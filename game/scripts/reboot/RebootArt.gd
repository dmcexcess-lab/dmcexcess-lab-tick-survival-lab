extends RefCounted
class_name RebootArt

# The reboot now uses the original tactical presentation vocabulary for the things
# that define the game's look: ground, floors, walls, doors, windows and common
# furniture/clutter. Later atlases are used only where the old sheets never had
# an equivalent (utility poles, stop signs and a few installed fixtures).
const TACTICAL: Texture2D = preload("res://assets/tactical_atlas.svg")
const CLUTTER: Texture2D = preload("res://assets/clutter_atlas.svg")
const WORLD: Texture2D = preload("res://assets/world_art_atlas.svg")
const BUILDING: Texture2D = preload("res://assets/building_props_atlas.svg")
const FINAL_PROPS: Texture2D = preload("res://assets/final_environment_props_atlas.svg")

const PLAYER_SOUTH: Texture2D = preload("res://assets/player_south.svg")
const PLAYER_NORTH: Texture2D = preload("res://assets/player_north.svg")
const PLAYER_WEST: Texture2D = preload("res://assets/player_west.svg")
const PLAYER_EAST: Texture2D = preload("res://assets/player_east.svg")

const SRC := 32
const ATLAS_COLS := 16
const ENCODE_SCALE := 256

const SOURCE_TACTICAL := 0
const SOURCE_CLUTTER := 1
const SOURCE_WORLD := 2
const SOURCE_BUILDING := 3
const SOURCE_FINAL_PROP := 4

# Exact original TacticalTiles ground/floor vocabulary.
const G_ASPHALT := SOURCE_TACTICAL * ENCODE_SCALE + 0
const G_ROAD := SOURCE_TACTICAL * ENCODE_SCALE + 1
const G_SIDEWALK := SOURCE_TACTICAL * ENCODE_SCALE + 2
const G_CONCRETE := SOURCE_TACTICAL * ENCODE_SCALE + 3
const G_TILE := SOURCE_TACTICAL * ENCODE_SCALE + 4
const G_WOOD := SOURCE_TACTICAL * ENCODE_SCALE + 5
const G_CARPET := SOURCE_TACTICAL * ENCODE_SCALE + 6
const G_LINOLEUM := SOURCE_TACTICAL * ENCODE_SCALE + 7
const G_GRASS := SOURCE_TACTICAL * ENCODE_SCALE + 8
const G_DIRT := SOURCE_TACTICAL * ENCODE_SCALE + 9
const G_WASH_CONCRETE := SOURCE_TACTICAL * ENCODE_SCALE + 10

# Small road additions that did not exist on the first tactical sheet.
const G_ROAD_H := SOURCE_WORLD * ENCODE_SCALE + 1
const G_DIRT_ROAD_V := SOURCE_WORLD * ENCODE_SCALE + 29
const G_GRAVEL := SOURCE_WORLD * ENCODE_SCALE + 30
const G_FIELD_ROWS := SOURCE_WORLD * ENCODE_SCALE + 31

# Exact original TacticalTiles wall/opening vocabulary.
const S_WALL_ALLEY := SOURCE_TACTICAL * ENCODE_SCALE + 16
const S_WALL_LIGHT := SOURCE_TACTICAL * ENCODE_SCALE + 17
const S_WALL_HOUSE := SOURCE_TACTICAL * ENCODE_SCALE + 18
const S_WALL_APARTMENT := SOURCE_TACTICAL * ENCODE_SCALE + 19
const S_WALL_STORE := SOURCE_TACTICAL * ENCODE_SCALE + 20
const S_WALL_INDUSTRIAL := SOURCE_TACTICAL * ENCODE_SCALE + 21
const S_WALL_WASH := SOURCE_TACTICAL * ENCODE_SCALE + 22
const S_DOOR_CLOSED := SOURCE_TACTICAL * ENCODE_SCALE + 23
const S_DOOR_OPEN := SOURCE_TACTICAL * ENCODE_SCALE + 24
const S_WINDOW := SOURCE_TACTICAL * ENCODE_SCALE + 25

# Common original tactical props.
const P_DUMPSTER := SOURCE_TACTICAL * ENCODE_SCALE + 32
const P_TRASH := SOURCE_TACTICAL * ENCODE_SCALE + 33
const P_NEON_SIGN := SOURCE_TACTICAL * ENCODE_SCALE + 34
const P_GAS_PUMP := SOURCE_TACTICAL * ENCODE_SCALE + 35
const P_CAR := SOURCE_TACTICAL * ENCODE_SCALE + 36
const P_COUNTER := SOURCE_TACTICAL * ENCODE_SCALE + 37
const P_STORE_SHELF := SOURCE_TACTICAL * ENCODE_SCALE + 38
const P_GAS_SIGN := SOURCE_TACTICAL * ENCODE_SCALE + 39
const P_ICE_BOX := SOURCE_TACTICAL * ENCODE_SCALE + 40
const P_SOFA := SOURCE_TACTICAL * ENCODE_SCALE + 41
const P_TABLE := SOURCE_TACTICAL * ENCODE_SCALE + 42
const P_BED := SOURCE_TACTICAL * ENCODE_SCALE + 43
const P_KITCHEN := SOURCE_TACTICAL * ENCODE_SCALE + 44
const P_FRIDGE := SOURCE_TACTICAL * ENCODE_SCALE + 45
const P_WASHER := SOURCE_TACTICAL * ENCODE_SCALE + 46
const P_VENDING := SOURCE_TACTICAL * ENCODE_SCALE + 47
const P_CRATE := SOURCE_TACTICAL * ENCODE_SCALE + 48
const P_PALLET := SOURCE_TACTICAL * ENCODE_SCALE + 49
const P_SCRUB := SOURCE_TACTICAL * ENCODE_SCALE + 52
const P_SHOPPING_CART := SOURCE_TACTICAL * ENCODE_SCALE + 53

