extends InteractionOfferProvider
class_name CombatInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PerceptionClass = preload("res://scripts/simulation/perception/ObserverPerceptionService.gd")

const PRIORITY: int = 300
const CATEGORY: StringName = &"combat"

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _perception: ObserverPerceptionService = null
var _health: ActorHealthState = null
var _combat: CombatActionService = null

func _init(
    world: WorldState = null,
    reach: WorldInteractionReachQuery = null,
    perception: ObserverPerceptionService = null,
    health: ActorHealthState = null,
    combat: CombatActionService = null
) -> void:
    _world = world
    _reach = reach
    _perception = perception
    _health = health
    _combat = combat
    if _health != null:
        _health.hp_changed.connect(_on_health_changed)
    if _perception != null:
        _perception.perception_changed.connect(_on_perception_changed)

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() \
        and _perception != null and _perception.is_ready() \
        and _health != null and _combat != null and _combat.is_ready()

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready():
        return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if target_id == actor_id or not _health.has_actor(target_id) or _health.current_hp(target_id) <= 0:
            continue
        var target: WorldPlacement = _world.placement(target_id)
        if target == null or target.channel != Layers.Channel.ACTOR:
            continue
        if not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        var visible: bool = false
        for cell: Vector2i in target.world_cells():
            if _perception.knowledge_state(cell) == PerceptionClass.KnowledgeState.VISIBLE:
                visible = true
                break
        if not visible:
            continue
        for descriptor: Dictionary in _combat.action_offers_for_target(actor_id, target_id):
            result.append(InteractionOffer.new(
                actor_id,
                target_id,
                StringName(String(descriptor.get("action_id", ""))),
                String(descriptor.get("label", "COMBAT")),
                WorldInteractionReachQuery.CONTACT_FORWARD,
                target.world_cells(),
                PRIORITY,
                CATEGORY,
                true
            ))
    return result

func _on_health_changed(_actor_id: String, _previous: int, _current: int, _maximum: int, _version: int) -> void:
    availability_changed.emit(&"combat_health_changed")

func _on_perception_changed(_reason: StringName) -> void:
    availability_changed.emit(&"combat_perception_changed")
