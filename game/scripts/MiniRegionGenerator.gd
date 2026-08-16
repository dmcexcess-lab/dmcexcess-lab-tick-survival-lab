extends RefCounted
class_name MiniRegionGenerator

const BaseRegion = preload("res://scripts/ProceduralRegionGenerator.gd")
const FocusPass = preload("res://scripts/MiniRegionFocusPass.gd")
const Streetscape = preload("res://scripts/StreetscapePass.gd")
const InteriorPass = preload("res://scripts/DestinationInteriorPass.gd")

const REGION_W := BaseRegion.REGION_W
const REGION_H := BaseRegion.REGION_H
const GENERATOR_VERSION := 6
const ROAD_N := BaseRegion.ROAD_N
const ROAD_E := BaseRegion.ROAD_E
const ROAD_S := BaseRegion.ROAD_S
const ROAD_W := BaseRegion.ROAD_W
const BIOMES := BaseRegion.BIOMES
const DIRS := BaseRegion.DIRS

static func generate(seed_value: int, width: int = REGION_W, height: int = REGION_H, focus: String = "mixed") -> Dictionary:
    var spec: Dictionary = BaseRegion.generate(seed_value, width, height)
    spec["base_generator_version"] = BaseRegion.GENERATOR_VERSION
    spec["generator_version"] = GENERATOR_VERSION
    spec["region_focus"] = focus
    spec["display_name"] = _display_name(focus)
    FocusPass.apply(spec, focus)
    Streetscape.apply(spec, seed_value, focus)
    InteriorPass.apply(spec, seed_value, focus)
    return spec

static func validate(spec: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    var base_result: Dictionary = BaseRegion.validate(spec)
    if not bool(base_result.get("ok", false)):
        for failure_value in base_result.get("failures", []):
            var failure := str(failure_value)
            # V4 was a one-region whole-world stress map, so it required every
            # 64x64 seed to contain a substantial patch of every biome. Focused
            # extraction raids intentionally use one destination identity.
            if failure.begins_with("biome too small"):
                continue
            # V4 also used one minimum footprint for every building. V6 keeps
            # intentionally narrow trailers and shallow multi-unit storefronts.
            if failure.begins_with("generated building footprint too small"):
                continue
            failures.append(failure)

    var street_result: Dictionary = Streetscape.validate(spec)
    if not bool(street_result.get("ok", false)):
        for failure_value in street_result.get("failures", []):
            failures.append(str(failure_value))

    var interior_result: Dictionary = InteriorPass.validate(spec)
    if not bool(interior_result.get("ok", false)):
        for failure_value in interior_result.get("failures", []):
            failures.append(str(failure_value))

    for building_value in spec.get("building_rects", []):
        var building: Array = building_value
        if building.size() < 6:
            continue
        var w := int(building[2])
        var h := int(building[3])
        var kind := str(building[5])
        if kind == "trailer":
            if maxi(w, h) < 8 or mini(w, h) < 5:
                failures.append("trailer footprint invalid: %s" % str(building))
                break
        elif kind.begins_with("strip_mall"):
            if maxi(w, h) < 8 or mini(w, h) < 5:
                failures.append("strip mall footprint invalid: %s" % str(building))
                break
        elif w < 8 or h < 8:
            failures.append("standard building footprint too small: %s" % str(building))
            break

    var focus := str(spec.get("region_focus", "mixed"))
    if focus in ["residential", "commercial", "downtown"] and not _has_large_destination_building(spec, focus):
        failures.append("focused raid missing large destination interior: %s" % focus)

    if int(spec.get("generator_version", 0)) != GENERATOR_VERSION:
        failures.append("mini region generator version missing")
    return {
        "ok": failures.is_empty(),
        "failures": failures,
        "biome_counts": base_result.get("biome_counts", {}),
    }

static func _has_large_destination_building(spec: Dictionary, focus: String) -> bool:
    var minimum_area := 110
    if focus in ["commercial", "downtown"]:
        minimum_area = 130
    for building_value in spec.get("building_rects", []):
        var building: Array = building_value
        if building.size() < 5:
            continue
        var area := int(building[2]) * int(building[3])
        if area >= minimum_area:
            return true
    return false

static func _display_name(focus: String) -> String:
    match focus:
        "downtown": return "Office / Downtown Raid"
        "commercial": return "Shops / Strip Mall Raid"
        "residential": return "Residential Raid"
        "woods": return "Woodland Raid"
        "rural": return "Rural Raid"
        _: return "Mixed Raid"
