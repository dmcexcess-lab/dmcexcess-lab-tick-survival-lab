extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

const TARGET_TICK: int = 2000
const MAX_ACTION_ATTEMPTS: int = 1200
const MAX_SETTLE_FRAMES: int = 240
const MAX_STARTUP_FRAMES: int = 1400
const REGION_SIZE: int = 128

var failures: Array[String] = []
var _player_finish_seen: bool = false
var _player_finish_usec: int = 0
var _player_finish_tick: int = -1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _check(packed != null, "production main scene loads")
    if packed == null:
        _finish({})
        return

    var title: Node = packed.instantiate()
    root.add_child(title)
    current_scene = title
    await process_frame
    var new_game: Button = _find_button(title, "NEW GAME")
    _check(new_game != null, "production NEW GAME button exists")
    if new_game == null:
        _finish({})
        return
    new_game.pressed.emit()

    var gameplay: Node = null
    var controller: PlayerActionController = null
    var world: WorldState = null
    var kernel: TickKernel = null
    var hud: CanonicalStatusHud = null
    var status: ActorStatusSummaryQuery = null
    var infected: ActiveInfectedCohortService = null
    var survivors: ActiveSurvivorCohortService = null
    var startup_frames: int = 0

    while startup_frames < MAX_STARTUP_FRAMES:
        startup_frames += 1
        await process_frame
        var candidate: Node = current_scene
        if candidate == null or candidate == title or candidate.scene_file_path != "res://gameplay.tscn":
            continue
        gameplay = candidate
        controller = gameplay.get("_controller") as PlayerActionController
        world = gameplay.get("_world") as WorldState
        kernel = gameplay.get("_kernel") as TickKernel
        hud = gameplay.get_node_or_null("Hud") as CanonicalStatusHud
        status = gameplay.get("_status_summary") as ActorStatusSummaryQuery
        if gameplay.has_method("infected_cohort_service"):
            infected = gameplay.call("infected_cohort_service") as ActiveInfectedCohortService
        if gameplay.has_method("survivor_cohort_service"):
            survivors = gameplay.call("survivor_cohort_service") as ActiveSurvivorCohortService
        if controller != null and controller.is_ready() and world != null and kernel != null \
            and hud != null and hud.is_configured() and status != null \
            and infected != null and infected.is_configured() \
            and survivors != null and survivors.is_configured():
            break

    _check(gameplay != null, "production gameplay scene boots")
    _check(controller != null and controller.is_ready(), "production player controller is ready")
    _check(world != null and kernel != null, "production world and WHEN are ready")
    _check(hud != null and hud.is_configured() and status != null, "production status HUD is live")
    _check(infected != null and infected.is_configured(), "production infected cohort is live")
    _check(survivors != null and survivors.is_configured(), "production survivor cohort is live")
    if gameplay == null or controller == null or world == null or kernel == null or hud == null or status == null \
        or infected == null or survivors == null:
        _finish({"startup_frames": startup_frames})
        return

    kernel.action_finished.connect(_on_kernel_action_finished)
    PerformanceTelemetry.reset()

    var start_placement: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    _check(start_placement != null, "player placement exists")
    if start_placement == null:
        _finish({"startup_frames": startup_frames})
        return

    var start_tick: int = kernel.world_tick()
    var start_anchor: Vector2i = start_placement.anchor
    var unique_cells: Dictionary = {start_anchor: true}
    var attempts: int = 0
    var accepted: int = 0
    var rejected: int = 0
    var successful_moves: int = 0
    var turns: int = 0
    var blocked: int = 0
    var next_intent: StringName = Intents.FORWARD
    var pending_planned_turn: bool = false
    var planned_turn_done: bool = false

    var action_total_usec: Array[int] = []
    var submit_usec_values: Array[int] = []
    var ready_tail_usec_values: Array[int] = []
    var max_frame_usec_values: Array[int] = []
    var settle_frame_values: Array[int] = []
    var status_query_usec_values: Array[int] = []
    var hud_refresh_usec_values: Array[int] = []
    var eval_delta_values: Array[int] = []
    var npc_submission_delta_values: Array[int] = []
    var per_action: Array[Dictionary] = []
    var wall_start_usec: int = Time.get_ticks_usec()

    while kernel.world_tick() < TARGET_TICK and attempts < MAX_ACTION_ATTEMPTS:
        attempts += 1
        var prewait: int = 0
        while prewait < MAX_SETTLE_FRAMES and (controller.is_busy() or not kernel.is_decision_paused()):
            prewait += 1
            await process_frame
        if controller.is_busy() or not kernel.is_decision_paused():
            failures.append("controller failed to reach decision pause before attempt %d" % attempts)
            break

        var before: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if before == null:
            failures.append("player placement disappeared before attempt %d" % attempts)
            break

        if successful_moves >= 155 and not planned_turn_done and not pending_planned_turn:
            next_intent = Intents.TURN_RIGHT
            pending_planned_turn = true

        var tick_before: int = kernel.world_tick()
        var submitted_intent: StringName = next_intent
        var infected_before: Dictionary = infected.metrics_snapshot()
        var survivors_before: Dictionary = survivors.metrics_snapshot()
        var active_infected: int = int(infected_before.get("active_actor_count", 0))
        var active_survivors: int = int(survivors_before.get("active_actor_count", 0))
        var eval_before: int = int(infected_before.get("behavior_evaluation_count", 0)) + int(survivors_before.get("behavior_evaluation_count", 0))
        var npc_submit_before: int = int(infected_before.get("ordinary_action_submission_count", 0)) + int(survivors_before.get("ordinary_action_submission_count", 0))

        _player_finish_seen = false
        _player_finish_usec = 0
        _player_finish_tick = -1
        var action_start_usec: int = Time.get_ticks_usec()
        var submit_start_usec: int = action_start_usec
        controller.submit_intent(submitted_intent)
        var submit_usec: int = Time.get_ticks_usec() - submit_start_usec

        if not controller.is_busy():
            rejected += 1
            if submitted_intent in [Intents.FORWARD, Intents.BACKWARD]:
                blocked += 1
                next_intent = Intents.TURN_RIGHT
            else:
                next_intent = Intents.FORWARD
            await process_frame
            continue

        accepted += 1
        var active_actions_after_submit: int = kernel.active_action_count()
        var settle_frames: int = 0
        var max_frame_usec: int = 0
        while settle_frames < MAX_SETTLE_FRAMES and controller.is_busy():
            var frame_start_usec: int = Time.get_ticks_usec()
            await process_frame
            var frame_usec: int = Time.get_ticks_usec() - frame_start_usec
            max_frame_usec = maxi(max_frame_usec, frame_usec)
            settle_frames += 1
        if controller.is_busy():
            failures.append("accepted action %d remained busy after %d rendered batches" % [attempts, MAX_SETTLE_FRAMES])
            break

        var action_end_usec: int = Time.get_ticks_usec()
        var total_usec: int = action_end_usec - action_start_usec
        var ready_tail_usec: int = 0
        if _player_finish_seen:
            ready_tail_usec = maxi(action_end_usec - _player_finish_usec, 0)

        var after: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if after == null:
            failures.append("player placement disappeared after attempt %d" % attempts)
            break
        unique_cells[after.anchor] = true

        if submitted_intent in [Intents.FORWARD, Intents.BACKWARD]:
            if after.anchor != before.anchor:
                successful_moves += 1
                next_intent = Intents.FORWARD
            else:
                blocked += 1
                next_intent = Intents.TURN_RIGHT
        elif submitted_intent in [Intents.TURN_LEFT, Intents.TURN_RIGHT]:
            turns += 1
            next_intent = Intents.FORWARD
            if pending_planned_turn:
                pending_planned_turn = false
                planned_turn_done = true

        if kernel.world_tick() <= tick_before:
            failures.append("accepted action %d did not advance authoritative WHEN" % attempts)
            break

        var infected_after: Dictionary = infected.metrics_snapshot()
        var survivors_after: Dictionary = survivors.metrics_snapshot()
        var eval_after: int = int(infected_after.get("behavior_evaluation_count", 0)) + int(survivors_after.get("behavior_evaluation_count", 0))
        var npc_submit_after: int = int(infected_after.get("ordinary_action_submission_count", 0)) + int(survivors_after.get("ordinary_action_submission_count", 0))
        var eval_delta: int = maxi(eval_after - eval_before, 0)
        var npc_submit_delta: int = maxi(npc_submit_after - npc_submit_before, 0)

        var status_start_usec: int = Time.get_ticks_usec()
        var status_snapshot: Dictionary = status.query(Fixture.PLAYER_ID)
        var status_usec: int = Time.get_ticks_usec() - status_start_usec
        var moodlet_count: int = (status_snapshot.get("moodlet_descriptors", []) as Array).size()

        var hud_usec: int = -1
        if accepted % 10 == 0:
            var hud_start_usec: int = Time.get_ticks_usec()
            hud.refresh()
            hud_usec = Time.get_ticks_usec() - hud_start_usec
            hud_refresh_usec_values.append(hud_usec)

        action_total_usec.append(total_usec)
        submit_usec_values.append(submit_usec)
        ready_tail_usec_values.append(ready_tail_usec)
        max_frame_usec_values.append(max_frame_usec)
        settle_frame_values.append(settle_frames)
        status_query_usec_values.append(status_usec)
        eval_delta_values.append(eval_delta)
        npc_submission_delta_values.append(npc_submit_delta)

        var sample := {
            "index": accepted,
            "tick_before": tick_before,
            "tick_after": kernel.world_tick(),
            "intent": String(submitted_intent),
            "anchor": [after.anchor.x, after.anchor.y],
            "region": _region_for(after.anchor),
            "active_infected": active_infected,
            "active_survivors": active_survivors,
            "active_npcs": active_infected + active_survivors,
            "active_actions_after_submit": active_actions_after_submit,
            "npc_evaluations": eval_delta,
            "npc_submissions": npc_submit_delta,
            "settle_frames": settle_frames,
            "submit_usec": submit_usec,
            "total_usec": total_usec,
            "ready_tail_usec": ready_tail_usec,
            "max_frame_usec": max_frame_usec,
            "status_query_usec": status_usec,
            "hud_refresh_usec": hud_usec,
            "moodlets": moodlet_count,
        }
        per_action.append(sample)

        if total_usec >= 500000 or submit_usec >= 100000 or max_frame_usec >= 100000:
            print("PROMPT_TICK_2000_SLOW %s" % JSON.stringify(sample))

    var wall_usec: int = Time.get_ticks_usec() - wall_start_usec
    var final_placement: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    var final_tick: int = kernel.world_tick()
    _check(final_tick >= TARGET_TICK, "authoritative WHEN reaches tick 2000")
    _check(final_placement != null, "player placement survives through tick 2000")

    var final_status_start: int = Time.get_ticks_usec()
    var final_status: Dictionary = status.query(Fixture.PLAYER_ID)
    var final_status_usec: int = Time.get_ticks_usec() - final_status_start
    var infected_final: Dictionary = infected.metrics_snapshot()
    var survivors_final: Dictionary = survivors.metrics_snapshot()

    var summary := {
        "startup_frames": startup_frames,
        "start_tick": start_tick,
        "final_tick": final_tick,
        "attempts": attempts,
        "accepted_actions": accepted,
        "rejected_actions": rejected,
        "successful_moves": successful_moves,
        "turns": turns,
        "blocked_moves": blocked,
        "unique_cells": unique_cells.size(),
        "start_anchor": [start_anchor.x, start_anchor.y],
        "end_anchor": [final_placement.anchor.x, final_placement.anchor.y] if final_placement != null else [0, 0],
        "wall_usec": wall_usec,
        "action_total_p50_usec": _percentile(action_total_usec, 0.50),
        "action_total_p95_usec": _percentile(action_total_usec, 0.95),
        "action_total_p99_usec": _percentile(action_total_usec, 0.99),
        "action_total_max_usec": _max_value(action_total_usec),
        "submit_p50_usec": _percentile(submit_usec_values, 0.50),
        "submit_p95_usec": _percentile(submit_usec_values, 0.95),
        "submit_max_usec": _max_value(submit_usec_values),
        "ready_tail_p50_usec": _percentile(ready_tail_usec_values, 0.50),
        "ready_tail_p95_usec": _percentile(ready_tail_usec_values, 0.95),
        "ready_tail_max_usec": _max_value(ready_tail_usec_values),
        "max_frame_p50_usec": _percentile(max_frame_usec_values, 0.50),
        "max_frame_p95_usec": _percentile(max_frame_usec_values, 0.95),
        "max_frame_max_usec": _max_value(max_frame_usec_values),
        "settle_frames_p50": _percentile(settle_frame_values, 0.50),
        "settle_frames_p95": _percentile(settle_frame_values, 0.95),
        "settle_frames_max": _max_value(settle_frame_values),
        "status_query_p50_usec": _percentile(status_query_usec_values, 0.50),
        "status_query_p95_usec": _percentile(status_query_usec_values, 0.95),
        "status_query_max_usec": _max_value(status_query_usec_values),
        "hud_refresh_p50_usec": _percentile(hud_refresh_usec_values, 0.50),
        "hud_refresh_p95_usec": _percentile(hud_refresh_usec_values, 0.95),
        "hud_refresh_max_usec": _max_value(hud_refresh_usec_values),
        "npc_eval_delta_p50": _percentile(eval_delta_values, 0.50),
        "npc_eval_delta_p95": _percentile(eval_delta_values, 0.95),
        "npc_submit_delta_p50": _percentile(npc_submission_delta_values, 0.50),
        "npc_submit_delta_p95": _percentile(npc_submission_delta_values, 0.95),
        "final_status_query_usec": final_status_usec,
        "final_moodlet_count": (final_status.get("moodlet_descriptors", []) as Array).size(),
        "infected_final": infected_final,
        "survivors_final": survivors_final,
        "active_npc_buckets": _bucket_by_active_npcs(per_action),
        "tick_phases": _bucket_by_tick_phase(per_action),
        "slowest_actions": _slowest(per_action, 12),
        "telemetry": PerformanceTelemetry.snapshot(),
    }
    _finish(summary)

