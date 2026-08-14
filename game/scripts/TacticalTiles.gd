extends RefCounted
class_name TacticalTiles

const ATLAS_PATH := "res://assets/tactical_atlas.svg"
const CLUTTER_ATLAS_PATH := "res://assets/clutter_atlas.svg"
const CELL := 32.0
static var _atlas: Texture2D = null
static var _clutter_atlas: Texture2D = null

const GROUND := {
    "asphalt": 0, "road": 1, "sidewalk": 2, "concrete": 3, "tile": 4,
    "wood": 5, "carpet": 6, "linoleum": 7, "grass": 8, "dirt": 9,
    "wash_concrete": 10,
}

const WALL_BY_THEME := {
    "alley": 16, "gas": 17, "house": 18, "apartment": 19,
    "store": 20, "industrial": 21, "wash": 22,
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

static func _texture() -> Texture2D:
    if _atlas == null:
        _atlas = ResourceLoader.load(ATLAS_PATH) as Texture2D
    return _atlas

static func _clutter_texture() -> Texture2D:
    if _clutter_atlas == null:
        _clutter_atlas = ResourceLoader.load(CLUTTER_ATLAS_PATH) as Texture2D
    return _clutter_atlas

static func region(index: int) -> Rect2:
    return Rect2(float(posmod(index, 16)) * CELL, float(index / 16) * CELL, CELL, CELL)

static func draw_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_clutter_region(canvas: CanvasItem, index: int, rect: Rect2, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _clutter_texture()
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, region(index), modulate, false, true)

static func draw_ground(canvas: CanvasItem, rect: Rect2, kind: String) -> void:
    draw_region(canvas, int(GROUND.get(kind, 0)), rect)

static func draw_wall(canvas: CanvasItem, rect: Rect2, theme: String) -> void:
    draw_region(canvas, int(WALL_BY_THEME.get(theme, 16)), rect)

static func draw_door(canvas: CanvasItem, rect: Rect2, opened: bool) -> void:
    draw_region(canvas, 24 if opened else 23, rect)

static func draw_window(canvas: CanvasItem, rect: Rect2) -> void:
    draw_region(canvas, 25, rect)

static func draw_barrel(canvas: CanvasItem, rect: Rect2) -> void:
    draw_region(canvas, 26, rect)

static func draw_prop(canvas: CanvasItem, rect: Rect2, kind: String) -> void:
    if CLUTTER_PROP.has(kind):
        draw_clutter_region(canvas, int(CLUTTER_PROP[kind]), rect)
        return
    draw_region(canvas, int(PROP.get(kind, 48)), rect)

static func player_region_for_facing(facing: Vector2i) -> int:
    # Atlas 96-99 are authored as south/front, west, north/back, east.
    if facing == Vector2i.UP:
        return 98
    if facing == Vector2i.DOWN:
        return 96
    if facing == Vector2i.LEFT:
        return 97
    if facing == Vector2i.RIGHT:
        return 99
    return 96

static func draw_player(canvas: CanvasItem, rect: Rect2, facing: Vector2i) -> void:
    draw_region(canvas, player_region_for_facing(facing), rect)
