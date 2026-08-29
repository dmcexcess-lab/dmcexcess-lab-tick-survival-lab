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
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.generate_global_plan()
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

    var baseline_support_id: String = ""
    var baseline_support_cell := Vector2i(2147483647, 2147483647)
    for entity_id: String in infrastructure.created_entity_ids():
        if entity_id.find(".support.") < 0:
            continue
        var placement: WorldPlacement = world.placement(entity_id)
        _check(placement != null, "segment support has a real persistent WHAT placement: %s" % entity_id)
        if placement != null:
            _check(
                not _cell_in_planned_road_surface(placement.anchor, plan.road_segments),
                "segment support remains off actual road surface, including crossroads: %s" % entity_id
            )
            if baseline_support_id.is_empty():
                baseline_support_id = entity_id
                baseline_support_cell = placement.anchor

    _check(not baseline_support_id.is_empty(), "baseline support available for constructed-surface regression")
    if not baseline_support_id.is_empty():
        _test_constructed_vehicle_surface_rejection(plan, baseline_support_id, baseline_support_cell)

    for wire: Dictionary in infrastructure.wire_edges():
        var start_id: String = String(wire.get("start_id", ""))
        var end_id: String = String(wire.get("end_id", ""))
        _check(not start_id.is_empty() and not end_id.is_empty(), "wire endpoints have stable IDs")
        _check(world.placement(start_id) != null and world.placement(end_id) != null, "wire endpoints are real persistent WHAT placements")

func _test_constructed_vehicle_surface_rejection(
    plan: GeneratedGlobalWorldPlan,
    baseline_support_id: String,
    baseline_support_cell: Vector2i
) -> void:
    var blocked_surfaces: Array[StringName] = [
        &"ground.road_plain",
        &"ground.parking_faded",
        &"ground.driveway_gravel",
        &"ground.gravel_dark",
        &"ground.gravel_light",
        &"ground.alley_stained",
        &"ground.concrete_oil",
    ]
    for semantic: StringName in blocked_surfaces:
        var world := WorldStateClass.new()
        var mutations := WorldMutationClass.new(world)
        _check(mutations.set_terrain(baseline_support_cell, semantic), "test surface materialized: %s" % String(semantic))
        var utilities := UtilityStateClass.new()
        _check(utilities.initialize_from_plan(plan), "utility state initializes for surface rejection: %s" % String(semantic))
        if not utilities.is_ready():
            continue
        var infrastructure := InfrastructureClass.new(world, mutations, plan, utilities)
        _check(infrastructure.materialize(), "power infrastructure materializes around blocked surface: %s" % String(semantic))
        var placement: WorldPlacement = world.placement(baseline_support_id)
        _check(placement != null, "support identity survives blocked-surface relocation: %s" % String(semantic))
        if placement != null:
            _check(
                placement.anchor != baseline_support_cell,
                "support rejects constructed vehicle surface: %s" % String(semantic)
            )

    var natural_world := WorldStateClass.new()
    var natural_mutations := WorldMutationClass.new(natural_world)
    _check(natural_mutations.set_terrain(baseline_support_cell, &"ground.grass_lush"), "natural-ground control materialized")
    var natural_utilities := UtilityStateClass.new()
    _check(natural_utilities.initialize_from_plan(plan), "utility state initializes for natural-ground control")
    if natural_utilities.is_ready():
        var natural_infrastructure := InfrastructureClass.new(natural_world, natural_mutations, plan, natural_utilities)
        _check(natural_infrastructure.materialize(), "power infrastructure materializes on natural-ground control")
        var natural_placement: WorldPlacement = natural_world.placement(baseline_support_id)
        _check(natural_placement != null, "support identity exists on natural-ground control")
        if natural_placement != null:
            _check(
                natural_placement.anchor == baseline_support_cell,
                "ordinary off-road ground remains valid for utility support placement"
            )

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

func _cell_in_planned_road_surface(cell: Vector2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        var width: int = int(road.get("width", 0))
        if width <= 0:
            continue
        var half_width: int = width / 2
        if start.y == finish.y:
            if cell.x >= mini(start.x, finish.x) and cell.x <= maxi(start.x, finish.x) \
                and absi(cell.y - start.y) <= half_width:
                return true
        elif start.x == finish.x:
            if cell.y >= mini(start.y, finish.y) and cell.y <= maxi(start.y, finish.y) \
                and absi(cell.x - start.x) <= half_width:
                return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
