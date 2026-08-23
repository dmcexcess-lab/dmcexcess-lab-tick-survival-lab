extends RefCounted
class_name StreamingRegionGrid

const INVALID_COORD: Vector2i = Vector2i(-1, -1)

var _world_bounds: Rect2i = Rect2i()
var _region_size: Vector2i = Vector2i.ZERO
var _grid_size: Vector2i = Vector2i.ZERO

func _init(world_bounds: Rect2i = Rect2i(), region_size: Vector2i = Vector2i(256, 256)) -> void:
    _world_bounds = world_bounds
    _region_size = region_size
    if world_bounds.size.x > 0 and world_bounds.size.y > 0 and region_size.x > 0 and region_size.y > 0:
        _grid_size = Vector2i(
            int((world_bounds.size.x + region_size.x - 1) / region_size.x),
            int((world_bounds.size.y + region_size.y - 1) / region_size.y)
        )

func is_valid() -> bool:
    return _world_bounds.size.x > 0 and _world_bounds.size.y > 0 \
        and _region_size.x > 0 and _region_size.y > 0 \
        and _grid_size.x > 0 and _grid_size.y > 0

func world_bounds() -> Rect2i:
    return _world_bounds

func region_size() -> Vector2i:
    return _region_size

func grid_size() -> Vector2i:
    return _grid_size

func region_coord_for_cell(cell: Vector2i) -> Vector2i:
    if not is_valid() or not _world_bounds.has_point(cell):
        return INVALID_COORD
    var relative: Vector2i = cell - _world_bounds.position
    return Vector2i(
        int(relative.x / _region_size.x),
        int(relative.y / _region_size.y)
    )

func region_bounds(coord: Vector2i) -> Rect2i:
    if not is_valid() or not _coord_valid(coord):
        return Rect2i()
    var start: Vector2i = _world_bounds.position + Vector2i(
        coord.x * _region_size.x,
        coord.y * _region_size.y
    )
    var world_end: Vector2i = _world_bounds.position + _world_bounds.size
    var nominal_end: Vector2i = start + _region_size
    var finish := Vector2i(
        mini(nominal_end.x, world_end.x),
        mini(nominal_end.y, world_end.y)
    )
    return Rect2i(start, finish - start)

func regions_around(coord: Vector2i, radius: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not is_valid() or radius < 0 or not _coord_valid(coord):
        return result
    var min_x: int = maxi(0, coord.x - radius)
    var max_x: int = mini(_grid_size.x - 1, coord.x + radius)
    var min_y: int = maxi(0, coord.y - radius)
    var max_y: int = mini(_grid_size.y - 1, coord.y + radius)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            result.append(Vector2i(x, y))
    return result

func region_coords_for_bounds(bounds: Rect2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not is_valid() or bounds.size.x <= 0 or bounds.size.y <= 0:
        return result
    var clipped: Rect2i = _intersection(_world_bounds, bounds)
    if clipped.size.x <= 0 or clipped.size.y <= 0:
        return result
    var first: Vector2i = region_coord_for_cell(clipped.position)
    var last_cell: Vector2i = clipped.position + clipped.size - Vector2i.ONE
    var last: Vector2i = region_coord_for_cell(last_cell)
    if first == INVALID_COORD or last == INVALID_COORD:
        return result
    for y in range(first.y, last.y + 1):
        for x in range(first.x, last.x + 1):
            result.append(Vector2i(x, y))
    return result

func _coord_valid(coord: Vector2i) -> bool:
    return coord.x >= 0 and coord.y >= 0 and coord.x < _grid_size.x and coord.y < _grid_size.y

func _intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start := Vector2i(maxi(a.position.x, b.position.x), maxi(a.position.y, b.position.y))
    var a_end: Vector2i = a.position + a.size
    var b_end: Vector2i = b.position + b.size
    var finish := Vector2i(mini(a_end.x, b_end.x), mini(a_end.y, b_end.y))
    if finish.x <= start.x or finish.y <= start.y:
        return Rect2i()
    return Rect2i(start, finish - start)
