extends RefCounted
class_name TickScheduler

const POLICY_COMMITTED := "committed"
const POLICY_RESUMABLE := "resumable"
const POLICY_CANCELED := "canceled"

const STATUS_READY := "ready"
const STATUS_RUNNING := "running"
const STATUS_COMPLETED := "completed"
const STATUS_INTERRUPTED := "interrupted"
const STATUS_CANCELED := "canceled"
const STATUS_FAILED := "failed"

var world_tick: int = 0
var action_serial: int = 0
var last_action: Dictionary = {}
var active_action: Dictionary = {}
var resumable_action: Dictionary = {}
var player_ready: bool = true
var event_trace: Array = []

func reset(start_tick: int = 0) -> void:
    world_tick = maxi(0, start_tick)
    action_serial = 0
    last_action = {}
    active_action = {}
    resumable_action = {}
    player_ready = true
    event_trace.clear()

func begin_action(actor_id: String, action_id: String, cost: int, interrupt_policy: String = POLICY_COMMITTED, phases: Array = [], payload: Dictionary = {}, resume_state: Dictionary = {}) -> Dictionary:
    if not active_action.is_empty():
        return {}
    var safe_cost: int = maxi(0, cost)
    var elapsed: int = clampi(int(resume_state.get("elapsed_ticks", 0)), 0, safe_cost)
    action_serial += 1
    active_action = {
        "serial": action_serial,
        "actor_id": actor_id,
        "action_id": action_id,
        "cost": safe_cost,
        "start_tick": world_tick,
        "elapsed_ticks": elapsed,
        "remaining_ticks": maxi(0, safe_cost - elapsed),
        "interrupt_policy": _safe_policy(interrupt_policy),
        "phases": phases.duplicate(true),
        "phase_index": 0,
        "phase_id": "",
        "phase_elapsed": 0,
        "status": STATUS_RUNNING,
        "interrupt_reason": "",
        "payload": payload.duplicate(true),
    }
    player_ready = false
    event_trace.clear()
    _update_active_progress()
    event_trace.append({"tick": world_tick, "kind": "action_start", "action_id": action_id})
    return active_action.duplicate(true)

func execute_action(actor_id: String, action_id: String, cost: int, interrupt_policy: String = POLICY_COMMITTED, phases: Array = [], payload: Dictionary = {}, scheduled_actors: Array = [], resume_state: Dictionary = {}) -> Dictionary:
    var started: Dictionary = begin_action(actor_id, action_id, cost, interrupt_policy, phases, payload, resume_state)
    if started.is_empty():
        return {}
    return run_until_player_ready(scheduled_actors)

func run_until_player_ready(scheduled_actors: Array = []) -> Dictionary:
    if active_action.is_empty():
        player_ready = true
        return last_action.duplicate(true)

    var target_tick: int = world_tick + int(active_action.get("remaining_ticks", 0))
    while not active_action.is_empty() and str(active_action.get("status", STATUS_RUNNING)) == STATUS_RUNNING:
        var actor = _next_due_actor(scheduled_actors, target_tick)
        if actor == null:
            break
        var due_tick: int = int(actor.next_tick)
        _advance_active_to(due_tick)
        event_trace.append({"tick": world_tick, "kind": "actor_step", "actor_id": str(actor.actor_id)})
        actor.scheduler_step(world_tick, self)
        if active_action.is_empty() or str(active_action.get("status", STATUS_RUNNING)) != STATUS_RUNNING:
            break

    if not active_action.is_empty() and str(active_action.get("status", STATUS_RUNNING)) == STATUS_RUNNING:
        _advance_active_to(target_tick)
        _finish_active(STATUS_COMPLETED)

    return last_action.duplicate(true)

func notify_damage_interrupt(reason: String = "damage", forced_failure: bool = false) -> String:
    if active_action.is_empty():
        return STATUS_READY
    var policy: String = str(active_action.get("interrupt_policy", POLICY_COMMITTED))
    event_trace.append({"tick": world_tick, "kind": "damage_interrupt", "policy": policy, "reason": reason})
    if forced_failure:
        active_action["interrupt_reason"] = reason
        _finish_active(STATUS_FAILED)
        return STATUS_FAILED
    if policy == POLICY_COMMITTED:
        active_action["interrupt_reason"] = reason
        return STATUS_RUNNING
    active_action["interrupt_reason"] = reason
    if policy == POLICY_RESUMABLE:
        resumable_action = _resume_snapshot(active_action)
        _finish_active(STATUS_INTERRUPTED)
        return STATUS_INTERRUPTED
    _finish_active(STATUS_CANCELED)
    return STATUS_CANCELED

