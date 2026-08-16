extends RefCounted
class_name TickKernel

const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const ActionClass = preload("res://scripts/foundation/time/TimedAction.gd")
const EventClass = preload("res://scripts/foundation/time/ScheduledEvent.gd")
const QueueClass = preload("res://scripts/foundation/time/TickEventQueue.gd")

## Authoritative simulation clock/scheduler. Owns WHEN, never gameplay meaning.

signal external_event_due(event)
signal action_started(action)
signal action_phase(action, phase)
signal action_interrupted(action)
signal action_finished(action)
signal decision_required(actor_id, world_tick)
signal world_tick_advanced(previous_tick, new_tick)
signal hard_pause_changed(paused)
signal timing_state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _world_tick: int = 0
var _next_event_serial: int = 1
var _next_action_serial: int = 1
var _queue: TickEventQueue = QueueClass.new()
var _active_actions: Dictionary = {}
var _actor_active_action: Dictionary = {}
var _resumable_actions: Dictionary = {}
var _decision_actor_id: String = ""
var _decision_paused: bool = false
var _decision_pending: bool = false
var _hard_paused: bool = false
var _trace: Array = []

func _init(decision_actor_id: String = "") -> void:
    _decision_actor_id = decision_actor_id.strip_edges()
    _decision_paused = not _decision_actor_id.is_empty()

func world_tick() -> int:
    return _world_tick

func is_hard_paused() -> bool:
    return _hard_paused

func is_decision_paused() -> bool:
    return _decision_paused

func decision_actor_id() -> String:
    return _decision_actor_id

func pending_event_count() -> int:
    return _queue.active_count()

func active_action_count() -> int:
    return _active_actions.size()

func set_decision_actor(actor_id: String) -> void:
    var normalized: String = actor_id.strip_edges()
    if normalized == _decision_actor_id:
        return
    _decision_actor_id = normalized
    _decision_pending = false
    if _decision_actor_id.is_empty():
        _decision_paused = false
        _append_trace("decision_actor_cleared")
        return
    if _actor_active_action.has(_decision_actor_id):
        _decision_paused = false
    else:
        _decision_paused = true
        _append_trace("decision_required", {"actor_id": _decision_actor_id})
        decision_required.emit(_decision_actor_id, _world_tick)

func set_hard_paused(paused: bool) -> void:
    if paused == _hard_paused:
        return
    _hard_paused = paused
    _append_trace("hard_pause", {"paused": paused})
    hard_pause_changed.emit(paused)

func schedule_event(
    due_tick: int,
    owner_key: String,
    event_type: StringName,
    subject_id: String = "",
    payload: Dictionary = {},
    priority: int = Rules.DEFAULT_PRIORITY
) -> int:
    if due_tick < _world_tick:
        return 0
    if owner_key.strip_edges().is_empty() or String(event_type).strip_edges().is_empty():
        return 0
    if not Rules.is_safe_payload(payload):
        return 0
    return _schedule_event_record(
        due_tick,
        priority,
        owner_key,
        event_type,
        subject_id,
        payload,
        Rules.EventKind.EXTERNAL,
        0,
        -1
    )

func cancel_event(event_serial: int) -> bool:
    var canceled: bool = _queue.cancel(event_serial)
    if canceled:
        _append_trace("event_canceled", {"event_serial": event_serial})
    return canceled

func begin_action(
    actor_id: String,
    action_type: StringName,
    duration_ticks: int,
    interruption_policy: int = Rules.InterruptionPolicy.COMMITTED,
    phases: Array = [],
    payload: Dictionary = {}
) -> int:
    var normalized_actor: String = actor_id.strip_edges()
    if normalized_actor.is_empty() or String(action_type).strip_edges().is_empty():
        return 0
    if duration_ticks < 1 or not Rules.is_valid_policy(interruption_policy):
        return 0
    if _actor_active_action.has(normalized_actor):
        return 0
    if not Rules.is_safe_payload(payload):
        return 0

    var normalized_phases: Array[ActionPhase] = _normalize_phases(phases, duration_ticks)
    if not phases.is_empty() and normalized_phases.is_empty():
        return 0

    var action_serial: int = _next_action_serial
    _next_action_serial += 1
    var action := ActionClass.new(
        action_serial,
        normalized_actor,
        action_type,
        duration_ticks,
        _world_tick,
        interruption_policy,
        normalized_phases,
        payload
    )
    if not action.is_valid():
        return 0

    _active_actions[action_serial] = action
    _actor_active_action[normalized_actor] = action_serial
    if not _schedule_remaining_action_events(action):
        _active_actions.erase(action_serial)
        _actor_active_action.erase(normalized_actor)
        return 0

    if normalized_actor == _decision_actor_id:
        _decision_paused = false
        _decision_pending = false

    _append_trace("action_started", {"action_serial": action_serial, "actor_id": normalized_actor})
    action_started.emit(_action_view(action))
    return action_serial

