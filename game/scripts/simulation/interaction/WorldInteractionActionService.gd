extends RefCounted
class_name WorldInteractionActionService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const QueryResult = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const CapacityPolicyClass = preload("res://scripts/simulation/items/ItemAcquisitionCapacityPolicy.gd")

signal action_resolved(actor_id, action_serial, target_id, action_id, success, reason)
signal availability_changed(reason: StringName)

const ACTION_TYPE: StringName = &"world.interaction"
const COMMIT_PHASE: StringName = &"world.interaction.commit"

const DOOR_OPEN: StringName = &"door.open"
const DOOR_CLOSE: StringName = &"door.close"
const DOOR_LOCK: StringName = &"door.lock"
const DOOR_UNLOCK: StringName = &"door.unlock"
const WINDOW_OPEN: StringName = &"window.open"
const WINDOW_CLOSE: StringName = &"window.close"
const WINDOW_LOCK: StringName = &"window.lock"
const WINDOW_UNLOCK: StringName = &"window.unlock"
const WINDOW_CLIMB: StringName = &"window.climb"
const OPENING_BOARD: StringName = &"opening.board"
const OPENING_UNBOARD: StringName = &"opening.remove_board"
const OPENING_BREAK: StringName = &"opening.break"
const OBJECT_DECONSTRUCT: StringName = &"world.deconstruct"

const CORE_ACTIONS: Array[StringName] = [
    DOOR_OPEN, DOOR_CLOSE, DOOR_LOCK, DOOR_UNLOCK,
    WINDOW_OPEN, WINDOW_CLOSE, WINDOW_LOCK, WINDOW_UNLOCK, WINDOW_CLIMB,
    OPENING_BOARD, OPENING_UNBOARD, OPENING_BREAK, OBJECT_DECONSTRUCT,
]

const HAMMER: StringName = &"item.tool.hammer"
const CROWBAR: StringName = &"item.tool.crowbar"
const NAILS: StringName = &"item.material.nails_box"
const PLANK: StringName = &"item.material.wood_plank"

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _door_state: DoorStateStore = null
var _door_transitions: DoorPhysicalTransitionService = null
var _reach: WorldInteractionReachQuery = null
var _spatial: SpatialQueryService = null
var _kernel: TickKernel = null
var _skill_checks: ActorSkillCheckService = null
var _carry: ActorCarryQuery = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _capacity: ItemAcquisitionCapacityPolicy = null
var _state: WorldInteractableState = null
var _catalog: WorldInteractionCatalog = null
var _outcomes: Dictionary = {}

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    door_state: DoorStateStore = null,
    door_transitions: DoorPhysicalTransitionService = null,
    reach: WorldInteractionReachQuery = null,
    spatial: SpatialQueryService = null,
    kernel: TickKernel = null,
    skill_checks: ActorSkillCheckService = null,
    carry: ActorCarryQuery = null,
    hands: ActorHandEquipmentState = null,
    hand_mutations: ActorHandEquipmentMutationService = null,
    inventory: InventoryContainmentState = null,
    inventory_mutations: InventoryContainmentMutationService = null,
    capacity: ItemAcquisitionCapacityPolicy = null,
    state: WorldInteractableState = null,
    catalog: WorldInteractionCatalog = null
) -> void:
    _world = world
    _mutations = mutations
    _door_state = door_state
    _door_transitions = door_transitions
    _reach = reach
    _spatial = spatial
    _kernel = kernel
    _skill_checks = skill_checks
    _carry = carry
    _hands = hands
    _hand_mutations = hand_mutations
    _inventory = inventory
    _inventory_mutations = inventory_mutations
    _capacity = capacity
    _state = state
    _catalog = catalog
    if _kernel != null:
        var phase_callback := Callable(self, "_on_action_phase")
        var finished_callback := Callable(self, "_on_action_finished")
        if not _kernel.action_phase.is_connected(phase_callback):
            _kernel.action_phase.connect(phase_callback)
        if not _kernel.action_finished.is_connected(finished_callback):
            _kernel.action_finished.connect(finished_callback)
    if _state != null:
        var changed := Callable(self, "_on_state_changed")
        if not _state.state_changed.is_connected(changed):
            _state.state_changed.connect(changed)

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _door_state != null and _door_transitions != null and _door_transitions.is_ready() \
        and _reach != null and _reach.is_ready() and _spatial != null and _spatial.is_ready() \
        and _kernel != null and _skill_checks != null and _skill_checks.is_ready() \
        and _carry != null and _hands != null and _hand_mutations != null and _hand_mutations.is_ready() \
        and _inventory != null and _inventory_mutations != null and _inventory_mutations.is_ready() \
        and _capacity != null and _capacity.is_ready() and _state != null and _catalog != null

