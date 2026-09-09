extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)

func _run() -> void:
    var shell := EquipmentPlayerShell.new()
    root.add_child(shell)
    await process_frame
    var slot: int = ActorHandSlot.Value.HEAD
    var row := {"slot": slot, "empty": false, "item_id": "old_hat", "valid": true, "semantic_type": &"item.clothing.beanie"}
    var inventory := {"inventory": [{"item_id": "new_hat", "semantic_type": &"item.clothing.baseball_cap", "valid": true}], "equipment": {"slots": [row]}}
    shell._append_inventory_transfer_actions(inventory, "new_hat")
    var blocked := shell._body.get_child(0) as Button
    _check(blocked != null and blocked.disabled and blocked.text == "WEAR HEAD (occupied)", "Occupied action must explain its disabled state")
    var hint := shell._body.get_child(1) as Label
    _check(hint != null and hint.text.contains("STOW or DROP"), "Touch users need visible recovery instructions")
    _check(blocked.custom_minimum_size.y >= 44 and blocked.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "Action must retain touch target and wrap text")
    shell._clear_body()
    shell._append_inventory_transfer_actions(inventory, "old_hat")
    _check((shell._body.get_child(0) as Button).text == "STOW", "Current item must offer stow")
    _check((shell._body.get_child(1) as Button).text == "DROP", "Current item must offer drop")
    shell._clear_body()
    row["empty"] = true
    row["item_id"] = ""
    shell._append_inventory_transfer_actions(inventory, "new_hat")
    var available := shell._body.get_child(0) as Button
    _check(not available.disabled and available.text == "WEAR HEAD", "Freed slot must offer ordinary enabled action")
    _check(available.get_meta("inventory_transfer_action") == "equip" and available.get_meta("inventory_transfer_item_id") == "new_hat", "Available action must retain equip intent and selected item")
    _check(shell._body.get_child_count() == 2, "Free slot must not show stale occupied guidance")
    shell.queue_free()
    await process_frame
    if failures.is_empty():
        print("PROMPT_INVENTORY_FEEDBACK_SMOKE: PASS")
    quit(0 if failures.is_empty() else 1)
