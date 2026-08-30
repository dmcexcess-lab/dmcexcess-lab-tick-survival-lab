extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")
const InfrastructureClass = preload("res://scripts/simulation/utilities/UtilityPowerInfrastructureMaterializer.gd")
const LocalTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")
const NeighborhoodUtilityStateClass = preload("res://scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd")
const NeighborhoodInfrastructureClass = preload("res://scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd")
const UtilityLightingClass = preload("res://scripts/simulation/utilities/UtilityPoweredLightingSourceAdapter.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")
const IslandFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

const INVALID_CELL := Vector2i(2147483647, 2147483647)
const MUNICIPAL_PLANT_ASSET: String = "water.physical.plant.001"

var _failures: Array[String] = []

func _initialize() -> void:
    _test_power_infrastructure_projection()
    _test_neighborhood_utility_physicalization()
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
    for segment: Dictionary in plan.power_segments:
        var services: Array = segment.get("service_settlement_ids", [])
        _check(not services.is_empty(), "00D4 physical segment carries downstream settlement mapping")

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
    _check(int(counts.get("prop.transformer", 0)) == 0, "no fake regional/substation transformer clusters are materialized")
    _check(int(counts.get("prop.utility_box", 0)) > 0, "settlement service switchgear remains physical")

    var baseline_support_id: String = ""
    var baseline_support_cell := Vector2i(2147483647, 2147483647)
    for entity_id: String in infrastructure.created_entity_ids():
        if entity_id.find(".support.") < 0:
            continue
        var placement: WorldPlacement = world.placement(entity_id)
        _check(placement != null, "segment support has real WHAT placement: %s" % entity_id)
        if placement != null:
            _check(not _cell_in_planned_road_surface(placement.anchor, plan.road_segments), "support stays off road/crossroad surface: %s" % entity_id)
            if baseline_support_id.is_empty():
                baseline_support_id = entity_id
                baseline_support_cell = placement.anchor
    _check(not baseline_support_id.is_empty(), "baseline support available for surface regression")
    if not baseline_support_id.is_empty():
        _test_constructed_vehicle_surface_rejection(plan, baseline_support_id, baseline_support_cell)

    var seen_assets: Dictionary = {}
    for wire: Dictionary in infrastructure.wire_edges():
        var start_id: String = String(wire.get("start_id", ""))
        var end_id: String = String(wire.get("end_id", ""))
        var asset_id: String = String(wire.get("asset_id", ""))
        _check(not start_id.is_empty() and not end_id.is_empty(), "wire endpoints have stable IDs")
        _check(world.placement(start_id) != null and world.placement(end_id) != null, "wire endpoints are real persistent WHAT placements")
        _check(not asset_id.is_empty() and not seen_assets.has(asset_id), "wire span has unique stable physical asset ID")
        seen_assets[asset_id] = true
        _check(not (wire.get("service_settlement_ids", []) as Array).is_empty(), "wire span carries downstream service mapping")

func _test_neighborhood_utility_physicalization() -> void:
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.generate_global_plan()
    _check(plan != null and plan.is_generated(), "neighborhood utility physicalization plan generated")
    if plan == null or not plan.is_generated():
        return
    var topology: Dictionary = LocalTopologyPlannerClass.new().plan(plan)
    _check(bool(topology.get("ok", false)), "neighborhood utility topology plans")
    if not bool(topology.get("ok", false)):
        return
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var utilities := NeighborhoodUtilityStateClass.new(topology)
    _check(utilities.initialize_from_plan(plan), "neighborhood utility runtime initializes")
    if not utilities.is_ready():
        return
    var infrastructure := NeighborhoodInfrastructureClass.new(world, mutations, plan, utilities, topology)
    _check(infrastructure.is_ready(), "neighborhood utility infrastructure materializer ready")
    _check(infrastructure.materialize(), "neighborhood power, municipal water plant, and wells physicalize")

    var plant: WorldEntityRecord = world.entity(MUNICIPAL_PLANT_ASSET)
    var plant_placement: WorldPlacement = world.placement(MUNICIPAL_PLANT_ASSET)
    _check(plant != null and plant_placement != null, "municipal treatment plant is a real persistent WHAT entity")
    if plant_placement != null:
        var horizontal_shore_distance: int = mini(
            plant_placement.anchor.x - plan.bounds.position.x,
            plan.bounds.end.x - 1 - plant_placement.anchor.x
        )
        var vertical_shore_distance: int = mini(
            plant_placement.anchor.y - plan.bounds.position.y,
            plan.bounds.end.y - 1 - plant_placement.anchor.y
        )
        var shore_distance: int = mini(horizontal_shore_distance, vertical_shore_distance)
        _check(shore_distance >= 0 and shore_distance <= 128, "physical municipal treatment plant remains near shore")

    var wells: Array = topology.get("wells", [])
    _check(not wells.is_empty(), "physicalization test has selected rural wells")
    for value: Variant in wells:
        if typeof(value) != TYPE_DICTIONARY:
            _check(false, "well projection record must be a dictionary")
            continue
        var well: Dictionary = value
        var asset_id: String = String(well.get("asset_id", ""))
        var building_rect: Rect2i = well.get("rect", Rect2i())
        var entity: WorldEntityRecord = world.entity(asset_id)
        var placement: WorldPlacement = world.placement(asset_id)
        _check(entity != null and placement != null, "selected well is a real persistent WHAT entity: %s" % asset_id)
        if placement != null:
            _check(not building_rect.has_point(placement.anchor), "well is physically outside its owning home footprint: %s" % asset_id)
        _check(not utilities.water_asset_record(asset_id).is_empty(), "selected well shares identity with real condition/maintenance state: %s" % asset_id)

    var snapshot: Dictionary = infrastructure.debug_snapshot()
    var counts: Dictionary = snapshot.get("semantic_counts", {})
    _check(int(counts.get("prop.shed", 0)) == 1, "one visible treatment-building shell is materialized")
    _check(int(counts.get("prop.manhole", 0)) == wells.size(), "every selected well has a visible physical ground-cap entity")
    for wire: Dictionary in infrastructure.wire_edges():
        _check(wire.get("snap_cell", INVALID_CELL) != INVALID_CELL, "each physical local span carries a real snap sound origin")

