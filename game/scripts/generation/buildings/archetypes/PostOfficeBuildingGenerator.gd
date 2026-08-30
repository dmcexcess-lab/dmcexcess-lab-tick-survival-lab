extends RefCounted
class_name PostOfficeBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const OneStoryGeneratorClass = preload("res://scripts/generation/buildings/grammar/OneStoryProfileBuildingGenerator.gd")

const ARCHETYPE_ID: StringName = &"civic.post_office.small"

var _delegate: OneStoryProfileBuildingGenerator

func _init() -> void:
    _delegate = OneStoryGeneratorClass.new(_profile())

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    return _delegate.generate(request)

func _profile() -> Dictionary:
    return {
        "id": ARCHETYPE_ID,
        "version": 1,
        "story_count": 1,
        "category": &"civic",
        "canonical_size": Vector2i(21, 13),
        "canonical_frontage": Facing.Value.SOUTH,
        "shell_wall_semantic": &"wall.office",
        "interior_wall_semantic": &"wall.interior",
        "exterior_door_semantic": &"door.storefront",
        "interior_door_semantic": &"door.office",
        "window_semantic": &"window.storefront",
        "window_spacing": 3,
        "window_sides": [Facing.Value.SOUTH, Facing.Value.EAST, Facing.Value.WEST],
        "rooms": [
            {"purpose": "public_lobby", "rect": Rect2i(1, 7, 19, 5), "floor": &"ground.shop_floor"},
            {"purpose": "sorting_room", "rect": Rect2i(1, 1, 10, 5), "floor": &"ground.warehouse_floor"},
            {"purpose": "office", "rect": Rect2i(12, 1, 4, 5), "floor": &"ground.office_carpet"},
            {"purpose": "package_storage", "rect": Rect2i(17, 1, 3, 3), "floor": &"ground.warehouse_floor"},
            {"purpose": "bathroom", "rect": Rect2i(17, 5, 3, 1), "floor": &"ground.tile_white"},
        ],
        "doors": [
            {"role": "door.exterior.primary", "cell": Vector2i(10, 12), "semantic": &"door.storefront", "kind": &"door", "facing": Facing.Value.SOUTH},
            {"role": "door.interior.sorting", "cell": Vector2i(6, 6), "semantic": &"door.office", "kind": &"door", "facing": Facing.Value.NORTH},
            {"role": "door.interior.office", "cell": Vector2i(14, 6), "semantic": &"door.office", "kind": &"door", "facing": Facing.Value.NORTH},
            {"role": "door.interior.storage", "cell": Vector2i(17, 4), "semantic": &"door.office", "kind": &"door", "facing": Facing.Value.SOUTH},
            {"role": "door.exterior.service", "cell": Vector2i(6, 0), "semantic": &"door.office", "kind": &"door", "facing": Facing.Value.NORTH},
        ],
        "props": [
            {"role": "prop.lobby.counter", "cell": Vector2i(10, 8), "semantic": &"prop.counter_straight", "facing": Facing.Value.SOUTH, "blocking": true},
            {"role": "prop.lobby.shelf", "cell": Vector2i(3, 9), "semantic": &"prop.retail_shelf", "facing": Facing.Value.SOUTH, "blocking": true},
            {"role": "prop.sorting.rack_1", "cell": Vector2i(3, 3), "semantic": &"prop.warehouse_rack", "facing": Facing.Value.SOUTH, "blocking": true},
            {"role": "prop.sorting.rack_2", "cell": Vector2i(8, 3), "semantic": &"prop.warehouse_rack", "facing": Facing.Value.SOUTH, "blocking": true},
            {"role": "prop.office.desk", "cell": Vector2i(13, 3), "semantic": &"prop.office_desk", "facing": Facing.Value.SOUTH, "blocking": true},
            {"role": "prop.office.files", "cell": Vector2i(15, 2), "semantic": &"prop.file_cabinet_tall", "facing": Facing.Value.SOUTH, "blocking": true},
            {"role": "prop.storage.rack", "cell": Vector2i(18, 2), "semantic": &"prop.warehouse_rack", "facing": Facing.Value.SOUTH, "blocking": true},
        ],
    }
