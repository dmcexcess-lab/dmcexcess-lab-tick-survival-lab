extends RefCounted
class_name CraftingPlayerInteractionController

signal open_requested(workstation_id)
signal action_resolved(recipe_id, success, reason, world_tick, workstation_id)

var _crafting: CraftingActionService = null
var _affordances: InteractionAffordanceQuery = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _outcomes: Dictionary = {}

func _init(
    crafting_service: CraftingActionService = null,
    affordance_query: InteractionAffordanceQuery = null,
    tick_kernel: TickKernel = null,
    actor_id: String = ""
) -> void:
    _crafting = crafting_service
    _affordances = affordance_query
    _kernel = tick_kernel
    _actor_id = actor_id.strip_edges()
    if _crafting != null:
        _crafting.craft_committed.connect(_on_craft_committed)
        _crafting.craft_failed.connect(_on_craft_failed)
        _crafting.craft_canceled.connect(_on_craft_canceled)

func is_ready() -> bool:
    return _crafting != null and _crafting.is_ready() \
        and _affordances != null and _affordances.is_ready() \
        and _kernel != null and not _actor_id.is_empty()

func request_open_global() -> void:
    if is_ready():
        open_requested.emit("")

## Exact-target zero-time browse seam used by the unified world interaction chooser.
## The affordance must still be current; this method does not bypass reach/perception.
func request_open_workstation(workstation_id: String) -> bool:
    if not is_ready():
        return false
    var target: String = workstation_id.strip_edges()
    if target.is_empty():
        return false
    for descriptor: Dictionary in _affordances.highlight_descriptors():
        if String(descriptor.get("target_entity_id", "")) != target:
            continue
        var actions: Array = descriptor.get("action_ids", [])
        if not actions.has(String(CraftingInteractionOfferProvider.ACTION_ID)):
            continue
        open_requested.emit(target)
        return true
    return false

## Historical/shared pointer seam retained for focused fixtures. Production composition
## routes world clicks through WorldInteractionPlayerController before delegating here.
func submit_world_cell(cell: Vector2i) -> void:
    if not is_ready():
        return
    var matches: Array[String] = []
    for descriptor: Dictionary in _affordances.highlight_descriptors():
        var actions: Array = descriptor.get("action_ids", [])
        var cells: Array = descriptor.get("visible_cells", [])
        if not actions.has(String(CraftingInteractionOfferProvider.ACTION_ID)) or not cells.has(cell):
            continue
        matches.append(String(descriptor.get("target_entity_id", "")))
    matches.sort()
    if matches.size() == 1 and not matches[0].is_empty():
        request_open_workstation(matches[0])

func request_craft(recipe_id: StringName, workstation_id: String = "") -> void:
    if not is_ready():
        action_resolved.emit(recipe_id, false, "crafting_input_not_ready", _tick(), workstation_id)
        return
    var result: Dictionary = _crafting.request_craft(_actor_id, recipe_id, workstation_id)
    if not bool(result.get("accepted", false)):
        action_resolved.emit(recipe_id, false, String(result.get("reason", "craft_rejected")), _tick(), workstation_id)
        return
    var serial: int = int(result.get("action_serial", 0))
    _outcomes.erase(serial)
    _kernel.run_until_stop()
    var outcome: Dictionary = _outcomes.get(serial, {})
    action_resolved.emit(
        recipe_id,
        bool(outcome.get("success", false)),
        String(outcome.get("reason", "" if bool(outcome.get("success", false)) else "action_unresolved")),
        _tick(),
        workstation_id
    )
    _outcomes.erase(serial)

func _on_craft_committed(actor_id: String, serial: int, _recipe_id: StringName, output_item_ids: Array) -> void:
    if actor_id == _actor_id:
        _outcomes[serial] = {"success": true, "reason": "", "output_item_ids": output_item_ids.duplicate()}

func _on_craft_failed(actor_id: String, serial: int, _recipe_id: StringName, reason: String) -> void:
    if actor_id == _actor_id:
        _outcomes[serial] = {"success": false, "reason": reason}

func _on_craft_canceled(actor_id: String, serial: int, _recipe_id: StringName, reason: String) -> void:
    if actor_id == _actor_id:
        _outcomes[serial] = {"success": false, "reason": reason}

func _tick() -> int:
    return 0 if _kernel == null else _kernel.world_tick()