func _on_kernel_action_finished(action: TimedAction) -> void:
    if action == null or action.actor_id != Fixture.PLAYER_ID:
        return
    _player_finish_seen = true
    _player_finish_usec = Time.get_ticks_usec()
    _player_finish_tick = action.end_tick()

func _region_for(cell: Vector2i) -> Array[int]:
    return [floori(float(cell.x) / float(REGION_SIZE)), floori(float(cell.y) / float(REGION_SIZE))]

func _bucket_by_active_npcs(samples: Array[Dictionary]) -> Dictionary:
    var buckets: Dictionary = {}
    for sample: Dictionary in samples:
        var key: String = str(int(sample.get("active_npcs", 0)))
        if not buckets.has(key):
            buckets[key] = {"count": 0, "total": [], "submit": [], "frames": [], "eval": []}
        var bucket: Dictionary = buckets[key]
        bucket["count"] = int(bucket.get("count", 0)) + 1
        (bucket["total"] as Array).append(int(sample.get("total_usec", 0)))
        (bucket["submit"] as Array).append(int(sample.get("submit_usec", 0)))
        (bucket["frames"] as Array).append(int(sample.get("settle_frames", 0)))
        (bucket["eval"] as Array).append(int(sample.get("npc_evaluations", 0)))
        buckets[key] = bucket
    var result: Dictionary = {}
    for key: Variant in buckets.keys():
        var bucket: Dictionary = buckets[key]
        result[key] = {
            "count": int(bucket.get("count", 0)),
            "total_p50_usec": _percentile_variant(bucket.get("total", []), 0.50),
            "total_p95_usec": _percentile_variant(bucket.get("total", []), 0.95),
            "submit_p50_usec": _percentile_variant(bucket.get("submit", []), 0.50),
            "submit_p95_usec": _percentile_variant(bucket.get("submit", []), 0.95),
            "settle_frames_p50": _percentile_variant(bucket.get("frames", []), 0.50),
            "eval_p50": _percentile_variant(bucket.get("eval", []), 0.50),
        }
    return result

