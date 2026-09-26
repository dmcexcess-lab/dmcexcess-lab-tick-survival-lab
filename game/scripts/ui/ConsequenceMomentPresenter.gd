extends CanvasLayer
class_name ConsequenceMomentPresenter

## Presentation-only batching for already-resolved same-timestamp consequences.
## Reads canonical signals, never mutates gameplay truth, never advances WHEN.

const PRESENTATION_LAYER: int = 35
const MAX_HISTORY: int = 8

var _kernel: TickKernel = null
var _combat: CombatActionService = null
var _movement: MovementActionService = null
var _health: ActorHealthState = null
var _deaths: ActorDeathTransitionService = null
var _player_id: String = ""
var _infected_ids: Dictionary = {}

var _events_by_tick: Dictionary = {}
var _scheduled_flush_ticks: Dictionary = {}
var _last_presentation: Dictionary = {}
var _history: Array[Dictionary] = []
var _label: Label = null

func _init(
    kernel: TickKernel = null,
    combat: CombatActionService = null,
    movement: MovementActionService = null,
    health: ActorHealthState = null,
    deaths: ActorDeathTransitionService = null,
    player_id: String = ""
) -> void:
    _kernel = kernel
    _combat = combat
    _movement = movement
    _health = health
    _deaths = deaths
    _player_id = player_id.strip_edges()

    if _combat != null:
        _combat.impact_resolved.connect(note_impact)
        _combat.shove_resolved.connect(note_shove)
    if _movement != null:
        _movement.movement_committed.connect(note_movement)
        _movement.physical_pressure_resolved.connect(note_pressure)
    if _deaths != null:
        _deaths.actor_died.connect(note_death)
    if _health != null:
        _health.consequence_batch_finished.connect(_on_consequence_batch_finished)

func _ready() -> void:
    layer = PRESENTATION_LAYER
    _ensure_ui()

func is_configured() -> bool:
    return _kernel != null and _combat != null and _movement != null and _health != null         and _deaths != null and not _player_id.is_empty()

func set_infected_actor_ids(actor_ids: Array[String]) -> void:
    _infected_ids.clear()
    for actor_id: String in actor_ids:
        if not actor_id.strip_edges().is_empty():
            _infected_ids[actor_id] = true

func presentation_snapshot() -> Dictionary:
    return _last_presentation.duplicate(true)

func history_snapshot() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for entry: Dictionary in _history:
        result.append(entry.duplicate(true))
    return result

func note_impact(
    attacker_id: String,
    target_id: String,
    _action_serial: int,
    _strike_cell: Vector2i,
    damage: int,
    _contact_mode: StringName
) -> void:
    # Shove contact also emits impact_resolved with zero damage; shove_resolved
    # owns that presentation so one physical contact cannot become two messages.
    if damage <= 0:
        return
    _record_event({
        "kind": "hit",
        "attacker_id": attacker_id,
        "target_id": target_id,
        "damage": damage,
    })

func note_shove(
    attacker_id: String,
    target_id: String,
    _action_serial: int,
    displaced: bool
) -> void:
    _record_event({
        "kind": "shove",
        "attacker_id": attacker_id,
        "target_id": target_id,
        "displaced": displaced,
    })

func note_movement(
    actor_id: String,
    _action_serial: int,
    _action_type: StringName,
    target_anchor: Vector2i,
    _target_facing: int
) -> void:
    _record_event({
        "kind": "move",
        "actor_id": actor_id,
        "target_anchor": target_anchor,
    })

