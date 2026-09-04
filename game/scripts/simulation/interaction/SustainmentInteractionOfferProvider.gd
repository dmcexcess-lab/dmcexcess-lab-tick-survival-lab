extends InteractionOfferProvider
class_name SustainmentInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

const DRINK_FROM_FIXTURE: StringName = &"sustainment.drink_fixture"
const REST_ON_FURNITURE: StringName = &"sustainment.rest_on"
const SLEEP_IN_BED: StringName = &"sustainment.sleep_in"
const CATEGORY: StringName = &"sustainment"
const PRIORITY: int = 125

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _catalog: WorldInteractionCatalog = null
var _potable_target_provider: Callable = Callable()

func _init(
    world: WorldState = null,
    reach: WorldInteractionReachQuery = null,
    catalog: WorldInteractionCatalog = null,
    potable_target_provider: Callable = Callable()
) -> void:
    _world = world
    _reach = reach
    _catalog = catalog
    _potable_target_provider = potable_target_provider

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() and _catalog != null and _potable_target_provider.is_valid()

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready(): return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if not _world.has_entity(target_id): continue
        var entity: WorldEntityRecord = _world.entity(target_id)
        var placement: WorldPlacement = _world.placement(target_id)
        if entity == null or placement == null or placement.channel != Layers.Channel.OBJECT: continue
        if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD): continue
        if _catalog.is_water_fixture(entity.semantic_type) and bool(_potable_target_provider.call(actor_id, target_id)):
            _append(result, actor_id, target_id, placement, DRINK_FROM_FIXTURE, "DRINK", PRIORITY + 5)
        var surface: StringName = _catalog.rest_surface(entity.semantic_type)
        if surface == &"bed":
            _append(result, actor_id, target_id, placement, SLEEP_IN_BED, "SLEEP", PRIORITY + 8)
            _append(result, actor_id, target_id, placement, REST_ON_FURNITURE, "REST", PRIORITY + 3)
        elif surface == &"chair" or surface == &"sofa":
            _append(result, actor_id, target_id, placement, REST_ON_FURNITURE, "REST", PRIORITY + 3)
    return result

func _append(result: Array[InteractionOffer], actor_id: String, target_id: String, placement: WorldPlacement, action_id: StringName, label: String, priority: int) -> void:
    result.append(InteractionOffer.new(
        actor_id,
        target_id,
        action_id,
        label,
        WorldInteractionReachQuery.CONTACT_FORWARD,
        placement.world_cells(),
        priority,
        CATEGORY,
        true
    ))
