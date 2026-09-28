extends CanonicalPlayerShell
class_name TurnBasedPlayerShell

## Slice 6 compatibility surface: presentation stays in the established phone shell,
## while EAT/DRINK execution is delegated to the canonical simple-turn game owner.
var _simple_consume: Callable = Callable()

func configure_simple_contextual_consume(callback: Callable) -> bool:
    if not callback.is_valid():
        return false
    _simple_consume = callback
    return true

func _consume_selected_inventory_item() -> void:
    var item_id: String = _selected_inventory_item_id
    var offer: Dictionary = _inventory_consumption_offer(item_id)
    if not bool(offer.get("available", false)):
        _inventory_status = "Item can no longer be used."
        _render_inventory()
        return
    if _pause_was_active:
        _inventory_status = "Resume before using inventory actions."
        _render_inventory()
        return
    if not _simple_consume.is_valid():
        _inventory_status = "Item action unavailable."
        _render_inventory()
        return
    var label: String = String(offer.get("label", "USE")).capitalize()
    close_modal()
    var result: Dictionary = _simple_consume.call(item_id)
    if bool(result.get("success", false)):
        _inventory_status = "%s complete." % label
        _selected_inventory_item_id = ""
    else:
        _inventory_status = "%s failed: %s." % [label, String(result.get("reason", "action rejected")).replace("_", " ")]
    open_inventory()
