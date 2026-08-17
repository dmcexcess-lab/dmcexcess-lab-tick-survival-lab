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

func materialize(plan: GeneratedBuildingPlan) -> bool:
    if not is_ready():
        return false
    var validation: Dictionary = _validator.validate(plan)
    if not bool(validation.get("ok", false)):
        return false
    if not _preflight(plan):
        return false

    var world_snapshot: Dictionary = _world.snapshot()
    var door_snapshot: Dictionary = _door_state.snapshot()
    for entry: Dictionary in plan.ground_entries:
        if not _mutations.set_terrain(entry.get("cell", Vector2i.ZERO), entry.get("semantic", &"")):
            return _rollback(world_snapshot, door_snapshot)
    for entry: Dictionary in plan.structures:
        var entity_id: String = _entity_id(plan.instance_id, String(entry.get("role", "")))
        if _mutations.create_entity(entry.get("semantic", &""), entity_id) != entity_id:
            return _rollback(world_snapshot, door_snapshot)
        if not _mutations.set_placement(
            entity_id,
            Layers.Channel.STRUCTURE,
            entry.get("cell", Vector2i.ZERO),
            int(entry.get("facing", Facing.Value.NORTH)),
            Footprint.single_cell(),
            int(entry.get("axis", -1))
        ):
            return _rollback(world_snapshot, door_snapshot)
        if String(entry.get("kind", "")) == "door":
            if not _door_mutations.enroll(entity_id, DoorValue.CLOSED):
                return _rollback(world_snapshot, door_snapshot)
    for entry: Dictionary in plan.props:
        var entity_id: String = _entity_id(plan.instance_id, String(entry.get("role", "")))
        if _mutations.create_entity(entry.get("semantic", &""), entity_id) != entity_id:
            return _rollback(world_snapshot, door_snapshot)
        if not _mutations.set_placement(
            entity_id,
            Layers.Channel.OBJECT,
            entry.get("cell", Vector2i.ZERO),
            int(entry.get("facing", Facing.Value.NORTH)),
            Footprint.single_cell()
        ):
            return _rollback(world_snapshot, door_snapshot)
    return true

func _preflight(plan: GeneratedBuildingPlan) -> bool:
    var planned_ids: Dictionary = {}
    for entry: Dictionary in plan.structures + plan.props:
        var role: String = String(entry.get("role", ""))
        var entity_id: String = _entity_id(plan.instance_id, role)
        if planned_ids.has(entity_id) or _world.has_entity(entity_id):
            return false
        planned_ids[entity_id] = true
        var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
        for channel: int in [Layers.Channel.STRUCTURE, Layers.Channel.OBJECT, Layers.Channel.ACTOR, Layers.Channel.LOOSE_ITEM]:
            if not _world.entities_at(cell, channel).is_empty():
                return false
    return true

func _rollback(world_snapshot: Dictionary, door_snapshot: Dictionary) -> bool:
    _world.load_snapshot(world_snapshot)
    _door_state.load_snapshot(door_snapshot)
    return false

static func _entity_id(instance_id: String, role: String) -> String:
    return "%s.%s" % [instance_id, role]
