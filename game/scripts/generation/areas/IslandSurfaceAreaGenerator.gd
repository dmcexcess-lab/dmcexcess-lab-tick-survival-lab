extends RefCounted
class_name IslandSurfaceAreaGenerator

const PlanClass = preload("res://scripts/generation/areas/GeneratedAreaPlan.gd")
const RoadPlannerClass = preload("res://scripts/generation/areas/LocalRoadPlanner.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")

const PROFILE_ID: StringName = &"island.surface"

var _road_planner: LocalRoadPlanner = RoadPlannerClass.new()
var _environment_profiles: EnvironmentProfileCatalog = EnvironmentProfilesClass.new()

func generate(request: AreaGenerationRequest) -> GeneratedAreaPlan:
    var plan := PlanClass.new()
    if request == null or not request.is_valid() \
        or request.area_profile_id != PROFILE_ID \
        or request.environment_profile_id != EnvironmentProfilesClass.TEMPERATE_COASTAL:
        plan.failure_reason = "invalid_island_surface_request"
        return plan
    var context: Dictionary = _surface_context(request)
    if context.is_empty():
        plan.failure_reason = "island_surface_context_missing"
        return plan

    var environment: Dictionary = _environment_profiles.profile(request.environment_profile_id)
    if environment.is_empty():
        plan.failure_reason = "island_surface_environment_missing"
        return plan

    var profile: Dictionary = {
        "id": PROFILE_ID,
        "version": 2,
        "road_layout": &"inherit_only",
        "signalize_first_inherited_intersection": false,
        "inherited_roads_required": false,
    }
    var road_result: Dictionary = _road_planner.plan(request, profile, [])
    if not bool(road_result.get("ok", false)):
        plan.failure_reason = String(road_result.get("failure_reason", "island_surface_road_planning_failed"))
        return plan
    var roads: Array[Dictionary] = []
    for value: Variant in road_result.get("roads", []):
        if typeof(value) != TYPE_DICTIONARY:
            plan.failure_reason = "island_surface_road_result_invalid"
            return plan
        var road: Dictionary = value
        if not bool(road.get("inherited", false)):
            plan.failure_reason = "island_surface_local_road_forbidden"
            return plan
        roads.append(road)
    var intersections: Array[Dictionary] = []
    for value: Variant in road_result.get("intersections", []):
        if typeof(value) != TYPE_DICTIONARY:
            plan.failure_reason = "island_surface_intersection_result_invalid"
            return plan
        intersections.append(value)

    var ground_regions: Array[Dictionary] = _surface_runs(request, context)
    for road: Dictionary in roads:
        var road_cells: Array[Vector2i] = []
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) != TYPE_VECTOR2I:
                plan.failure_reason = "island_surface_road_cell_invalid"
                return plan
            var cell: Vector2i = value
            if _kind(context, cell) == Surface.OCEAN:
                plan.failure_reason = "island_surface_road_enters_ocean"
                return plan
            road_cells.append(cell)
        if not road_cells.is_empty():
            ground_regions.append({
                "id": "%s.ground.road.%s.surface" % [request.area_id, String(road.get("road_id", "road"))],
                "semantic": StringName(environment.get("road_surface_ground", &"ground.road_plain")),
                "cells": road_cells,
                "priority": 100,
            })
        _append_centerline_regions(request, road, intersections, environment, ground_regions)

    var outdoor_props: Array[Dictionary] = _natural_land_props(request, context, roads, environment)

    plan.area_id = request.area_id
    plan.seed = request.seed
    plan.bounds = request.bounds
    plan.area_profile_id = PROFILE_ID
    plan.area_profile_version = 2
    plan.environment_profile_id = request.environment_profile_id
    plan.environment_profile_version = int(environment.get("version", 0))
    plan.reservations = []
    plan.roads = roads
    plan.intersections = intersections
    plan.blocks = []
    plan.parcels = []
    plan.building_requests = []
    plan.hydrology_features = []
    plan.ground_regions = ground_regions
    plan.outdoor_props = outdoor_props
    return plan

