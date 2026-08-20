extends RefCounted
class_name BuildingGrammarProfile

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var archetype_id: StringName = &""
var archetype_version: int = 0
var canonical_size: Vector2i = Vector2i.ZERO
var canonical_frontage: int = Facing.Value.NORTH
var layout_strategy: StringName = &""
var public_room: Dictionary = {}
var service_rooms: Dictionary = {}
var service_order_variants: Array = []
var service_depth: int = 0
var forbid_dedicated_hall: bool = true

var shell_wall_semantic: StringName = &"wall.plaster"
var front_wall_semantic: StringName = &"wall.plaster"
var interior_wall_semantic: StringName = &"wall.interior"
var primary_door_semantic: StringName = &"door.house"
var service_door_semantic: StringName = &"door.house"
var interior_door_semantic: StringName = &"door.house"
var front_window_semantic: StringName = &"window.house"
var side_window_semantic: StringName = &"window.house"
var rear_window_semantic: StringName = &"window.house"
var front_window_spacing: int = 2

func is_valid() -> bool:
    if String(archetype_id).is_empty() or archetype_version <= 0:
        return false
    if canonical_size.x < 7 or canonical_size.y < 7 or not Facing.is_valid(canonical_frontage):
        return false
    if layout_strategy != &"front_hub_back_strip":
        return false
    if service_depth < 2 or service_depth + 3 >= canonical_size.y:
        return false
    if public_room.is_empty() or service_rooms.is_empty() or service_order_variants.is_empty():
        return false
    if String(public_room.get("purpose", "")).is_empty() or String(public_room.get("floor", &"")).is_empty():
        return false

    var interior_width: int = canonical_size.x - 2
    for variant_value: Variant in service_order_variants:
        var variant: Array = variant_value
        if variant.size() != service_rooms.size():
            return false
        var seen: Dictionary = {}
        var occupied_width: int = maxi(0, variant.size() - 1)
        for purpose_value: Variant in variant:
            var purpose: String = String(purpose_value)
            if purpose.is_empty() or seen.has(purpose) or not service_rooms.has(purpose):
                return false
            seen[purpose] = true
            var spec: Dictionary = service_rooms[purpose]
            var room_width: int = int(spec.get("width", 0))
            if room_width < 3 or String(spec.get("floor", &"")).is_empty():
                return false
            occupied_width += room_width
        if occupied_width != interior_width:
            return false
    return true

func service_order(seed: int) -> Array[String]:
    var result: Array[String] = []
    if service_order_variants.is_empty():
        return result
    var index: int = absi(seed) % service_order_variants.size()
    var selected: Array = service_order_variants[index]
    for value: Variant in selected:
        result.append(String(value))
    return result

func service_spec(purpose: String) -> Dictionary:
    if not service_rooms.has(purpose):
        return {}
    return (service_rooms[purpose] as Dictionary).duplicate(true)
