extends RefCounted
class_name ArtCatalog

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const ArtSourceClass = preload("res://scripts/art/ArtSource.gd")
const ArtSelectionClass = preload("res://scripts/art/ArtSelection.gd")
const RoadTopology = preload("res://scripts/art/RoadArtTopology.gd")

## Canonical recovered semantic art-selection catalog.
## This module returns descriptors only. Renderers own texture caching and drawing.

const SOURCE_TACTICAL: StringName = &"tactical"
const SOURCE_CLUTTER: StringName = &"clutter"
const SOURCE_WORLD: StringName = &"world"
const SOURCE_BUILDING: StringName = &"building_props"
const SOURCE_FINAL_SURFACES: StringName = &"final_surfaces"
const SOURCE_FINAL_PROPS: StringName = &"final_props"
const SOURCE_ACTORS: StringName = &"actors"
const SOURCE_HELD_ITEMS: StringName = &"held_items"
const SOURCE_PLAYER_NORTH: StringName = &"player_north"
const SOURCE_PLAYER_EAST: StringName = &"player_east"
const SOURCE_PLAYER_SOUTH: StringName = &"player_south"
const SOURCE_PLAYER_WEST: StringName = &"player_west"

const ATLAS_CELL_PIXELS: int = 32
const ATLAS_COLUMNS: int = 16
const LIVING_ACTOR_VARIANTS: int = 8
const HELD_ITEM_WEAPON_SCALE: float = 14.0 / 32.0
const HELD_ITEM_UTILITY_SCALE: float = 12.0 / 32.0

const GROUND := {
    "asphalt": 0, "road": 1, "sidewalk": 2, "concrete": 3, "tile": 4,
    "wood": 5, "carpet": 6, "linoleum": 7, "grass": 8, "dirt": 9,
    "wash_concrete": 10,
}

const WORLD_GROUND := {
    "road_v": 0, "road_h": 1,
    "road_ne": 2, "road_es": 3, "road_sw": 4, "road_wn": 5,
    "road_t_nes": 6, "road_t_esw": 7, "road_t_swn": 8, "road_t_wne": 9,
    "road_cross": 10,
    "road_end_n": 11, "road_end_e": 12, "road_end_s": 13, "road_end_w": 14,
    "road_plain": 15,
    "sidewalk": 16,
    "sidewalk_curb_n": 17, "sidewalk_curb_e": 18, "sidewalk_curb_s": 19, "sidewalk_curb_w": 20,
    "driveway": 21,
    "parking": 22, "parking_v": 23,
    "crosswalk_h": 24, "crosswalk_v": 25,
    "cracked_asphalt": 26, "stained_concrete": 27,
    "dirt_road_h": 28, "dirt_road_v": 29, "gravel": 30, "field_rows": 31,
    "hardwood_h": 32, "hardwood_v": 33,
    "kitchen_tile": 34, "bathroom_tile": 35,
    "office_carpet": 36, "worn_carpet": 37,
    "warehouse_floor": 38, "shop_floor": 39,
}

const FINAL_GROUND := {
    "grass_lush": 0, "grass_dry": 1, "grass_weedy": 2, "forest_floor": 3,
    "mud": 4, "sand": 5, "beach_sand": 6, "moss_ground": 7,
    "marsh_ground": 8, "rocky_ground": 9, "dirt_dark": 10, "dirt_light": 11,
    "gravel_dark": 12, "gravel_light": 13, "field_green": 14, "field_dry": 15,
    "asphalt_patch": 16, "pothole": 17, "road_white_line_h": 18, "road_white_line_v": 19,
    "road_yellow_line_h": 20, "road_yellow_line_v": 21, "shoulder_gravel": 22, "curb_ramp": 23,
    "patio_pavers": 24, "brick_pavers": 25, "concrete_clean": 26, "concrete_cracked": 27,
    "concrete_oil": 28, "driveway_gravel": 29, "parking_faded": 30, "alley_stained": 31,
    "laminate_light": 32, "laminate_dark": 33, "wood_parquet": 34, "carpet_blue": 35,
    "carpet_beige": 36, "carpet_green": 37, "tile_white": 38, "tile_blackwhite": 39,
    "tile_mosaic": 40, "linoleum_green": 41, "linoleum_yellow": 42, "garage_floor": 43,
    "basement_floor": 44, "restaurant_floor": 45, "hospital_floor": 46, "classroom_floor": 47,
}

