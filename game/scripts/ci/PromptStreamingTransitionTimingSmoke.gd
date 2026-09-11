extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")
const ACTION_COUNT: int = 100
const MAX_STARTUP_FRAMES: int = 1200
const MAX_SETTLE_FRAMES: int = 240

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _check(packed != null, "production title scene loads")
    if packed == null:
        _finish([])
        return

    var title: Node = packed.instantiate()
    root.add_child(title)
    current_scene = title
    await process_frame
    var new_game: Button = _find_button(title, "NEW GAME")
    _check(new_game != null, "production NEW GAME button exists")
    if new_game == null:
        _finish([])
        return
    new_game.pressed.emit()

    var gameplay: Node = null
    var controller: PlayerActionController = null
    var world: WorldState = null
    var kernel: TickKernel = null
    for _frame: int in range(MAX_STARTUP_FRAMES):
        await process_frame
        var candidate: Node = current_scene
        if candidate == null or candidate.scene_file_path != "res://gameplay.tscn":
            continue
        gameplay = candidate
        controller = _find_controller(gameplay)
        world = gameplay.get("_world") as WorldState
        kernel = gameplay.get("_kernel") as TickKernel
        if controller != null and controller.is_ready() and world != null and kernel != null:
            break

    var streaming: WorldStreamingCoordinator = Fixture.streaming_coordinator()
    _check(gameplay != null and controller != null and controller.is_ready(), "production gameplay action controller is ready")
    _check(world != null and kernel != null, "authoritative world and WHEN are ready")
    _check(streaming != null and streaming.is_ready() and streaming.has_focus(), "production streaming coordinator is ready")
    if gameplay == null or controller == null or not controller.is_ready() or world == null or kernel == null or streaming == null or not streaming.is_ready():
        _finish([])
        return

    var records: Array[Dictionary] = []
    var initial_region: Vector2i = streaming.focus_region_coord()
    var transitions: int = 0

    for action_index: int in range(1, ACTION_COUNT + 1):
        if controller.is_busy() or not kernel.is_decision_paused():
            failures.append("controller not ready before action %d" % action_index)
            break
        var before: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if before == null:
            failures.append("player placement missing before action %d" % action_index)
            break
        var tick_before: int = kernel.world_tick()
        var region_before: Vector2i = streaming.focus_region_coord()
        PerformanceTelemetry.reset()
        var started_usec: int = Time.get_ticks_usec()
        controller.submit_intent(Intents.FORWARD)
        if not controller.is_busy():
            failures.append("forward action %d was rejected" % action_index)
            break

        var settle_frames: int = 0
        while controller.is_busy() and settle_frames < MAX_SETTLE_FRAMES:
            settle_frames += 1
            await process_frame
        var action_usec: int = Time.get_ticks_usec() - started_usec
        if controller.is_busy():
            failures.append("action %d did not settle" % action_index)
            break

        var after: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if after == null:
            failures.append("player placement missing after action %d" % action_index)
            break
        var region_after: Vector2i = streaming.focus_region_coord()
        var crossed: bool = region_after != region_before
        if crossed:
            transitions += 1
        var telemetry: Dictionary = PerformanceTelemetry.snapshot()
        var timings: Dictionary = telemetry.get("timings", {})
        var values: Dictionary = telemetry.get("values", {})
        var record: Dictionary = {
            "action": action_index,
            "tick_before": tick_before,
            "tick_after": kernel.world_tick(),
            "anchor_before": [before.anchor.x, before.anchor.y],
            "anchor_after": [after.anchor.x, after.anchor.y],
            "region_before": [region_before.x, region_before.y],
            "region_after": [region_after.x, region_after.y],
            "crossed_region": crossed,
            "settle_frames": settle_frames,
            "action_usec": action_usec,
            "stream_update_usec": _last_timing(timings, "stream_update"),
            "source_discovery_usec": _total_timing(timings, "stream_source_discovery"),
            "plan_prepare_usec": _total_timing(timings, "stream_plan_prepare"),
            "catalog_validation_usec": _total_timing(timings, "stream_catalog_validation"),
            "world_snapshot_usec": _total_timing(timings, "stream_world_snapshot"),
            "materialization_commit_usec": _total_timing(timings, "stream_materialization_commit"),
            "lookahead_generated": int(values.get("stream_prepare_generated_last", 0)),
            "entering_regions": int(values.get("stream_entering_regions", 0)),
            "last_sources": int(values.get("stream_last_sources", 0)),
        }
        records.append(record)
        print("PROMPT_STREAM_ACTION %s" % JSON.stringify(record))
        _check(after.anchor != before.anchor, "forward action %d moves the player" % action_index)
        _check(kernel.world_tick() > tick_before, "forward action %d advances WHEN" % action_index)

    _check(records.size() == ACTION_COUNT, "all %d timing actions complete" % ACTION_COUNT)
    _check(transitions >= 1, "route crosses at least one streaming-region boundary")
    _check(streaming.focus_region_coord() != initial_region, "streaming focus follows the crossed boundary")
    _finish(records)

func _find_button(node: Node, text_value: String) -> Button:
    var button := node as Button
    if button != null and button.text == text_value:
        return button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, text_value)
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

func _last_timing(timings: Dictionary, key: String) -> int:
    var entry: Dictionary = timings.get(key, {})
    return int(entry.get("last_usec", 0))

func _total_timing(timings: Dictionary, key: String) -> int:
    var entry: Dictionary = timings.get(key, {})
    return int(entry.get("total_usec", 0))

func _finish(records: Array[Dictionary]) -> void:
    var max_action_usec: int = 0
    var max_record: Dictionary = {}
    for record: Dictionary in records:
        var duration: int = int(record.get("action_usec", 0))
        if duration > max_action_usec:
            max_action_usec = duration
            max_record = record
    print("PROMPT_STREAM_TIMING_RESULT %s" % JSON.stringify({
        "actions": records.size(),
        "max_action_usec": max_action_usec,
        "max_action": int(max_record.get("action", 0)),
        "max_action_crossed_region": bool(max_record.get("crossed_region", false)),
    }))
    if failures.is_empty():
        print("PROMPT_STREAMING_TRANSITION_TIMING_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_STREAMING_TRANSITION_TIMING_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
