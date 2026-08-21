extends RefCounted
class_name GlobalWorldProfileCatalog

const TEMPERATE_RURAL_REGION: StringName = &"temperate.rural.region"

func has_profile(profile_id: StringName) -> bool:
    return profile_id == TEMPERATE_RURAL_REGION

func profile(profile_id: StringName) -> Dictionary:
    if profile_id != TEMPERATE_RURAL_REGION:
        return {}
    return {
        "id": TEMPERATE_RURAL_REGION,
        "version": 1,
        "minimum_world_size": Vector2i(1536, 1536),
        "local_site_size": Vector2i(256, 256),
        "primary_width": 5,
        "secondary_width": 3,
        "smalltown_distance_min": 520,
        "smalltown_distance_max": 620,
        "north_hamlet_distance_min": 500,
        "north_hamlet_distance_max": 610,
        "southwest_x_distance_min": 440,
        "southwest_x_distance_max": 560,
        "southwest_y_distance_min": 500,
        "southwest_y_distance_max": 620,
        "northeast_x_distance_min": 450,
        "northeast_x_distance_max": 570,
        "northeast_y_distance_min": 460,
        "northeast_y_distance_max": 580,
        "crossroads_influence_radius": 160,
        "smalltown_influence_radius": 256,
        "hamlet_influence_radius": 192,
    }