func has_active_action(actor_id: String) -> bool:
    return _actor_active_action.has(actor_id)

func active_action_for_actor(actor_id: String) -> TimedAction:
    if not _actor_active_action.has(actor_id):
        return null
    return action_by_serial(int(_actor_active_action[actor_id]))

func action_by_serial(action_serial: int) -> TimedAction:
    var action: TimedAction = _action_ref(action_serial)
    if action == null:
        return null
    return _action_view(action)

func has_resumable_action(action_serial: int) -> bool:
    return _resumable_actions.has(action_serial)

func resumable_action(action_serial: int) -> TimedAction:
    if not _resumable_actions.has(action_serial):
        return null
    var action: TimedAction = _resumable_actions[action_serial]
    return action.copy()

func interrupt_action(action_serial: int, reason: String = "interrupted", forced_failure: bool = false) -> int:
    if not _active_actions.has(action_serial):
        return -1
    var action: TimedAction = _active_actions[action_serial]
    action.sync_to_tick(_world_tick)
    action.reason = reason

    if forced_failure:
        _finish_active_action(action, Rules.ActionStatus.FAILED)
        return Rules.ActionStatus.FAILED

    if action.interruption_policy == Rules.InterruptionPolicy.COMMITTED:
        _append_trace("action_interruption_ignored", {"action_serial": action_serial, "reason": reason})
        action_interrupted.emit(_action_view(action))
        return Rules.ActionStatus.RUNNING

    if action.interruption_policy == Rules.InterruptionPolicy.RESUMABLE:
        _queue.cancel_action_events(action_serial)
        _active_actions.erase(action_serial)
        _actor_active_action.erase(action.actor_id)
        action.status = Rules.ActionStatus.INTERRUPTED
        action.segment_start_tick = -1
        _resumable_actions[action_serial] = action
        _mark_decision_actor_ready(action.actor_id)
        _append_trace("action_interrupted", {"action_serial": action_serial, "reason": reason})
        action_interrupted.emit(action.copy())
        return Rules.ActionStatus.INTERRUPTED

    _finish_active_action(action, Rules.ActionStatus.CANCELED)
    return Rules.ActionStatus.CANCELED

func resume_action(action_serial: int) -> bool:
    if not _resumable_actions.has(action_serial):
        return false
    var action: TimedAction = _resumable_actions[action_serial]
    if action.status != Rules.ActionStatus.INTERRUPTED:
        return false
    if _actor_active_action.has(action.actor_id):
        return false
    if action.elapsed_ticks >= action.duration_ticks:
        return false

    _resumable_actions.erase(action_serial)
    action.status = Rules.ActionStatus.RUNNING
    action.segment_start_tick = _world_tick
    action.reason = ""
    _active_actions[action_serial] = action
    _actor_active_action[action.actor_id] = action_serial
    if not _schedule_remaining_action_events(action):
        _active_actions.erase(action_serial)
        _actor_active_action.erase(action.actor_id)
        action.status = Rules.ActionStatus.INTERRUPTED
        action.segment_start_tick = -1
        _resumable_actions[action_serial] = action
        return false

    if action.actor_id == _decision_actor_id:
        _decision_paused = false
        _decision_pending = false
    _append_trace("action_resumed", {"action_serial": action_serial, "actor_id": action.actor_id})
    action_started.emit(_action_view(action))
    return true

func cancel_action(action_serial: int, reason: String = "canceled") -> bool:
    if _active_actions.has(action_serial):
        var active: TimedAction = _active_actions[action_serial]
        active.sync_to_tick(_world_tick)
        active.reason = reason
        _finish_active_action(active, Rules.ActionStatus.CANCELED)
        return true
    if _resumable_actions.has(action_serial):
        var interrupted: TimedAction = _resumable_actions[action_serial]
        _resumable_actions.erase(action_serial)
        interrupted.status = Rules.ActionStatus.CANCELED
        interrupted.reason = reason
        _mark_decision_actor_ready(interrupted.actor_id)
        _append_trace("action_canceled", {"action_serial": action_serial, "reason": reason})
        action_finished.emit(interrupted.copy())
        return true
    return false

