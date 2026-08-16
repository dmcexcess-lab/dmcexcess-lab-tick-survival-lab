extends SceneTree

const KernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_deterministic_event_order_and_time_jump()
    _test_dynamic_same_tick_batch()
    _test_decision_pause_after_full_batch()
    _test_concurrent_actions_and_phases()
    _test_interruption_policies()
    _test_hard_pause_mid_action()
    _test_event_cancellation_and_validation()
    _test_snapshot_restore_and_atomic_rejection()
    _test_safety_limit()

    if _failures.is_empty():
        print("TICK_KERNEL_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("TICK_KERNEL_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _phase(id: String, offset: int) -> ActionPhase:
    return PhaseClass.new(StringName(id), offset)

func _test_deterministic_event_order_and_time_jump() -> void:
    var kernel := KernelClass.new()
    var order: Array[String] = []
    kernel.external_event_due.connect(func(event):
        order.append("%d:%s" % [kernel.world_tick(), String(event.event_type)])
    )

    kernel.schedule_event(5, "b", &"b_default")
    kernel.schedule_event(5, "a", &"a_default_1")
    kernel.schedule_event(5, "a", &"a_early", "", {}, -1)
    kernel.schedule_event(3, "z", &"z_first")
    kernel.schedule_event(5, "a", &"a_default_2")

    var reason: int = kernel.run_until_stop()
    _check(reason == Rules.RunStopReason.IDLE, "event-only kernel stops idle")
    _check(kernel.world_tick() == 5, "kernel jumps directly to final due tick")
    _check(order == [
        "3:z_first",
        "5:a_early",
        "5:a_default_1",
        "5:a_default_2",
        "5:b_default",
    ], "event ordering is tick/priority/owner/serial deterministic")

func _test_dynamic_same_tick_batch() -> void:
    var kernel := KernelClass.new()
    var order: Array[String] = []
    kernel.external_event_due.connect(func(event):
        order.append(String(event.event_type))
        if event.event_type == &"seed":
            kernel.schedule_event(kernel.world_tick(), "same", &"child")
    )
    kernel.schedule_event(4, "same", &"seed")
    var reason: int = kernel.run_until_stop()
    _check(reason == Rules.RunStopReason.IDLE, "dynamic same-tick batch eventually idles")
    _check(kernel.world_tick() == 4, "same-tick child does not advance time")
    _check(order == ["seed", "child"], "same-current-tick event joins active batch")

func _test_decision_pause_after_full_batch() -> void:
    var kernel := KernelClass.new("player")
    var order: Array[String] = []
    kernel.action_finished.connect(func(action):
        order.append("player_finished@%d" % kernel.world_tick())
    )
    kernel.external_event_due.connect(func(event):
        order.append("%s@%d" % [String(event.event_type), kernel.world_tick()])
    )

    var player_action: int = kernel.begin_action("player", &"move", 5)
    _check(player_action > 0, "decision actor can begin action from auto-pause")
    kernel.schedule_event(5, "zombie", &"zombie_same_tick")
    var reason: int = kernel.run_until_stop()
    _check(reason == Rules.RunStopReason.DECISION_REQUIRED, "player readiness returns decision stop")
    _check(kernel.world_tick() == 5, "decision action completes at exact duration")
    _check(kernel.is_decision_paused(), "decision pause engaged")
    _check(order == ["player_finished@5", "zombie_same_tick@5"], "full tick batch drains before decision pause")

func _test_concurrent_actions_and_phases() -> void:
    var kernel := KernelClass.new()
    var phases: Array[String] = []
    var finishes: Array[String] = []
    kernel.action_phase.connect(func(action, phase):
        phases.append("%s:%s@%d" % [action.actor_id, String(phase.phase_id), kernel.world_tick()])
    )
    kernel.action_finished.connect(func(action):
        finishes.append("%s:%d@%d" % [action.actor_id, action.status, kernel.world_tick()])
    )

    var actor_a: int = kernel.begin_action("a", &"long", 5, Rules.InterruptionPolicy.COMMITTED, [
        _phase("prep", 2),
        _phase("effect", 5),
    ])
    var actor_b: int = kernel.begin_action("b", &"short", 3)
    var duplicate_actor: int = kernel.begin_action("a", &"illegal_second", 2)
    _check(actor_a > 0 and actor_b > 0, "different actors may act concurrently")
    _check(duplicate_actor == 0, "one active action per actor enforced")

    var reason: int = kernel.run_until_stop()
    _check(reason == Rules.RunStopReason.IDLE, "concurrent actions drain to idle")
    _check(phases == ["a:prep@2", "a:effect@5"], "action phases fire at exact offsets")
    _check(finishes.size() == 2, "both concurrent actions finish")
    _check(finishes[0].begins_with("b:%d@3" % Rules.ActionStatus.COMPLETED), "short actor finishes first at tick 3")
    _check(finishes[1].begins_with("a:%d@5" % Rules.ActionStatus.COMPLETED), "long actor finishes at tick 5 after final phase")

func _test_interruption_policies() -> void:
    _test_committed_and_forced_failure()
    _test_resumable_progress()
    _test_cancelable()

func _test_committed_and_forced_failure() -> void:
    var committed := KernelClass.new()
    var committed_serial: int = committed.begin_action("actor", &"committed", 10, Rules.InterruptionPolicy.COMMITTED)
    var committed_result: Array[int] = []
    var committed_finish: Array = []
    committed.external_event_due.connect(func(event):
        if event.event_type == &"interrupt":
            committed_result.append(committed.interrupt_action(committed_serial, "ordinary"))
    )
    committed.action_finished.connect(func(action): committed_finish.append(action))
    committed.schedule_event(3, "interruptor", &"interrupt")
    committed.run_until_stop()
    _check(committed_result == [Rules.ActionStatus.RUNNING], "COMMITTED ignores ordinary interruption")
    _check(committed.world_tick() == 10, "COMMITTED action keeps original completion tick")
    _check(committed_finish.size() == 1 and committed_finish[0].status == Rules.ActionStatus.COMPLETED, "COMMITTED action completes")

    var forced := KernelClass.new()
    var forced_serial: int = forced.begin_action("actor", &"forced", 10, Rules.InterruptionPolicy.COMMITTED)
    var forced_finish: Array = []
    forced.external_event_due.connect(func(event):
        forced.interrupt_action(forced_serial, "catastrophic", true)
    )
    forced.action_finished.connect(func(action): forced_finish.append(action))
    forced.schedule_event(2, "interruptor", &"force_fail")
    forced.run_until_stop()
    _check(forced.world_tick() == 2, "forced failure stops at interruption tick")
    _check(forced_finish.size() == 1 and forced_finish[0].status == Rules.ActionStatus.FAILED, "forced failure overrides COMMITTED")

func _test_resumable_progress() -> void:
    var kernel := KernelClass.new()
    var phase_log: Array[String] = []
    var serial: int = kernel.begin_action("actor", &"repair", 10, Rules.InterruptionPolicy.RESUMABLE, [
        _phase("first", 3),
        _phase("second", 7),
    ])
    kernel.action_phase.connect(func(action, phase):
        phase_log.append("%s@%d" % [String(phase.phase_id), kernel.world_tick()])
    )
    kernel.external_event_due.connect(func(event):
        if event.event_type == &"interrupt":
            kernel.interrupt_action(serial, "danger")
    )
    kernel.schedule_event(5, "interruptor", &"interrupt")
    var first_reason: int = kernel.run_until_stop()
    _check(first_reason == Rules.RunStopReason.IDLE, "interrupted resumable action leaves kernel idle")
    _check(kernel.world_tick() == 5, "resumable interruption occurs at exact tick")
    _check(phase_log == ["first@3"], "only reached phases fire before interruption")
    var interrupted: TimedAction = kernel.resumable_action(serial)
    _check(interrupted != null and interrupted.elapsed_ticks == 5, "resumable action preserves elapsed progress")
    _check(interrupted != null and interrupted.next_phase_index == 1, "resumable action preserves pending phase index")

    kernel.schedule_event(8, "clock", &"advance")
    kernel.run_until_stop()
    _check(kernel.world_tick() == 8, "unrelated time may advance while action is interrupted")
    _check(kernel.resume_action(serial), "resumable action resumes")
    kernel.run_until_stop()
    _check(phase_log == ["first@3", "second@10"], "remaining phase reschedules from preserved progress")
    _check(kernel.world_tick() == 13, "resumed action completes after remaining five ticks")

func _test_cancelable() -> void:
    var kernel := KernelClass.new()
    var serial: int = kernel.begin_action("actor", &"search", 10, Rules.InterruptionPolicy.CANCELABLE)
    var finish: Array = []
    kernel.action_finished.connect(func(action): finish.append(action))
    kernel.external_event_due.connect(func(event): kernel.interrupt_action(serial, "stop"))
    kernel.schedule_event(4, "interruptor", &"interrupt")
    kernel.run_until_stop()
    _check(kernel.world_tick() == 4, "CANCELABLE stops at interruption tick")
    _check(not kernel.has_resumable_action(serial), "CANCELABLE does not create resumable state")
    _check(not kernel.resume_action(serial), "CANCELABLE cannot resume")
    _check(finish.size() == 1 and finish[0].status == Rules.ActionStatus.CANCELED, "CANCELABLE emits canceled terminal action")

func _test_hard_pause_mid_action() -> void:
    var kernel := KernelClass.new()
    var serial: int = kernel.begin_action("actor", &"long_task", 10)
    kernel.external_event_due.connect(func(event):
        if event.event_type == &"pause_now":
            kernel.set_hard_paused(true)
    )
    kernel.schedule_event(4, "lifecycle", &"pause_now")
    var reason: int = kernel.run_until_stop()
    _check(reason == Rules.RunStopReason.HARD_PAUSED, "hard pause stops run immediately")
    _check(kernel.world_tick() == 4, "hard pause freezes at current simulation tick")
    var paused_action: TimedAction = kernel.action_by_serial(serial)
    _check(paused_action != null and paused_action.elapsed_ticks == 4, "hard pause preserves mid-action progress")
    var still_paused_reason: int = kernel.run_until_stop()
    _check(still_paused_reason == Rules.RunStopReason.HARD_PAUSED and kernel.world_tick() == 4, "re-running while hard paused advances zero ticks")
    kernel.set_hard_paused(false)
    kernel.run_until_stop()
    _check(kernel.world_tick() == 10, "unpaused action resumes to original due tick")

func _test_event_cancellation_and_validation() -> void:
    var kernel := KernelClass.new()
    var fired: Array[String] = []
    kernel.external_event_due.connect(func(event): fired.append(String(event.event_type)))
    var cancel_me: int = kernel.schedule_event(2, "system", &"cancel_me")
    _check(cancel_me > 0 and kernel.cancel_event(cancel_me), "scheduled event can be canceled")
    _check(kernel.schedule_event(-1, "system", &"past") == 0, "negative/past event rejected")
    _check(kernel.schedule_event(0, "", &"bad_owner") == 0, "empty event owner rejected")
    _check(kernel.schedule_event(0, "system", &"bad_payload", "", {"cell": Vector2i(1, 2)}) == 0, "non-serializable opaque payload rejected")
    var reason: int = kernel.run_until_stop()
    _check(reason == Rules.RunStopReason.IDLE, "all-canceled queue is idle")
    _check(kernel.world_tick() == 0 and fired.is_empty(), "canceled event never dispatches or advances time")

func _test_snapshot_restore_and_atomic_rejection() -> void:
    var original := KernelClass.new("player")
    var action_serial: int = original.begin_action("player", &"long", 10, Rules.InterruptionPolicy.RESUMABLE, [
        _phase("p1", 4),
        _phase("p2", 9),
    ], {"note": "snapshot"})
    _check(action_serial > 0, "snapshot test action starts")
    original.schedule_event(3, "clock", &"checkpoint")
    original.schedule_event(6, "weather", &"weather_change", "", {"kind": "rain"})
    var first_batch: int = original.run_next_batch()
    _check(first_batch == Rules.RunStopReason.BATCH_COMPLETE and original.world_tick() == 3, "snapshot captured between action checkpoints")

    var snap: Dictionary = original.snapshot()
    var restored := KernelClass.new()
    _check(restored.load_snapshot(snap), "valid WHEN snapshot restores")
    _check(restored.snapshot() == snap, "snapshot restore round-trips deterministically")

    var original_order: Array[String] = []
    var restored_order: Array[String] = []
    original.external_event_due.connect(func(event): original_order.append("e:%s@%d" % [String(event.event_type), original.world_tick()]))
    original.action_phase.connect(func(action, phase): original_order.append("p:%s@%d" % [String(phase.phase_id), original.world_tick()]))
    original.action_finished.connect(func(action): original_order.append("f@%d" % original.world_tick()))
    restored.external_event_due.connect(func(event): restored_order.append("e:%s@%d" % [String(event.event_type), restored.world_tick()]))
    restored.action_phase.connect(func(action, phase): restored_order.append("p:%s@%d" % [String(phase.phase_id), restored.world_tick()]))
    restored.action_finished.connect(func(action): restored_order.append("f@%d" % restored.world_tick()))
    var original_reason: int = original.run_until_stop()
    var restored_reason: int = restored.run_until_stop()
    _check(original_reason == Rules.RunStopReason.DECISION_REQUIRED and restored_reason == Rules.RunStopReason.DECISION_REQUIRED, "restored decision actor reaches same stop")
    _check(original_order == restored_order, "restored timing dispatch order matches original")
    _check(original.snapshot() == restored.snapshot(), "restored kernel converges to identical canonical timing state")

    var before_bad: Dictionary = restored.snapshot()
    var malformed: Dictionary = before_bad.duplicate(true)
    malformed["next_event_serial"] = 1
    _check(not restored.load_snapshot(malformed), "malformed next serial snapshot rejected")
    _check(restored.snapshot() == before_bad, "failed snapshot restore is atomic")

    var continuation := KernelClass.new()
    continuation.schedule_event(2, "system", &"one")
    var continuation_snap: Dictionary = continuation.snapshot()
    var continuation_restored := KernelClass.new()
    _check(continuation_restored.load_snapshot(continuation_snap), "serial continuation snapshot restores")
    var new_event_serial: int = continuation_restored.schedule_event(3, "system", &"two")
    var new_action_serial: int = continuation_restored.begin_action("actor", &"act", 1)
    _check(new_event_serial >= 2, "event serial continues after restore without collision")
    _check(new_action_serial >= 1, "action serial allocator remains valid after restore")

func _test_safety_limit() -> void:
    var kernel := KernelClass.new()
    var fired: int = 0
    kernel.external_event_due.connect(func(event):
        fired += 1
        kernel.schedule_event(kernel.world_tick(), "loop", &"loop")
    )
    kernel.schedule_event(0, "loop", &"loop")
    var reason: int = kernel.run_until_stop(5)
    _check(reason == Rules.RunStopReason.SAFETY_LIMIT, "pathological same-tick loop hits operation guard")
    _check(kernel.world_tick() == 0, "safety guard never invents time advancement")
    _check(fired == 5 and kernel.pending_event_count() == 1, "safety guard leaves remaining same-tick work explicit")
