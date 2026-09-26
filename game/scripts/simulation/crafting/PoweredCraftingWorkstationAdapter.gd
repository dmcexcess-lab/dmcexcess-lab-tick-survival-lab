extends Node
class_name PoweredCraftingWorkstationAdapter

## Small production composition adapter: System 32 already asks its owning runtime
## whether a workstation is currently usable; System 33 already owns live power truth.
## This binds those existing seams without creating another workstation state owner.

var _game: Node = null
var _world: WorldState = null
var _plans: CraftingPlanQuery = null
var _utilities: UtilityRuntimeState = null
var _bound: bool = false

func _ready() -> void:
    call_deferred("_bind_existing_owners")

func is_bound() -> bool:
    return _bound

func _bind_existing_owners() -> void:
    _game = get_parent()
    if _game == null:
        push_error("PoweredCraftingWorkstationAdapter: gameplay root missing")
        return
    _world = _game.get("_world") as WorldState
    _plans = _game.get("_crafting_plans") as CraftingPlanQuery
    _utilities = _game.get("_utilities") as UtilityRuntimeState
    if _world == null or _plans == null or not _plans.is_ready() or _utilities == null or not _utilities.is_ready():
        push_error("PoweredCraftingWorkstationAdapter: authoritative owners unavailable")
        return
    _bound = _plans.set_workstation_availability_provider(Callable(self, "_workstation_available"))
    if not _bound:
        push_error("PoweredCraftingWorkstationAdapter: availability provider bind failed")

func _workstation_available(_actor_id: String, workstation_id: String, capability: StringName) -> bool:
    if not _bound or _world == null or _utilities == null:
        return false
    if capability != CraftingWorkstationCatalog.COOKING_STOVE:
        return true
    var placement: WorldPlacement = _world.placement(workstation_id.strip_edges())
    return placement != null and _utilities.power_available_at_cell(placement.anchor)
