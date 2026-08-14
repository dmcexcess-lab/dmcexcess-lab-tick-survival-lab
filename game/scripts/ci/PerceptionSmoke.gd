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

    var corner_spec: Dictionary = {
        "default_ground": "asphalt", "ground_rects": [], "indoor_rects": [],
        "walls": [Vector2i(2, 1), Vector2i(1, 2)], "obstacles": [], "glass": [], "doors": [],
        "barrels": [], "props": [[Vector2i(4, 3), "tree"]], "lights": [], "player_spawn": Vector2i(1, 1), "exit_cells": [Vector2i(6, 6)]
    }
    var corner_world = WorldClass.new()
    corner_world.load_from_spec(corner_spec)
    var corner_opaque: Dictionary = Perception.opaque_cells(corner_spec)
    if Perception.line_clear(Vector2i(1, 1), Vector2i(3, 3), corner_spec, corner_world, corner_opaque):
        push_error("PERCEPTION_SMOKE_DIAGONAL_CORNER_LEAK")
        quit(1); return
    if not corner_opaque.has(Vector2i(4, 3)):
        push_error("PERCEPTION_SMOKE_TREE_NOT_OPAQUE")
        quit(1); return

    var region_spec: Dictionary = {
        "width": 16, "height": 16, "default_ground": "grass", "ground_rects": [], "indoor_rects": [],
        "walls": [], "obstacles": [], "glass": [], "doors": [], "barrels": [], "props": [], "lights": [],
        "biome_cells": {Vector2i(3, 3): "woods", Vector2i(4, 3): "downtown"}, "player_spawn": Vector2i(3, 3), "exit_cells": []
    }
    if Perception.theme_for_cell(region_spec, "procedural_region", Vector2i(3, 3)) != "wash" or Perception.theme_for_cell(region_spec, "procedural_region", Vector2i(4, 3)) != "industrial":
        push_error("PERCEPTION_SMOKE_PROCEDURAL_BIOME_THEME_BAD")
        quit(1); return

    print("TICK_SURVIVAL_PERCEPTION_SMOKE_OK")
    quit(0)
