extends CanvasLayer
class_name CraftingPanel

## System 32 phone/Safari-first crafting presentation. Browsing is zero-tick UI;
## pressing CRAFT releases this panel's hard pause before requesting the real action.

signal interaction_blocked_changed(blocked: bool)
signal craft_requested(recipe_id: StringName, workstation_id: String)

const VIEW_SIZE := Vector2(640, 844)

var _plans: CraftingPlanQuery = null
var _kernel: TickKernel = null
var _icons: SemanticUiIconCatalog = null
var _skill_checks: ActorSkillCheckService = null
var _actor_id: String = ""
var _workstation_id: String = ""
var _pause_restore_captured: bool = false
var _pause_was_active: bool = false
var _overlay: ColorRect = null
var _body: VBoxContainer = null
var _title: Label = null
var _last_message: String = ""
var _last_snapshot: Dictionary = {}

func _ready() -> void:
    layer = 45
    _build_ui()

func configure(
    plan_query: CraftingPlanQuery,
    kernel: TickKernel,
    actor_id: String,
    icon_catalog: SemanticUiIconCatalog = null,
    skill_check_service: ActorSkillCheckService = null
) -> bool:
    if plan_query == null or not plan_query.is_ready() or kernel == null or actor_id.strip_edges().is_empty():
        return false
    _plans = plan_query
    _kernel = kernel
    _actor_id = actor_id.strip_edges()
    _icons = icon_catalog
    _skill_checks = skill_check_service
    return true

func is_configured() -> bool:
    return _plans != null and _plans.is_ready() and _kernel != null and not _actor_id.is_empty()

func is_open() -> bool:
    return _overlay != null and _overlay.visible

func open_panel(workstation_id: String = "") -> void:
    if not is_configured():
        return
    _workstation_id = workstation_id.strip_edges()
    _acquire_pause()
    if _overlay == null:
        _build_ui()
    _overlay.visible = true
    _render()

func close_panel() -> void:
    if not is_open():
        return
    _overlay.visible = false
    if _pause_restore_captured and _kernel != null:
        _kernel.set_hard_paused(_pause_was_active)
    _pause_restore_captured = false
    interaction_blocked_changed.emit(false)

func present_action_result(
    recipe_id: StringName,
    success: bool,
    reason: String,
    world_tick: int,
    workstation_id: String
) -> void:
    var recipe_value: CraftingRecipe = null if _plans == null else _plans.recipe(recipe_id)
    var label: String = String(recipe_id) if recipe_value == null else recipe_value.label
    if success:
        _last_message = "%s complete at tick %d." % [label, world_tick]
    else:
        _last_message = "%s failed: %s" % [label, reason.replace("_", " ").capitalize()]
    open_panel(workstation_id)

func presentation_snapshot() -> Dictionary:
    return _last_snapshot.duplicate(true)

func _acquire_pause() -> void:
    if _pause_restore_captured:
        return
    _pause_was_active = _kernel.is_hard_paused()
    _pause_restore_captured = true
    _kernel.set_hard_paused(true)
    interaction_blocked_changed.emit(true)

func _build_ui() -> void:
    if _overlay != null:
        return
    _overlay = ColorRect.new()
    _overlay.position = Vector2.ZERO
    _overlay.size = VIEW_SIZE
    _overlay.color = Color(0.0, 0.0, 0.0, 0.9)
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _overlay.visible = false
    add_child(_overlay)

    var outer := MarginContainer.new()
    outer.position = Vector2(18, 64)
    outer.size = Vector2(604, 758)
    outer.add_theme_constant_override("margin_left", 10)
    outer.add_theme_constant_override("margin_right", 10)
    outer.add_theme_constant_override("margin_top", 10)
    outer.add_theme_constant_override("margin_bottom", 10)
    _overlay.add_child(outer)

    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_child(panel)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    panel.add_child(root)

    var header := HBoxContainer.new()
    root.add_child(header)
    _title = Label.new()
    _title.text = "CRAFTING"
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title.add_theme_font_size_override("font_size", 22)
    header.add_child(_title)

    var close := Button.new()
    close.text = "CLOSE"
    close.custom_minimum_size = Vector2(110, 46)
    close.focus_mode = Control.FOCUS_NONE
    close.pressed.connect(close_panel)
    header.add_child(close)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)

    _body = VBoxContainer.new()
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _body.add_theme_constant_override("separation", 10)
    scroll.add_child(_body)

