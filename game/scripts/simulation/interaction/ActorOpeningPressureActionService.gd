extends RefCounted
class_name ActorOpeningPressureActionService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryResult = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const SoundProfiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")

## Generic physical pressure against the exact opening that blocks an actor's
## ordinary forward movement. This service does not know or care whether the actor
## is infected. It owns no pathfinding, group pressure, private clock or hidden
## lock knowledge. Each actor must physically reach/facing-contact the target.

signal action_resolved(actor_id, action_serial, target_id, action_id, success, reason)
signal impact_resolved(actor_id, action_serial, target_id, damage, total_damage, breached, cell)

const ACTION_TYPE: StringName = &"opening.pressure"
const TRY_OPEN: StringName = &"opening.try_open"
const IMPACT: StringName = &"opening.impact"
const TRY_PHASE: StringName = &"opening.try_open.commit"
const IMPACT_PHASE: StringName = &"opening.impact.contact"

const TRY_OPEN_TICKS: int = 3
const IMPACT_TICKS: int = 8
const DOOR_IMPACT_DAMAGE: int = 25
const WINDOW_IMPACT_DAMAGE: int = 55
const BOARD_DAMAGE_PENALTY: int = 5
const MIN_IMPACT_DAMAGE: int = 5

var _world: WorldState = null
var _state: WorldInteractableState = null
var _door_state: DoorStateStore = null
var _door_transitions: DoorPhysicalTransitionService = null
var _reach: WorldInteractionReachQuery = null
var _spatial: SpatialQueryService = null
var _kernel: TickKernel = null
var _catalog: WorldInteractionCatalog = null
var _world_actions: WorldInteractionActionService = null
var _sound: SpatialSoundService = null

var _known_resisted: Dictionary = {}
var _outcomes: Dictionary = {}

func _init(
    world: WorldState = null,
    state: WorldInteractableState = null,
    door_state: DoorStateStore = null,
    door_transitions: DoorPhysicalTransitionService = null,
    reach: WorldInteractionReachQuery = null,
    spatial: SpatialQueryService = null,
    kernel: TickKernel = null,
    catalog: WorldInteractionCatalog = null,
    world_actions: WorldInteractionActionService = null,
    sound: SpatialSoundService = null
) -> void:
    _world = world
    _state = state
    _door_state = door_state
    _door_transitions = door_transitions
    _reach = reach
    _spatial = spatial
    _kernel = kernel
    _catalog = catalog
    _world_actions = world_actions
    _sound = sound
    if _kernel != null:
        var phase_cb := Callable(self, "_on_action_phase")
        var finish_cb := Callable(self, "_on_action_finished")
        if not _kernel.action_phase.is_connected(phase_cb):
            _kernel.action_phase.connect(phase_cb)
        if not _kernel.action_finished.is_connected(finish_cb):
            _kernel.action_finished.connect(finish_cb)

func is_ready() -> bool:
    return _world != null and _state != null and _door_state != null \
        and _door_transitions != null and _door_transitions.is_ready() \
        and _reach != null and _reach.is_ready() and _spatial != null and _spatial.is_ready() \
        and _kernel != null and _catalog != null \
        and _world_actions != null and _world_actions.is_ready() \
        and _sound != null and _sound.is_ready()

func actor_knows_opening_resisted(actor_id: String, target_id: String) -> bool:
    return _known_resisted.has(_knowledge_key(actor_id, target_id))

func request_for_forward_blocker(actor_id: String) -> Dictionary:
    if not is_ready():
        return _rejected("opening_pressure_not_ready")
    var actor := actor_id.strip_edges()
    var placement: WorldPlacement = _actor_placement(actor)
    if placement == null:
        return _rejected("actor_unavailable")
    if _kernel.is_hard_paused():
        return _rejected("hard_paused")
    if _kernel.has_active_action(actor):
        return _rejected("actor_busy")

    var target_anchor: Vector2i = placement.anchor + Facing.vector(placement.facing)
    var query: SpatialQueryResult = _spatial.query_entity_footprint(actor, target_anchor, placement.facing, true)
    if query == null or query.status != QueryResult.Status.BLOCKED:
        return _rejected("forward_not_blocked")

    var blockers: Array[String] = query.blocking_entity_ids.duplicate()
    blockers.sort()
    for target_id: String in blockers:
        if not _is_opening(target_id):
            continue
        return request_target(actor, target_id)
    return _rejected("no_actionable_opening_blocker")