func state() -> WorldInteractableState:
    return _state

func request_action(actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    var target: String = target_id.strip_edges()
    if not is_ready():
        return _rejected("world_interaction_not_ready")
    if action_id not in CORE_ACTIONS:
        return _rejected("world_action_unknown")
    if actor.is_empty() or target.is_empty() or not _world.has_entity(actor) or not _world.has_entity(target):
        return _rejected("interaction_target_missing")
    if _kernel.is_hard_paused():
        return _rejected("hard_paused")
    if _kernel.has_active_action(actor):
        return _rejected("actor_busy")
    if not _reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return _rejected("target_out_of_reach")

    var entity: WorldEntityRecord = _world.entity(target)
    var placement: WorldPlacement = _world.placement(target)
    if entity == null or placement == null or _state.is_destroyed(target):
        return _rejected("target_unavailable")
    var legality: String = _legality_reason(actor, target, entity.semantic_type, action_id)
    if not legality.is_empty():
        return _rejected(legality)

    var base_duration: int = _base_duration(action_id, entity.semantic_type, target)
    var difficulty: int = _skill_difficulty(action_id, entity.semantic_type)
    var skill_level: int = -1
    var duration: int = base_duration
    if difficulty >= 0:
        var profile: Dictionary = _skill_checks.action_profile(actor, SkillCatalog.MECHANICAL, base_duration, difficulty)
        if not bool(profile.get("ok", false)):
            return _rejected(String(profile.get("reason", "mechanical_skill_unavailable")))
        duration = int(profile.get("duration_ticks", 0))
        skill_level = int(profile.get("skill_level", -1))

    var payload: Dictionary = {
        "target_id": target,
        "semantic_type": String(entity.semantic_type),
        "action_id": String(action_id),
        "state_version": _state.version(target),
        "door_version": _door_state.version(target) if _door_state.has_door(target) else 0,
        "skill_difficulty": difficulty,
        "skill_level": skill_level,
        "tool_item_id": "",
        "material_item_ids": [],
    }

    if action_id == OPENING_BOARD:
        var hammer_id: String = _find_carried_any(actor, [HAMMER])
        var plank_id: String = _find_carried_any(actor, [PLANK])
        var nails_id: String = _find_carried_any(actor, [NAILS])
        if hammer_id.is_empty():
            return _rejected("hammer_required")
        if plank_id.is_empty():
            return _rejected("wood_plank_required")
        if nails_id.is_empty():
            return _rejected("nails_required")
        payload["tool_item_id"] = hammer_id
        payload["material_item_ids"] = [plank_id, nails_id]
    elif action_id == OPENING_UNBOARD or action_id == OPENING_BREAK:
        var opening_tool: String = _find_carried_any(actor, [CROWBAR, HAMMER])
        if opening_tool.is_empty():
            return _rejected("hammer_or_crowbar_required")
        payload["tool_item_id"] = opening_tool
    elif action_id == OBJECT_DECONSTRUCT:
        var deconstruction: Dictionary = _catalog.deconstruction_profile(entity.semantic_type)
        var tool_id: String = _find_carried_any(actor, deconstruction.get("tool_semantics", []))
        if tool_id.is_empty():
            return _rejected("deconstruction_tool_required")
        payload["tool_item_id"] = tool_id
    elif action_id == WINDOW_CLIMB:
        var destination: Variant = _window_climb_destination(actor, target)
        if typeof(destination) != TYPE_VECTOR2I:
            return _rejected("window_climb_destination_blocked")
        payload["destination"] = destination

    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, duration)]
    var serial: int = _kernel.begin_action(
        actor,
        ACTION_TYPE,
        duration,
        TickRulesClass.InterruptionPolicy.CANCELABLE,
        phases,
        payload
    )
    if serial <= 0:
        return _rejected("when_rejected_world_interaction")
    return {
        "accepted": true,
        "reason": "",
        "action_serial": serial,
        "duration_ticks": duration,
        "action_id": action_id,
        "target_id": target,
    }

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or action.action_type != ACTION_TYPE or phase.phase_id != COMMIT_PHASE:
        return
    _commit(action)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != ACTION_TYPE:
        return
    var target_id: String = String(action.payload.get("target_id", ""))
    var action_id := StringName(String(action.payload.get("action_id", "")))
    var outcome: Dictionary = _outcomes.get(action.serial, {})
    var success: bool = action.status == TickRulesClass.ActionStatus.COMPLETED and bool(outcome.get("success", false))
    var reason: String = String(outcome.get("reason", action.reason))
    if success and reason.is_empty():
        reason = "completed"
    elif not success and reason.is_empty():
        reason = "world_interaction_failed"
    action_resolved.emit(action.actor_id, action.serial, target_id, action_id, success, reason)
    _outcomes.erase(action.serial)

