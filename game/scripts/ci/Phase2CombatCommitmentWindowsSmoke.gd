extends SceneTree

const KernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2_COMMITMENT_WINDOWS: " + message)
    quit(1)

func _run() -> void:
    var kernel: TickKernel = KernelClass.new("player")
    var phases_seen: Array[String] = []
    kernel.action_phase.connect(func(action: TimedAction, phase: ActionPhase) -> void:
        phases_seen.append("%s:%s:%d" % [action.actor_id, String(phase.phase_id), kernel.world_tick()])
    )

    var before_commit: int = kernel.begin_action(
        "player", &"combat.test_before", 6, Rules.InterruptionPolicy.CANCELABLE,
        [PhaseClass.new(&"combat.contact", 3)], {}, 3
    )
    if before_commit <= 0:
        _fail("could not begin pre-commit action")
        return
    var before_view: TimedAction = kernel.action_by_serial(before_commit)
    if before_view == null or before_view.commit_offset_ticks != 3:
        _fail("commit offset was not stored")
        return
    if kernel.interrupt_action(before_commit, "impact") != Rules.ActionStatus.CANCELED:
        _fail("interruptible wind-up did not cancel before commitment")
        return
    if kernel.has_active_action("player"):
        _fail("canceled wind-up remained active")
        return

    var player_serial: int = kernel.begin_action(
        "player", &"combat.test_player", 6, Rules.InterruptionPolicy.CANCELABLE,
        [PhaseClass.new(&"combat.contact", 3)], {}, 3
    )
    var zombie_serial: int = kernel.begin_action(
        "zombie", &"combat.test_zombie", 6, Rules.InterruptionPolicy.CANCELABLE,
        [PhaseClass.new(&"combat.contact", 3)], {}, 3
    )
    if player_serial <= 0 or zombie_serial <= 0:
        _fail("could not begin paired same-tick actions")
        return

    var stop: int = kernel.run_next_batch()
    if kernel.world_tick() != 3:
        _fail("shared contact boundary did not advance to tick 3")
        return
    if phases_seen.size() != 2:
        _fail("both same-tick contact phases were not dispatched in the same batch")
        return
    var player_active: TimedAction = kernel.active_action_for_actor("player")
    var zombie_active: TimedAction = kernel.active_action_for_actor("zombie")
    if player_active == null or zombie_active == null:
        _fail("actions did not remain active through recovery")
        return
    if player_active.effective_interruption_policy(kernel.world_tick()) != Rules.InterruptionPolicy.COMMITTED         or zombie_active.effective_interruption_policy(kernel.world_tick()) != Rules.InterruptionPolicy.COMMITTED:
        _fail("contact boundary did not enter the committed window")
        return
    if kernel.interrupt_action(player_serial, "late_impact") != Rules.ActionStatus.RUNNING:
        _fail("committed recovery was incorrectly canceled")
        return

    kernel.run_until_stop()
    if not kernel.is_decision_paused():
        _fail("player action did not return to the decision pause")
        return

    var snapshot_kernel: TickKernel = KernelClass.new("player")
    var serial: int = snapshot_kernel.begin_action(
        "player", &"combat.snapshot", 8, Rules.InterruptionPolicy.CANCELABLE,
        [PhaseClass.new(&"combat.contact", 4)], {"proof": "commit"}, 4
    )
    if serial <= 0:
        _fail("snapshot action did not begin")
        return
    var restored: TickKernel = KernelClass.new()
    if not restored.load_snapshot(snapshot_kernel.snapshot()):
        _fail("commitment window did not survive timing snapshot restore")
        return
    var restored_action: TimedAction = restored.action_by_serial(serial)
    if restored_action == null or restored_action.commit_offset_ticks != 4:
        _fail("restored action lost commit offset")
        return

    print("PHASE2_COMMITMENT_WINDOWS_OK same_tick_phases=%d stop=%d" % [phases_seen.size(), stop])
    quit(0)
