extends InteractionOfferProvider
class_name LooseItemPickupInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

const ACTION_ID: StringName = &"item.pickup"
const CATEGORY: StringName = &"item"
const PRIORITY: int = 140

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null

func _init(world: WorldState = null, reach: WorldInteractionReachQuery = null) -> void:
    _world = world
    _reach = reach

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready()

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready():
        return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if not _world.has_entity(target_id):
            continue
        var entity: WorldEntityRecord = _world.entity(target_id)
        var placement: WorldPlacement = _world.placement(target_id)
        if entity == null or placement == null or placement.channel != Layers.Channel.LOOSE_ITEM:
            continue
        if not String(entity.semantic_type).begins_with("item."):
            continue
        if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        result.append(InteractionOffer.new(
            actor_id,
            target_id,
            ACTION_ID,
            "PICK UP",
            WorldInteractionReachQuery.CONTACT_FORWARD,
            placement.world_cells(),
            PRIORITY,
            CATEGORY,
            true
        ))
    return result