func _bucket_by_tick_phase(samples: Array[Dictionary]) -> Dictionary:
    var ranges := {
        "0_499": [0, 499],
        "500_999": [500, 999],
        "1000_1499": [1000, 1499],
        "1500_2000": [1500, 2000],
    }
    var result: Dictionary = {}
    for label: Variant in ranges.keys():
        var bounds: Array = ranges[label]
        var total: Array[int] = []
        var submit: Array[int] = []
        var frames: Array[int] = []
        var actors: Array[int] = []
        for sample: Dictionary in samples:
            var tick: int = int(sample.get("tick_before", 0))
            if tick < int(bounds[0]) or tick > int(bounds[1]):
                continue
            total.append(int(sample.get("total_usec", 0)))
            submit.append(int(sample.get("submit_usec", 0)))
            frames.append(int(sample.get("settle_frames", 0)))
            actors.append(int(sample.get("active_npcs", 0)))
        result[label] = {
            "count": total.size(),
            "total_p50_usec": _percentile(total, 0.50),
            "total_p95_usec": _percentile(total, 0.95),
            "submit_p50_usec": _percentile(submit, 0.50),
            "settle_frames_p50": _percentile(frames, 0.50),
            "active_npcs_p50": _percentile(actors, 0.50),
        }
    return result

