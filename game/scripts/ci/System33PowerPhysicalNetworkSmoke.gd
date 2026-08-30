extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const PowerTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd")
const InfrastructureClass = preload("res://scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd")
const PowerNetworkClass = preload("res://scripts/simulation/utilities/UtilityPowerNetworkRuntime.gd")
const ConditionStoreClass = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")
const IslandFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

const INVALID_CELL := Vector2i(2147483647, 2147483647)

var _failures: Array[String] = []
var _test_tick: int = 0
var _snap_events: Array[Dictionary] = []

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
    var topology: Dictionary = PowerTopologyPlannerClass.new().plan(plan)
    _check(bool(topology.get("ok", false)), "local physical power topology generated")
    if not bool(topology.get("ok", false)):
        return
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var utilities := UtilityStateClass.new(topology)
    _check(utilities.initialize_from_plan(plan), "System 33 initialized")
    if not utilities.is_ready():
        return
    var infrastructure := InfrastructureClass.new(world, mutations, plan, utilities, topology)
    _check(infrastructure.materialize(), "physical local distribution projection materialized")
    var wires: Array[Dictionary] = infrastructure.wire_edges()
    _check(not wires.is_empty(), "physical local wire projection exists")
    if wires.is_empty():
        return

    var network := PowerNetworkClass.new()
    _test_tick = 0
    _check(network.initialize(utilities, wires, Callable(self, "_current_tick")), "event-driven physical power runtime initialized")
    if not network.is_ready():
        return
    network.line_snapped.connect(Callable(self, "_on_line_snapped"))

    var targeted_wire: Dictionary = wires[0]
    var settlements: Array = targeted_wire.get("service_settlement_ids", [])
    _check(settlements.size() == 1, "local wire maps to exactly one generated local service")
    if settlements.size() != 1:
        return
    var affected_service: String = utilities.power_service_for_settlement(String(settlements[0]))
    _check(not affected_service.is_empty(), "physical local wire resolves authoritative downstream service")
    if affected_service.is_empty():
        return
    var unaffected_service: String = ""
    for service_id: String in utilities.power_service_ids():
        if service_id != affected_service:
            unaffected_service = service_id
            break
    _check(not unaffected_service.is_empty(), "sibling local service available for isolation proof")

    var span_id: String = String(targeted_wire.get("asset_id", ""))
    _check(not span_id.is_empty(), "physical wire span has stable condition identity")
    _check(network.damage_asset(span_id, 1000, &"vehicle"), "one physical span accepts event-driven damage")
    _check(not utilities.power_service_available(affected_service), "failed span blacks out its mapped downstream service")
    _check(unaffected_service.is_empty() or utilities.power_service_available(unaffected_service), "unrelated local branch stays energized")
    _check(wires.has(targeted_wire), "failed cable remains in presentation topology")

    var requirements: Dictionary = network.repair_requirements(span_id)
    _check(int(requirements.get("electrical_skill", -1)) == 2, "distribution span repair uses low electrical tier")
    _check(int(requirements.get("material_units", -1)) == 1, "distribution span repair uses small material cost")
    var repaired: Dictionary = network.repair_asset(span_id, 2, 1)
    _check(bool(repaired.get("ok", false)), "physical span can be repaired")
    _check(utilities.power_service_available(affected_service), "repair restores only the physical outage owner")

    var first_test_tick: int = network.next_failure_tick()
    _check(first_test_tick == ConditionStoreClass.TICKS_PER_DAY, "next automatic work is the next authoritative day boundary")
    var initial_chance: int = network.current_daily_snap_chance()
    _check(initial_chance > 0 and initial_chance < 10000, "daily snap begins at a conservative low chance")

    var day_count: int = 0
    while _snap_events.is_empty() and day_count < 2000:
        var next_tick: int = network.next_failure_tick()
        _test_tick = next_tick
        _check(network.advance_to_tick(_test_tick), "authoritative day-boundary snap pass succeeds")
        day_count += 1
        if _snap_events.is_empty() and day_count == 1:
            var quiet_debug: Dictionary = network.debug_snapshot()
            _check(int(quiet_debug.get("quiet_days", 0)) == 1, "a no-snap day increments the quiet-day counter")
            _check(network.current_daily_snap_chance() > initial_chance, "a no-snap day increases the next day's chance")
    _check(not _snap_events.is_empty(), "deterministic escalating daily snap eventually produces a real line failure")
    if _snap_events.is_empty():
        return

    _check(_snap_events.size() == 1, "first snap stops all remaining line tests for that day")
    var snap: Dictionary = _snap_events[0]
    var snapped_span: String = String(snap.get("asset_id", ""))
    var snapped_cell: Vector2i = snap.get("cell", INVALID_CELL)
    _check(not snapped_span.is_empty(), "daily snap reports the actual failed physical span")
    _check(snapped_cell != INVALID_CELL, "daily snap reports a real physical sound origin")
    var snapped_record: Dictionary = network.asset_record(snapped_span)
    _check(bool(snapped_record.get("failed", false)), "daily snap creates real failed condition state")
    _check(network.current_daily_snap_chance() == initial_chance, "a snap resets next day's chance to base")

    var snapped_services: Array = snapped_record.get("affected_services", [])
    _check(not snapped_services.is_empty(), "snapped span retains causal downstream service mapping")
    for service_value: Variant in snapped_services:
        _check(not utilities.power_service_available(String(service_value)), "snapped line propagates outage into canonical service truth")

    var event_count: int = _snap_events.size()
    _check(network.advance_to_tick(_test_tick), "reobserving the same day is a no-op")
    _check(_snap_events.size() == event_count, "same authoritative day never tests or snaps a second time")

    var snap_requirements: Dictionary = network.repair_requirements(snapped_span)
    var snap_repair: Dictionary = network.repair_asset(
        snapped_span,
        int(snap_requirements.get("electrical_skill", 0)),
        int(snap_requirements.get("material_units", 0))
    )
    _check(bool(snap_repair.get("ok", false)), "daily-snapped physical line repairs through the existing repair seam")
    for service_value: Variant in snapped_services:
        _check(utilities.power_service_available(String(service_value)), "repair restores snapped line's mapped service")

    var support_ids: Array[String] = network.asset_ids(ConditionStoreClass.DISTRIBUTION_SUPPORT)
    _check(not support_ids.is_empty(), "physical supports share the generic utility condition substrate")
    if not support_ids.is_empty():
        var support_requirements: Dictionary = network.repair_requirements(support_ids[0])
        _check(int(support_requirements.get("material_units", -1)) == 2, "support repair costs more material than a wire span")

    var condition_record: Dictionary = network.asset_record(span_id)
    _check(int(condition_record.get("predicted_failure_tick", 0)) == ConditionStoreClass.MAX_TICK, "healthy asset condition no longer predicts analytic unattended wear failure")

func _on_line_snapped(asset_id: String, cell: Vector2i) -> void:
    _snap_events.append({"asset_id": asset_id, "cell": cell, "tick": _test_tick})

func _current_tick() -> int:
    return _test_tick

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
