extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const TARGET_TICK: int = 1000
const MAX_ACTION_ATTEMPTS: int = 4000
const MAX_SETTLE_FRAMES: int = 240
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

    var main: Node = packed.instantiate()
    root.add_child(main)
    current_scene = main
    await process_frame

    var controller: PlayerActionController = _find_controller(main)
    var world: WorldState = main.get("_world") as WorldState
    var kernel: TickKernel = main.get("_kernel") as TickKernel
    var perception: ObserverPerceptionService = main.get("_perception") as ObserverPerceptionService
    var world_view: TacticalRendererStack = main.get("_world_view") as TacticalRendererStack
    _check(controller != null, "production PlayerActionController exists")
    _check(world != null, "production WorldState exists")
    _check(kernel != null, "production TickKernel exists")
    _check(perception != null, "production perception exists")
    _check(world_view != null, "production renderer exists")
    if controller == null or world == null or kernel == null or perception == null or world_view == null:
        _finish({})
        return

    var initial: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    _check(initial != null, "player placement exists at playtest start")
    if initial == null:
        _finish({})
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
        var action_start_usec: int = Time.get_ticks_usec()
        controller.submit_intent(next_intent)

        if not controller.is_busy():
            rejected_actions += 1
            if next_intent == Intents.FORWARD:
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

        if next_intent == Intents.FORWARD:
            if after.anchor != before.anchor:
                moves += 1
                consecutive_blocked = 0
                next_intent = Intents.FORWARD
            else:
                blocked_moves += 1
                consecutive_blocked += 1
                next_intent = Intents.TURN_RIGHT
        elif next_intent == Intents.TURN_RIGHT:
            turns += 1
            next_intent = Intents.FORWARD

        if kernel.world_tick() <= tick_before:
            failures.append("accepted action %d did not advance authoritative WHEN" % attempts)
            break

        # If the local geometry traps the simple explorer, deliberately vary the
        # action rather than manufacturing progress by directly advancing WHEN.
        if consecutive_blocked >= 4:
            next_intent = Intents.BACKWARD
            consecutive_blocked = 0
        elif next_intent == Intents.BACKWARD:
            next_intent = Intents.TURN_LEFT

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
    _check(bool(final_light_view.get("multiply_texture_ready", false)), "multiply lighting texture remains ready")
    _check(bool(final_light_view.get("glow_texture_ready", false)), "glow lighting texture remains ready")
    _check(float(final_light_view.get("max_luminance", 0.0)) > 0.001, "lighting remains nonblack at tick 1000")

    var end_anchor: Vector2i = start_anchor if final_placement == null else final_placement.anchor
    var metrics: Dictionary = {
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
