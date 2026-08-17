extends RefCounted
class_name GeneratedBuildingPlan

var instance_id: String = ""
var archetype_id: StringName = &""
var archetype_version: int = 1
var seed: int = 0
var footprint_rect: Rect2i = Rect2i()
var orientation: int = 0
var frontage_side: int = 0
var ground_entries: Array[Dictionary] = []
var structures: Array[Dictionary] = []
var props: Array[Dictionary] = []
var rooms: Array[Dictionary] = []
var failure_reason: String = ""

func is_generated() -> bool:
    return failure_reason.is_empty() and not instance_id.is_empty() and footprint_rect.size.x > 0 and footprint_rect.size.y > 0

func snapshot() -> Dictionary:
    var ground_out: Array = []
    for entry: Dictionary in ground_entries:
        ground_out.append({"cell": _cell(entry.get("cell", Vector2i.ZERO)), "semantic": String(entry.get("semantic", &""))})
    var structures_out: Array = []
    for entry: Dictionary in structures:
        structures_out.append({
            "role": String(entry.get("role", "")),
            "cell": _cell(entry.get("cell", Vector2i.ZERO)),
            "semantic": String(entry.get("semantic", &"")),
            "axis": int(entry.get("axis", -1)),
            "facing": int(entry.get("facing", 0)),
            "kind": String(entry.get("kind", "")),
        })
    var props_out: Array = []
    for entry: Dictionary in props:
        props_out.append({
            "role": String(entry.get("role", "")),
            "cell": _cell(entry.get("cell", Vector2i.ZERO)),
            "semantic": String(entry.get("semantic", &"")),
            "facing": int(entry.get("facing", 0)),
            "blocking": bool(entry.get("blocking", true)),
        })
    var rooms_out: Array = []
    for room: Dictionary in rooms:
        var cells_out: Array = []
        for cell: Vector2i in room.get("cells", []):
            cells_out.append(_cell(cell))
        rooms_out.append({"purpose": String(room.get("purpose", "")), "cells": cells_out})
    return {
        "instance_id": instance_id,
        "archetype_id": String(archetype_id),
        "archetype_version": archetype_version,
        "seed": seed,
        "footprint": [footprint_rect.position.x, footprint_rect.position.y, footprint_rect.size.x, footprint_rect.size.y],
        "orientation": orientation,
        "frontage_side": frontage_side,
        "ground": ground_out,
        "structures": structures_out,
        "props": props_out,
        "rooms": rooms_out,
    }

func signature() -> String:
    return JSON.stringify(snapshot())

static func _cell(value: Vector2i) -> Array:
    return [value.x, value.y]
