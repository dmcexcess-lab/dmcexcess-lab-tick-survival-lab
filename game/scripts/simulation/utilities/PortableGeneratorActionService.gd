extends RefCounted
class_name PortableGeneratorActionService

const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

const INSPECT: StringName = &"utility.generator_inspect"
const REFUEL: StringName = &"utility.generator_refuel"
const START: StringName = &"utility.generator_start"
const STOP: StringName = &"utility.generator_stop"
const REPAIR: StringName = &"utility.generator_repair"
const ACTION_IDS: Array[StringName] = [INSPECT, REFUEL, START, STOP, REPAIR]
const COMMIT_PHASE: StringName = &"utility.generator.commit"
const GAS_CAN: StringName = &"item.automotive.gas_can"
const WRENCH: StringName = &"item.tool.adjustable_wrench"
const METAL_SCRAP: StringName = &"item.material.scrap_metal"
const REPAIR_DIFFICULTY: int = 2

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _reach: WorldInteractionReachQuery = null
var _kernel: TickKernel = null
var _skills: ActorSkillCheckService = null
var _carry: ActorCarryQuery = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _generators: PortableGeneratorState = null
var _outcomes: Dictionary = {}

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    reach: WorldInteractionReachQuery = null,
    kernel: TickKernel = null,
    skills: ActorSkillCheckService = null,
    carry: ActorCarryQuery = null,
    hands: ActorHandEquipmentState = null,
    hand_mutations: ActorHandEquipmentMutationService = null,
    inventory: InventoryContainmentState = null,
    inventory_mutations: InventoryContainmentMutationService = null,
    generators: PortableGeneratorState = null
) -> void:
    _world = world
    _mutations = mutations
    _reach = reach
    _kernel = kernel
    _skills = skills
    _carry = carry
    _hands = hands
    _hand_mutations = hand_mutations
    _inventory = inventory
    _inventory_mutations = inventory_mutations
    _generators = generators
    if _kernel != null:
        _kernel.action_phase.connect(_on_action_phase)
        _kernel.action_finished.connect(_on_action_finished)

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _reach != null and _reach.is_ready() and _kernel != null \
        and _skills != null and _skills.is_ready() and _carry != null \
        and _hands != null and _hand_mutations != null and _hand_mutations.is_ready() \
        and _inventory != null and _inventory_mutations != null and _inventory_mutations.is_ready() \
        and _generators != null

func request_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    var target: String = target_id.strip_edges()
    if action_id not in ACTION_IDS:
        return _reject("generator_action_unknown")
    var common_reason: String = _common_failure(actor, target)
    if not common_reason.is_empty():
        return _reject(common_reason)
    var state: Dictionary = _generators.record(target)
    var payload: Dictionary = {
        "target_id": target,
        "target_version": int(state.get("version", 0)),
        "action_id": String(action_id),
    }
    var duration: int = 1
    match action_id:
        INSPECT:
            duration = 1
        REFUEL:
            if not _generators.can_refuel(target):
                return _reject("generator_refuel_unavailable")
            var gas_can_id: String = _find_carried(actor, GAS_CAN)
            if gas_can_id.is_empty():
                return _reject("generator_refuel_requires_gas_can")
            payload["consumed_item_id"] = gas_can_id
            duration = 6
        START:
            if bool(state.get("running", false)):
                return _reject("generator_already_running")
            if int(state.get("fuel_ticks", 0)) <= 0:
                return _reject("generator_out_of_fuel")
            if int(state.get("condition", 0)) < PortableGeneratorState.MIN_START_CONDITION:
                return _reject("generator_requires_repair")
            duration = 4
        STOP:
            if not bool(state.get("running", false)):
                return _reject("generator_not_running")
            duration = 2
        REPAIR:
            if not _generators.can_repair(target):
                return _reject("generator_repair_unavailable")
            var wrench_id: String = _find_carried(actor, WRENCH)
            if wrench_id.is_empty():
                return _reject("generator_repair_requires_wrench")
            var scrap_id: String = _find_carried(actor, METAL_SCRAP)
            if scrap_id.is_empty():
                return _reject("generator_repair_requires_metal_scrap")
            var skill: Dictionary = _skills.action_profile(actor, SkillCatalog.MECHANICAL, 16, REPAIR_DIFFICULTY)
            if not bool(skill.get("ok", false)):
                return _reject(String(skill.get("reason", "mechanical_skill_unavailable")))
            if int(skill.get("skill_level", -1)) < REPAIR_DIFFICULTY:
                return _reject("insufficient_mechanical_skill")
            payload["consumed_item_id"] = scrap_id
            payload["tool_item_id"] = wrench_id
            payload["skill_level"] = int(skill.get("skill_level", -1))
            payload["skill_difficulty"] = REPAIR_DIFFICULTY
            duration = int(skill.get("duration_ticks", 16))
    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, duration)]
    var serial: int = _kernel.begin_action(
        actor,
        action_id,
        duration,
        TickRulesClass.InterruptionPolicy.CANCELABLE,
        phases,
        payload
    )
    if serial <= 0:
        return _reject("when_rejected_generator_action")
    return {"accepted": true, "reason": "", "action_serial": serial, "duration_ticks": duration, "target_id": target}

