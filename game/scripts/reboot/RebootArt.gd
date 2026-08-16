extends RefCounted
class_name RebootArt

const SURFACES: Texture2D = preload("res://assets/final_environment_surfaces_atlas.svg")
const PROPS: Texture2D = preload("res://assets/final_environment_props_atlas.svg")
const PLAYER_SOUTH: Texture2D = preload("res://assets/player_south.svg")
const PLAYER_NORTH: Texture2D = preload("res://assets/player_north.svg")
const PLAYER_WEST: Texture2D = preload("res://assets/player_west.svg")
const PLAYER_EAST: Texture2D = preload("res://assets/player_east.svg")

const SRC := 32
const ATLAS_COLS := 16

# Final environment surface atlas indices.
const G_GRASS_LUSH := 0
const G_GRASS_DRY := 1
const G_GRASS_WEEDY := 2
const G_FOREST_FLOOR := 3
const G_MUD := 4
const G_DIRT_DARK := 10
const G_DIRT_LIGHT := 11
const G_GRAVEL_DARK := 12
const G_GRAVEL_LIGHT := 13
const G_FIELD_GREEN := 14
const G_FIELD_DRY := 15
const G_ASPHALT := 16
const G_PATIO := 24
const G_CONCRETE := 26
const G_DRIVEWAY_GRAVEL := 29
const G_PARKING_FADED := 30
const G_ALLEY := 31
const G_LAMINATE_LIGHT := 32
const G_LAMINATE_DARK := 33
const G_WOOD_PARQUET := 34
const G_CARPET_BLUE := 35
const G_CARPET_BEIGE := 36
const G_TILE_WHITE := 38
const G_TILE_MOSAIC := 40
const G_LINOLEUM_GREEN := 41
const G_GARAGE := 43
const G_RESTAURANT := 45

const S_WALL_WALLPAPER := 48
const S_WALL_PANELING := 49
const S_WALL_RED_BRICK := 50
const S_WALL_WHITE_BRICK := 51
const S_WALL_STONE := 52
const S_WALL_TILE := 53
const S_WALL_GLASS := 54
const S_WALL_PLASTER := 55
const S_WALL_CONCRETE := 56
const S_WALL_METAL := 57
const S_DOOR := 58
const S_DOOR_REINFORCED := 59
const S_WINDOW_BOARDED := 60
const S_WINDOW_BROKEN := 61
const S_WINDOW_GLASS := 62
const S_SCREEN_DOOR := 63

# Final environment prop atlas indices.
const P_TREE_SMALL := 0
const P_TREE_LARGE := 1
const P_PINE := 2
const P_DEAD_TREE := 3
const P_STUMP := 4
const P_FALLEN_LOG := 5
const P_ROCK := 6
const P_ROCK_CLUSTER := 7
const P_BUSH := 8
const P_THORN_BUSH := 9
const P_TALL_GRASS := 10
const P_WEEDS := 11
const P_WILDFLOWERS := 12
const P_LEAF_LITTER := 15
const P_BRANCH_PILE := 16
const P_BRUSH_PILE := 17
const P_GARDEN := 19
const P_CROP_GREEN := 20
const P_CROP_DRY := 21
const P_HAY_BALE := 22
const P_COMPOST := 23
const P_WOOD_FENCE := 44
const P_PRIVACY_FENCE := 45
const P_UTILITY_BOX := 50
const P_STREET_PLANTER := 60
const P_MAILBOX := 61
const P_UTILITY_POLE := 62

const P_FRIDGE := 64
const P_FRIDGE_STEEL := 65
const P_STOVE := 66
const P_KITCHEN_SINK := 67
const P_COUNTER := 68
const P_COUNTER_CORNER := 69
const P_PANTRY := 70
const P_DISHWASHER := 71
const P_KITCHEN_ISLAND := 72
const P_MICROWAVE := 73
const P_BREAKFAST_TABLE := 74
const P_DINING_CHAIR := 75
const P_SOFA := 76
const P_LOVESEAT := 77
const P_RECLINER := 78
const P_COFFEE_TABLE := 79
const P_TV := 80
const P_TV_OLD := 81
const P_TV_STAND := 82
const P_BOOKSHELF := 83
const P_END_TABLE := 84
const P_FLOOR_LAMP := 85
const P_BED_SINGLE := 86
const P_BED_DOUBLE := 87
const P_BUNK_BED := 88
const P_DRESSER := 89
const P_WARDROBE := 90
const P_HOME_DESK := 91
const P_DESK_CHAIR := 92
const P_HAMPER := 93
const P_TOILET := 94
const P_PEDESTAL_SINK := 95
const P_BATH_VANITY := 96
const P_BATHTUB := 97
const P_SHOWER := 98
const P_TOWEL_RACK := 99
const P_MEDICINE_CABINET := 100
const P_WASHER := 101
const P_DRYER := 102
const P_WATER_HEATER := 103

const P_RETAIL_SHELF := 104
const P_OFFICE_DESK := 111
const P_OFFICE_CHAIR := 112
const P_FILE_CABINET := 113
const P_PALLET := 117
const P_WAREHOUSE_RACK := 118
const P_WORKBENCH := 119
const P_TOOL_CABINET := 120
const P_GENERATOR := 122
const P_LOCKERS := 123

static func atlas_region(index: int) -> Rect2:
    var x := float(posmod(index, ATLAS_COLS) * SRC)
    var y := float((index / ATLAS_COLS) * SRC)
    return Rect2(x, y, SRC, SRC)

static func player_texture(facing: int) -> Texture2D:
    match posmod(facing, 4):
        0: return PLAYER_NORTH
        1: return PLAYER_EAST
        2: return PLAYER_SOUTH
        _: return PLAYER_WEST