func _append_centerline_regions(
    request: AreaGenerationRequest,
    road: Dictionary,
    intersections: Array[Dictionary],
    environment: Dictionary,
    ground_regions: Array[Dictionary]
) -> void:
    if not bool(road.get("paint_centerline", false)):
        return
    var road_id: String = String(road.get("road_id", "road"))
    var groups: Dictionary = _centerline_cells_by_axis(road, intersections)
    var horizontal: Array = groups.get(&"horizontal", [])
    if not horizontal.is_empty():
        ground_regions.append({
            "id": "%s.ground.road.%s.centerline_h" % [request.area_id, road_id],
            "semantic": StringName(environment.get("road_centerline_horizontal", &"ground.road_yellow_line_h")),
            "cells": horizontal.duplicate(),
            "priority": 110,
        })
    var vertical: Array = groups.get(&"vertical", [])
    if not vertical.is_empty():
        ground_regions.append({
            "id": "%s.ground.road.%s.centerline_v" % [request.area_id, road_id],
            "semantic": StringName(environment.get("road_centerline_vertical", &"ground.road_yellow_line_v")),
            "cells": vertical.duplicate(),
            "priority": 110,
        })

func _centerline_cells_by_axis(road: Dictionary, intersections: Array[Dictionary]) -> Dictionary:
    var horizontal: Array[Vector2i] = []
    var vertical: Array[Vector2i] = []
    var path: Array = road.get("path_cells", [])
    var road_id: String = String(road.get("road_id", ""))
    var intersection_clearance: int = int(road.get("width", 1)) / 2 + 1
    var explicit_axis: StringName = StringName(road.get("axis", &""))
    for index in range(path.size()):
        var cell: Vector2i = path[index]
        if _near_road_intersection(cell, road_id, intersections, intersection_clearance):
            continue
        var axis: StringName = explicit_axis
        if axis != &"horizontal" and axis != &"vertical":
            axis = _path_axis(path, index)
        if axis == &"horizontal":
            horizontal.append(cell)
        elif axis == &"vertical":
            vertical.append(cell)
    return {&"horizontal": horizontal, &"vertical": vertical}

func _path_axis(path: Array, index: int) -> StringName:
    var cell: Vector2i = path[index]
    var before: Vector2i = cell
    var after: Vector2i = cell
    if index > 0:
        before = path[index - 1]
    if index + 1 < path.size():
        after = path[index + 1]
    if before.y == cell.y and after.y == cell.y:
        return &"horizontal"
    if before.x == cell.x and after.x == cell.x:
        return &"vertical"
    if after != cell:
        return &"horizontal" if after.y == cell.y else &"vertical"
    if before != cell:
        return &"horizontal" if before.y == cell.y else &"vertical"
    return &""

func _near_road_intersection(cell: Vector2i, road_id: String, intersections: Array[Dictionary], clearance: int) -> bool:
    for intersection: Dictionary in intersections:
        var ids: Array = intersection.get("road_ids", [])
        if not ids.has(road_id):
            continue
        var center: Vector2i = intersection.get("cell", Vector2i(-999999, -999999))
        if absi(cell.x - center.x) + absi(cell.y - center.y) <= clearance:
            return true
    return false

func _natural_land_props(
    request: AreaGenerationRequest,
    context: Dictionary,
    roads: Array[Dictionary],
    environment: Dictionary
) -> Array[Dictionary]:
    var props: Array[Dictionary] = []
    var trees: Array = environment.get("tree_semantics", [])
    var shrubs: Array = environment.get("shrub_semantics", [])
    var rocks: Array = environment.get("rock_semantics", [])
    if trees.is_empty() or shrubs.is_empty() or rocks.is_empty():
        return props

    var blocked: Dictionary = {}
    var clearance: int = maxi(0, int(environment.get("natural_road_clearance", 1)))
    for road: Dictionary in roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) != TYPE_VECTOR2I:
                continue
            var road_cell: Vector2i = value
            for dy in range(-clearance, clearance + 1):
                for dx in range(-clearance, clearance + 1):
                    var blocked_cell := road_cell + Vector2i(dx, dy)
                    if request.bounds.has_point(blocked_cell):
                        blocked[blocked_cell] = true

    var base_density: float = clampf(float(environment.get("natural_noise_density", 0.012)), 0.0, 0.04)
    var patch_scale: int = maxi(8, int(environment.get("natural_noise_patch_scale", 22)))
    var sparse_multiplier: float = maxf(0.0, float(environment.get("natural_noise_sparse_multiplier", 0.20)))
    var dense_multiplier: float = maxf(sparse_multiplier, float(environment.get("natural_noise_dense_multiplier", 2.25)))
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        for x in range(request.bounds.position.x, request.bounds.position.x + request.bounds.size.x):
            var cell := Vector2i(x, y)
            if blocked.has(cell) or _kind(context, cell) != Surface.LAND:
                continue
            var patch_noise: float = _value_noise_global(request.seed, cell, patch_scale, 401)
            var local_density: float = minf(0.04, base_density * lerpf(sparse_multiplier, dense_multiplier, patch_noise))
            if Seed.unit_2d(request.seed, cell.x, cell.y, 503) >= local_density:
                continue
            var family_noise: float = _value_noise_global(request.seed, cell, patch_scale * 2, 607)
            var family: Array = trees
            if family_noise >= 0.78:
                family = rocks
            elif family_noise >= 0.43:
                family = shrubs
            if family.is_empty():
                continue
            var index: int = Seed.hash_2d(request.seed, cell.x, cell.y, 811) % family.size()
            props.append({
                "id": "island_surface.natural.%d.%d" % [cell.x, cell.y],
                "semantic": StringName(family[index]),
                "cell": cell,
                "facing": Facing.Value.SOUTH,
            })
    return props

