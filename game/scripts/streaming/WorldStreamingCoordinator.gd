extends RefCounted
class_name WorldStreamingCoordinator

signal active_regions_changed(activated, deactivated)
signal source_materialized(source_key, source_id, bounds)

const NO_FOCUS_CELL: Vector2i = Vector2i(-999999999, -999999999)
const LOOKAHEAD_EDGE_CELLS: int = 24
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

var _global_plan: GeneratedGlobalWorldPlan = null
var _grid: StreamingRegionGrid = null
var _materialization: WorldMaterializationCoordinator = null
var _providers: Array = []
var _provider_by_kind: Dictionary = {}
var _provider_configuration_valid: bool = true
var _active_radius: int = 1
var _focus_cell: Vector2i = NO_FOCUS_CELL
var _focus_region: Vector2i = StreamingRegionGrid.INVALID_COORD
var _active_regions: Array[Vector2i] = []
var _region_source_cache: Dictionary = {}
var _update_count: int = 0
var _same_region_fast_path_count: int = 0
var _last_update_usec: int = 0
var _last_materialized_source_count: int = 0
var _lookahead_prepare_count: int = 0

func _init(
    global_plan: GeneratedGlobalWorldPlan = null,
    grid: StreamingRegionGrid = null,
    materialization: WorldMaterializationCoordinator = null,
    source: Variant = null,
    active_radius: int = 1,
    countryside_source: Variant = null,
    source_providers: Array = []
) -> void:
    _global_plan = global_plan
    _grid = grid
    _materialization = materialization
    _active_radius = active_radius

    _register_provider(source)
    _register_provider(countryside_source)
    for provider: Variant in source_providers:
        _register_provider(provider)
    if _materialization != null:
        for provider: Variant in _materialization.source_providers():
            _register_provider(provider)

func is_ready() -> bool:
    if not _provider_configuration_valid \
        or _global_plan == null or not _global_plan.is_generated() \
        or _grid == null or not _grid.is_valid() \
        or _grid.world_bounds() != _global_plan.bounds \
        or _materialization == null or not _materialization.is_ready() \
        or _active_radius < 0 \
        or _providers.is_empty():
        return false
    for provider: Variant in _providers:
        if not _provider_ready(provider):
            return false
        var source_kind: StringName = StringName(provider.call("source_kind"))
        if not _materialization.supports_source_kind(source_kind):
            return false
    return true

func source_providers() -> Array:
    return _providers.duplicate()

