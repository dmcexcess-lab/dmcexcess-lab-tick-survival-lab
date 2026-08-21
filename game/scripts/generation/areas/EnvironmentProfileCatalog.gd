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
        "version": 3,
        "base_ground": &"ground.grass_lush",
        "road_ground": &"ground.road_plain",
        "road_surface_ground": &"ground.road_plain",
        "road_centerline_horizontal": &"ground.road_yellow_line_h",
        "road_centerline_vertical": &"ground.road_yellow_line_v",
        "local_road_ground": &"ground.gravel_dark",
        "driveway_ground": &"ground.driveway_gravel",
        "field_ground": &"ground.field_green",
        "tree_semantics": [&"prop.deciduous_large", &"prop.deciduous_small"],
        "shrub_semantics": [&"prop.dense_bush", &"prop.thorn_bush"],
        "rock_semantics": [&"prop.rock_small", &"prop.rock_cluster", &"prop.mossy_rock"],
        "natural_noise_density": 0.0105,
        "natural_noise_patch_scale": 22,
        "natural_noise_sparse_multiplier": 0.20,
        "natural_noise_dense_multiplier": 2.25,
        "natural_road_clearance": 1,
        "natural_center_clear_radius": 24,
        "fence_semantic": &"prop.wood_fence",
        "mailbox_semantic": &"prop.curb_mailbox",
        "traffic_signal_semantic": &"prop.traffic_light",
    }
