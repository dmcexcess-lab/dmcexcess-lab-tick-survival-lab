extends RefCounted
class_name SpatialLayer

## Shared spatial occupancy-channel vocabulary.
## This classifies where facts may be indexed later; it stores no occupants.

enum Channel {
    TERRAIN,
    STRUCTURE,
    OBJECT,
    ACTOR,
    LOOSE_ITEM,
    EFFECT,
}

static func is_valid(channel: int) -> bool:
    return channel >= Channel.TERRAIN and channel <= Channel.EFFECT

static func label(channel: int) -> String:
    match channel:
        Channel.TERRAIN:
            return "terrain"
        Channel.STRUCTURE:
            return "structure"
        Channel.OBJECT:
            return "object"
        Channel.ACTOR:
            return "actor"
        Channel.LOOSE_ITEM:
            return "loose_item"
        Channel.EFFECT:
            return "effect"
        _:
            return "invalid"
