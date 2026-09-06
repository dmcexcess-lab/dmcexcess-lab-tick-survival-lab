extends RefCounted
class_name VehicleProfileCatalog

const SKATEBOARD := &"skateboard"
const BICYCLE := &"bicycle"
const MOTORCYCLE := &"motorcycle"
const CAR := &"car"
const TRUCK := &"truck"

const SEMANTIC_PREFIX := "object.vehicle."
const SKATEBOARD_ITEM_SEMANTIC := &"item.vehicle.skateboard"

var _profiles: Dictionary = {}

func _init() -> void:
    _profiles = {
        SKATEBOARD: _profile(SKATEBOARD, 2, false, 0, 0, 0, 0, 1, 1, 0, 0),
        BICYCLE: _profile(BICYCLE, 3, false, 0, 0, 6000, 1, 1, 2, 0, 1),
        MOTORCYCLE: _profile(MOTORCYCLE, 3, true, 18, 1, 12000, 0, 1, 2, 2, 2),
        CAR: _profile(CAR, 3, true, 40, 2, 70000, 0, 1, 3, 4, 4),
        TRUCK: _profile(TRUCK, 3, true, 55, 3, 140000, 0, 2, 3, 5, 5),
    }

func has_profile(kind: StringName) -> bool: return _profiles.has(kind)
func profile(kind: StringName) -> Dictionary: return Dictionary(_profiles.get(kind, {})).duplicate(true)
func kinds() -> Array[StringName]: return [SKATEBOARD, BICYCLE, MOTORCYCLE, CAR, TRUCK]

func semantic_type(kind: StringName) -> StringName:
    if kind == SKATEBOARD: return SKATEBOARD_ITEM_SEMANTIC
    return StringName(SEMANTIC_PREFIX + String(kind))

func kind_for_semantic(semantic_type: StringName) -> StringName:
    if semantic_type == SKATEBOARD_ITEM_SEMANTIC: return SKATEBOARD
    var text := String(semantic_type)
    if not text.begins_with(SEMANTIC_PREFIX): return &""
    var kind := StringName(text.trim_prefix(SEMANTIC_PREFIX))
    return kind if has_profile(kind) else &""

func is_motorized(kind: StringName) -> bool: return bool(profile(kind).get("motorized", false))
func movement_cells(kind: StringName) -> int: return int(profile(kind).get("movement_cells", 1))
func max_fuel(kind: StringName) -> int: return int(profile(kind).get("max_fuel", 0))
func fuel_per_move(kind: StringName) -> int: return int(profile(kind).get("fuel_per_move", 0))
func cargo_grams(kind: StringName) -> int: return int(profile(kind).get("cargo_grams", 0))
func hotwire_difficulty(kind: StringName) -> int: return int(profile(kind).get("hotwire_difficulty", 0))

func footprint(kind: StringName) -> SpatialFootprint:
    var p := profile(kind)
    return SpatialFootprint.rectangle(int(p.get("width", 1)), int(p.get("height", 1)))

func collision_footprint(kind: StringName, heading: int) -> SpatialFootprint:
    var p := profile(kind)
    var width: int = int(p.get("width", 1))
    var height: int = int(p.get("height", 1))
    if posmod(heading, 3) == 0: return SpatialFootprint.rectangle(width, height)
    var angle := deg_to_rad(float(posmod(heading, 6)) * 30.0)
    var c := absf(cos(angle))
    var s := absf(sin(angle))
    return SpatialFootprint.rectangle(maxi(1, ceili(c * float(width) + s * float(height))), maxi(1, ceili(s * float(width) + c * float(height))))

func _profile(kind: StringName, movement_cells: int, motorized: bool, max_fuel: int, fuel_per_move: int, cargo_grams: int, fatigue_per_move: int, width: int, height: int, hotwire_difficulty: int, repair_difficulty: int) -> Dictionary:
    return {
        "kind": kind, "movement_cells": movement_cells, "motorized": motorized,
        "max_fuel": max_fuel, "fuel_per_move": fuel_per_move, "cargo_grams": cargo_grams,
        "fatigue_per_move": fatigue_per_move, "width": width, "height": height,
        "hotwire_difficulty": hotwire_difficulty, "repair_difficulty": repair_difficulty,
    }
