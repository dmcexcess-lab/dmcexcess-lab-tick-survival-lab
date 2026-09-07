extends RefCounted
class_name FirearmProfileCatalog

const SERVICE_PISTOL: StringName = &"item.firearm.service_pistol"
const SERVICE_MAGAZINE: StringName = &"item.firearm.magazine.9mm"
const SERVICE_ROUND: StringName = &"item.ammo.9mm_round"

const _PROFILES := {
    "item.firearm.service_pistol": {
        "magazine_type": "item.firearm.magazine.9mm",
        "ammo_type": "item.ammo.9mm_round",
        "max_range_cells": 12,
        "snap_range_cells": 6,
        "impact_damage": 34,
        "gunshot_power": 760,
        "weight_grams": 950,
    },
}

func has_firearm(semantic_type: StringName) -> bool:
    return _PROFILES.has(String(semantic_type))

func profile(semantic_type: StringName) -> Dictionary:
    var key := String(semantic_type)
    if not _PROFILES.has(key): return {}
    return Dictionary(_PROFILES[key]).duplicate(true)

func magazine_type(semantic_type: StringName) -> StringName:
    return StringName(String(profile(semantic_type).get("magazine_type", "")))

func ammo_type(semantic_type: StringName) -> StringName:
    return StringName(String(profile(semantic_type).get("ammo_type", "")))

func max_range_cells(semantic_type: StringName) -> int:
    return int(profile(semantic_type).get("max_range_cells", 0))

func snap_range_cells(semantic_type: StringName) -> int:
    return int(profile(semantic_type).get("snap_range_cells", 0))

func impact_damage(semantic_type: StringName) -> int:
    return int(profile(semantic_type).get("impact_damage", 0))

func gunshot_power(semantic_type: StringName) -> int:
    return int(profile(semantic_type).get("gunshot_power", 0))

func register_physical_profiles(catalog: ItemPhysicalPropertyCatalog) -> bool:
    if catalog == null: return false
    var entries := {
        SERVICE_PISTOL: 950,
        SERVICE_MAGAZINE: 130,
        SERVICE_ROUND: 12,
    }
    for semantic_type: StringName in entries.keys():
        if catalog.has_profile(semantic_type): continue
        if not catalog.register_profile(semantic_type, int(entries[semantic_type])): return false
    return true
