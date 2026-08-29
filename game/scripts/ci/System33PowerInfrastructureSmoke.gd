extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")
const InfrastructureClass = preload("res://scripts/simulation/utilities/UtilityPowerInfrastructureMaterializer.gd")
const UtilityLightingClass = preload("res://scripts/simulation/utilities/UtilityPoweredLightingSourceAdapter.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")
const IslandFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_power_infrastructure_projection()
    _test_colored_bloom_profiles_and_tick_phases()
    if _failures.is_empty():
        print("SYSTEM33_POWER_INFRASTRUCTURE_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SYSTEM33_POWER_INFRASTRUCTURE_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_power_infrastructure_projection() -> void:
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.global_plan()
    _check(plan != null and plan.is_generated(), "canonical island global plan generated")
    if plan == null or not plan.is_generated():
        return

    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var utilities := UtilityStateClass.new()
    _check(utilities.initialize_from_plan(plan), "System 33 initializes from canonical 00D power plan")
    if not utilities.is_ready():
        return

    var infrastructure := InfrastructureClass.new(world, mutations, plan, utilities)
    _check(infrastructure.is_ready(), "power infrastructure materializer ready")
    _check(infrastructure.materialize(), "canonical power topology physicalized")
    var snapshot: Dictionary = infrastructure.debug_snapshot()
    var counts: Dictionary = snapshot.get("semantic_counts", {})
    _check(int(snapshot.get("wire_count", 0)) > 0, "road-following overhead wire graph exists")
    _check(int(counts.get("prop.utility_pole_wood", 0)) > 0, "wood utility poles materialized")
    _check(int(counts.get("prop.utility_pole_transformer", 0)) > 0, "transformer poles materialized")
    _check(int(counts.get("prop.streetlight", 0)) > 0, "real streetlights materialized")
    _check(int(counts.get("prop.transformer", 0)) >= 2, "regional/substation transformer equipment materialized")
    _check(int(counts.get("prop.utility_box", 0)) >= 2, "regional/substation switchgear materialized")

    for wire: Dictionary in infrastructure.wire_edges():
        var start_id: String = String(wire.get("start_id", ""))
        var end_id: String = String(wire.get("end_id", ""))
        _check(not start_id.is_empty() and not end_id.is_empty(), "wire endpoints have stable IDs")
        _check(world.placement(start_id) != null and world.placement(end_id) != null, "wire endpoints are real persistent WHAT placements")

func _test_colored_bloom_profiles_and_tick_phases() -> void:
    var street: LightEmitterProfile = EmitterProfileClass.streetlight()
    var neon: LightEmitterProfile = EmitterProfileClass.neon()
    var gas: LightEmitterProfile = EmitterProfileClass.gas_sign()
    _check(street.is_valid() and street.presentation_glow_scale > 0.9, "streetlight remains a bloom-capable physical source")
    _check(street.tint.b > 0.9 and street.tint.r > 0.9, "streetlight uses bright near-white utility light")
    _check(neon.is_valid() and neon.presentation_glow_scale > 0.9 and neon.tint.b > neon.tint.r, "neon is strong colored blue bloom")
    _check(gas.is_valid() and gas.presentation_glow_scale > 0.9 and gas.tint.r > gas.tint.b * 3.0, "gas sign is strong colored red bloom")

    var green: LightEmitterProfile = UtilityLightingClass.traffic_profile_for_tick(0)
    var yellow: LightEmitterProfile = UtilityLightingClass.traffic_profile_for_tick(UtilityLightingClass.TRAFFIC_GREEN_TICKS)
    var red: LightEmitterProfile = UtilityLightingClass.traffic_profile_for_tick(
        UtilityLightingClass.TRAFFIC_GREEN_TICKS + UtilityLightingClass.TRAFFIC_YELLOW_TICKS
    )
    _check(green.profile_id == &"light.traffic.green.candidate001", "traffic cycle begins green")
    _check(yellow.profile_id == &"light.traffic.yellow.candidate001", "traffic cycle advances to yellow at authoritative tick boundary")
    _check(red.profile_id == &"light.traffic.red.candidate001", "traffic cycle advances to red at authoritative tick boundary")
    _check(green.tint != yellow.tint and yellow.tint != red.tint and green.tint != red.tint, "traffic phases emit distinct physical colors")
    _check(UtilityLightingClass.traffic_profile_for_tick(UtilityLightingClass.TRAFFIC_CYCLE_TICKS).profile_id == green.profile_id, "traffic cycle repeats deterministically from world tick")

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
