extends SceneTree

const InfrastructureClass = preload("res://scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd")
const STREETLIGHT_MIN_SPACING: int = 16

var _failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check_tap_cadence_coalescing()

    var game: Node = (load("res://main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame

    var infrastructure: NeighborhoodPowerInfrastructureMaterializer = game.get("_power_infrastructure")
    var world: WorldState = game.get("_world")
    var lighting: UtilityPoweredLightingSourceAdapter = game.get("_utility_lighting")
    var kernel: TickKernel = game.get("_kernel")
    var utilities: UtilityRuntimeState = game.get("_utilities")
    var network: UtilityPowerNetworkRuntime = game.get("_power_network")
    _check(infrastructure != null and infrastructure.is_ready(), "production power infrastructure boots")
    _check(world != null and lighting != null and lighting.is_ready(), "production streetlight source boots")
    _check(kernel != null and utilities != null and network != null, "production WHEN and power owners boot")
    if infrastructure == null or world == null or lighting == null or kernel == null or utilities == null or network == null:
        _finish()
        return

    var runs: Dictionary = infrastructure.get("_roadside_runs")
    var streetlight_count: int = 0
    for run_key: String in runs:
        var previous_light_axis: int = -2147483648
        for id_value: Variant in runs[run_key]:
            var id: String = String(id_value)
            var record: WorldEntityRecord = world.entity(id)
            var placement: WorldPlacement = world.placement(id)
            _check(record != null and placement != null, "roadside support has persistent physical identity")
            if record == null or placement == null or record.semantic_type != &"prop.streetlight":
                continue
            streetlight_count += 1
            var horizontal: bool = run_key.begins_with("h:")
            var axis: int = placement.anchor.x if horizontal else placement.anchor.y
            if previous_light_axis != -2147483648:
                _check(absi(axis - previous_light_axis) >= STREETLIGHT_MIN_SPACING, "streetlights never bunch inside minimum physical cadence")
            previous_light_axis = axis
    _check(streetlight_count > 0, "real generated roadside streetlights exist")

    # The canonical scenario begins at 08:00, which is DAY. Powered streetlights
    # must be absent while other lawful fixed/equipment emitters remain independent.
    _check(_streetlight_emitters(lighting, world).is_empty(), "powered streetlights are off during canonical daytime")

    # 20:30 is canonical NIGHT. Reset is a test-only lawful WHEN state load; the
    # source derives its phase from the same TickKernel/System-25 profile as game boot.
    var night_tick: int = (12 * 60 * 60 + 30 * 60) * WorldTimeProfile.DEFAULT_TICKS_PER_SECOND
    kernel.reset(night_tick)
    await process_frame
    var night_emitters: Array[LightEmitter] = _streetlight_emitters(lighting, world)
    _check(not night_emitters.is_empty(), "powered streetlights turn on at canonical night")

    var chosen_id: String = ""
    if not night_emitters.is_empty():
        chosen_id = night_emitters[0].emitter_id.trim_prefix("utility.light:")

    _check(utilities.set_power_component_state(utilities.power_source_component_id(), UtilityRuntimeState.DISABLED), "disable real upstream source")
    _check(_streetlight_emitters(lighting, world).is_empty(), "night streetlights go dark with real power outage")
    _check(utilities.set_power_component_state(utilities.power_source_component_id(), UtilityRuntimeState.OPERATIONAL), "restore real upstream source")
    _check(not _streetlight_emitters(lighting, world).is_empty(), "night streetlights return with restored power")

    if not chosen_id.is_empty():
        _check(network.damage_asset(chosen_id, 1000), "damage real streetlight support")
        var damaged_still_emits: bool = false
        for emitter: LightEmitter in _streetlight_emitters(lighting, world):
            if emitter.emitter_id == "utility.light:%s" % chosen_id:
                damaged_still_emits = true
        _check(not damaged_still_emits, "damaged streetlight support stops real night emission")

    for wire: Dictionary in infrastructure.wire_edges():
        var a: WorldPlacement = world.placement(wire["start_id"])
        var b: WorldPlacement = world.placement(wire["end_id"])
        if a != null and b != null:
            _check(Vector2(a.anchor).distance_to(Vector2(b.anchor)) <= float(infrastructure.MAX_WIRE_SPAN), "wire span cap remains intact")

    print("STREETLIGHT_SPACING_NIGHT_COUNTS: lights=%d runs=%d" % [streetlight_count, runs.size()])
    game.queue_free()
    await process_frame
    _finish()

func _check_tap_cadence_coalescing() -> void:
    var infrastructure = InfrastructureClass.new()
    var graph: Dictionary = {}
    for x: int in range(0, 31):
        graph[Vector2i(x, 0)] = []
    for x: int in range(0, 30):
        infrastructure._graph_connect(graph, Vector2i(x, 0), Vector2i(x + 1, 0))
    var customers: Array[Dictionary] = [
        {"building_id": "house.a", "rect": Rect2i(11, 3, 1, 1), "ordinal": 0},
        {"building_id": "house.b", "rect": Rect2i(12, 3, 1, 1), "ordinal": 1},
    ]
    var routes: Dictionary = infrastructure._distribution_routes(Vector2i(0, 0), customers, graph)
    _check(not routes.is_empty(), "straight-road cadence route resolves")
    if routes.is_empty():
        return
    var paths: Array[Dictionary] = routes["customer_paths"]
    _check(paths.size() == 2, "both nearby customers retain service routes")
    if paths.size() == 2:
        _check(paths[0]["tap_cell"] == Vector2i(10, 0), "first nearby customer snaps to trunk cadence")
        _check(paths[1]["tap_cell"] == Vector2i(10, 0), "adjacent customer shares same roadside tap instead of spawning a bunch")

func _streetlight_emitters(lighting: UtilityPoweredLightingSourceAdapter, world: WorldState) -> Array[LightEmitter]:
    var result: Array[LightEmitter] = []
    for emitter: LightEmitter in lighting.emitters():
        if not emitter.emitter_id.begins_with("utility.light:"):
            continue
        var entity_id: String = emitter.emitter_id.trim_prefix("utility.light:")
        var record: WorldEntityRecord = world.entity(entity_id)
        if record != null and record.semantic_type == &"prop.streetlight":
            result.append(emitter)
    return result

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    _failures += 1
    push_error("PROMPT_STREETLIGHT_SPACING_NIGHT_SMOKE: %s" % message)

func _finish() -> void:
    if _failures == 0:
        print("PROMPT_STREETLIGHT_SPACING_NIGHT_SMOKE: PASS")
        quit(0)
        return
    print("PROMPT_STREETLIGHT_SPACING_NIGHT_SMOKE: FAIL count=%d" % _failures)
    quit(1)