func note_pressure(
    target_actor_id: String,
    pressure_score: int,
    displaced: bool,
    trapped: bool
) -> void:
    if pressure_score <= 0:
        return
    var tick: int = _kernel.world_tick() if _kernel != null else -1
    if tick < 0:
        return
    var events: Array = _events_by_tick.get(tick, [])
    for index: int in range(events.size()):
        var existing: Variant = events[index]
        if typeof(existing) != TYPE_DICTIONARY:
            continue
        var event: Dictionary = existing
        if String(event.get("kind", "")) != "pressure"             or String(event.get("target_id", "")) != target_actor_id:
            continue
        event["pressure_score"] = maxi(int(event.get("pressure_score", 0)), pressure_score)
        event["displaced"] = bool(event.get("displaced", false)) or displaced
        event["trapped"] = bool(event.get("trapped", false)) or trapped
        events[index] = event
        _events_by_tick[tick] = events
        _queue_flush(tick)
        return
    _record_event({
        "kind": "pressure",
        "target_id": target_actor_id,
        "pressure_score": pressure_score,
        "displaced": displaced,
        "trapped": trapped,
    })

func note_death(actor_id: String, _corpse_id: String) -> void:
    _record_event({
        "kind": "death",
        "actor_id": actor_id,
    })

func _record_event(event: Dictionary) -> void:
    if _kernel == null or event.is_empty():
        return
    var tick: int = _kernel.world_tick()
    var events: Array = _events_by_tick.get(tick, [])
    var key: String = _event_key(event)
    for existing_value: Variant in events:
        if typeof(existing_value) == TYPE_DICTIONARY and _event_key(existing_value as Dictionary) == key:
            return
    events.append(event.duplicate(true))
    _events_by_tick[tick] = events
    _queue_flush(tick)

func _queue_flush(tick: int) -> void:
    if _health != null and _health.consequence_batch_active():
        return
    if _scheduled_flush_ticks.has(tick):
        return
    _scheduled_flush_ticks[tick] = true
    call_deferred("_flush_tick", tick)

func _on_consequence_batch_finished() -> void:
    if _kernel == null:
        return
    _flush_tick(_kernel.world_tick())

func _flush_tick(tick: int) -> void:
    _scheduled_flush_ticks.erase(tick)
    var events_value: Variant = _events_by_tick.get(tick, [])
    _events_by_tick.erase(tick)
    if typeof(events_value) != TYPE_ARRAY:
        return
    var events: Array = events_value
    if events.is_empty():
        return

    var non_move_count: int = 0
    for value: Variant in events:
        if typeof(value) == TYPE_DICTIONARY and String((value as Dictionary).get("kind", "")) != "move":
            non_move_count += 1
    if non_move_count == 0 and events.size() < 2:
        return

    var text_value: String = _summary_for(events, tick)
    if text_value.is_empty():
        return
    _last_presentation = {
        "tick": tick,
        "text": text_value,
        "event_count": events.size(),
        "events": events.duplicate(true),
    }
    _history.append(_last_presentation.duplicate(true))
    while _history.size() > MAX_HISTORY:
        _history.pop_front()
    _ensure_ui()
    if _label != null:
        _label.text = text_value
        _label.visible = true

