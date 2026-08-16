extends RefCounted
class_name RebootPlayer

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var cell: Vector2i = Vector2i.ZERO
var facing: int = 2

func reset(spawn: Vector2i, start_facing: int = 2) -> void:
    cell = spawn
    facing = posmod(start_facing, 4)

func turn_left() -> void:
    facing = posmod(facing - 1, 4)

func turn_right() -> void:
    facing = posmod(facing + 1, 4)

func facing_vector() -> Vector2i:
    return DIRS[facing]

func move_forward(spec: Dictionary) -> bool:
    return _try_move(spec, facing_vector())

func move_backward(spec: Dictionary) -> bool:
    return _try_move(spec, -facing_vector())

func _try_move(spec: Dictionary, delta: Vector2i) -> bool:
    var target := cell + delta
    var width := int(spec.get("width", 0))
    var height := int(spec.get("height", 0))
    if target.x < 0 or target.y < 0 or target.x >= width or target.y >= height:
        return false
    var blocked: Dictionary = spec.get("blocked", {})
    if blocked.has(target):
        return false
    cell = target
    return true
