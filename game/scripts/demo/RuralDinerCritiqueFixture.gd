extends RefCounted
class_name RuralDinerCritiqueFixture

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const MaterializerClass = preload("res://scripts/generation/buildings/GeneratedBuildingMaterializer.gd")
const DinerClass = preload("res://scripts/generation/buildings/archetypes/RuralDinerBuildingGenerator.gd")

const MAP_ORIGIN: Vector2i = Vector2i.ZERO
const MAP_SIZE: Vector2i = Vector2i(19, 13)
const CELL_PIXELS: float = 28.0
const PLAYER_ID: String = "actor.player.demo"
const PLAYER_START: Vector2i = Vector2i(9, 12)
const BASE_WALK_TICKS: int = 10
const BUILDING_ID: String = "building.demo.diner.rural_small.001"
const EXTERIOR_DOOR_ID: String = "building.demo.diner.rural_small.001.door.exterior.primary"
const DINER_ENVELOPE: Rect2i = Rect2i(1, 1, 17, 11)
const DINER_SEED: int = 19006

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
        DinerClass.ARCHETYPE_ID,
        DINER_SEED,
        DINER_ENVELOPE,
        Facing.Value.NORTH,
        Facing.Value.SOUTH
    )
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    var plan: GeneratedBuildingPlan = generator.generate(request)
    var validation: Dictionary = validator.validate(plan)
    if not bool(validation.get("ok", false)):
        push_error("RuralDinerCritiqueFixture validation failed: %s" % str(validation.get("failures", [])))
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
        &"wall.red_brick", &"wall.storefront", &"wall.interior",
        &"door.storefront", &"door.store", &"door.commercial",
        &"window.storefront", &"window.store",
        &"prop.refrigerator_white", &"prop.counter_straight", &"prop.kitchen_sink", &"prop.stove_range", &"prop.pantry",
        &"prop.restaurant_table", &"prop.restaurant_booth", &"prop.dining_chair",
        &"prop.warehouse_rack", &"prop.pallet_stack", &"prop.tool_cabinet",
        &"prop.toilet_modern", &"prop.pedestal_sink", &"prop.towel_rack",
    ]
    for semantic: StringName in blocking_semantics:
        if not collision_catalog.register(semantic, true):
            return false
    for terrain: StringName in [
        GRASS, ROAD,
        &"ground.restaurant_floor", &"ground.kitchen_tile", &"ground.warehouse_floor", &"ground.tile_mosaic"
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
