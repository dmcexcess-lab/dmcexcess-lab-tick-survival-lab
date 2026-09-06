extends Node2D
class_name ActorEquipmentPresentationRenderer

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Lightweight paper-doll/equipment presentation. Reads authoritative equipment only.

var _world: WorldState = null
var _equipment: ActorHandEquipmentState = null
var _origin := Vector2i.ZERO
var _size := Vector2i.ZERO
var _cell_pixels: float = 0.0
var _view_valid := false

func configure(world: WorldState, equipment: ActorHandEquipmentState) -> bool:
    if world == null or equipment == null:
        return false
    _world = world
    _equipment = equipment
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
    return _world != null and _equipment != null

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    if size_cells.x <= 0 or size_cells.y <= 0 or cell_pixels <= 0.0:
        return false
    _origin = origin
    _size = size_cells
    _cell_pixels = cell_pixels
    _view_valid = true
    queue_redraw()
    return true

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
        _draw_apparel(actor_id, center, placement.facing)
        _draw_floating(actor_id, center, placement.facing)

func _draw_apparel(actor_id: String, center: Vector2, facing: int) -> void:
    var s := _cell_pixels
    var torso := _semantic_in_slot(actor_id, Slots.Value.TORSO)
    var legs := _semantic_in_slot(actor_id, Slots.Value.LEGS)
    var feet := _semantic_in_slot(actor_id, Slots.Value.FEET)
    var head := _semantic_in_slot(actor_id, Slots.Value.HEAD)
    var hands := _semantic_in_slot(actor_id, Slots.Value.HANDS)
    if torso != &"":
        var torso_color := Color(0.30, 0.35, 0.32, 0.90)
        if torso == &"item.clothing.t_shirt":
            torso_color = Color(0.58, 0.58, 0.54, 0.90)
        elif torso == &"item.clothing.hoodie":
            torso_color = Color(0.24, 0.31, 0.39, 0.92)
        draw_rect(Rect2(center + Vector2(-s * 0.22, -s * 0.05), Vector2(s * 0.44, s * 0.32)), torso_color, true)
    if legs != &"":
        var leg_color := Color(0.18, 0.24, 0.34, 0.92) if legs == &"item.clothing.jeans" else Color(0.30, 0.31, 0.22, 0.92)
        draw_rect(Rect2(center + Vector2(-s * 0.19, s * 0.22), Vector2(s * 0.38, s * 0.24)), leg_color, true)
    if feet != &"":
        var foot_color := Color(0.16, 0.12, 0.09, 0.96) if feet == &"item.clothing.work_boots" else Color(0.27, 0.27, 0.27, 0.96)
        draw_rect(Rect2(center + Vector2(-s * 0.22, s * 0.40), Vector2(s * 0.44, s * 0.10)), foot_color, true)
    if head != &"":
        var hat_color := Color(0.19, 0.23, 0.26, 0.96)
        draw_arc(center + Vector2(0, -s * 0.28), s * 0.20, PI, TAU, 12, hat_color, s * 0.09)
        if head == &"item.clothing.baseball_cap":
            var facing_vector := FacingRules.vector(facing)
            var forward := Vector2(float(facing_vector.x), float(facing_vector.y))
            draw_line(center + Vector2(0, -s * 0.28), center + Vector2(0, -s * 0.28) + forward * s * 0.20, hat_color, s * 0.08)
    if hands != &"":
        draw_circle(center + Vector2(-s * 0.28, s * 0.02), s * 0.07, Color(0.28, 0.20, 0.12, 0.96))
        draw_circle(center + Vector2(s * 0.28, s * 0.02), s * 0.07, Color(0.28, 0.20, 0.12, 0.96))

func _draw_floating(actor_id: String, center: Vector2, facing: int) -> void:
    var forward_i := FacingRules.vector(facing)
    var forward := Vector2(float(forward_i.x), float(forward_i.y))
    var right := Vector2(-forward.y, forward.x)
    _draw_item(_equipment.item_in_slot(actor_id, Slots.Value.PRIMARY_RIGHT), center + right * _cell_pixels * 0.37 - forward * _cell_pixels * 0.03, false, facing)
    _draw_item(_equipment.item_in_slot(actor_id, Slots.Value.SECONDARY_LEFT), center - right * _cell_pixels * 0.37 - forward * _cell_pixels * 0.03, false, facing)
    _draw_item(_equipment.item_in_slot(actor_id, Slots.Value.BACK), center - forward * _cell_pixels * 0.28, true, facing)

func _draw_item(item_id: String, center: Vector2, on_back: bool, facing: int) -> void:
    if item_id.is_empty():
        return
    var entity := _world.entity(item_id)
    if entity == null:
        return
    var semantic := entity.semantic_type
    if semantic == &"item.vehicle.skateboard":
        var facing_vector := FacingRules.vector(facing)
        var forward := Vector2(float(facing_vector.x), float(facing_vector.y))
        var axis := Vector2(-forward.y, forward.x) if on_back else forward
        draw_line(center - axis * _cell_pixels * 0.22, center + axis * _cell_pixels * 0.22, Color(0.30, 0.20, 0.12, 1.0), maxf(3.0, _cell_pixels * 0.10))
        draw_circle(center - axis * _cell_pixels * 0.17, maxf(2.0, _cell_pixels * 0.035), Color(0.05, 0.05, 0.05, 1.0))
        draw_circle(center + axis * _cell_pixels * 0.17, maxf(2.0, _cell_pixels * 0.035), Color(0.05, 0.05, 0.05, 1.0))
        return
    draw_circle(center, maxf(4.0, _cell_pixels * 0.11), Color(0.08, 0.08, 0.08, 0.80))
    draw_rect(Rect2(center - Vector2.ONE * _cell_pixels * 0.07, Vector2.ONE * _cell_pixels * 0.14), Color(0.78, 0.74, 0.62, 0.96), true)

func _semantic_in_slot(actor_id: String, slot: int) -> StringName:
    var item_id := _equipment.item_in_slot(actor_id, slot)
    if item_id.is_empty():
        return &""
    var entity := _world.entity(item_id)
    return entity.semantic_type if entity != null else &""

func _center(cell: Vector2i) -> Vector2:
    var local := cell - _origin
    return Vector2((float(local.x) + 0.5) * _cell_pixels, (float(local.y) + 0.5) * _cell_pixels)

func _on_equipment_changed(_actor_id: String, _slot: int, _old: String, _new: String, _version: int) -> void:
    queue_redraw()
func _on_equipment_reset() -> void:
    queue_redraw()
func _on_world_changed(_change: Variant) -> void:
    queue_redraw()
