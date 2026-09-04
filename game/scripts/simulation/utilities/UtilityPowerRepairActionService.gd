extends RefCounted
class_name UtilityPowerRepairActionService

const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const ConditionStore = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")

## Player-facing repair for physical local-distribution supports. Utility condition and
## outage truth remain owned by UtilityPowerNetworkRuntime. This layer translates real
## carried resources + Mechanical + WHEN into that existing owner and rolls it back if
## exact material consumption cannot commit.

signal action_resolved(actor_id, action_serial, target_id, success, reason)

const ACTION_ID: StringName = &"utility.power_repair"
const ACTION_TYPE: StringName = &"utility.power_repair"
const COMMIT_PHASE: StringName = &"utility.power_repair.commit"
const SUPPORTED_SEMANTIC: StringName = &"prop.utility_pole_wood"
const HAMMER: StringName = &"item.tool.hammer"
const WOOD_PLANK: StringName = &"item.material.wood_plank"
const NAILS: StringName = &"item.material.nails_box"
const BASE_DURATION_TICKS: int = 20

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _reach: WorldInteractionReachQuery = null
var _kernel: TickKernel = null
var _skill_checks: ActorSkillCheckService = null
var _carry: ActorCarryQuery = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _network: UtilityPowerNetworkRuntime = null
var _outcomes: Dictionary = {}

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    reach: WorldInteractionReachQuery = null,
    kernel: TickKernel = null,
    skill_checks: ActorSkillCheckService = null,
    carry: ActorCarryQuery = null,
    hands: ActorHandEquipmentState = null,
    hand_mutations: ActorHandEquipmentMutationService = null,
    inventory: InventoryContainmentState = null,
    inventory_mutations: InventoryContainmentMutationService = null,
    network: UtilityPowerNetworkRuntime = null
) -> void:
    _world = world
    _mutations = mutations
    _reach = reach
    _kernel = kernel
    _skill_checks = skill_checks
    _carry = carry
    _hands = hands
    _hand_mutations = hand_mutations
    _inventory = inventory
    _inventory_mutations = inventory_mutations
    _network = network
    if _kernel != null:
        var phase_callback := Callable(self, "_on_action_phase")
        var finished_callback := Callable(self, "_on_action_finished")
        if not _kernel.action_phase.is_connected(phase_callback):
            _kernel.action_phase.connect(phase_callback)
        if not _kernel.action_finished.is_connected(finished_callback):
            _kernel.action_finished.connect(finished_callback)

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _reach != null and _reach.is_ready() and _kernel != null \
        and _skill_checks != null and _skill_checks.is_ready() and _carry != null \
        and _hands != null and _hand_mutations != null and _hand_mutations.is_ready() \
        and _inventory != null and _inventory_mutations != null and _inventory_mutations.is_ready() \
        and _network != null and _network.is_ready()