const FINAL_GROUND_ALIAS := {
    "grass": 0, "dirt": 11, "asphalt": 16, "concrete": 26, "tile": 38,
    "wood": 32, "carpet": 36, "linoleum": 41, "wash_concrete": 27,
}

const WALL_BY_THEME := {
    "alley": 16, "gas": 17, "house": 18, "apartment": 19,
    "store": 20, "industrial": 21, "wash": 22,
}

const WORLD_WALL_BY_THEME := {
    "house": 40, "siding": 40,
    "apartment": 41, "brick": 41, "store": 41,
    "industrial": 42, "cinder": 42,
    "interior": 43, "drywall": 43,
    "office": 44, "warehouse": 45, "rural_wood": 46, "storefront": 47,
}

const FINAL_WALL_BY_THEME := {
    "wallpaper": 48, "paneling": 49, "red_brick": 50, "white_brick": 51,
    "stone": 52, "tile": 53, "tile_wall": 53, "glass_partition": 54,
    "plaster": 55, "concrete": 56, "concrete_wall": 56, "metal_panel": 57,
}

const PROP := {
    "dumpster": 32, "trash": 33, "neon_sign": 34, "gas_pump": 35,
    "car": 36, "counter": 37, "store_shelf": 38, "gas_sign": 39,
    "ice_box": 40, "couch": 41, "table": 42, "bed": 43,
    "kitchen": 44, "fridge": 45, "washer": 46, "vending": 47,
    "crate": 48, "pallet": 49, "forklift": 50, "machine": 51,
    "scrub": 52, "shopping_cart": 53, "culvert_debris": 54,
    "apt_sign": 55, "shop_sign": 55, "warehouse_sign": 55, "wash_sign": 55,
}

const CLUTTER_PROP := {
    "chair": 0, "desk": 1, "toilet": 2, "sink": 3,
    "cabinet": 4, "bookshelf": 5, "tv": 6, "lamp": 7,
    "tree": 8, "bush": 9, "fence": 10, "mailbox": 11,
    "trash_can": 12, "road_sign": 13, "bench": 14, "hydrant": 15,
    "streetlight": 16, "rug": 17, "laundry": 18, "planter": 19,
    "tire_pile": 20, "cardboard": 21, "picnic_table": 22, "firewood": 23,
}

const BUILDING_PROP := {
    "stove": 0, "kitchen_counter": 1, "dresser": 2, "nightstand": 3,
    "bathtub": 4, "shower": 5, "vanity": 6, "dining_table": 7,
    "armchair": 8, "filing_cabinet": 9, "cubicle": 10, "computer": 11,
    "checkout": 12, "freezer": 13, "produce_bin": 14, "pallet_rack": 15,
    "tool_chest": 16, "workbench": 17, "locker": 18, "utility_sink": 19,
    "water_heater": 20, "exterior_ac": 21, "electric_meter": 22, "utility_pole": 23,
    "traffic_light": 24, "stop_sign": 25, "parking_meter": 26, "bollard": 27,
    "hedge": 28, "flower_bed": 29, "shed": 30, "propane_tank": 31,
}

