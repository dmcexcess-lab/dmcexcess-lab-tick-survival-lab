extends CanvasLayer
class_name BuildingGrammarDevControls

const FixtureClass = preload("res://scripts/demo/RuralDinerCritiqueFixture.gd")
const SeedSessionClass = preload("res://scripts/demo/BuildingGrammarDevSeedSession.gd")

## DEV-only phone-friendly critique control.
## It never mutates an already-materialized world. Pressing it advances the seed and
## reloads the demo so the normal generation -> validation -> materialization path runs fresh.

var _button: Button = null
var _busy: bool = false

func _ready() -> void:
    layer = 21
    _build_button()
    _refresh_label()

func _build_button() -> void:
    _button = Button.new()
    _button.position = Vector2(255, 704)
    _button.size = Vector2(130, 56)
    _button.focus_mode = Control.FOCUS_NONE
    _button.add_theme_font_size_override("font_size", 13)
    _button.pressed.connect(_on_new_building_pressed)
    add_child(_button)

func _refresh_label() -> void:
    if _button == null:
        return
    var current: int = FixtureClass.active_seed()
    _button.text = "NEW BUILDING\nNEXT %d" % (current + 1)

func _on_new_building_pressed() -> void:
    if _busy or _button == null:
        return
    _busy = true
    _button.disabled = true
    var next_seed: int = SeedSessionClass.request_next_building(get_tree(), FixtureClass.DINER_SEED)
    _button.text = "LOADING\nSEED %d" % next_seed
