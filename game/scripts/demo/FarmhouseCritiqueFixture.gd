extends RefCounted
class_name FarmhouseCritiqueFixture

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const MaterializerClass = preload("res://scripts/generation/buildings/GeneratedBuildingMaterializer.gd")
const FarmhouseClass = preload("res://scripts/generation/buildings/archetypes/FarmhouseBuildingGenerator.gd")

const MAP_ORIGIN: Vector2i = Vector2i.ZERO
const MAP_SIZE: Vector2i = Vector2i(15, 15)
const CELL_PIXELS: float = 32.0
const PLAYER_ID: String = "actor.player.demo"
const PLAYER_START: Vector2i = Vector2i(4, 0)
const BASE_WALK_TICKS: int = 10
const BUILDING_ID: String = "building.demo.farmhouse.001"
const EXTERIOR_DOOR_ID: String = "building.demo.farmhouse.001.door.exterior.primary"
const FARMHOUSE_ENVELOPE: Rect2i = Rect2i(1, 1, 13, 9)
const FARMHOUSE_SEED: int = 19002

const GRASS: StringName = &"ground.grass_lush"
const ROAD: StringName = &"ground.road"
const SURVIVOR: StringName = &"actor.survivor"

static func build(
    world: WorldState,
    mutations: WorldMutationService,
    collision_catalog: CollisionCatalog,
    traversal_policy: MovementTraversalPolicy,
    door_state: DoorStateStore,
    door_mutations: DoorStateMutationService
) -> bool:
    if world == null or mutations == null or collision_catalog == null or traversal_policy == null or door_state == null or door_mutations == null:
        return false
    if not _configure_rules(collision_catalog, traversal_policy):
        return false
    if not _build_base_terrain(mutations):
        return false

    var request := RequestClass.new(
        BUILDING_ID,
        FarmhouseClass.ARCHETYPE_ID,
        FARMHOUSE_SEED,
        FARMHOUSE_ENVELOPE,
        Facing.Value.NORTH,
        Facing.Value.NORTH
    )
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    var plan: GeneratedBuildingPlan = generator.generate(request)
    var validation: Dictionary = validator.validate(plan)
    if not bool(validation.get("ok", false)):
        push_error("FarmhouseCritiqueFixture validation failed: %s" % str(validation.get("failures", [])))
        return false
    var materializer := MaterializerClass.new(world, mutations, door_state, door_mutations, validator)
    if not materializer.materialize(plan):
        return false

    if mutations.create_entity(SURVIVOR, PLAYER_ID) != PLAYER_ID:
        return false
    if not mutations.set_placement(
        PLAYER_ID,
        Layers.Channel.ACTOR,
        PLAYER_START,
        Facing.Value.SOUTH,
        Footprint.single_cell()
    ):
        return false
    return world.has_entity(EXTERIOR_DOOR_ID) and door_state.has_door(EXTERIOR_DOOR_ID)

static func _configure_rules(collision_catalog: CollisionCatalog, traversal_policy: MovementTraversalPolicy) -> bool:
    var blocking_semantics: Array[StringName] = [
        SURVIVOR,
        &"wall.plaster", &"wall.interior",
        &"door.house", &"window.house",
        &"prop.sofa", &"prop.armchair", &"prop.coffee_table",
        &"prop.stove_range", &"prop.refrigerator_white", &"prop.kitchen_sink",
        &"prop.bed_double", &"prop.dresser_wide",
        &"prop.toilet_modern", &"prop.bathroom_vanity", &"prop.bathtub_clawfoot",
    ]
    for semantic: StringName in blocking_semantics:
        if not collision_catalog.register(semantic, true):
            return false
    for terrain: StringName in [
        GRASS, ROAD, &"ground.laminate_light", &"ground.linoleum_yellow",
        &"ground.tile_white", &"ground.carpet_beige", &"ground.carpet_blue"
    ]:
        if not traversal_policy.register_terrain(terrain, true, BASE_WALK_TICKS):
            return false
    return true

static func _build_base_terrain(mutations: WorldMutationService) -> bool:
    for y in range(MAP_SIZE.y):
        for x in range(MAP_SIZE.x):
            var semantic: StringName = ROAD if y == 0 else GRASS
            if not mutations.set_terrain(Vector2i(x, y), semantic):
                return false
    return true
