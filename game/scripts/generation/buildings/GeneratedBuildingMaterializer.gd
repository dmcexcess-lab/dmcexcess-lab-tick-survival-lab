extends RefCounted
class_name GeneratedBuildingMaterializer

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _door_state: DoorStateStore = null
var _door_mutations: DoorStateMutationService = null
var _validator: GeneratedBuildingValidator = null

func _init(
    world_state: WorldState = null,
    world_mutations: WorldMutationService = null,
    door_state: DoorStateStore = null,
    door_mutations: DoorStateMutationService = null,
    validator: GeneratedBuildingValidator = null
) -> void:
    _world = world_state
    _mutations = world_mutations
    _door_state = door_state
    _door_mutations = door_mutations
    _validator = validator

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _door_state != null and _door_mutations != null and _door_mutations.is_ready() \
        and _validator != null

## Standalone building transaction. Existing callers retain exact rollback behavior.
func materialize(plan: GeneratedBuildingPlan) -> bool:
    return _materialize(plan, true)

## Used only when an enclosing owner (currently System 20/00F) already owns rollback.
## Failure may leave partial writes for that caller to restore; this avoids a full-world snapshot per building.
func materialize_in_transaction(plan: GeneratedBuildingPlan) -> bool:
    return _materialize(plan, false)

func _materialize(plan: GeneratedBuildingPlan, owns_transaction: bool) -> bool:
    if not is_ready():
        return false
    var validation: Dictionary = _validator.validate(plan)
    if not bool(validation.get("ok", false)):
        return false
    if not _preflight(plan):
        return false

    var world_snapshot: Dictionary = {}
    var door_snapshot: Dictionary = {}
    if owns_transaction:
        world_snapshot = _world.snapshot()
        door_snapshot = _door_state.snapshot()

    if not _materialize_ground_entries(plan):
        return _rollback_if_owned(owns_transaction, world_snapshot, door_snapshot)
    for entry: Dictionary in plan.structures:
        var entity_id: String = plan.entity_id_for_role(String(entry.get("role", "")))
        if entity_id.is_empty() or _mutations.create_entity(entry.get("semantic", &""), entity_id) != entity_id:
            return _rollback_if_owned(owns_transaction, world_snapshot, door_snapshot)
        if not _mutations.set_placement(
            entity_id,
            Layers.Channel.STRUCTURE,
            entry.get("cell", Vector2i.ZERO),
            int(entry.get("facing", Facing.Value.NORTH)),
            Footprint.single_cell(),
            int(entry.get("axis", -1))
        ):
            return _rollback_if_owned(owns_transaction, world_snapshot, door_snapshot)
        if String(entry.get("kind", "")) == "door":
            if not _door_mutations.enroll(entity_id, DoorValue.CLOSED):
                return _rollback_if_owned(owns_transaction, world_snapshot, door_snapshot)
    for entry: Dictionary in plan.props:
        var entity_id: String = plan.entity_id_for_role(String(entry.get("role", "")))
        if entity_id.is_empty() or _mutations.create_entity(entry.get("semantic", &""), entity_id) != entity_id:
            return _rollback_if_owned(owns_transaction, world_snapshot, door_snapshot)
        if not _mutations.set_placement(
            entity_id,
            Layers.Channel.OBJECT,
            entry.get("cell", Vector2i.ZERO),
            int(entry.get("facing", Facing.Value.NORTH)),
            Footprint.single_cell()
        ):
            return _rollback_if_owned(owns_transaction, world_snapshot, door_snapshot)
    return true

## Preserve the original ground-entry order exactly while coalescing consecutive equal semantics.
## This keeps any intentional later overwrite behavior while reducing one change/revision per floor cell
## to one change/revision per semantic run.
func _materialize_ground_entries(plan: GeneratedBuildingPlan) -> bool:
    var run_semantic: StringName = &""
    var run_cells: Array[Vector2i] = []
    for entry: Dictionary in plan.ground_entries:
        var semantic: StringName = StringName(entry.get("semantic", &""))
        var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
        if semantic == &"":
            return false
        if run_semantic != &"" and semantic != run_semantic:
            if not _mutations.set_terrain_cells(run_cells, run_semantic):
                return false
            run_cells.clear()
        run_semantic = semantic
        run_cells.append(cell)
    if run_semantic != &"" and not run_cells.is_empty():
        return _mutations.set_terrain_cells(run_cells, run_semantic)
    return true

func _preflight(plan: GeneratedBuildingPlan) -> bool:
    var planned_ids: Dictionary = {}
    for entry: Dictionary in plan.structures + plan.props:
        var role: String = String(entry.get("role", ""))
        var entity_id: String = plan.entity_id_for_role(role)
        if entity_id.is_empty() or planned_ids.has(entity_id) or _world.has_entity(entity_id):
            return false
        planned_ids[entity_id] = true
        var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
        for channel: int in [Layers.Channel.STRUCTURE, Layers.Channel.OBJECT, Layers.Channel.ACTOR, Layers.Channel.LOOSE_ITEM]:
            if not _world.entities_at(cell, channel).is_empty():
                return false
    return true

func _rollback_if_owned(owns_transaction: bool, world_snapshot: Dictionary, door_snapshot: Dictionary) -> bool:
    if not owns_transaction:
        return false
    _world.load_snapshot(world_snapshot)
    _door_state.load_snapshot(door_snapshot)
    return false