func fail_action(action_serial: int, reason: String = "failed") -> bool:
    if _active_actions.has(action_serial):
        var active: TimedAction = _active_actions[action_serial]
        active.sync_to_tick(_world_tick)
        active.reason = reason
        _finish_active_action(active, Rules.ActionStatus.FAILED)
        return true
    if _resumable_actions.has(action_serial):
        var interrupted: TimedAction = _resumable_actions[action_serial]
        _resumable_actions.erase(action_serial)
        interrupted.status = Rules.ActionStatus.FAILED
        interrupted.reason = reason
        _mark_decision_actor_ready(interrupted.actor_id)
        _append_trace("action_failed", {"action_serial": action_serial, "reason": reason})
        action_finished.emit(interrupted.copy())
        return true
    return false

func run_until_stop(max_operations: int = Rules.DEFAULT_MAX_OPERATIONS) -> int:
    if max_operations < 1:
        return Rules.RunStopReason.SAFETY_LIMIT
    if _hard_paused:
        return Rules.RunStopReason.HARD_PAUSED
    if _decision_paused:
        return Rules.RunStopReason.DECISION_REQUIRED

    var operations: int = 0
    while operations < max_operations:
        if _hard_paused:
            return Rules.RunStopReason.HARD_PAUSED

        var next_event: ScheduledEvent = _queue.peek()
        if next_event == null:
            if _apply_pending_decision_pause():
                return Rules.RunStopReason.DECISION_REQUIRED
            return Rules.RunStopReason.IDLE

        if next_event.due_tick > _world_tick:
            _advance_world_tick(next_event.due_tick)

        while operations < max_operations:
            if _hard_paused:
                return Rules.RunStopReason.HARD_PAUSED
            var current: ScheduledEvent = _queue.peek()
            if current == null or current.due_tick != _world_tick:
                break
            var due: ScheduledEvent = _queue.pop()
            operations += 1
            _dispatch_event(due)

        var same_tick_remaining: ScheduledEvent = _queue.peek()
        if operations >= max_operations and same_tick_remaining != null and same_tick_remaining.due_tick == _world_tick:
            _append_trace("safety_limit", {"operations": operations})
            return Rules.RunStopReason.SAFETY_LIMIT

        if _apply_pending_decision_pause():
            return Rules.RunStopReason.DECISION_REQUIRED

    _append_trace("safety_limit", {"operations": operations})
    return Rules.RunStopReason.SAFETY_LIMIT

func run_next_batch(max_operations: int = Rules.DEFAULT_MAX_OPERATIONS) -> int:
    if max_operations < 1:
        return Rules.RunStopReason.SAFETY_LIMIT
    if _hard_paused:
        return Rules.RunStopReason.HARD_PAUSED
    if _decision_paused:
        return Rules.RunStopReason.DECISION_REQUIRED
    var next_event: ScheduledEvent = _queue.peek()
    if next_event == null:
        if _apply_pending_decision_pause():
            return Rules.RunStopReason.DECISION_REQUIRED
        return Rules.RunStopReason.IDLE
    if next_event.due_tick > _world_tick:
        _advance_world_tick(next_event.due_tick)

    var operations: int = 0
    while operations < max_operations:
        if _hard_paused:
            return Rules.RunStopReason.HARD_PAUSED
        var current: ScheduledEvent = _queue.peek()
        if current == null or current.due_tick != _world_tick:
            break
        var due: ScheduledEvent = _queue.pop()
        operations += 1
        _dispatch_event(due)

    var same_tick_remaining: ScheduledEvent = _queue.peek()
    if operations >= max_operations and same_tick_remaining != null and same_tick_remaining.due_tick == _world_tick:
        _append_trace("safety_limit", {"operations": operations})
        return Rules.RunStopReason.SAFETY_LIMIT
    if _apply_pending_decision_pause():
        return Rules.RunStopReason.DECISION_REQUIRED
    return Rules.RunStopReason.BATCH_COMPLETE

func reset(start_tick: int = 0) -> void:
    _world_tick = maxi(0, start_tick)
    _next_event_serial = 1
    _next_action_serial = 1
    _queue.clear()
    _active_actions.clear()
    _actor_active_action.clear()
    _resumable_actions.clear()
    _hard_paused = false
    _decision_pending = false
    _decision_paused = not _decision_actor_id.is_empty()
    _trace.clear()
    timing_state_reset.emit()