func _test_constructed_vehicle_surface_rejection(plan: GeneratedGlobalWorldPlan, baseline_support_id: String, baseline_support_cell: Vector2i) -> void:
    var blocked_surfaces: Array[StringName] = [
        &"ground.road_plain", &"ground.parking_faded", &"ground.driveway_gravel",
        &"ground.gravel_dark", &"ground.gravel_light", &"ground.alley_stained", &"ground.concrete_oil",
    ]
    for semantic: StringName in blocked_surfaces:
        var world := WorldStateClass.new()
        var mutations := WorldMutationClass.new(world)
        _check(mutations.set_terrain(baseline_support_cell, semantic), "test surface materialized: %s" % String(semantic))
        var utilities := UtilityStateClass.new()
        _check(utilities.initialize_from_plan(plan), "utility state initializes for blocked surface")
        if not utilities.is_ready():
            continue
        var infrastructure := InfrastructureClass.new(world, mutations, plan, utilities)
        _check(infrastructure.materialize(), "power infrastructure materializes around blocked surface")
        var placement: WorldPlacement = world.placement(baseline_support_id)
        _check(placement != null and placement.anchor != baseline_support_cell, "support rejects constructed vehicle surface: %s" % String(semantic))

    var natural_world := WorldStateClass.new()
    var natural_mutations := WorldMutationClass.new(natural_world)
    _check(natural_mutations.set_terrain(baseline_support_cell, &"ground.grass_lush"), "natural-ground control materialized")
    var natural_utilities := UtilityStateClass.new()
    _check(natural_utilities.initialize_from_plan(plan), "utility state initializes for natural-ground control")
    if natural_utilities.is_ready():
        var natural_infrastructure := InfrastructureClass.new(natural_world, natural_mutations, plan, natural_utilities)
        _check(natural_infrastructure.materialize(), "power infrastructure materializes on natural ground")
        var natural_placement: WorldPlacement = natural_world.placement(baseline_support_id)
        _check(natural_placement != null and natural_placement.anchor == baseline_support_cell, "ordinary off-road ground remains valid")

func _test_colored_bloom_profiles_and_tick_phases() -> void:
    var street: LightEmitterProfile = EmitterProfileClass.streetlight()
    var neon: LightEmitterProfile = EmitterProfileClass.neon()
    var gas: LightEmitterProfile = EmitterProfileClass.gas_sign()
    _check(street.is_valid() and street.presentation_glow_scale > 0.9, "streetlight remains bloom-capable")
    _check(neon.is_valid() and neon.tint.b > neon.tint.r, "neon remains blue")
    _check(gas.is_valid() and gas.tint.r > gas.tint.b * 3.0, "gas sign remains red")
    var green: LightEmitterProfile = UtilityLightingClass.traffic_profile_for_tick(0)
    var yellow: LightEmitterProfile = UtilityLightingClass.traffic_profile_for_tick(UtilityLightingClass.TRAFFIC_GREEN_TICKS)
    var red: LightEmitterProfile = UtilityLightingClass.traffic_profile_for_tick(UtilityLightingClass.TRAFFIC_GREEN_TICKS + UtilityLightingClass.TRAFFIC_YELLOW_TICKS)
    _check(green.profile_id == &"light.traffic.green.candidate001", "traffic begins green")
    _check(yellow.profile_id == &"light.traffic.yellow.candidate001", "traffic advances yellow")
    _check(red.profile_id == &"light.traffic.red.candidate001", "traffic advances red")

func _cell_in_planned_road_surface(cell: Vector2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        var width: int = int(road.get("width", 0))
        if width <= 0:
            continue
        var half_width: int = width / 2
        if start.y == finish.y and cell.x >= mini(start.x, finish.x) and cell.x <= maxi(start.x, finish.x) and absi(cell.y - start.y) <= half_width:
            return true
        if start.x == finish.x and cell.y >= mini(start.y, finish.y) and cell.y <= maxi(start.y, finish.y) and absi(cell.x - start.x) <= half_width:
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
