extends RefCounted
class_name PlayerActor

const MODE_WALK := "walk"
const MODE_RUN := "run"

const WALK_TICKS := 10
const RUN_TICKS := 6
const CROUCH_WALK_TICKS := 14
const TURN_TICKS := 3
const DOOR_TICKS := 8
const STANCE_TICKS := 4

var actor_id := "player"
var cell := Vector2i.ZERO
var facing := Vector2i.DOWN
var move_mode := MODE_WALK
var crouched := false
var encumbrance_ratio := 0.0
var fatigue_ratio := 0.0

func reset(spawn: Vector2i) -> void:
    cell = spawn
    facing = Vector2i.DOWN
    move_mode = MODE_WALK
    crouched = false
    encumbrance_ratio = 0.0
    fatigue_ratio = 0.0

func set_move_mode(mode: String) -> void:
    if crouched:
        move_mode = MODE_WALK
    elif mode == MODE_RUN:
        move_mode = MODE_RUN
    else:
        move_mode = MODE_WALK

func set_crouched(value: bool) -> void:
    crouched = value
    if crouched:
        move_mode = MODE_WALK

func movement_cost() -> int:
    var base: int = CROUCH_WALK_TICKS if crouched else (RUN_TICKS if move_mode == MODE_RUN else WALK_TICKS)
    return _modified_cost(base)

func turn_cost() -> int:
    return _modified_cost(TURN_TICKS)

func door_cost() -> int:
    return _modified_cost(DOOR_TICKS)

func stance_cost() -> int:
    return _modified_cost(STANCE_TICKS)

func _modified_cost(base: int) -> int:
    # Timing modifiers are deliberately centralized here so later condition,
    # inventory, and injury systems can feed ratios without owning the clock.
    var multiplier: float = 1.0 + maxf(0.0, encumbrance_ratio) * 0.75 + maxf(0.0, fatigue_ratio) * 0.65
    return maxi(1, int(ceil(float(base) * multiplier)))
