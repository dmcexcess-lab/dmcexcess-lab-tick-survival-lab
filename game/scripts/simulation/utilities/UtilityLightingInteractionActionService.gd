extends RefCounted
class_name UtilityLightingInteractionActionService

const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")

## Ordinary fixed-light switch action. System 33 remains the sole owner of switch and
## power truth; this service only validates reach, schedules the physical interaction,
## and asks UtilityRuntimeState to mutate the already-bound fixed-light appliance.

const ACTION_TOGGLE: StringName = &"utility.light_toggle"
const COMMIT_PHASE: StringName = &"utility.light_toggle.commit"
const DURATION_TICKS: int = 1
const FIXED_LIGHT_KIND: StringName = &"fixed_light"
const APPLIANCE_PREFIX: String = "utility.light:"

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _kernel: TickKernel = null
var _utilities: UtilityRuntimeState = null

func _init(
    world: WorldState = null,
    reach: WorldInteractionReachQuery = null,
    kernel: TickKernel = null,
    utilities: UtilityRuntimeState = null
) -> void:
    _world = world
    _reach = reach
    _kernel = kernel
    _utilities = utilities
    if _kernel != null:
        var phase_callable := Callable(self, "_on_action_phase")
        if not _kernel.action_phase.is_connected(phase_callable):
            _kernel.action_phase.connect(phase_callable)

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() \
        and _kernel != null and _utilities != null and _utilities.is_ready()

static func appliance_id_for_target(target_id: String) -> String:
    var key: String = target_id.strip_edges()
    return "" if key.is_empty() else "%s%s" % [APPLIANCE_PREFIX, key]

func appliance_record_for_target(target_id: String) -> Dictionary:
    if _utilities == null:
        return {}
    var key: String = target_id.strip_edges()
    var record: Dictionary = _utilities.appliance_record(appliance_id_for_target(key))
    if record.is_empty() \
        or StringName(record.get("kind", &"")) != FIXED_LIGHT_KIND \
        or String(record.get("owner_entity_id", "")) != key:
        return {}
    return record

func request_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if action_id != ACTION_TOGGLE:
        return _reject("light_action_unknown")
    var actor: String = actor_id.strip_edges()
    var target: String = target_id.strip_edges()
    var failure: String = _common_failure(actor, target)
    if not failure.is_empty():
        return _reject(failure)
    var record: Dictionary = appliance_record_for_target(target)
    if StringName(record.get("operational_state", &"")) != UtilityRuntimeState.OPERATIONAL:
        return _reject("light_not_operational")
    var target_switched_on: bool = not bool(record.get("switched_on", false))
    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, DURATION_TICKS)]
    var serial: int = _kernel.begin_action(
        actor,
        ACTION_TOGGLE,
        DURATION_TICKS,
        TickRulesClass.InterruptionPolicy.CANCELABLE,
        phases,
        {
            "target_id": target,
            "appliance_id": appliance_id_for_target(target),
            "target_switched_on": target_switched_on,
        }
    )
    if serial <= 0:
        return _reject("when_rejected_light_toggle")
    return {
        "accepted": true,
        "reason": "",
        "action_serial": serial,
        "duration_ticks": DURATION_TICKS,
        "target_id": target,
        "target_switched_on": target_switched_on,
    }

func _common_failure(actor_id: String, target_id: String) -> String:
    if not is_ready():
        return "light_action_not_ready"
    if actor_id.is_empty() or target_id.is_empty() \
        or not _world.has_entity(actor_id) or not _world.has_entity(target_id):
        return "light_target_missing"
    if _kernel.is_hard_paused():
        return "hard_paused"
    if _kernel.has_active_action(actor_id):
        return "actor_busy"
    if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return "target_out_of_reach"
    if appliance_record_for_target(target_id).is_empty():
        return "fixed_light_target_unsupported"
    return ""

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or action.action_type != ACTION_TOGGLE or phase.phase_id != COMMIT_PHASE:
        return
    var target_id: String = String(action.payload.get("target_id", "")).strip_edges()
    var failure: String = _common_commit_failure(action.actor_id, target_id)
    if not failure.is_empty():
        _fail(action, failure)
        return
    var record: Dictionary = appliance_record_for_target(target_id)
    if StringName(record.get("operational_state", &"")) != UtilityRuntimeState.OPERATIONAL:
        _fail(action, "light_not_operational")
        return
    var appliance_id: String = String(action.payload.get("appliance_id", "")).strip_edges()
    var target_switched_on: bool = bool(action.payload.get("target_switched_on", false))
    if appliance_id != appliance_id_for_target(target_id) \
        or not _utilities.set_appliance_switched(appliance_id, target_switched_on, &"player_light_switch"):
        _fail(action, "light_switch_commit_failed")

func _common_commit_failure(actor_id: String, target_id: String) -> String:
    if not is_ready() or not _world.has_entity(actor_id) or not _world.has_entity(target_id):
        return "light_target_missing_at_commit"
    if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return "target_out_of_reach"
    if appliance_record_for_target(target_id).is_empty():
        return "fixed_light_target_changed"
    return ""

func _fail(action: TimedAction, reason: String) -> void:
    if not _kernel.fail_action(action.serial, reason):
        push_error("UtilityLightingInteractionActionService: failed to mark action failed: %s" % reason)

static func _reject(reason: String) -> Dictionary:
    return {"accepted": false, "reason": reason, "action_serial": 0, "duration_ticks": 0, "target_id": ""}
