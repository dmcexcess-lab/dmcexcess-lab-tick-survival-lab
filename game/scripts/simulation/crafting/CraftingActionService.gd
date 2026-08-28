extends RefCounted
class_name CraftingActionService

const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const DispositionQueryClass = preload("res://scripts/simulation/items/transfer/ItemDispositionQuery.gd")
const DispositionResultClass = preload("res://scripts/simulation/items/transfer/ItemDispositionResult.gd")

## System 32 timed transformation coordinator. It owns no alternate inventory store:
## exact input entities are removed from their existing disposition at the final WHEN
## phase, output WHAT entities are created, then ordinary System 11 containment owns them.

signal craft_committed(actor_id, action_serial, recipe_id, output_item_ids)
signal craft_failed(actor_id, action_serial, recipe_id, reason)
signal craft_canceled(actor_id, action_serial, recipe_id, reason)

const ACTION_TYPE: StringName = &"crafting.craft_recipe"
const COMMIT_PHASE: StringName = &"crafting.commit"
const DIAGNOSTIC_LIMIT: int = 64

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _containment: InventoryContainmentState = null
var _containment_mutations: InventoryContainmentMutationService = null
var _kernel: TickKernel = null
var _recipes: CraftingRecipeCatalog = null
var _plans: CraftingPlanQuery = null
var _disposition: ItemDispositionQuery = null
var _commit_outcomes: Dictionary = {}
var _diagnostics: Array[Dictionary] = []
var _dev_fail_after_removed_inputs: int = -1

func _init(
    world_state: WorldState = null,
    world_mutation_service: WorldMutationService = null,
    hand_state: ActorHandEquipmentState = null,
    hand_mutation_service: ActorHandEquipmentMutationService = null,
    containment_state: InventoryContainmentState = null,
    containment_mutation_service: InventoryContainmentMutationService = null,
    tick_kernel: TickKernel = null,
    recipe_catalog: CraftingRecipeCatalog = null,
    plan_query: CraftingPlanQuery = null
) -> void:
    _world = world_state
    _world_mutations = world_mutation_service
    _hands = hand_state
    _hand_mutations = hand_mutation_service
    _containment = containment_state
    _containment_mutations = containment_mutation_service
    _kernel = tick_kernel
    _recipes = recipe_catalog
    _plans = plan_query
    if _world != null and _hands != null and _containment != null:
        _disposition = DispositionQueryClass.new(_world, _hands, _containment)
    if _kernel != null:
        if not _kernel.action_phase.is_connected(_on_action_phase):
            _kernel.action_phase.connect(_on_action_phase)
        if not _kernel.action_finished.is_connected(_on_action_finished):
            _kernel.action_finished.connect(_on_action_finished)

func is_ready() -> bool:
    return _world != null \
        and _world_mutations != null and _world_mutations.is_ready() \
        and _hands != null \
        and _hand_mutations != null and _hand_mutations.is_ready() \
        and _containment != null \
        and _containment_mutations != null and _containment_mutations.is_ready() \
        and _kernel != null \
        and _recipes != null \
        and _plans != null and _plans.is_ready() \
        and _disposition != null and _disposition.is_ready()

func recent_diagnostics() -> Array[Dictionary]:
    return _diagnostics.duplicate(true)

## DEV/CI-only fault injection for proving bounded compensation. Negative disables it.
func set_dev_failure_after_removed_inputs(count: int) -> void:
    _dev_fail_after_removed_inputs = count