func update_focus(cell: Vector2i) -> Dictionary:
    var started: int = Time.get_ticks_usec()
    _update_count += 1
    _last_materialized_source_count = 0
    if not is_ready():
        return _finish_update(_failure("streaming_coordinator_not_ready"), started)
    if not _global_plan.bounds.has_point(cell):
        return _finish_update(_failure("focus_outside_world_bounds"), started)

    var target_focus_region: Vector2i = _grid.region_coord_for_cell(cell)
    if target_focus_region == StreamingRegionGrid.INVALID_COORD:
        return _finish_update(_failure("focus_region_unresolved"), started)

    ## Same-region movement remains a strict fast path. Look-ahead preparation is invoked by the
    ## player focus adapter after this returns, so active-region state never changes early.
    if has_focus() and target_focus_region == _focus_region:
        _focus_cell = cell
        _same_region_fast_path_count += 1
        return _finish_update(_success([], [], true, [], []), started)

    var target_regions: Array[Vector2i] = _grid.regions_around(target_focus_region, _active_radius)
    if target_regions.is_empty():
        return _finish_update(_failure("active_region_set_empty"), started)

    var activated: Array[Vector2i] = _difference(target_regions, _active_regions)
    var deactivated: Array[Vector2i] = _difference(_active_regions, target_regions)
    PerformanceTelemetry.record_value(&"stream_entering_regions", activated.size())

    ## Only entering regions can introduce a newly required logical source. Each technical region
    ## is discovered once and retained as a lazy spatial index, so revisits become dictionary reads.
    var discovery_started: int = Time.get_ticks_usec()
    var discovery: Dictionary = _handles_for_regions(activated)
    PerformanceTelemetry.record_timing(&"stream_source_discovery", Time.get_ticks_usec() - discovery_started)
    if not bool(discovery.get("ok", false)):
        return _finish_update(_failure(String(discovery.get("failure_reason", "materialization_source_discovery_failed"))), started)
    var handles: Array[Dictionary] = discovery.get("handles", [])

    ## Do not enter the coordinator at all for sources WHAT already owns.
    var already_skipped: Array[String] = []
    var missing: Array[Dictionary] = []
    for handle: Dictionary in handles:
        var source_key: String = String(handle.get("source_key", ""))
        if _materialization.is_source_materialized(source_key):
            already_skipped.append(source_key)
        else:
            missing.append(handle)
    already_skipped.sort()
    PerformanceTelemetry.record_value(&"stream_skipped_materialized", already_skipped.size())

    var newly: Array = []
    var already: Array = already_skipped.duplicate()
    if not missing.is_empty():
        var ensured: Dictionary = _materialization.ensure_sources(_global_plan, missing)
        if not bool(ensured.get("ok", false)):
            return _finish_update(_failure("required_materialization_failed:%s" % String(ensured.get("failure_reason", "unknown"))), started)
        newly = ensured.get("newly_materialized", [])
        for value: Variant in ensured.get("already_materialized", []):
            var source_key: String = String(value)
            if not already.has(source_key):
                already.append(source_key)
        already.sort()

    _focus_cell = cell
    _focus_region = target_focus_region
    _active_regions = target_regions.duplicate()

    _last_materialized_source_count = newly.size()
    for key_value: Variant in newly:
        var source_key: String = String(key_value)
        var value: MaterializationRecord = _materialization.registry().record(source_key)
        if value != null:
            source_materialized.emit(value.source_key, value.source_id, value.bounds)
    if not activated.is_empty() or not deactivated.is_empty():
        active_regions_changed.emit(activated.duplicate(), deactivated.duplicate())

    return _finish_update(_success(newly, already, false, activated, deactivated), started)

## Prepare the strip that would enter if movement continues in the current direction. This never
## changes active regions or WHAT. One generated source per call keeps prep bounded across steps.
func prepare_lookahead(cell: Vector2i, movement_delta: Vector2i, max_new_sources: int = 1) -> Dictionary:
    if not is_ready() or not has_focus() or movement_delta == Vector2i.ZERO:
        return {"ok": true, "prepared": [], "pending": [], "generated_count": 0}
    if _grid.region_coord_for_cell(cell) != _focus_region:
        return {"ok": true, "prepared": [], "pending": [], "generated_count": 0}

    var direction := Vector2i(signi(movement_delta.x), signi(movement_delta.y))
    if not _approaching_edge(cell, direction):
        return {"ok": true, "prepared": [], "pending": [], "generated_count": 0}

    var next_focus_region: Vector2i = _focus_region + direction
    if _grid.region_bounds(next_focus_region).size.x <= 0 or _grid.region_bounds(next_focus_region).size.y <= 0:
        return {"ok": true, "prepared": [], "pending": [], "generated_count": 0}
    var next_regions: Array[Vector2i] = _grid.regions_around(next_focus_region, _active_radius)
    var entering: Array[Vector2i] = _difference(next_regions, _active_regions)
    if entering.is_empty():
        return {"ok": true, "prepared": [], "pending": [], "generated_count": 0}

    for region: Vector2i in entering:
        var discovery_started: int = Time.get_ticks_usec()
        var discovery: Dictionary = _handles_for_regions([region])
        PerformanceTelemetry.record_timing(&"stream_source_discovery", Time.get_ticks_usec() - discovery_started)
        if not bool(discovery.get("ok", false)):
            return discovery
        var candidates: Array[Dictionary] = []
        for handle: Dictionary in discovery.get("handles", []):
            var source_key: String = String(handle.get("source_key", ""))
            if not _materialization.is_source_materialized(source_key) and not _materialization.is_source_prepared(source_key):
                candidates.append(handle)
        if candidates.is_empty():
            continue
        var result: Dictionary = _materialization.prepare_sources(_global_plan, candidates, maxi(max_new_sources, 1))
        if bool(result.get("ok", false)) and int(result.get("generated_count", 0)) > 0:
            _lookahead_prepare_count += int(result.get("generated_count", 0))
            PerformanceTelemetry.record_value(&"stream_lookahead_prepares", _lookahead_prepare_count)
        return result

    return {"ok": true, "prepared": [], "pending": [], "generated_count": 0}

