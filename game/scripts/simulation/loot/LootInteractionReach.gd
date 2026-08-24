extends RefCounted
class_name LootInteractionReach

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Shared current-world reach rule for both searching and System 12 external access.
## Reach is actor footprint plus the one-cell-forward fringe in current facing.

static func is_reachable(world: WorldState, actor_id: String, container_id: String) -> bool:
    if world == null or actor_id.strip_edges().is_empty() or container_id.strip_edges().is_empty():
        return false
    if not world.has_entity(actor_id) or not world.has_entity(container_id):
        return false
    var actor_entity: WorldEntityRecord = world.entity(actor_id)
    if actor_entity == null or String(actor_entity.semantic_type) != "actor.survivor":
        return false
    var actor_placement: WorldPlacement = world.placement(actor_id)
    var container_placement: WorldPlacement = world.placement(container_id)
    if actor_placement == null or actor_placement.channel != Layers.Channel.ACTOR:
        return false
    if container_placement == null or container_placement.channel != Layers.Channel.OBJECT:
        return false
    if not Facing.is_valid(actor_placement.facing):
        return false

    var reachable: Dictionary = {}
    var forward: Vector2i = Facing.vector(actor_placement.facing)
    for cell: Vector2i in actor_placement.world_cells():
        reachable[cell] = true
        reachable[cell + forward] = true
    for cell: Vector2i in container_placement.world_cells():
        if reachable.has(cell):
            return true
    return false
