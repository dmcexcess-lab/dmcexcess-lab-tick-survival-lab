extends RefCounted
class_name RuralOpenLandscapePlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

func plan(
    request: AreaGenerationRequest,
    profile: Dictionary,
    environment: Dictionary,
    roads: Array[Dictionary]
) -> Dictionary:
    var ground_regions: Array[Dictionary] = []
    var props: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty() or environment.is_empty():
        return _failure("invalid_rural_open_landscape_input")
    if StringName(profile.get("land_use_mode", &"")) != &"rural_open":
        return _failure("rural_open_profile_required")
    if request.inherited_geography.is_empty():
        return _failure("rural_open_geography_missing")

    var geography_result: Dictionary = _geography_by_cell(request)
    if not bool(geography_result.get("ok", false)):
        return _failure(String(geography_result.get("failure_reason", "rural_open_geography_invalid")))
    var geography_by_cell: Dictionary = geography_result.get("by_cell", {})

    var blocked: Dictionary = _blocked_cells(request, profile, roads)
    var field_cells: Array[Vector2i] = []
    var field_set: Dictionary = {}
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        for x in range(request.bounds.position.x, request.bounds.position.x + request.bounds.size.x):
            var cell := Vector2i(x, y)
            if blocked.has(cell):
                continue
            var geography: Dictionary = geography_by_cell.get(cell, {})
            if _is_agricultural_cell(request.seed, profile, cell, geography):
                field_cells.append(cell)
                field_set[cell] = true

    if not field_cells.is_empty():
        ground_regions.append({
            "id": "%s.ground.rural_open.field" % request.area_id,
            "semantic": environment.get("field_ground", &"ground.field_green"),
            "cells": field_cells,
            "priority": 40,
        })

    var trees: Array = environment.get("tree_semantics", [])
    var shrubs: Array = environment.get("shrub_semantics", [])
    var rocks: Array = environment.get("rock_semantics", [])
    if trees.is_empty() or shrubs.is_empty() or rocks.is_empty():
        return _failure("rural_open_natural_semantics_missing")

    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        for x in range(request.bounds.position.x, request.bounds.position.x + request.bounds.size.x):
            var cell := Vector2i(x, y)
            if blocked.has(cell) or field_set.has(cell):
                continue
            var geography: Dictionary = geography_by_cell.get(cell, {})
            var density: float = _natural_density(profile, StringName(geography.get("landform", &"")))
            var patch: float = _value_noise_global(request.seed, cell, 46, 1301)
            var local_density: float = clampf(density * lerpf(0.22, 2.15, patch), 0.0, 0.16)
            if Seed.unit_2d(request.seed, cell.x, cell.y, 1409) >= local_density:
                continue
            var semantic: StringName = _natural_semantic(
                request.seed,
                cell,
                StringName(geography.get("landform", &"")),
                trees,
                shrubs,
                rocks
            )
            if semantic == &"":
                continue
            props.append({
                "id": _natural_prop_id(cell),
                "semantic": semantic,
                "cell": cell,
                "facing": Facing.Value.SOUTH,
            })

    return {
        "ok": true,
        "failure_reason": "",
        "ground_regions": ground_regions,
        "props": props,
    }

func _geography_by_cell(request: AreaGenerationRequest) -> Dictionary:
    var by_cell: Dictionary = {}
    for geography: Dictionary in request.inherited_geography:
        var rect: Rect2i = geography.get("rect", Rect2i())
        if rect.size.x <= 0 or rect.size.y <= 0:
            return {"ok": false, "failure_reason": "rural_open_geography_rect_invalid", "by_cell": {}}
        for y in range(rect.position.y, rect.position.y + rect.size.y):
            for x in range(rect.position.x, rect.position.x + rect.size.x):
                var cell := Vector2i(x, y)
                if not request.bounds.has_point(cell):
                    return {"ok": false, "failure_reason": "rural_open_geography_out_of_bounds", "by_cell": {}}
                if by_cell.has(cell):
                    return {"ok": false, "failure_reason": "rural_open_geography_overlap", "by_cell": {}}
                by_cell[cell] = geography
    if by_cell.size() != request.bounds.size.x * request.bounds.size.y:
        return {"ok": false, "failure_reason": "rural_open_geography_incomplete", "by_cell": {}}
    return {"ok": true, "failure_reason": "", "by_cell": by_cell}

func _is_agricultural_cell(seed: int, profile: Dictionary, cell: Vector2i, geography: Dictionary) -> bool:
    var landform: StringName = StringName(geography.get("landform", &""))
    if landform != &"lowland" and landform != &"rolling":
        return false
    var threshold: float = float(profile.get("rural_open_field_threshold_lowland", 0.48))
    if landform == &"rolling":
        threshold = float(profile.get("rural_open_field_threshold_rolling", 0.68))
    var elevation: int = clampi(int(geography.get("elevation", 50)), 0, 100)
    threshold += float(elevation) * 0.00045
    var scale: int = maxi(16, int(profile.get("rural_open_field_scale", 72)))
    return _value_noise_global(seed, cell, scale, 911) >= threshold

