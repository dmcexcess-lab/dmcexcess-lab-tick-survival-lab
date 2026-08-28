extends InteractionOfferProvider
class_name CraftingInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## System-32 read-only adapter into System 29. It reports only explicitly classified
## reachable workstation objects; actual craft eligibility remains CraftingPlanQuery.

const ACTION_ID: StringName = &"crafting.use_workstation"
const LABEL: String = "CRAFT"
const CATEGORY: StringName = &"crafting"
const PRESENTATION_PRIORITY: int = 90

var _world: WorldState = null
var _workstations: CraftingWorkstationCatalog = null
var _reach: WorldInteractionReachQuery = null

func _init(
    world_state: WorldState = null,
    workstation_catalog: CraftingWorkstationCatalog = null,
    reach_query: WorldInteractionReachQuery = null
) -> void:
    _world = world_state
    _workstations = workstation_catalog
    _reach = reach_query

func is_ready() -> bool:
    return _world != null and _workstations != null and _reach != null and _reach.is_ready()

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready():
        return result
    var actor: String = actor_id.strip_edges()
    if actor.is_empty():
        return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if not _world.has_entity(target_id):
            continue
        var entity: WorldEntityRecord = _world.entity(target_id)
        var placement: WorldPlacement = _world.placement(target_id)
        if entity == null or placement == null or placement.channel != Layers.Channel.OBJECT:
            continue
        if _workstations.capabilities_for_semantic(entity.semantic_type).is_empty():
            continue
        if not _reach.target_reachable(actor, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        result.append(InteractionOffer.new(
            actor,
            target_id,
            ACTION_ID,
            LABEL,
            WorldInteractionReachQuery.CONTACT_FORWARD,
            placement.world_cells(),
            PRESENTATION_PRIORITY,
            CATEGORY,
            true
        ))
    return result
