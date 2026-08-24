extends RefCounted
class_name EnvironmentProfileCatalog

const TEMPERATE_RURAL: StringName = &"temperate.rural"
const TEMPERATE_SUBURBAN: StringName = &"temperate.suburban"
const TEMPERATE_URBAN: StringName = &"temperate.urban"
const TEMPERATE_INDUSTRIAL: StringName = &"temperate.industrial"
const TEMPERATE_WOODLAND: StringName = &"temperate.woodland"
const TEMPERATE_COASTAL: StringName = &"temperate.coastal"
const TEMPERATE_MARSH: StringName = &"temperate.marsh"

const PROFILE_IDS: Array[StringName] = [
    TEMPERATE_RURAL,
    TEMPERATE_SUBURBAN,
    TEMPERATE_URBAN,
    TEMPERATE_INDUSTRIAL,
    TEMPERATE_WOODLAND,
    TEMPERATE_COASTAL,
    TEMPERATE_MARSH,
]

func profile_ids() -> Array[StringName]:
    return PROFILE_IDS.duplicate()

func has_profile(profile_id: StringName) -> bool:
    return profile_id in PROFILE_IDS

func profile(profile_id: StringName) -> Dictionary:
    match profile_id:
        TEMPERATE_RURAL:
            return _environment(
                TEMPERATE_RURAL, 3,
                &"ground.grass_lush", &"ground.gravel_dark", &"ground.driveway_gravel", &"ground.field_green",
                [&"prop.deciduous_large", &"prop.deciduous_small"],
                [&"prop.dense_bush", &"prop.thorn_bush"],
                [&"prop.rock_small", &"prop.rock_cluster", &"prop.mossy_rock"],
                0.0105, &"prop.wood_fence", &"prop.curb_mailbox"
            )
        TEMPERATE_SUBURBAN:
            return _environment(
                TEMPERATE_SUBURBAN, 1,
                &"ground.grass_lush", &"ground.road_plain", &"ground.concrete_clean", &"ground.field_green",
                [&"prop.deciduous_large", &"prop.deciduous_small"],
                [&"prop.dense_bush", &"prop.wildflowers"],
                [&"prop.rock_small", &"prop.mossy_rock"],
                0.0060, &"prop.privacy_fence", &"prop.curb_mailbox"
            )
        TEMPERATE_URBAN:
            return _environment(
                TEMPERATE_URBAN, 1,
                &"ground.concrete_clean", &"ground.alley_stained", &"ground.concrete_clean", &"ground.concrete_clean",
                [&"prop.deciduous_small"],
                [&"prop.street_planter", &"prop.weeds_patch"],
                [&"prop.rock_small"],
                0.0018, &"prop.chainlink_fence", &"prop.curb_mailbox"
            )
        TEMPERATE_INDUSTRIAL:
            return _environment(
                TEMPERATE_INDUSTRIAL, 1,
                &"ground.concrete_cracked", &"ground.alley_stained", &"ground.concrete_oil", &"ground.concrete_cracked",
                [&"prop.dead_tree", &"prop.deciduous_small"],
                [&"prop.weeds_patch", &"prop.thorn_bush"],
                [&"prop.rock_small", &"prop.rock_cluster"],
                0.0025, &"prop.chainlink_fence", &"prop.curb_mailbox"
            )
        TEMPERATE_WOODLAND:
            return _environment(
                TEMPERATE_WOODLAND, 1,
                &"ground.forest_floor", &"ground.gravel_dark", &"ground.driveway_gravel", &"ground.field_dry",
                [&"prop.pine_tree", &"prop.deciduous_large", &"prop.deciduous_small"],
                [&"prop.dense_bush", &"prop.sapling", &"prop.leaf_litter"],
                [&"prop.mossy_rock", &"prop.rock_cluster", &"prop.rock_small"],
                0.0300, &"prop.wood_fence", &"prop.curb_mailbox"
            )
        TEMPERATE_COASTAL:
            return _environment(
                TEMPERATE_COASTAL, 1,
                &"ground.beach_sand", &"ground.gravel_light", &"ground.concrete_clean", &"ground.sand",
                [&"prop.pine_tree", &"prop.deciduous_small"],
                [&"prop.tall_grass", &"prop.reeds", &"prop.dense_bush"],
                [&"prop.rock_small", &"prop.rock_cluster"],
                0.0120, &"prop.wood_fence", &"prop.curb_mailbox"
            )
        TEMPERATE_MARSH:
            return _environment(
                TEMPERATE_MARSH, 1,
                &"ground.marsh_ground", &"ground.gravel_dark", &"ground.gravel_light", &"ground.marsh_ground",
                [&"prop.dead_tree", &"prop.deciduous_small"],
                [&"prop.cattails", &"prop.reeds", &"prop.tall_grass"],
                [&"prop.mossy_rock", &"prop.rock_small"],
                0.0200, &"prop.wood_fence", &"prop.curb_mailbox"
            )
    return {}

func _environment(
    profile_id: StringName,
    version: int,
    base_ground: StringName,
    local_road_ground: StringName,
    driveway_ground: StringName,
    field_ground: StringName,
    trees: Array,
    shrubs: Array,
    rocks: Array,
    density: float,
    fence: StringName,
    mailbox: StringName
) -> Dictionary:
    return {
        "id": profile_id,
        "version": version,
        "base_ground": base_ground,
        "road_ground": &"ground.road_plain",
        "road_surface_ground": &"ground.road_plain",
        "road_centerline_horizontal": &"ground.road_yellow_line_h",
        "road_centerline_vertical": &"ground.road_yellow_line_v",
        "local_road_ground": local_road_ground,
        "driveway_ground": driveway_ground,
        "field_ground": field_ground,
        "tree_semantics": trees.duplicate(),
        "shrub_semantics": shrubs.duplicate(),
        "rock_semantics": rocks.duplicate(),
        "natural_noise_density": density,
        "natural_noise_patch_scale": 22,
        "natural_noise_sparse_multiplier": 0.20,
        "natural_noise_dense_multiplier": 2.25,
        "natural_road_clearance": 1,
        "natural_center_clear_radius": 24,
        "fence_semantic": fence,
        "mailbox_semantic": mailbox,
        "traffic_signal_semantic": &"prop.traffic_light",
    }