func _summary_for(events: Array, tick: int) -> String:
    var hits: Array[Dictionary] = []
    var shoves: Array[Dictionary] = []
    var pressures: Array[Dictionary] = []
    var moves: Array[Dictionary] = []
    var deaths: Array[String] = []

    for value: Variant in events:
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var event: Dictionary = value
        match String(event.get("kind", "")):
            "hit":
                hits.append(event)
            "shove":
                shoves.append(event)
            "pressure":
                pressures.append(event)
            "move":
                moves.append(event)
            "death":
                var actor_id: String = String(event.get("actor_id", ""))
                if not actor_id.is_empty() and actor_id not in deaths:
                    deaths.append(actor_id)

    var parts := PackedStringArray()
    if hits.size() == 2         and String(hits[0].get("attacker_id", "")) == String(hits[1].get("target_id", ""))         and String(hits[1].get("attacker_id", "")) == String(hits[0].get("target_id", "")):
        parts.append("%s ↔ %s hit each other (%d/%d)" % [
            _actor_label(String(hits[0].get("attacker_id", ""))),
            _actor_label(String(hits[0].get("target_id", ""))),
            int(hits[0].get("damage", 0)),
            int(hits[1].get("damage", 0)),
        ])
    else:
        for hit: Dictionary in hits:
            parts.append("%s hits %s (%d)" % [
                _actor_label(String(hit.get("attacker_id", ""))),
                _actor_label(String(hit.get("target_id", ""))),
                int(hit.get("damage", 0)),
            ])

    for shove: Dictionary in shoves:
        parts.append("%s shoves %s %s" % [
            _actor_label(String(shove.get("attacker_id", ""))),
            _actor_label(String(shove.get("target_id", ""))),
            "back" if bool(shove.get("displaced", false)) else "but they hold",
        ])

    if not pressures.is_empty():
        var shifted: int = 0
        var trapped: int = 0
        for pressure: Dictionary in pressures:
            if bool(pressure.get("displaced", false)):
                shifted += 1
            if bool(pressure.get("trapped", false)):
                trapped += 1
        var pressure_text: String = "crowd pressure"
        if shifted > 0:
            pressure_text += " shifts %d" % shifted
        if trapped > 0:
            pressure_text += "%s traps %d" % ["," if shifted > 0 else "", trapped]
        if shifted == 0 and trapped == 0:
            pressure_text += " holds"
        parts.append(pressure_text)

    var moved_ids: Array[String] = []
    for move: Dictionary in moves:
        var actor_id: String = String(move.get("actor_id", ""))
        if not actor_id.is_empty() and actor_id not in moved_ids:
            moved_ids.append(actor_id)
    if moved_ids.size() >= 2:
        parts.append("%d actors reposition together" % moved_ids.size())
    elif moved_ids.size() == 1 and not parts.is_empty():
        parts.append("%s moves" % _actor_label(moved_ids[0]))

    if deaths.size() == 2 and _contains_player(deaths):
        parts.append("BOTH DOWN")
    else:
        for actor_id: String in deaths:
            parts.append("%s down" % _actor_label(actor_id))

    if parts.is_empty():
        return ""
    var prefix: String = "Tick %d · " % tick
    if events.size() > 1:
        prefix += "SAME MOMENT — "
    return prefix + "; ".join(parts)

func _contains_player(actor_ids: Array[String]) -> bool:
    return _player_id in actor_ids

func _actor_label(actor_id: String) -> String:
    if actor_id == _player_id:
        return "YOU"
    if _infected_ids.has(actor_id):
        return "INFECTED"
    return "ACTOR"

static func _event_key(event: Dictionary) -> String:
    var kind: String = String(event.get("kind", ""))
    match kind:
        "hit":
            return "hit|%s|%s|%d" % [
                String(event.get("attacker_id", "")),
                String(event.get("target_id", "")),
                int(event.get("damage", 0)),
            ]
        "shove":
            return "shove|%s|%s|%s" % [
                String(event.get("attacker_id", "")),
                String(event.get("target_id", "")),
                str(bool(event.get("displaced", false))),
            ]
        "pressure":
            return "pressure|%s" % String(event.get("target_id", ""))
        "move":
            var anchor: Vector2i = event.get("target_anchor", Vector2i.ZERO)
            return "move|%s|%d|%d" % [String(event.get("actor_id", "")), anchor.x, anchor.y]
        "death":
            return "death|%s" % String(event.get("actor_id", ""))
        _:
            return JSON.stringify(event)

func _ensure_ui() -> void:
    if _label != null:
        return
    _label = Label.new()
    _label.name = "ConsequenceMomentLabel"
    _label.anchor_left = 0.05
    _label.anchor_top = 0.72
    _label.anchor_right = 0.95
    _label.anchor_bottom = 0.90
    _label.offset_left = 0.0
    _label.offset_top = 0.0
    _label.offset_right = 0.0
    _label.offset_bottom = 0.0
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.focus_mode = Control.FOCUS_NONE
    _label.add_theme_font_size_override("font_size", 12)
    _label.add_theme_constant_override("outline_size", 5)
    _label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
    _label.visible = false
    add_child(_label)
