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
    if _plan != null and _plan.is_generated():
        _topology = PowerTopologyPlannerClass.new().plan(_plan)
        _check(
            bool(_topology.get("ok", false)),
            "local utility topology must plan: %s" % String(_topology.get("failure_reason", "unknown"))
        )
    if bool(_topology.get("ok", false)):
        _utilities = UtilityStateClass.new(_topology)
        _check(_utilities.initialize_from_plan(_plan), "neighborhood utility state initializes")
    if _utilities != null and _utilities.is_ready():
        _test_dynamic_power_topology()
        _test_island_water()
        _test_rural_private_wells()
        _test_refrigeration_clock()
        _test_snapshot_restore()
    _finish()

func _test_dynamic_power_topology() -> void:
    var building_count: int = int(_topology.get("building_count", 0))
    var target: int = int(_topology.get("target_buildings_per_substation", 0))
    var substations: Array = _topology.get("substations", [])
    var site_counts: Dictionary = _topology.get("site_building_counts", {})
    _check(building_count > 0, "power topology derives from generated buildings")
    _check(target == 10, "local substation target remains ten buildings")
    var expected_substations: int = 0
    for value: Variant in site_counts.values():
        var count: int = int(value)
        if count > 0:
            expected_substations += int((count + target - 1) / target)
    _check(substations.size() == expected_substations, "substation count derives from per-site building population")

    var covered: Dictionary = {}
    for value: Variant in substations:
        _check(typeof(value) == TYPE_DICTIONARY, "substation record is valid")
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var substation: Dictionary = value
        var building_ids: Array = substation.get("building_ids", [])
        _check(not building_ids.is_empty() and building_ids.size() <= target, "each substation serves one to ten generated buildings")
        for building_value: Variant in building_ids:
            var building_id: String = String(building_value)
            _check(not covered.has(building_id), "a building cannot belong to two substations")
            covered[building_id] = true
            var service_id: String = _utilities.power_service_for_building(building_id)
            _check(not service_id.is_empty() and _utilities.power_service_ids().has(service_id), "each building resolves one authoritative local power service")
    _check(covered.size() == building_count, "every generated building belongs to one local substation")
    _check(_utilities.power_substation_component_ids().size() == substations.size(), "runtime substation count matches generated topology")

func _test_island_water() -> void:
    var central_power: String = _utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    var central_water: String = _utilities.water_service_for_settlement(CENTRAL_SETTLEMENT)
    _check(not central_power.is_empty() and _utilities.power_service_available(central_power), "central local power starts operational")
    _check(not central_water.is_empty() and _utilities.water_service_available(central_water), "central municipal water starts operational")
    _check(_utilities.water_required_power_service_id(central_water).is_empty(), "municipal water remains independent of outside grid power")
    _check(_plan.water_nodes.is_empty() and _plan.water_segments.is_empty(), "municipal water has no pipe or node graph")
    _check(_plan.wastewater_services.is_empty() and _plan.wastewater_nodes.is_empty() and _plan.wastewater_segments.is_empty(), "wastewater remains absent")

    var facility_ids: Dictionary = {}
    for service: Dictionary in _plan.water_services:
        _check(StringName(service.get("service_mode", &"")) == &"island_wide_municipal", "every planned water service is island-wide municipal")
        _check(bool(service.get("island_wide", false)), "municipal service explicitly owns island-wide coverage")
        facility_ids[String(service.get("facility_id", ""))] = true
    _check(facility_ids.size() == 1, "one municipal facility serves the island")

    var municipal_assets: Array[String] = _utilities.water_asset_ids(&"municipal_plant")
    _check(municipal_assets.size() == 1, "one real condition-owned municipal facility building exists")
    if municipal_assets.is_empty():
        return
    var municipal_asset: String = municipal_assets[0]
    _check(municipal_asset == _utilities.water_facility_building_id(), "municipal water asset is the generated facility building")

    var branch: String = _utilities.power_branch_component_id(central_power)
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_grid_outage"), "local grid branch can fail")
    _check(not _utilities.power_service_available(central_power), "local grid branch outage is real")
    _check(_utilities.water_service_available(central_water), "municipal water survives outside-grid outage")
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_grid_restore"), "local grid branch restores")

    _check(_utilities.damage_water_asset(municipal_asset, 1000, &"smoke_plant_damage"), "municipal facility accepts real damage")
    for service: Dictionary in _plan.water_services:
        _check(not _utilities.water_service_available(String(service.get("id", ""))), "municipal facility failure removes municipal water island-wide")
    _check(bool(_utilities.repair_water_asset(municipal_asset, 3).get("ok", false)), "municipal facility repairs with real materials")
    for service: Dictionary in _plan.water_services:
        _check(_utilities.water_service_available(String(service.get("id", ""))), "municipal repair restores island-wide service")

