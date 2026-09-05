extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const PowerTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd")
const RefrigerationProviderClass = preload("res://scripts/simulation/utilities/UtilityRefrigerationEnvironmentProvider.gd")

const CENTRAL_SETTLEMENT: String = "settlement.rural.crossroads.001"

var _failures: Array[String] = []
var _plan: GeneratedGlobalWorldPlan = null
var _topology: Dictionary = {}
var _utilities: NeighborhoodUtilityRuntimeState = null

func _initialize() -> void:
    _plan = Fixture.generate_global_plan(GlobalFixture.SEED)
    _check(_plan != null and _plan.is_generated(), "canonical island plan must generate")
    if _plan == null or not _plan.is_generated():
        _finish()
        return
    _topology = PowerTopologyPlannerClass.new().plan(_plan)
    _check(bool(_topology.get("ok", false)), "local utility topology must plan")
    if not bool(_topology.get("ok", false)):
        _finish()
        return
    _utilities = UtilityStateClass.new(_topology)
    _check(_utilities.initialize_from_plan(_plan), "neighborhood utility state initializes")
    if _utilities == null or not _utilities.is_ready():
        _finish()
        return
    _test_power_baseline()
    _test_municipal_water_baseline()
    _test_private_wells()
    _test_refrigeration_clock()
    _test_snapshot_restore()
    _finish()

func _test_power_baseline() -> void:
    var building_count: int = int(_topology.get("building_count", 0))
    var target: int = int(_topology.get("target_buildings_per_substation", 0))
    var substations: Array = _topology.get("substations", [])
    _check(building_count > 0, "power topology derives from generated buildings")
    _check(target == 10, "local substation target remains ten buildings")
    _check(not substations.is_empty(), "generated island has local substations")
    var covered: Dictionary = {}
    for value: Variant in substations:
        if typeof(value) != TYPE_DICTIONARY:
            _check(false, "substation record is valid")
            continue
        var substation: Dictionary = value
        var building_ids: Array = substation.get("building_ids", [])
        _check(not building_ids.is_empty() and building_ids.size() <= target, "each substation serves one to ten buildings")
        for building_value: Variant in building_ids:
            var building_id: String = String(building_value)
            _check(not covered.has(building_id), "building cannot belong to two substations")
            covered[building_id] = true
            var service_id: String = _utilities.power_service_for_building(building_id)
            _check(not service_id.is_empty() and _utilities.power_service_available(service_id), "generated building has operational local power")
    _check(covered.size() == building_count, "every generated building belongs to one local substation")

func _test_municipal_water_baseline() -> void:
    _check(not _plan.water_services.is_empty(), "island has municipal service references")
    var facility_ids: Dictionary = {}
    for service: Dictionary in _plan.water_services:
        _check(StringName(service.get("service_mode", &"")) == &"island_wide_municipal", "municipal service mode is island-wide")
        _check(bool(service.get("island_wide", false)), "municipal service owns island-wide coverage")
        facility_ids[String(service.get("facility_id", ""))] = true
    _check(facility_ids.size() == 1, "one municipal facility serves the island")
    var municipal_assets: Array[String] = _utilities.water_asset_ids(&"municipal_plant")
    _check(municipal_assets.size() == 1, "one real municipal water asset exists")
    if municipal_assets.is_empty():
        return
    _check(municipal_assets[0] == _utilities.water_facility_building_id(), "municipal asset is the generated facility building")
    var central_water: String = _utilities.water_service_for_settlement(CENTRAL_SETTLEMENT)
    _check(not central_water.is_empty() and _utilities.water_service_available(central_water), "municipal water starts operational")
    _check(_utilities.water_required_power_service_id(central_water).is_empty(), "municipal water is independent of outside grid power")

