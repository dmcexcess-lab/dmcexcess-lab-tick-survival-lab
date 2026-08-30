extends RefCounted
class_name GlobalWorldPlanner

const PlanClass = preload("res://scripts/generation/world/GeneratedGlobalWorldPlan.gd")
const ProfilesClass = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const GeographyPlannerClass = preload("res://scripts/generation/world/GlobalGeographyPlanner.gd")
const HydrologyPlannerClass = preload("res://scripts/generation/world/GlobalHydrologyPlanner.gd")
const SettlementPlannerClass = preload("res://scripts/generation/world/GlobalSettlementPlanner.gd")
const IslandSettlementPlannerClass = preload("res://scripts/generation/world/IslandSettlementHierarchyPlanner.gd")
const RoadPlannerClass = preload("res://scripts/generation/world/GlobalMajorRoadPlanner.gd")
const IslandRoadPlannerClass = preload("res://scripts/generation/world/IslandMajorRoadNetworkPlanner.gd")
const BridgePlannerClass = preload("res://scripts/generation/world/GlobalBridgeIntentPlanner.gd")
const PowerPlannerClass = preload("res://scripts/generation/world/GlobalPowerInfrastructurePlanner.gd")
const WaterPlannerClass = preload("res://scripts/generation/world/GlobalWaterInfrastructurePlanner.gd")
const RegionPlannerClass = preload("res://scripts/generation/world/GlobalPlanningRegionPlanner.gd")
const ValidatorClass = preload("res://scripts/generation/world/GeneratedGlobalWorldValidator.gd")
const PowerValidatorClass = preload("res://scripts/generation/world/GlobalPowerInfrastructureValidator.gd")
const WaterValidatorClass = preload("res://scripts/generation/world/GlobalWaterInfrastructureValidator.gd")

var _profiles: GlobalWorldProfileCatalog
var _geography_planner: GlobalGeographyPlanner
var _hydrology_planner: GlobalHydrologyPlanner
var _settlement_planner: GlobalSettlementPlanner
var _island_settlement_planner: IslandSettlementHierarchyPlanner
var _road_planner: GlobalMajorRoadPlanner
var _island_road_planner: IslandMajorRoadNetworkPlanner
var _bridge_planner: GlobalBridgeIntentPlanner
var _power_planner: GlobalPowerInfrastructurePlanner
var _water_planner: GlobalWaterInfrastructurePlanner
var _region_planner: GlobalPlanningRegionPlanner
var _validator: GeneratedGlobalWorldValidator
var _power_validator: GlobalPowerInfrastructureValidator
var _water_validator: GlobalWaterInfrastructureValidator

func _init() -> void:
    _profiles = ProfilesClass.new()
    _geography_planner = GeographyPlannerClass.new()
    _hydrology_planner = HydrologyPlannerClass.new()
    _settlement_planner = SettlementPlannerClass.new()
    _island_settlement_planner = IslandSettlementPlannerClass.new()
    _road_planner = RoadPlannerClass.new()
    _island_road_planner = IslandRoadPlannerClass.new()
    _bridge_planner = BridgePlannerClass.new()
    _power_planner = PowerPlannerClass.new()
    _water_planner = WaterPlannerClass.new()
    _region_planner = RegionPlannerClass.new()
    _validator = ValidatorClass.new()
    _power_validator = PowerValidatorClass.new()
    _water_validator = WaterValidatorClass.new()

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

    var island_mode: bool = request.profile_id == ProfilesClass.TEMPERATE_ISLAND_REGION
    var settlement_result: Dictionary
    if island_mode:
        settlement_result = _island_settlement_planner.plan(request, profile, geography_cells, river_segments)
    else:
        settlement_result = _settlement_planner.plan(request, profile, geography_cells, river_segments)
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

    var road_result: Dictionary
    if island_mode:
        road_result = _island_road_planner.plan(request, profile, settlements, geography_cells, river_segments)
    else:
        road_result = _road_planner.plan(request, profile, settlements, geography_cells, river_segments)
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

    var power_result: Dictionary = _power_planner.plan(request, profile, settlements, road_segments)
    if not bool(power_result.get("ok", false)):
        plan.failure_reason = String(power_result.get("failure_reason", "global_power_infrastructure_planning_failed"))
        return plan
    var power_nodes: Array[Dictionary] = []
    for power_node_value: Variant in power_result.get("power_nodes", []):
        if typeof(power_node_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_power_node_result_invalid"
            return plan
        power_nodes.append(power_node_value)
    var power_segments: Array[Dictionary] = []
    for power_segment_value: Variant in power_result.get("power_segments", []):
        if typeof(power_segment_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_power_segment_result_invalid"
            return plan
        power_segments.append(power_segment_value)

    var water_result: Dictionary = _water_planner.plan(request, profile, settlements, area_sites, road_segments)
    if not bool(water_result.get("ok", false)):
        plan.failure_reason = String(water_result.get("failure_reason", "global_water_infrastructure_planning_failed"))
        return plan
    var water_services: Array[Dictionary] = []
    for water_service_value: Variant in water_result.get("water_services", []):
        if typeof(water_service_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_water_service_result_invalid"
            return plan
        water_services.append(water_service_value)
    var water_nodes: Array[Dictionary] = []
    for water_node_value: Variant in water_result.get("water_nodes", []):
        if typeof(water_node_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_water_node_result_invalid"
            return plan
        water_nodes.append(water_node_value)
    var water_segments: Array[Dictionary] = []
    for water_segment_value: Variant in water_result.get("water_segments", []):
        if typeof(water_segment_value) != TYPE_DICTIONARY:
            plan.failure_reason = "global_water_segment_result_invalid"
            return plan
        water_segments.append(water_segment_value)

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
    plan.power_nodes = power_nodes
    plan.power_segments = power_segments
    plan.water_services = water_services
    plan.water_nodes = water_nodes
    plan.water_segments = water_segments
    plan.area_sites = area_sites

    var validation: Dictionary = _validator.validate(request, plan)
    if not bool(validation.get("ok", false)):
        var failure_parts := PackedStringArray()
        for failure_value: Variant in validation.get("failures", []):
            failure_parts.append(String(failure_value))
        plan.failure_reason = "global_world_validation_failed:%s" % ",".join(failure_parts)
        return plan

    var power_validation: Dictionary = _power_validator.validate(request, plan)
    if not bool(power_validation.get("ok", false)):
        var power_failure_parts := PackedStringArray()
        for failure_value: Variant in power_validation.get("failures", []):
            power_failure_parts.append(String(failure_value))
        plan.failure_reason = "global_power_validation_failed:%s" % ",".join(power_failure_parts)
        return plan

    var water_validation: Dictionary = _water_validator.validate(request, plan)
    if not bool(water_validation.get("ok", false)):
        var water_failure_parts := PackedStringArray()
        for failure_value: Variant in water_validation.get("failures", []):
            water_failure_parts.append(String(failure_value))
        plan.failure_reason = "global_water_validation_failed:%s" % ",".join(water_failure_parts)
    return plan

func profile_ids() -> Array[StringName]:
    return [ProfilesClass.TEMPERATE_RURAL_REGION, ProfilesClass.TEMPERATE_ISLAND_REGION]