func _test_rural_private_wells() -> void:
    var rural_building_count: int = int(_topology.get("rural_building_count", 0))
    var wells: Array = _topology.get("wells", [])
    _check(rural_building_count > 0 and not wells.is_empty(), "generated rural buildings receive deterministic private wells")
    if rural_building_count > 0:
        _check(wells.size() * 100 >= rural_building_count * 10, "at least ten percent of rural buildings have wells")
        _check(wells.size() * 100 <= rural_building_count * 20, "no more than twenty percent of rural buildings have wells")

    var replay: Dictionary = PowerTopologyPlannerClass.new().plan(_plan)
    _check(bool(replay.get("ok", false)), "private-well topology replays")
    _check(_well_signature(replay.get("wells", [])) == _well_signature(wells), "same world seed chooses the same rural wells")

    var well_buildings: Dictionary = {}
    for value: Variant in wells:
        _check(typeof(value) == TYPE_DICTIONARY, "well record is valid")
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var well: Dictionary = value
        var asset_id: String = String(well.get("asset_id", ""))
        var building_id: String = String(well.get("building_id", ""))
        var service_id: String = String(well.get("service_id", ""))
        var site_id: String = String(well.get("site_id", ""))
        var cell: Vector2i = well.get("cell", Vector2i(-999999, -999999))
        _check(_site_is_rural(site_id), "only rural-site buildings receive wells")
        _check(asset_id.begins_with("water.physical.well."), "well has stable private asset identity")
        _check(not building_id.is_empty() and not well_buildings.has(building_id), "a rural building receives at most one well")
        well_buildings[building_id] = true
        _check(_utilities.water_asset_ids(&"private_well").has(asset_id), "runtime owns each planned private well")
        _check(_utilities.well_service_for_building(building_id) == service_id, "well maps directly to its owning building")
        _check(_utilities.water_service_for_building(building_id) == service_id, "well replaces municipal water for its building")
        _check(_utilities.water_service_for_cell(cell) == service_id, "well-building cell lookup resolves the private source")
        _check(_utilities.water_required_power_service_id(service_id).is_empty(), "simple private well has no electrical-grid dependency")
        _check(_utilities.water_service_available(service_id), "private well starts operational")

    var non_well_rural: Dictionary = _first_non_well_building(well_buildings, true)
    _check(not non_well_rural.is_empty(), "at least one rural building remains on municipal water")
    if not non_well_rural.is_empty():
        var building_id: String = String(non_well_rural.get("building_id", ""))
        var settlement_id: String = String(non_well_rural.get("settlement_id", ""))
        _check(_utilities.well_service_for_building(building_id).is_empty(), "non-well rural building has no private source")
        _check(_utilities.water_service_for_building(building_id) == _utilities.water_service_for_settlement(settlement_id), "non-well rural building remains municipal")

    var town_building: Dictionary = _first_non_well_building(well_buildings, false)
    _check(not town_building.is_empty(), "town building exists for municipal-only proof")
    if not town_building.is_empty():
        var town_id: String = String(town_building.get("building_id", ""))
        var town_settlement: String = String(town_building.get("settlement_id", ""))
        _check(_utilities.well_service_for_building(town_id).is_empty(), "town building never receives a private rural well")
        _check(_utilities.water_service_for_building(town_id) == _utilities.water_service_for_settlement(town_settlement), "town building stays on municipal water")

    if wells.is_empty():
        return
    var first_well: Dictionary = wells[0]
    var well_asset: String = String(first_well.get("asset_id", ""))
    var well_building: String = String(first_well.get("building_id", ""))
    var well_service: String = String(first_well.get("service_id", ""))
    var well_cell: Vector2i = first_well.get("cell", Vector2i(-999999, -999999))
    var municipal_assets: Array[String] = _utilities.water_asset_ids(&"municipal_plant")
    if municipal_assets.is_empty():
        return
    var municipal_asset: String = municipal_assets[0]

    _check(_utilities.damage_water_asset(municipal_asset, 1000, &"smoke_plant_with_well"), "municipal facility can fail independently")
    _check(_utilities.water_service_available(well_service), "private well survives island municipal failure")
    _check(_utilities.water_service_for_building(well_building) == well_service, "well building remains bound to its private source during municipal failure")
    _check(bool(_utilities.repair_water_asset(municipal_asset, 3).get("ok", false)), "municipal facility repairs after well independence proof")

    _check(_utilities.damage_water_asset(well_asset, 1000, &"smoke_well_damage"), "well has real damageable condition")
    _check(not _utilities.water_service_available(well_service), "damaged well stops providing water")
    _check(_utilities.water_service_for_building(well_building) == well_service, "broken well does not silently fall back to municipal water")
    _check(_utilities.water_service_for_cell(well_cell) == well_service, "broken well remains the building's authoritative source identity")
    _check(bool(_utilities.repair_water_asset(well_asset, 1).get("ok", false)), "well repairs with one maintenance material")
    _check(_utilities.water_service_available(well_service), "well repair restores private service")

    var center: Vector2i = _settlement_center(CENTRAL_SETTLEMENT)
    _check(_utilities.water_service_for_cell(center) == _utilities.water_service_for_settlement(CENTRAL_SETTLEMENT), "ordinary outdoor cell lookup still resolves municipal water")

