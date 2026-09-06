extends RefCounted
class_name WorldInteractionReachQuery

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Neutral actor-to-world-interactable reach query.
## CONTACT_FORWARD preserves the original actor footprint + one-cell-forward fringe.
## Interactable targets may live on LOOSE_ITEM, OBJECT or STRUCTURE; terrain/effects remain excluded.

const CONTACT_FORWARD: StringName = &"contact_forward"
const INTERACTABLE_CHANNELS: Array[int] = [Layers.Channel.LOOSE_ITEM, Layers.Channel.OBJECT, Layers.Channel.STRUCTURE]

var _world: WorldState = null

func _init(world_state: WorldState = null) -> void:
    _world = world_state

func is_ready() -> bool:
    return _world != null

func supports_profile(profile_id: StringName) -> bool:
    return profile_id == CONTACT_FORWARD

func reachable_cells(actor_id: String, profile_id: StringName = CONTACT_FORWARD) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not is_ready() or not supports_profile(profile_id):
        return result
    var actor: String = actor_id.strip_edges()
    if actor.is_empty() or not _world.has_entity(actor):
        return result
    var entity: WorldEntityRecord = _world.entity(actor)
    var placement: WorldPlacement = _world.placement(actor)
    if entity == null or String(entity.semantic_type) != "actor.survivor":
        return result
    if placement == null or placement.channel != Layers.Channel.ACTOR or not Facing.is_valid(placement.facing):
        return result

    var seen: Dictionary = {}
    var forward: Vector2i = Facing.vector(placement.facing)
    for cell: Vector2i in placement.world_cells():
        seen[cell] = true
        seen[cell + forward] = true
    for value: Variant in seen.keys():
        var cell: Vector2i = value
        result.append(cell)
    result.sort_custom(_cell_less)
    return result

func candidate_object_ids(actor_id: String, profile_id: StringName = CONTACT_FORWARD) -> Array[String]:
    return _candidate_ids(actor_id, profile_id, [Layers.Channel.OBJECT])

func candidate_interactable_ids(actor_id: String, profile_id: StringName = CONTACT_FORWARD) -> Array[String]:
    return _candidate_ids(actor_id, profile_id, INTERACTABLE_CHANNELS)

func target_reachable(actor_id: String, target_entity_id: String, profile_id: StringName = CONTACT_FORWARD) -> bool:
    if not is_ready() or not supports_profile(profile_id):
        return false
    var target: String = target_entity_id.strip_edges()
    if target.is_empty() or not _world.has_entity(target):
        return false
    var target_placement: WorldPlacement = _world.placement(target)
    if target_placement == null or target_placement.channel not in INTERACTABLE_CHANNELS:
        return false

    var reachable: Dictionary = {}
    for cell: Vector2i in reachable_cells(actor_id, profile_id):
        reachable[cell] = true
    if reachable.is_empty():
        return false
    for cell: Vector2i in target_placement.world_cells():
        if reachable.has(cell):
            return true
    return false

func _candidate_ids(actor_id: String, profile_id: StringName, channels: Array[int]) -> Array[String]:
    var result: Array[String] = []
    if not is_ready() or not supports_profile(profile_id):
        return result
    var seen: Dictionary = {}
    for cell: Vector2i in reachable_cells(actor_id, profile_id):
        for channel: int in channels:
            for entity_id: String in _world.entities_at(cell, channel):
                if seen.has(entity_id):
                    continue
                var placement: WorldPlacement = _world.placement(entity_id)
                if placement == null or placement.channel != channel:
                    continue
                seen[entity_id] = true
                result.append(entity_id)
    result.sort()
    return result

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