func recent_trace() -> Array:
    return _trace.duplicate(true)

func snapshot() -> Dictionary:
    var active_entries: Array = []
    var active_serials: Array[int] = []
    for key: Variant in _active_actions.keys():
        active_serials.append(int(key))
    active_serials.sort()
    for serial: int in active_serials:
        var action: TimedAction = _active_actions[serial]
        var normalized: TimedAction = _action_view(action)
        active_entries.append(normalized.to_snapshot())

    var resumable_entries: Array = []
    var resumable_serials: Array[int] = []
    for key: Variant in _resumable_actions.keys():
        resumable_serials.append(int(key))
    resumable_serials.sort()
    for serial: int in resumable_serials:
        var action: TimedAction = _resumable_actions[serial]
        resumable_entries.append(action.to_snapshot())

    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "world_tick": _world_tick,
        "next_event_serial": _next_event_serial,
        "next_action_serial": _next_action_serial,
        "decision_actor_id": _decision_actor_id,
        "decision_paused": _decision_paused,
        "hard_paused": _hard_paused,
        "active_actions": active_entries,
        "resumable_actions": resumable_entries,
        "events": _queue.snapshot_entries(),
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false

    var restored_tick: int = int(data.get("world_tick", -1))
    var restored_next_event: int = int(data.get("next_event_serial", 0))
    var restored_next_action: int = int(data.get("next_action_serial", 0))
    if restored_tick < 0 or restored_next_event < 1 or restored_next_action < 1:
        return false

    var active_value: Variant = data.get("active_actions", [])
    var resumable_value: Variant = data.get("resumable_actions", [])
    var events_value: Variant = data.get("events", [])
    if typeof(active_value) != TYPE_ARRAY or typeof(resumable_value) != TYPE_ARRAY or typeof(events_value) != TYPE_ARRAY:
        return false

    var restored_active: Dictionary = {}
    var restored_actor_active: Dictionary = {}
    var restored_resumable: Dictionary = {}
    var max_action_serial: int = 0

    for value: Variant in active_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var action: TimedAction = ActionClass.from_snapshot(value)
        if action == null or action.status != Rules.ActionStatus.RUNNING:
            return false
        if action.segment_start_tick != restored_tick:
            return false
        if restored_active.has(action.serial) or restored_resumable.has(action.serial):
            return false
        if restored_actor_active.has(action.actor_id):
            return false
        restored_active[action.serial] = action
        restored_actor_active[action.actor_id] = action.serial
        max_action_serial = maxi(max_action_serial, action.serial)

    for value: Variant in resumable_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var action: TimedAction = ActionClass.from_snapshot(value)
        if action == null or action.status != Rules.ActionStatus.INTERRUPTED:
            return false
        if restored_active.has(action.serial) or restored_resumable.has(action.serial):
            return false
        restored_resumable[action.serial] = action
        max_action_serial = maxi(max_action_serial, action.serial)

    var restored_queue: TickEventQueue = QueueClass.new()
    var restored_events: Array[ScheduledEvent] = []
    var max_event_serial: int = 0
    for value: Variant in events_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var event: ScheduledEvent = EventClass.from_snapshot(value, restored_tick)
        if event == null or not restored_queue.push(event):
            return false
        restored_events.append(event)
        max_event_serial = maxi(max_event_serial, event.serial)

    if restored_next_action <= max_action_serial or restored_next_event <= max_event_serial:
        return false
    if not _validate_restored_action_events(restored_tick, restored_active, restored_events):
        return false

    var restored_decision_actor: String = String(data.get("decision_actor_id", "")).strip_edges()
    var restored_decision_paused: bool = bool(data.get("decision_paused", false))
    var restored_hard_paused: bool = bool(data.get("hard_paused", false))
    if restored_decision_actor.is_empty() and restored_decision_paused:
        return false
    if restored_decision_paused and restored_actor_active.has(restored_decision_actor):
        return false

    _world_tick = restored_tick
    _next_event_serial = restored_next_event
    _next_action_serial = restored_next_action
    _queue = restored_queue
    _active_actions = restored_active
    _actor_active_action = restored_actor_active
    _resumable_actions = restored_resumable
    _decision_actor_id = restored_decision_actor
    _decision_paused = restored_decision_paused
    _hard_paused = restored_hard_paused
    _decision_pending = (
        not _decision_actor_id.is_empty()
        and not _decision_paused
        and not _actor_active_action.has(_decision_actor_id)
    )
    _trace.clear()
    timing_state_reset.emit()
    return true