func _test_refrigeration_clock() -> void:
    var service: String = _utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    var branch: String = _utilities.power_branch_component_id(service)
    _check(_utilities.bind_appliance("test.fridge", &"refrigeration", service, "test.fridge", true), "refrigerator binds to real power service")
    var provider := RefrigerationProviderClass.new(_utilities, "test.fridge", 0)
    _check(provider.is_valid(), "refrigeration provider is valid")
    _check(provider.exposure_ticks_at(100) == 20, "powered refrigerator accrues reduced ambient exposure")
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_fridge_outage"), "fridge power can fail")
    _check(provider.sync_at_tick(100), "refrigeration clock settles at outage")
    _check(provider.exposure_ticks_at(200) == 120, "unpowered refrigerator accrues ambient exposure")
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_fridge_restore"), "fridge power restores")
    _check(provider.sync_at_tick(200), "refrigeration clock settles at restore")
    _check(provider.exposure_ticks_at(300) == 140, "restored refrigerator resumes reduced exposure")

func _test_snapshot_restore() -> void:
    var central_power: String = _utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    var snapshot: Dictionary = _utilities.snapshot()
    var branch: String = _utilities.power_branch_component_id(central_power)
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_snapshot_power"), "snapshot test mutates power")

    var municipal_assets: Array[String] = _utilities.water_asset_ids(&"municipal_plant")
    _check(not municipal_assets.is_empty(), "snapshot has municipal asset")
    if not municipal_assets.is_empty():
        _check(_utilities.damage_water_asset(municipal_assets[0], 1000, &"smoke_snapshot_water"), "snapshot test mutates municipal water asset")
    var private_assets: Array[String] = _utilities.water_asset_ids(&"private_well")
    if not private_assets.is_empty():
        _check(_utilities.damage_water_asset(private_assets[0], 1000, &"smoke_snapshot_well"), "snapshot test mutates private well")

    _check(_utilities.restore_snapshot(snapshot), "valid neighborhood utility snapshot restores")
    _check(_utilities.power_service_available(central_power), "snapshot restores power")
    if not municipal_assets.is_empty():
        _check(int(_utilities.water_asset_record(municipal_assets[0]).get("condition", 0)) > 250, "snapshot restores municipal water condition")
    if not private_assets.is_empty():
        _check(int(_utilities.water_asset_record(private_assets[0]).get("condition", 0)) > 250, "snapshot restores private well condition")
        var well_building: String = _building_for_well_asset(private_assets[0])
        var well_service: String = _utilities.well_service_for_building(well_building)
        _check(not well_building.is_empty() and not well_service.is_empty(), "snapshot rebuilds private well building mapping")
        _check(_utilities.water_service_available(well_service), "snapshot restores private well service")
    _check(_utilities.water_service_available(_utilities.water_service_for_settlement(CENTRAL_SETTLEMENT)), "snapshot restores municipal water")

    var malformed: Dictionary = snapshot.duplicate(true)
    malformed["schema_version"] = 999
    _check(not _utilities.restore_snapshot(malformed), "wrong snapshot schema fails closed")
    _check(_utilities.power_service_available(central_power), "failed restore leaves current utility truth intact")

func _first_non_well_building(well_buildings: Dictionary, rural: bool) -> Dictionary:
    for value: Variant in _topology.get("buildings", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var building: Dictionary = value
        var building_id: String = String(building.get("building_id", ""))
        var is_rural: bool = _site_is_rural(String(building.get("site_id", "")))
        if is_rural == rural and not well_buildings.has(building_id):
            return building
    return {}

func _site_is_rural(site_id: String) -> bool:
    for site: Dictionary in _plan.area_sites:
        if String(site.get("id", "")) != site_id:
            continue
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
        parts.append("%s|%s|%s" % [
            String(well.get("asset_id", "")),
            String(well.get("building_id", "")),
            String(well.get("service_id", "")),
        ])
    return ";".join(parts)

func _settlement_center(settlement_id: String) -> Vector2i:
    for settlement: Dictionary in _plan.settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement.get("center", Vector2i(-999999, -999999))
    return Vector2i(-999999, -999999)

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