func _commit(action: TimedAction) -> void:
    var target: String = String(action.payload.get("target_id", ""))
    var action_id := StringName(String(action.payload.get("action_id", "")))
    if not _world.has_entity(action.actor_id) or not _world.has_entity(target):
        _fail(action, "target_missing_at_commit")
        return
    var entity: WorldEntityRecord = _world.entity(target)
    if entity == null or String(entity.semantic_type) != String(action.payload.get("semantic_type", "")):
        _fail(action, "target_semantic_changed")
        return
    if _state.version(target) != int(action.payload.get("state_version", -1)):
        _fail(action, "target_state_changed")
        return
    if _door_state.has_door(target) and _door_state.version(target) != int(action.payload.get("door_version", -1)):
        _fail(action, "door_state_changed")
        return
    if not _reach.target_reachable(action.actor_id, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        _fail(action, "target_out_of_reach")
        return
    var legality: String = _legality_reason(action.actor_id, target, entity.semantic_type, action_id)
    if not legality.is_empty():
        _fail(action, legality)
        return
    if not _still_has_payload_items(action.actor_id, action.payload):
        _fail(action, "required_item_no_longer_carried")
        return

    var difficulty: int = int(action.payload.get("skill_difficulty", -1))
    if difficulty >= 0:
        var skill: Dictionary = _skill_checks.resolve_attempt(
            action.actor_id,
            SkillCatalog.MECHANICAL,
            difficulty,
            action.serial,
            StringName("%s|%s" % [String(action_id), target]),
            int(action.payload.get("skill_level", -1))
        )
        if not bool(skill.get("ok", false)):
            _fail(action, String(skill.get("reason", "mechanical_skill_unavailable")))
            return
        if not bool(skill.get("success", false)):
            _skill_checks.award_attempt_xp(action.actor_id, SkillCatalog.MECHANICAL, difficulty, false)
            _fail(action, "mechanical_skill_check_failed")
            return

    var ok: bool = false
    match action_id:
        DOOR_OPEN:
            ok = _door_transitions.open_for_passage(action.actor_id, target, &"interaction.door_open")
        DOOR_CLOSE:
            ok = _door_transitions.close_manually(action.actor_id, target)
        DOOR_LOCK, WINDOW_LOCK:
            ok = _state.set_locked(target, true, &"manually_locked")
        DOOR_UNLOCK, WINDOW_UNLOCK:
            ok = _state.set_locked(target, false, &"manually_unlocked")
        WINDOW_OPEN:
            ok = _state.set_window_open(target, true, &"window_opened")
        WINDOW_CLOSE:
            ok = _state.set_window_open(target, false, &"window_closed")
        WINDOW_CLIMB:
            ok = _commit_window_climb(action, target)
        OPENING_BOARD:
            ok = _commit_board(action, target)
        OPENING_UNBOARD:
            ok = _commit_unboard(action, target)
        OPENING_BREAK:
            ok = _commit_break(action, target, entity.semantic_type)
        OBJECT_DECONSTRUCT:
            ok = _commit_deconstruct(action, target, entity.semantic_type)
    if not ok:
        _fail(action, "world_interaction_commit_failed")
        return
    if difficulty >= 0 and not _skill_checks.award_attempt_xp(action.actor_id, SkillCatalog.MECHANICAL, difficulty, true):
        _fail(action, "mechanical_xp_commit_failed")
        return
    _outcomes[action.serial] = {"success": true, "reason": "completed"}

func _legality_reason(actor: String, target: String, semantic: StringName, action_id: StringName) -> String:
    var is_door: bool = _catalog.is_door(semantic) and _door_state.has_door(target)
    var is_window: bool = _catalog.is_window(semantic)
    var boards: int = _state.board_count(target)
    var broken: bool = _state.is_broken(target)
    var locked: bool = _state.is_locked(target)
    if action_id == DOOR_OPEN:
        if not is_door:
            return "not_a_door"
        if broken:
            return "door_broken_open"
        if boards > 0:
            return "door_boarded"
        if locked:
            return "door_locked"
        if _door_state.state(target) != DoorValue.CLOSED:
            return "door_not_closed"
    elif action_id == DOOR_CLOSE:
        if not is_door:
            return "not_a_door"
        if broken:
            return "door_broken"
        if _door_state.state(target) != DoorValue.OPEN:
            return "door_not_open"
    elif action_id == DOOR_LOCK:
        if not is_door or broken or boards > 0 or locked or _door_state.state(target) != DoorValue.CLOSED:
            return "door_cannot_lock"
    elif action_id == DOOR_UNLOCK:
        if not is_door or broken or not locked:
            return "door_not_locked"
    elif action_id == WINDOW_OPEN:
        if not is_window or broken or boards > 0 or locked or _state.window_open(target):
            return "window_cannot_open"
    elif action_id == WINDOW_CLOSE:
        if not is_window or broken or not _state.window_open(target):
            return "window_not_open"
    elif action_id == WINDOW_LOCK:
        if not is_window or broken or boards > 0 or locked or _state.window_open(target):
            return "window_cannot_lock"
    elif action_id == WINDOW_UNLOCK:
        if not is_window or broken or not locked:
            return "window_not_locked"
    elif action_id == WINDOW_CLIMB:
        if not is_window or boards > 0 or (not broken and not _state.window_open(target)):
            return "window_not_passable"
        if typeof(_window_climb_destination(actor, target)) != TYPE_VECTOR2I:
            return "window_climb_destination_blocked"
    elif action_id == OPENING_BOARD:
        if not (is_door or is_window) or broken or boards >= WorldInteractableState.MAX_BOARDS:
            return "opening_cannot_board"
        if is_door and _door_state.state(target) != DoorValue.CLOSED:
            return "close_door_before_boarding"
        if is_window and _state.window_open(target):
            return "close_window_before_boarding"
    elif action_id == OPENING_UNBOARD:
        if not (is_door or is_window) or boards <= 0:
            return "opening_not_boarded"
    elif action_id == OPENING_BREAK:
        if not (is_door or is_window) or broken:
            return "opening_already_broken"
    elif action_id == OBJECT_DECONSTRUCT:
        if _catalog.deconstruction_profile(semantic).is_empty():
            return "object_not_deconstructible"
        var placement: WorldPlacement = _world.placement(target)
        if placement == null or placement.channel != Layers.Channel.OBJECT:
            return "deconstruction_requires_object"
        if _inventory.has_container(target):
            return "searchable_container_deconstruction_not_yet_supported"
    return ""

func _base_duration(action_id: StringName, semantic: StringName, target: String) -> int:
    if action_id in [DOOR_OPEN, DOOR_CLOSE, WINDOW_OPEN, WINDOW_CLOSE]:
        return 3
    if action_id in [DOOR_LOCK, DOOR_UNLOCK, WINDOW_LOCK, WINDOW_UNLOCK]:
        return 4
    if action_id == WINDOW_CLIMB:
        return 6
    if action_id == OPENING_BOARD:
        return 12
    if action_id == OPENING_UNBOARD:
        return 10
    if action_id == OPENING_BREAK:
        return 8 + (_state.board_count(target) * 4)
    if action_id == OBJECT_DECONSTRUCT:
        return int(_catalog.deconstruction_profile(semantic).get("base_duration_ticks", 16))
    return 4

func _skill_difficulty(action_id: StringName, semantic: StringName) -> int:
    if action_id == OPENING_BOARD:
        return 2
    if action_id == OPENING_UNBOARD:
        return 1
    if action_id == OPENING_BREAK:
        return 2
    if action_id == OBJECT_DECONSTRUCT:
        return int(_catalog.deconstruction_profile(semantic).get("difficulty", 2))
    return -1

func _commit_board(action: TimedAction, target: String) -> bool:
    var materials: Array = action.payload.get("material_item_ids", [])
    if materials.size() != 2:
        return false
    var before: int = _state.board_count(target)
    if not _state.set_board_count(target, before + 1, &"opening_boarded"):
        return false
    if _consume_items_transaction(action.actor_id, materials):
        return true
    _state.set_board_count(target, before, &"boarding_rollback")
    return false

func _commit_unboard(action: TimedAction, target: String) -> bool:
    var before: int = _state.board_count(target)
    if before <= 0 or not _state.set_board_count(target, before - 1, &"board_removed"):
        return false
    if _create_recovered_items(action.actor_id, action.serial, PLANK, 1):
        return true
    _state.set_board_count(target, before, &"board_removal_rollback")
    return false

func _commit_break(action: TimedAction, target: String, semantic: StringName) -> bool:
    var before: Dictionary = _state.record(target)
    var previous_door_state: StringName = _door_state.state(target) if _door_state.has_door(target) else &""
    if not _state.set_broken(target, true, &"opening_broken"):
        return false
    if not _state.set_locked(target, false, &"broken_lock_destroyed") \
        or not _state.set_board_count(target, 0, &"broken_boards_destroyed"):
        _restore_target_state(target, before)
        return false
    if _catalog.is_window(semantic):
        if _state.set_window_open(target, true, &"broken_window_open"):
            return true
        _restore_target_state(target, before)
        return false
    if _catalog.is_door(semantic):
        if _door_transitions.open_for_passage(action.actor_id, target, &"door_broken"):
            return true
        _restore_target_state(target, before)
        if previous_door_state == DoorValue.CLOSED:
            _door_transitions.close_manually(action.actor_id, target)
        return false
    _restore_target_state(target, before)
    return false

func _restore_target_state(target: String, before: Dictionary) -> void:
    _state.set_locked(target, bool(before.get("locked", false)), &"interaction_rollback")
    _state.set_broken(target, bool(before.get("broken", false)), &"interaction_rollback")
    _state.set_board_count(target, int(before.get("board_count", 0)), &"interaction_rollback")
    _state.set_window_open(target, bool(before.get("window_open", false)), &"interaction_rollback")
    _state.set_destroyed(target, bool(before.get("destroyed", false)), &"interaction_rollback")

func _commit_window_climb(action: TimedAction, target: String) -> bool:
    var expected: Variant = action.payload.get("destination", null)
    var current: Variant = _window_climb_destination(action.actor_id, target)
    if typeof(expected) != TYPE_VECTOR2I or typeof(current) != TYPE_VECTOR2I or expected != current:
        return false
    var actor_placement: WorldPlacement = _world.placement(action.actor_id)
    if actor_placement == null:
        return false
    return _mutations.set_placement(
        action.actor_id,
        actor_placement.channel,
        current,
        actor_placement.facing,
        actor_placement.footprint
    )

func _window_climb_destination(actor_id: String, target_id: String) -> Variant:
    var actor: WorldPlacement = _world.placement(actor_id)
    var target: WorldPlacement = _world.placement(target_id)
    if actor == null or target == null or actor.footprint == null or actor.footprint.cell_count() != 1:
        return null
    var delta: Vector2i = target.anchor - actor.anchor
    if abs(delta.x) + abs(delta.y) != 1:
        return null
    var destination: Vector2i = target.anchor + delta
    var query: SpatialQueryResult = _spatial.query_entity_footprint(actor_id, destination, actor.facing, true)
    if query.status != QueryResult.Status.CLEAR:
        return null
    return destination

func _commit_deconstruct(action: TimedAction, target: String, semantic: StringName) -> bool:
    var profile: Dictionary = _catalog.deconstruction_profile(semantic)
    if profile.is_empty():
        return false
    var output_semantic := StringName(profile.get("output_semantic", &""))
    var output_count: int = int(profile.get("output_count", 0))
    if output_count < 1:
        return false
    var created: Array[String] = _create_recovered_items_with_ids(action.actor_id, action.serial, output_semantic, output_count)
    if created.size() != output_count:
        _rollback_created_items(created)
        return false
    if not _state.set_destroyed(target, true, &"object_deconstructed"):
        _rollback_created_items(created)
        return false
    if _mutations.remove_entity(target):
        return true
    _state.set_destroyed(target, false, &"deconstruction_rollback")
    _rollback_created_items(created)
    return false

func _create_recovered_items(actor_id: String, action_serial: int, semantic: StringName, count: int) -> bool:
    var created: Array[String] = _create_recovered_items_with_ids(actor_id, action_serial, semantic, count)
    if created.size() == count:
        return true
    _rollback_created_items(created)
    return false

func _create_recovered_items_with_ids(actor_id: String, action_serial: int, semantic: StringName, count: int) -> Array[String]:
    var result: Array[String] = []
    var actor_placement: WorldPlacement = _world.placement(actor_id)
    if actor_placement == null:
        return result
    for index in range(count):
        var item_id: String = "interaction.%d.%02d" % [action_serial, index]
        if _world.has_entity(item_id) or _mutations.create_entity(semantic, item_id) != item_id:
            return result
        var capacity: Dictionary = _capacity.evaluate(actor_id, item_id)
        var stored: bool = false
        if int(capacity.get("status", CapacityPolicyClass.Status.UNKNOWN)) == CapacityPolicyClass.Status.ALLOWED:
            stored = _inventory_mutations.set_container(item_id, actor_id)
        if not stored:
            if not _mutations.set_placement(
                item_id,
                Layers.Channel.LOOSE_ITEM,
                actor_placement.anchor,
                Facing.Value.SOUTH,
                Footprint.single_cell()
            ):
                _mutations.remove_entity(item_id)
                return result
        result.append(item_id)
    return result

func _rollback_created_items(ids: Array[String]) -> void:
    for index in range(ids.size() - 1, -1, -1):
        var item_id: String = ids[index]
        if _inventory.is_contained(item_id):
            _inventory_mutations.clear_container(item_id)
        if _world.has_entity(item_id):
            _mutations.remove_entity(item_id)

func _find_carried_any(actor_id: String, semantics: Array) -> String:
    var carry_result: Dictionary = _carry.query(actor_id)
    if int(carry_result.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return ""
    var allowed: Dictionary = {}
    for semantic: Variant in semantics:
        allowed[String(semantic)] = true
    var ids: Array[String] = []
    for value: Variant in carry_result.get("item_ids", []):
        ids.append(String(value))
    ids.sort()
    for item_id: String in ids:
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity != null and allowed.has(String(entity.semantic_type)):
            return item_id
    return ""

func _still_has_payload_items(actor_id: String, payload: Dictionary) -> bool:
    var required: Array[String] = []
    var tool: String = String(payload.get("tool_item_id", ""))
    if not tool.is_empty():
        required.append(tool)
    for value: Variant in payload.get("material_item_ids", []):
        required.append(String(value))
    if required.is_empty():
        return true
    var carry_result: Dictionary = _carry.query(actor_id)
    if int(carry_result.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return false
    var possessed: Dictionary = {}
    for value: Variant in carry_result.get("item_ids", []):
        possessed[String(value)] = true
    for item_id: String in required:
        if not possessed.has(item_id):
            return false
    return true

func _consume_items_transaction(actor_id: String, item_ids: Array) -> bool:
    var journal: Array[Dictionary] = []
    for value: Variant in item_ids:
        var entry: Dictionary = _capture_item(actor_id, String(value))
        if entry.is_empty():
            return false
        journal.append(entry)
    var removed: Array[Dictionary] = []
    for entry: Dictionary in journal:
        if not _remove_captured_item(entry):
            _restore_removed_items(removed)
            return false
        removed.append(entry)
    return true

func _capture_item(actor_id: String, item_id: String) -> Dictionary:
    if not _world.has_entity(item_id):
        return {}
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return {}
    var assignment: Dictionary = _hands.assignment_for_item(item_id)
    if not assignment.is_empty():
        if String(assignment.get("actor_id", "")) != actor_id:
            return {}
        return {
            "item_id": item_id,
            "semantic": entity.semantic_type,
            "kind": "hand",
            "actor": actor_id,
            "slot": int(assignment.get("slot", -1)),
            "container": "",
        }
    if _inventory.is_contained(item_id):
        var current: String = item_id
        var visited: Dictionary = {}
        while _inventory.is_contained(current) and not visited.has(current):
            visited[current] = true
            current = _inventory.container_of(current)
            if current == actor_id:
                return {
                    "item_id": item_id,
                    "semantic": entity.semantic_type,
                    "kind": "container",
                    "actor": actor_id,
                    "slot": -1,
                    "container": _inventory.container_of(item_id),
                }
    return {}

func _remove_captured_item(entry: Dictionary) -> bool:
    var item_id: String = String(entry.get("item_id", ""))
    var kind: String = String(entry.get("kind", ""))
    if kind == "hand":
        if not _hand_mutations.clear_slot(String(entry.get("actor", "")), int(entry.get("slot", -1))):
            return false
    elif kind == "container":
        if not _inventory_mutations.clear_container(item_id):
            return false
    else:
        return false
    if _mutations.remove_entity(item_id):
        return true
    _restore_relation(entry)
    return false

func _restore_removed_items(entries: Array[Dictionary]) -> void:
    for index in range(entries.size() - 1, -1, -1):
        var entry: Dictionary = entries[index]
        var item_id: String = String(entry.get("item_id", ""))
        if not _world.has_entity(item_id):
            _mutations.create_entity(StringName(entry.get("semantic", &"")), item_id)
        _restore_relation(entry)

func _restore_relation(entry: Dictionary) -> bool:
    var item_id: String = String(entry.get("item_id", ""))
    if String(entry.get("kind", "")) == "hand":
        return _hand_mutations.set_item(String(entry.get("actor", "")), int(entry.get("slot", -1)), item_id)
    return _inventory_mutations.set_container(item_id, String(entry.get("container", "")))

func _fail(action: TimedAction, reason: String) -> void:
    _outcomes[action.serial] = {"success": false, "reason": reason}
    if not _kernel.fail_action(action.serial, reason):
        push_error("WorldInteractionActionService: failed to mark action failed: %s" % reason)

func _on_state_changed(_target_id: String, _version: int, reason: StringName) -> void:
    availability_changed.emit(reason)

static func _rejected(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "reason": reason,
        "action_serial": 0,
        "duration_ticks": 0,
        "action_id": &"",
        "target_id": "",
    }
