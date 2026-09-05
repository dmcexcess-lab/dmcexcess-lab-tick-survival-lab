extends RefCounted
class_name GeneratedWorldRuleInstaller

const BuildingGeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BuildingRequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const EnvironmentCatalogClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

const SURVIVOR: StringName = &"actor.survivor"
const BASE_WALK_TICKS: int = 10

const ENVIRONMENT_GROUND_KEYS: Array[String] = [
    "base_ground", "road_ground", "road_surface_ground",
    "road_centerline_horizontal", "road_centerline_vertical",
    "local_road_ground", "driveway_ground", "field_ground",
]

const EXTRA_WALKABLE_TERRAIN: Array[StringName] = [
    &"ground.road", &"ground.road_plain", &"ground.sidewalk",
    &"ground.dirt_road", &"ground.road_white_line_h", &"ground.road_white_line_v",
    &"ground.parking", &"ground.parking_v", &"ground.crosswalk_h", &"ground.crosswalk_v",
    &"ground.gravel", &"ground.shoulder_gravel",
    &"ground.shore_sand", &"ground.shore_n", &"ground.shore_e", &"ground.shore_s", &"ground.shore_w",
    &"ground.shore_ne", &"ground.shore_es", &"ground.shore_sw", &"ground.shore_wn",
    &"ground.shore_nes", &"ground.shore_wne", &"ground.shore_swn", &"ground.shore_esw", &"ground.shore_all",
]

const BLOCKED_TERRAIN: Array[StringName] = [
    &"ground.water_ocean",
    &"ground.water_river",
]

func install(collision_catalog: CollisionCatalog, traversal_policy: MovementTraversalPolicy) -> Dictionary:
    if collision_catalog == null or traversal_policy == null:
        return _failure("generated_world_rule_dependencies_missing")

    var terrain: Dictionary = {}
    var collision: Dictionary = {SURVIVOR: true}
    var environments := EnvironmentCatalogClass.new()
    for profile_id: StringName in environments.profile_ids():
        var profile: Dictionary = environments.profile(profile_id)
        if profile.is_empty():
            return _failure("environment_profile_missing:%s" % String(profile_id))
        for key: String in ENVIRONMENT_GROUND_KEYS:
            _add_terrain(terrain, StringName(profile.get(key, &"")))
        for array_key: String in ["tree_semantics", "shrub_semantics", "rock_semantics"]:
            for semantic_value: Variant in profile.get(array_key, []):
                if not _merge_collision(collision, StringName(semantic_value), true):
                    return _failure("environment_collision_conflict:%s" % String(semantic_value))
        for semantic_key: String in ["fence_semantic", "mailbox_semantic", "traffic_signal_semantic"]:
            var semantic: StringName = StringName(profile.get(semantic_key, &""))
            if not _merge_collision(collision, semantic, true):
                return _failure("environment_collision_conflict:%s" % String(semantic))

    for semantic: StringName in EXTRA_WALKABLE_TERRAIN:
        _add_terrain(terrain, semantic)

    var buildings := BuildingGeneratorClass.new()
    var ordinal: int = 0
    for archetype_id: StringName in buildings.supported_archetypes():
        var descriptor: BuildingArchetypePlacementDescriptor = buildings.placement_descriptor(archetype_id)
        if descriptor == null or not descriptor.is_valid():
            return _failure("building_descriptor_missing:%s" % String(archetype_id))
        var orientations: Array[int] = descriptor.supported_orientations()
        if orientations.is_empty():
            return _failure("building_orientation_missing:%s" % String(archetype_id))
        var request := BuildingRequestClass.new(
            "world.rules.probe.%03d" % ordinal,
            archetype_id,
            0,
            Rect2i(0, 0, 512, 512),
            orientations[0],
            descriptor.canonical_frontage()
        )
        var plan: GeneratedBuildingPlan = buildings.generate(request)
        if plan == null or not plan.is_generated():
            return _failure("building_rule_probe_failed:%s" % String(archetype_id))
        for ground: Dictionary in plan.ground_entries:
            _add_terrain(terrain, StringName(ground.get("semantic", &"")))
        for structure: Dictionary in plan.structures:
            var structure_semantic: StringName = StringName(structure.get("semantic", &""))
            if not _merge_collision(collision, structure_semantic, true):
                return _failure("building_structure_collision_conflict:%s" % String(structure_semantic))
        for prop: Dictionary in plan.props:
            var prop_semantic: StringName = StringName(prop.get("semantic", &""))
            if not _merge_collision(collision, prop_semantic, bool(prop.get("blocking", true))):
                return _failure("building_prop_collision_conflict:%s" % String(prop_semantic))
        ordinal += 1

    var collision_keys: Array = collision.keys()
    collision_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
    for semantic_value: Variant in collision_keys:
        var semantic: StringName = StringName(semantic_value)
        if not collision_catalog.register(semantic, bool(collision[semantic_value])):
            return _failure("collision_registration_failed:%s" % String(semantic))

    var terrain_keys: Array = terrain.keys()
    terrain_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
    for terrain_value: Variant in terrain_keys:
        var semantic: StringName = StringName(terrain_value)
        if not traversal_policy.register_terrain(semantic, true, BASE_WALK_TICKS):
            return _failure("terrain_registration_failed:%s" % String(semantic))
    for blocked: StringName in BLOCKED_TERRAIN:
        if not traversal_policy.register_terrain(blocked, false):
            return _failure("blocked_terrain_registration_failed:%s" % String(blocked))

    return {
        "ok": true,
        "failure_reason": "",
        "terrain_count": terrain.size() + BLOCKED_TERRAIN.size(),
        "collision_count": collision.size(),
    }

func _add_terrain(rules: Dictionary, semantic: StringName) -> void:
    if not String(semantic).strip_edges().is_empty():
        rules[semantic] = true

func _merge_collision(rules: Dictionary, semantic: StringName, blocking: bool) -> bool:
    if String(semantic).strip_edges().is_empty():
        return true
    if rules.has(semantic):
        return bool(rules[semantic]) == blocking
    rules[semantic] = blocking
    return true

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "terrain_count": 0,
        "collision_count": 0,
    }
