extends RefCounted
class_name CanonicalDemoFixture

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")

## Authored canonical demo content. This is a real WHAT fixture, not a generator.

const MAP_ORIGIN: Vector2i = Vector2i.ZERO
const MAP_SIZE: Vector2i = Vector2i(13, 13)
const PLAYER_ID: String = "actor.player.demo"
const PLAYER_START: Vector2i = Vector2i(6, 10)
const BASE_WALK_TICKS: int = 10

const GRASS: StringName = &"ground.grass_lush"
const ROAD: StringName = &"ground.road"
const WALL: StringName = &"wall.house"
const TREE: StringName = &"vegetation.tree"
const BENCH: StringName = &"prop.bench"
const MAILBOX: StringName = &"prop.mailbox"
const STREETLIGHT: StringName = &"prop.streetlight"
const SURVIVOR: StringName = &"actor.survivor"

static func build(
    world: WorldState,
    mutations: WorldMutationService,
    collision_catalog: CollisionCatalog,
    traversal_policy: MovementTraversalPolicy
) -> bool:
    if world == null or mutations == null or collision_catalog == null or traversal_policy == null:
        return false
    if not mutations.is_ready():
        return false
    if not _configure_rules(collision_catalog, traversal_policy):
        return false
    if not _build_terrain(mutations):
        return false
    if not _build_house(mutations):
        return false
    if not _build_props(mutations):
        return false
    if not _create_placed_entity(
        mutations,
        SURVIVOR,
        PLAYER_ID,
        Layers.Channel.ACTOR,
        PLAYER_START,
        Facing.Value.NORTH
    ):
        return false
    return world.has_entity(PLAYER_ID) and world.has_placement(PLAYER_ID)

static func _configure_rules(
    collision_catalog: CollisionCatalog,
    traversal_policy: MovementTraversalPolicy
) -> bool:
    for semantic_type: StringName in [SURVIVOR, WALL, TREE, BENCH, MAILBOX, STREETLIGHT]:
        if not collision_catalog.register(semantic_type, true):
            return false
    if not traversal_policy.register_terrain(GRASS, true, BASE_WALK_TICKS):
        return false
    if not traversal_policy.register_terrain(ROAD, true, BASE_WALK_TICKS):
        return false
    return true

static func _build_terrain(mutations: WorldMutationService) -> bool:
    for y in range(MAP_ORIGIN.y, MAP_ORIGIN.y + MAP_SIZE.y):
        for x in range(MAP_ORIGIN.x, MAP_ORIGIN.x + MAP_SIZE.x):
            var cell := Vector2i(x, y)
            var semantic: StringName = ROAD if x == 6 or y == 6 else GRASS
            if not mutations.set_terrain(cell, semantic):
                return false
    return true

static func _build_house(mutations: WorldMutationService) -> bool:
    for x in range(1, 5):
        if not _create_structure(mutations, "demo.wall.top.%d" % x, Vector2i(x, 1), StructureGeometry.Axis.HORIZONTAL):
            return false
    for x in [1, 3, 4]:
        if not _create_structure(mutations, "demo.wall.bottom.%d" % x, Vector2i(x, 4), StructureGeometry.Axis.HORIZONTAL):
            return false
    for y in range(2, 4):
        if not _create_structure(mutations, "demo.wall.left.%d" % y, Vector2i(1, y), StructureGeometry.Axis.VERTICAL):
            return false
        if not _create_structure(mutations, "demo.wall.right.%d" % y, Vector2i(4, y), StructureGeometry.Axis.VERTICAL):
            return false
    return true

static func _build_props(mutations: WorldMutationService) -> bool:
    var props: Array = [
        [TREE, "demo.tree.1", Vector2i(10, 2)],
        [TREE, "demo.tree.2", Vector2i(11, 3)],
        [TREE, "demo.tree.3", Vector2i(9, 3)],
        [BENCH, "demo.bench.1", Vector2i(8, 8)],
        [MAILBOX, "demo.mailbox.1", Vector2i(2, 7)],
        [STREETLIGHT, "demo.streetlight.1", Vector2i(5, 5)],
    ]
    for entry: Array in props:
        if not _create_placed_entity(
            mutations,
            entry[0],
            String(entry[1]),
            Layers.Channel.OBJECT,
            entry[2],
            Facing.Value.NORTH
        ):
            return false
    return true

static func _create_structure(
    mutations: WorldMutationService,
    entity_id: String,
    cell: Vector2i,
    axis: int
) -> bool:
    var created: String = mutations.create_entity(WALL, entity_id)
    if created != entity_id:
        return false
    return mutations.set_placement(
        entity_id,
        Layers.Channel.STRUCTURE,
        cell,
        Facing.Value.NORTH,
        Footprint.single_cell(),
        axis
    )

static func _create_placed_entity(
    mutations: WorldMutationService,
    semantic_type: StringName,
    entity_id: String,
    channel: int,
    anchor: Vector2i,
    facing: int
) -> bool:
    var created: String = mutations.create_entity(semantic_type, entity_id)
    if created != entity_id:
        return false
    return mutations.set_placement(
        entity_id,
        channel,
        anchor,
        facing,
        Footprint.single_cell()
    )
