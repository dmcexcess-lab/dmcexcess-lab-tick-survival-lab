extends Node
class_name CombatPlayerController

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")

signal action_resolved(intent, success, reason, world_tick)
signal action_busy_changed(busy)

var _combat: CombatActionService = null
var _firearms: FirearmActionService = null
var _kernel: TickKernel = null
var _actor_id: String = ""
var _busy: bool = false
var _active_serial: int = 0
var _active_intent: StringName = &""
var _outcomes: Dictionary = {}

func _init(combat: CombatActionService = null, kernel: TickKernel = null, actor_id: String = "", firearms: FirearmActionService = null) -> void:
    _combat = combat
    _firearms = firearms
    _kernel = kernel
    _actor_id = actor_id.strip_edges()
    if _kernel != null: _kernel.action_finished.connect(_on_action_finished)
    set_process(false)

func is_ready() -> bool:
    return _combat != null and _combat.is_ready() and _kernel != null and not _actor_id.is_empty() and (_firearms == null or _firearms.is_ready())

func is_busy() -> bool: return _busy

func submit_intent(intent: StringName) -> void:
    if not is_ready() or intent != Intents.COMBAT_FORWARD or _busy or not _kernel.is_decision_paused(): return
    var result: Dictionary = {}
    if _firearms != null:
        result = _firearms.request_forward(_actor_id)
    if result.is_empty() or String(result.get("reason", "")) == "no_firearm":
        result = _combat.request_forward(_actor_id)
    if not bool(result.get("accepted", false)):
        action_resolved.emit(intent, false, String(result.get("reason", "combat_rejected")), _kernel.world_tick()); return
    var serial := int(result.get("action_serial", 0))
    if serial <= 0:
        action_resolved.emit(intent, false, "combat_action_invalid", _kernel.world_tick()); return
    _active_serial = serial
    _active_intent = intent
    _set_busy(true)
    if is_inside_tree(): set_process(true)
    else:
        _kernel.run_until_stop(); _finish_if_ready()

func _process(_delta: float) -> void:
    if not _busy:
        set_process(false); return
    _kernel.run_next_batch()
    _finish_if_ready()

func _finish_if_ready() -> void:
    if not _busy or not _outcomes.has(_active_serial) or not _kernel.is_decision_paused(): return
    var outcome: Dictionary = _outcomes.get(_active_serial, {})
    action_resolved.emit(_active_intent, bool(outcome.get("success", false)), String(outcome.get("reason", "")), _kernel.world_tick())
    _outcomes.erase(_active_serial)
    _active_serial = 0
    _active_intent = &""
    set_process(false)
    _set_busy(false)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.serial != _active_serial or action.actor_id != _actor_id: return
    _outcomes[action.serial] = {"success": action.status == Rules.ActionStatus.COMPLETED, "reason": action.reason}

func _set_busy(value: bool) -> void:
    if _busy == value: return
    _busy = value
    action_busy_changed.emit(value)
