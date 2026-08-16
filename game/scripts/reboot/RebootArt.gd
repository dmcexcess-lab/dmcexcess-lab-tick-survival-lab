extends RefCounted
class_name RebootArt

# The pre-reboot tactical presentation was a composite vocabulary, not one atlas.
# Keep that visual language while leaving all legacy gameplay/rendering modules inactive.
const TACTICAL: Texture2D = preload("res://assets/tactical_atlas.svg")
const CLUTTER: Texture2D = preload("res://assets/clutter_atlas.svg")
const WORLD: Texture2D = preload("res://assets/world_art_atlas.svg")
const BUILDING: Texture2D = preload("res://assets/building_props_atlas.svg")
const FINAL_SURFACES: Texture2D = preload("res://assets/final_environment_surfaces_atlas.svg")
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
const SOURCE_FINAL_SURFACE := 4
const SOURCE_FINAL_PROP := 5

# Ground / floor. Roads and structural floors deliberately use the older world-art
# vocabulary; nature and a few exterior surfaces use the final environment atlas.
const G_GRASS_LUSH := SOURCE_FINAL_SURFACE * ENCODE_SCALE + 0
const G_GRASS_DRY := SOURCE_FINAL_SURFACE * ENCODE_SCALE + 1
const G_GRASS_WEEDY := SOURCE_FINAL_SURFACE * ENCODE_SCALE + 2
const G_FOREST_FLOOR := SOURCE_FINAL_SURFACE * ENCODE_SCALE + 3
const G_DIRT_DARK := SOURCE_FINAL_SURFACE * ENCODE_SCALE + 10
const G_DIRT_LIGHT := SOURCE_FINAL_SURFACE * ENCODE_SCALE + 11
const G_ROAD_H := SOURCE_WORLD * ENCODE_SCALE + 1
const G_DIRT_ROAD_H := SOURCE_WORLD * ENCODE_SCALE + 28
const G_GRAVEL := SOURCE_WORLD * ENCODE_SCALE + 30
const G_FIELD_ROWS := SOURCE_WORLD * ENCODE_SCALE + 31
const G_DRIVEWAY := SOURCE_WORLD * ENCODE_SCALE + 21
const G_PATIO := SOURCE_FINAL_SURFACE * ENCODE_SCALE + 24
const G_WOOD := SOURCE_WORLD * ENCODE_SCALE + 32
const G_WOOD_ALT := SOURCE_WORLD * ENCODE_SCALE + 33
const G_KITCHEN := SOURCE_WORLD * ENCODE_SCALE + 34
const G_BATHROOM := SOURCE_WORLD * ENCODE_SCALE + 35
const G_CARPET := SOURCE_WORLD * ENCODE_SCALE + 37
const G_UTILITY := SOURCE_WORLD * ENCODE_SCALE + 38

# Walls / openings return to the world-art shell vocabulary that the old renderer used.
const S_WALL_HOUSE := SOURCE_WORLD * ENCODE_SCALE + 40
const S_WALL_INTERIOR := SOURCE_WORLD * ENCODE_SCALE + 43
const S_WALL_BARN := SOURCE_WORLD * ENCODE_SCALE + 45
const S_WALL_RURAL := SOURCE_WORLD * ENCODE_SCALE + 46
const S_DOOR_HOUSE := SOURCE_WORLD * ENCODE_SCALE + 48
const S_DOOR_SERVICE := SOURCE_WORLD * ENCODE_SCALE + 52
const S_WINDOW_HOUSE := SOURCE_WORLD * ENCODE_SCALE + 58

