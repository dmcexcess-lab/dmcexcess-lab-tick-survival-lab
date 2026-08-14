extends SceneTree

const Perception = preload("res://scripts/TacticalPerception.gd")
const WorldClass = preload("res://scripts/LocalWorldState.gd")

func _init() -> void:
    var spec: Dictionary = {
        "default_ground": "asphalt", "ground_rects": [], "indoor_rects": [],
        "walls": [], "obstacles": [], "glass": [], "doors": [[Vector2i(5, 5), false]],
        "barrels": [], "props": [], "lights": [], "player_spawn": Vector2i(3, 5), "exit_cells": [Vector2i(8, 5)]
    }
    var world = WorldClass.new()
    world.load_from_spec(spec)
    var opaque: Dictionary = Perception.opaque_cells(spec)
    if Perception.line_clear(Vector2i(3, 5), Vector2i(7, 5), spec, world, opaque):
        push_error("PERCEPTION_SMOKE_CLOSED_DOOR_DID_NOT_OCCLUDE")
        quit(1); return
    world.set_door_open(Vector2i(5, 5), true)
    if not Perception.line_clear(Vector2i(3, 5), Vector2i(7, 5), spec, world, opaque):
        push_error("PERCEPTION_SMOKE_OPEN_DOOR_STILL_OCCLUDES")
        quit(1); return
    if not Perception.in_cone(Vector2i(3, 5), Vector2i.RIGHT, Vector2i(6, 5), 7, 0.14):
        push_error("PERCEPTION_SMOKE_FORWARD_NOT_IN_CONE")
        quit(1); return
    if Perception.in_cone(Vector2i(3, 5), Vector2i.RIGHT, Vector2i(1, 5), 7, 0.14):
        push_error("PERCEPTION_SMOKE_BEHIND_IN_CONE")
        quit(1); return
    var light: Dictionary = Perception.calculate_lighting(spec, world, "back_alley", "night", false, Vector2i(3, 5), Vector2i.RIGHT, true)
    var levels: Dictionary = light.get("levels", {})
    if float(levels.get(Vector2i(6, 5), 0.0)) <= float(levels.get(Vector2i(1, 5), 0.0)):
        push_error("PERCEPTION_SMOKE_FLASHLIGHT_NOT_DIRECTIONAL")
        quit(1); return
    var first: Dictionary = Perception.calculate_visibility(Vector2i(3, 5), Vector2i.RIGHT, levels, spec, world, opaque, {}, 7)
    var memory: Dictionary = first.get("memory", {})
    if not memory.has(Vector2i(6, 5)):
        push_error("PERCEPTION_SMOKE_VISIBLE_NOT_REMEMBERED")
        quit(1); return
    var second: Dictionary = Perception.calculate_visibility(Vector2i(3, 5), Vector2i.LEFT, levels, spec, world, opaque, memory, 7)
    if second.get("visible", {}).has(Vector2i(6, 5)) or not second.get("memory", {}).has(Vector2i(6, 5)):
        push_error("PERCEPTION_SMOKE_FOG_MEMORY_BAD")
        quit(1); return
    print("TICK_SURVIVAL_PERCEPTION_SMOKE_OK")
    quit(0)
