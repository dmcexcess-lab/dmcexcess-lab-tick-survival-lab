extends RefCounted
class_name ScheduledEvent

const Rules = preload("res://scripts/foundation/time/TickRules.gd")

## Serializable deterministic queue record. Mechanic-specific meaning stays opaque.

var serial: int = 0
var due_tick: int = 0
var priority: int = Rules.DEFAULT_PRIORITY
var owner_key: String = ""
var event_type: StringName = &""
var subject_id: String = ""
var payload: Dictionary = {}
var kind: int = Rules.EventKind.EXTERNAL
var action_serial: int = 0
var phase_index: int = -1

func _init(
    event_serial: int = 0,
    event_due_tick: int = 0,
    event_priority: int = Rules.DEFAULT_PRIORITY,
    event_owner_key: String = "",
    semantic_event_type: StringName = &"",
    event_subject_id: String = "",
    event_payload: Dictionary = {},
    event_kind: int = Rules.EventKind.EXTERNAL,
    related_action_serial: int = 0,
    related_phase_index: int = -1
) -> void:
    serial = event_serial
    due_tick = event_due_tick
    priority = event_priority
    owner_key = event_owner_key
    event_type = semantic_event_type
    subject_id = event_subject_id
    payload = Rules.copy_payload(event_payload)
    kind = event_kind
    action_serial = related_action_serial
    phase_index = related_phase_index

func is_valid(minimum_tick: int = -1, allow_internal: bool = true) -> bool:
    if serial < 1 or due_tick < 0:
        return false
    if minimum_tick >= 0 and due_tick < minimum_tick:
        return false
    if owner_key.strip_edges().is_empty():
        return false
    if String(event_type).strip_edges().is_empty():
        return false
    if not Rules.is_safe_payload(payload):
        return false
    if not Rules.is_valid_event_kind(kind):
        return false
    if kind != Rules.EventKind.EXTERNAL and not allow_internal:
        return false
    if kind == Rules.EventKind.EXTERNAL:
        return action_serial == 0 and phase_index == -1
    if action_serial < 1:
        return false
    if kind == Rules.EventKind.ACTION_PHASE:
        return phase_index >= 0
    return phase_index == -1

func copy() -> ScheduledEvent:
    return ScheduledEvent.new(
        serial,
        due_tick,
        priority,
        owner_key,
        event_type,
        subject_id,
        payload,
        kind,
        action_serial,
        phase_index
    )

func to_snapshot() -> Dictionary:
    return {
        "serial": serial,
        "due_tick": due_tick,
        "priority": priority,
        "owner_key": owner_key,
        "event_type": String(event_type),
        "subject_id": subject_id,
        "payload": Rules.copy_payload(payload),
        "kind": kind,
        "action_serial": action_serial,
        "phase_index": phase_index,
    }

static func from_snapshot(data: Dictionary, minimum_tick: int = -1) -> ScheduledEvent:
    var payload_value: Variant = data.get("payload", {})
    if typeof(payload_value) != TYPE_DICTIONARY:
        return null
    var value := ScheduledEvent.new(
        int(data.get("serial", 0)),
        int(data.get("due_tick", -1)),
        int(data.get("priority", Rules.DEFAULT_PRIORITY)),
        String(data.get("owner_key", "")),
        StringName(String(data.get("event_type", ""))),
        String(data.get("subject_id", "")),
        payload_value,
        int(data.get("kind", -1)),
        int(data.get("action_serial", 0)),
        int(data.get("phase_index", -1))
    )
    if not value.is_valid(minimum_tick, true):
        return null
    return value

static func less(a: ScheduledEvent, b: ScheduledEvent) -> bool:
    if a.due_tick != b.due_tick:
        return a.due_tick < b.due_tick
    if a.priority != b.priority:
        return a.priority < b.priority
    if a.owner_key != b.owner_key:
        return a.owner_key < b.owner_key
    return a.serial < b.serial