func request_craft(actor_id: String, recipe_id: StringName, workstation_id: String = "") -> Dictionary:
    var actor: String = actor_id.strip_edges()
    if not is_ready():
        return _request_result(false, 0, actor, recipe_id, "crafting_not_ready")
    if actor.is_empty():
        return _request_result(false, 0, actor, recipe_id, "actor_missing")
    if _kernel.has_active_action(actor):
        return _request_result(false, 0, actor, recipe_id, "actor_busy")
    var plan: Dictionary = _plans.query(actor, recipe_id, workstation_id)
    if not bool(plan.get("ready", false)):
        return _request_result(false, 0, actor, recipe_id, String(plan.get("reason", "crafting_blocked")))
    var recipe_value: CraftingRecipe = _recipes.recipe(recipe_id)
    if recipe_value == null or recipe_value.duration_ticks < 1:
        return _request_result(false, 0, actor, recipe_id, "recipe_unknown")

    var payload: Dictionary = {
        "recipe_id": String(recipe_id),
        "recipe_catalog_version": int(plan.get("recipe_catalog_version", -1)),
        "consumed_item_ids": plan.get("consumed_item_ids", []).duplicate(),
        "tool_item_ids": plan.get("tool_item_ids", []).duplicate(),
        "workstation_id": String(plan.get("workstation_id", "")),
    }
    var phases: Array = [PhaseClass.new(COMMIT_PHASE, recipe_value.duration_ticks)]
    var serial: int = _kernel.begin_action(
        actor,
        ACTION_TYPE,
        recipe_value.duration_ticks,
        TickRulesClass.InterruptionPolicy.CANCELABLE,
        phases,
        payload
    )
    if serial <= 0:
        return _request_result(false, 0, actor, recipe_id, "when_rejected_craft")
    return _request_result(true, serial, actor, recipe_id, "")

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or action.action_type != ACTION_TYPE or phase == null or phase.phase_id != COMMIT_PHASE:
        return
    var recipe_id := StringName(String(action.payload.get("recipe_id", "")))
    var exact: Dictionary = _plans.validate_exact(
        action.actor_id,
        recipe_id,
        int(action.payload.get("recipe_catalog_version", -1)),
        action.payload.get("consumed_item_ids", []),
        action.payload.get("tool_item_ids", []),
        String(action.payload.get("workstation_id", ""))
    )
    if not bool(exact.get("ready", false)):
        _fail_during_commit(action, recipe_id, String(exact.get("reason", "crafting_plan_stale")))
        return
    var output_ids: Array = _output_ids(action.serial, exact.get("output_semantics", []))
    if output_ids.is_empty() or output_ids.size() != exact.get("output_semantics", []).size():
        _fail_during_commit(action, recipe_id, "output_identity_invalid")
        return
    for output_value: Variant in output_ids:
        if _world.has_entity(String(output_value)):
            _fail_during_commit(action, recipe_id, "output_identity_collision")
            return

    var journal: Array[Dictionary] = []
    for input_value: Variant in exact.get("consumed_item_ids", []):
        var captured: Dictionary = _capture_input(action.actor_id, String(input_value))
        if captured.is_empty():
            _fail_during_commit(action, recipe_id, "input_disposition_stale:%s" % String(input_value))
            return
        journal.append(captured)

    var removed: Array[Dictionary] = []
    var created_outputs: Array = []
    for entry: Dictionary in journal:
        var removal: Dictionary = _remove_input(entry)
        if not bool(removal.get("ok", false)):
            var restored: bool = bool(removal.get("source_restored", false)) and _rollback(created_outputs, removed)
            _fail_during_commit(action, recipe_id, "input_remove_failed" if restored else "critical_consistency_failure")
            return
        removed.append(entry.duplicate(true))
        if _dev_fail_after_removed_inputs >= 0 and removed.size() >= _dev_fail_after_removed_inputs:
            _dev_fail_after_removed_inputs = -1
            var restored: bool = _rollback(created_outputs, removed)
            _fail_during_commit(action, recipe_id, "dev_injected_commit_failure" if restored else "critical_consistency_failure")
            return

    var output_semantics: Array = exact.get("output_semantics", [])
    for index in range(output_ids.size()):
        var output_id: String = String(output_ids[index])
        var semantic := StringName(output_semantics[index])
        if _world_mutations.create_entity(semantic, output_id) != output_id:
            var restored: bool = _rollback(created_outputs, removed)
            _fail_during_commit(action, recipe_id, "output_create_failed" if restored else "critical_consistency_failure")
            return
        created_outputs.append(output_id)
        if not _containment_mutations.set_container(output_id, action.actor_id):
            var restored: bool = _rollback(created_outputs, removed)
            _fail_during_commit(action, recipe_id, "output_containment_failed" if restored else "critical_consistency_failure")
            return

    _commit_outcomes[action.serial] = {
        "success": true,
        "reason": "",
        "recipe_id": recipe_id,
        "output_item_ids": created_outputs.duplicate(),
    }

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != ACTION_TYPE:
        return
    var recipe_id := StringName(String(action.payload.get("recipe_id", "")))
    var outcome: Dictionary = _commit_outcomes.get(action.serial, {})
    if action.status == TickRulesClass.ActionStatus.COMPLETED and bool(outcome.get("success", false)):
        craft_committed.emit(action.actor_id, action.serial, recipe_id, outcome.get("output_item_ids", []).duplicate())
    elif action.status == TickRulesClass.ActionStatus.CANCELED:
        craft_canceled.emit(action.actor_id, action.serial, recipe_id, action.reason if not action.reason.is_empty() else "canceled")
    else:
        var reason: String = String(outcome.get("reason", action.reason))
        if reason.is_empty():
            reason = "craft_failed"
        craft_failed.emit(action.actor_id, action.serial, recipe_id, reason)
    _commit_outcomes.erase(action.serial)