const FINAL_PROP := {
    "deciduous_small": 0, "deciduous_large": 1, "pine_tree": 2, "dead_tree": 3,
    "tree_stump": 4, "fallen_log": 5, "rock_small": 6, "rock_cluster": 7,
    "dense_bush": 8, "thorn_bush": 9, "tall_grass": 10, "weeds_patch": 11,
    "wildflowers": 12, "reeds": 13, "vine_patch": 14, "leaf_litter": 15,
    "branch_pile": 16, "brush_pile": 17, "dirt_mound": 18, "garden_patch": 19,
    "crop_green": 20, "crop_dry": 21, "hay_bale": 22, "compost_pile": 23,
    "cactus": 24, "palm_tree": 25, "desert_scrub": 26, "cattails": 27,
    "mushroom_patch": 28, "mossy_rock": 29, "sapling": 30, "fallen_branches": 31,
    "yield_sign": 32, "speed_limit_sign": 33, "no_parking_sign": 34, "street_name_sign": 35,
    "one_way_sign": 36, "dead_end_sign": 37, "road_work_sign": 38, "pedestrian_sign": 39,
    "bus_stop_sign": 40, "public_trash_bin": 41, "guardrail": 42, "chainlink_fence": 43,
    "wood_fence": 44, "privacy_fence": 45, "traffic_cone": 46, "road_barricade": 47,
    "storm_drain": 48, "manhole": 49, "utility_box": 50, "transformer": 51,
    "phone_box": 52, "newspaper_box": 53, "bike_rack": 54, "crosswalk_beacon": 55,
    "parking_sign": 56, "fire_call_box": 57, "road_barrier": 58, "sewer_grate": 59,
    "street_planter": 60, "curb_mailbox": 61, "utility_pole_wood": 62, "utility_pole_transformer": 63,
    "refrigerator_white": 64, "refrigerator_stainless": 65, "stove_range": 66, "kitchen_sink": 67,
    "counter_straight": 68, "counter_corner": 69, "pantry": 70, "dishwasher": 71,
    "kitchen_island": 72, "microwave_counter": 73, "breakfast_table": 74, "dining_chair": 75,
    "sofa": 76, "loveseat": 77, "recliner": 78, "coffee_table": 79,
    "tv_flat": 80, "tv_old": 81, "tv_stand": 82, "bookshelf_tall": 83,
    "end_table": 84, "floor_lamp": 85, "bed_single": 86, "bed_double": 87,
    "bunk_bed": 88, "dresser_wide": 89, "wardrobe": 90, "home_desk": 91,
    "desk_chair": 92, "hamper": 93, "toilet_modern": 94, "pedestal_sink": 95,
    "bathroom_vanity": 96, "bathtub_clawfoot": 97, "shower_stall": 98, "towel_rack": 99,
    "medicine_cabinet": 100, "washer_front": 101, "dryer_front": 102, "water_heater_tall": 103,
    "retail_shelf": 104, "retail_endcap": 105, "walkin_cooler": 106, "chest_freezer": 107,
    "produce_display": 108, "restaurant_table": 109, "restaurant_booth": 110, "office_desk": 111,
    "office_chair": 112, "file_cabinet_tall": 113, "copier": 114, "cubicle_corner": 115,
    "server_rack": 116, "pallet_stack": 117, "warehouse_rack": 118, "workbench_heavy": 119,
    "tool_cabinet": 120, "industrial_machine": 121, "portable_generator": 122, "locker_bank": 123,
    "janitor_sink": 124, "janitor_cart": 125, "vending_machine": 126, "breakroom_table": 127,
}

const FINAL_PROP_ALIAS := {
    "tree": 1, "bush": 8, "road_sign": 35, "fence": 44, "mailbox": 61,
    "chair": 75, "desk": 91, "toilet": 94, "sink": 95, "cabinet": 70,
    "bookshelf": 83, "tv": 80, "laundry": 93, "couch": 76, "table": 74,
    "bed": 86, "kitchen": 68, "fridge": 64, "washer": 101, "store_shelf": 104,
}

const DOOR_CLOSED := {
    "house": 48, "siding": 48, "rural_wood": 48,
    "store": 50, "commercial": 50,
    "industrial": 52, "warehouse": 52,
    "storefront": 54, "office": 54,
    "garage": 56,
}

const DOOR_OPEN := {
    "house": 49, "siding": 49, "rural_wood": 49,
    "store": 51, "commercial": 51,
    "industrial": 53, "warehouse": 53,
    "storefront": 55, "office": 55,
    "garage": 57,
}

const WINDOW_BY_THEME := {
    "house": 58, "siding": 58, "rural_wood": 58,
    "store": 59, "commercial": 59, "storefront": 59,
    "industrial": 60, "warehouse": 60,
    "office": 61, "apartment": 61,
}

