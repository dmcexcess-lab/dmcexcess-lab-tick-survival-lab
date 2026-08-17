extends RefCounted
class_name ActorHandDrawCommand

const SelectionClass = preload("res://scripts/art/ArtSelection.gd")

## Immutable-style presentation command for one stable held item in one actor hand.

var actor_id: String = ""
var item_id: String = ""
var item_semantic_type: StringName = &""
var hand_slot: int = -1
var render_pass: int = -1
var anchor: Vector2i = Vector2i.ZERO
var facing: int = -1
var center: Vector2 = Vector2.ZERO
var draw_size: float = 0.0
var rotation_radians: float = 0.0
var selection: ArtSelection = null

func _init(
    value_actor_id: String = "",
    value_item_id: String = "",
    value_item_semantic_type: StringName = &"",
    value_hand_slot: int = -1,
    value_render_pass: int = -1,
    value_anchor: Vector2i = Vector2i.ZERO,
    value_facing: int = -1,
    value_center: Vector2 = Vector2.ZERO,
    value_draw_size: float = 0.0,
    value_rotation_radians: float = 0.0,
    value_selection: ArtSelection = null
) -> void:
    actor_id = value_actor_id
    item_id = value_item_id
    item_semantic_type = value_item_semantic_type
    hand_slot = value_hand_slot
    render_pass = value_render_pass
    anchor = value_anchor
    facing = value_facing
    center = value_center
    draw_size = value_draw_size
    rotation_radians = value_rotation_radians
    selection = value_selection.copy() if value_selection != null else SelectionClass.unknown(value_item_semantic_type, "selection_missing")

func is_diagnostic() -> bool:
    return selection == null or not selection.is_found()

func diagnostic_reason() -> String:
    if selection == null:
        return "selection_missing"
    return selection.reason

func copy() -> ActorHandDrawCommand:
    return ActorHandDrawCommand.new(
        actor_id,
        item_id,
        item_semantic_type,
        hand_slot,
        render_pass,
        anchor,
        facing,
        center,
        draw_size,
        rotation_radians,
        selection
    )
