extends RefCounted
class_name TickScheduler

var world_tick: int = 0
var action_serial: int = 0
var last_action: Dictionary = {}

func reset(start_tick: int = 0) -> void:
    world_tick = maxi(0, start_tick)
    action_serial = 0
    last_action = {}

func commit_action(actor_id: String, action_id: String, cost: int, payload: Dictionary = {}) -> Dictionary:
    var safe_cost: int = maxi(0, cost)
    var start_tick: int = world_tick
    world_tick += safe_cost
    action_serial += 1
    last_action = {
        "serial": action_serial,
        "actor_id": actor_id,
        "action_id": action_id,
        "cost": safe_cost,
        "start_tick": start_tick,
        "end_tick": world_tick,
        "payload": payload.duplicate(true),
    }
    return last_action.duplicate(true)

func snapshot() -> Dictionary:
    return {
        "world_tick": world_tick,
        "action_serial": action_serial,
        "last_action": last_action.duplicate(true),
    }
