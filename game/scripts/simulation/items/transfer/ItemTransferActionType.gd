extends RefCounted
class_name ItemTransferActionType

const WORLD_TO_CONTAINER: StringName = &"item.world_to_container"
const WORLD_TO_HAND: StringName = &"item.world_to_hand"
const CONTAINER_TO_WORLD: StringName = &"item.container_to_world"
const HAND_TO_WORLD: StringName = &"item.hand_to_world"
const CONTAINER_TO_HAND: StringName = &"item.container_to_hand"
const HAND_TO_CONTAINER: StringName = &"item.hand_to_container"
const CONTAINER_TO_CONTAINER: StringName = &"item.container_to_container"

const ALL := [
    WORLD_TO_CONTAINER,
    WORLD_TO_HAND,
    CONTAINER_TO_WORLD,
    HAND_TO_WORLD,
    CONTAINER_TO_HAND,
    HAND_TO_CONTAINER,
    CONTAINER_TO_CONTAINER,
]

static func is_valid(action_type: StringName) -> bool:
    return action_type in ALL

static func source_kind(action_type: StringName) -> StringName:
    match action_type:
        WORLD_TO_CONTAINER, WORLD_TO_HAND:
            return &"world"
        CONTAINER_TO_WORLD, CONTAINER_TO_HAND, CONTAINER_TO_CONTAINER:
            return &"container"
        HAND_TO_WORLD, HAND_TO_CONTAINER:
            return &"hand"
        _:
            return &"unknown"

static func destination_kind(action_type: StringName) -> StringName:
    match action_type:
        WORLD_TO_CONTAINER, HAND_TO_CONTAINER, CONTAINER_TO_CONTAINER:
            return &"container"
        WORLD_TO_HAND, CONTAINER_TO_HAND:
            return &"hand"
        CONTAINER_TO_WORLD, HAND_TO_WORLD:
            return &"world"
        _:
            return &"unknown"
