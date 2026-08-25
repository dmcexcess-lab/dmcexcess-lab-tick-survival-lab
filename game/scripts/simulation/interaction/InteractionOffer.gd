extends RefCounted
class_name InteractionOffer

## Read-only System-29 description of an action that a real mechanic owner says is
## currently available. It deliberately carries no mutation callback.

var actor_id: String = ""
var target_entity_id: String = ""
var action_id: StringName = &""
var label: String = ""
var reach_profile_id: StringName = &""
var target_cells: Array[Vector2i] = []
var presentation_priority: int = 0
var category: StringName = &""
var available: bool = false

func _init(
    offer_actor_id: String = "",
    offer_target_entity_id: String = "",
    offer_action_id: StringName = &"",
    offer_label: String = "",
    offer_reach_profile_id: StringName = &"",
    offer_target_cells: Array[Vector2i] = [],
    offer_presentation_priority: int = 0,
    offer_category: StringName = &"",
    offer_available: bool = false
) -> void:
    actor_id = offer_actor_id.strip_edges()
    target_entity_id = offer_target_entity_id.strip_edges()
    action_id = offer_action_id
    label = offer_label.strip_edges()
    reach_profile_id = offer_reach_profile_id
    presentation_priority = offer_presentation_priority
    category = offer_category
    available = offer_available

    var seen: Dictionary = {}
    for cell: Vector2i in offer_target_cells:
        if seen.has(cell):
            continue
        seen[cell] = true
        target_cells.append(cell)
    target_cells.sort_custom(_cell_less)

func is_valid() -> bool:
    return not actor_id.is_empty() \
        and not target_entity_id.is_empty() \
        and not String(action_id).strip_edges().is_empty() \
        and not label.is_empty() \
        and not String(reach_profile_id).strip_edges().is_empty() \
        and not target_cells.is_empty()

func copy() -> InteractionOffer:
    return InteractionOffer.new(
        actor_id,
        target_entity_id,
        action_id,
        label,
        reach_profile_id,
        target_cells,
        presentation_priority,
        category,
        available
    )

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
