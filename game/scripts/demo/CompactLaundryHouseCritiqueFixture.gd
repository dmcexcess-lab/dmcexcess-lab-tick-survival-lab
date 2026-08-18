extends RefCounted
class_name CompactLaundryHouseCritiqueFixture

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const MaterializerClass = preload("res://scripts/generation/buildings/GeneratedBuildingMaterializer.gd")
const HouseClass = preload("res://scripts/generation/buildings/archetypes/CompactLaundryHouseBuildingGenerator.gd")

const MAP_ORIGIN: Vector2i = Vector2i.ZERO
const MAP_SIZE: Vector2i = Vector2i(19, 15)
const CELL_PIXELS: float = 26.0
const PLAYER_ID: String = "actor.player.demo"
const PLAYER_START: Vector2i = Vector2i(8, 14)
const BASE_WALK_TICKS: int = 10
const BUILDING_ID: String = "building.demo.house.compact_laundry.001"
const EXTERIOR_DOOR_ID: String = "building.demo.house.compact_laundry.001.door.exterior.primary"
const HOUSE_ENVELOPE: Rect2i = Rect2i(1, 1, 17, 13)
const HOUSE_SEED: int = 19004

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
        HouseClass.ARCHETYPE_ID,
        HOUSE_SEED,
        HOUSE_ENVELOPE,
        Facing.Value.NORTH,
        Facing.Value.SOUTH
    )
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    var plan: GeneratedBuildingPlan = generator.generate(request)
    var validation: Dictionary = validator.validate(plan)
    if not bool(validation.get("ok", false)):
        push_error("CompactLaundryHouseCritiqueFixture validation failed: %s" % str(validation.get("failures", [])))
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
        Facing.Value.NORTH,
        Footprint.single_cell()
    ):
        return false
    return world.has_entity(EXTERIOR_DOOR_ID) and door_state.has_door(EXTERIOR_DOOR_ID)

static func _configure_rules(collision_catalog: CollisionCatalog, traversal_policy: MovementTraversalPolicy) -> bool:
    var blocking_semantics: Array[StringName] = [
        SURVIVOR,
        &"wall.plaster", &"wall.interior",
        &"door.house", &"window.house",
        &"prop.bed_single", &"prop.bed_double", &"prop.nightstand", &"prop.wardrobe", &"prop.dresser_wide",
        &"prop.refrigerator_white", &"prop.counter_straight", &"prop.kitchen_sink", &"prop.stove_range", &"prop.pantry",
        &"prop.breakfast_table", &"prop.dining_chair",
        &"prop.washer_front", &"prop.dryer_front", &"prop.utility_sink", &"prop.hamper",
        &"prop.toilet_modern", &"prop.bathroom_vanity", &"prop.shower_stall",
        &"prop.bookshelf_tall", &"prop.tv_stand", &"prop.sofa", &"prop.coffee_table", &"prop.armchair", &"prop.end_table",
    ]
    for semantic: StringName in blocking_semantics:
        if not collision_catalog.register(semantic, true):
            return false
    if not collision_catalog.register(&"prop.rug", false):
        return false
    for terrain: StringName in [
        GRASS, ROAD,
        &"ground.carpet_beige", &"ground.carpet_blue",
        &"ground.tile_white", &"ground.tile_mosaic", &"ground.laminate_dark"
    ]:
        if not traversal_policy.register_terrain(terrain, true, BASE_WALK_TICKS):
            return false
    return true

static func _build_base_terrain(mutations: WorldMutationService) -> bool:
    for y in range(MAP_SIZE.y):
        for x in range(MAP_SIZE.x):
            var semantic: StringName = ROAD if y == MAP_SIZE.y - 1 else GRASS
            if not mutations.set_terrain(Vector2i(x, y), semantic):
                return false
    return true
