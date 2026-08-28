extends CanonicalPlayerShell
class_name CraftingPlayerShell

## Phase-2 additive shell surface. Existing Stats/Inventory/Menu ownership remains in
## System 16; this child adds only the zero-tick route into the System-32 panel.

signal crafting_open_requested

func _ready() -> void:
    super._ready()
    _reflow_header_for_crafting()
    _add_header_button(
        "CRAFT",
        Vector2(336, 16),
        Vector2(128, 42),
        Callable(self, "_request_crafting"),
        CraftingSemanticUiIconCatalog.SHELL_CRAFT
    )

func _request_crafting() -> void:
    if not is_configured() or active_modal() != MODAL_NONE:
        return
    crafting_open_requested.emit()

func _reflow_header_for_crafting() -> void:
    var stats: Button = _header_buttons.get(String(SemanticUiIconCatalog.SHELL_STATS)) as Button
    var inventory: Button = _header_buttons.get(String(SemanticUiIconCatalog.SHELL_INVENTORY)) as Button
    var menu: Button = _header_buttons.get(String(SemanticUiIconCatalog.SHELL_MENU)) as Button
    if stats != null:
        stats.position = Vector2(16, 16)
        stats.size = Vector2(128, 42)
    if inventory != null:
        inventory.position = Vector2(154, 16)
        inventory.size = Vector2(172, 42)
    if menu != null:
        menu.position = Vector2(474, 16)
        menu.size = Vector2(150, 42)
