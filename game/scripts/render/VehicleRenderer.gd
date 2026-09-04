extends Node2D
class_name VehicleRenderer

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

const VEHICLE_SPRITES: Dictionary = {
    VehicleProfileCatalog.SKATEBOARD: preload("res://assets/vehicle_skateboard.svg"),
    VehicleProfileCatalog.BICYCLE: preload("res://assets/vehicle_bicycle.svg"),
    VehicleProfileCatalog.MOTORCYCLE: preload("res://assets/vehicle_motorcycle.svg"),
    VehicleProfileCatalog.CAR: preload("res://assets/vehicle_car.svg"),
    VehicleProfileCatalog.TRUCK: preload("res://assets/vehicle_truck.svg"),
}
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

static func has_dedicated_sprite(kind: StringName) -> bool:
    return VEHICLE_SPRITES.has(kind) and VEHICLE_SPRITES.get(kind) is Texture2D

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
    var occupied_cells: Array[Vector2i] = placement.footprint.world_cells(placement.anchor, placement.facing)
    if occupied_cells.is_empty():
        return
    var min_cell := occupied_cells[0]
    var max_cell := occupied_cells[0]
    for cell: Vector2i in occupied_cells:
        min_cell = Vector2i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y))
        max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
    var center := Vector2(
        (float(min_cell.x + max_cell.x + 1) * 0.5 - float(_origin.x)) * _cell_pixels,
        (float(min_cell.y + max_cell.y + 1) * 0.5 - float(_origin.y)) * _cell_pixels
    )
    var angle := deg_to_rad(float(int(rec.get("heading", 0)) * 30))
    if not has_dedicated_sprite(kind):
        return
    var texture: Texture2D = VEHICLE_SPRITES[kind]
    var texture_size := texture.get_size()
    var fit_scale := minf(width / texture_size.x, height / texture_size.y)
    var draw_size := texture_size * fit_scale
    draw_set_transform(center, angle)
    draw_texture_rect(texture, Rect2(-draw_size * 0.5, draw_size), false)
    draw_set_transform(Vector2.ZERO, 0.0)

func _on_world_changed(_change: Variant) -> void:
    queue_redraw()

func _on_world_batch_changed(_batch: Variant) -> void:
    queue_redraw()
