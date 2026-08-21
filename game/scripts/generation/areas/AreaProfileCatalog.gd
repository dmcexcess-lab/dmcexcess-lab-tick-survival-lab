extends RefCounted
class_name AreaProfileCatalog

const RURAL_CROSSROADS: StringName = &"rural.crossroads"

func has_profile(profile_id: StringName) -> bool:
    return profile_id == RURAL_CROSSROADS

func profile(profile_id: StringName) -> Dictionary:
    if profile_id != RURAL_CROSSROADS:
        return {}
    return {
        "id": RURAL_CROSSROADS,
        "version": 2,
        "center_exclusion_radius": 30,
        "edge_margin": 8,
        "parcel_gap": 3,
        "primary_parcel_depth": 28,
        "secondary_parcel_depth": 32,
        "frontage_min": 28,
        "frontage_max": 36,
        "commercial_count": 3,
        "residential_count": 6,
        "farmstead_count": 4,
        "local_road_spurs": 1,
        "local_spur_width": 3,
        "local_spur_branch_offset": 64,
        "local_spur_first_leg": 20,
        "local_spur_lateral_leg": 20,
        "local_spur_second_leg": 30,
        "local_spur_tail_leg": 14,
        "residential_setback": 3,
        "farmstead_setback": 8,
        "commercial_setback": 1,
        "commercial_archetypes": [
            &"commercial.gas_station.small",
            &"commercial.diner.rural_small",
        ],
        "residential_archetypes": [
            &"residential.trailer.singlewide",
            &"residential.house.farm_small",
            &"residential.house.farm_large",
            &"residential.house.compact_laundry",
        ],
        "farmstead_archetypes": [
            &"residential.house.farm_small",
            &"residential.house.farm_large",
        ],
    }