func _natural_density(profile: Dictionary, landform: StringName) -> float:
    match landform:
        &"lowland":
            return float(profile.get("rural_open_natural_density_lowland", 0.010))
        &"rolling":
            return float(profile.get("rural_open_natural_density_rolling", 0.014))
        &"upland":
            return float(profile.get("rural_open_natural_density_upland", 0.020))
        &"ridge":
            return float(profile.get("rural_open_natural_density_ridge", 0.024))
    return 0.0

func _natural_semantic(
    seed: int,
    cell: Vector2i,
    landform: StringName,
    trees: Array,
    shrubs: Array,
    rocks: Array
) -> StringName:
    var family_roll: float = Seed.unit_2d(seed, cell.x, cell.y, 1511)
    var family: Array = trees
    if landform == &"lowland":
        if family_roll < 0.58:
            family = trees
        elif family_roll < 0.92:
            family = shrubs
        else:
            family = rocks
    elif landform == &"rolling":
        if family_roll < 0.48:
            family = trees
        elif family_roll < 0.80:
            family = shrubs
        else:
            family = rocks
    else:
        if family_roll < 0.38:
            family = trees
        elif family_roll < 0.66:
            family = shrubs
        else:
            family = rocks
    if family.is_empty():
        return &""
    var index: int = Seed.hash_2d(seed, cell.x, cell.y, 1601) % family.size()
    return StringName(family[index])

func _blocked_cells(request: AreaGenerationRequest, profile: Dictionary, roads: Array[Dictionary]) -> Dictionary:
    var blocked: Dictionary = {}
    var road_clearance: int = maxi(0, int(profile.get("rural_open_road_clearance", 2)))
    for road: Dictionary in roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) != TYPE_VECTOR2I:
                continue
            _block_with_clearance(blocked, value, road_clearance, request.bounds)

    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("reservation_role", &"")) != &"corridor":
            continue
        var start: Vector2i = constraint.get("start", Vector2i(-999999, -999999))
        var finish: Vector2i = constraint.get("end", Vector2i(-999999, -999999))
        var width: int = maxi(1, int(constraint.get("width", 1)))
        var domain: StringName = StringName(constraint.get("domain", &""))
        var extra: int = maxi(0, int(profile.get("rural_open_power_clearance", 1))) if domain == &"power" else 0
        _block_cardinal_corridor(blocked, start, finish, width, extra, request.bounds)
    return blocked

func _block_cardinal_corridor(
    blocked: Dictionary,
    start: Vector2i,
    finish: Vector2i,
    width: int,
    extra: int,
    bounds: Rect2i
) -> void:
    if start == finish or (start.x != finish.x and start.y != finish.y):
        return
    var half_width: int = width / 2
    if start.y == finish.y:
        for x in range(mini(start.x, finish.x), maxi(start.x, finish.x) + 1):
            for y in range(start.y - half_width, start.y + half_width + 1):
                _block_with_clearance(blocked, Vector2i(x, y), extra, bounds)
        return
    for y in range(mini(start.y, finish.y), maxi(start.y, finish.y) + 1):
        for x in range(start.x - half_width, start.x + half_width + 1):
            _block_with_clearance(blocked, Vector2i(x, y), extra, bounds)

func _block_with_clearance(blocked: Dictionary, center: Vector2i, clearance: int, bounds: Rect2i) -> void:
    for dy in range(-clearance, clearance + 1):
        for dx in range(-clearance, clearance + 1):
            var cell := center + Vector2i(dx, dy)
            if bounds.has_point(cell):
                blocked[cell] = true

func _value_noise_global(seed: int, cell: Vector2i, scale: int, salt: int) -> float:
    var safe_scale: int = maxi(1, scale)
    var grid_x: int = floori(float(cell.x) / float(safe_scale))
    var grid_y: int = floori(float(cell.y) / float(safe_scale))
    var frac_x: float = float(cell.x - grid_x * safe_scale) / float(safe_scale)
    var frac_y: float = float(cell.y - grid_y * safe_scale) / float(safe_scale)
    var smooth_x: float = frac_x * frac_x * (3.0 - 2.0 * frac_x)
    var smooth_y: float = frac_y * frac_y * (3.0 - 2.0 * frac_y)
    var n00: float = Seed.unit_2d(seed, grid_x, grid_y, salt)
    var n10: float = Seed.unit_2d(seed, grid_x + 1, grid_y, salt)
    var n01: float = Seed.unit_2d(seed, grid_x, grid_y + 1, salt)
    var n11: float = Seed.unit_2d(seed, grid_x + 1, grid_y + 1, salt)
    var top: float = lerpf(n00, n10, smooth_x)
    var bottom: float = lerpf(n01, n11, smooth_x)
    return lerpf(top, bottom, smooth_y)

func _natural_prop_id(cell: Vector2i) -> String:
    return "rural_open.natural.%d.%d" % [cell.x, cell.y]

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "ground_regions": [],
        "props": [],
    }