func _common_failure(actor_id: String, target_id: String) -> String:
    if not is_ready():
        return "generator_action_not_ready"
    if actor_id.is_empty() or target_id.is_empty() or not _world.has_entity(actor_id) or not _world.has_entity(target_id):
        return "generator_target_missing"
    if _kernel.is_hard_paused():
        return "hard_paused"
    if _kernel.has_active_action(actor_id):
        return "actor_busy"
    if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return "target_out_of_reach"
    var entity: WorldEntityRecord = _world.entity(target_id)
    if entity == null or entity.semantic_type != PortableGeneratorState.SEMANTIC or not _generators.has_generator(target_id):
        return "generator_target_unsupported"
    return ""

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or phase.phase_id != COMMIT_PHASE or action.action_type not in ACTION_IDS:
        return
    _commit(action)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type not in ACTION_IDS:
        return
    _outcomes.erase(action.serial)

func _commit(action: TimedAction) -> void:
    var target: String = String(action.payload.get("target_id", ""))
    var failure: String = _common_commit_failure(action.actor_id, target)
    if not failure.is_empty():
        _fail(action, failure)
        return
    var before: Dictionary = _generators.snapshot()
    var success: bool = false
    match action.action_type:
        INSPECT:
            success = true
        REFUEL:
            success = _generators.can_refuel(target) and _generators.refuel(target, _kernel.world_tick())
            if success and not _consume_item(action.actor_id, String(action.payload.get("consumed_item_id", "")), GAS_CAN):
                _generators.restore_snapshot(before)
                success = false
        START:
            success = _generators.start(target, _kernel.world_tick())
        STOP:
            success = _generators.stop(target, _kernel.world_tick())
        REPAIR:
            success = _commit_repair(action, target, before)
    if not success:
        _fail(action, "generator_%s_commit_failed" % String(action.action_type).trim_prefix("utility.generator_"))
        return
    _outcomes[action.serial] = {"success": true}

func _commit_repair(action: TimedAction, target_id: String, before: Dictionary) -> bool:
    if not _generators.can_repair(target_id) \
        or not _is_carried_item(action.actor_id, String(action.payload.get("tool_item_id", "")), WRENCH) \
        or not _is_carried_item(action.actor_id, String(action.payload.get("consumed_item_id", "")), METAL_SCRAP):
        return false
    var skill: Dictionary = _skills.resolve_attempt(
        action.actor_id,
        SkillCatalog.MECHANICAL,
        int(action.payload.get("skill_difficulty", REPAIR_DIFFICULTY)),
        action.serial,
        StringName("utility.generator_repair|%s" % target_id),
        int(action.payload.get("skill_level", -1))
    )
    if not bool(skill.get("ok", false)):
        return false
    var skill_success: bool = bool(skill.get("success", false))
    _skills.award_attempt_xp(action.actor_id, SkillCatalog.MECHANICAL, REPAIR_DIFFICULTY, skill_success)
    if not skill_success:
        return false
    if not _generators.repair(target_id, _kernel.world_tick()):
        return false
    if _consume_item(action.actor_id, String(action.payload.get("consumed_item_id", "")), METAL_SCRAP):
        return true
    _generators.restore_snapshot(before)
    return false

func _common_commit_failure(actor_id: String, target_id: String) -> String:
    if not is_ready() or not _world.has_entity(actor_id) or not _world.has_entity(target_id):
        return "generator_target_missing_at_commit"
    if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        return "target_out_of_reach"
    var entity: WorldEntityRecord = _world.entity(target_id)
    if entity == null or entity.semantic_type != PortableGeneratorState.SEMANTIC or not _generators.has_generator(target_id):
        return "generator_target_changed"
    return ""

func _find_carried(actor_id: String, semantic: StringName) -> String:
    var result: Dictionary = _carry.query(actor_id)
    if int(result.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return ""
    var ids: Array[String] = []
    for value: Variant in result.get("item_ids", []):
        ids.append(String(value))
    ids.sort()
    for item_id: String in ids:
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity != null and entity.semantic_type == semantic:
            return item_id
    return ""

func _is_carried_item(actor_id: String, item_id: String, semantic: StringName) -> bool:
    if item_id.is_empty() or not _world.has_entity(item_id):
        return false
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null or entity.semantic_type != semantic:
        return false
    var result: Dictionary = _carry.query(actor_id)
    if int(result.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return false
    for value: Variant in result.get("item_ids", []):
        if String(value) == item_id:
            return true
    return false

func _consume_item(actor_id: String, item_id: String, semantic: StringName) -> bool:
    if not _is_carried_item(actor_id, item_id, semantic):
        return false
    var assignment: Dictionary = _hands.assignment_for_item(item_id)
    if not assignment.is_empty():
        if String(assignment.get("actor_id", "")) != actor_id:
            return false
        var slot: int = int(assignment.get("slot", -1))
        if not _hand_mutations.clear_slot(actor_id, slot):
            return false
        if _mutations.remove_entity(item_id):
            return true
        _hand_mutations.set_item(actor_id, slot, item_id)
        return false
    if not _inventory.is_contained(item_id):
        return false
    var container_id: String = _inventory.container_of(item_id)
    var current: String = item_id
    var visited: Dictionary = {}
    while _inventory.is_contained(current) and not visited.has(current):
        visited[current] = true
        current = _inventory.container_of(current)
    if current != actor_id or not _inventory_mutations.clear_container(item_id):
        return false
    if _mutations.remove_entity(item_id):
        return true
    _inventory_mutations.set_container(item_id, container_id)
    return false

func _fail(action: TimedAction, reason: String) -> void:
    _outcomes[action.serial] = {"success": false, "reason": reason}
    if not _kernel.fail_action(action.serial, reason):
        push_error("PortableGeneratorActionService: failed to mark action failed: %s" % reason)

static func _reject(reason: String) -> Dictionary:
    return {"accepted": false, "reason": reason, "action_serial": 0, "duration_ticks": 0, "target_id": ""}
