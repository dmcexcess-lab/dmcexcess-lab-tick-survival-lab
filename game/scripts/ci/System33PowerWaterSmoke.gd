extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const PowerTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd")
const RefrigerationProviderClass = preload("res://scripts/simulation/utilities/UtilityRefrigerationEnvironmentProvider.gd")

const CENTRAL_SETTLEMENT: String = "settlement.rural.crossroads.001"
const MUNICIPAL_PLANT_ASSET: String = "water.physical.plant.001"

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
        _test_island_water_and_wells()
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
            _check(not service_id.is_empty() and _utilities.power_service_ids().has(service_id), "each building resolves one authoritative local service")
    _check(covered.size() == building_count, "every generated building belongs to one local substation")
    _check(_utilities.power_substation_component_ids().size() == substations.size(), "runtime substation count matches generated topology")

func _test_island_water_and_wells() -> void:
    var central_power: String = _utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    var central_water: String = _utilities.water_service_for_settlement(CENTRAL_SETTLEMENT)
    _check(not central_power.is_empty() and _utilities.power_service_available(central_power), "central local power starts operational")
    _check(not central_water.is_empty() and _utilities.water_service_available(central_water), "central municipal water starts operational")
    _check(_utilities.water_required_power_service_id(central_water).is_empty(), "municipal treatment is independent of outside grid power")

    var plant_ids: Dictionary = {}
    for service: Dictionary in _plan.water_services:
        _check(StringName(service.get("service_mode", &"")) == &"island_wide_municipal", "every planned water service is island-wide municipal")
        _check(bool(service.get("island_wide", false)), "municipal service explicitly owns island-wide coverage")
        _check(not service.has("service_radius") or int(service.get("service_radius", 0)) <= 0, "no hidden radius coverage survives")
        plant_ids[String(service.get("plant_id", ""))] = true
    _check(plant_ids.size() == 1, "one municipal treatment plant serves the island")
    _check(_utilities.water_asset_ids(&"municipal_plant") == [MUNICIPAL_PLANT_ASSET], "one real condition-owned municipal plant asset exists")

    var branch: String = _utilities.power_branch_component_id(central_power)
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_grid_outage"), "local grid branch can fail")
    _check(not _utilities.power_service_available(central_power), "local grid branch outage is real")
    _check(_utilities.water_service_available(central_water), "municipal water survives outside-grid outage")
    _check(_utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_grid_restore"), "local grid branch restores")

    _check(_utilities.damage_water_asset(MUNICIPAL_PLANT_ASSET, 1000, &"smoke_plant_damage"), "critical plant accepts real damage")
    for service: Dictionary in _plan.water_services:
        _check(not _utilities.water_service_available(String(service.get("id", ""))), "critical plant failure removes municipal water island-wide")
    _check(bool(_utilities.repair_water_asset(MUNICIPAL_PLANT_ASSET, 3).get("ok", false)), "critical plant repairs with real materials")
    for service: Dictionary in _plan.water_services:
        _check(_utilities.water_service_available(String(service.get("id", ""))), "plant repair restores municipal water island-wide")

    var rural_home_count: int = int(_topology.get("rural_home_count", 0))
    var wells: Array = _topology.get("wells", [])
    _check(rural_home_count > 0 and not wells.is_empty(), "generated rural homes receive deterministic wells")
    if rural_home_count > 0:
        _check(wells.size() * 100 >= rural_home_count * 10, "at least ten percent of rural homes have wells")
        _check(wells.size() * 100 <= rural_home_count * 20, "no more than twenty percent of rural homes have wells")
    if wells.is_empty():
        return

    var well: Dictionary = wells[0]
    var well_asset: String = String(well.get("asset_id", ""))
    var well_building: String = String(well.get("building_id", ""))
    var well_power: String = String(well.get("power_service_id", ""))
    var well_service: String = _utilities.well_service_for_building(well_building)
    _check(well_asset.begins_with("water.physical.well."), "well has stable real asset identity")
    _check(not well_service.is_empty() and _utilities.water_service_available(well_service), "powered maintained well provides private water")
    _check(_utilities.water_service_for_building(well_building) == well_service, "healthy well is the home's effective unlimited source")

    _check(_utilities.damage_water_asset(MUNICIPAL_PLANT_ASSET, 1000, &"smoke_plant_with_well"), "municipal plant can fail independently")
    _check(_utilities.water_service_available(well_service), "private well survives island municipal failure")
    _check(bool(_utilities.repair_water_asset(MUNICIPAL_PLANT_ASSET, 3).get("ok", false)), "municipal plant repairs after well independence proof")

    var well_branch: String = _utilities.power_branch_component_id(well_power)
    _check(not well_branch.is_empty(), "well's power service exposes local branch")
    _check(_utilities.set_power_component_state(well_branch, UtilityRuntimeState.DAMAGED, &"smoke_well_power_loss"), "well local power can fail")
    _check(not _utilities.water_service_available(well_service), "well stops when local electrical power fails")
    _check(_utilities.water_service_for_building(well_building) != well_service, "home falls back to municipal water when well power is out")
    _check(_utilities.set_power_component_state(well_branch, UtilityRuntimeState.OPERATIONAL, &"smoke_well_power_restore"), "well local power restores")
    _check(_utilities.water_service_available(well_service), "well resumes when local power returns")

    _check(_utilities.damage_water_asset(well_asset, 1000, &"smoke_well_damage"), "well has real damageable condition")
    _check(not _utilities.water_service_available(well_service), "damaged well stops providing water")
    _check(_utilities.water_service_for_building(well_building) != well_service, "damaged well falls back to municipal service")
    _check(bool(_utilities.repair_water_asset(well_asset, 1).get("ok", false)), "well repairs with real maintenance material")
    _check(_utilities.water_service_available(well_service), "well repair restores private service")

    var center: Vector2i = _settlement_center(CENTRAL_SETTLEMENT)
    _check(_utilities.water_service_for_cell(center) == central_water, "cell lookup resolves island-wide municipal service without radius simulation")

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
    _check(_utilities.damage_water_asset(MUNICIPAL_PLANT_ASSET, 1000, &"smoke_snapshot_water"), "snapshot test mutates water asset")
    _check(_utilities.restore_snapshot(snapshot), "valid neighborhood utility snapshot restores")
    _check(_utilities.power_service_available(central_power), "snapshot restores power")
    _check(int(_utilities.water_asset_record(MUNICIPAL_PLANT_ASSET).get("condition", 0)) > 250, "snapshot restores physical water condition")
    _check(_utilities.water_service_available(_utilities.water_service_for_settlement(CENTRAL_SETTLEMENT)), "snapshot restores municipal water")

    var wells: Array = _topology.get("wells", [])
    if not wells.is_empty():
        var well: Dictionary = wells[0]
        var well_service: String = _utilities.well_service_for_building(String(well.get("building_id", "")))
        var settlement_service: String = _utilities.water_service_for_settlement(String(well.get("settlement_id", "")))
        _check(not well_service.is_empty() and settlement_service != well_service, "snapshot keeps settlement municipal mapping separate from private well")

    var malformed: Dictionary = snapshot.duplicate(true)
    malformed["schema_version"] = 999
    _check(not _utilities.restore_snapshot(malformed), "wrong snapshot schema fails closed")
    _check(_utilities.power_service_available(central_power), "failed restore leaves current utility truth intact")

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
