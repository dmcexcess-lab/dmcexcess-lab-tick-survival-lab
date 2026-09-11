extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")
const BASELINE_GROUND_COMMIT_USEC: int = 9925013
const MAX_GROUND_COMMIT_USEC: int = 3000000
const MAX_STARTUP_FRAMES: int = 1200
const MAX_SETTLE_FRAMES: int = 240
const MAX_ACTIONS_TO_BOUNDARY: int = 70

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _verify_bulk_store_semantics()
    await _verify_production_boundary()
    _finish()

func _verify_bulk_store_semantics() -> void:
    var world := WorldState.new()
    var mutations := WorldMutationService.new(world)
    var rect := Rect2i(-32, -32, 256, 256)
    var grass: StringName = &"ground.grass_lush"
    var road: StringName = &"ground.road_plain"
    _check(mutations.set_terrain_rect(rect, grass), "initial aligned terrain rectangle materializes")

    var overrides: Array[Vector2i] = [
        Vector2i(-16, -16),
        Vector2i(0, 0),
        Vector2i(17, 17),
        Vector2i(100, 100),
    ]
    _check(mutations.set_terrain_cells(overrides, road), "sparse terrain overrides materialize")
    var revision_before_restore: int = world.terrain_revision()

    PerformanceTelemetry.reset()
    _check(mutations.set_terrain_rect(rect, grass), "bulk rectangle restores sparse overrides")
    var restore_values: Dictionary = PerformanceTelemetry.snapshot().get("values", {})
    _check(world.terrain_revision() == revision_before_restore + 1, "mixed bulk restore advances terrain revision exactly once")
    for cell: Vector2i in overrides:
        _check(world.terrain_at(cell) == grass, "bulk rectangle preserves exact overwrite semantics at %s" % cell)
    _check(int(restore_values.get("terrain_bulk_rect_requested_cells", 0)) == 65536, "bulk diagnostics report the full requested rectangle")
    _check(int(restore_values.get("terrain_bulk_rect_skipped_chunks", 0)) >= 250, "bulk restore skips already-uniform chunks")
    _check(int(restore_values.get("terrain_bulk_rect_visited_cells", 65536)) <= 1536, "bulk restore avoids scalar visits across full chunks")

    var revision_before_noop: int = world.terrain_revision()
    PerformanceTelemetry.reset()
    _check(mutations.set_terrain_rect(rect, grass), "uniform no-op rectangle succeeds")
    var noop_values: Dictionary = PerformanceTelemetry.snapshot().get("values", {})
    _check(world.terrain_revision() == revision_before_noop, "uniform no-op rectangle does not advance terrain revision")
    _check(int(noop_values.get("terrain_bulk_rect_visited_cells", -1)) == 0, "uniform no-op rectangle visits zero terrain cells")
    _check(int(noop_values.get("terrain_bulk_rect_skipped_cells", 0)) == 65536, "uniform no-op rectangle skips every requested cell")
    _check(int(noop_values.get("terrain_bulk_rect_skipped_chunks", 0)) == 256, "uniform no-op rectangle skips every aligned chunk")

    var negative_cell := Vector2i(-31, -31)
    _check(world.has_terrain(negative_cell) and world.terrain_at(negative_cell) == grass, "negative-coordinate chunk lookup remains exact")
    _check(mutations.clear_terrain(negative_cell), "terrain erase works inside a chunk")
    _check(not world.has_terrain(negative_cell), "erased chunk cell becomes unknown")
    _check(mutations.set_terrain(negative_cell, road), "single-cell rewrite works after erase")
    _check(world.terrain_at(negative_cell) == road, "single-cell rewrite preserves exact semantic")

    var snapshot: Dictionary = world.snapshot()
    var restored := WorldState.new()
    _check(restored.load_snapshot(snapshot), "chunk-backed terrain snapshot round-trips through existing schema")
    _check(restored.terrain_at(negative_cell) == road, "snapshot round-trip preserves sparse terrain override")
    _check(restored.terrain_at(Vector2i(100, 100)) == grass, "snapshot round-trip preserves bulk terrain")

