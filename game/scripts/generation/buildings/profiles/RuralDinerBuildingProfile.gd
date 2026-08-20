extends RefCounted
class_name RuralDinerBuildingProfile

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const ProfileClass = preload("res://scripts/generation/buildings/grammar/BuildingGrammarProfile.gd")

const ARCHETYPE_ID: StringName = &"commercial.diner.rural_small"
const ARCHETYPE_VERSION: int = 2
const CANONICAL_SIZE: Vector2i = Vector2i(17, 11)
const CANONICAL_FRONTAGE: int = Facing.Value.SOUTH

static func build() -> BuildingGrammarProfile:
    var profile := ProfileClass.new()
    profile.archetype_id = ARCHETYPE_ID
    profile.archetype_version = ARCHETYPE_VERSION
    profile.canonical_size = CANONICAL_SIZE
    profile.canonical_frontage = CANONICAL_FRONTAGE
    profile.layout_strategy = &"front_hub_back_strip"
    profile.service_depth = 3
    profile.forbid_dedicated_hall = true

    profile.public_room = {
        "purpose": "dining_room",
        "floor": &"ground.restaurant_floor",
        "dressing": &"restaurant_dining",
    }
    profile.service_rooms = {
        "kitchen": {
            "purpose": "kitchen",
            "width": 7,
            "floor": &"ground.kitchen_tile",
            "dressing": &"kitchen_line",
            "rear_window": true,
            "service_exit": false,
        },
        "storage": {
            "purpose": "storage",
            "width": 3,
            "floor": &"ground.warehouse_floor",
            "dressing": &"storage_service",
            "rear_window": false,
            "service_exit": true,
        },
        "bathroom": {
            "purpose": "bathroom",
            "width": 3,
            "floor": &"ground.tile_mosaic",
            "dressing": &"bathroom_basic",
            "rear_window": true,
            "service_exit": false,
        },
    }
    # Four legal orders keep the 7-wide kitchen away from the far-right booth wall,
    # where the customer-counter cluster would otherwise collide with seating.
    # Ordering is chosen so accepted critique seeds 19006 and 19007 keep their v1 topology.
    profile.service_order_variants = [
        ["kitchen", "bathroom", "storage"],
        ["storage", "kitchen", "bathroom"],
        ["kitchen", "storage", "bathroom"],
        ["bathroom", "kitchen", "storage"],
    ]

    profile.shell_wall_semantic = &"wall.red_brick"
    profile.front_wall_semantic = &"wall.storefront"
    profile.interior_wall_semantic = &"wall.interior"
    profile.primary_door_semantic = &"door.storefront"
    profile.service_door_semantic = &"door.store"
    profile.interior_door_semantic = &"door.commercial"
    profile.front_window_semantic = &"window.storefront"
    profile.side_window_semantic = &"window.store"
    profile.rear_window_semantic = &"window.store"
    profile.front_window_spacing = 2
    return profile
