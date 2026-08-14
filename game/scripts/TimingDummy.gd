extends RefCounted
class_name TimingDummy

var actor_id: String = "timing_dummy"
var interval: int = 4
var next_tick: int = 4
var actions_taken: int = 0
var interrupt_on_action: int = -1
var interrupt_reason: String = "dummy damage"
var forced_failure: bool = false

func configure(id_value: String, interval_ticks: int, start_tick: int = 0) -> void:
    actor_id = id_value
    interval = maxi(1, interval_ticks)
    next_tick = start_tick + interval
    actions_taken = 0
    interrupt_on_action = -1
    interrupt_reason = "dummy damage"
    forced_failure = false

func scheduler_step(world_tick: int, scheduler) -> void:
    actions_taken += 1
    if interrupt_on_action > 0 and actions_taken == interrupt_on_action:
        scheduler.notify_damage_interrupt(interrupt_reason, forced_failure)
    next_tick = world_tick + interval
