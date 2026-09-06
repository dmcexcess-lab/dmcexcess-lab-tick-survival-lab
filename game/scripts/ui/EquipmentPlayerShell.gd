extends CraftingPlayerShell
class_name EquipmentPlayerShell

const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Profiles = preload("res://scripts/simulation/actors/equipment/ActorEquipmentProfileCatalog.gd")

## Production inventory/equipment surface. Reads the authoritative paper-doll projection
## and routes all mutations through the existing timed ItemTransferActionService.

var _equipment_profiles: ActorEquipmentProfileCatalog = Profiles.new()

func _render_inventory() -> void:
    super._render_inventory()
    if not bool(_last_result.get("ok", false)):
        return
    var equipment: Dictionary = _last_result.get("equipment", {})
    _append_heading("EQUIPMENT / PAPER DOLL")
    if not bool(equipment.get("known", false)):
        _append_line("Equipment unavailable", 14)
    else:
        for row_value: Variant in equipment.get("slots", []):
            if typeof(row_value) != TYPE_DICTIONARY:
                continue
            _append_equipment_slot_row(row_value as Dictionary)

    _append_heading("PROTECTION / CLOTHING")
    var protection: Dictionary = equipment.get("protection", {})
    if not bool(protection.get("known", false)):
        _append_line("Protection totals unavailable", 14)
        return
    _append_line("Bite / Cut Armor: %d / 100" % int(protection.get("bite_cut_armor", 0)), 14)
    _append_line("Blunt / Ballistic Armor: %d / 100" % int(protection.get("blunt_ballistic_armor", 0)), 14)
    _append_line("Water Resistance: %d / 100" % int(protection.get("water_resistance", 0)), 14)
    _append_line("Insulation (thermal / comfort): %d / 100" % int(protection.get("insulation", 0)), 14)

func _append_equipment_slot_row(row: Dictionary) -> void:
    var label := String(row.get("label", "Unknown"))
    if bool(row.get("empty", true)):
        _append_line("%s: Empty" % label, 14)
        return
    var item := {
        "item_id": String(row.get("item_id", "")),
        "semantic_type": StringName(row.get("semantic_type", &"")),
        "label": String(row.get("item_label", "Unknown Item")),
        "valid": bool(row.get("valid", false)),
        "reason": "" if bool(row.get("valid", false)) else "equipment_item_missing",
        "weight_known": false,
        "weight_grams": 0,
        "children": [],
    }
    _append_inventory_item_row(item, "%s: %s" % [label, String(item.get("label", "Unknown Item"))], 0, 14)

func _append_inventory_transfer_actions(result: Dictionary, item_id: String) -> void:
    _append_flashlight_toggle_action(item_id)
    var selected := _inventory_entry_by_id(result, item_id)
    var semantic := StringName(selected.get("semantic_type", &""))
    var current_slot := _equipment_slot_for_item(result, item_id)
    if current_slot >= 0:
        if semantic != ActorEquipmentProfileCatalog.SKATEBOARD:
            _append_inventory_action_button("STOW", "stow", item_id, current_slot)
        _append_inventory_action_button("DROP", "drop_hand", item_id, current_slot)
        return

    for slot: int in _equipment_profiles.allowed_slots(semantic):
        _append_inventory_action_button(
            _slot_action_label(slot),
            "equip",
            item_id,
            slot,
            _equipment_slot_occupied(result, slot)
        )
    _append_inventory_action_button("DROP", "drop_container", item_id, -1)

func _hand_slot_for_item(result: Dictionary, item_id: String) -> int:
    return _equipment_slot_for_item(result, item_id)

func _inventory_entry_by_id(result: Dictionary, item_id: String) -> Dictionary:
    var found := super._inventory_entry_by_id(result, item_id)
    if not found.is_empty():
        return found
    var key := item_id.strip_edges()
    if key.is_empty():
        return {}
    var equipment: Dictionary = result.get("equipment", {})
    for row_value: Variant in equipment.get("slots", []):
        if typeof(row_value) != TYPE_DICTIONARY:
            continue
        var row: Dictionary = row_value
        if String(row.get("item_id", "")) != key:
            continue
        return {
            "item_id": key,
            "semantic_type": StringName(row.get("semantic_type", &"")),
            "label": String(row.get("item_label", "Unknown Item")),
            "valid": bool(row.get("valid", false)),
            "reason": "" if bool(row.get("valid", false)) else "equipment_item_missing",
            "weight_known": false,
            "weight_grams": 0,
            "children": [],
        }
    return {}

func _equipment_slot_for_item(result: Dictionary, item_id: String) -> int:
    var equipment: Dictionary = result.get("equipment", {})
    for row_value: Variant in equipment.get("slots", []):
        if typeof(row_value) != TYPE_DICTIONARY:
            continue
        var row: Dictionary = row_value
        if String(row.get("item_id", "")) == item_id:
            return int(row.get("slot", -1))
    return -1

func _equipment_slot_occupied(result: Dictionary, slot: int) -> bool:
    var equipment: Dictionary = result.get("equipment", {})
    for row_value: Variant in equipment.get("slots", []):
        if typeof(row_value) != TYPE_DICTIONARY:
            continue
        var row: Dictionary = row_value
        if int(row.get("slot", -1)) == slot:
            return not bool(row.get("empty", true))
    return true

static func _slot_action_label(slot: int) -> String:
    match slot:
        Slots.Value.PRIMARY_RIGHT: return "RIGHT HAND"
        Slots.Value.SECONDARY_LEFT: return "LEFT HAND"
        Slots.Value.BACK: return "EQUIP BACK"
        Slots.Value.HEAD: return "WEAR HEAD"
        Slots.Value.TORSO: return "WEAR TORSO"
        Slots.Value.LEGS: return "WEAR LEGS"
        Slots.Value.FEET: return "WEAR FEET"
        Slots.Value.HANDS: return "WEAR HANDS"
        _: return "EQUIP"
