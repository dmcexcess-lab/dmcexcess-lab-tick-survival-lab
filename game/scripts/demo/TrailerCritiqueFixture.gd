extends RefCounted
class_name TrailerCritiqueFixture

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const MaterializerClass = preload("res://scripts/generation/buildings/GeneratedBuildingMaterializer.gd")
const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")

const MAP_ORIGIN: Vector2i = Vector2i.ZERO
const MAP_SIZE: Vector2i = Vector2i(13, 13)
const PLAYER_ID: String = "actor.player.demo"
const PLAYER_START: Vector2i = Vector2i(8, 3)
const BASE_WALK_TICKS: int = 10
const BUILDING_ID: String = "building.demo.trailer.001"
const EXTERIOR_DOOR_ID: String = "building.demo.trailer.001.door.exterior.primary"
const TRAILER_ENVELOPE: Rect2i = Rect2i(2, 0, 6, 12)
const TRAILER_SEED: int = 19001

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
        TrailerClass.ARCHETYPE_ID,
        TRAILER_SEED,
        TRAILER_ENVELOPE,
        Facing.Value.NORTH,
        Facing.Value.EAST
    )
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    var plan: GeneratedBuildingPlan = generator.generate(request)
    var validation: Dictionary = validator.validate(plan)
    if not bool(validation.get("ok", false)):
        push_error("TrailerCritiqueFixture validation failed: %s" % str(validation.get("failures", [])))
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
        Facing.Value.WEST,
        Footprint.single_cell()
    ):
        return false
    return world.has_entity(EXTERIOR_DOOR_ID) and door_state.has_door(EXTERIOR_DOOR_ID)

static func _configure_rules(collision_catalog: CollisionCatalog, traversal_policy: MovementTraversalPolicy) -> bool:
    var blocking_semantics: Array[StringName] = [
        SURVIVOR,
        &"wall.rural_wood", &"wall.interior",
        &"door.rural_wood", &"door.house",
        &"window.rural_wood",
        &"prop.stove_range", &"prop.refrigerator_white", &"prop.kitchen_sink",
        &"prop.sofa", &"prop.loveseat", &"prop.toilet_modern", &"prop.bathroom_vanity",
        &"prop.bed_single", &"prop.dresser_wide",
    ]
    for semantic: StringName in blocking_semantics:
        if not collision_catalog.register(semantic, true):
            return false
    for terrain: StringName in [
        GRASS, ROAD, &"ground.linoleum_green", &"ground.tile_white",
        &"ground.carpet_beige", &"ground.carpet_blue"
    ]:
        if not traversal_policy.register_terrain(terrain, true, BASE_WALK_TICKS):
            return false
    return true

static func _build_base_terrain(mutations: WorldMutationService) -> bool:
    for y in range(MAP_SIZE.y):
        for x in range(MAP_SIZE.x):
            var semantic: StringName = ROAD if x == 10 else GRASS
            if not mutations.set_terrain(Vector2i(x, y), semantic):
                return false
    return true
