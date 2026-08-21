extends RefCounted
class_name RuralCrossroadsCritiqueFixture

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PlanFixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const AreaGeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const AreaMaterializerClass = preload("res://scripts/generation/areas/AreaMaterializationCoordinator.gd")

const AREA_BOUNDS: Rect2i = Rect2i(1000, 2000, 256, 256)
const RENDER_WINDOW_SIZE: Vector2i = Vector2i(80, 96)
const CELL_PIXELS: float = 24.0
const PLAYER_ID: String = "actor.player.demo"
const SURVIVOR: StringName = &"actor.survivor"
const DINER_ARCHETYPE: StringName = &"commercial.diner.rural_small"
const BASE_WALK_TICKS: int = 10

static func generate_plan(seed: int = PlanFixtureClass.SEED) -> GeneratedAreaPlan:
    return AreaGeneratorClass.new().generate(PlanFixtureClass.request(seed))

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

    var request: AreaGenerationRequest = PlanFixtureClass.request()
    var plan: GeneratedAreaPlan = AreaGeneratorClass.new().generate(request)
    if plan == null or not plan.is_generated():
        push_error("RuralCrossroadsCritiqueFixture: area generation failed")
        return false

    var materializer := AreaMaterializerClass.new(world, mutations, door_state, door_mutations)
    var building_plans: Array[GeneratedBuildingPlan] = materializer.generated_building_plans(plan)
    if building_plans.size() != plan.building_requests.size():
        return false
    if not _configure_rules(plan, building_plans, collision_catalog, traversal_policy):
        return false
    if not materializer.materialize(request, plan):
        push_error("RuralCrossroadsCritiqueFixture: area materialization failed")
        return false

    var player_start: Vector2i = player_start_for_plan(plan)
    var diner_door: String = diner_door_id(plan)
    var diner_frontage: int = diner_frontage_for_plan(plan)
    if player_start.x < 0 or diner_door.is_empty() or not Facing.is_valid(diner_frontage):
        return false
    if mutations.create_entity(SURVIVOR, PLAYER_ID) != PLAYER_ID:
        return false
    if not mutations.set_placement(
        PLAYER_ID,
        Layers.Channel.ACTOR,
        player_start,
        Facing.opposite(diner_frontage),
        Footprint.single_cell()
    ):
        return false
    return world.has_entity(diner_door) and door_state.has_door(diner_door)

static func initial_render_origin(world: WorldState) -> Vector2i:
    if world == null:
        return AREA_BOUNDS.position
    var placement: WorldPlacement = world.placement(PLAYER_ID)
    if placement == null:
        return AREA_BOUNDS.position
    return _window_origin_for_cell(placement.anchor)

static func player_start_for_plan(plan: GeneratedAreaPlan) -> Vector2i:
    var parcel: Dictionary = _diner_parcel(plan)
    if parcel.is_empty():
        return Vector2i(-1, -1)
    var entry: Vector2i = parcel.get("building_entry_cell", Vector2i(-1, -1))
    var frontage: int = int(parcel.get("frontage_side", -1))
    if entry.x < 0 or not Facing.is_valid(frontage):
        return Vector2i(-1, -1)
    return entry + Facing.vector(frontage)

static func diner_door_id(plan: GeneratedAreaPlan) -> String:
    var parcel: Dictionary = _diner_parcel(plan)
    var instance_id: String = String(parcel.get("building_instance_id", ""))
    return "" if instance_id.is_empty() else "%s.door.exterior.primary" % instance_id

static func diner_frontage_for_plan(plan: GeneratedAreaPlan) -> int:
    var parcel: Dictionary = _diner_parcel(plan)
    return int(parcel.get("frontage_side", -1))

static func _diner_parcel(plan: GeneratedAreaPlan) -> Dictionary:
    if plan == null:
        return {}
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("building_archetype_id", &"")) == DINER_ARCHETYPE:
            return parcel
    return {}

static func _configure_rules(
    plan: GeneratedAreaPlan,
    building_plans: Array[GeneratedBuildingPlan],
    collision_catalog: CollisionCatalog,
    traversal_policy: MovementTraversalPolicy
) -> bool:
    var collision_rules: Dictionary = {SURVIVOR: true}
    var terrain_rules: Dictionary = {}

    for region: Dictionary in plan.ground_regions:
        var terrain_semantic: StringName = StringName(region.get("semantic", &""))
        if terrain_semantic != &"":
            terrain_rules[terrain_semantic] = true
    for prop: Dictionary in plan.outdoor_props:
        var outdoor_semantic: StringName = StringName(prop.get("semantic", &""))
        if outdoor_semantic != &"" and not _merge_collision_rule(collision_rules, outdoor_semantic, true):
            return false

    for building_plan: GeneratedBuildingPlan in building_plans:
        for ground: Dictionary in building_plan.ground_entries:
            var ground_semantic: StringName = StringName(ground.get("semantic", &""))
            if ground_semantic != &"":
                terrain_rules[ground_semantic] = true
        for structure: Dictionary in building_plan.structures:
            var structure_semantic: StringName = StringName(structure.get("semantic", &""))
            if structure_semantic != &"" and not _merge_collision_rule(collision_rules, structure_semantic, true):
                return false
        for prop_entry: Dictionary in building_plan.props:
            var prop_semantic: StringName = StringName(prop_entry.get("semantic", &""))
            var blocking: bool = bool(prop_entry.get("blocking", true))
            if prop_semantic != &"" and not _merge_collision_rule(collision_rules, prop_semantic, blocking):
                return false

    var collision_keys: Array = collision_rules.keys()
    collision_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
    for semantic_value: Variant in collision_keys:
        var semantic: StringName = StringName(semantic_value)
        if not collision_catalog.register(semantic, bool(collision_rules[semantic_value])):
            return false

    var terrain_keys: Array = terrain_rules.keys()
    terrain_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
    for terrain_value: Variant in terrain_keys:
        var terrain: StringName = StringName(terrain_value)
        if not traversal_policy.register_terrain(terrain, true, BASE_WALK_TICKS):
            return false
    return true

static func _merge_collision_rule(rules: Dictionary, semantic: StringName, blocking: bool) -> bool:
    if rules.has(semantic):
        return bool(rules[semantic]) == blocking
    rules[semantic] = blocking
    return true

static func _window_origin_for_cell(cell: Vector2i) -> Vector2i:
    var desired := cell - Vector2i(RENDER_WINDOW_SIZE.x / 2, RENDER_WINDOW_SIZE.y / 2)
    var max_origin := AREA_BOUNDS.position + AREA_BOUNDS.size - RENDER_WINDOW_SIZE
    return Vector2i(
        clampi(desired.x, AREA_BOUNDS.position.x, max_origin.x),
        clampi(desired.y, AREA_BOUNDS.position.y, max_origin.y)
    )