func request_action(actor_id: String, target_id: String, action_id: StringName = ACTION_ID) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    var target: String = target_id.strip_edges()
    if action_id != ACTION_ID:
        return _rejected("utility_repair_action_unknown")
    if not is_ready():
        return _rejected("utility_repair_not_ready")
    if actor.is_empty() or target.is_empty() or not _world.has_entity(actor) or not _world.has_entity(target):
        return _rejected("utility_repair_target_missing")
    if _kernel.is_hard_paused():
        return _rejected("hard_paused")
    if _kernel.has_active_action(actor):
        return _rejected("actor_busy")
    if not _reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        return _rejected("target_out_of_reach")

    var entity: WorldEntityRecord = _world.entity(target)
    if entity == null or entity.semantic_type != SUPPORTED_SEMANTIC:
        return _rejected("utility_repair_target_unsupported")
    var asset: Dictionary = _network.asset_record(target)
    if asset.is_empty() \
        or StringName(asset.get("kind", &"")) != ConditionStore.DISTRIBUTION_SUPPORT \
        or String(asset.get("entity_id", "")) != target:
        return _rejected("utility_repair_asset_missing")
    if not bool(asset.get("failed", false)):
        return _rejected("utility_asset_not_failed")

    var requirements: Dictionary = _network.repair_requirements(target)
    var required_skill: int = int(requirements.get("mechanical_skill", -1))
    var material_units: int = int(requirements.get("material_units", -1))
    if required_skill < 0 or material_units != 2:
        return _rejected("utility_repair_profile_unsupported")

    var used: Dictionary = {}
    var hammer_id: String = _find_carried(actor, HAMMER, used)
    if hammer_id.is_empty():
        return _rejected("repair_tool_required")
    used[hammer_id] = true
    var plank_ids: Array[String] = []
    for _index: int in range(material_units):
        var plank_id: String = _find_carried(actor, WOOD_PLANK, used)
        if plank_id.is_empty():
            return _rejected("repair_material_required")
        used[plank_id] = true
        plank_ids.append(plank_id)
    var nails_id: String = _find_carried(actor, NAILS, used)
    if nails_id.is_empty():
        return _rejected("repair_fasteners_required")

    var skill_profile: Dictionary = _skill_checks.action_profile(
        actor,
        SkillCatalog.MECHANICAL,
        BASE_DURATION_TICKS,
        required_skill
    )
    if not bool(skill_profile.get("ok", false)):
        return _rejected(String(skill_profile.get("reason", "mechanical_skill_unavailable")))
    var duration: int = int(skill_profile.get("duration_ticks", 0))
    var skill_level: int = int(skill_profile.get("skill_level", -1))
    if duration < 1 or skill_level < required_skill:
        return _rejected("insufficient_mechanical_skill")

    var material_ids: Array[String] = plank_ids.duplicate()
    material_ids.append(nails_id)
    var payload: Dictionary = {
        "target_id": target,
        "semantic_type": String(entity.semantic_type),
        "asset_condition": int(asset.get("derived_condition", -1)),
        "skill_difficulty": required_skill,
        "skill_level": skill_level,
        "material_units": material_units,
        "tool_item_id": hammer_id,
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
        return _rejected("when_rejected_utility_repair")
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
        reason = "utility_repair_failed"
    action_resolved.emit(action.actor_id, action.serial, target_id, success, reason)
    _outcomes.erase(action.serial)

func _commit(action: TimedAction) -> void:
    var actor: String = action.actor_id
    var target: String = String(action.payload.get("target_id", ""))
    if not _world.has_entity(actor) or not _world.has_entity(target):
        _fail(action, "utility_repair_target_missing_at_commit")
        return
    var entity: WorldEntityRecord = _world.entity(target)
    if entity == null or String(entity.semantic_type) != String(action.payload.get("semantic_type", "")):
        _fail(action, "utility_repair_target_semantic_changed")
        return
    if not _reach.target_reachable(actor, target, WorldInteractionReachQuery.CONTACT_FORWARD):
        _fail(action, "target_out_of_reach")
        return

    var asset: Dictionary = _network.asset_record(target)
    if asset.is_empty() \
        or StringName(asset.get("kind", &"")) != ConditionStore.DISTRIBUTION_SUPPORT \
        or String(asset.get("entity_id", "")) != target \
        or not bool(asset.get("failed", false)):
        _fail(action, "utility_repair_asset_changed")
        return
    if int(asset.get("derived_condition", -1)) != int(action.payload.get("asset_condition", -2)):
        _fail(action, "utility_repair_condition_changed")
        return
    if not _still_has_payload_items(actor, action.payload):
        _fail(action, "required_item_no_longer_carried")
        return

    var difficulty: int = int(action.payload.get("skill_difficulty", -1))
    var skill_level: int = int(action.payload.get("skill_level", -1))
    var skill: Dictionary = _skill_checks.resolve_attempt(
        actor,
        SkillCatalog.MECHANICAL,
        difficulty,
        action.serial,
        StringName("utility.power_repair|%s" % target),
        skill_level
    )
    if not bool(skill.get("ok", false)):
        _fail(action, String(skill.get("reason", "mechanical_skill_unavailable")))
        return
    var skill_success: bool = bool(skill.get("success", false))
    _skill_checks.award_attempt_xp(actor, SkillCatalog.MECHANICAL, difficulty, skill_success)
    if not skill_success:
        _fail(action, "mechanical_skill_check_failed")
        return

    var before_snapshot: Dictionary = _network.snapshot()
    if before_snapshot.is_empty():
        _fail(action, "utility_repair_snapshot_failed")
        return
    var owner_result: Dictionary = _network.repair_asset(
        target,
        skill_level,
        int(action.payload.get("material_units", 0))
    )
    if not bool(owner_result.get("ok", false)):
        _fail(action, String(owner_result.get("reason", "utility_owner_repair_failed")))
        return
    if int(owner_result.get("material_units_consumed", -1)) != int(action.payload.get("material_units", -2)):
        if not _network.restore_snapshot(before_snapshot):
            push_error("UtilityPowerRepairActionService: failed owner rollback after material-unit mismatch")
        _fail(action, "utility_owner_material_mismatch")
        return

    var material_ids: Array = action.payload.get("material_item_ids", [])
    if not _consume_items_transaction(actor, material_ids):
        if not _network.restore_snapshot(before_snapshot):
            push_error("UtilityPowerRepairActionService: failed owner rollback after item commit failure")
        _fail(action, "utility_repair_material_commit_failed")
        return
    _outcomes[action.serial] = {"success": true, "reason": "completed"}

func _find_carried(actor_id: String, semantic: StringName, excluded: Dictionary) -> String:
    var carry_result: Dictionary = _carry.query(actor_id)
    if int(carry_result.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return ""
    var ids: Array[String] = []
    for value: Variant in carry_result.get("item_ids", []):
        ids.append(String(value))
    ids.sort()
    for item_id: String in ids:
        if excluded.has(item_id):
            continue
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity != null and entity.semantic_type == semantic:
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
        push_error("UtilityPowerRepairActionService: failed to mark action failed: %s" % reason)

static func _rejected(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "reason": reason,
        "action_serial": 0,
        "duration_ticks": 0,
        "action_id": ACTION_ID,
        "target_id": "",
    }
