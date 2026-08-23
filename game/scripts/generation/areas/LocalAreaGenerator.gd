extends RefCounted
class_name LocalAreaGenerator

const PlanClass = preload("res://scripts/generation/areas/GeneratedAreaPlan.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const ReservationPlannerClass = preload("res://scripts/generation/areas/InfrastructureReservationPlanner.gd")
const RoadPlannerClass = preload("res://scripts/generation/areas/LocalRoadPlanner.gd")
const BlockPlannerClass = preload("res://scripts/generation/areas/TownBlockPlanner.gd")
const ParcelPlannerClass = preload("res://scripts/generation/areas/ParcelPlanner.gd")
const AccessPlannerClass = preload("res://scripts/generation/areas/ParcelAccessPlanner.gd")
const BuildingPlannerClass = preload("res://scripts/generation/areas/BuildingPlacementPlanner.gd")
const PavedFrontagePlannerClass = preload("res://scripts/generation/areas/CommercialPavedFrontagePlanner.gd")
const OutdoorPlannerClass = preload("res://scripts/generation/areas/OutdoorPropertyDressingPlanner.gd")
const RuralOpenLandscapePlannerClass = preload("res://scripts/generation/areas/RuralOpenLandscapePlanner.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")

var _area_profiles: AreaProfileCatalog
var _environment_profiles: EnvironmentProfileCatalog
var _reservation_planner: InfrastructureReservationPlanner
var _road_planner: LocalRoadPlanner
var _block_planner: TownBlockPlanner
var _parcel_planner: ParcelPlanner
var _access_planner: ParcelAccessPlanner
var _building_planner: BuildingPlacementPlanner
var _paved_frontage_planner: CommercialPavedFrontagePlanner
var _outdoor_planner: OutdoorPropertyDressingPlanner
var _rural_open_landscape_planner: RuralOpenLandscapePlanner
var _validator: GeneratedAreaValidator

func _init() -> void:
    _area_profiles = AreaProfilesClass.new()
    _environment_profiles = EnvironmentProfilesClass.new()
    _reservation_planner = ReservationPlannerClass.new()
    _road_planner = RoadPlannerClass.new()
    _block_planner = BlockPlannerClass.new()
    _parcel_planner = ParcelPlannerClass.new()
    _access_planner = AccessPlannerClass.new()
    _building_planner = BuildingPlannerClass.new()
    _paved_frontage_planner = PavedFrontagePlannerClass.new()
    _outdoor_planner = OutdoorPlannerClass.new()
    _rural_open_landscape_planner = RuralOpenLandscapePlannerClass.new()
    _validator = ValidatorClass.new()

func generate(request: AreaGenerationRequest) -> GeneratedAreaPlan:
    var plan := PlanClass.new()
    if request == null or not request.is_valid():
        plan.failure_reason = "invalid_area_request"
        return plan
    if not _area_profiles.has_profile(request.area_profile_id):
        plan.failure_reason = "area_profile_unknown"
        return plan
    if not _environment_profiles.has_profile(request.environment_profile_id):
        plan.failure_reason = "environment_profile_unknown"
        return plan

    var area_profile: Dictionary = _area_profiles.profile(request.area_profile_id)
    var environment_profile: Dictionary = _environment_profiles.profile(request.environment_profile_id)
    if bool(area_profile.get("inherited_roads_required", true)) and request.inherited_roads.is_empty():
        plan.failure_reason = "area_profile_requires_inherited_road"
        return plan
    if request.area_profile_id == AreaProfileCatalog.RURAL_OPEN:
        return _generate_rural_open(request, area_profile, environment_profile)

    var reservation_result: Dictionary = _reservation_planner.plan(request, area_profile, request.inherited_roads)
    if not bool(reservation_result.get("ok", false)):
        plan.failure_reason = String(reservation_result.get("failure_reason", "infrastructure_reservation_planning_failed"))
        return plan
    var reservations: Array[Dictionary] = []
    for reservation_value: Variant in reservation_result.get("reservations", []):
        if typeof(reservation_value) != TYPE_DICTIONARY:
            plan.failure_reason = "infrastructure_reservation_result_invalid"
            return plan
        reservations.append(reservation_value)

    var road_result: Dictionary = _road_planner.plan(request, area_profile, reservations)
    if not bool(road_result.get("ok", false)):
        plan.failure_reason = String(road_result.get("failure_reason", "road_planning_failed"))
        return plan
    var roads: Array[Dictionary] = []
    for road_value: Variant in road_result.get("roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            plan.failure_reason = "road_planning_result_invalid"
            return plan
        roads.append(road_value)
    var intersections: Array[Dictionary] = []
    for intersection_value: Variant in road_result.get("intersections", []):
        if typeof(intersection_value) != TYPE_DICTIONARY:
            plan.failure_reason = "intersection_planning_result_invalid"
            return plan
        intersections.append(intersection_value)

    var block_result: Dictionary = _block_planner.plan(request, area_profile, roads, reservations)
    if not bool(block_result.get("ok", false)):
        plan.failure_reason = String(block_result.get("failure_reason", "town_block_planning_failed"))
        return plan
    var blocks: Array[Dictionary] = []
    for block_value: Variant in block_result.get("blocks", []):
        if typeof(block_value) != TYPE_DICTIONARY:
            plan.failure_reason = "town_block_planning_result_invalid"
            return plan
        blocks.append(block_value)

    var parcel_roads: Array[Dictionary] = _parcel_road_order(area_profile, roads)
    var parcel_result: Dictionary = _parcel_planner.plan(request, area_profile, parcel_roads, intersections, reservations)
    if not bool(parcel_result.get("ok", false)):
        plan.failure_reason = String(parcel_result.get("failure_reason", "parcel_planning_failed"))
        return plan
    var parcels: Array[Dictionary] = []
    for parcel_value: Variant in parcel_result.get("parcels", []):
        if typeof(parcel_value) != TYPE_DICTIONARY:
            plan.failure_reason = "parcel_planning_result_invalid"
            return plan
        parcels.append(parcel_value)

    var access_result: Dictionary = _access_planner.assign_access(parcels, roads)
    if not bool(access_result.get("ok", false)):
        plan.failure_reason = String(access_result.get("failure_reason", "parcel_access_failed"))
        return plan

    var building_result: Dictionary = _building_planner.place(request, area_profile, parcels)
    if not bool(building_result.get("ok", false)):
        plan.failure_reason = String(building_result.get("failure_reason", "building_placement_failed"))
        return plan
    var building_requests: Array[BuildingGenerationRequest] = []
    for building_value: Variant in building_result.get("building_requests", []):
        var building_request: BuildingGenerationRequest = building_value as BuildingGenerationRequest
        if building_request == null:
            plan.failure_reason = "building_placement_result_invalid"
            return plan
        building_requests.append(building_request)

    var driveway_result: Dictionary = _access_planner.finalize_driveways(parcels)
    if not bool(driveway_result.get("ok", false)):
        plan.failure_reason = String(driveway_result.get("failure_reason", "driveway_planning_failed"))
        return plan

    var paved_result: Dictionary = _paved_frontage_planner.plan(request, parcels)
    if not bool(paved_result.get("ok", false)):
        plan.failure_reason = String(paved_result.get("failure_reason", "paved_frontage_planning_failed"))
        return plan

    var ground_regions: Array[Dictionary] = []
    for paved_value: Variant in paved_result.get("ground_regions", []):
        if typeof(paved_value) != TYPE_DICTIONARY:
            plan.failure_reason = "paved_frontage_ground_result_invalid"
            return plan
        ground_regions.append(paved_value)

    var outdoor_result: Dictionary = _outdoor_planner.plan(request, environment_profile, roads, intersections, parcels, reservations)
    if not bool(outdoor_result.get("ok", false)):
        plan.failure_reason = String(outdoor_result.get("failure_reason", "outdoor_dressing_failed"))
        return plan
    for ground_value: Variant in outdoor_result.get("ground_regions", []):
        if typeof(ground_value) != TYPE_DICTIONARY:
            plan.failure_reason = "outdoor_ground_result_invalid"
            return plan
        ground_regions.append(ground_value)
    var outdoor_props: Array[Dictionary] = []
    for prop_value: Variant in outdoor_result.get("props", []):
        if typeof(prop_value) != TYPE_DICTIONARY:
            plan.failure_reason = "outdoor_prop_result_invalid"
            return plan
        outdoor_props.append(prop_value)

    plan.area_id = request.area_id
    plan.seed = request.seed
    plan.bounds = request.bounds
    plan.area_profile_id = request.area_profile_id
    plan.area_profile_version = int(area_profile.get("version", 0))
    plan.environment_profile_id = request.environment_profile_id
    plan.environment_profile_version = int(environment_profile.get("version", 0))
    plan.reservations = reservations
    plan.roads = roads
    plan.intersections = intersections
    plan.blocks = blocks
    plan.parcels = parcels
    plan.building_requests = building_requests
    plan.ground_regions = ground_regions
    plan.outdoor_props = outdoor_props

    _validate_final_plan(request, plan)
    return plan

func _generate_rural_open(
    request: AreaGenerationRequest,
    area_profile: Dictionary,
    environment_profile: Dictionary
) -> GeneratedAreaPlan:
    var plan := PlanClass.new()
    var road_result: Dictionary = _road_planner.plan(request, area_profile, [])
    if not bool(road_result.get("ok", false)):
        plan.failure_reason = String(road_result.get("failure_reason", "rural_open_road_planning_failed"))
        return plan

    var roads: Array[Dictionary] = []
    for road_value: Variant in road_result.get("roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            plan.failure_reason = "rural_open_road_result_invalid"
            return plan
        var road: Dictionary = road_value
        if not bool(road.get("inherited", false)):
            plan.failure_reason = "rural_open_local_road_forbidden"
            return plan
        roads.append(road)

    var intersections: Array[Dictionary] = []
    for intersection_value: Variant in road_result.get("intersections", []):
        if typeof(intersection_value) != TYPE_DICTIONARY:
            plan.failure_reason = "rural_open_intersection_result_invalid"
            return plan
        var intersection: Dictionary = intersection_value
        if StringName(intersection.get("control", &"")) != &"uncontrolled":
            plan.failure_reason = "rural_open_controlled_intersection_forbidden"
            return plan
        intersections.append(intersection)

    var surface_environment: Dictionary = environment_profile.duplicate(true)
    surface_environment["tree_semantics"] = []
    surface_environment["shrub_semantics"] = []
    surface_environment["rock_semantics"] = []
    var surface_result: Dictionary = _outdoor_planner.plan(request, surface_environment, roads, intersections, [], [])
    if not bool(surface_result.get("ok", false)):
        plan.failure_reason = String(surface_result.get("failure_reason", "rural_open_surface_planning_failed"))
        return plan

    var landscape_result: Dictionary = _rural_open_landscape_planner.plan(request, area_profile, environment_profile, roads)
    if not bool(landscape_result.get("ok", false)):
        plan.failure_reason = String(landscape_result.get("failure_reason", "rural_open_landscape_planning_failed"))
        return plan

    var ground_regions: Array[Dictionary] = []
    for value: Variant in surface_result.get("ground_regions", []):
        if typeof(value) != TYPE_DICTIONARY:
            plan.failure_reason = "rural_open_surface_ground_invalid"
            return plan
        ground_regions.append(value)
    for value: Variant in landscape_result.get("ground_regions", []):
        if typeof(value) != TYPE_DICTIONARY:
            plan.failure_reason = "rural_open_landscape_ground_invalid"
            return plan
        ground_regions.append(value)

    var outdoor_props: Array[Dictionary] = []
    for value: Variant in landscape_result.get("props", []):
        if typeof(value) != TYPE_DICTIONARY:
            plan.failure_reason = "rural_open_landscape_prop_invalid"
            return plan
        outdoor_props.append(value)

    plan.area_id = request.area_id
    plan.seed = request.seed
    plan.bounds = request.bounds
    plan.area_profile_id = request.area_profile_id
    plan.area_profile_version = int(area_profile.get("version", 0))
    plan.environment_profile_id = request.environment_profile_id
    plan.environment_profile_version = int(environment_profile.get("version", 0))
    plan.reservations = []
    plan.roads = roads
    plan.intersections = intersections
    plan.blocks = []
    plan.parcels = []
    plan.building_requests = []
    plan.ground_regions = ground_regions
    plan.outdoor_props = outdoor_props

    _validate_final_plan(request, plan)
    return plan

func _validate_final_plan(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> void:
    var validation: Dictionary = _validator.validate(request, plan)
    if bool(validation.get("ok", false)):
        return
    var failure_parts := PackedStringArray()
    for failure_value: Variant in validation.get("failures", []):
        failure_parts.append(String(failure_value))
    plan.failure_reason = "area_validation_failed:%s" % ",".join(failure_parts)

func _parcel_road_order(profile: Dictionary, roads: Array[Dictionary]) -> Array[Dictionary]:
    if StringName(profile.get("land_use_mode", &"rural_crossroads")) != &"smalltown_center":
        return roads
    var ordered: Array[Dictionary] = []
    for road: Dictionary in roads:
        if StringName(road.get("road_class", &"")) == &"local_town":
            ordered.append(road)
    for road: Dictionary in roads:
        if StringName(road.get("road_class", &"")) == &"primary":
            ordered.append(road)
    for road: Dictionary in roads:
        var road_class: StringName = StringName(road.get("road_class", &""))
        if road_class != &"local_town" and road_class != &"primary":
            ordered.append(road)
    return ordered

func area_profile_ids() -> Array[StringName]:
    return [AreaProfileCatalog.RURAL_CROSSROADS, AreaProfileCatalog.SMALLTOWN_CENTER, AreaProfileCatalog.RURAL_SCATTERED, AreaProfileCatalog.RURAL_OPEN]

func environment_profile_ids() -> Array[StringName]:
    return [EnvironmentProfileCatalog.TEMPERATE_RURAL]