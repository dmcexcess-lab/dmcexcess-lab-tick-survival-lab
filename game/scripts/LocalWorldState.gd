extends RefCounted
class_name LocalWorldState

var walls: Dictionary = {}
var obstacles: Dictionary = {}
var glass: Dictionary = {}
var doors: Dictionary = {}
var width := TacticalMapGenerator.BOARD_W
var height := TacticalMapGenerator.BOARD_H

func load_from_spec(spec: Dictionary) -> void:
    walls.clear()
    obstacles.clear()
    glass.clear()
    doors.clear()
    width = int(spec.get("width", TacticalMapGenerator.BOARD_W))
    height = int(spec.get("height", TacticalMapGenerator.BOARD_H))
    for value in spec.get("walls", []):
        walls[value] = true
    for value in spec.get("obstacles", []):
        obstacles[value] = true
    for value in spec.get("glass", []):
        glass[value] = true
    for entry_value in spec.get("doors", []):
        var entry: Array = entry_value
        doors[entry[0]] = bool(entry[1])

func is_inside(cell: Vector2i) -> bool:
    return cell.x >= 1 and cell.y >= 1 and cell.x < width - 1 and cell.y < height - 1

func is_door(cell: Vector2i) -> bool:
    return doors.has(cell)

func is_door_open(cell: Vector2i) -> bool:
    return bool(doors.get(cell, false))

func set_door_open(cell: Vector2i, opened: bool) -> void:
    if doors.has(cell):
        doors[cell] = opened

func can_enter(cell: Vector2i) -> bool:
    if not is_inside(cell):
        return false
    if walls.has(cell) or obstacles.has(cell) or glass.has(cell):
        return false
    if doors.has(cell) and not bool(doors[cell]):
        return false
    return true
