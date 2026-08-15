extends RefCounted
class_name TacticalTiles

const ATLAS_PATH := "res://assets/tactical_atlas.svg"
const CLUTTER_ATLAS_PATH := "res://assets/clutter_atlas.svg"
const WORLD_ART_PATH := "res://assets/world_art_atlas.svg"
const BUILDING_PROPS_PATH := "res://assets/building_props_atlas.svg"
const PLAYER_SOUTH_PATH := "res://assets/player_south.svg"
const PLAYER_NORTH_PATH := "res://assets/player_north.svg"
const PLAYER_WEST_PATH := "res://assets/player_west.svg"
const PLAYER_EAST_PATH := "res://assets/player_east.svg"
const CELL := 32.0

const ROAD_N := 1
const ROAD_E := 2
const ROAD_S := 4
const ROAD_W := 8

static var _atlas: Texture2D = null
static var _clutter_atlas: Texture2D = null
static var _world_art: Texture2D = null
static var _building_props: Texture2D = null
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

static func draw_ground(canvas: CanvasItem, rect: Rect2, kind: String) -> void:
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
        return touches[0]
    return 16