func _test_private_wells() -> void:
    var rural_building_count: int = int(_topology.get("rural_building_count", 0))
    var wells: Array = _topology.get("wells", [])
    _check(rural_building_count > 0, "generated island has rural buildings")
    _check(not wells.is_empty(), "rural well assignment creates wells")
    if rural_building_count <= 0 or wells.is_empty():
        return
    _check(wells.size() * 100 >= rural_building_count * 10, "at least ten percent of rural buildings have wells")
    _check(wells.size() * 100 <= rural_building_count * 20, "no more than twenty percent of rural buildings have wells")
    var replay: Dictionary = PowerTopologyPlannerClass.new().plan(_plan)
    _check(bool(replay.get("ok", false)), "private-well topology replays")
    _check(_well_signature(replay.get("wells", [])) == _well_signature(wells), "same seed chooses the same wells")

    var well_buildings: Dictionary = {}
    for value: Variant in wells:
        if typeof(value) != TYPE_DICTIONARY:
            _check(false, "well record is valid")
            continue
        var well: Dictionary = value
        var asset_id: String = String(well.get("asset_id", ""))
        var building_id: String = String(well.get("building_id", ""))
        var service_id: String = String(well.get("service_id", ""))
        var site_id: String = String(well.get("site_id", ""))
        var cell: Vector2i = well.get("cell", Vector2i(-999999, -999999))
        _check(_site_is_rural(site_id), "only rural-site buildings receive wells")
        _check(asset_id.begins_with("water.physical.well."), "well has stable private asset identity")
        _check(not building_id.is_empty() and not well_buildings.has(building_id), "building receives at most one well")
        well_buildings[building_id] = true
        _check(_utilities.water_asset_ids(&"private_well").has(asset_id), "runtime owns planned private well")
        _check(_utilities.well_service_for_building(building_id) == service_id, "well maps directly to owning building")
        _check(_utilities.water_service_for_building(building_id) == service_id, "well replaces municipal source for owning building")
        _check(_utilities.water_service_for_cell(cell) == service_id, "well building resolves its private source spatially")
        _check(_utilities.water_required_power_service_id(service_id).is_empty(), "simple well has no grid dependency")
        _check(_utilities.water_service_available(service_id), "private well starts operational")

    _check(_utilities.water_asset_ids(&"private_well").size() == wells.size(), "runtime private-well count matches planner")
    var non_well_rural: Dictionary = _first_building_without_well(well_buildings, true)
    _check(not non_well_rural.is_empty(), "some rural buildings remain municipal")
    if not non_well_rural.is_empty():
        var rural_id: String = String(non_well_rural.get("building_id", ""))
        var rural_service: String = _utilities.water_service_for_building(rural_id)
        _check(_utilities.well_service_for_building(rural_id).is_empty(), "non-well rural building has no private source")
        _check(not rural_service.is_empty() and _utilities.water_service_available(rural_service), "non-well rural building remains on municipal water")

    var town_building: Dictionary = _first_building_without_well(well_buildings, false)
    _check(not town_building.is_empty(), "town building exists for exclusion proof")
    if not town_building.is_empty():
        var town_id: String = String(town_building.get("building_id", ""))
        var town_service: String = _utilities.water_service_for_building(town_id)
        _check(_utilities.well_service_for_building(town_id).is_empty(), "town building never receives rural private well")
        _check(not town_service.is_empty() and _utilities.water_service_available(town_service), "town building remains municipal")

    var first_well: Dictionary = wells[0]
    var well_asset: String = String(first_well.get("asset_id", ""))
    var well_building: String = String(first_well.get("building_id", ""))
    var well_service: String = String(first_well.get("service_id", ""))
    var municipal_assets: Array[String] = _utilities.water_asset_ids(&"municipal_plant")
    if municipal_assets.is_empty():
        return
    var municipal_asset: String = municipal_assets[0]
    _check(_utilities.damage_water_asset(municipal_asset, 1000, &"smoke_municipal_failure"), "municipal facility accepts damage")
    _check(_utilities.water_service_available(well_service), "private well survives municipal failure")
    _check(_utilities.water_service_for_building(well_building) == well_service, "well building remains on private source during municipal failure")
    _check(bool(_utilities.repair_water_asset(municipal_asset, 3).get("ok", false)), "municipal facility repairs")
    _check(_utilities.damage_water_asset(well_asset, 1000, &"smoke_well_failure"), "private well accepts damage")
    _check(not _utilities.water_service_available(well_service), "broken well stops water for its building")
    _check(_utilities.water_service_for_building(well_building) == well_service, "broken well does not fall back to municipal water")
    _check(bool(_utilities.repair_water_asset(well_asset, 1).get("ok", false)), "private well repairs with one maintenance material")
    _check(_utilities.water_service_available(well_service), "well repair restores private water")

    var outdoor_cell: Vector2i = _first_outdoor_cell()
    _check(outdoor_cell != Vector2i(-999999, -999999), "test can find ordinary outdoor cell")
    if outdoor_cell != Vector2i(-999999, -999999):
        var outdoor_service: String = _utilities.water_service_for_cell(outdoor_cell)
        _check(not outdoor_service.is_empty() and _utilities.water_service_available(outdoor_service), "ordinary outdoor cell resolves municipal water")