const LIVING_ACTOR_BASE := {
    "survivor": 0,
    "infected": 32,
}

const HELD_ITEM_INDEX := {
    "utility_knife": 0,
    "kitchen_knife": 0,
    "wooden_club": 1,
    "baseball_bat": 1,
    "hammer": 2,
    "improvised_spear": 3,
    "crowbar": 4,
    "hatchet": 5,
    "pistol": 6,
    "shotgun": 7,
    "flashlight": 8,
    "headlamp": 9,
    "lantern": 10,
    "glow_stick": 11,
    "road_flare": 12,
}

const HELD_ITEM_WEAPON_KIND := {
    "utility_knife": true,
    "kitchen_knife": true,
    "wooden_club": true,
    "baseball_bat": true,
    "hammer": true,
    "improvised_spear": true,
    "crowbar": true,
    "hatchet": true,
    "pistol": true,
    "shotgun": true,
}

var _sources: Dictionary = {}

func _init() -> void:
    _register_source(SOURCE_TACTICAL, "res://assets/tactical_atlas.svg", true)
    _register_source(SOURCE_CLUTTER, "res://assets/clutter_atlas.svg", true)
    _register_source(SOURCE_WORLD, "res://assets/world_art_atlas.svg", true)
    _register_source(SOURCE_BUILDING, "res://assets/building_props_atlas.svg", true)
    _register_source(SOURCE_FINAL_SURFACES, "res://assets/final_environment_surfaces_atlas.svg", true)
    _register_source(SOURCE_FINAL_PROPS, "res://assets/final_environment_props_atlas.svg", true)
    _register_source(SOURCE_ACTORS, "res://assets/actor_atlas.svg", true)
    _register_source(SOURCE_HELD_ITEMS, "res://assets/held_item_atlas.svg", true)
    _register_source(SOURCE_PLAYER_NORTH, "res://assets/player_north.svg", false)
    _register_source(SOURCE_PLAYER_EAST, "res://assets/player_east.svg", false)
    _register_source(SOURCE_PLAYER_SOUTH, "res://assets/player_south.svg", false)
    _register_source(SOURCE_PLAYER_WEST, "res://assets/player_west.svg", false)

func source(source_id: StringName) -> ArtSource:
    if not _sources.has(source_id):
        return null
    var value: ArtSource = _sources[source_id]
    return value.copy()

func source_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _sources.keys():
        result.append(StringName(key))
    result.sort()
    return result

func mapping_counts() -> Dictionary:
    return {
        "ground_tactical": GROUND.size(),
        "ground_world": WORLD_GROUND.size(),
        "ground_final": FINAL_GROUND.size(),
        "ground_final_alias": FINAL_GROUND_ALIAS.size(),
        "wall_tactical": WALL_BY_THEME.size(),
        "wall_world": WORLD_WALL_BY_THEME.size(),
        "wall_final": FINAL_WALL_BY_THEME.size(),
        "prop_tactical": PROP.size() + 1,
        "prop_clutter": CLUTTER_PROP.size(),
        "prop_building": BUILDING_PROP.size(),
        "prop_final": FINAL_PROP.size(),
        "prop_final_alias": FINAL_PROP_ALIAS.size(),
        "actor_survivor": LIVING_ACTOR_VARIANTS * 4,
        "actor_infected": LIVING_ACTOR_VARIANTS * 4,
        "held_item": HELD_ITEM_INDEX.size(),
    }

func resolve_ground(semantic_id: StringName) -> ArtSelection:
    var token: String = _leaf_token(semantic_id)
    if token.is_empty():
        return _unknown(semantic_id, "ground_unclassified")
    if FINAL_GROUND.has(token):
        return _found(semantic_id, SOURCE_FINAL_SURFACES, int(FINAL_GROUND[token]))
    if FINAL_GROUND_ALIAS.has(token):
        return _found(semantic_id, SOURCE_FINAL_SURFACES, int(FINAL_GROUND_ALIAS[token]))
    if WORLD_GROUND.has(token):
        return _found(semantic_id, SOURCE_WORLD, int(WORLD_GROUND[token]))
    if GROUND.has(token):
        return _found(semantic_id, SOURCE_TACTICAL, int(GROUND[token]))
    return _unknown(semantic_id, "ground_unclassified")

