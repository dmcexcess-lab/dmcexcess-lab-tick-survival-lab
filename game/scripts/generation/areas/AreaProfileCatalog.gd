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
        "version": 3,
        "center_exclusion_radius": 30,
        "edge_margin": 8,
        "parcel_gap": 3,
        "parcel_road_gap": 1,
        "parcel_buildable_margin": 1,
        "primary_parcel_depth": 24,
        "secondary_parcel_depth": 24,
        "local_parcel_depth": 20,
        "frontage_min": 28,
        "frontage_max": 36,
        "local_frontage_min": 20,
        "local_frontage_max": 26,
        "local_frontage_end_margin": 5,
        "commercial_count": 3,
        "residential_count": 6,
        "farmstead_count": 4,
        "local_residential_target": 4,
        "local_farmstead_target": 3,
        "local_road_spurs": 2,
        "local_spur_width": 3,
        "local_spur_branch_offset": 64,
        "local_spur_first_leg": 36,
        "local_spur_lateral_leg": 44,
        "local_spur_second_leg": 46,
        "local_spur_tail_leg": 28,
        "residential_setback": 1,
        "farmstead_setback": 4,
        "commercial_setback": 4,
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