func has_resumable_action(action_id: String = "") -> bool:
    if resumable_action.is_empty():
        return false
    return action_id == "" or str(resumable_action.get("action_id", "")) == action_id

func take_resumable_action(action_id: String = "") -> Dictionary:
    if not has_resumable_action(action_id):
        return {}
    var result: Dictionary = resumable_action.duplicate(true)
    resumable_action = {}
    return result

func commit_action(actor_id: String, action_id: String, cost: int, payload: Dictionary = {}) -> Dictionary:
    return execute_action(actor_id, action_id, cost, POLICY_COMMITTED, [], payload)

func snapshot() -> Dictionary:
    return {
        "world_tick": world_tick,
        "action_serial": action_serial,
        "last_action": last_action.duplicate(true),
        "active_action": active_action.duplicate(true),
        "resumable_action": resumable_action.duplicate(true),
        "player_ready": player_ready,
        "event_trace": event_trace.duplicate(true),
    }

func _safe_policy(value: String) -> String:
    if value in [POLICY_COMMITTED, POLICY_RESUMABLE, POLICY_CANCELED]:
        return value
    return POLICY_COMMITTED

func _next_due_actor(scheduled_actors: Array, target_tick: int):
    var best = null
    var best_tick: int = target_tick + 1
    var best_id: String = ""
    for actor in scheduled_actors:
        if actor == null:
            continue
        var due_tick: int = int(actor.next_tick)
        if due_tick > target_tick:
            continue
        var actor_id: String = str(actor.actor_id)
        if due_tick < best_tick or (due_tick == best_tick and (best == null or actor_id < best_id)):
            best = actor
            best_tick = due_tick
            best_id = actor_id
    return best

func _advance_active_to(new_tick: int) -> void:
    if active_action.is_empty():
        return
    var delta: int = maxi(0, new_tick - world_tick)
    world_tick = maxi(world_tick, new_tick)
    active_action["elapsed_ticks"] = mini(int(active_action.get("cost", 0)), int(active_action.get("elapsed_ticks", 0)) + delta)
    active_action["remaining_ticks"] = maxi(0, int(active_action.get("cost", 0)) - int(active_action.get("elapsed_ticks", 0)))
    _update_active_progress()

func _update_active_progress() -> void:
    if active_action.is_empty():
        return
    var phases: Array = active_action.get("phases", [])
    if phases.is_empty():
        active_action["phase_index"] = 0
        active_action["phase_id"] = str(active_action.get("action_id", ""))
        active_action["phase_elapsed"] = int(active_action.get("elapsed_ticks", 0))
        return
    var elapsed: int = int(active_action.get("elapsed_ticks", 0))
    var cursor: int = 0
    for i in range(phases.size()):
        var phase: Dictionary = phases[i]
        var phase_ticks: int = maxi(0, int(phase.get("ticks", 0)))
        if elapsed < cursor + phase_ticks or i == phases.size() - 1:
            active_action["phase_index"] = i
            active_action["phase_id"] = str(phase.get("id", "phase_%d" % i))
            active_action["phase_elapsed"] = clampi(elapsed - cursor, 0, phase_ticks)
            return
        cursor += phase_ticks

func _resume_snapshot(action: Dictionary) -> Dictionary:
    return {
        "actor_id": str(action.get("actor_id", "")),
        "action_id": str(action.get("action_id", "")),
        "cost": int(action.get("cost", 0)),
        "elapsed_ticks": int(action.get("elapsed_ticks", 0)),
        "interrupt_policy": str(action.get("interrupt_policy", POLICY_RESUMABLE)),
        "phases": action.get("phases", []).duplicate(true),
        "payload": action.get("payload", {}).duplicate(true),
        "phase_index": int(action.get("phase_index", 0)),
        "phase_id": str(action.get("phase_id", "")),
        "phase_elapsed": int(action.get("phase_elapsed", 0)),
    }

func _finish_active(status: String) -> void:
    if active_action.is_empty():
        return
    active_action["status"] = status
    active_action["end_tick"] = world_tick
    last_action = active_action.duplicate(true)
    event_trace.append({"tick": world_tick, "kind": "action_end", "status": status, "action_id": str(active_action.get("action_id", ""))})
    active_action = {}
    player_ready = true
