extends RefCounted
class_name WorldObjectRepairActionService

const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

## Mechanical repair action for existing broken world objects. Persistent damage truth
## remains in WorldInteractableState; this service owns only prerequisite validation,
## WHEN timing, Mechanical resolution, exact resource consumption and transactional repair.

signal action_resolved(actor_id, action_serial, target_id, success, reason)

const ACTION_ID: StringName = &"world.repair"
const ACTION_TYPE: StringName = &"world.object_repair"
const COMMIT_PHASE: StringName = &"world.object_repair.commit"

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _door_state: DoorStateStore = null
var _door_transitions: DoorPhysicalTransitionService = null
var _reach: WorldInteractionReachQuery = null
var _kernel: TickKernel = null
var _skill_checks: ActorSkillCheckService = null
var _carry: ActorCarryQuery = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _state: WorldInteractableState = null
var _catalog: WorldInteractionCatalog = null
var _outcomes: Dictionary = {}

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    door_state: DoorStateStore = null,
    door_transitions: DoorPhysicalTransitionService = null,
    reach: WorldInteractionReachQuery = null,
    kernel: TickKernel = null,
    skill_checks: ActorSkillCheckService = null,
    carry: ActorCarryQuery = null,
    hands: ActorHandEquipmentState = null,
    hand_mutations: ActorHandEquipmentMutationService = null,
    inventory: InventoryContainmentState = null,
    inventory_mutations: InventoryContainmentMutationService = null,
    state: WorldInteractableState = null,
    catalog: WorldInteractionCatalog = null
) -> void:
    _world = world
    _mutations = mutations
    _door_state = door_state
    _door_transitions = door_transitions
    _reach = reach
    _kernel = kernel
    _skill_checks = skill_checks
    _carry = carry
    _hands = hands
    _hand_mutations = hand_mutations
    _inventory = inventory
    _inventory_mutations = inventory_mutations
    _state = state
    _catalog = catalog
    if _kernel != null:
        var phase_callback := Callable(self, "_on_action_phase")
        var finished_callback := Callable(self, "_on_action_finished")
        if not _kernel.action_phase.is_connected(phase_callback):
            _kernel.action_phase.connect(phase_callback)
        if not _kernel.action_finished.is_connected(finished_callback):
            _kernel.action_finished.connect(finished_callback)

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _door_state != null and _door_transitions != null and _door_transitions.is_ready() \
        and _reach != null and _reach.is_ready() and _kernel != null \
        and _skill_checks != null and _skill_checks.is_ready() and _carry != null \
        and _hands != null and _hand_mutations != null and _hand_mutations.is_ready() \
        and _inventory != null and _inventory_mutations != null and _inventory_mutations.is_ready() \
        and _state != null and _catalog != null

