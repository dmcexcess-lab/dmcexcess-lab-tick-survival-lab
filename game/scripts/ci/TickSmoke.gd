extends SceneTree

const TickSchedulerClass = preload("res://scripts/TickScheduler.gd")
const PlayerActorClass = preload("res://scripts/PlayerActor.gd")
const LocalWorldStateClass = preload("res://scripts/LocalWorldState.gd")
const MapGen = preload("res://scripts/TacticalMapGenerator.gd")

func _init() -> void:
    var scheduler = TickSchedulerClass.new()
    var player = PlayerActorClass.new()
    var world = LocalWorldStateClass.new()

    player.reset(Vector2i(5, 5))
    if player.movement_cost() != PlayerActorClass.WALK_TICKS:
        push_error("TICK_SMOKE_BAD_WALK_COST")
        quit(1)
        return
    scheduler.commit_action(player.actor_id, "walk", player.movement_cost())
    if scheduler.world_tick != PlayerActorClass.WALK_TICKS:
        push_error("TICK_SMOKE_CLOCK_DID_NOT_ADVANCE")
        quit(1)
        return

    player.set_move_mode(PlayerActorClass.MODE_RUN)
    scheduler.commit_action(player.actor_id, "run", player.movement_cost())
    if scheduler.world_tick != PlayerActorClass.WALK_TICKS + PlayerActorClass.RUN_TICKS:
        push_error("TICK_SMOKE_BAD_RUN_COST")
        quit(1)
        return

    player.encumbrance_ratio = 1.0
    player.fatigue_ratio = 1.0
    if player.movement_cost() <= PlayerActorClass.RUN_TICKS:
        push_error("TICK_SMOKE_MODIFIERS_NOT_APPLIED")
        quit(1)
        return

    var spec: Dictionary = MapGen.build_layout("back_alley", 0)
    world.load_from_spec(spec)
    var door_cell := Vector2i(9, 8)
    if not world.is_door(door_cell) or world.is_door_open(door_cell) or world.can_enter(door_cell):
        push_error("TICK_SMOKE_CLOSED_DOOR_BAD")
        quit(1)
        return
    world.set_door_open(door_cell, true)
    if not world.is_door_open(door_cell) or not world.can_enter(door_cell):
        push_error("TICK_SMOKE_OPEN_DOOR_BAD")
        quit(1)
        return

    print("TICK_SURVIVAL_SCHEDULER_SMOKE_OK")
    quit(0)