func _render() -> void:
    _clear_body()
    var snapshots: Array = []
    var station: Dictionary = _plans.workstation_context(_workstation_id)
    var capabilities: Array = station.get("capabilities", [])
    _title.text = _panel_title(capabilities)
    if not _last_message.is_empty():
        _append_label(_last_message, 14)
    _append_label(
        "Materials must be in your hands or carried inventory. Nearby floor/container items are never pulled automatically.",
        12
    )

    for recipe_id: StringName in _plans.recipe_ids():
        var recipe_value: CraftingRecipe = _plans.recipe(recipe_id)
        if recipe_value == null:
            continue
        if not _recipe_belongs_in_context(recipe_value, capabilities):
            continue
        var plan: Dictionary = _plans.query(_actor_id, recipe_id, _workstation_id)
        var quote: Dictionary = _skill_quote(recipe_value)
        var snapshot: Dictionary = plan.duplicate(true)
        snapshot["quoted_duration_ticks"] = int(quote.get("duration_ticks", recipe_value.duration_ticks))
        snapshot["skill_id"] = recipe_value.skill_id
        snapshot["skill_level"] = int(quote.get("skill_level", -1))
        snapshot["skill_difficulty"] = recipe_value.skill_difficulty
        snapshot["success_chance_percent"] = int(quote.get("success_chance_percent", 0))
        snapshots.append(snapshot)
        _append_recipe(recipe_value, plan, quote)
    _last_snapshot = {
        "open": is_open(),
        "actor_id": _actor_id,
        "workstation_id": _workstation_id,
        "title": _title.text,
        "workstation_known": bool(station.get("known", false)),
        "workstation_capabilities": capabilities.duplicate(),
        "hard_paused": _kernel.is_hard_paused(),
        "message": _last_message,
        "recipes": snapshots,
    }

func _append_recipe(recipe_value: CraftingRecipe, plan: Dictionary, quote: Dictionary) -> void:
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _body.add_child(card)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 4)
    card.add_child(root)

    var heading := HBoxContainer.new()
    root.add_child(heading)
    var output_semantic: StringName = &""
    if not recipe_value.outputs.is_empty():
        output_semantic = StringName(recipe_value.outputs[0].get("semantic_type", &""))
    if _icons != null and _icons.is_ready() and not String(output_semantic).is_empty():
        var texture: Texture2D = _icons.texture_for(output_semantic)
        if texture != null:
            var icon := TextureRect.new()
            icon.texture = texture
            icon.custom_minimum_size = SemanticUiIconCatalog.DRAW_SIZE
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            heading.add_child(icon)
    var title_label := Label.new()
    var duration_ticks: int = int(quote.get("duration_ticks", recipe_value.duration_ticks))
    title_label.text = "%s — %d ticks" % [recipe_value.label, duration_ticks]
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title_label.add_theme_font_size_override("font_size", 16)
    heading.add_child(title_label)

    _append_to(root, "Consumes: %s" % _requirements_text(recipe_value.consumed_inputs), 12)
    _append_to(root, "Tools: %s" % ("None" if recipe_value.required_tools.is_empty() else _requirements_text(recipe_value.required_tools)), 12)
    if not String(recipe_value.workstation_capability).is_empty():
        _append_to(root, "Workstation: %s" % CraftingWorkstationCatalog.display_label(recipe_value.workstation_capability), 12)
    _append_to(root, "Produces: %s" % _requirements_text(recipe_value.outputs), 12)
    if bool(quote.get("ok", false)):
        _append_to(
            root,
            "%s %d/10 • difficulty %d • %d%% success" % [
                _skill_label(recipe_value.skill_id),
                int(quote.get("skill_level", 0)),
                recipe_value.skill_difficulty,
                int(quote.get("success_chance_percent", 0)),
            ],
            12
        )

    var ready: bool = bool(plan.get("ready", false))
    var reason: String = String(plan.get("reason", ""))
    if ready:
        _append_to(
            root,
            "Ready • carry %s -> %s kg" % [_kg(int(plan.get("current_carry_grams", 0))), _kg(int(plan.get("projected_carry_grams", 0)))],
            12
        )
    else:
        _append_to(root, "Unavailable: %s" % reason.replace("_", " ").replace(":", " — ").capitalize(), 12)

    var button := Button.new()
    button.text = "COOK" if recipe_value.workstation_capability == CraftingWorkstationCatalog.COOKING_STOVE else "CRAFT"
    button.set_meta("crafting_recipe_id", String(recipe_value.recipe_id))
    button.set_meta("crafting_workstation_id", _workstation_id)
    button.disabled = not ready or not bool(quote.get("ok", true))
    button.custom_minimum_size = Vector2(0, 46)
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(_on_craft_pressed.bind(recipe_value.recipe_id))
    root.add_child(button)

