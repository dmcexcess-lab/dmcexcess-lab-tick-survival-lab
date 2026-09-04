extends RefCounted
class_name FlashlightToggleActionService

const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")

## Exact-item flashlight switch action. The switch is only operable while the physical
## flashlight is in one of the actor's hands. The durable switch state remains owned by
## FlashlightItemState when the item is later stowed or re-equipped.

const FLASHLIGHT_SEMANTIC: StringName = &"item.tool.flashlight"
const ACTION_TOGGLE: StringName = &"item.flashlight_toggle"
const DURATION_TICKS: int = 1

var _world: WorldState = null
var _hands: ActorHandEquipmentState = null
var _state: FlashlightItemState = null
var _kernel: TickKernel = null
var _outcomes: Dictionary = {}

func _init(
    world_state: WorldState = null,
    hand_state: ActorHandEquipmentState = null,
    flashlight_state: FlashlightItemState = null,
    kernel: TickKernel = null
) -> void:
    _world = world_state
    _hands = hand_state
    _state = flashlight_state
    _kernel = kernel
    if _kernel != null:
        var finished_callable := Callable(self, "_on_action_finished")
        if not _kernel.action_finished.is_connected(finished_callable):
            _kernel.action_finished.connect(finished_callable)
    if _world != null:
        var changed_callable := Callable(self, "_on_world_changed")
        if not _world.changed.is_connected(changed_callable):
            _world.changed.connect(changed_callable)

func is_ready() -> bool:
    return _world != null and _hands != null and _state != null and _kernel != null

func toggle_offer(actor_id: String, item_id: String) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    var item: String = item_id.strip_edges()
    if not is_ready() or actor.is_empty():
        return {"available": false, "applicable": false, "reason": "flashlight_actions_unavailable"}
    if item.is_empty() or not _world.has_entity(item):
        return {"available": false, "applicable": false, "reason": "item_missing"}
    var entity: WorldEntityRecord = _world.entity(item)
    if entity == null or entity.semantic_type != FLASHLIGHT_SEMANTIC:
        return {"available": false, "applicable": false, "reason": "item_not_flashlight"}
    var switched_on: bool = _state.is_switched_on(item)
    if not _item_equipped_by(actor, item):
        return {
            "available": false,
            "applicable": true,
            "reason": "item_not_equipped",
            "item_id": item,
            "switched_on": switched_on,
            "label": "TURN OFF" if switched_on else "TURN ON",
        }
    return {
        "available": true,
        "applicable": true,
        "reason": "",
        "item_id": item,
        "switched_on": switched_on,
        "label": "TURN OFF" if switched_on else "TURN ON",
        "duration_ticks": DURATION_TICKS,
    }

func begin_toggle(actor_id: String, item_id: String) -> int:
    var offer: Dictionary = toggle_offer(actor_id, item_id)
    if not bool(offer.get("available", false)):
        return 0
    var target_state: bool = not bool(offer.get("switched_on", false))
    var serial: int = _kernel.begin_action(
        actor_id.strip_edges(),
        ACTION_TOGGLE,
        DURATION_TICKS,
        Rules.InterruptionPolicy.COMMITTED,
        [],
        {
            "item_id": item_id.strip_edges(),
            "target_switched_on": target_state,
        }
    )
    if serial > 0:
        _outcomes[serial] = {
            "finished": false,
            "committed": false,
            "item_id": item_id.strip_edges(),
            "switched_on": not target_state,
            "reason": "pending",
        }
    return serial

func toggle_outcome(action_serial: int) -> Dictionary:
    if not _outcomes.has(action_serial):
        return {}
    return (_outcomes[action_serial] as Dictionary).duplicate(true)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != ACTION_TOGGLE:
        return
    var item_id: String = String(action.payload.get("item_id", "")).strip_edges()
    var target_state: bool = bool(action.payload.get("target_switched_on", false))
    var outcome: Dictionary = {
        "finished": true,
        "committed": false,
        "item_id": item_id,
        "switched_on": _state.is_switched_on(item_id) if _state != null else false,
        "reason": "action_not_completed",
    }
    if action.status == Rules.ActionStatus.COMPLETED:
        var offer: Dictionary = toggle_offer(action.actor_id, item_id)
        if not bool(offer.get("available", false)):
            outcome["reason"] = String(offer.get("reason", "revalidation_failed"))
        elif bool(offer.get("switched_on", false)) == target_state:
            outcome["committed"] = true
            outcome["switched_on"] = target_state
            outcome["reason"] = ""
        elif _state.set_switched_on(item_id, target_state):
            outcome["committed"] = true
            outcome["switched_on"] = target_state
            outcome["reason"] = ""
        else:
            outcome["reason"] = "switch_state_commit_failed"
    _outcomes[action.serial] = outcome

func _item_equipped_by(actor_id: String, item_id: String) -> bool:
    if not _hands.has_actor(actor_id):
        return false
    var assignment: Dictionary = _hands.assignment_for_item(item_id)
    return not assignment.is_empty() and String(assignment.get("actor_id", "")) == actor_id

func _on_world_changed(change: WorldChange) -> void:
    if change != null and change.kind == ChangeClass.Kind.ENTITY_REMOVED and _state != null:
        _state.remove_item(change.entity_id)
