extends RefCounted
class_name BaselineGridParcelPlanner

const BaseParcelPlannerClass = preload("res://scripts/generation/areas/ParcelPlanner.gd")

var _base_planner := BaseParcelPlannerClass.new()

func plan(
    request: AreaGenerationRequest,
    profile: Dictionary,
    roads: Array[Dictionary],
    intersections: Array[Dictionary],
    reservations: Array[Dictionary] = []
) -> Dictionary:
    if request == null or profile.is_empty() or StringName(profile.get("land_use_mode", &"")) != &"baseline_grid":
        return {"ok": false, "failure_reason": "baseline_grid_profile_required", "parcels": []}

    var geometry_profile: Dictionary = profile.duplicate(true)
    geometry_profile["land_use_mode"] = &"smalltown_center"
    geometry_profile["commercial_count"] = 0
    geometry_profile["residential_count"] = 0
    geometry_profile["farmstead_count"] = 0
    geometry_profile["local_residential_target"] = 0
    geometry_profile["local_farmstead_target"] = 0

    var geometry_result: Dictionary = _base_planner.plan(request, geometry_profile, roads, intersections, reservations)
    if not bool(geometry_result.get("ok", false)):
        return geometry_result

    var parcels: Array[Dictionary] = []
    for value: Variant in geometry_result.get("parcels", []):
        if typeof(value) != TYPE_DICTIONARY:
            return {"ok": false, "failure_reason": "baseline_grid_parcel_geometry_invalid", "parcels": []}
        var parcel: Dictionary = value
        parcel["land_use"] = &"unclassified"
        parcels.append(parcel)

    var commercial_target: int = int(profile.get("commercial_count", 0))
    var residential_target: int = int(profile.get("residential_count", 0))
    var civic_target: int = int(profile.get("civic_count", 0))
    var industrial_target: int = int(profile.get("industrial_count", 0))
    var required_total: int = commercial_target + residential_target + civic_target + industrial_target
    if parcels.size() < required_total:
        return {"ok": false, "failure_reason": "baseline_grid_insufficient_parcels", "parcels": parcels}

    _sort_nearest(parcels)
    _assign_preferred_road(parcels, &"commercial_small", commercial_target, &"primary", false)
    _assign_any(parcels, &"commercial_small", commercial_target - _count(parcels, &"commercial_small"), false)

    _assign_preferred_road(parcels, &"civic", civic_target, &"local_town", false)
    _assign_any(parcels, &"civic", civic_target - _count(parcels, &"civic"), false)

    var local_residential_target: int = mini(residential_target, int(profile.get("local_residential_target", residential_target)))
    _assign_preferred_road(parcels, &"residential", local_residential_target, &"local_town", false)
    _assign_any(parcels, &"residential", residential_target - _count(parcels, &"residential"), false)

    _assign_preferred_road(parcels, &"industrial", industrial_target, &"local_town", true)
    _assign_any(parcels, &"industrial", industrial_target - _count(parcels, &"industrial"), true)

    if _count(parcels, &"commercial_small") != commercial_target \
        or _count(parcels, &"residential") != residential_target \
        or _count(parcels, &"civic") != civic_target \
        or _count(parcels, &"industrial") != industrial_target:
        return {"ok": false, "failure_reason": "baseline_grid_land_use_targets_unmet", "parcels": parcels}

    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) == &"unclassified":
            parcel["land_use"] = &"vacant"
    return {"ok": true, "failure_reason": "", "parcels": parcels}

func _assign_preferred_road(
    parcels: Array[Dictionary],
    land_use: StringName,
    target: int,
    road_class: StringName,
    farthest_first: bool
) -> void:
    if target <= 0:
        return
    var candidates: Array[Dictionary] = []
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) != &"unclassified":
            continue
        if StringName(parcel.get("frontage_road_class", &"")) != road_class:
            continue
        candidates.append(parcel)
    _sort_distance(candidates, farthest_first)
    var used: int = 0
    for parcel: Dictionary in candidates:
        if used >= target:
            break
        parcel["land_use"] = land_use
        used += 1

func _assign_any(parcels: Array[Dictionary], land_use: StringName, target: int, farthest_first: bool) -> void:
    if target <= 0:
        return
    var candidates: Array[Dictionary] = []
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) == &"unclassified":
            candidates.append(parcel)
    _sort_distance(candidates, farthest_first)
    var used: int = 0
    for parcel: Dictionary in candidates:
        if used >= target:
            break
        parcel["land_use"] = land_use
        used += 1

func _sort_nearest(parcels: Array[Dictionary]) -> void:
    _sort_distance(parcels, false)

func _sort_distance(parcels: Array[Dictionary], farthest_first: bool) -> void:
    parcels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var da: int = int(a.get("distance_to_center", 0))
        var db: int = int(b.get("distance_to_center", 0))
        if da != db:
            return da > db if farthest_first else da < db
        return String(a.get("id", "")) < String(b.get("id", ""))
    )

func _count(parcels: Array[Dictionary], land_use: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) == land_use:
            count += 1
    return count
