extends SceneTree

var _failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Node = (load("res://main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame

    var infrastructure: NeighborhoodPowerInfrastructureMaterializer = game.get("_power_infrastructure")
    var world: WorldState = game.get("_world")
    var lighting: UtilityPoweredLightingSourceAdapter = game.get("_utility_lighting")
    var physical: PhysicalLightingService = game.get("_physical_lighting")
    var kernel: TickKernel = game.get("_kernel")
    var world_time: WorldTimeService = game.get("_world_time")
    var daylight: OutdoorAmbientLightService = game.get("_ambient_daylight")

    _check(infrastructure != null and infrastructure.is_ready(), "production neighborhood power boots")
    _check(world != null and lighting != null and lighting.is_ready(), "production utility lighting boots")
    _check(kernel != null and world_time != null and daylight != null and daylight.is_ready(), "canonical world time/daylight boots")
    if infrastructure == null or world == null or lighting == null or kernel == null or daylight == null:
        _finish()
        return

    var wires: Array[Dictionary] = infrastructure.wire_edges()
    _check(not wires.is_empty(), "production wire graph materializes")
    var longest: float = 0.0
    for wire: Dictionary in wires:
        var a: WorldPlacement = world.placement(String(wire.get("start_id", "")))
        var b: WorldPlacement = world.placement(String(wire.get("end_id", "")))
        _check(a != null and b != null, "wire has physical endpoints")
        if a == null or b == null:
            continue
        var length: float = Vector2(a.anchor).distance_to(Vector2(b.anchor))
        longest = maxf(longest, length)
        _check(length > 0.0, "coalesced topology never creates zero-length physical wire")
        _check(length <= float(infrastructure.MAX_WIRE_SPAN), "wire keeps physical max-span contract")

    var runs: Dictionary = infrastructure.get("_roadside_runs")
    var streetlight_ids: Array[String] = []
    var min_gap: int = 2147483647
    for key: String in runs:
        var ids: Array = runs[key]
        var previous: WorldPlacement = null
        for index: int in range(ids.size()):
            var id: String = String(ids[index])
            var record: WorldEntityRecord = world.entity(id)
            var placement: WorldPlacement = world.placement(id)
            var expected: StringName = &"prop.streetlight" if index % 2 == 1 else &"prop.utility_pole_wood"
            _check(record != null and record.semantic_type == expected, "roadside sequence still alternates real streetlights")
            _check(placement != null, "roadside support has physical placement")
            if placement != null and previous != null:
                var gap: int = absi(placement.anchor.x - previous.anchor.x) + absi(placement.anchor.y - previous.anchor.y)
                min_gap = mini(min_gap, gap)
                _check(gap >= infrastructure.ROAD_POLE_MIN_SPACING, "same-bank roadside supports are not bunched: %s gap=%d" % [key, gap])
            if expected == &"prop.streetlight":
                streetlight_ids.append(id)
            previous = placement

    _check(not streetlight_ids.is_empty(), "generated roadside streetlights exist")
    _check(daylight.current_phase() == OutdoorAmbientLightService.PHASE_DAY, "reference game starts in canonical daytime")
    var daytime_emitters: Dictionary = _streetlight_emitters(lighting)
    _check(daytime_emitters.is_empty(), "powered streetlights are physically dark during daytime")

    var time_profile: WorldTimeProfile = world_time.profile()
    var daylight_profile: DaylightProfile = daylight.daylight_profile()
    var seconds_to_night: int = daylight_profile.night_start_second - time_profile.start_second_of_day
    if seconds_to_night < 0:
        seconds_to_night += WorldTimeProfile.SECONDS_PER_DAY
    var night_tick: int = seconds_to_night * time_profile.ticks_per_second
    kernel.reset(night_tick)
    _check(daylight.current_phase() == OutdoorAmbientLightService.PHASE_NIGHT, "authoritative WHEN reset reaches canonical night")

    var night_emitters: Dictionary = _streetlight_emitters(lighting)
    _check(night_emitters.size() == streetlight_ids.size(), "all powered generated streetlights emit at night")
    var sample_found: bool = false
    for id: String in streetlight_ids:
        _check(night_emitters.has("utility.light:%s" % id), "night emitter exists for alternating streetlight: %s" % id)
        if sample_found:
            continue
        var placement: WorldPlacement = world.placement(id)
        if placement != null and physical != null and physical.field_bounds().has_point(placement.anchor) and world.has_terrain(placement.anchor):
            sample_found = true
            _check(physical.illumination_at(placement.anchor).local_artificial > 0.0, "night streetlight contributes real physical illumination")
    _check(sample_found, "night streetlight sample lies in active physical lighting field")

    print("STREETLIGHT_SPACING_NIGHT_COUNTS: wires=%d lights=%d min_gap=%d longest=%.2f" % [wires.size(), streetlight_ids.size(), min_gap, longest])
    game.queue_free()
    await process_frame
    _finish()

func _streetlight_emitters(lighting: UtilityPoweredLightingSourceAdapter) -> Dictionary:
    var result: Dictionary = {}
    for emitter: LightEmitter in lighting.emitters():
        var id: String = String(emitter.emitter_id)
        if id.begins_with("utility.light:power.physical.road.") and emitter.profile != null:
            result[id] = true
    return result

func _check(ok: bool, message: String) -> void:
    if ok:
        return
    _failures += 1
    push_error("PROMPT_STREETLIGHT_SPACING_NIGHT: %s" % message)

func _finish() -> void:
    if _failures == 0:
        print("PROMPT_STREETLIGHT_SPACING_NIGHT_SMOKE: PASS")
    quit(0 if _failures == 0 else 1)
