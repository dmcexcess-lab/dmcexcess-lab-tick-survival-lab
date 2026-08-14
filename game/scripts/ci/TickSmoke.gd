extends SceneTree

const TickSchedulerClass = preload("res://scripts/TickScheduler.gd")
const TimingDummyClass = preload("res://scripts/TimingDummy.gd")
const PlayerActorClass = preload("res://scripts/PlayerActor.gd")
const LocalWorldStateClass = preload("res://scripts/LocalWorldState.gd")
const MapGen = preload("res://scripts/TacticalMapGenerator.gd")

func _fail(code: String) -> void:
    push_error(code)
    quit(1)

func _init() -> void:
    var scheduler = TickSchedulerClass.new()
    var player = PlayerActorClass.new()
    var world = LocalWorldStateClass.new()
    var dummy = TimingDummyClass.new()

    player.reset(Vector2i(5, 5))
    dummy.configure("dummy", 4, 0)
    var result: Dictionary = scheduler.execute_action(player.actor_id, "walk", 10, TickSchedulerClass.POLICY_COMMITTED, [], {}, [dummy])
    if scheduler.world_tick != 10 or dummy.actions_taken != 2 or str(result.get("status", "")) != TickSchedulerClass.STATUS_COMPLETED or not scheduler.player_ready:
        _fail("TICK_SMOKE_CONCURRENT_EXECUTION_BAD")
        return

    scheduler.reset()
    dummy.configure("dummy", 4, 0)
    scheduler.execute_action(player.actor_id, "quick", 3, TickSchedulerClass.POLICY_COMMITTED, [], {}, [dummy])
    if dummy.actions_taken != 0 or scheduler.world_tick != 3:
        _fail("TICK_SMOKE_SHORT_ACTION_BAD")
        return

    scheduler.reset()
    dummy.configure("damage_dummy", 5, 0)
    dummy.interrupt_on_action = 1
    var phases: Array = [{"id": "mag_out", "ticks": 4}, {"id": "mag_in", "ticks": 4}, {"id": "chamber", "ticks": 4}]
    result = scheduler.execute_action(player.actor_id, "reload", 12, TickSchedulerClass.POLICY_RESUMABLE, phases, {}, [dummy])
    if str(result.get("status", "")) != TickSchedulerClass.STATUS_INTERRUPTED or not scheduler.has_resumable_action("reload"):
        _fail("TICK_SMOKE_RESUMABLE_DID_NOT_INTERRUPT")
        return
    var resume: Dictionary = scheduler.take_resumable_action("reload")
    if int(resume.get("elapsed_ticks", 0)) != 5 or str(resume.get("phase_id", "")) != "mag_in":
        _fail("TICK_SMOKE_RESUME_PROGRESS_BAD")
        return
    dummy.configure("dummy", 4, scheduler.world_tick)
    result = scheduler.execute_action(player.actor_id, "reload", 12, TickSchedulerClass.POLICY_RESUMABLE, phases, {}, [dummy], resume)
    if str(result.get("status", "")) != TickSchedulerClass.STATUS_COMPLETED or scheduler.world_tick != 12:
        _fail("TICK_SMOKE_RESUME_COMPLETION_BAD")
        return

    scheduler.reset()
    dummy.configure("damage_dummy", 2, 0)
    dummy.interrupt_on_action = 1
    result = scheduler.execute_action(player.actor_id, "axe_swing", 6, TickSchedulerClass.POLICY_COMMITTED, [], {}, [dummy])
    if str(result.get("status", "")) != TickSchedulerClass.STATUS_COMPLETED or scheduler.world_tick != 6:
        _fail("TICK_SMOKE_COMMITTED_DAMAGE_BAD")
        return

    var spec: Dictionary = MapGen.build_layout("back_alley", 0)
    world.load_from_spec(spec)
    var door_cell := Vector2i(9, 8)
    if not world.is_door(door_cell) or world.is_door_open(door_cell) or world.can_enter(door_cell):
        _fail("TICK_SMOKE_CLOSED_DOOR_BAD")
        return
    world.set_door_open(door_cell, true)
    if not world.can_enter(door_cell):
        _fail("TICK_SMOKE_OPEN_DOOR_BAD")
        return

    print("TICK_SURVIVAL_SCHEDULER_SMOKE_OK")
    quit(0)