func _verify_production_boundary() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _check(packed != null, "production title scene loads")
    if packed == null:
        return
    var title: Node = packed.instantiate()
    root.add_child(title)
    current_scene = title
    await process_frame
    var new_game: Button = _find_button(title, "NEW GAME")
    _check(new_game != null, "production NEW GAME button exists")
    if new_game == null:
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
        return

    var transition_record: Dictionary = {}
    for action_index: int in range(1, MAX_ACTIONS_TO_BOUNDARY + 1):
        var before: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if before == null:
            failures.append("player placement missing before action %d" % action_index)
            return
        var region_before: Vector2i = streaming.focus_region_coord()
        PerformanceTelemetry.reset()
        var started_usec: int = Time.get_ticks_usec()
        controller.submit_intent(Intents.FORWARD)
        if not controller.is_busy():
            failures.append("forward action %d was rejected" % action_index)
            return
        var settle_frames: int = 0
        while controller.is_busy() and settle_frames < MAX_SETTLE_FRAMES:
            settle_frames += 1
            await process_frame
        if controller.is_busy():
            failures.append("forward action %d did not settle" % action_index)
            return
        var action_usec: int = Time.get_ticks_usec() - started_usec
        var after: WorldPlacement = world.placement(Fixture.PLAYER_ID)
        if after == null:
            failures.append("player placement missing after action %d" % action_index)
            return
        var region_after: Vector2i = streaming.focus_region_coord()
        if region_after == region_before:
            continue

        var telemetry: Dictionary = PerformanceTelemetry.snapshot()
        var timings: Dictionary = telemetry.get("timings", {})
        var values: Dictionary = telemetry.get("values", {})
        transition_record = {
            "action": action_index,
            "anchor_before": [before.anchor.x, before.anchor.y],
            "anchor_after": [after.anchor.x, after.anchor.y],
            "region_before": [region_before.x, region_before.y],
            "region_after": [region_after.x, region_after.y],
            "action_usec": action_usec,
            "ground_commit_usec": _total_timing(timings, "stream_area_ground_commit"),
            "world_snapshot_usec": _total_timing(timings, "stream_world_snapshot"),
            "rect_calls": int(values.get("terrain_bulk_rect_calls", 0)),
            "requested_cells": int(values.get("terrain_bulk_rect_requested_cells", 0)),
            "visited_cells": int(values.get("terrain_bulk_rect_visited_cells", 0)),
            "skipped_cells": int(values.get("terrain_bulk_rect_skipped_cells", 0)),
            "skipped_chunks": int(values.get("terrain_bulk_rect_skipped_chunks", 0)),
        }
        break

    _check(not transition_record.is_empty(), "production route crosses the expected streaming boundary")
    if transition_record.is_empty():
        return
    var ground_commit_usec: int = int(transition_record.get("ground_commit_usec", BASELINE_GROUND_COMMIT_USEC))
    _check(int(transition_record.get("rect_calls", 0)) > 0, "production boundary uses bulk rectangle mutation path")
    _check(int(transition_record.get("requested_cells", 0)) == 49152, "production boundary covers the same 49,152-cell terrain workload as baseline")
    _check(ground_commit_usec < BASELINE_GROUND_COMMIT_USEC, "production ground commit improves over measured baseline")
    _check(ground_commit_usec <= MAX_GROUND_COMMIT_USEC, "production ground commit is at most %.2f seconds" % (float(MAX_GROUND_COMMIT_USEC) / 1000000.0))
    print("PROMPT_TERRAIN_BULK_BOUNDARY %s" % JSON.stringify(transition_record))

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

func _total_timing(timings: Dictionary, key: String) -> int:
    var entry: Dictionary = timings.get(key, {})
    return int(entry.get("total_usec", 0))

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_TERRAIN_BULK_WRITE_OPTIMIZATION_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_TERRAIN_BULK_WRITE_OPTIMIZATION_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
