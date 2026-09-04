extends Node2D
class_name VehicleRenderer

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

var _world: WorldState
var _state: VehicleState
var _profiles: VehicleProfileCatalog
var _origin := Vector2i.ZERO
var _size := Vector2i.ZERO
var _cell_pixels: float = 0.0
var _configured: bool = false

func configure(world: WorldState, state: VehicleState, profiles: VehicleProfileCatalog) -> bool:
    if world == null or state == null or profiles == null:
        return false
    _world = world
    _state = state
    _profiles = profiles
    if not _world.changed.is_connected(_on_world_changed):
        _world.changed.connect(_on_world_changed)
    if not _world.batch_changed.is_connected(_on_world_batch_changed):
        _world.batch_changed.connect(_on_world_batch_changed)
    _configured = true
    queue_redraw()
    return true

func is_configured() -> bool:
    return _configured

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    _origin = origin
    _size = size_cells
    _cell_pixels = cell_pixels
    queue_redraw()
    return true

func _draw() -> void:
    if not _configured or _cell_pixels <= 0.0:
        return
    var seen: Dictionary = {}
    for y in range(_origin.y, _origin.y + _size.y):
        for x in range(_origin.x, _origin.x + _size.x):
            for entity_id: String in _world.entities_at(Vector2i(x, y), Layers.Channel.OBJECT):
                if seen.has(entity_id) or not _state.has_vehicle(entity_id):
                    continue
                seen[entity_id] = true
                _draw_vehicle(entity_id)

func _draw_vehicle(vehicle_id: String) -> void:
    var placement := _world.placement(vehicle_id)
    if placement == null:
        return
    var rec := _state.record(vehicle_id)
    var kind := StringName(rec.get("kind", &""))
    var p := _profiles.profile(kind)
    var width := float(p.get("width", 1)) * _cell_pixels
    var height := float(p.get("height", 1)) * _cell_pixels
    var center := Vector2(
        (float(placement.anchor.x - _origin.x) + 0.5) * _cell_pixels,
        (float(placement.anchor.y - _origin.y) + 0.5) * _cell_pixels
    )
    var half := Vector2(width * 0.5, height * 0.5)
    var angle := deg_to_rad(float(int(rec.get("heading", 0)) * 30))
    var points := PackedVector2Array([
        _rotate(Vector2(-half.x, -half.y), angle) + center,
        _rotate(Vector2(half.x, -half.y), angle) + center,
        _rotate(Vector2(half.x, half.y), angle) + center,
        _rotate(Vector2(-half.x, half.y), angle) + center,
    ])
    var body_color := Color(0.24, 0.30, 0.34, 1.0)
    if kind == VehicleProfileCatalog.SKATEBOARD: body_color = Color(0.34, 0.24, 0.18, 1.0)
    elif kind == VehicleProfileCatalog.BICYCLE: body_color = Color(0.20, 0.35, 0.24, 1.0)
    elif kind == VehicleProfileCatalog.MOTORCYCLE: body_color = Color(0.32, 0.20, 0.20, 1.0)
    elif kind == VehicleProfileCatalog.TRUCK: body_color = Color(0.28, 0.28, 0.22, 1.0)
    draw_colored_polygon(points, body_color)
    draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.05, 0.05, 0.05, 1.0), maxf(1.0, _cell_pixels * 0.08))
    var nose := _rotate(Vector2(0, -half.y), angle) + center
    draw_line(center, nose, Color(0.92, 0.92, 0.75, 1.0), maxf(1.0, _cell_pixels * 0.1))

static func _rotate(point: Vector2, angle: float) -> Vector2:
    var c := cos(angle)
    var s := sin(angle)
    return Vector2(point.x * c - point.y * s, point.x * s + point.y * c)

func _on_world_changed(_change: Variant) -> void:
    queue_redraw()

func _on_world_batch_changed(_batch: Variant) -> void:
    queue_redraw()
