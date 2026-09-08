extends SceneTree

var _failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _test_crossing_and_long_span()
    var game: Node = (load("res://main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame
    var infrastructure: NeighborhoodPowerInfrastructureMaterializer = game.get("_power_infrastructure")
    _check(infrastructure != null and infrastructure.is_ready(), "production neighborhood power boots")
    if infrastructure == null or infrastructure.wire_edges().is_empty():
        _check(false, "production wire graph materializes")
        _finish()
        return
    var world: WorldState = game.get("_world")
    var wires: Array[Dictionary] = infrastructure.wire_edges()
    var longest: float = 0.0
    var segments: Array[Dictionary] = []
    var physical_pairs: Dictionary = {}
    var lights: int = 0
    var supports: Dictionary = {}
    var dump: Array = []
    for wire: Dictionary in wires:
        var a: WorldPlacement = world.placement(wire["start_id"])
        var b: WorldPlacement = world.placement(wire["end_id"])
        _check(a != null and b != null, "wire has physical endpoints")
        if a == null or b == null:
            continue
        var length: float = Vector2(a.anchor).distance_to(Vector2(b.anchor))
        longest = maxf(longest, length)
        _check(length <= float(infrastructure.MAX_WIRE_SPAN), "physical wire obeys span cap: %s" % wire["asset_id"])
        var pair: String = str(a.anchor) + ">" + str(b.anchor) if str(a.anchor) < str(b.anchor) else str(b.anchor) + ">" + str(a.anchor)
        _check(not physical_pairs.has(pair), "physical span is not duplicated")
        physical_pairs[pair] = true
        segments.append({"a": Vector2(a.anchor), "b": Vector2(b.anchor)})
        supports[wire["start_id"]] = true
        supports[wire["end_id"]] = true
        dump.append({"a": [a.anchor.x, a.anchor.y], "b": [b.anchor.x, b.anchor.y], "role": wire["wire_role"], "start_id": wire["start_id"], "end_id": wire["end_id"], "route": str(wire["route_start_cell"])})
    _check_no_crossings(segments)
    var runs: Dictionary = infrastructure.get("_roadside_runs")
    for key: String in runs:
        var ids: Array = runs[key]
        for index: int in range(ids.size()):
            var record: WorldEntityRecord = world.entity(ids[index])
            var expected: StringName = &"prop.streetlight" if index % 2 == 1 else &"prop.utility_pole_wood"
            _check(record != null and record.semantic_type == expected, "alternating physical roadside pole: %s" % ids[index])
            _check(supports.has(ids[index]), "roadside pole belongs to real network")
            if expected == &"prop.streetlight":
                lights += 1
    _check(lights > 0, "generated roadside streetlights exist")
    var lighting: UtilityPoweredLightingSourceAdapter = game.get("_utility_lighting")
    var lit_ids: Dictionary = {}
    for emitter: LightEmitter in lighting.emitters():
        lit_ids[String(emitter.emitter_id)] = true
    for key: String in runs:
        for id: String in runs[key]:
            if world.entity(id).semantic_type == &"prop.streetlight":
                _check(lit_ids.has("utility.light:%s" % id), "real streetlight emitter enabled: %s" % id)
    var physical: PhysicalLightingService = game.get("_physical_lighting")
    var utilities: UtilityRuntimeState = game.get("_utilities")
    var bindings: Dictionary = infrastructure.support_power_services()
    var damage_light: String = ""
    var lit_sample: Vector2i = Vector2i.ZERO
    var sample_found: bool = false
    for emitter: LightEmitter in lighting.emitters():
        var id: String = emitter.emitter_id.trim_prefix("utility.light:")
        if not bindings.has(id) or world.entity(id).semantic_type != &"prop.streetlight":
            continue
        damage_light = id
        _check(utilities.appliance_record(emitter.emitter_id).get("power_service_id", "") == bindings[id], "streetlight uses its physical distribution service")
        _check(emitter.profile.base_luminance > 0.0 and emitter.profile.presentation_glow_scale > 0.0, "streetlight has illumination and rendered glow")
        if not sample_found and physical.field_bounds().has_point(emitter.origin_cell) and world.has_terrain(emitter.origin_cell):
            lit_sample = emitter.origin_cell
            sample_found = true
    _check(sample_found, "streetlight lies in the real active lighting field")
    if sample_found:
        _check(physical.illumination_at(lit_sample).local_artificial > 0.0, "streetlight contributes real world illumination")
    _check(utilities.set_power_component_state(utilities.power_source_component_id(), UtilityRuntimeState.DISABLED), "turn off real upstream power")
    for emitter: LightEmitter in lighting.emitters():
        _check(not bindings.has(emitter.emitter_id.trim_prefix("utility.light:")), "unpowered roadside lights stop emitting")
    if sample_found:
        _check(physical.illumination_at(lit_sample).local_artificial == 0.0, "production light field loses artificial illumination with power")
    _check(utilities.set_power_component_state(utilities.power_source_component_id(), UtilityRuntimeState.OPERATIONAL), "restore upstream power")
    if sample_found:
        _check(physical.illumination_at(lit_sample).local_artificial > 0.0, "production streetlight illumination returns with power")
    var network: UtilityPowerNetworkRuntime = game.get("_power_network")
    _check(not damage_light.is_empty() and network.damage_asset(damage_light, 1000), "damage a real physical streetlight support")
    for emitter: LightEmitter in lighting.emitters():
        _check(emitter.emitter_id != "utility.light:%s" % damage_light, "damaged distribution support stops its real streetlight emission")
    print("ROADSIDE_POWER_COUNTS: wires=%d lights=%d longest=%.2f" % [wires.size(), lights, longest])
    if OS.has_environment("POLE_GEOMETRY_DIAGNOSTIC"):
        var file := FileAccess.open(OS.get_environment("POLE_GEOMETRY_DIAGNOSTIC"), FileAccess.WRITE)
        if file != null:
            file.store_string(JSON.stringify(dump))
    game.queue_free()
    await process_frame
    _finish()

# Independent geometry assertion: use Godot's segment intersection primitive,
# not the production crossing helper. A sweep limits comparison to nearby spans.
func _check_no_crossings(segments: Array[Dictionary]) -> void:
    segments.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return minf(a["a"].x, a["b"].x) < minf(b["a"].x, b["b"].x)
    )
    for i: int in range(segments.size()):
        var a: Vector2 = segments[i]["a"]
        var b: Vector2 = segments[i]["b"]
        for j: int in range(i + 1, segments.size()):
            var c: Vector2 = segments[j]["a"]
            var d: Vector2 = segments[j]["b"]
            if minf(c.x, d.x) > maxf(a.x, b.x):
                break
            var intersection: Variant = Geometry2D.segment_intersects_segment(a, b, c, d)
            if intersection == null:
                continue
            var point: Vector2 = intersection
            _check(point.is_equal_approx(a) or point.is_equal_approx(b) or point.is_equal_approx(c) or point.is_equal_approx(d), "wires meet at supports, never an unsupported X: %s %s %s %s" % [a, b, c, d])

func _test_crossing_and_long_span() -> void:
    var world := WorldState.new()
    var plan := GeneratedGlobalWorldPlan.new()
    plan.bounds = Rect2i(-32, -32, 160, 160)
    var infrastructure := NeighborhoodPowerInfrastructureMaterializer.new(world, WorldMutationService.new(world), plan)
    var props: Array[Dictionary] = []
    var reserved: Dictionary = {}
    var points: Array[Vector2i] = [Vector2i(0, 0), Vector2i(10, 10), Vector2i(0, 10), Vector2i(10, 0), Vector2i(20, 30), Vector2i(68, 30)]
    for index: int in range(points.size()):
        props.append({"id": "pole.%d" % index, "cell": points[index], "semantic": &"prop.utility_pole_wood"})
        reserved[points[index]] = true
    var wires: Array[Dictionary] = []
    for index: int in range(0, points.size(), 2):
        wires.append({"asset_id": "span.%d" % index, "start_id": "pole.%d" % index, "end_id": "pole.%d" % (index + 1), "service_settlement_ids": ["test.service"], "segment_id": "test.segment"})
    var result: Dictionary = infrastructure._bound_wire_spans(props, wires, reserved)
    _check(not result.is_empty(), "crossed leads and long span produce a lawful supported route")
    if result.is_empty():
        return
    var cells: Dictionary = {}
    for prop: Dictionary in props:
        cells[prop["id"]] = Vector2(prop["cell"])
    var segments: Array[Dictionary] = []
    for wire: Dictionary in result["wires"]:
        var a: Vector2 = cells[wire["start_id"]]
        var b: Vector2 = cells[wire["end_id"]]
        _check(a.distance_to(b) <= 16.0, "long lead gets real intermediate supports")
        _check(wire["service_settlement_ids"] == ["test.service"], "subdivision retains service provenance")
        segments.append({"a": a, "b": b})
    _check(props.size() > points.size(), "intermediate supports exist as physical projection records")
    _check_no_crossings(segments)

func _check(ok: bool, message: String) -> void:
    if not ok:
        _failures += 1
        push_error("PROMPT_ROADSIDE_POWER: %s" % message)

func _finish() -> void:
    if _failures == 0:
        print("PROMPT_ROADSIDE_POWER_SMOKE: PASS")
    quit(0 if _failures == 0 else 1)