func _slowest(samples: Array[Dictionary], limit: int) -> Array[Dictionary]:
    var copy: Array[Dictionary] = []
    for sample: Dictionary in samples:
        copy.append(sample.duplicate(true))
    copy.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("total_usec", 0)) > int(b.get("total_usec", 0)))
    var result: Array[Dictionary] = []
    for index: int in range(mini(limit, copy.size())):
        result.append(copy[index])
    return result

func _percentile(values: Array[int], percentile: float) -> int:
    if values.is_empty():
        return 0
    var sorted_values: Array[int] = values.duplicate()
    sorted_values.sort()
    var index: int = clampi(int(ceil(float(sorted_values.size()) * percentile)) - 1, 0, sorted_values.size() - 1)
    return sorted_values[index]

func _percentile_variant(values: Variant, percentile: float) -> int:
    if typeof(values) != TYPE_ARRAY:
        return 0
    var typed: Array[int] = []
    for value: Variant in values:
        typed.append(int(value))
    return _percentile(typed, percentile)

func _max_value(values: Array[int]) -> int:
    var result: int = 0
    for value: int in values:
        result = maxi(result, value)
    return result

func _find_button(node: Node, text_value: String) -> Button:
    var button := node as Button
    if button != null and button.text == text_value:
        return button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, text_value)
        if found != null:
            return found
    return null

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish(metrics: Dictionary) -> void:
    print("PROMPT_TICK_2000_RESULT %s" % JSON.stringify(metrics))
    if failures.is_empty():
        print("PROMPT_TICK_2000_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_TICK_2000_FAIL: %s" % failure)
    quit(1)