func request_target(actor_id: String, target_id: String) -> Dictionary:
    if not is_ready():
        return _rejected("opening_pressure_not_ready")
    var actor := actor_id.strip_edges()
    var target := target_id.strip_edges()
    if _actor_placement(actor) == null or not _is_opening(target):
        return _rejected("opening_target_unavailable")
    if _kernel.is_hard_paused():
        return _rejected("hard_paused")
    if _kernel.has_active_action(actor):
        return _rejected("actor_busy")
    if not _reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return _rejected("opening_out_of_reach")

    var entity: WorldEntityRecord = _world.entity(target)
    if entity == null:
        return _rejected("opening_target_unavailable")
    var semantic: StringName = entity.semantic_type

    if _catalog.is_window(semantic) and (_state.is_broken(target) or _state.window_open(target)):
        return _world_actions.request_action(actor, target, WorldActions.WINDOW_CLIMB)

    if _catalog.is_door(semantic):
        if _state.is_broken(target) or (_door_state.has_door(target) and _door_state.state(target) == DoorValue.OPEN):
            return _rejected("opening_already_passable")
        if _state.board_count(target) <= 0 and not actor_knows_opening_resisted(actor, target):
            return _begin(actor, target, TRY_OPEN, TRY_OPEN_TICKS, TRY_PHASE)

    if _state.is_broken(target):
        return _rejected("opening_already_broken")
    return _begin(actor, target, IMPACT, IMPACT_TICKS, IMPACT_PHASE)

func _begin(actor_id: String, target_id: String, action_id: StringName, ticks: int, phase_id: StringName) -> Dictionary:
    var phases: Array[ActionPhase] = [PhaseClass.new(phase_id, ticks)]
    var payload := {
        "target_id": target_id,
        "action_id": String(action_id),
    }
    var serial: int = _kernel.begin_action(
        actor_id,
        ACTION_TYPE,
        ticks,
        TickRules.InterruptionPolicy.COMMITTED,
        phases,
        payload
    )
    if serial <= 0:
        return _rejected("when_rejected_opening_pressure")
    return {
        "accepted": true,
        "reason": "",
        "action_serial": serial,
        "duration_ticks": ticks,
        "action_id": action_id,
        "target_id": target_id,
    }

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or action.action_type != ACTION_TYPE:
        return
    var action_id := StringName(String(action.payload.get("action_id", "")))
    if action_id == TRY_OPEN and phase.phase_id == TRY_PHASE:
        _commit_try_open(action)
    elif action_id == IMPACT and phase.phase_id == IMPACT_PHASE:
        _commit_impact(action)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != ACTION_TYPE:
        return
    var target_id := String(action.payload.get("target_id", ""))
    var action_id := StringName(String(action.payload.get("action_id", "")))
    var outcome: Dictionary = _outcomes.get(action.serial, {})
    var success: bool = action.status == TickRules.ActionStatus.COMPLETED and bool(outcome.get("success", false))
    var reason: String = String(outcome.get("reason", action.reason))
    if reason.is_empty():
        reason = "completed" if success else "opening_pressure_failed"
    action_resolved.emit(action.actor_id, action.serial, target_id, action_id, success, reason)
    _outcomes.erase(action.serial)

func _commit_try_open(action: TimedAction) -> void:
    var target := String(action.payload.get("target_id", ""))
    if not _commit_contact_valid(action.actor_id, target) or not _is_door(target):
        _fail(action, "opening_contact_changed")
        return
    if _state.is_broken(target) or _door_state.state(target) == DoorValue.OPEN:
        _fail(action, "opening_already_passable")
        return

    # The request path deliberately did not inspect lock state. Resistance is
    # learned only now, after the physical try-open action spends WHEN.
    if _state.is_locked(target) or _state.board_count(target) > 0:
        _known_resisted[_knowledge_key(action.actor_id, target)] = true
        var placement: WorldPlacement = _world.placement(target)
        if placement != null:
            _sound.emit_sound(SoundProfiles.DOOR_QUIET, placement.anchor, action.actor_id, "opening_try:%s" % target)
        _outcomes[action.serial] = {"success": false, "reason": "opening_resisted"}
        _kernel.fail_action(action.serial, "opening_resisted")
        return

    if not _door_transitions.open_for_passage(action.actor_id, target, &"interaction.door_open"):
        _fail(action, "door_open_transition_failed")
        return
    _outcomes[action.serial] = {"success": true, "reason": "opened"}

