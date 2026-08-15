extends RefCounted
class_name TacticalTiles

const ATLAS_PATH := "res://assets/tactical_atlas.svg"
const CLUTTER_ATLAS_PATH := "res://assets/clutter_atlas.svg"
const WORLD_ART_PATH := "res://assets/world_art_atlas.svg"
const BUILDING_PROPS_PATH := "res://assets/building_props_atlas.svg"
const FINAL_SURFACES_PATH := "res://assets/final_environment_surfaces_atlas.svg"
const FINAL_PROPS_PATH := "res://assets/final_environment_props_atlas.svg"
const PLAYER_SOUTH_PATH := "res://assets/player_south.svg"
const PLAYER_NORTH_PATH := "res://assets/player_north.svg"
const PLAYER_WEST_PATH := "res://assets/player_west.svg"
const PLAYER_EAST_PATH := "res://assets/player_east.svg"
const CELL := 32.0
const FINAL_SURFACE_COUNT := 64
const FINAL_PROP_COUNT := 128

const ROAD_N := 1
const ROAD_E := 2
const ROAD_S := 4
const ROAD_W := 8

static var _atlas: Texture2D = null
static var _clutter_atlas: Texture2D = null
static var _world_art: Texture2D = null
static var _building_props: Texture2D = null
static var _final_surfaces: Texture2D = null
static var _final_props: Texture2D = null
static var _player_south: Texture2D = null
static var _player_north: Texture2D = null
static var _player_west: Texture2D = null
static var _player_east: Texture2D = null

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
    "grass_lush": 0,
    "grass_dry": 1,
    "grass_weedy": 2,
    "forest_floor": 3,
    "mud": 4,
    "sand": 5,
    "beach_sand": 6,
    "moss_ground": 7,
    "marsh_ground": 8,
    "rocky_ground": 9,
    "dirt_dark": 10,
    "dirt_light": 11,
    "gravel_dark": 12,
    "gravel_light": 13,
    "field_green": 14,
    "field_dry": 15,
    "asphalt_patch": 16,
    "pothole": 17,
    "road_white_line_h": 18,
    "road_white_line_v": 19,
    "road_yellow_line_h": 20,
    "road_yellow_line_v": 21,
    "shoulder_gravel": 22,
    "curb_ramp": 23,
    "patio_pavers": 24,
    "brick_pavers": 25,
    "concrete_clean": 26,
    "concrete_cracked": 27,
    "concrete_oil": 28,
    "driveway_gravel": 29,
    "parking_faded": 30,
    "alley_stained": 31,
    "laminate_light": 32,
    "laminate_dark": 33,
    "wood_parquet": 34,
    "carpet_blue": 35,
    "carpet_beige": 36,
    "carpet_green": 37,
    "tile_white": 38,
    "tile_blackwhite": 39,
    "tile_mosaic": 40,
    "linoleum_green": 41,
    "linoleum_yellow": 42,
    "garage_floor": 43,
    "basement_floor": 44,
    "restaurant_floor": 45,
    "hospital_floor": 46,
    "classroom_floor": 47,
}

const FINAL_GROUND_ALIAS := {
    "grass": 0,
    "dirt": 11,
    "asphalt": 16,
    "concrete": 26,
    "tile": 38,
    "wood": 32,
    "carpet": 36,
    "linoleum": 41,
    "wash_concrete": 27,
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
    "office": 44,
    "warehouse": 45,
    "rural_wood": 46,
    "storefront": 47,
}

