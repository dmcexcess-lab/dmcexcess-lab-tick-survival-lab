extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)

func street_count(lighting: Variant) -> int:
    var count: int = 0
    for emitter: Variant in lighting.emitters():
        if String(emitter.emitter_id).begins_with("utility.light:power.physical.road."):
            count += 1
    return count

func _run() -> void:
    var game: Node = load("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    var world: Variant = game.get("_world")
    var infrastructure: Variant = game.get("_power_infrastructure")
    var lighting: Variant = game.get("_utility_lighting")
    check(infrastructure != null and infrastructure.is_ready(), "production infrastructure ready")
    check(lighting != null and lighting.is_ready(), "production lighting ready")
    if lighting == null or infrastructure == null:
        quit(1)
        return
    check(street_count(lighting) == 0, "daytime streetlights off")
    var kernel: Variant = game.get("_kernel")
    var time: Variant = game.get("_world_time")
    var profile: Variant = time.profile()
    for second: int in [73800, 86399, 0, 19799, 19800, 43200, 73799, 73800]:
        var elapsed: int = posmod(second - profile.start_second_of_day, 86400)
        kernel.set("_world_tick", elapsed * profile.ticks_per_second)
        kernel.timing_state_reset.emit()
        var night: bool = second < 19800 or second >= 73800
        check((street_count(lighting) > 0) == night, "streetlight cycle at %d" % second)
    var utilities: Variant = game.get("_utilities")
    check(utilities.set_power_component_state(utilities.power_source_component_id(), &"DISABLED"), "disable source")
    check(street_count(lighting) == 0, "night outage extinguishes lights")
    check(utilities.set_power_component_state(utilities.power_source_component_id(), &"OPERATIONAL"), "restore source")
    check(street_count(lighting) > 0, "night restoration relights lights")
    var segments: Array = []
    var seen: Dictionary = {}
    var count: int = world.entity_ids_of_type(&"prop.streetlight").size()
    print("STREETLIGHT_COUNT: ", count)
    check(count > 0 and count < 1048, "shared cadence reduces excess poles/lights")
    for edge: Dictionary in infrastructure.wire_edges():
        var a: Variant = world.placement(edge["start_id"])
        var b: Variant = world.placement(edge["end_id"])
        check(a != null and b != null, "wire endpoints exist")
        if a != null and b != null:
            var ids: Array = [edge["start_id"], edge["end_id"]]
            ids.sort()
            var key: String = str(ids)
            check(not seen.has(key), "no duplicate physical spans")
            seen[key] = true
            var av: Vector2 = Vector2(a.anchor)
            var bv: Vector2 = Vector2(b.anchor)
            for segment: Array in segments:
                if av == segment[0] or av == segment[1] or bv == segment[0] or bv == segment[1]:
                    continue
                var intersection: Variant = Geometry2D.segment_intersects_segment(av, bv, segment[0], segment[1])
                if intersection != null:
                    var supported: bool = false
                    for endpoint: Vector2 in [av, bv, segment[0], segment[1]]:
                        supported = supported or endpoint.is_equal_approx(intersection)
                    check(supported, "no unsupported X crossing")
            segments.append([av, bv])
            check(Vector2(a.anchor).distance_to(Vector2(b.anchor)) <= 16.001, "wire max length preserved")
    game.queue_free()
    await process_frame
    print("PROMPT_STREETLIGHT_CYCLE_SMOKE: PASS" if failures == 0 else "PROMPT_STREETLIGHT_CYCLE_SMOKE: FAIL")
    quit(0 if failures == 0 else 1)
