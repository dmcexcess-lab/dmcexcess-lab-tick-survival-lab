extends RefCounted
class_name CommercialPavedFrontagePlanner

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

## Extends an existing building-owned road-facing parking edge to the road.
## It never invents parking for a building that does not expose parking semantics
## on its real frontage edge.
func plan(request: AreaGenerationRequest, parcels: Array[Dictionary]) -> Dictionary:
    var ground_regions: Array[Dictionary] = []
    if request == null or not request.is_valid():
        return {"ok": false, "failure_reason": "invalid_paved_frontage_input", "ground_regions": ground_regions}

    for parcel: Dictionary in parcels:
        parcel["parking_cells"] = []
        var edge_entries: Array = parcel.get("road_flush_paved_frontage", [])
        if edge_entries.is_empty():
            continue
        var frontage: int = int(parcel.get("frontage_side", -1))
        var road_access: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
        if not Facing.is_valid(frontage) or road_access.x < 0:
            return {"ok": false, "failure_reason": "paved_frontage_access_missing", "ground_regions": ground_regions}

        var grouped: Dictionary = {}
        var all_cells: Array[Vector2i] = []
        var seen: Dictionary = {}
        for edge_value: Variant in edge_entries:
            if typeof(edge_value) != TYPE_DICTIONARY:
                return {"ok": false, "failure_reason": "paved_frontage_entry_invalid", "ground_regions": ground_regions}
            var edge: Dictionary = edge_value
            var edge_cell: Vector2i = edge.get("cell", Vector2i(-999999, -999999))
            var semantic: StringName = StringName(edge.get("semantic", &""))
            if edge_cell.x < -900000 or not String(semantic).begins_with("ground.parking"):
                return {"ok": false, "failure_reason": "paved_frontage_semantic_invalid", "ground_regions": ground_regions}
            var extension: Array[Vector2i] = _extension_cells(edge_cell, road_access, frontage, request.bounds)
            if extension.is_empty() and _frontage_distance(edge_cell, road_access, frontage) > 1:
                return {"ok": false, "failure_reason": "paved_frontage_cannot_reach_road", "ground_regions": ground_regions}
            var key: String = String(semantic)
            if not grouped.has(key):
                grouped[key] = []
            var semantic_cells: Array = grouped[key]
            for cell: Vector2i in extension:
                if seen.has(cell):
                    continue
                seen[cell] = true
                all_cells.append(cell)
                semantic_cells.append(cell)
            grouped[key] = semantic_cells

        _sort_cells(all_cells)
        parcel["parking_cells"] = all_cells.duplicate()
        var semantic_keys: Array = grouped.keys()
        semantic_keys.sort()
        var region_ordinal: int = 0
        for semantic_value: Variant in semantic_keys:
            var semantic_key: String = String(semantic_value)
            var cells: Array = grouped[semantic_key]
            if cells.is_empty():
                continue
            var typed_cells: Array[Vector2i] = []
            for value: Variant in cells:
                if typeof(value) == TYPE_VECTOR2I:
                    typed_cells.append(value)
            _sort_cells(typed_cells)
            ground_regions.append({
                "id": "%s.ground.parking_apron.%02d" % [String(parcel.get("id", "parcel")), region_ordinal],
                "semantic": StringName(semantic_key),
                "cells": typed_cells,
                "priority": 95,
            })
            region_ordinal += 1

    return {"ok": true, "failure_reason": "", "ground_regions": ground_regions}

func _extension_cells(
    edge_cell: Vector2i,
    road_access: Vector2i,
    frontage: int,
    bounds: Rect2i
) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var distance: int = _frontage_distance(edge_cell, road_access, frontage)
    if distance <= 1:
        return result
    var direction: Vector2i = Facing.vector(frontage)
    var current: Vector2i = edge_cell
    var previous_distance: int = distance
    for _step in range(64):
        current += direction
        if not bounds.has_point(current):
            return []
        var current_distance: int = _frontage_distance(current, road_access, frontage)
        if current_distance >= previous_distance:
            return []
        if current_distance == 0:
            return result
        result.append(current)
        previous_distance = current_distance
    return []

func _frontage_distance(a: Vector2i, b: Vector2i, frontage: int) -> int:
    if frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH:
        return absi(a.y - b.y)
    return absi(a.x - b.x)

func _sort_cells(cells: Array[Vector2i]) -> void:
    cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return a.y < b.y or (a.y == b.y and a.x < b.x)
    )
