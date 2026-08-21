extends RefCounted
class_name AreaMaterializationCoordinator

const AreaValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")
const BuildingGeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BuildingValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const BuildingMaterializerClass = preload("res://scripts/generation/buildings/GeneratedBuildingMaterializer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _door_state: DoorStateStore = null
var _door_mutations: DoorStateMutationService = null
var _area_validator: GeneratedAreaValidator = null
var _building_generator: LocalBuildingGenerator = null
var _building_validator: GeneratedBuildingValidator = null

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    door_state: DoorStateStore = null,
    door_mutations: DoorStateMutationService = null
) -> void:
    _world = world
    _mutations = mutations
    _door_state = door_state
    _door_mutations = door_mutations
    _area_validator = AreaValidatorClass.new()
    _building_generator = BuildingGeneratorClass.new()
    _building_validator = BuildingValidatorClass.new()

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _door_state != null and _door_mutations != null and _door_mutations.is_ready()

func materialize(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> bool:
    if not is_ready() or request == null or plan == null:
        return false
    var area_validation: Dictionary = _area_validator.validate(request, plan)
    if not bool(area_validation.get("ok", false)):
        return false

    var building_plans: Array[GeneratedBuildingPlan] = []
    var planned_ids: Dictionary = {}
    for building_request: BuildingGenerationRequest in plan.building_requests:
        var building_plan: GeneratedBuildingPlan = _building_generator.generate(building_request)
        if building_plan == null or not building_plan.is_generated():
            return false
        var validation: Dictionary = _building_validator.validate(building_plan)
        if not bool(validation.get("ok", false)):
            return false
        if not _preflight_building_ids(building_plan, planned_ids):
            return false
        building_plans.append(building_plan)

    for prop: Dictionary in plan.outdoor_props:
        var prop_id: String = String(prop.get("id", "")).strip_edges()
        if prop_id.is_empty() or planned_ids.has(prop_id) or _world.has_entity(prop_id):
            return false
        planned_ids[prop_id] = true

    var world_snapshot: Dictionary = _world.snapshot()
    var door_snapshot: Dictionary = _door_state.snapshot()

    if not _materialize_ground(plan):
        return _rollback(world_snapshot, door_snapshot)
    if not _materialize_outdoor_props(plan):
        return _rollback(world_snapshot, door_snapshot)

    var building_materializer := BuildingMaterializerClass.new(
        _world,
        _mutations,
        _door_state,
        _door_mutations,
        _building_validator
    )
    for building_plan: GeneratedBuildingPlan in building_plans:
        if not building_materializer.materialize(building_plan):
            return _rollback(world_snapshot, door_snapshot)
    return true

func generated_building_plans(plan: GeneratedAreaPlan) -> Array[GeneratedBuildingPlan]:
    var result: Array[GeneratedBuildingPlan] = []
    if plan == null:
        return result
    for request: BuildingGenerationRequest in plan.building_requests:
        var building_plan: GeneratedBuildingPlan = _building_generator.generate(request)
        if building_plan != null and building_plan.is_generated():
            result.append(building_plan)
    return result

func _materialize_ground(plan: GeneratedAreaPlan) -> bool:
    var regions: Array[Dictionary] = plan.ground_regions.duplicate(true)
    regions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ap: int = int(a.get("priority", 0))
        var bp: int = int(b.get("priority", 0))
        if ap != bp:
            return ap < bp
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    for region: Dictionary in regions:
        var semantic: StringName = StringName(region.get("semantic", &""))
        if semantic == &"":
            return false
        if region.has("rect"):
            var rect: Rect2i = region.get("rect", Rect2i())
            for y in range(rect.position.y, rect.position.y + rect.size.y):
                for x in range(rect.position.x, rect.position.x + rect.size.x):
                    if not _mutations.set_terrain(Vector2i(x, y), semantic):
                        return false
        else:
            for value: Variant in region.get("cells", []):
                if typeof(value) != TYPE_VECTOR2I:
                    return false
                var cell: Vector2i = value
                if not _mutations.set_terrain(cell, semantic):
                    return false
    return true

func _materialize_outdoor_props(plan: GeneratedAreaPlan) -> bool:
    for prop: Dictionary in plan.outdoor_props:
        var entity_id: String = String(prop.get("id", ""))
        var semantic: StringName = StringName(prop.get("semantic", &""))
        var cell: Vector2i = prop.get("cell", Vector2i.ZERO)
        var facing: int = int(prop.get("facing", Facing.Value.NORTH))
        if _mutations.create_entity(semantic, entity_id) != entity_id:
            return false
        if not _mutations.set_placement(entity_id, Layers.Channel.OBJECT, cell, facing, Footprint.single_cell()):
            return false
    return true

func _preflight_building_ids(plan: GeneratedBuildingPlan, planned_ids: Dictionary) -> bool:
    for entry: Dictionary in plan.structures + plan.props:
        var role: String = String(entry.get("role", ""))
        var entity_id: String = "%s.%s" % [plan.instance_id, role]
        if role.is_empty() or planned_ids.has(entity_id) or _world.has_entity(entity_id):
            return false
        planned_ids[entity_id] = true
    return true

func _rollback(world_snapshot: Dictionary, door_snapshot: Dictionary) -> bool:
    _world.load_snapshot(world_snapshot)
    _door_state.load_snapshot(door_snapshot)
    return false
