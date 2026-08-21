extends RefCounted
class_name EnvironmentProfileCatalog

const TEMPERATE_RURAL: StringName = &"temperate.rural"

func has_profile(profile_id: StringName) -> bool:
    return profile_id == TEMPERATE_RURAL

func profile(profile_id: StringName) -> Dictionary:
    if profile_id != TEMPERATE_RURAL:
        return {}
    return {
        "id": TEMPERATE_RURAL,
        "version": 1,
        "base_ground": &"ground.grass_lush",
        "road_ground": &"ground.road",
        "driveway_ground": &"ground.driveway_gravel",
        "field_ground": &"ground.field_green",
        "tree_semantics": [&"prop.deciduous_large", &"prop.deciduous_small"],
        "fence_semantic": &"prop.wood_fence",
        "mailbox_semantic": &"prop.curb_mailbox",
        "traffic_signal_semantic": &"prop.traffic_light",
    }