func resolve_wall(semantic_id: StringName) -> ArtSelection:
    var token: String = _leaf_token(semantic_id)
    if token.is_empty():
        return _unknown(semantic_id, "wall_unclassified")
    if FINAL_WALL_BY_THEME.has(token):
        return _found(semantic_id, SOURCE_FINAL_SURFACES, int(FINAL_WALL_BY_THEME[token]))
    if WORLD_WALL_BY_THEME.has(token):
        return _found(semantic_id, SOURCE_WORLD, int(WORLD_WALL_BY_THEME[token]))
    if WALL_BY_THEME.has(token):
        return _found(semantic_id, SOURCE_TACTICAL, int(WALL_BY_THEME[token]))
    return _unknown(semantic_id, "wall_unclassified")

func resolve_door(theme: StringName = &"", opened: bool = false) -> ArtSelection:
    var token: String = _leaf_token(theme)
    var requested := StringName("door.%s.%s" % [token if not token.is_empty() else "default", "open" if opened else "closed"])
    if token.is_empty():
        return _found(requested, SOURCE_TACTICAL, 24 if opened else 23)
    var mapping: Dictionary = DOOR_OPEN if opened else DOOR_CLOSED
    if mapping.has(token):
        return _found(requested, SOURCE_WORLD, int(mapping[token]))
    return _unknown(requested, "door_theme_unclassified")

func resolve_window(theme: StringName = &"") -> ArtSelection:
    var token: String = _leaf_token(theme)
    var requested := StringName("window.%s" % (token if not token.is_empty() else "default"))
    if token.is_empty():
        return _found(requested, SOURCE_TACTICAL, 25)
    if WINDOW_BY_THEME.has(token):
        return _found(requested, SOURCE_WORLD, int(WINDOW_BY_THEME[token]))
    return _unknown(requested, "window_theme_unclassified")

func resolve_prop(semantic_id: StringName) -> ArtSelection:
    var token: String = _leaf_token(semantic_id)
    if token.is_empty():
        return _unknown(semantic_id, "prop_unclassified")
    if token == "barrel":
        return _found(semantic_id, SOURCE_TACTICAL, 26)
    if FINAL_PROP.has(token):
        return _found(semantic_id, SOURCE_FINAL_PROPS, int(FINAL_PROP[token]))
    if FINAL_PROP_ALIAS.has(token):
        return _found(semantic_id, SOURCE_FINAL_PROPS, int(FINAL_PROP_ALIAS[token]))
    if BUILDING_PROP.has(token):
        return _found(semantic_id, SOURCE_BUILDING, int(BUILDING_PROP[token]))
    if CLUTTER_PROP.has(token):
        return _found(semantic_id, SOURCE_CLUTTER, int(CLUTTER_PROP[token]))
    if PROP.has(token):
        return _found(semantic_id, SOURCE_TACTICAL, int(PROP[token]))
    return _unknown(semantic_id, "prop_unclassified")

func resolve_player(facing: int) -> ArtSelection:
    if not Facing.is_valid(facing):
        return _unknown(&"actor.player", "facing_unclassified")
    match facing:
        Facing.Value.NORTH:
            return _found(&"actor.player.north", SOURCE_PLAYER_NORTH, -1)
        Facing.Value.EAST:
            return _found(&"actor.player.east", SOURCE_PLAYER_EAST, -1)
        Facing.Value.SOUTH:
            return _found(&"actor.player.south", SOURCE_PLAYER_SOUTH, -1)
        Facing.Value.WEST:
            return _found(&"actor.player.west", SOURCE_PLAYER_WEST, -1)
    return _unknown(&"actor.player", "facing_unclassified")