func _surface_runs(request: AreaGenerationRequest, context: Dictionary) -> Array[Dictionary]:
    var regions: Array[Dictionary] = []
    var ordinal: int = 0
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        var run_start: int = request.bounds.position.x
        var current_semantic: StringName = _semantic(context, Vector2i(run_start, y))
        for x in range(request.bounds.position.x + 1, request.bounds.position.x + request.bounds.size.x + 1):
            var next_semantic: StringName = &""
            if x < request.bounds.position.x + request.bounds.size.x:
                next_semantic = _semantic(context, Vector2i(x, y))
            if x == request.bounds.position.x + request.bounds.size.x or next_semantic != current_semantic:
                regions.append({
                    "id": "%s.ground.surface.%06d" % [request.area_id, ordinal],
                    "semantic": current_semantic,
                    "rect": Rect2i(Vector2i(run_start, y), Vector2i(x - run_start, 1)),
                    "priority": 0,
                })
                ordinal += 1
                run_start = x
                current_semantic = next_semantic
    return regions

func _semantic(context: Dictionary, cell: Vector2i) -> StringName:
    var kind: StringName = _kind(context, cell)
    if kind == Surface.OCEAN:
        return &"ground.water_ocean"
    if kind == Surface.SHORE:
        return Surface.shore_semantic(
            context.get("world_bounds", Rect2i()),
            int(context.get("world_seed", 0)),
            cell,
            int(context.get("ocean_margin", 48)),
            int(context.get("shore_width", 12)),
            int(context.get("coast_wobble", 18)),
            int(context.get("coast_scale", 96))
        )
    var world_seed: int = int(context.get("world_seed", 0))
    if _value_noise_global(world_seed, cell, 96, 1709) >= 0.82:
        return &"ground.forest_floor"
    return &"ground.grass_lush"

func _value_noise_global(seed: int, cell: Vector2i, scale: int, salt: int) -> float:
    var safe_scale: int = maxi(1, scale)
    var grid_x: int = floori(float(cell.x) / float(safe_scale))
    var grid_y: int = floori(float(cell.y) / float(safe_scale))
    var frac_x: float = float(cell.x - grid_x * safe_scale) / float(safe_scale)
    var frac_y: float = float(cell.y - grid_y * safe_scale) / float(safe_scale)
    var smooth_x: float = frac_x * frac_x * (3.0 - 2.0 * frac_x)
    var smooth_y: float = frac_y * frac_y * (3.0 - 2.0 * frac_y)
    var n00: float = Seed.unit_2d(seed, grid_x, grid_y, salt)
    var n10: float = Seed.unit_2d(seed, grid_x + 1, grid_y, salt)
    var n01: float = Seed.unit_2d(seed, grid_x, grid_y + 1, salt)
    var n11: float = Seed.unit_2d(seed, grid_x + 1, grid_y + 1, salt)
    var top: float = lerpf(n00, n10, smooth_x)
    var bottom: float = lerpf(n01, n11, smooth_x)
    return lerpf(top, bottom, smooth_y)

func _kind(context: Dictionary, cell: Vector2i) -> StringName:
    return Surface.classify(
        context.get("world_bounds", Rect2i()),
        int(context.get("world_seed", 0)),
        cell,
        int(context.get("ocean_margin", 48)),
        int(context.get("shore_width", 12)),
        int(context.get("coast_wobble", 18)),
        int(context.get("coast_scale", 96))
    )

func _surface_context(request: AreaGenerationRequest) -> Dictionary:
    var matches: Array[Dictionary] = []
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("domain", &"")) == &"island" \
            and StringName(constraint.get("kind", &"")) == &"surface_context":
            matches.append(constraint)
    if matches.size() != 1:
        return {}
    var value: Dictionary = matches[0]
    var world_bounds: Rect2i = value.get("world_bounds", Rect2i())
    if world_bounds.size.x <= 0 or world_bounds.size.y <= 0:
        return {}
    return value.duplicate(true)