const FINAL_WALL_BY_THEME := {
    "wallpaper": 48,
    "paneling": 49,
    "red_brick": 50,
    "white_brick": 51,
    "stone": 52,
    "tile": 53, "tile_wall": 53,
    "glass_partition": 54,
    "plaster": 55,
    "concrete": 56, "concrete_wall": 56,
    "metal_panel": 57,
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
    "deciduous_small": 0,
    "deciduous_large": 1,
    "pine_tree": 2,
    "dead_tree": 3,
    "tree_stump": 4,
    "fallen_log": 5,
    "rock_small": 6,
    "rock_cluster": 7,
    "dense_bush": 8,
    "thorn_bush": 9,
    "tall_grass": 10,
    "weeds_patch": 11,
    "wildflowers": 12,
    "reeds": 13,
    "vine_patch": 14,
    "leaf_litter": 15,
    "branch_pile": 16,
    "brush_pile": 17,
    "dirt_mound": 18,
    "garden_patch": 19,
    "crop_green": 20,
    "crop_dry": 21,
    "hay_bale": 22,
    "compost_pile": 23,
    "cactus": 24,
    "palm_tree": 25,
    "desert_scrub": 26,
    "cattails": 27,
    "mushroom_patch": 28,
    "mossy_rock": 29,
    "sapling": 30,
    "fallen_branches": 31,
    "yield_sign": 32,
    "speed_limit_sign": 33,
    "no_parking_sign": 34,
    "street_name_sign": 35,
    "one_way_sign": 36,
    "dead_end_sign": 37,
    "road_work_sign": 38,
    "pedestrian_sign": 39,
    "bus_stop_sign": 40,
    "public_trash_bin": 41,
    "guardrail": 42,
    "chainlink_fence": 43,
    "wood_fence": 44,
    "privacy_fence": 45,
    "traffic_cone": 46,
    "road_barricade": 47,
    "storm_drain": 48,
    "manhole": 49,
    "utility_box": 50,
    "transformer": 51,
    "phone_box": 52,
    "newspaper_box": 53,
    "bike_rack": 54,
    "crosswalk_beacon": 55,
    "parking_sign": 56,
    "fire_call_box": 57,
    "road_barrier": 58,
    "sewer_grate": 59,
    "street_planter": 60,
    "curb_mailbox": 61,
    "utility_pole_wood": 62,
    "utility_pole_transformer": 63,
    "refrigerator_white": 64,
    "refrigerator_stainless": 65,
    "stove_range": 66,
    "kitchen_sink": 67,
    "counter_straight": 68,
    "counter_corner": 69,
    "pantry": 70,
    "dishwasher": 71,
    "kitchen_island": 72,
    "microwave_counter": 73,
    "breakfast_table": 74,
    "dining_chair": 75,
    "sofa": 76,
    "loveseat": 77,
    "recliner": 78,
    "coffee_table": 79,
    "tv_flat": 80,
    "tv_old": 81,
    "tv_stand": 82,
    "bookshelf_tall": 83,
    "end_table": 84,
    "floor_lamp": 85,
    "bed_single": 86,
    "bed_double": 87,
    "bunk_bed": 88,
    "dresser_wide": 89,
    "wardrobe": 90,
    "home_desk": 91,
    "desk_chair": 92,
    "hamper": 93,
    "toilet_modern": 94,
    "pedestal_sink": 95,
    "bathroom_vanity": 96,
    "bathtub_clawfoot": 97,
    "shower_stall": 98,
    "towel_rack": 99,
    "medicine_cabinet": 100,
    "washer_front": 101,
    "dryer_front": 102,
    "water_heater_tall": 103,
    "retail_shelf": 104,
    "retail_endcap": 105,
    "walkin_cooler": 106,
    "chest_freezer": 107,
    "produce_display": 108,
    "restaurant_table": 109,
    "restaurant_booth": 110,
    "office_desk": 111,
    "office_chair": 112,
    "file_cabinet_tall": 113,
    "copier": 114,
    "cubicle_corner": 115,
    "server_rack": 116,
    "pallet_stack": 117,
    "warehouse_rack": 118,
    "workbench_heavy": 119,
    "tool_cabinet": 120,
    "industrial_machine": 121,
    "portable_generator": 122,
    "locker_bank": 123,
    "janitor_sink": 124,
    "janitor_cart": 125,
    "vending_machine": 126,
    "breakroom_table": 127,
}