func resolve_living_actor(actor_family: StringName, facing: int, variant: int) -> ArtSelection:
    var token: String = _leaf_token(actor_family)
    var requested := StringName("actor.%s.variant_%d" % [token if not token.is_empty() else "unknown", variant])
    if not LIVING_ACTOR_BASE.has(token):
        return _unknown(requested, "actor_family_unclassified")
    if not Facing.is_valid(facing):
        return _unknown(requested, "facing_unclassified")
    if variant < 0 or variant >= LIVING_ACTOR_VARIANTS:
        return _unknown(requested, "actor_variant_unclassified")
    var facing_index: int = _facing_index(facing)
    if facing_index < 0:
        return _unknown(requested, "facing_unclassified")
    var atlas_index: int = int(LIVING_ACTOR_BASE[token]) + variant * 4 + facing_index
    return _found(requested, SOURCE_ACTORS, atlas_index)

func resolve_held_item(semantic_id: StringName) -> ArtSelection:
    var token: String = _leaf_token(semantic_id)
    if not HELD_ITEM_INDEX.has(token):
        return _unknown(semantic_id, "held_item_unclassified")
    return _found(semantic_id, SOURCE_HELD_ITEMS, int(HELD_ITEM_INDEX[token]))

func held_item_draw_scale(semantic_id: StringName) -> float:
    var token: String = _leaf_token(semantic_id)
    if not HELD_ITEM_INDEX.has(token):
        return 0.0
    return HELD_ITEM_WEAPON_SCALE if HELD_ITEM_WEAPON_KIND.has(token) else HELD_ITEM_UTILITY_SCALE

func held_item_native_facing(semantic_id: StringName) -> int:
    var token: String = _leaf_token(semantic_id)
    if not HELD_ITEM_INDEX.has(token):
        return -1
    return Facing.Value.EAST

func resolve_road(
    mask: int,
    road_class: StringName = &"local",
    north_mask: int = 0,
    east_mask: int = 0,
    south_mask: int = 0,
    west_mask: int = 0
) -> ArtSelection:
    var index: int = RoadTopology.road_index(mask, road_class, north_mask, east_mask, south_mask, west_mask)
    if index < 0:
        return _unknown(&"ground.road", "road_topology_invalid")
    return _found(&"ground.road", SOURCE_WORLD, index)

func resolve_dirt_road(mask: int) -> ArtSelection:
    var index: int = RoadTopology.dirt_road_index(mask)
    if index < 0:
        return _unknown(&"ground.dirt_road", "road_topology_invalid")
    return _found(&"ground.dirt_road", SOURCE_WORLD, index)

func resolve_sidewalk(touching_road_mask: int) -> ArtSelection:
    var index: int = RoadTopology.sidewalk_index(touching_road_mask)
    if index < 0:
        return _unknown(&"ground.sidewalk", "sidewalk_topology_invalid")
    return _found(&"ground.sidewalk", SOURCE_WORLD, index)

func _register_source(source_id: StringName, texture_path: String, atlas: bool) -> void:
    var cell_size: int = ATLAS_CELL_PIXELS if atlas else 0
    var columns: int = ATLAS_COLUMNS if atlas else 0
    _sources[source_id] = ArtSourceClass.new(source_id, texture_path, atlas, cell_size, columns)

func _found(requested_id: StringName, source_id: StringName, atlas_index: int) -> ArtSelection:
    if not _sources.has(source_id):
        return _unknown(requested_id, "source_unclassified")
    var art_source: ArtSource = _sources[source_id]
    return ArtSelectionClass.found(requested_id, art_source, atlas_index)

func _unknown(requested_id: StringName, reason: String) -> ArtSelection:
    return ArtSelectionClass.unknown(requested_id, reason)

func _leaf_token(value: StringName) -> String:
    var raw: String = String(value).strip_edges()
    if raw.is_empty():
        return ""
    var dot_index: int = raw.rfind(".")
    if dot_index >= 0 and dot_index < raw.length() - 1:
        return raw.substr(dot_index + 1)
    return raw

func _facing_index(facing: int) -> int:
    match facing:
        Facing.Value.NORTH:
            return 0
        Facing.Value.EAST:
            return 1
        Facing.Value.SOUTH:
            return 2
        Facing.Value.WEST:
            return 3
    return -1
