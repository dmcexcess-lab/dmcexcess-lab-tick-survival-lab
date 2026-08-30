extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const PowerTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd")
const RefrigerationProviderClass = preload("res://scripts/simulation/utilities/UtilityRefrigerationEnvironmentProvider.gd")

const CENTRAL_SETTLEMENT: String = "settlement.rural.crossroads.001"

var _failures: Array[String] = []

func _initialize() -> void:
    _test_dynamic_power_topology()
    _test_power_water_and_cache()
    _test_refrigeration_clock()
    _test_snapshot_restore()
    if _failures.is_empty():
        print("SYSTEM33_POWER_WATER_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SYSTEM33_POWER_WATER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _canonical_plan() -> GeneratedGlobalWorldPlan:
    var plan: GeneratedGlobalWorldPlan = Fixture.generate_global_plan(GlobalFixture.SEED)
    _check(plan != null and plan.is_generated(), "canonical island plan must generate")
    return plan

func _canonical_topology(plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if plan == null or not plan.is_generated():
        return {}
    var topology: Dictionary = PowerTopologyPlannerClass.new().plan(plan)
    _check(bool(topology.get("ok", false)), "generated local power topology must plan")
    return topology

func _new_state() -> UtilityRuntimeState:
    var plan: GeneratedGlobalWorldPlan = _canonical_plan()
    if plan == null or not plan.is_generated():
        return null
    var topology: Dictionary = _canonical_topology(plan)
    if not bool(topology.get("ok", false)):
        return null
    var utilities := UtilityStateClass.new(topology)
    _check(utilities.initialize_from_plan(plan), "utility state must initialize from generated local power topology")
    return utilities

func _test_dynamic_power_topology() -> void:
    var plan: GeneratedGlobalWorldPlan = _canonical_plan()
    if plan == null or not plan.is_generated():
        return
    var topology: Dictionary = _canonical_topology(plan)
    if not bool(topology.get("ok", false)):
        return

    var building_count: int = int(topology.get("building_count", 0))
    var target: int = int(topology.get("target_buildings_per_substation", 0))
    var substations: Array = topology.get("substations", [])
    var site_counts: Dictionary = topology.get("site_building_counts", {})
    _check(building_count > 0, "local power topology must derive from actual generated buildings")
    _check(target == 10, "local substation target must remain ten buildings")

    var expected_substations: int = 0
    for site_value: Variant in site_counts.values():
        var count: int = int(site_value)
        if count > 0:
            expected_substations += int((count + target - 1) / target)
    _check(substations.size() == expected_substations, "substation count must be derived from per-site generated building population")

    var covered: Dictionary = {}
    for value: Variant in substations:
        _check(typeof(value) == TYPE_DICTIONARY, "every planned substation record must be valid")
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var substation: Dictionary = value
        var building_ids: Array = substation.get("building_ids", [])
        _check(not building_ids.is_empty() and building_ids.size() <= target, "each substation must serve one to ten generated buildings")
        _check(not String(substation.get("service_key", "")).is_empty(), "each substation exposes a stable local service key")
        for building_value: Variant in building_ids:
            var building_id: String = String(building_value)
            _check(not covered.has(building_id), "a generated building cannot belong to two substations")
            covered[building_id] = true
    _check(covered.size() == building_count, "every generated building must belong to exactly one local substation")

    var utilities := UtilityStateClass.new(topology)
    _check(utilities.initialize_from_plan(plan), "dynamic substation runtime must initialize")
    if not utilities.is_ready():
        return
    _check(utilities.power_substation_component_ids().size() == substations.size(), "runtime substation count must match generated topology")
    var building_service: Dictionary = topology.get("building_service", {})
    for building_value: Variant in building_service.keys():
        var building_id: String = String(building_value)
        var service_id: String = utilities.power_service_for_building(building_id)
        _check(not service_id.is_empty(), "every generated building must resolve its local power service")
        _check(utilities.power_service_ids().has(service_id), "building service must be an authoritative runtime service")

func _test_power_water_and_cache() -> void:
    var plan: GeneratedGlobalWorldPlan = _canonical_plan()
    if plan == null or not plan.is_generated():
        return
    var topology: Dictionary = _canonical_topology(plan)
    if not bool(topology.get("ok", false)):
        return
    var utilities := UtilityStateClass.new(topology)
    _check(utilities.initialize_from_plan(plan), "utility state must initialize from canonical generated topology")
    if not utilities.is_ready():
        return

    var central_power: String = utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    var central_water: String = utilities.water_service_for_settlement(CENTRAL_SETTLEMENT)
    _check(not central_power.is_empty(), "central settlement must have power binding")
    _check(not central_water.is_empty(), "central settlement must have water binding")
    _check(utilities.power_service_available(central_power), "central power starts operational")
    var telemetry_before: Dictionary = utilities.telemetry()
    _check(utilities.power_service_available(central_power), "repeated power query remains operational")
    var telemetry_after: Dictionary = utilities.telemetry()
    _check(
        int(telemetry_after.get("power_cache_hits", 0)) > int(telemetry_before.get("power_cache_hits", 0)),
        "repeated power query must hit revision cache"
    )

    var other_power: String = ""
    for service_id: String in utilities.power_service_ids():
        if service_id != central_power:
            other_power = service_id
            break
    _check(not other_power.is_empty(), "island must expose another local-substation power service")
    var branch: String = utilities.power_branch_component_id(central_power)
    _check(not branch.is_empty(), "central power must expose local branch")
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_local_outage"), "local branch damage mutates")
    _check(not utilities.power_service_available(central_power), "local branch damage removes central power")
    _check(utilities.power_service_available(other_power), "local branch damage preserves unrelated substation service")
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_local_restore"), "local branch restores")
    _check(utilities.power_service_available(central_power), "central power restores")

    var source: String = utilities.power_source_component_id()
    _check(not source.is_empty(), "power source must exist")
    _check(utilities.set_power_component_state(source, UtilityRuntimeState.DAMAGED, &"smoke_source_outage"), "source damage mutates")
    _check(not utilities.power_service_available(central_power), "source outage removes central power")
    _check(not utilities.power_service_available(other_power), "source outage removes unrelated power")
    _check(utilities.set_power_component_state(source, UtilityRuntimeState.OPERATIONAL, &"smoke_source_restore"), "source restores")

    var plant_ids: Dictionary = {}
    for service: Dictionary in plan.water_services:
        _check(StringName(service.get("service_mode", &"")) != &"decentralized_source", "regional water plan contains no private-source service")
        plant_ids[String(service.get("plant_id", ""))] = true
    _check(plant_ids.size() == 4, "canonical island exposes four regional water treatment plants")
    _check(utilities.water_service_available(central_water), "regional water starts operational")

    var central_plant: String = utilities.water_plant_id(central_water)
    var water_power: String = utilities.water_required_power_service_id(central_water)
    var treatment: String = utilities.water_treatment_component_id(central_water)
    _check(not central_plant.is_empty(), "central water resolves to a real plant")
    _check(not water_power.is_empty(), "central water plant has a real power dependency")
    _check(not treatment.is_empty(), "central water exposes a treatment component")

    var other_plant_water: String = ""
    for service_id: String in utilities.water_service_ids():
        if utilities.water_plant_id(service_id) != central_plant:
            other_plant_water = service_id
            break
    _check(not other_plant_water.is_empty(), "island exposes an independently served water plant")

    var water_power_branch: String = utilities.power_branch_component_id(water_power)
    _check(not water_power_branch.is_empty(), "water plant power service exposes a branch")
    var water_rev: int = utilities.water_revision()
    _check(utilities.set_power_component_state(water_power_branch, UtilityRuntimeState.DAMAGED, &"smoke_plant_power_loss"), "plant power loss mutates power")
    _check(not utilities.water_service_available(central_water), "regional treatment fails when its host power fails")
    _check(other_plant_water.is_empty() or utilities.water_service_available(other_plant_water), "plant power loss preserves a different treatment plant")
    _check(utilities.water_revision() == water_rev, "power-driven water outage does not fake a water mutation")
    _check(utilities.set_power_component_state(water_power_branch, UtilityRuntimeState.OPERATIONAL, &"smoke_plant_power_restore"), "plant power restores")
    _check(utilities.water_service_available(central_water), "regional water returns when plant power returns")

    var same_plant_water: String = ""
    for service_id: String in utilities.water_service_ids():
        if service_id != central_water and utilities.water_plant_id(service_id) == central_plant:
            same_plant_water = service_id
            break
    _check(utilities.set_water_component_state(treatment, UtilityRuntimeState.DAMAGED, &"smoke_treatment_damage"), "treatment plant damage mutates water")
    _check(not utilities.water_service_available(central_water), "treatment plant damage removes central water")
    _check(same_plant_water.is_empty() or not utilities.water_service_available(same_plant_water), "same plant outage removes every dependent service")
    _check(other_plant_water.is_empty() or utilities.water_service_available(other_plant_water), "treatment plant damage preserves other plants")
    _check(utilities.set_water_component_state(treatment, UtilityRuntimeState.OPERATIONAL, &"smoke_treatment_restore"), "treatment plant restores")
    _check(utilities.water_service_available(central_water), "regional water restores with treatment")

    var central_center: Vector2i = _settlement_center(plan, CENTRAL_SETTLEMENT)
    var spatial_service: String = utilities.water_service_for_cell(central_center)
    _check(not spatial_service.is_empty(), "structure-scale cell lookup resolves water inside a plant radius")
    _check(utilities.water_plant_id(spatial_service) == central_plant, "cell lookup resolves the same nearest regional plant")

func _test_refrigeration_clock() -> void:
    var utilities: UtilityRuntimeState = _new_state()
    if utilities == null or not utilities.is_ready():
        return
    var power_service: String = utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    var branch: String = utilities.power_branch_component_id(power_service)
    _check(utilities.bind_appliance("test.fridge", &"refrigeration", power_service, "test.fridge", true), "refrigerator binds to real service")
    var provider := RefrigerationProviderClass.new(utilities, "test.fridge", 0)
    _check(provider.is_valid(), "refrigeration provider must be valid")
    _check(provider.exposure_ticks_at(100) == 20, "powered refrigerator accrues 20 percent ambient exposure")
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_fridge_outage"), "fridge outage mutates")
    _check(provider.sync_at_tick(100), "provider settles at outage boundary")
    _check(provider.exposure_ticks_at(200) == 120, "unpowered refrigerator accrues ambient exposure")
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_fridge_restore"), "fridge power restores")
    _check(provider.sync_at_tick(200), "provider settles at restore boundary")
    _check(provider.exposure_ticks_at(300) == 140, "restored refrigerator resumes reduced exposure without losing history")
    _check(utilities.set_appliance_switched("test.fridge", false, &"smoke_fridge_switch"), "fridge switch mutates")
    _check(provider.sync_at_tick(300), "provider settles switch boundary")
    _check(provider.exposure_ticks_at(400) == 240, "switched-off refrigerator is ambient")

func _test_snapshot_restore() -> void:
    var utilities: UtilityRuntimeState = _new_state()
    if utilities == null or not utilities.is_ready():
        return
    var central_power: String = utilities.power_service_for_settlement(CENTRAL_SETTLEMENT)
    _check(utilities.bind_appliance("snapshot.fridge", &"refrigeration", central_power, "snapshot.fridge", true), "snapshot appliance binds")
    var snapshot: Dictionary = utilities.snapshot()
    var branch: String = utilities.power_branch_component_id(central_power)
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_snapshot_mutation"), "snapshot test mutates branch")
    _check(not utilities.power_service_available(central_power), "snapshot mutation changes service")
    _check(utilities.restore_snapshot(snapshot), "valid snapshot restores")
    _check(utilities.power_service_available(central_power), "snapshot restore recovers service")
    _check(utilities.cold_storage_available("snapshot.fridge"), "snapshot restore recovers appliance state")

    var malformed: Dictionary = snapshot.duplicate(true)
    malformed["schema_version"] = 999
    _check(not utilities.restore_snapshot(malformed), "wrong snapshot schema fails closed")
    _check(utilities.power_service_available(central_power), "failed restore leaves current utility truth intact")

func _settlement_center(plan: GeneratedGlobalWorldPlan, settlement_id: String) -> Vector2i:
    for settlement: Dictionary in plan.settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement.get("center", Vector2i(-999999, -999999))
    return Vector2i(-999999, -999999)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