# Exact original clutter sheet vocabulary.
const P_CHAIR := SOURCE_CLUTTER * ENCODE_SCALE + 0
const P_DESK := SOURCE_CLUTTER * ENCODE_SCALE + 1
const P_TOILET := SOURCE_CLUTTER * ENCODE_SCALE + 2
const P_SINK := SOURCE_CLUTTER * ENCODE_SCALE + 3
const P_CABINET := SOURCE_CLUTTER * ENCODE_SCALE + 4
const P_BOOKSHELF := SOURCE_CLUTTER * ENCODE_SCALE + 5
const P_TV := SOURCE_CLUTTER * ENCODE_SCALE + 6
const P_LAMP := SOURCE_CLUTTER * ENCODE_SCALE + 7
const P_TREE := SOURCE_CLUTTER * ENCODE_SCALE + 8
const P_BUSH := SOURCE_CLUTTER * ENCODE_SCALE + 9
const P_FENCE := SOURCE_CLUTTER * ENCODE_SCALE + 10
const P_MAILBOX := SOURCE_CLUTTER * ENCODE_SCALE + 11
const P_TRASH_CAN := SOURCE_CLUTTER * ENCODE_SCALE + 12
const P_ROAD_SIGN := SOURCE_CLUTTER * ENCODE_SCALE + 13
const P_BENCH := SOURCE_CLUTTER * ENCODE_SCALE + 14
const P_HYDRANT := SOURCE_CLUTTER * ENCODE_SCALE + 15
const P_STREETLIGHT := SOURCE_CLUTTER * ENCODE_SCALE + 16
const P_RUG := SOURCE_CLUTTER * ENCODE_SCALE + 17
const P_LAUNDRY := SOURCE_CLUTTER * ENCODE_SCALE + 18
const P_PLANTER := SOURCE_CLUTTER * ENCODE_SCALE + 19
const P_TIRE_PILE := SOURCE_CLUTTER * ENCODE_SCALE + 20
const P_CARDBOARD := SOURCE_CLUTTER * ENCODE_SCALE + 21
const P_PICNIC_TABLE := SOURCE_CLUTTER * ENCODE_SCALE + 22
const P_FIREWOOD := SOURCE_CLUTTER * ENCODE_SCALE + 23

# Later building-prop additions retained only when the original sheets had no
# clean equivalent.
const P_STOVE := SOURCE_BUILDING * ENCODE_SCALE + 0
const P_DRESSER := SOURCE_BUILDING * ENCODE_SCALE + 2
const P_NIGHTSTAND := SOURCE_BUILDING * ENCODE_SCALE + 3
const P_BATHTUB := SOURCE_BUILDING * ENCODE_SCALE + 4
const P_SHOWER := SOURCE_BUILDING * ENCODE_SCALE + 5
const P_BATH_VANITY := SOURCE_BUILDING * ENCODE_SCALE + 6
const P_WORKBENCH := SOURCE_BUILDING * ENCODE_SCALE + 17
const P_TOOL_CABINET := SOURCE_BUILDING * ENCODE_SCALE + 16
const P_WATER_HEATER := SOURCE_BUILDING * ENCODE_SCALE + 20
const P_UTILITY_POLE := SOURCE_BUILDING * ENCODE_SCALE + 23
const P_TRAFFIC_LIGHT := SOURCE_BUILDING * ENCODE_SCALE + 24
const P_STOP_SIGN := SOURCE_BUILDING * ENCODE_SCALE + 25
const P_PROPANE_TANK := SOURCE_BUILDING * ENCODE_SCALE + 31

# A few unobtrusive vegetation variants for dense rural edges.
const P_TREE_LARGE := SOURCE_FINAL_PROP * ENCODE_SCALE + 1
const P_TALL_GRASS := SOURCE_FINAL_PROP * ENCODE_SCALE + 10
const P_WEEDS := SOURCE_FINAL_PROP * ENCODE_SCALE + 11
const P_WILDFLOWERS := SOURCE_FINAL_PROP * ENCODE_SCALE + 12

static func atlas_region(index: int) -> Rect2:
    var x := float(posmod(index, ATLAS_COLS) * SRC)
    var y := float((index / ATLAS_COLS) * SRC)
    return Rect2(x, y, SRC, SRC)

static func draw_encoded(canvas: CanvasItem, encoded: int, rect: Rect2) -> void:
    var source := encoded / ENCODE_SCALE
    var index := posmod(encoded, ENCODE_SCALE)
    var texture: Texture2D = _texture_for_source(source)
    if texture == null:
        return
    canvas.draw_texture_rect_region(texture, rect, atlas_region(index), Color.WHITE, false, true)

static func _texture_for_source(source: int) -> Texture2D:
    match source:
        SOURCE_TACTICAL:
            return TACTICAL
        SOURCE_CLUTTER:
            return CLUTTER
        SOURCE_WORLD:
            return WORLD
        SOURCE_BUILDING:
            return BUILDING
        SOURCE_FINAL_PROP:
            return FINAL_PROPS
        _:
            return TACTICAL

static func player_texture(facing: int) -> Texture2D:
    match posmod(facing, 4):
        0:
            return PLAYER_NORTH
        1:
            return PLAYER_EAST
        2:
            return PLAYER_SOUTH
        _:
            return PLAYER_WEST
