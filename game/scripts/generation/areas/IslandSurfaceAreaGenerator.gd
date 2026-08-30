extends RefCounted
class_name IslandSurfaceAreaGenerator

const PlanClass = preload("res://scripts/generation/areas/GeneratedAreaPlan.gd")
const RoadPlannerClass = preload("res://scripts/generation/areas/LocalRoadPlanner.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Surface = preload("res://scripts/generation/shared/IslandSurfaceMath.gd")
const NaturalEcology = preload("res://scripts/generation/shared/NaturalEcologyField.gd")
const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

const PROFILE_ID: StringName = &"island.surface"
const LAND_USE_WILDERNESS: StringName = &"wilderness"
const LAND_USE_FIELD: StringName = &"field"
const LAND_USE_PASTURE: StringName = &"pasture"
const LAND_USE_SALT: int = 47011

var _road_planner: LocalRoadPlanner = RoadPlannerClass.new()
var _environment_profiles: EnvironmentProfileCatalog = EnvironmentProfilesClass.new()

func generate(request: AreaGenerationRequest) -> GeneratedAreaPlan:
    var plan := PlanClass.new()
    if request == null or not request.is_valid() \
        or request.area_profile_id != PROFILE_ID \
        or request.environment_profile_id != EnvironmentProfilesClass.TEMPERATE_RURAL:
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
        "version": 4,
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

    var ground_regions: Array[Dictionary] = _surface_runs(request, context, environment)
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
    plan.area_profile_version = 4
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

static func land_use_kind(world_seed: int, cell: Vector2i, block_size: int, wilderness_fraction: float) -> StringName:
    var size: int = maxi(16, block_size)
    var block_x: int = floori(float(cell.x) / float(size))
    var block_y: int = floori(float(cell.y) / float(size))
    var wilderness: float = clampf(wilderness_fraction, 0.0, 1.0)
    var sample: float = Seed.unit_2d(world_seed, block_x, block_y, LAND_USE_SALT)
    if sample < wilderness:
        return LAND_USE_WILDERNESS
    if wilderness >= 1.0:
        return LAND_USE_WILDERNESS
    var managed_sample: float = (sample - wilderness) / (1.0 - wilderness)
    return LAND_USE_FIELD if managed_sample < 0.55 else LAND_USE_PASTURE

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

    var world_seed: int = int(context.get("world_seed", request.seed))
    var block_size: int = int(context.get("land_use_block_size", 64))
    var wilderness_fraction: float = float(context.get("wilderness_fraction", 0.10))
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        for x in range(request.bounds.position.x, request.bounds.position.x + request.bounds.size.x):
            var cell := Vector2i(x, y)
            if blocked.has(cell) or _kind(context, cell) != Surface.LAND:
                continue
            if land_use_kind(world_seed, cell, block_size, wilderness_fraction) != LAND_USE_WILDERNESS:
                continue
            var semantic: StringName = NaturalEcology.semantic_at(environment, request.seed, cell)
            if semantic == &"":
                continue
            props.append({
                "id": "island_surface.natural.%d.%d" % [cell.x, cell.y],
                "semantic": semantic,
                "cell": cell,
                "facing": Facing.Value.SOUTH,
            })
    return props

func _surface_runs(request: AreaGenerationRequest, context: Dictionary, environment: Dictionary) -> Array[Dictionary]:
    var regions: Array[Dictionary] = []
    var ordinal: int = 0
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        var run_start: int = request.bounds.position.x
        var current_semantic: StringName = _semantic(context, environment, Vector2i(run_start, y))
        for x in range(request.bounds.position.x + 1, request.bounds.position.x + request.bounds.size.x + 1):
            var next_semantic: StringName = &""
            if x < request.bounds.position.x + request.bounds.size.x:
                next_semantic = _semantic(context, environment, Vector2i(x, y))
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

func _semantic(context: Dictionary, environment: Dictionary, cell: Vector2i) -> StringName:
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
    var use: StringName = land_use_kind(
        int(context.get("world_seed", 0)),
        cell,
        int(context.get("land_use_block_size", 64)),
        float(context.get("wilderness_fraction", 0.10))
    )
    if use == LAND_USE_FIELD:
        return StringName(environment.get("field_ground", &"ground.field_green"))
    return StringName(environment.get("base_ground", &"ground.grass_lush"))

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