const FINAL_PROP_ALIAS := {
    "tree": 1,
    "bush": 8,
    "road_sign": 35,
    "fence": 44,
    "mailbox": 61,
    "chair": 75,
    "desk": 91,
    "toilet": 94,
    "sink": 95,
    "cabinet": 70,
    "bookshelf": 83,
    "tv": 80,
    "laundry": 93,
    "couch": 76,
    "table": 74,
    "bed": 86,
    "kitchen": 68,
    "fridge": 64,
    "washer": 101,
    "store_shelf": 104,
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

static func _texture() -> Texture2D:
    if _atlas == null:
        _atlas = ResourceLoader.load(ATLAS_PATH) as Texture2D
    return _atlas

static func _clutter_texture() -> Texture2D:
    if _clutter_atlas == null:
        _clutter_atlas = ResourceLoader.load(CLUTTER_ATLAS_PATH) as Texture2D
    return _clutter_atlas

static func _world_texture() -> Texture2D:
    if _world_art == null:
        _world_art = ResourceLoader.load(WORLD_ART_PATH) as Texture2D
    return _world_art

static func _building_prop_texture() -> Texture2D:
    if _building_props == null:
        _building_props = ResourceLoader.load(BUILDING_PROPS_PATH) as Texture2D
    return _building_props

static func _final_surface_texture() -> Texture2D:
    if _final_surfaces == null:
        _final_surfaces = ResourceLoader.load(FINAL_SURFACES_PATH) as Texture2D
    return _final_surfaces

static func _final_prop_texture() -> Texture2D:
    if _final_props == null:
        _final_props = ResourceLoader.load(FINAL_PROPS_PATH) as Texture2D
    return _final_props

static func _player_texture_for_facing(facing: Vector2i) -> Texture2D:
    if facing == Vector2i.UP:
        if _player_north == null:
            _player_north = ResourceLoader.load(PLAYER_NORTH_PATH) as Texture2D
        return _player_north
    if facing == Vector2i.LEFT:
        if _player_west == null:
            _player_west = ResourceLoader.load(PLAYER_WEST_PATH) as Texture2D
        return _player_west
    if facing == Vector2i.RIGHT:
        if _player_east == null:
            _player_east = ResourceLoader.load(PLAYER_EAST_PATH) as Texture2D
        return _player_east
    if _player_south == null:
        _player_south = ResourceLoader.load(PLAYER_SOUTH_PATH) as Texture2D
    return _player_south

static func region(index: int) -> Rect2:
    return Rect2(float(posmod(index, 16)) * CELL, float(index / 16) * CELL, CELL, CELL)

static func draw_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_world_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _world_texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_final_surface_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _final_surface_texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_clutter_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _clutter_texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_building_prop_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _building_prop_texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_final_prop_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _final_prop_texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_ground(canvas: CanvasItem, rect: Rect2, kind: String) -> void:
    if FINAL_GROUND.has(kind):
        draw_final_surface_region(canvas, int(FINAL_GROUND[kind]), rect)
        return
    if FINAL_GROUND_ALIAS.has(kind):
        draw_final_surface_region(canvas, int(FINAL_GROUND_ALIAS[kind]), rect)
        return
    if WORLD_GROUND.has(kind):
        draw_world_region(canvas, int(WORLD_GROUND[kind]), rect)
        return
    draw_region(canvas, int(GROUND.get(kind, 0)), rect)

static func draw_ground_context(canvas: CanvasItem, rect: Rect2, spec: Dictionary, cell: Vector2i, kind: String) -> void:
    if spec.get("road_cells", {}).has(cell):
        if kind == "dirt":
            draw_world_region(canvas, _dirt_road_index(spec, cell), rect)
            return
        if kind == "road":
            draw_world_region(canvas, _road_index(spec, cell), rect)
            return
    if kind == "sidewalk":
        draw_world_region(canvas, _sidewalk_index(spec, cell), rect)
        return
    draw_ground(canvas, rect, kind)

static func draw_wall(canvas: CanvasItem, rect: Rect2, theme: String) -> void:
    if FINAL_WALL_BY_THEME.has(theme):
        draw_final_surface_region(canvas, int(FINAL_WALL_BY_THEME[theme]), rect)
        return
    if WORLD_WALL_BY_THEME.has(theme):
        draw_world_region(canvas, int(WORLD_WALL_BY_THEME[theme]), rect)
        return
    draw_region(canvas, int(WALL_BY_THEME.get(theme, 16)), rect)

static func draw_door(canvas: CanvasItem, rect: Rect2, opened: bool, theme: String = "") -> void:
    var mapping: Dictionary = DOOR_OPEN if opened else DOOR_CLOSED
    if mapping.has(theme):
        draw_world_region(canvas, int(mapping[theme]), rect)
        return
    draw_region(canvas, 24 if opened else 23, rect)

static func draw_window(canvas: CanvasItem, rect: Rect2, theme: String = "") -> void:
    if WINDOW_BY_THEME.has(theme):
        draw_world_region(canvas, int(WINDOW_BY_THEME[theme]), rect)
        return
    draw_region(canvas, 25, rect)

static func draw_barrel(canvas: CanvasItem, rect: Rect2) -> void:
    draw_region(canvas, 26, rect)

static func draw_prop(canvas: CanvasItem, rect: Rect2, kind: String) -> void:
    if FINAL_PROP.has(kind):
        draw_final_prop_region(canvas, int(FINAL_PROP[kind]), rect)
        return
    if FINAL_PROP_ALIAS.has(kind):
        draw_final_prop_region(canvas, int(FINAL_PROP_ALIAS[kind]), rect)
        return
    if BUILDING_PROP.has(kind):
        draw_building_prop_region(canvas, int(BUILDING_PROP[kind]), rect)
        return
    if CLUTTER_PROP.has(kind):
        draw_clutter_region(canvas, int(CLUTTER_PROP[kind]), rect)
        return
    draw_region(canvas, int(PROP.get(kind, 48)), rect)

static func draw_player(canvas: CanvasItem, rect: Rect2, facing: Vector2i) -> void:
    var texture: Texture2D = _player_texture_for_facing(facing)
    if texture == null:
        return
    canvas.draw_texture_rect(texture, rect, false, Color.WHITE, false)

static func _road_mask(spec: Dictionary, cell: Vector2i) -> int:
    var links: Dictionary = spec.get("road_links", {})
    if links.has(cell):
        return int(links[cell])
    var roads: Dictionary = spec.get("road_cells", {})
    var mask := 0
    if roads.has(cell + Vector2i.UP): mask = mask | ROAD_N
    if roads.has(cell + Vector2i.RIGHT): mask = mask | ROAD_E
    if roads.has(cell + Vector2i.DOWN): mask = mask | ROAD_S
    if roads.has(cell + Vector2i.LEFT): mask = mask | ROAD_W
    return mask

static func _road_index(spec: Dictionary, cell: Vector2i) -> int:
    var mask := _road_mask(spec, cell)
    var road_class := str(spec.get("road_class_cells", {}).get(cell, "local"))
    if road_class == "arterial":
        if mask == (ROAD_E | ROAD_W):
            var north_mask := _road_mask(spec, cell + Vector2i.UP)
            var south_mask := _road_mask(spec, cell + Vector2i.DOWN)
            if (north_mask & (ROAD_E | ROAD_W)) != (ROAD_E | ROAD_W) or (south_mask & (ROAD_E | ROAD_W)) != (ROAD_E | ROAD_W):
                return 15
        elif mask == (ROAD_N | ROAD_S):
            var east_mask := _road_mask(spec, cell + Vector2i.RIGHT)
            var west_mask := _road_mask(spec, cell + Vector2i.LEFT)
            if (east_mask & (ROAD_N | ROAD_S)) != (ROAD_N | ROAD_S) or (west_mask & (ROAD_N | ROAD_S)) != (ROAD_N | ROAD_S):
                return 15
        elif (mask & (ROAD_N | ROAD_S)) != 0 and (mask & (ROAD_E | ROAD_W)) != 0:
            return 15
    if mask == (ROAD_N | ROAD_S): return 0
    if mask == (ROAD_E | ROAD_W): return 1
    if mask == (ROAD_N | ROAD_E): return 2
    if mask == (ROAD_E | ROAD_S): return 3
    if mask == (ROAD_S | ROAD_W): return 4
    if mask == (ROAD_W | ROAD_N): return 5
    if mask == (ROAD_N | ROAD_E | ROAD_S): return 6
    if mask == (ROAD_E | ROAD_S | ROAD_W): return 7
    if mask == (ROAD_S | ROAD_W | ROAD_N): return 8
    if mask == (ROAD_W | ROAD_N | ROAD_E): return 9
    if mask == (ROAD_N | ROAD_E | ROAD_S | ROAD_W): return 10
    if mask == ROAD_N: return 11
    if mask == ROAD_E: return 12
    if mask == ROAD_S: return 13
    if mask == ROAD_W: return 14
    return 15

static func _dirt_road_index(spec: Dictionary, cell: Vector2i) -> int:
    var mask := _road_mask(spec, cell)
    var horizontal := (mask & (ROAD_E | ROAD_W)) != 0
    var vertical := (mask & (ROAD_N | ROAD_S)) != 0
    if horizontal and not vertical:
        return 28
    if vertical and not horizontal:
        return 29
    return 30

static func _sidewalk_index(spec: Dictionary, cell: Vector2i) -> int:
    var roads: Dictionary = spec.get("road_cells", {})
    var touches: Array[int] = []
    if roads.has(cell + Vector2i.UP): touches.append(17)
    if roads.has(cell + Vector2i.RIGHT): touches.append(18)
    if roads.has(cell + Vector2i.DOWN): touches.append(19)
    if roads.has(cell + Vector2i.LEFT): touches.append(20)
    if touches.size() == 1:
        return int(touches[0])
    return 16