func _test_refrigeration_clock() -> void:
    var service: String = _utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    var branch: String = _utilities.power_branch_component_id(service)
    if service.is_empty() or branch.is_empty():
        _check(false, "central power service exists for refrigeration proof")
        return
    _check(_utilities.bind_appliance("test.fridge", &"refrigeration", service, "test.fridge", true), "refrigerator binds to real power")
    var provider := RefrigerationProviderClass.new(_utilities, "test.fridge", 0)
    _check(provider.is_valid(), "refrigeration provider is valid")
    _check(provider.exposure_ticks_at(100) == 20, "powered refrigerator accrues reduced exposure")
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_fridge_outage"), "fridge branch can fail")
    _check(provider.sync_at_tick(100), "refrigeration clock settles at outage")
    _check(provider.exposure_ticks_at(200) == 120, "unpowered refrigerator accrues ambient exposure")
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_fridge_restore"), "fridge branch restores")

func _test_snapshot_restore() -> void:
    var snapshot: Dictionary = _utilities.snapshot()
    _check(not snapshot.is_empty(), "utility snapshot exists")
    var private_assets: Array[String] = _utilities.water_asset_ids(&"private_well")
    var municipal_assets: Array[String] = _utilities.water_asset_ids(&"municipal_plant")
    if not private_assets.is_empty():
        _check(_utilities.damage_water_asset(private_assets[0], 1000, &"snapshot_well_damage"), "snapshot test can damage a well")
    if not municipal_assets.is_empty():
        _check(_utilities.damage_water_asset(municipal_assets[0], 1000, &"snapshot_municipal_damage"), "snapshot test can damage municipal facility")
    _check(_utilities.restore_snapshot(snapshot), "valid neighborhood utility snapshot restores")
    if not private_assets.is_empty():
        _check(int(_utilities.water_asset_record(private_assets[0]).get("condition", 0)) > 250, "snapshot restores private well condition")
        var building_id: String = _building_for_well_asset(private_assets[0])
        var service_id: String = _utilities.well_service_for_building(building_id)
        _check(not building_id.is_empty() and not service_id.is_empty() and _utilities.water_service_available(service_id), "snapshot restores private well mapping")
    if not municipal_assets.is_empty():
        _check(int(_utilities.water_asset_record(municipal_assets[0]).get("condition", 0)) > 250, "snapshot restores municipal condition")

func _first_building_without_well(well_buildings: Dictionary, rural: bool) -> Dictionary:
    for value: Variant in _topology.get("buildings", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var building: Dictionary = value
        var building_id: String = String(building.get("building_id", ""))
        var is_rural: bool = _site_is_rural(String(building.get("site_id", "")))
        if is_rural == rural and not well_buildings.has(building_id):
            return building
    return {}

func _first_outdoor_cell() -> Vector2i:
    var occupied: Array[Rect2i] = []
    for value: Variant in _topology.get("buildings", []):
        if typeof(value) == TYPE_DICTIONARY:
            occupied.append((value as Dictionary).get("rect", Rect2i()))
    for y: int in range(_plan.bounds.position.y, _plan.bounds.end.y):
        for x: int in range(_plan.bounds.position.x, _plan.bounds.end.x):
            var cell := Vector2i(x, y)
            var inside_building: bool = false
            for rect: Rect2i in occupied:
                if rect.has_point(cell):
                    inside_building = true
                    break
            if not inside_building:
                return cell
    return Vector2i(-999999, -999999)

func _site_is_rural(site_id: String) -> bool:
    for site: Dictionary in _plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return String(StringName(site.get("area_profile_hint", &""))).begins_with("rural.")
    return false

func _building_for_well_asset(asset_id: String) -> String:
    for value: Variant in _topology.get("wells", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var well: Dictionary = value
        if String(well.get("asset_id", "")) == asset_id:
            return String(well.get("building_id", ""))
    return ""

func _well_signature(wells_value: Variant) -> String:
    if typeof(wells_value) != TYPE_ARRAY:
        return "invalid"
    var parts: PackedStringArray = []
    for value: Variant in wells_value:
        if typeof(value) != TYPE_DICTIONARY:
            return "invalid"
        var well: Dictionary = value
        parts.append("%s|%s|%s" % [String(well.get("asset_id", "")), String(well.get("building_id", "")), String(well.get("service_id", ""))])
    return ";".join(parts)

func _finish() -> void:
    if _failures.is_empty():
        print("SYSTEM33_POWER_WATER_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SYSTEM33_POWER_WATER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