func has_focus() -> bool:
    return _focus_cell != NO_FOCUS_CELL

func focus_cell() -> Vector2i:
    return _focus_cell

func focus_region_coord() -> Vector2i:
    return _focus_region

func active_region_coords() -> Array[Vector2i]:
    return _active_regions.duplicate()

func active_region_bounds() -> Array[Rect2i]:
    var result: Array[Rect2i] = []
    if _grid == null:
        return result
    for coord: Vector2i in _active_regions:
        result.append(_grid.region_bounds(coord))
    return result

func is_cell_active(cell: Vector2i) -> bool:
    if _grid == null or not _grid.is_valid():
        return false
    var coord: Vector2i = _grid.region_coord_for_cell(cell)
    return coord != StreamingRegionGrid.INVALID_COORD and _active_regions.has(coord)

func debug_snapshot() -> Dictionary:
    return {
        "update_count": _update_count,
        "same_region_fast_path_count": _same_region_fast_path_count,
        "last_update_usec": _last_update_usec,
        "last_materialized_source_count": _last_materialized_source_count,
        "focus_cell": _focus_cell,
        "focus_region": _focus_region,
        "active_region_count": _active_regions.size(),
        "indexed_region_count": _region_source_cache.size(),
        "prepared_source_count": 0 if _materialization == null else _materialization.prepared_source_count(),
        "lookahead_prepare_count": _lookahead_prepare_count,
    }

func _handles_for_regions(regions: Array[Vector2i]) -> Dictionary:
    var by_key: Dictionary = {}
    for coord: Vector2i in regions:
        var cache_key: String = _region_cache_key(coord)
        var region_handles: Array[Dictionary] = []
        if _region_source_cache.has(cache_key):
            PerformanceTelemetry.increment(&"stream_region_index_hits")
            for value: Variant in _region_source_cache[cache_key]:
                if typeof(value) == TYPE_DICTIONARY:
                    region_handles.append((value as Dictionary).duplicate(true))
        else:
            var bounds: Rect2i = _grid.region_bounds(coord)
            if bounds.size.x <= 0 or bounds.size.y <= 0:
                return {"ok": false, "failure_reason": "active_region_bounds_invalid", "handles": []}
            for provider: Variant in _providers:
                var discovered_value: Variant = provider.call("source_handles_intersecting", _global_plan, [bounds])
                if typeof(discovered_value) != TYPE_ARRAY:
                    return {"ok": false, "failure_reason": "materialization_source_discovery_invalid:%s" % String(provider.call("source_kind")), "handles": []}
                for handle_value: Variant in discovered_value:
                    if typeof(handle_value) != TYPE_DICTIONARY:
                        return {"ok": false, "failure_reason": "materialization_source_handle_invalid:%s" % String(provider.call("source_kind")), "handles": []}
                    region_handles.append((handle_value as Dictionary).duplicate(true))
            region_handles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
                return String(a.get("source_key", "")) < String(b.get("source_key", ""))
            )
            _region_source_cache[cache_key] = region_handles.duplicate(true)
        for handle: Dictionary in region_handles:
            var source_key: String = String(handle.get("source_key", ""))
            if source_key.is_empty():
                return {"ok": false, "failure_reason": "materialization_source_key_invalid", "handles": []}
            if not by_key.has(source_key):
                by_key[source_key] = handle

    var handles: Array[Dictionary] = []
    for value: Variant in by_key.values():
        handles.append((value as Dictionary).duplicate(true))
    handles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("source_key", "")) < String(b.get("source_key", ""))
    )
    PerformanceTelemetry.record_value(&"stream_indexed_regions", _region_source_cache.size())
    return {"ok": true, "failure_reason": "", "handles": handles}

