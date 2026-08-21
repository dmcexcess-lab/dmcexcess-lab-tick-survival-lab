extends RefCounted
class_name LocalAreaGenerator

const PlanClass = preload("res://scripts/generation/areas/GeneratedAreaPlan.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const RoadPlannerClass = preload("res://scripts/generation/areas/LocalRoadPlanner.gd")
const ParcelPlannerClass = preload("res://scripts/generation/areas/ParcelPlanner.gd")
const AccessPlannerClass = preload("res://scripts/generation/areas/ParcelAccessPlanner.gd")
const BuildingPlannerClass = preload("res://scripts/generation/areas/BuildingPlacementPlanner.gd")
const OutdoorPlannerClass = preload("res://scripts/generation/areas/OutdoorPropertyDressingPlanner.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")

var _area_profiles: AreaProfileCatalog
var _environment_profiles: EnvironmentProfileCatalog
var _road_planner: LocalRoadPlanner
var _parcel_planner: ParcelPlanner
var _access_planner: ParcelAccessPlanner
var _building_planner: BuildingPlacementPlanner
var _outdoor_planner: OutdoorPropertyDressingPlanner
var _validator: GeneratedAreaValidator

func _init() -> void:
    _area_profiles = AreaProfilesClass.new()
    _environment_profiles = EnvironmentProfilesClass.new()
    _road_planner = RoadPlannerClass.new()
    _parcel_planner = ParcelPlannerClass.new()
    _access_planner = AccessPlannerClass.new()
    _building_planner = BuildingPlannerClass.new()
    _outdoor_planner = OutdoorPlannerClass.new()
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
    var road_result: Dictionary = _road_planner.plan(request, area_profile)
    if not bool(road_result.get("ok", false)):
        plan.failure_reason = String(road_result.get("failure_reason", "road_planning_failed"))
        return plan
    var roads: Array[Dictionary] = road_result.get("roads", [])
    var intersections: Array[Dictionary] = road_result.get("intersections", [])

    var parcel_result: Dictionary = _parcel_planner.plan(request, area_profile, roads, intersections)
    if not bool(parcel_result.get("ok", false)):
        plan.failure_reason = String(parcel_result.get("failure_reason", "parcel_planning_failed"))
        return plan
    var parcels: Array[Dictionary] = parcel_result.get("parcels", [])

    var access_result: Dictionary = _access_planner.assign_access(parcels, roads)
    if not bool(access_result.get("ok", false)):
        plan.failure_reason = String(access_result.get("failure_reason", "parcel_access_failed"))
        return plan

    var building_result: Dictionary = _building_planner.place(request, area_profile, parcels)
    if not bool(building_result.get("ok", false)):
        plan.failure_reason = String(building_result.get("failure_reason", "building_placement_failed"))
        return plan
    var building_requests: Array[BuildingGenerationRequest] = building_result.get("building_requests", [])

    var driveway_result: Dictionary = _access_planner.finalize_driveways(parcels)
    if not bool(driveway_result.get("ok", false)):
        plan.failure_reason = String(driveway_result.get("failure_reason", "driveway_planning_failed"))
        return plan

    var outdoor_result: Dictionary = _outdoor_planner.plan(request, environment_profile, roads, intersections, parcels)
    if not bool(outdoor_result.get("ok", false)):
        plan.failure_reason = String(outdoor_result.get("failure_reason", "outdoor_dressing_failed"))
        return plan

    plan.area_id = request.area_id
    plan.seed = request.seed
    plan.bounds = request.bounds
    plan.area_profile_id = request.area_profile_id
    plan.area_profile_version = int(area_profile.get("version", 0))
    plan.environment_profile_id = request.environment_profile_id
    plan.environment_profile_version = int(environment_profile.get("version", 0))
    plan.roads = roads
    plan.intersections = intersections
    plan.parcels = parcels
    plan.building_requests = building_requests
    plan.ground_regions = outdoor_result.get("ground_regions", [])
    plan.outdoor_props = outdoor_result.get("props", [])

    var validation: Dictionary = _validator.validate(request, plan)
    if not bool(validation.get("ok", false)):
        plan.failure_reason = "area_validation_failed:%s" % ",".join(validation.get("failures", []))
    return plan

func area_profile_ids() -> Array[StringName]:
    return [AreaProfileCatalog.RURAL_CROSSROADS]

func environment_profile_ids() -> Array[StringName]:
    return [EnvironmentProfileCatalog.TEMPERATE_RURAL]
