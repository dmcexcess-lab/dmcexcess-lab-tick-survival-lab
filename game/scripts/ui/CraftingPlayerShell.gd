extends CanonicalPlayerShell
class_name CraftingPlayerShell

## Phase-2 additive shell surface. Existing Stats/Inventory/Menu ownership remains in
## System 16; this child adds the System-32 route and, when the live summary exposes
## System 34, presents the approved positive-condition model and derived modifiers.

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

func _render_stats() -> void:
    var result: Dictionary = _stats_query.query(_actor_id)
    var status: Dictionary = result.get("status", {})
    if not bool(result.get("ok", false)) or not bool(status.get("system34", false)):
        super._render_stats()
        return

    _last_result = result.duplicate(true)
    _last_lines = []
    _append_heading("CONDITION")
    _append_line("Stance: %s" % String(result.get("stance_label", "Unknown")), 15)
    _append_line(
        "Health %d / %d   •   Fatigue %d / 100" % [
            int(status.get("current_hp", -1)),
            int(status.get("max_hp", -1)),
            int(status.get("fatigue", -1)),
        ],
        15
    )
    _append_line(
        "Fed %d   •   Hydration %d   •   Rest %d" % [
            int(status.get("satiety", -1)),
            int(status.get("hydration", -1)),
            int(status.get("rest", -1)),
        ],
        14
    )
    _append_line(
        "Fun %d   •   Comfort %d   •   Calm %d" % [
            int(status.get("engagement", -1)),
            int(status.get("comfort", -1)),
            int(status.get("calm", -1)),
        ],
        14
    )
    _append_line(
        "Carry %s / %s kg" % [
            _kg_text(int(status.get("carry_weight_grams", -1))),
            _kg_text(int(status.get("carry_capacity_grams", -1))),
        ],
        14
    )
    var moods: Array = status.get("moodlet_labels", [])
    _append_line("Moodlets: %s" % ("None" if moods.is_empty() else _join_values(moods)), 14)

    var modifiers: Dictionary = status.get("condition_modifiers", {})
    _append_heading("CONDITION EFFECTS")
    _append_line(
        "Max Health %s   •   Fatigue Gain %s   •   Speed %s" % [
            _multiplier_text(int(modifiers.get("health_multiplier_bp", 10000))),
            _multiplier_text(int(modifiers.get("fatigue_gain_multiplier_bp", 10000))),
            _multiplier_text(int(modifiers.get("speed_multiplier_bp", 10000))),
        ],
        14
    )
    _append_line(
        "Carry %s   •   Melee Damage %s" % [
            _multiplier_text(int(modifiers.get("carry_multiplier_bp", 10000))),
            _multiplier_text(int(modifiers.get("melee_damage_multiplier_bp", 10000))),
        ],
        14
    )

    _append_heading("INJURIES")
    var injuries: Array = result.get("injuries", [])
    if injuries.is_empty():
        _append_line("None", 14)
    else:
        for injury_value: Variant in injuries:
            var injury: Dictionary = injury_value
            var treatment: Array[String] = []
            if bool(injury.get("stabilized", false)):
                treatment.append("Stabilized")
            if bool(injury.get("treated", false)):
                treatment.append("Treated")
            var suffix: String = "" if treatment.is_empty() else " • %s" % ", ".join(treatment)
            _append_line(
                "%s — %s — %s%s" % [
                    String(injury.get("injury_label", "Unknown")),
                    String(injury.get("body_region_label", "Unknown")),
                    String(injury.get("severity_label", "Unknown")),
                    suffix,
                ],
                14
            )

    _append_heading("SKILLS")
    for skill_value: Variant in result.get("skills", []):
        var skill: Dictionary = skill_value
        var skill_text: String
        if bool(skill.get("max_level", false)):
            skill_text = "%s — Level %d • MAX" % [String(skill.get("label", "Unknown")), int(skill.get("level", -1))]
        else:
            skill_text = "%s — Level %d • %d/%d XP" % [
                String(skill.get("label", "Unknown")),
                int(skill.get("level", -1)),
                int(skill.get("xp", -1)),
                int(skill.get("next_level_xp", -1)),
            ]
        _append_line(skill_text, 14)

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

static func _multiplier_text(multiplier_bp: int) -> String:
    var delta_bp: int = multiplier_bp - 10000
    if delta_bp == 0:
        return "normal"
    var sign: String = "+" if delta_bp > 0 else ""
    return "%s%.1f%%" % [sign, float(delta_bp) / 100.0]