func _normalize_phases(values: Array, duration_ticks: int) -> Array[ActionPhase]:
    var normalized: Array[ActionPhase] = []
    for value: Variant in values:
        if not (value is ActionPhase):
            return []
        var phase: ActionPhase = value
        if not phase.is_valid(duration_ticks):
            return []
        normalized.append(phase.copy())
    normalized.sort_custom(ActionPhase.less)
    var previous_offset: int = 0
    for phase: ActionPhase in normalized:
        if phase.offset_ticks <= previous_offset:
            return []
        previous_offset = phase.offset_ticks
    return normalized

func _schedule_remaining_action_events(action: TimedAction) -> bool:
    if action == null or action.status != Rules.ActionStatus.RUNNING:
        return false
    var scheduled_serials: Array[int] = []
    for index in range(action.next_phase_index, action.phases.size()):
        var phase: ActionPhase = action.phases[index]
        var remaining_to_phase: int = phase.offset_ticks - action.elapsed_ticks
        if remaining_to_phase < 0:
            _cancel_serials(scheduled_serials)
            return false
        var event_serial: int = _schedule_event_record(
            _world_tick + remaining_to_phase,
            Rules.DEFAULT_PRIORITY,
            action.actor_id,
            &"when.action_phase",
            action.actor_id,
            {},
            Rules.EventKind.ACTION_PHASE,
            action.serial,
            index
        )
        if event_serial == 0:
            _cancel_serials(scheduled_serials)
            return false
        scheduled_serials.append(event_serial)

    var remaining_to_completion: int = action.duration_ticks - action.elapsed_ticks
    if remaining_to_completion < 1:
        _cancel_serials(scheduled_serials)
        return false
    var completion_serial: int = _schedule_event_record(
        _world_tick + remaining_to_completion,
        Rules.DEFAULT_PRIORITY,
        action.actor_id,
        &"when.action_complete",
        action.actor_id,
        {},
        Rules.EventKind.ACTION_COMPLETE,
        action.serial,
        -1
    )
    if completion_serial == 0:
        _cancel_serials(scheduled_serials)
        return false
    return true

func _cancel_serials(serials: Array[int]) -> void:
    for serial: int in serials:
        _queue.cancel(serial)