func _fail_during_commit(action: TimedAction, recipe_id: StringName, reason: String) -> void:
    _commit_outcomes[action.serial] = {
        "success": false,
        "reason": reason,
        "recipe_id": recipe_id,
        "output_item_ids": [],
    }
    _diagnostics.append({
        "tick": _kernel.world_tick(),
        "action_serial": action.serial,
        "actor_id": action.actor_id,
        "recipe_id": recipe_id,
        "reason": reason,
    })
    while _diagnostics.size() > DIAGNOSTIC_LIMIT:
        _diagnostics.pop_front()
    _kernel.fail_action(action.serial, reason)

func _capture_input(actor_id: String, item_id: String) -> Dictionary:
    var disposition: ItemDispositionResult = _disposition.query(item_id)
    if disposition == null or not _world.has_entity(item_id):
        return {}
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return {}
    if disposition.status == DispositionResultClass.Status.HAND:
        if disposition.actor_id != actor_id:
            return {}
        return {
            "item_id": item_id,
            "semantic_type": entity.semantic_type,
            "kind": "hand",
            "actor_id": actor_id,
            "slot": disposition.slot,
            "container_id": "",
        }
    if disposition.status == DispositionResultClass.Status.CONTAINED:
        return {
            "item_id": item_id,
            "semantic_type": entity.semantic_type,
            "kind": "container",
            "actor_id": actor_id,
            "slot": -1,
            "container_id": disposition.container_id,
        }
    return {}

func _remove_input(entry: Dictionary) -> Dictionary:
    var item_id: String = String(entry.get("item_id", ""))
    var kind: String = String(entry.get("kind", ""))
    var source_cleared: bool = false
    if kind == "hand":
        source_cleared = _hand_mutations.clear_slot(String(entry.get("actor_id", "")), int(entry.get("slot", -1)))
    elif kind == "container":
        source_cleared = _containment_mutations.clear_container(item_id)
    if not source_cleared:
        return {"ok": false, "source_restored": true}
    if _world_mutations.remove_entity(item_id):
        return {"ok": true, "source_restored": false}
    return {"ok": false, "source_restored": _restore_source_relation(entry)}

func _rollback(created_outputs: Array, removed_inputs: Array[Dictionary]) -> bool:
    var ok: bool = true
    for index in range(created_outputs.size() - 1, -1, -1):
        var output_id: String = String(created_outputs[index])
        if _containment.is_contained(output_id) and not _containment_mutations.clear_container(output_id):
            ok = false
        if _world.has_entity(output_id) and not _world_mutations.remove_entity(output_id):
            ok = false
    for index in range(removed_inputs.size() - 1, -1, -1):
        var entry: Dictionary = removed_inputs[index]
        var item_id: String = String(entry.get("item_id", ""))
        if not _world.has_entity(item_id):
            var recreated: String = _world_mutations.create_entity(StringName(entry.get("semantic_type", &"")), item_id)
            if recreated != item_id:
                ok = false
                continue
        if not _restore_source_relation(entry):
            ok = false
    return ok

func _restore_source_relation(entry: Dictionary) -> bool:
    var item_id: String = String(entry.get("item_id", ""))
    if item_id.is_empty() or not _world.has_entity(item_id) or _world.has_placement(item_id):
        return false
    var kind: String = String(entry.get("kind", ""))
    if kind == "hand":
        var actor_id: String = String(entry.get("actor_id", ""))
        var slot: int = int(entry.get("slot", -1))
        if _hands.item_in_slot(actor_id, slot) == item_id:
            return true
        if not _hands.item_in_slot(actor_id, slot).is_empty():
            return false
        return _hand_mutations.set_item(actor_id, slot, item_id)
    if kind == "container":
        var container_id: String = String(entry.get("container_id", ""))
        if _containment.container_of(item_id) == container_id:
            return true
        if _containment.is_contained(item_id):
            return false
        return _containment_mutations.set_container(item_id, container_id)
    return false

static func _output_ids(action_serial: int, output_semantics: Array) -> Array:
    var result: Array = []
    if action_serial < 1 or output_semantics.is_empty():
        return result
    for index in range(output_semantics.size()):
        result.append("craft_%016d_%02d" % [action_serial, index])
    return result

static func _request_result(accepted: bool, serial: int, actor_id: String, recipe_id: StringName, reason: String) -> Dictionary:
    return {
        "accepted": accepted,
        "action_serial": serial,
        "actor_id": actor_id,
        "recipe_id": recipe_id,
        "reason": reason,
    }
