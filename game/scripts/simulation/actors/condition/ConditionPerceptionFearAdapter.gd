extends RefCounted
class_name ConditionPerceptionFearAdapter

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## System 23 -> System 34 fear adapter. Only actually VISIBLE infected actors can
## create visual threat pressure. Hidden/remembered actors never leak into Calm.

var _world: WorldState = null
var _perception: ObserverPerceptionService = null
var _condition: ActorConditionService = null
var _actor_id: String = ""
var _visible_threats: Dictionary = {}

func _init(
    world_state: WorldState = null,
    perception_service: ObserverPerceptionService = null,
    condition_service: ActorConditionService = null,
    actor_id: String = ""
) -> void:
    _world = world_state
    _perception = perception_service
    _condition = condition_service
    _actor_id = actor_id.strip_edges()
    if _perception != null:
        var callable := Callable(self, "_on_perception_changed")
        if not _perception.perception_changed.is_connected(callable):
            _perception.perception_changed.connect(callable)
    _refresh_visible_threats()

func is_ready() -> bool:
    return _world != null and _perception != null and _perception.is_ready() \
        and _condition != null and _condition.is_ready() and _condition.has_actor(_actor_id)

func visible_threat_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _visible_threats.keys():
        result.append(String(key))
    result.sort()
    return result

func _on_perception_changed(_reason: StringName) -> void:
    _refresh_visible_threats()

func _refresh_visible_threats() -> void:
    if not is_ready():
        return
    var current: Dictionary = {}
    for cell: Vector2i in _perception.visible_cells():
        for entity_id: String in _world.entities_at(cell, Layers.Channel.ACTOR):
            if entity_id == _actor_id or current.has(entity_id):
                continue
            var entity: WorldEntityRecord = _world.entity(entity_id)
            var placement: WorldPlacement = _world.placement(entity_id)
            if entity == null or placement == null or entity.semantic_type != &"actor.infected":
                continue
            if not _perception.is_visible(placement.anchor):
                continue
            current[entity_id] = true
            if not _visible_threats.has(entity_id):
                _condition.change_condition(_actor_id, StateClass.CALM, -12, &"visible_infected_threat")
    _visible_threats = current
