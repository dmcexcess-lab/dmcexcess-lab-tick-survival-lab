extends RefCounted
class_name WorldStreamingCoordinator

signal active_regions_changed(activated, deactivated)
signal source_materialized(source_key, source_id, bounds)

const NO_FOCUS_CELL: Vector2i = Vector2i(-999999999, -999999999)

var _global_plan: GeneratedGlobalWorldPlan = null
var _grid: StreamingRegionGrid = null
var _materialization: WorldMaterializationCoordinator = null
var _source: AreaSiteMaterializationSource = null
var _active_radius: int = 1
var _focus_cell: Vector2i = NO_FOCUS_CELL
var _focus_region: Vector2i = StreamingRegionGrid.INVALID_COORD
var _active_regions: Array[Vector2i] = []

func _init(
    global_plan: GeneratedGlobalWorldPlan = null,
    grid: StreamingRegionGrid = null,
    materialization: WorldMaterializationCoordinator = null,
    source: AreaSiteMaterializationSource = null,
    active_radius: int = 1
) -> void:
    _global_plan = global_plan
    _grid = grid
    _materialization = materialization
    _source = source
    _active_radius = active_radius

func is_ready() -> bool:
    return _global_plan != null and _global_plan.is_generated() \
        and _grid != null and _grid.is_valid() \
        and _grid.world_bounds() == _global_plan.bounds \
        and _materialization != null and _materialization.is_ready() \
        and _source != null and _source.is_ready() \
        and _active_radius >= 0

func update_focus(cell: Vector2i) -> Dictionary:
    if not is_ready():
        return _failure("streaming_coordinator_not_ready")
    if not _global_plan.bounds.has_point(cell):
        return _failure("focus_outside_world_bounds")

    var target_focus_region: Vector2i = _grid.region_coord_for_cell(cell)
    if target_focus_region == StreamingRegionGrid.INVALID_COORD:
        return _failure("focus_region_unresolved")
    var target_regions: Array[Vector2i] = _grid.regions_around(target_focus_region, _active_radius)
    if target_regions.is_empty():
        return _failure("active_region_set_empty")

    var target_bounds: Array[Rect2i] = []
    for coord: Vector2i in target_regions:
        var bounds: Rect2i = _grid.region_bounds(coord)
        if bounds.size.x <= 0 or bounds.size.y <= 0:
            return _failure("active_region_bounds_invalid")
        target_bounds.append(bounds)

    var site_ids: Array[String] = _source.site_ids_intersecting(_global_plan, target_bounds)
    var ensured: Dictionary = _materialization.ensure_area_sites(_global_plan, site_ids)
    if not bool(ensured.get("ok", false)):
        return _failure("required_materialization_failed:%s" % String(ensured.get("failure_reason", "unknown")))

    var activated: Array[Vector2i] = _difference(target_regions, _active_regions)
    var deactivated: Array[Vector2i] = _difference(_active_regions, target_regions)
    _focus_cell = cell
    _focus_region = target_focus_region
    _active_regions = target_regions.duplicate()

    var newly: Array = ensured.get("newly_materialized", [])
    for key_value: Variant in newly:
        var source_key: String = String(key_value)
        var value: MaterializationRecord = _materialization.registry().record(source_key)
        if value != null:
            source_materialized.emit(value.source_key, value.source_id, value.bounds)
    if not activated.is_empty() or not deactivated.is_empty():
        active_regions_changed.emit(activated.duplicate(), deactivated.duplicate())

    return {
        "ok": true,
        "failure_reason": "",
        "focus_cell": _focus_cell,
        "focus_region": _focus_region,
        "active_regions": _active_regions.duplicate(),
        "activated": activated,
        "deactivated": deactivated,
        "newly_materialized": ensured.get("newly_materialized", []),
        "already_materialized": ensured.get("already_materialized", []),
    }

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

func _difference(a: Array[Vector2i], b: Array[Vector2i]) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for value: Vector2i in a:
        if not b.has(value):
            result.append(value)
    return result

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
    }