func _schedule_event_record(
    due_tick: int,
    priority: int,
    owner_key: String,
    event_type: StringName,
    subject_id: String,
    payload: Dictionary,
    kind: int,
    action_serial: int,
    phase_index: int
) -> int:
    var event_serial: int = _next_event_serial
    _next_event_serial += 1
    var event := EventClass.new(
        event_serial,
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
    if not event.is_valid(_world_tick, true) or not _queue.push(event):
        return 0
    return event_serial

func _dispatch_event(event: ScheduledEvent) -> void:
    if event == null:
        return
    _append_trace("event_due", {
        "event_serial": event.serial,
        "event_type": String(event.event_type),
        "owner_key": event.owner_key,
    })
    match event.kind:
        Rules.EventKind.EXTERNAL:
            external_event_due.emit(event.copy())
        Rules.EventKind.ACTION_PHASE:
            _dispatch_action_phase(event)
        Rules.EventKind.ACTION_COMPLETE:
            _dispatch_action_completion(event)

func _dispatch_action_phase(event: ScheduledEvent) -> void:
    if not _active_actions.has(event.action_serial):
        return
    var action: TimedAction = _active_actions[event.action_serial]
    if event.phase_index != action.next_phase_index:
        return
    if event.phase_index < 0 or event.phase_index >= action.phases.size():
        return
    action.sync_to_tick(_world_tick)
    var phase: ActionPhase = action.phases[event.phase_index]
    if action.elapsed_ticks < phase.offset_ticks:
        return
    action.next_phase_index += 1
    _append_trace("action_phase", {
        "action_serial": action.serial,
        "phase_id": String(phase.phase_id),
    })
    action_phase.emit(_action_view(action), phase.copy())

func _dispatch_action_completion(event: ScheduledEvent) -> void:
    if not _active_actions.has(event.action_serial):
        return
    var action: TimedAction = _active_actions[event.action_serial]
    action.sync_to_tick(_world_tick)
    if action.elapsed_ticks < action.duration_ticks:
        return
    action.elapsed_ticks = action.duration_ticks
    _finish_active_action(action, Rules.ActionStatus.COMPLETED)

func _finish_active_action(action: TimedAction, final_status: int) -> void:
    if action == null or not _active_actions.has(action.serial):
        return
    _queue.cancel_action_events(action.serial)
    _active_actions.erase(action.serial)
    _actor_active_action.erase(action.actor_id)
    action.status = final_status
    action.segment_start_tick = -1
    _mark_decision_actor_ready(action.actor_id)
    var kind: String = "action_finished"
    if final_status == Rules.ActionStatus.CANCELED:
        kind = "action_canceled"
    elif final_status == Rules.ActionStatus.FAILED:
        kind = "action_failed"
    _append_trace(kind, {"action_serial": action.serial, "actor_id": action.actor_id})
    action_finished.emit(action.copy())

func _mark_decision_actor_ready(actor_id: String) -> void:
    if not _decision_actor_id.is_empty() and actor_id == _decision_actor_id:
        _decision_pending = true

func _apply_pending_decision_pause() -> bool:
    if _decision_actor_id.is_empty() or not _decision_pending:
        return false
    if _actor_active_action.has(_decision_actor_id):
        _decision_pending = false
        return false
    _decision_pending = false
    _decision_paused = true
    _append_trace("decision_required", {"actor_id": _decision_actor_id})
    decision_required.emit(_decision_actor_id, _world_tick)
    return true

func _advance_world_tick(new_tick: int) -> void:
    if new_tick <= _world_tick:
        return
    var previous: int = _world_tick
    _world_tick = new_tick
    _append_trace("tick_advanced", {"from": previous, "to": new_tick})
    world_tick_advanced.emit(previous, new_tick)

func _action_ref(action_serial: int) -> TimedAction:
    if _active_actions.has(action_serial):
        return _active_actions[action_serial]
    if _resumable_actions.has(action_serial):
        return _resumable_actions[action_serial]
    return null

func _action_view(action: TimedAction) -> TimedAction:
    if action == null:
        return null
    var view: TimedAction = action.copy()
    view.sync_to_tick(_world_tick)
    return view

func _append_trace(kind: String, details: Dictionary = {}) -> void:
    var entry: Dictionary = {
        "tick": _world_tick,
        "kind": kind,
    }
    for key: Variant in details.keys():
        entry[key] = details[key]
    _trace.append(entry)
    while _trace.size() > Rules.TRACE_LIMIT:
        _trace.pop_front()

func _validate_restored_action_events(
    restored_tick: int,
    restored_active: Dictionary,
    restored_events: Array[ScheduledEvent]
) -> bool:
    var phase_keys: Dictionary = {}
    var completion_keys: Dictionary = {}

    for event: ScheduledEvent in restored_events:
        if event.kind == Rules.EventKind.EXTERNAL:
            continue
        if not restored_active.has(event.action_serial):
            return false
        var action: TimedAction = restored_active[event.action_serial]
        if event.owner_key != action.actor_id or event.subject_id != action.actor_id:
            return false
        if event.kind == Rules.EventKind.ACTION_PHASE:
            if event.phase_index < action.next_phase_index or event.phase_index >= action.phases.size():
                return false
            var phase: ActionPhase = action.phases[event.phase_index]
            var expected_due: int = restored_tick + (phase.offset_ticks - action.elapsed_ticks)
            if expected_due < restored_tick or event.due_tick != expected_due:
                return false
            var phase_key: String = "%d:%d" % [action.serial, event.phase_index]
            if phase_keys.has(phase_key):
                return false
            phase_keys[phase_key] = true
        elif event.kind == Rules.EventKind.ACTION_COMPLETE:
            var expected_completion: int = restored_tick + (action.duration_ticks - action.elapsed_ticks)
            if expected_completion < restored_tick or event.due_tick != expected_completion:
                return false
            var completion_key: String = str(action.serial)
            if completion_keys.has(completion_key):
                return false
            completion_keys[completion_key] = true

    for key: Variant in restored_active.keys():
        var action: TimedAction = restored_active[key]
        for index in range(action.next_phase_index, action.phases.size()):
            var required_phase_key: String = "%d:%d" % [action.serial, index]
            if not phase_keys.has(required_phase_key):
                return false
        if not completion_keys.has(str(action.serial)):
            return false
    return true
