extends RefCounted
class_name ActorEquipmentProjection

const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Profiles = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")

## Read-only projection of authoritative equipment truth for renderers and UI.
## This object never owns assignments and never mutates equipment state.

const VISUAL_LAYER_ORDER: Array[int] = [
    Slots.Value.BACK,
    Slots.Value.LEGS,
    Slots.Value.TORSO,
    Slots.Value.FEET,
    Slots.Value.HEAD,
    Slots.Value.HANDS,
    Slots.Value.PRIMARY_RIGHT,
    Slots.Value.SECONDARY_LEFT,
]

var _world: WorldState = null
var _equipment: ActorHandEquipmentState = null
var _profiles: ActorEquipmentProfileCatalog = null

func _init(
    world: WorldState = null,
    equipment: ActorHandEquipmentState = null,
    profiles: ActorEquipmentProfileCatalog = null
) -> void:
    _world = world
    _equipment = equipment
    _profiles = profiles if profiles != null else Profiles.new()

func is_ready() -> bool:
    return _world != null and _equipment != null and _profiles != null

func query(actor_id: String) -> Dictionary:
    var result := {"known": false, "actor_id": actor_id, "slots": []}
    if not is_ready() or actor_id.strip_edges().is_empty() or not _equipment.has_actor(actor_id):
        return result
    var rows: Array = []
    for slot: int in Slots.ALL:
        rows.append(_slot_row(actor_id, slot))
    result["slots"] = rows
    result["known"] = true
    return result

func visual_layers(actor_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not is_ready() or not _equipment.has_actor(actor_id):
        return result
    for slot: int in VISUAL_LAYER_ORDER:
        var row := _slot_row(actor_id, slot)
        if bool(row.get("empty", true)) or not bool(row.get("valid", false)):
            continue
        result.append(row)
    return result

func _slot_row(actor_id: String, slot: int) -> Dictionary:
    var item_id := _equipment.item_in_slot(actor_id, slot)
    var row := {
        "slot": slot,
        "slot_name": String(Slots.label(slot)),
        "label": display_label(slot),
        "empty": item_id.is_empty(),
        "valid": true,
        "item_id": item_id,
        "semantic_type": &"",
        "item_label": "Empty",
        "visual": &"",
    }
    if item_id.is_empty():
        return row
    var entity := _world.entity(item_id)
    if entity == null:
        row["valid"] = false
        row["item_label"] = "Missing Item"
        return row
    var semantic: StringName = entity.semantic_type
    var profile := _profiles.profile(semantic)
    row["semantic_type"] = semantic
    row["item_label"] = item_label(semantic)
    row["visual"] = StringName(profile.get("visual", &""))
    return row

static func display_label(slot: int) -> String:
    match slot:
        Slots.Value.PRIMARY_RIGHT: return "Right Hand"
        Slots.Value.SECONDARY_LEFT: return "Left Hand"
        Slots.Value.BACK: return "Back"
        Slots.Value.HEAD: return "Head"
        Slots.Value.TORSO: return "Torso"
        Slots.Value.LEGS: return "Legs"
        Slots.Value.FEET: return "Feet"
        Slots.Value.HANDS: return "Hands"
        _: return "Unknown"

static func item_label(semantic_type: StringName) -> String:
    var value := String(semantic_type).strip_edges()
    if value.begins_with("item."):
        value = value.substr(5)
    value = value.replace("_", " ").replace(".", " ")
    return "Unknown Item" if value.is_empty() else value.capitalize()
