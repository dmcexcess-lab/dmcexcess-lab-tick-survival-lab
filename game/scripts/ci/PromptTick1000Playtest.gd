extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const TARGET_TICK: int = 1000
const MAX_ACTION_ATTEMPTS: int = 4000
const MAX_SETTLE_FRAMES: int = 240
const MAX_STARTUP_FRAMES: int = 1200
const LONG_ACTION_USEC: int = 100000
const VERY_LONG_ACTION_USEC: int = 500000

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _check(packed != null, "production main scene loads")
    if packed == null:
        _finish({})
        return

    var startup: Node = packed.instantiate()
    root.add_child(startup)
    current_scene = startup
    await process_frame

    var new_game: Button = _find_button(startup, "NEW GAME")
    _check(new_game != null, "production NEW GAME button exists")
    if new_game == null:
        _finish({})
        return
    new_game.emit_signal("pressed")

    var gameplay: Node = null
    var controller: PlayerActionController = null
    var world: WorldState = null
    var kernel: TickKernel = null
    var perception: ObserverPerceptionService = null
    var world_view: TacticalRendererStack = null
    var startup_frames: int = 0
    while startup_frames < MAX_STARTUP_FRAMES:
        startup_frames += 1
        await process_frame
        var candidate: Node = current_scene
        if candidate == null or candidate == startup or candidate.scene_file_path != "res://gameplay.tscn":
            continue
        gameplay = candidate
        controller = _find_controller(gameplay)
        world = gameplay.get("_world") as WorldState
        kernel = gameplay.get("_kernel") as TickKernel
        perception = gameplay.get("_perception") as ObserverPerceptionService
        world_view = gameplay.get("_world_view") as TacticalRendererStack
        if controller != null and controller.is_ready() and world != null and kernel != null and perception != null and world_view != null:
            break

    _check(gameplay != null, "NEW GAME transitions to production gameplay scene")
    _check(controller != null and controller.is_ready() and world != null and kernel != null and perception != null and world_view != null, "production gameplay boot completes")
    if gameplay == null or controller == null or not controller.is_ready() or world == null or kernel == null or perception == null or world_view == null:
        _finish({"startup_frames": startup_frames})
        return

    var initial: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    _check(initial != null, "player placement exists at playtest start")
    if initial == null:
        _finish({"startup_frames": startup_frames})
        return

    var start_tick: int = kernel.world_tick()
    var start_anchor: Vector2i = initial.anchor
    var min_anchor: Vector2i = start_anchor
    var max_anchor: Vector2i = start_anchor
    var unique_cells: Dictionary = {start_anchor: true}
    var durations_usec: Array[int] = []
    var attempts: int = 0
    var accepted_actions: int = 0
    var rejected_actions: int = 0
    var moves: int = 0
    var blocked_moves: int = 0
    var turns: int = 0
    var long_actions: int = 0
    var very_long_actions: int = 0
    var max_settle_frames: int = 0
    var stalled_actions: int = 0
    var next_intent: StringName = Intents.FORWARD
    var consecutive_blocked: int = 0
    var wall_start_usec: int = Time.get_ticks_usec()

    while kernel.world_tick() < TARGET_TICK and attempts < MAX_ACTION_ATTEMPTS:
        attempts += 1
        if controller.is_busy() or not kernel.is_decision_paused():
            var prewait_frames: int = 0
            while prewait_frames < MAX_SETTLE_FRAMES and (controller.is_busy() or not kernel.is_decision_paused()):
                prewait_frames += 1
                await process_frame
            if controller.is_busy() or not kernel.is_decision_paused():
                stalled_actions += 1
                failures.append("controller failed to return to decision pause before action %d" % attempts)
                break

        var before: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if before == null:
            failures.append("player placement disappeared before action %d" % attempts)
            break
        var tick_before: int = kernel.world_tick()
        var submitted_intent: StringName = next_intent
        var action_start_usec: int = Time.get_ticks_usec()
        controller.submit_intent(submitted_intent)

        if not controller.is_busy():
            rejected_actions += 1
            if submitted_intent == Intents.FORWARD or submitted_intent == Intents.BACKWARD:
                blocked_moves += 1
                consecutive_blocked += 1
                next_intent = Intents.TURN_RIGHT
            else:
                next_intent = Intents.FORWARD
            await process_frame
            continue

        accepted_actions += 1
        var settle_frames: int = 0
        while settle_frames < MAX_SETTLE_FRAMES and controller.is_busy():
            settle_frames += 1
            await process_frame
        max_settle_frames = maxi(max_settle_frames, settle_frames)
        if controller.is_busy():
            stalled_actions += 1
            failures.append("accepted action %d remained busy after %d frames" % [attempts, MAX_SETTLE_FRAMES])
            break

        var duration_usec: int = Time.get_ticks_usec() - action_start_usec
        durations_usec.append(duration_usec)
        if duration_usec >= LONG_ACTION_USEC:
            long_actions += 1
        if duration_usec >= VERY_LONG_ACTION_USEC:
            very_long_actions += 1

        var after: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if after == null:
            failures.append("player placement disappeared after action %d" % attempts)
            break
        min_anchor.x = mini(min_anchor.x, after.anchor.x)
        min_anchor.y = mini(min_anchor.y, after.anchor.y)
        max_anchor.x = maxi(max_anchor.x, after.anchor.x)
        max_anchor.y = maxi(max_anchor.y, after.anchor.y)
        unique_cells[after.anchor] = true

        if submitted_intent == Intents.FORWARD or submitted_intent == Intents.BACKWARD:
            if after.anchor != before.anchor:
                moves += 1
                consecutive_blocked = 0
                next_intent = Intents.FORWARD
            else:
                blocked_moves += 1
                consecutive_blocked += 1
                next_intent = Intents.TURN_RIGHT
        elif submitted_intent == Intents.TURN_RIGHT or submitted_intent == Intents.TURN_LEFT:
            turns += 1
            next_intent = Intents.FORWARD

        if kernel.world_tick() <= tick_before:
            failures.append("accepted action %d did not advance authoritative WHEN" % attempts)
            break

        if consecutive_blocked >= 4:
            next_intent = Intents.BACKWARD
            consecutive_blocked = 0

    var wall_usec: int = Time.get_ticks_usec() - wall_start_usec
    var final_placement: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    var final_tick: int = kernel.world_tick()
    _check(final_tick >= TARGET_TICK, "authoritative WHEN reaches tick 1000")
    _check(final_placement != null, "player placement survives through tick 1000")
    _check(stalled_actions == 0, "no player action stalls permanently")

    var final_perception: Dictionary = world_view.perception_debug_snapshot()
    var final_light_view: Dictionary = world_view.physical_lighting_debug_snapshot()
    if final_placement != null:
        _check(perception.is_visible(final_placement.anchor), "player remains visible at tick 1000")
    _check(int(final_perception.get("visible", 0)) > 1, "visible field remains populated at tick 1000")
    _check(final_light_view.get("multiply_texture_ready", false) == true, "multiply lighting texture remains ready")
    _check(final_light_view.get("glow_texture_ready", false) == true, "glow lighting texture remains ready")
    _check(float(final_light_view.get("max_luminance", 0.0)) > 0.001, "lighting remains nonblack at tick 1000")

    var end_anchor: Vector2i = start_anchor if final_placement == null else final_placement.anchor
    var metrics: Dictionary = {
        "startup_frames": startup_frames,
        "start_tick": start_tick,
        "final_tick": final_tick,
        "attempts": attempts,
        "accepted_actions": accepted_actions,
        "rejected_actions": rejected_actions,
        "moves": moves,
        "blocked_moves": blocked_moves,
        "turns": turns,
        "unique_cells": unique_cells.size(),
        "start_anchor": [start_anchor.x, start_anchor.y],
        "end_anchor": [end_anchor.x, end_anchor.y],
        "min_anchor": [min_anchor.x, min_anchor.y],
        "max_anchor": [max_anchor.x, max_anchor.y],
        "wall_usec": wall_usec,
        "p50_action_usec": _percentile(durations_usec, 0.50),
        "p95_action_usec": _percentile(durations_usec, 0.95),
        "p99_action_usec": _percentile(durations_usec, 0.99),
        "max_action_usec": _max_value(durations_usec),
        "long_actions_ge_100ms": long_actions,
        "very_long_actions_ge_500ms": very_long_actions,
        "max_settle_frames": max_settle_frames,
        "stalled_actions": stalled_actions,
        "visible_cells": int(final_perception.get("visible", 0)),
        "max_luminance": float(final_light_view.get("max_luminance", 0.0)),
    }
    _finish(metrics)

func _find_button(node: Node, text: String) -> Button:
    if node is Button and (node as Button).text == text:
        return node as Button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, text)
        if found != null:
            return found
    return null

func _find_controller(node: Node) -> PlayerActionController:
    if node is PlayerActionController:
        return node
    for child: Node in node.get_children():
        var found: PlayerActionController = _find_controller(child)
        if found != null:
            return found
    return null

func _percentile(values: Array[int], percentile: float) -> int:
    if values.is_empty():
        return 0
    var sorted_values: Array[int] = values.duplicate()
    sorted_values.sort()
    var index: int = clampi(int(ceil(float(sorted_values.size()) * percentile)) - 1, 0, sorted_values.size() - 1)
    return sorted_values[index]

func _max_value(values: Array[int]) -> int:
    var result: int = 0
    for value: int in values:
        result = maxi(result, value)
    return result

func _finish(metrics: Dictionary) -> void:
    print("PROMPT_TICK_1000_PLAYTEST_RESULT %s" % JSON.stringify(metrics))
    if failures.is_empty():
        print("PROMPT_TICK_1000_PLAYTEST_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_TICK_1000_PLAYTEST_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
