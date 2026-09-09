extends InteractionOfferProvider
class_name SurvivorInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

const TALK: StringName = &"survivor.talk"
const RECRUIT: StringName = &"survivor.recruit"
const DISMISS: StringName = &"survivor.dismiss"
const ACTION_IDS: Array[StringName] = [TALK, RECRUIT, DISMISS]
const PRIORITY: int = 340
const CATEGORY: StringName = &"social"

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _state: SurvivorNpcState = null
var _health: ActorHealthState = null

func _init(world: WorldState = null, reach: WorldInteractionReachQuery = null, state: SurvivorNpcState = null, health: ActorHealthState = null) -> void:
    _world = world
    _reach = reach
    _state = state
    _health = health
    if _state != null:
        _state.role_changed.connect(_on_role_changed)
        _state.survivor_removed.connect(_on_survivor_removed)
    if _health != null:
        _health.hp_changed.connect(_on_health_changed)

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() and _state != null and _health != null

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready():
        return result
    var ordered := candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if target_id == actor_id or not _state.has_actor(target_id) or _state.role(target_id) == SurvivorNpcState.RAIDER \
            or not _health.has_actor(target_id) or _health.current_hp(target_id) <= 0:
            continue
        var placement: WorldPlacement = _world.placement(target_id)
        if placement == null or placement.channel != Layers.Channel.ACTOR \
            or not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        result.append(_offer(actor_id, target_id, TALK, "TALK", placement))
        if _state.role(target_id) == SurvivorNpcState.NEUTRAL:
            result.append(_offer(actor_id, target_id, RECRUIT, "ASK TO FOLLOW", placement))
        elif _state.role(target_id) == SurvivorNpcState.FOLLOWER:
            result.append(_offer(actor_id, target_id, DISMISS, "TELL TO STAY", placement))
    return result

func _offer(actor_id: String, target_id: String, action_id: StringName, label: String, placement: WorldPlacement) -> InteractionOffer:
    return InteractionOffer.new(
        actor_id, target_id, action_id, label, WorldInteractionReachQuery.CONTACT_FORWARD,
        placement.world_cells(), PRIORITY, CATEGORY, true
    )

func _on_role_changed(_actor_id: String, _previous: StringName, _current: StringName) -> void:
    availability_changed.emit(&"survivor_role_changed")

func _on_survivor_removed(_actor_id: String, _reason: StringName) -> void:
    availability_changed.emit(&"survivor_removed")

func _on_health_changed(_actor_id: String, _previous: int, _current: int, _maximum: int, _version: int) -> void:
    availability_changed.emit(&"survivor_health_changed")
