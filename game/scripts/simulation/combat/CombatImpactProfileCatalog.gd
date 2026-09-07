extends RefCounted
class_name CombatImpactProfileCatalog

const ProfileClass = preload("res://scripts/simulation/combat/CombatImpactProfile.gd")

## Small physical-contact catalog. Specialized shapes refine real semantics; any item
## with canonical mass still has a conservative generic blunt striking profile.

const _SPECIALIZED := {
    "item.crafting.sharpened_stake": {"mode": "point", "length": 90, "rigidity": 9000, "leverage": 10500, "balance": 10500, "transfer": 13000},
    "item.crafting.stone_hammer": {"mode": "blunt", "length": 35, "rigidity": 11000, "leverage": 12000, "balance": 9000, "transfer": 10500},
    "item.material.wood_plank": {"mode": "blunt", "length": 120, "rigidity": 8500, "leverage": 11500, "balance": 6500, "transfer": 10000},
    "item.material.scrap_metal": {"mode": "blunt", "length": 45, "rigidity": 12500, "leverage": 9500, "balance": 7000, "transfer": 11000},
}

func profile_for_item(semantic_type: StringName, weight_grams: int) -> CombatImpactProfile:
    if not String(semantic_type).begins_with("item.") or weight_grams <= 0:
        return null
    var key := String(semantic_type)
    if _SPECIALIZED.has(key):
        var data: Dictionary = _SPECIALIZED[key]
        return ProfileClass.new(
            semantic_type,
            StringName(String(data.get("mode", "blunt"))),
            int(data.get("length", 25)),
            int(data.get("rigidity", 7000)),
            int(data.get("leverage", 7500)),
            int(data.get("balance", 8500)),
            int(data.get("transfer", 10000))
        )
    # Generic improvised use is deliberately weak but truthful: real mass plus a
    # conservative hand-object geometry, not a secret weapon damage table.
    return ProfileClass.new(semantic_type, ProfileClass.BLUNT, 25, 6500, 7000, 9000, 8500)

func unarmed_profile() -> CombatImpactProfile:
    return ProfileClass.new(&"body.unarmed", ProfileClass.BLUNT, 15, 8500, 7500, 11000, 9000)