func request_action(actor_id: String, target_id: String, action_id: StringName = ACTION_ID) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    var target: String = target_id.strip_edges()
    if action_id != ACTION_ID:
        return _rejected("repair_action_unknown")
    if not is_ready():
        return _rejected("world_repair_not_ready")
    if actor.is_empty() or target.is_empty() or not _world.has_entity(actor) or not _world.has_entity(target):
        return _rejected("repair_target_missing")
    if _kernel.is_hard_paused():
        return _rejected("hard_paused")
    if _kernel.has_active_action(actor):
        return _rejected("actor_busy")
    if not _reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return _rejected("target_out_of_reach")

    var entity: WorldEntityRecord = _world.entity(target)
    var placement: WorldPlacement = _world.placement(target)
    if entity == null or placement == null or _state.is_destroyed(target):
        return _rejected("repair_target_unavailable")
    var profile: Dictionary = _catalog.repair_profile(entity.semantic_type)
    if profile.is_empty():
        return _rejected("object_not_repairable")
    if not _state.is_broken(target):
        return _rejected("target_not_broken")
    if StringName(profile.get("repair_kind", &"")) == &"door" and not _door_state.has_door(target):
        return _rejected("repair_door_state_missing")

    var tool_id: String = _find_carried_any(actor, profile.get("tool_semantics", []), {})
    if tool_id.is_empty():
        return _rejected("repair_tool_required")

    var used: Dictionary = {tool_id: true}
    var material_ids: Array[String] = []
    for semantic_value: Variant in profile.get("material_semantics", []):
        var material_id: String = _find_carried_any(actor, [StringName(semantic_value)], used)
        if material_id.is_empty():
            return _rejected("repair_material_required")
        used[material_id] = true
        material_ids.append(material_id)

    var base_duration: int = int(profile.get("base_duration_ticks", 16))
    var difficulty: int = int(profile.get("difficulty", 3))
    if base_duration < 1 or difficulty < 0:
        return _rejected("repair_profile_invalid")
    var skill_profile: Dictionary = _skill_checks.action_profile(actor, SkillCatalog.MECHANICAL, base_duration, difficulty)
    if not bool(skill_profile.get("ok", false)):
        return _rejected(String(skill_profile.get("reason", "mechanical_skill_unavailable")))
    var duration: int = int(skill_profile.get("duration_ticks", 0))
    var skill_level: int = int(skill_profile.get("skill_level", -1))
    if duration < 1 or skill_level < 0:
        return _rejected("repair_skill_profile_invalid")

    var payload: Dictionary = {
        "target_id": target,
        "semantic_type": String(entity.semantic_type),
        "repair_kind": String(profile.get("repair_kind", &"")),
        "state_version": _state.version(target),
        "door_version": _door_state.version(target) if _door_state.has_door(target) else 0,
        "skill_difficulty": difficulty,
        "skill_level": skill_level,
        "tool_item_id": tool_id,
        "material_item_ids": material_ids,
    }
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
        return _rejected("when_rejected_world_repair")
    return {
        "accepted": true,
        "reason": "",
        "action_serial": serial,
        "duration_ticks": duration,
        "action_id": ACTION_ID,
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
    var outcome: Dictionary = _outcomes.get(action.serial, {})
    var success: bool = action.status == TickRulesClass.ActionStatus.COMPLETED and bool(outcome.get("success", false))
    var reason: String = String(outcome.get("reason", action.reason))
    if success and reason.is_empty():
        reason = "completed"
    elif not success and reason.is_empty():
        reason = "world_repair_failed"
    action_resolved.emit(action.actor_id, action.serial, target_id, success, reason)
    _outcomes.erase(action.serial)

func _commit(action: TimedAction) -> void:
    var actor: String = action.actor_id
    var target: String = String(action.payload.get("target_id", ""))
    if not _world.has_entity(actor) or not _world.has_entity(target):
        _fail(action, "repair_target_missing_at_commit")
        return
    var entity: WorldEntityRecord = _world.entity(target)
    if entity == null or String(entity.semantic_type) != String(action.payload.get("semantic_type", "")):
        _fail(action, "repair_target_semantic_changed")
        return
    if _state.version(target) != int(action.payload.get("state_version", -1)):
        _fail(action, "repair_target_state_changed")
        return
    if _door_state.has_door(target) and _door_state.version(target) != int(action.payload.get("door_version", -1)):
        _fail(action, "repair_door_state_changed")
        return
    if not _reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        _fail(action, "target_out_of_reach")
        return
    if not _state.is_broken(target):
        _fail(action, "target_no_longer_broken")
        return
    var profile: Dictionary = _catalog.repair_profile(entity.semantic_type)
    if profile.is_empty() or String(profile.get("repair_kind", &"")) != String(action.payload.get("repair_kind", "")):
        _fail(action, "repair_profile_changed")
        return
    if not _still_has_payload_items(actor, action.payload):
        _fail(action, "required_item_no_longer_carried")
        return

    var difficulty: int = int(action.payload.get("skill_difficulty", -1))
    var skill: Dictionary = _skill_checks.resolve_attempt(
        actor,
        SkillCatalog.MECHANICAL,
        difficulty,
        action.serial,
        StringName("world.repair|%s" % target),
        int(action.payload.get("skill_level", -1))
    )
    if not bool(skill.get("ok", false)):
        _fail(action, String(skill.get("reason", "mechanical_skill_unavailable")))
        return
    if not bool(skill.get("success", false)):
        _skill_checks.award_attempt_xp(actor, SkillCatalog.MECHANICAL, difficulty, false)
        _fail(action, "mechanical_skill_check_failed")
        return

    var ok: bool = false
    if StringName(profile.get("repair_kind", &"")) == &"door":
        ok = _commit_door_repair(action, target)
    if not ok:
        _fail(action, "world_repair_commit_failed")
        return
    if not _skill_checks.award_attempt_xp(actor, SkillCatalog.MECHANICAL, difficulty, true):
        _fail(action, "mechanical_xp_commit_failed")
        return
    _outcomes[action.serial] = {"success": true, "reason": "completed"}

func _commit_door_repair(action: TimedAction, target: String) -> bool:
    if not _door_state.has_door(target) or not _state.is_broken(target):
        return false
    var previous_door_state: StringName = _door_state.state(target)
    if previous_door_state != DoorValue.OPEN and previous_door_state != DoorValue.CLOSED:
        return false
    var materials: Array = action.payload.get("material_item_ids", [])
    if materials.size() != 2:
        return false

    if previous_door_state == DoorValue.OPEN and not _door_transitions.close_manually(action.actor_id, target):
        return false
    if not _state.set_broken(target, false, &"door_repaired"):
        _restore_door_position(action.actor_id, target, previous_door_state)
        return false
    if _consume_items_transaction(action.actor_id, materials):
        return true

    _state.set_broken(target, true, &"door_repair_rollback")
    _restore_door_position(action.actor_id, target, previous_door_state)
    return false

func _restore_door_position(actor_id: String, target: String, previous_state: StringName) -> void:
    var current: StringName = _door_state.state(target)
    if previous_state == DoorValue.OPEN and current != DoorValue.OPEN:
        _door_transitions.open_manually(actor_id, target)
    elif previous_state == DoorValue.CLOSED and current != DoorValue.CLOSED:
        _door_transitions.close_manually(actor_id, target)

func _find_carried_any(actor_id: String, semantics: Array, excluded_ids: Dictionary) -> String:
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
        if excluded_ids.has(item_id):
            continue
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity != null and allowed.has(String(entity.semantic_type)):
            return item_id
    return ""

func _still_has_payload_items(actor_id: String, payload: Dictionary) -> bool:
    var required: Array[String] = [String(payload.get("tool_item_id", ""))]
    for value: Variant in payload.get("material_item_ids", []):
        required.append(String(value))
    var carry_result: Dictionary = _carry.query(actor_id)
    if int(carry_result.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return false
    var possessed: Dictionary = {}
    for value: Variant in carry_result.get("item_ids", []):
        possessed[String(value)] = true
    for item_id: String in required:
        if item_id.is_empty() or not possessed.has(item_id):
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
        push_error("WorldObjectRepairActionService: failed to mark action failed: %s" % reason)

static func _rejected(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "reason": reason,
        "action_serial": 0,
        "duration_ticks": 0,
        "action_id": ACTION_ID,
        "target_id": "",
    }
