extends RefCounted
class_name TimedAction

const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")

## Timing state for one committed actor action. Gameplay meaning/effects stay external.

var serial: int = 0
var actor_id: String = ""
var action_type: StringName = &""
var duration_ticks: int = 0
var elapsed_ticks: int = 0
var start_tick: int = 0
var segment_start_tick: int = -1
var status: int = Rules.ActionStatus.RUNNING
var interruption_policy: int = Rules.InterruptionPolicy.COMMITTED
var phases: Array[ActionPhase] = []
var next_phase_index: int = 0
var payload: Dictionary = {}
var reason: String = ""

func _init(
    action_serial: int = 0,
    action_actor_id: String = "",
    semantic_action_type: StringName = &"",
    action_duration_ticks: int = 0,
    action_start_tick: int = 0,
    action_policy: int = Rules.InterruptionPolicy.COMMITTED,
    action_phases: Array = [],
    action_payload: Dictionary = {}
) -> void:
    serial = action_serial
    actor_id = action_actor_id
    action_type = semantic_action_type
    duration_ticks = action_duration_ticks
    start_tick = action_start_tick
    segment_start_tick = action_start_tick
    interruption_policy = action_policy
    payload = Rules.copy_payload(action_payload)
    for value: Variant in action_phases:
        if value is ActionPhase:
            phases.append((value as ActionPhase).copy())
    phases.sort_custom(ActionPhase.less)

func is_valid() -> bool:
    if serial < 1 or actor_id.strip_edges().is_empty():
        return false
    if String(action_type).strip_edges().is_empty():
        return false
    if duration_ticks < 1:
        return false
    if elapsed_ticks < 0 or elapsed_ticks > duration_ticks:
        return false
    if start_tick < 0:
        return false
    if not Rules.is_valid_policy(interruption_policy):
        return false
    if not Rules.is_valid_action_status(status):
        return false
    if status == Rules.ActionStatus.RUNNING and segment_start_tick < 0:
        return false
    if status != Rules.ActionStatus.RUNNING and segment_start_tick != -1:
        return false
    if next_phase_index < 0 or next_phase_index > phases.size():
        return false
    if not Rules.is_safe_payload(payload):
        return false

    var previous_offset: int = 0
    for phase: ActionPhase in phases:
        if phase == null or not phase.is_valid(duration_ticks):
            return false
        if phase.offset_ticks <= previous_offset:
            return false
        previous_offset = phase.offset_ticks
    return true

func progress_at(world_tick: int) -> int:
    if status != Rules.ActionStatus.RUNNING or segment_start_tick < 0:
        return elapsed_ticks
    return mini(duration_ticks, elapsed_ticks + maxi(0, world_tick - segment_start_tick))

func remaining_at(world_tick: int) -> int:
    return maxi(0, duration_ticks - progress_at(world_tick))

func sync_to_tick(world_tick: int) -> void:
    if status != Rules.ActionStatus.RUNNING or segment_start_tick < 0:
        return
    elapsed_ticks = progress_at(world_tick)
    segment_start_tick = world_tick

func copy() -> TimedAction:
    var phase_copies: Array[ActionPhase] = []
    for phase: ActionPhase in phases:
        phase_copies.append(phase.copy())
    var value := TimedAction.new(
        serial,
        actor_id,
        action_type,
        duration_ticks,
        start_tick,
        interruption_policy,
        phase_copies,
        payload
    )
    value.elapsed_ticks = elapsed_ticks
    value.segment_start_tick = segment_start_tick
    value.status = status
    value.next_phase_index = next_phase_index
    value.reason = reason
    return value

func to_snapshot() -> Dictionary:
    var phase_entries: Array = []
    for phase: ActionPhase in phases:
        phase_entries.append(phase.to_snapshot())
    return {
        "serial": serial,
        "actor_id": actor_id,
        "action_type": String(action_type),
        "duration_ticks": duration_ticks,
        "elapsed_ticks": elapsed_ticks,
        "start_tick": start_tick,
        "segment_start_tick": segment_start_tick,
        "status": status,
        "interruption_policy": interruption_policy,
        "phases": phase_entries,
        "next_phase_index": next_phase_index,
        "payload": Rules.copy_payload(payload),
        "reason": reason,
    }

static func from_snapshot(data: Dictionary) -> TimedAction:
    var payload_value: Variant = data.get("payload", {})
    var phases_value: Variant = data.get("phases", [])
    if typeof(payload_value) != TYPE_DICTIONARY or typeof(phases_value) != TYPE_ARRAY:
        return null

    var duration: int = int(data.get("duration_ticks", 0))
    var restored_phases: Array[ActionPhase] = []
    for value: Variant in phases_value:
        if typeof(value) != TYPE_DICTIONARY:
            return null
        var phase: ActionPhase = PhaseClass.from_snapshot(value, duration)
        if phase == null:
            return null
        restored_phases.append(phase)
    restored_phases.sort_custom(ActionPhase.less)

    var action := TimedAction.new(
        int(data.get("serial", 0)),
        String(data.get("actor_id", "")),
        StringName(String(data.get("action_type", ""))),
        duration,
        int(data.get("start_tick", -1)),
        int(data.get("interruption_policy", -1)),
        restored_phases,
        payload_value
    )
    action.elapsed_ticks = int(data.get("elapsed_ticks", -1))
    action.segment_start_tick = int(data.get("segment_start_tick", -2))
    action.status = int(data.get("status", -1))
    action.next_phase_index = int(data.get("next_phase_index", -1))
    action.reason = String(data.get("reason", ""))
    if not action.is_valid():
        return null
    return action
