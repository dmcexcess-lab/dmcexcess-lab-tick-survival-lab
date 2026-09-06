extends Node2D
class_name ActorEquipmentPresentationRenderer

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const ProjectionClass = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProjection.gd")

## Modular actor equipment presentation. ActorHandEquipmentState remains the only
## equipment authority; this renderer consumes a deterministic read-only projection.

var _world: WorldState = null
var _equipment: ActorHandEquipmentState = null
var _projection: ActorEquipmentProjection = null
var _origin := Vector2i.ZERO
var _size := Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid := false

func configure(world: WorldState, equipment: ActorHandEquipmentState) -> bool:
    if world == null or equipment == null:
        return false
    _world = world
    _equipment = equipment
    _projection = ProjectionClass.new(_world, _equipment)
    if not _projection.is_ready():
        return false
    var changed := Callable(self, "_on_equipment_changed")
    if not _equipment.equipment_assignment_changed.is_connected(changed):
        _equipment.equipment_assignment_changed.connect(changed)
    var reset := Callable(self, "_on_equipment_reset")
    if not _equipment.hand_equipment_reset.is_connected(reset):
        _equipment.hand_equipment_reset.connect(reset)
    var world_changed := Callable(self, "_on_world_changed")
    if not _world.changed.is_connected(world_changed):
        _world.changed.connect(world_changed)
    queue_redraw()
    return true

func is_configured() -> bool:
    return _world != null and _equipment != null and _projection != null and _projection.is_ready()

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    _origin = origin
    _size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    queue_redraw()
    return true

func projection_snapshot(actor_id: String) -> Dictionary:
    return _projection.query(actor_id) if _projection != null else {"known": false, "slots": []}

func _draw() -> void:
    if not is_configured() or not _view_valid:
        return
    for actor_id: String in _equipment.actor_ids():
        var placement := _world.placement(actor_id)
        if placement == null or placement.channel != Layers.Channel.ACTOR:
            continue
        if placement.anchor.x < _origin.x or placement.anchor.y < _origin.y or placement.anchor.x >= _origin.x + _size.x or placement.anchor.y >= _origin.y + _size.y:
            continue
        var center := _center(placement.anchor)
        for layer: Dictionary in _projection.visual_layers(actor_id):
            _draw_layer(layer, center, placement.facing)

func _draw_layer(layer: Dictionary, center: Vector2, facing: int) -> void:
    var slot := int(layer.get("slot", -1))
    var visual := StringName(layer.get("visual", &""))
    match slot:
        Slots.Value.BACK:
            _draw_item(layer, center, facing, true, false)
        Slots.Value.LEGS:
            _draw_legs(visual, center)
        Slots.Value.TORSO:
            _draw_torso(visual, center)
        Slots.Value.FEET:
            _draw_feet(visual, center)
        Slots.Value.HEAD:
            _draw_head(visual, center, facing)
        Slots.Value.HANDS:
            _draw_gloves(center)
        Slots.Value.PRIMARY_RIGHT:
            _draw_item(layer, center, facing, false, true)
        Slots.Value.SECONDARY_LEFT:
            _draw_item(layer, center, facing, false, false)

func _draw_torso(visual: StringName, center: Vector2) -> void:
    var color := Color(0.30, 0.35, 0.32, 0.90)
    if visual == &"t_shirt": color = Color(0.58, 0.58, 0.54, 0.90)
    elif visual == &"hoodie": color = Color(0.24, 0.31, 0.39, 0.92)
    draw_rect(Rect2(center + Vector2(-_cell_pixels * 0.22, -_cell_pixels * 0.05), Vector2(_cell_pixels * 0.44, _cell_pixels * 0.32)), color, true)

func _draw_legs(visual: StringName, center: Vector2) -> void:
    var color := Color(0.30, 0.31, 0.22, 0.92)
    if visual == &"jeans": color = Color(0.18, 0.24, 0.34, 0.92)
    draw_rect(Rect2(center + Vector2(-_cell_pixels * 0.19, _cell_pixels * 0.22), Vector2(_cell_pixels * 0.38, _cell_pixels * 0.24)), color, true)