func _recipe_belongs_in_context(recipe_value: CraftingRecipe, capabilities: Array) -> bool:
    if recipe_value == null:
        return false
    if _workstation_id.is_empty():
        return String(recipe_value.workstation_capability).is_empty()
    return capabilities.has(recipe_value.workstation_capability)

static func _panel_title(capabilities: Array) -> String:
    if capabilities.has(CraftingWorkstationCatalog.COOKING_STOVE):
        return "COOKING — STOVE"
    if capabilities.has(CraftingWorkstationCatalog.GENERAL_WORKBENCH):
        return "CRAFTING — WORKBENCH"
    return "CRAFTING"

func _skill_quote(recipe_value: CraftingRecipe) -> Dictionary:
    if _skill_checks == null or not _skill_checks.is_ready():
        return {
            "ok": true,
            "duration_ticks": recipe_value.duration_ticks,
            "skill_level": -1,
            "success_chance_percent": 0,
        }
    return _skill_checks.action_profile(
        _actor_id,
        recipe_value.skill_id,
        recipe_value.duration_ticks,
        recipe_value.skill_difficulty
    )

static func _skill_label(skill_id: StringName) -> String:
    var label: String = String(skill_id).replace("_", " ").capitalize()
    return label if not label.is_empty() else "Skill"

func _on_craft_pressed(recipe_id: StringName) -> void:
    var workstation: String = _workstation_id
    _last_message = ""
    close_panel()
    craft_requested.emit(recipe_id, workstation)

func _clear_body() -> void:
    if _body == null:
        return
    for child: Node in _body.get_children():
        _body.remove_child(child)
        child.queue_free()

func _append_label(text_value: String, font_size: int) -> void:
    _append_to(_body, text_value, font_size)

static func _append_to(parent: Node, text_value: String, font_size: int) -> void:
    var label := Label.new()
    label.text = text_value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", font_size)
    parent.add_child(label)

static func _requirements_text(requirements: Array[Dictionary]) -> String:
    var parts := PackedStringArray()
    for requirement: Dictionary in requirements:
        var semantic: String = String(requirement.get("semantic_type", ""))
        var count: int = int(requirement.get("count", 0))
        var label: String = semantic
        if label.begins_with("item."):
            label = label.substr(5)
        label = label.replace("_", " ").replace(".", " ").capitalize()
        parts.append("%dx %s" % [count, label])
    return ", ".join(parts)

static func _kg(grams: int) -> String:
    return "%.1f" % (float(grams) / 1000.0)
