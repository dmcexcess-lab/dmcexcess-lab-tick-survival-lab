extends RefCounted
class_name MiniRegionGenerator

const BaseRegion = preload("res://scripts/ProceduralRegionGenerator.gd")
const Streetscape = preload("res://scripts/StreetscapePass.gd")

const REGION_W := BaseRegion.REGION_W
const REGION_H := BaseRegion.REGION_H
const GENERATOR_VERSION := 5
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
    Streetscape.apply(spec, seed_value, focus)
    return spec

static func validate(spec: Dictionary) -> Dictionary:
    var failures: Array[String] = []
    var base_result: Dictionary = BaseRegion.validate(spec)
    if not bool(base_result.get("ok", false)):
        for failure_value in base_result.get("failures", []):
            var failure := str(failure_value)
            # Generator v4 used one minimum footprint for every building. V5
            # intentionally adds narrow trailers and shallow strip malls, so
            # size validation is family-aware below instead.
            if failure.begins_with("generated building footprint too small"):
                continue
            failures.append(failure)

    var street_result: Dictionary = Streetscape.validate(spec)
    if not bool(street_result.get("ok", false)):
        for failure_value in street_result.get("failures", []):
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

    if int(spec.get("generator_version", 0)) != GENERATOR_VERSION:
        failures.append("mini region generator version missing")
    return {
        "ok": failures.is_empty(),
        "failures": failures,
        "biome_counts": base_result.get("biome_counts", {}),
    }

static func _display_name(focus: String) -> String:
    match focus:
        "downtown": return "Downtown District"
        "commercial": return "Commercial District"
        "residential": return "Residential District"
        "woods": return "Woodland District"
        "rural": return "Rural District"
        _: return "Mixed District"