func _draw_feet(visual: StringName, center: Vector2) -> void:
    var color := Color(0.27, 0.27, 0.27, 0.96)
    if visual == &"work_boots": color = Color(0.16, 0.12, 0.09, 0.96)
    draw_rect(Rect2(center + Vector2(-_cell_pixels * 0.22, _cell_pixels * 0.40), Vector2(_cell_pixels * 0.44, _cell_pixels * 0.10)), color, true)

func _draw_head(visual: StringName, center: Vector2, facing: int) -> void:
    var color := Color(0.19, 0.23, 0.26, 0.96)
    draw_arc(center + Vector2(0, -_cell_pixels * 0.28), _cell_pixels * 0.20, PI, TAU, 12, color, _cell_pixels * 0.09)
    if visual == &"baseball_cap":
        var facing_vector := FacingRules.vector(facing)
        var forward := Vector2(float(facing_vector.x), float(facing_vector.y))
        draw_line(center + Vector2(0, -_cell_pixels * 0.28), center + Vector2(0, -_cell_pixels * 0.28) + forward * _cell_pixels * 0.20, color, _cell_pixels * 0.08)

func _draw_gloves(center: Vector2) -> void:
    draw_circle(center + Vector2(-_cell_pixels * 0.28, _cell_pixels * 0.02), _cell_pixels * 0.07, Color(0.28, 0.20, 0.12, 0.96))
    draw_circle(center + Vector2(_cell_pixels * 0.28, _cell_pixels * 0.02), _cell_pixels * 0.07, Color(0.28, 0.20, 0.12, 0.96))

func _draw_item(layer: Dictionary, actor_center: Vector2, facing: int, on_back: bool, right_hand: bool) -> void:
    var facing_vector := FacingRules.vector(facing)
    var forward := Vector2(float(facing_vector.x), float(facing_vector.y))
    var right := Vector2(-forward.y, forward.x)
    var center := actor_center
    if on_back:
        center -= forward * _cell_pixels * 0.28
    elif right_hand:
        center += right * _cell_pixels * 0.37 - forward * _cell_pixels * 0.03
    else:
        center -= right * _cell_pixels * 0.37 + forward * _cell_pixels * 0.03

    var visual := StringName(layer.get("visual", &""))
    if visual == &"skateboard":
        var axis := Vector2(-forward.y, forward.x) if on_back else forward
        draw_line(center - axis * _cell_pixels * 0.22, center + axis * _cell_pixels * 0.22, Color(0.30, 0.20, 0.12, 1.0), maxf(3.0, _cell_pixels * 0.10))
        draw_circle(center - axis * _cell_pixels * 0.17, maxf(2.0, _cell_pixels * 0.035), Color(0.05, 0.05, 0.05, 1.0))
        draw_circle(center + axis * _cell_pixels * 0.17, maxf(2.0, _cell_pixels * 0.035), Color(0.05, 0.05, 0.05, 1.0))
        return
    draw_circle(center, maxf(4.0, _cell_pixels * 0.11), Color(0.08, 0.08, 0.08, 0.80))
    draw_rect(Rect2(center - Vector2.ONE * _cell_pixels * 0.07, Vector2.ONE * _cell_pixels * 0.14), Color(0.78, 0.74, 0.62, 0.96), true)

func _center(cell: Vector2i) -> Vector2:
    var local := cell - _origin
    return Vector2((float(local.x) + 0.5) * _cell_pixels, (float(local.y) + 0.5) * _cell_pixels)

func _on_equipment_changed(_actor_id: String, _slot: int, _old: String, _new: String, _version: int) -> void:
    queue_redraw()

func _on_equipment_reset() -> void:
    queue_redraw()

func _on_world_changed(_change: Variant) -> void:
    queue_redraw()