func _commit_impact(action: TimedAction) -> void:
    var target := String(action.payload.get("target_id", ""))
    if not _commit_contact_valid(action.actor_id, target) or not _is_opening(target):
        _fail(action, "opening_contact_changed")
        return
    if _state.is_broken(target):
        _fail(action, "opening_already_broken")
        return

    var entity: WorldEntityRecord = _world.entity(target)
    var placement: WorldPlacement = _world.placement(target)
    if entity == null or placement == null:
        _fail(action, "opening_target_unavailable")
        return

    var base_damage: int = DOOR_IMPACT_DAMAGE if _catalog.is_door(entity.semantic_type) else WINDOW_IMPACT_DAMAGE
    var damage: int = maxi(MIN_IMPACT_DAMAGE, base_damage - _state.board_count(target) * BOARD_DAMAGE_PENALTY)
    var before: Dictionary = _state.record(target)
    var total: int = mini(WorldInteractableState.MAX_OPENING_DAMAGE, _state.opening_damage(target) + damage)
    if not _state.set_opening_damage(target, total, &"opening_impact"):
        _fail(action, "opening_damage_commit_failed")
        return

    var breached: bool = total >= WorldInteractableState.MAX_OPENING_DAMAGE
    if breached and not _breach(action.actor_id, target, entity.semantic_type, before):
        _fail(action, "opening_breach_commit_failed")
        return

    var profile: StringName = SoundProfiles.OPENING_BREAK if breached else SoundProfiles.OPENING_IMPACT
    _sound.emit_sound(profile, placement.anchor, action.actor_id, "opening_pressure:%s" % target)
    _outcomes[action.serial] = {"success": true, "reason": "breached" if breached else "impact"}
    impact_resolved.emit(action.actor_id, action.serial, target, damage, total, breached, placement.anchor)

func _breach(actor_id: String, target: String, semantic: StringName, before: Dictionary) -> bool:
    if not _state.set_broken(target, true, &"opening_pressure_breached") \
        or not _state.set_locked(target, false, &"opening_pressure_lock_broken") \
        or not _state.set_board_count(target, 0, &"opening_pressure_boards_broken"):
        _restore_opening(target, before)
        return false
    if _catalog.is_window(semantic):
        if _state.set_window_open(target, true, &"opening_pressure_window_open"):
            return true
        _restore_opening(target, before)
        return false
    if _catalog.is_door(semantic):
        if _door_transitions.open_for_passage(actor_id, target, &"door_broken"):
            return true
        _restore_opening(target, before)
        return false
    _restore_opening(target, before)
    return false

func _restore_opening(target: String, before: Dictionary) -> void:
    _state.set_opening_damage(target, int(before.get("opening_damage", 0)), &"opening_pressure_rollback")
    _state.set_locked(target, bool(before.get("locked", false)), &"opening_pressure_rollback")
    _state.set_broken(target, bool(before.get("broken", false)), &"opening_pressure_rollback")
    _state.set_board_count(target, int(before.get("board_count", 0)), &"opening_pressure_rollback")
    _state.set_window_open(target, bool(before.get("window_open", false)), &"opening_pressure_rollback")

func _commit_contact_valid(actor_id: String, target_id: String) -> bool:
    return _actor_placement(actor_id) != null \
        and _is_opening(target_id) \
        and _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD)

func _actor_placement(actor_id: String) -> WorldPlacement:
    var normalized := actor_id.strip_edges()
    if normalized.is_empty() or not _world.has_entity(normalized):
        return null
    var entity: WorldEntityRecord = _world.entity(normalized)
    var placement: WorldPlacement = _world.placement(normalized)
    if entity == null or String(entity.semantic_type) != "actor.survivor" \
        or placement == null or placement.channel != Layers.Channel.ACTOR or not Facing.is_valid(placement.facing):
        return null
    return placement

func _is_opening(target_id: String) -> bool:
    var normalized := target_id.strip_edges()
    if normalized.is_empty() or not _world.has_entity(normalized) or not _world.has_placement(normalized):
        return false
    var entity: WorldEntityRecord = _world.entity(normalized)
    var placement: WorldPlacement = _world.placement(normalized)
    return entity != null and placement != null and placement.channel == Layers.Channel.STRUCTURE \
        and (_catalog.is_door(entity.semantic_type) or _catalog.is_window(entity.semantic_type))

func _is_door(target_id: String) -> bool:
    if not _is_opening(target_id):
        return false
    var entity: WorldEntityRecord = _world.entity(target_id)
    return entity != null and _catalog.is_door(entity.semantic_type) and _door_state.has_door(target_id)

func _knowledge_key(actor_id: String, target_id: String) -> String:
    return "%s|%s" % [actor_id.strip_edges(), target_id.strip_edges()]

func _fail(action: TimedAction, reason: String) -> void:
    _outcomes[action.serial] = {"success": false, "reason": reason}
    _kernel.fail_action(action.serial, reason)

func _rejected(reason: String) -> Dictionary:
    return {"accepted": false, "reason": reason, "action_serial": 0, "duration_ticks": 0, "action_id": &"", "target_id": ""}
