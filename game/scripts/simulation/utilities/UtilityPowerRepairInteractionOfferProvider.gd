extends InteractionOfferProvider
class_name UtilityPowerRepairInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const ConditionStore = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")
const RepairActions = preload("res://scripts/simulation/utilities/UtilityPowerRepairActionService.gd")

const CATEGORY: StringName = &"utility"
const PRIORITY: int = 135

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _network: UtilityPowerNetworkRuntime = null

func _init(
    world: WorldState = null,
    reach: WorldInteractionReachQuery = null,
    network: UtilityPowerNetworkRuntime = null
) -> void:
    _world = world
    _reach = reach
    _network = network

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() \
        and _network != null and _network.is_ready()

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
        if entity == null or placement == null \
            or placement.channel not in [Layers.Channel.OBJECT, Layers.Channel.STRUCTURE] \
            or entity.semantic_type != RepairActions.SUPPORTED_SEMANTIC:
            continue
        if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        var asset: Dictionary = _network.asset_record(target_id)
        if asset.is_empty() \
            or StringName(asset.get("kind", &"")) != ConditionStore.DISTRIBUTION_SUPPORT \
            or String(asset.get("entity_id", "")) != target_id \
            or not bool(asset.get("failed", false)):
            continue
        result.append(InteractionOffer.new(
            actor_id,
            target_id,
            RepairActions.ACTION_ID,
            "REPAIR POWER POLE",
            WorldInteractionReachQuery.CONTACT_FORWARD,
            placement.world_cells(),
            PRIORITY,
            CATEGORY,
            true
        ))
    return result
