extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")
const InfrastructureClass = preload("res://scripts/simulation/utilities/UtilityPowerInfrastructureMaterializer.gd")
const PowerNetworkClass = preload("res://scripts/simulation/utilities/UtilityPowerNetworkRuntime.gd")
const ConditionStoreClass = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")
const IslandFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

var _failures: Array[String] = []
var _test_tick: int = 0

func _initialize() -> void:
    _test_physical_distribution_causality()
    if _failures.is_empty():
        print("SYSTEM33_POWER_PHYSICAL_NETWORK_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SYSTEM33_POWER_PHYSICAL_NETWORK_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_physical_distribution_causality() -> void:
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.generate_global_plan()
    _check(plan != null and plan.is_generated(), "procedural global plan generated")
    if plan == null or not plan.is_generated():
        return
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var utilities := UtilityStateClass.new()
    _check(utilities.initialize_from_plan(plan), "System 33 initialized")
    if not utilities.is_ready():
        return
    var infrastructure := InfrastructureClass.new(world, mutations, plan, utilities)
    _check(infrastructure.materialize(), "physical distribution projection materialized")
    var wires: Array[Dictionary] = infrastructure.wire_edges()
    _check(not wires.is_empty(), "physical wire projection exists")
    if wires.is_empty():
        return

    var network := PowerNetworkClass.new()
    _test_tick = 0
    _check(network.initialize(utilities, wires, Callable(self, "_current_tick")), "analytic physical power runtime initialized")
    if not network.is_ready():
        return

    var targeted_wire: Dictionary = {}
    var targeted_service_ids: Array[String] = []
    for wire: Dictionary in wires:
        var settlements: Array = wire.get("service_settlement_ids", [])
        if settlements.size() != 1:
            continue
        var service_id: String = utilities.power_service_for_settlement(String(settlements[0]))
        if service_id.is_empty():
            continue
        targeted_wire = wire
        targeted_service_ids = [service_id]
        break
    _check(not targeted_wire.is_empty(), "generated physical grid exposes a settlement-specific span")
    if targeted_wire.is_empty():
        return

    var affected_service: String = targeted_service_ids[0]
    var unaffected_service: String = ""
    for service_id: String in utilities.power_service_ids():
        if service_id != affected_service:
            unaffected_service = service_id
            break
    _check(not unaffected_service.is_empty(), "sibling service available for isolation proof")

    var span_id: String = String(targeted_wire.get("asset_id", ""))
    _check(not span_id.is_empty(), "physical wire span has stable condition identity")
    _check(network.damage_asset(span_id, 1000, &"vehicle"), "one physical span accepts event-driven damage")
    _check(not utilities.power_service_available(affected_service), "failed span blacks out its mapped downstream service")
    _check(unaffected_service.is_empty() or utilities.power_service_available(unaffected_service), "unrelated branch stays energized")
    _check(wires.has(targeted_wire), "failed cable remains in presentation topology")

    var requirements: Dictionary = network.repair_requirements(span_id)
    _check(int(requirements.get("electrical_skill", -1)) == 2, "distribution span repair uses low electrical tier")
    _check(int(requirements.get("material_units", -1)) == 1, "distribution span repair uses small material cost")
    var repaired: Dictionary = network.repair_asset(span_id, 2, 1)
    _check(bool(repaired.get("ok", false)), "physical span can be repaired")
    _check(utilities.power_service_available(affected_service), "repair restores only the physical outage owner")

    # Condition is analytic: jump directly to the earliest predicted threshold crossing. The
    # runtime observes the due crossing without iterating simulated days or every asset per tick.
    var next_failure: int = network.next_failure_tick()
    _check(next_failure > ConditionStoreClass.TICKS_PER_DAY and next_failure < ConditionStoreClass.MAX_TICK, "network predicts a finite unattended wear failure after the one-day grace")
    if next_failure < ConditionStoreClass.MAX_TICK:
        _test_tick = next_failure
        _check(network.advance_to_tick(_test_tick), "single due-threshold observation succeeds")
        var debug: Dictionary = network.debug_snapshot()
        var condition_debug: Dictionary = debug.get("condition", {})
        _check(int(condition_debug.get("failed_count", 0)) > 0, "analytic wear creates real failed distribution assets")
        var any_outage: bool = false
        for service_id: String in utilities.power_service_ids():
            if not utilities.power_service_available(service_id):
                any_outage = true
                break
        _check(any_outage, "unattended physical failure propagates into canonical service truth")

    var support_ids: Array[String] = network.asset_ids(ConditionStoreClass.DISTRIBUTION_SUPPORT)
    _check(not support_ids.is_empty(), "physical supports share the generic utility condition substrate")
    if not support_ids.is_empty():
        var support_requirements: Dictionary = network.repair_requirements(support_ids[0])
        _check(int(support_requirements.get("material_units", -1)) == 2, "support repair costs more material than a wire span")

func _current_tick() -> int:
    return _test_tick

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
