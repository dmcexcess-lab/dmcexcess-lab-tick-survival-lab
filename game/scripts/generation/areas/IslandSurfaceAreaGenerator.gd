extends RefCounted
class_name IslandSurfaceAreaGenerator

const PlanClass = preload("res://scripts/generation/areas/GeneratedAreaPlan.gd")
const RoadPlannerClass = preload("res://scripts/generation/areas/LocalRoadPlanner.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
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

    var profile: Dictionary = {
        "id": PROFILE_ID,
        "version": 1,
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
                "id": "%s.ground.road.%s" % [request.area_id, String(road.get("road_id", "road"))],
                "semantic": &"ground.road_plain",
                "cells": road_cells,
                "priority": 100,
            })

    var environment: Dictionary = _environment_profiles.profile(request.environment_profile_id)
    if environment.is_empty():
        plan.failure_reason = "island_surface_environment_missing"
        return plan

    plan.area_id = request.area_id
    plan.seed = request.seed
    plan.bounds = request.bounds
    plan.area_profile_id = PROFILE_ID
    plan.area_profile_version = 1
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
    plan.outdoor_props = []
    return plan

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
    return &"ground.grass_lush"

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