# Nature / civic clutter.
const P_TREE_SMALL := SOURCE_FINAL_PROP * ENCODE_SCALE + 0
const P_TREE_LARGE := SOURCE_FINAL_PROP * ENCODE_SCALE + 1
const P_PINE := SOURCE_FINAL_PROP * ENCODE_SCALE + 2
const P_DEAD_TREE := SOURCE_FINAL_PROP * ENCODE_SCALE + 3
const P_STUMP := SOURCE_FINAL_PROP * ENCODE_SCALE + 4
const P_FALLEN_LOG := SOURCE_FINAL_PROP * ENCODE_SCALE + 5
const P_ROCK := SOURCE_FINAL_PROP * ENCODE_SCALE + 6
const P_BUSH := SOURCE_FINAL_PROP * ENCODE_SCALE + 8
const P_TALL_GRASS := SOURCE_FINAL_PROP * ENCODE_SCALE + 10
const P_WEEDS := SOURCE_FINAL_PROP * ENCODE_SCALE + 11
const P_WILDFLOWERS := SOURCE_FINAL_PROP * ENCODE_SCALE + 12
const P_BRANCH_PILE := SOURCE_FINAL_PROP * ENCODE_SCALE + 16
const P_BRUSH_PILE := SOURCE_FINAL_PROP * ENCODE_SCALE + 17
const P_GARDEN := SOURCE_FINAL_PROP * ENCODE_SCALE + 19
const P_HAY_BALE := SOURCE_FINAL_PROP * ENCODE_SCALE + 22
const P_COMPOST := SOURCE_FINAL_PROP * ENCODE_SCALE + 23
const P_WOOD_FENCE := SOURCE_FINAL_PROP * ENCODE_SCALE + 44
const P_UTILITY_BOX := SOURCE_FINAL_PROP * ENCODE_SCALE + 50
const P_MAILBOX := SOURCE_FINAL_PROP * ENCODE_SCALE + 61
const P_UTILITY_POLE := SOURCE_BUILDING * ENCODE_SCALE + 23
const P_TRASH_CAN := SOURCE_CLUTTER * ENCODE_SCALE + 12
const P_TIRE_PILE := SOURCE_CLUTTER * ENCODE_SCALE + 20
const P_CARDBOARD := SOURCE_CLUTTER * ENCODE_SCALE + 21
const P_FIREWOOD := SOURCE_CLUTTER * ENCODE_SCALE + 23

# Domestic furniture. These source choices intentionally mirror the old composite renderer.
const P_STOVE := SOURCE_BUILDING * ENCODE_SCALE + 0
const P_COUNTER := SOURCE_BUILDING * ENCODE_SCALE + 1
const P_DRESSER := SOURCE_BUILDING * ENCODE_SCALE + 2
const P_NIGHTSTAND := SOURCE_BUILDING * ENCODE_SCALE + 3
const P_BATHTUB := SOURCE_BUILDING * ENCODE_SCALE + 4
const P_SHOWER := SOURCE_BUILDING * ENCODE_SCALE + 5
const P_BATH_VANITY := SOURCE_BUILDING * ENCODE_SCALE + 6
const P_DINING_TABLE := SOURCE_BUILDING * ENCODE_SCALE + 7
const P_ARMCHAIR := SOURCE_BUILDING * ENCODE_SCALE + 8
const P_WORKBENCH := SOURCE_BUILDING * ENCODE_SCALE + 17
const P_TOOL_CABINET := SOURCE_BUILDING * ENCODE_SCALE + 16
const P_WATER_HEATER := SOURCE_BUILDING * ENCODE_SCALE + 20

const P_KITCHEN_SINK := SOURCE_CLUTTER * ENCODE_SCALE + 3
const P_TOILET := SOURCE_CLUTTER * ENCODE_SCALE + 2
const P_TV := SOURCE_FINAL_PROP * ENCODE_SCALE + 80
const P_TV_OLD := SOURCE_FINAL_PROP * ENCODE_SCALE + 81
const P_SOFA := SOURCE_FINAL_PROP * ENCODE_SCALE + 76
const P_COFFEE_TABLE := SOURCE_FINAL_PROP * ENCODE_SCALE + 79
const P_FRIDGE := SOURCE_FINAL_PROP * ENCODE_SCALE + 64
const P_BED_SINGLE := SOURCE_FINAL_PROP * ENCODE_SCALE + 86
const P_BED_DOUBLE := SOURCE_FINAL_PROP * ENCODE_SCALE + 87
const P_WASHER := SOURCE_FINAL_PROP * ENCODE_SCALE + 101
const P_DRYER := SOURCE_FINAL_PROP * ENCODE_SCALE + 102

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
        SOURCE_FINAL_SURFACE:
            return FINAL_SURFACES
        SOURCE_FINAL_PROP:
            return FINAL_PROPS
        _:
            return FINAL_SURFACES

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
