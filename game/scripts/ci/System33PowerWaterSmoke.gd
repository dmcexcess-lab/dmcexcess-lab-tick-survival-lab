extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")
const RefrigerationProviderClass = preload("res://scripts/simulation/utilities/UtilityRefrigerationEnvironmentProvider.gd")

const CENTRAL_SETTLEMENT: String = "settlement.rural.crossroads.001"

var _failures: Array[String] = []

func _initialize() -> void:
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

func _new_state() -> UtilityRuntimeState:
    var plan: GeneratedGlobalWorldPlan = Fixture.generate_global_plan(GlobalFixture.SEED)
    _check(plan != null and plan.is_generated(), "canonical island plan must generate")
    if plan == null or not plan.is_generated():
        return null
    var utilities := UtilityStateClass.new()
    _check(utilities.initialize_from_plan(plan), "utility state must initialize from 00D plan")
    return utilities

func _test_power_water_and_cache() -> void:
    var utilities: UtilityRuntimeState = _new_state()
    if utilities == null or not utilities.is_ready():
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
    _check(not other_power.is_empty(), "island must expose another power service")
    var branch: String = utilities.power_branch_component_id(central_power)
    _check(not branch.is_empty(), "central power must expose local branch")
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_local_outage"), "local branch damage mutates")
    _check(not utilities.power_service_available(central_power), "local branch damage removes central power")
    _check(utilities.power_service_available(other_power), "local branch damage preserves unrelated service")
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_local_restore"), "local branch restores")
    _check(utilities.power_service_available(central_power), "central power restores")

    var source: String = utilities.power_source_component_id()
    _check(not source.is_empty(), "power source must exist")
    _check(utilities.set_power_component_state(source, UtilityRuntimeState.DAMAGED, &"smoke_source_outage"), "source damage mutates")
    _check(not utilities.power_service_available(central_power), "source outage removes central power")
    _check(not utilities.power_service_available(other_power), "source outage removes unrelated power")
    _check(utilities.set_power_component_state(source, UtilityRuntimeState.OPERATIONAL, &"smoke_source_restore"), "source restores")

    _check(utilities.water_service_available(central_water), "rural well water starts operational")
    var water_rev: int = utilities.water_revision()
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.DAMAGED, &"smoke_pump_power_loss"), "pump power loss mutates power")
    _check(not utilities.water_service_available(central_water), "powered rural pump fails when local power fails")
    _check(utilities.water_revision() == water_rev, "power-driven water outage does not fake a water mutation")
    _check(utilities.set_power_component_state(branch, UtilityRuntimeState.OPERATIONAL, &"smoke_pump_power_restore"), "pump power restores")
    _check(utilities.water_service_available(central_water), "water returns when pump power returns")

    var other_water: String = ""
    for service_id: String in utilities.water_service_ids():
        if service_id != central_water:
            other_water = service_id
            break
    var local_water_component: String = utilities.water_local_component_id(central_water)
    _check(utilities.set_water_component_state(local_water_component, UtilityRuntimeState.DAMAGED, &"smoke_local_water"), "local water damage mutates")
    _check(not utilities.water_service_available(central_water), "local water damage removes central water")
    _check(other_water.is_empty() or utilities.water_service_available(other_water), "local water damage preserves unrelated water")
    _check(utilities.set_water_component_state(local_water_component, UtilityRuntimeState.OPERATIONAL, &"smoke_water_restore"), "local water restores")

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

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