func _approaching_edge(cell: Vector2i, direction: Vector2i) -> bool:
    var bounds: Rect2i = _grid.region_bounds(_focus_region)
    if bounds.size.x <= 0 or bounds.size.y <= 0:
        return false
    var last: Vector2i = bounds.position + bounds.size - Vector2i.ONE
    var x_ready: bool = direction.x == 0 \
        or (direction.x > 0 and last.x - cell.x < LOOKAHEAD_EDGE_CELLS) \
        or (direction.x < 0 and cell.x - bounds.position.x < LOOKAHEAD_EDGE_CELLS)
    var y_ready: bool = direction.y == 0 \
        or (direction.y > 0 and last.y - cell.y < LOOKAHEAD_EDGE_CELLS) \
        or (direction.y < 0 and cell.y - bounds.position.y < LOOKAHEAD_EDGE_CELLS)
    return x_ready and y_ready

func _region_cache_key(coord: Vector2i) -> String:
    return "%d,%d" % [coord.x, coord.y]

func _finish_update(result: Dictionary, started_usec: int) -> Dictionary:
    _last_update_usec = Time.get_ticks_usec() - started_usec
    PerformanceTelemetry.record_timing(&"stream_update", _last_update_usec)
    PerformanceTelemetry.record_value(&"stream_updates", _update_count)
    PerformanceTelemetry.record_value(&"stream_fast_paths", _same_region_fast_path_count)
    PerformanceTelemetry.record_value(&"stream_last_sources", _last_materialized_source_count)
    return result

func _register_provider(provider: Variant) -> void:
    if provider == null:
        return
    if typeof(provider) != TYPE_OBJECT or not provider.has_method("source_kind"):
        _provider_configuration_valid = false
        return
    var source_kind: StringName = StringName(provider.call("source_kind"))
    if String(source_kind).is_empty():
        _provider_configuration_valid = false
        return
    if _provider_by_kind.has(source_kind):
        if _provider_by_kind[source_kind] == provider:
            return
        _provider_configuration_valid = false
        return
    _providers.append(provider)
    _provider_by_kind[source_kind] = provider

func _provider_ready(provider: Variant) -> bool:
    if provider == null or typeof(provider) != TYPE_OBJECT:
        return false
    for method_name: String in ["is_ready", "source_kind", "source_handles_intersecting"]:
        if not provider.has_method(method_name):
            return false
    return bool(provider.call("is_ready"))

func _difference(a: Array[Vector2i], b: Array[Vector2i]) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for value: Vector2i in a:
        if not b.has(value):
            result.append(value)
    return result

func _success(
    newly_materialized: Array,
    already_materialized: Array,
    fast_path: bool,
    activated: Array,
    deactivated: Array
) -> Dictionary:
    return {
        "ok": true,
        "failure_reason": "",
        "focus_cell": _focus_cell,
        "focus_region": _focus_region,
        "active_regions": _active_regions.duplicate(),
        "activated": activated.duplicate(),
        "deactivated": deactivated.duplicate(),
        "newly_materialized": newly_materialized.duplicate(),
        "already_materialized": already_materialized.duplicate(),
        "fast_path": fast_path,
    }

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "focus_cell": _focus_cell,
        "focus_region": _focus_region,
        "active_regions": _active_regions.duplicate(),
        "activated": [],
        "deactivated": [],
        "newly_materialized": [],
        "already_materialized": [],
        "fast_path": false,
    }
