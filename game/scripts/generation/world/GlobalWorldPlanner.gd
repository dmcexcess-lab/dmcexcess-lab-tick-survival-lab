extends RefCounted
class_name GlobalWorldPlanner

const PlanClass = preload("res://scripts/generation/world/GeneratedGlobalWorldPlan.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const GeographyPlannerClass = preload("res://scripts/generation/world/GlobalGeographyPlanner.gd")
const HydrologyPlannerClass = preload("res://scripts/generation/world/GlobalHydrologyPlanner.gd")
const SettlementPlannerClass = preload("res://scripts/generation/world/GlobalSettlementPlanner.gd")
const RoadPlannerClass = preload("res://scripts/generation/world/GlobalMajorRoadPlanner.gd")
const BridgePlannerClass = preload("res://scripts/generation/world/GlobalBridgeIntentPlanner.gd")
const RegionPlannerClass = preload("res://scripts/generation/world/GlobalPlanningRegionPlanner.gd")
const ValidatorClass = preload("res://scripts/generation/world/GeneratedGlobalWorldValidator.gd")

var _profiles: GlobalWorldProfileCatalog
var _geography_planner: GlobalGeographyPlanner
var _hydrology_planner: GlobalHydrologyPlanner
var _settlement_planner: GlobalSettlementPlanner
var _road_planner: GlobalMajorRoadPlanner
var _bridge_planner: GlobalBridgeIntentPlanner
var _region_planner: GlobalPlanningRegionPlanner
var _validator: GeneratedGlobalWorldValidator

func _init() -> void:
    _profiles = ProfilesClass.new()
    _geography_planner = GeographyPlannerClass.new()
    _hydrology_planner = HydrologyPlannerClass.new()
    _settlement_planner = SettlementPlannerClass.new()
    _road_planner = RoadPlannerClass.new()
    _bridge_planner = BridgePlannerClass.new()
    _region_planner = RegionPlannerClass.new()
    _validator = ValidatorClass.new()

func generate(request: GlobalWorldGenerationRequest) -> GeneratedGlobalWorldPlan:
    var plan: GeneratedGlobalWorldPlan = PlanClass.new()
    if request == null or not request.is_valid():
        plan.failure_reason = "invalid_global_world_request"
        return plan
    if not _profiles.has_profile(request.profile_id):
        plan.failure_reason = "global_world_profile_unknown"
        return plan

    var profile: Dictionary = _profiles.profile(request.profile_id)

    var geography_result: Dictionary = _geography_planner.plan(request, profile)
    if not bool(geography_result.get("ok", false)):
        plan.failure_reason = String(geography_result.get("failure_reason", "global_geography_planning_failed"))
        return plan
    var geography_cells: Array[Dictionary] = []
    for geography_value: Variant in geography_result.get("geography_cells", []):
        if typeof(geography_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_geography_result_invalid"
            return plan
        geography_cells.append(geography_value)

    var hydrology_result: Dictionary = _hydrology_planner.plan(request, profile, geography_cells)
    if not bool(hydrology_result.get("ok", false)):
        plan.failure_reason = String(hydrology_result.get("failure_reason", "global_hydrology_planning_failed"))
        return plan
    var river_segments: Array[Dictionary] = []
    for river_value: Variant in hydrology_result.get("river_segments", []):
        if typeof(river_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_hydrology_result_invalid"
            return plan
        river_segments.append(river_value)

    var settlement_result: Dictionary = _settlement_planner.plan(request, profile, geography_cells, river_segments)
    if not bool(settlement_result.get("ok", false)):
        plan.failure_reason = String(settlement_result.get("failure_reason", "global_settlement_planning_failed"))
        return plan
    var settlements: Array[Dictionary] = []
    for settlement_value: Variant in settlement_result.get("settlements", []):
        if typeof(settlement_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_settlement_result_invalid"
            return plan
        settlements.append(settlement_value)
    var area_sites: Array[Dictionary] = []
    for site_value: Variant in settlement_result.get("area_sites", []):
        if typeof(site_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_area_site_result_invalid"
            return plan
        area_sites.append(site_value)

    var road_result: Dictionary = _road_planner.plan(request, profile, settlements, geography_cells, river_segments)
    if not bool(road_result.get("ok", false)):
        plan.failure_reason = String(road_result.get("failure_reason", "global_major_road_planning_failed"))
        return plan
    var road_segments: Array[Dictionary] = []
    for road_value: Variant in road_result.get("road_segments", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_major_road_result_invalid"
            return plan
        road_segments.append(road_value)

    var bridge_result: Dictionary = _bridge_planner.plan(road_segments, river_segments)
    if not bool(bridge_result.get("ok", false)):
        plan.failure_reason = String(bridge_result.get("failure_reason", "global_bridge_intent_planning_failed"))
        return plan
    var bridge_intents: Array[Dictionary] = []
    for bridge_value: Variant in bridge_result.get("bridge_intents", []):
        if typeof(bridge_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_bridge_intent_result_invalid"
            return plan
        bridge_intents.append(bridge_value)

    var region_result: Dictionary = _region_planner.plan(request, settlements)
    if not bool(region_result.get("ok", false)):
        plan.failure_reason = String(region_result.get("failure_reason", "global_region_planning_failed"))
        return plan
    var regions: Array[Dictionary] = []
    for region_value: Variant in region_result.get("regions", []):
        if typeof(region_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_region_result_invalid"
            return plan
        regions.append(region_value)

    plan.world_id = request.world_id
    plan.seed = request.seed
    plan.bounds = request.bounds
    plan.profile_id = request.profile_id
    plan.profile_version = int(profile.get("version", 0))
    plan.geography_cells = geography_cells
    plan.river_segments = river_segments
    plan.regions = regions
    plan.settlements = settlements
    plan.road_segments = road_segments
    plan.bridge_intents = bridge_intents
    plan.area_sites = area_sites

    var validation: Dictionary = _validator.validate(request, plan)
    if not bool(validation.get("ok", false)):
        var failure_parts := PackedStringArray()
        for failure_value: Variant in validation.get("failures", []):
            failure_parts.append(String(failure_value))
        plan.failure_reason = "global_world_validation_failed:%s" % ",".join(failure_parts)
    return plan

func profile_ids() -> Array[StringName]:
    return [GlobalWorldProfileCatalog.TEMPERATE_RURAL_REGION]
