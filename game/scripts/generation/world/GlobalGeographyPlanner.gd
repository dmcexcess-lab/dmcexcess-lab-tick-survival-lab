extends RefCounted
class_name GlobalGeographyPlanner

const Seed = preload("res://scripts/generation/world/GlobalWorldSeed.gd")

func plan(request: GlobalWorldGenerationRequest, profile: Dictionary) -> Dictionary:
    var geography_cells: Array[Dictionary] = []
    if request == null or not request.is_valid() or profile.is_empty():
        return {"ok": false, "failure_reason": "invalid_global_geography_input", "geography_cells": geography_cells}

    var cell_size: int = int(profile.get("geography_cell_size", 128))
    if cell_size <= 0:
        return {"ok": false, "failure_reason": "global_geography_cell_size_invalid", "geography_cells": geography_cells}

    var columns: int = ceili(float(request.bounds.size.x) / float(cell_size))
    var rows: int = ceili(float(request.bounds.size.y) / float(cell_size))
    if columns <= 0 or rows <= 0:
        return {"ok": false, "failure_reason": "global_geography_grid_invalid", "geography_cells": geography_cells}

    var center := Vector2i(
        request.bounds.position.x + request.bounds.size.x / 2,
        request.bounds.position.y + request.bounds.size.y / 2
    )
    var peak_centers: Array[Vector2i] = _peak_centers(request.seed, columns, rows)

    for gy in range(rows):
        for gx in range(columns):
            var origin := Vector2i(
                request.bounds.position.x + gx * cell_size,
                request.bounds.position.y + gy * cell_size
            )
            var width: int = mini(cell_size, request.bounds.position.x + request.bounds.size.x - origin.x)
            var height: int = mini(cell_size, request.bounds.position.y + request.bounds.size.y - origin.y)
            var rect := Rect2i(origin, Vector2i(width, height))
            var elevation: int = _elevation_for_cell(request.seed, gx, gy, peak_centers, profile)
            if _protected_integration_geography(rect, center, profile):
                elevation = mini(elevation, int(profile.get("rolling_elevation_max", 58)) - 2)
            elevation = clampi(elevation, 0, 100)
            geography_cells.append({
                "id": "%s.geography.%03d.%03d" % [request.world_id, gx, gy],
                "grid": Vector2i(gx, gy),
                "rect": rect,
                "elevation": elevation,
                "landform": _landform_for_elevation(elevation, profile),
            })

    return {"ok": true, "failure_reason": "", "geography_cells": geography_cells}

func _elevation_for_cell(
    seed: int,
    gx: int,
    gy: int,
    peak_centers: Array[Vector2i],
    profile: Dictionary
) -> int:
    var scale: int = maxi(1, int(profile.get("geography_noise_scale_cells", 4)))
    var broad: float = _value_noise(seed, gx, gy, scale, 101)
    var detail: float = Seed.unit_2d(seed, gx, gy, 211)
    var elevation: int = roundi((broad * 0.78 + detail * 0.22) * 100.0)
    var peak_boost: int = int(profile.get("geography_peak_boost", 46))
    for peak: Vector2i in peak_centers:
        var distance: int = absi(gx - peak.x) + absi(gy - peak.y)
        if distance == 0:
            elevation += peak_boost
        elif distance == 1:
            elevation += roundi(float(peak_boost) * 0.66)
        elif distance == 2:
            elevation += roundi(float(peak_boost) * 0.30)
    return clampi(elevation, 0, 100)

func _peak_centers(seed: int, columns: int, rows: int) -> Array[Vector2i]:
    if columns < 6 or rows < 6:
        return []
    var mid_x: int = columns / 2
    var mid_y: int = rows / 2
    var west_y_jitter: int = Seed.choose_index(seed, "geography:peak:west:y", 3) - 1
    var northeast_x_jitter: int = Seed.choose_index(seed, "geography:peak:northeast:x", 3) - 1
    var southwest_y_jitter: int = Seed.choose_index(seed, "geography:peak:southwest:y", 3) - 1
    return [
        Vector2i(clampi(2, 1, columns - 2), clampi(mid_y + west_y_jitter, 1, rows - 2)),
        Vector2i(clampi(columns - 4 + northeast_x_jitter, 1, columns - 2), clampi(2, 1, rows - 2)),
        Vector2i(clampi(3, 1, columns - 2), clampi(rows - 3 + southwest_y_jitter, 1, rows - 2)),
    ]

func _protected_integration_geography(rect: Rect2i, center: Vector2i, profile: Dictionary) -> bool:
    var half_span: int = int(profile.get("protected_cross_half_span", 384))
    var half_thickness: int = int(profile.get("protected_cross_half_thickness", 192))
    var horizontal := Rect2i(
        Vector2i(center.x - half_span, center.y - half_thickness),
        Vector2i(half_span * 2, half_thickness * 2)
    )
    var vertical := Rect2i(
        Vector2i(center.x - half_thickness, center.y - half_span),
        Vector2i(half_thickness * 2, half_span * 2)
    )
    return _rects_intersect(rect, horizontal) or _rects_intersect(rect, vertical)

func _landform_for_elevation(elevation: int, profile: Dictionary) -> StringName:
    var lowland_max: int = int(profile.get("lowland_elevation_max", 35))
    var rolling_max: int = int(profile.get("rolling_elevation_max", 58))
    var upland_max: int = int(profile.get("upland_elevation_max", 75))
    if elevation <= lowland_max:
        return &"lowland"
    if elevation <= rolling_max:
        return &"rolling"
    if elevation <= upland_max:
        return &"upland"
    return &"ridge"

func _value_noise(seed: int, gx: int, gy: int, scale: int, salt: int) -> float:
    var safe_scale: int = maxi(1, scale)
    var grid_x: int = floori(float(gx) / float(safe_scale))
    var grid_y: int = floori(float(gy) / float(safe_scale))
    var frac_x: float = float(gx - grid_x * safe_scale) / float(safe_scale)
    var frac_y: float = float(gy - grid_y * safe_scale) / float(safe_scale)
    var smooth_x: float = frac_x * frac_x * (3.0 - 2.0 * frac_x)
    var smooth_y: float = frac_y * frac_y * (3.0 - 2.0 * frac_y)
    var n00: float = Seed.unit_2d(seed, grid_x, grid_y, salt)
    var n10: float = Seed.unit_2d(seed, grid_x + 1, grid_y, salt)
    var n01: float = Seed.unit_2d(seed, grid_x, grid_y + 1, salt)
    var n11: float = Seed.unit_2d(seed, grid_x + 1, grid_y + 1, salt)
    var top: float = lerpf(n00, n10, smooth_x)
    var bottom: float = lerpf(n01, n11, smooth_x)
    return lerpf(top, bottom, smooth_y)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
