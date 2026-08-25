extends RefCounted
class_name SkyExposureQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## Neutral read-only shelter/sky-exposure query for precipitation presentation.
## Structure cells form the enclosure boundary regardless of current door OPEN/CLOSED state.
## Cache invalidation follows only terrain + STRUCTURE placement truth, never unrelated WHAT churn.

const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _world: WorldState = null
var _cached_bounds: Rect2i = Rect2i()
var _cached_terrain_revision: int = -1
var _cached_structure_revision: int = -1
var _rebuild_count: int = 0
var _exposed: Dictionary = {}
var _materialized: Dictionary = {}
var _structure: Dictionary = {}

func _init(world_state: WorldState = null) -> void:
    _world = world_state

func is_ready() -> bool:
    return _world != null

func is_exposed(cell: Vector2i, bounds: Rect2i) -> bool:
    if not _ensure(bounds):
        return false
    return _exposed.has(cell)

func exposure_mask(bounds: Rect2i) -> Dictionary:
    if not _ensure(bounds):
        return {}
    return _exposed.duplicate()

func debug_snapshot(bounds: Rect2i) -> Dictionary:
    _ensure(bounds)
    return {
        "ready": is_ready(),
        "bounds": _cached_bounds,
        "world_revision": -1 if _world == null else _world.revision(),
        "terrain_revision": _cached_terrain_revision,
        "structure_revision": _cached_structure_revision,
        "rebuild_count": _rebuild_count,
        "materialized_cells": _materialized.size(),
        "structure_cells": _structure.size(),
        "sky_exposed_cells": _exposed.size(),
    }

func _ensure(bounds: Rect2i) -> bool:
    if not is_ready() or bounds.size.x <= 0 or bounds.size.y <= 0:
        return false
    var terrain_revision: int = _world.terrain_revision()
    var structure_revision: int = _world.placement_revision(Layers.Channel.STRUCTURE)
    if bounds == _cached_bounds \
        and terrain_revision == _cached_terrain_revision \
        and structure_revision == _cached_structure_revision \
        and not _materialized.is_empty():
        return true
    _cached_bounds = bounds
    _cached_terrain_revision = terrain_revision
    _cached_structure_revision = structure_revision
    _rebuild()
    return true

func _rebuild() -> void:
    var started: int = Time.get_ticks_usec()
    _exposed.clear()
    _materialized.clear()
    _structure.clear()
    var end_x: int = _cached_bounds.position.x + _cached_bounds.size.x
    var end_y: int = _cached_bounds.position.y + _cached_bounds.size.y
    for y in range(_cached_bounds.position.y, end_y):
        for x in range(_cached_bounds.position.x, end_x):
            var cell := Vector2i(x, y)
            if not _world.has_terrain(cell):
                continue
            _materialized[cell] = true
            if not _world.entities_at(cell, Layers.Channel.STRUCTURE).is_empty():
                _structure[cell] = true

    var queue: Array[Vector2i] = []
    var queued: Dictionary = {}
    var min_x: int = _cached_bounds.position.x
    var min_y: int = _cached_bounds.position.y
    var max_x: int = min_x + _cached_bounds.size.x - 1
    var max_y: int = min_y + _cached_bounds.size.y - 1
    for x in range(min_x, max_x + 1):
        _queue_seed(Vector2i(x, min_y), queue, queued)
        _queue_seed(Vector2i(x, max_y), queue, queued)
    for y in range(min_y + 1, max_y):
        _queue_seed(Vector2i(min_x, y), queue, queued)
        _queue_seed(Vector2i(max_x, y), queue, queued)

    var head: int = 0
    while head < queue.size():
        var cell: Vector2i = queue[head]
        head += 1
        _exposed[cell] = true
        for direction: Vector2i in CARDINALS:
            var neighbor: Vector2i = cell + direction
            if not _cached_bounds.has_point(neighbor) or queued.has(neighbor):
                continue
            if not _materialized.has(neighbor) or _structure.has(neighbor):
                continue
            queued[neighbor] = true
            queue.append(neighbor)

    _rebuild_count += 1
    PerformanceTelemetry.record_timing(&"sky_exposure_rebuild", Time.get_ticks_usec() - started)
    PerformanceTelemetry.record_value(&"sky_exposure_rebuilds", _rebuild_count)

func _queue_seed(cell: Vector2i, queue: Array[Vector2i], queued: Dictionary) -> void:
    if queued.has(cell) or not _materialized.has(cell) or _structure.has(cell):
        return
    queued[cell] = true
    queue.append(cell)
