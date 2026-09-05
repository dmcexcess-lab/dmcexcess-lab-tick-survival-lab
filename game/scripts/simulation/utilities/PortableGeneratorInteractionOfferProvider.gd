extends InteractionOfferProvider
class_name PortableGeneratorInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Actions = preload("res://scripts/simulation/utilities/PortableGeneratorActionService.gd")

const PRIORITY: int = 145
const CATEGORY: StringName = &"utility"

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _generators: PortableGeneratorState = null

func _init(world: WorldState = null, reach: WorldInteractionReachQuery = null, generators: PortableGeneratorState = null) -> void:
    _world = world
    _reach = reach
    _generators = generators
    if _generators != null:
        _generators.generator_changed.connect(_on_generator_changed)
        _generators.state_reset.connect(_on_state_reset)

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() and _generators != null

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready():
        return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if not _generators.has_generator(target_id) or not _world.has_entity(target_id):
            continue
        var entity: WorldEntityRecord = _world.entity(target_id)
        var placement: WorldPlacement = _world.placement(target_id)
        if entity == null or entity.semantic_type != PortableGeneratorState.SEMANTIC or placement == null \
            or placement.channel != Layers.Channel.OBJECT \
            or not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        var state: Dictionary = _generators.record(target_id)
        var fuel: int = int(state.get("fuel_ticks", 0))
        var condition: int = int(state.get("condition", 0))
        var running: bool = bool(state.get("running", false))
        _append(result, actor_id, target_id, placement, Actions.INSPECT, "INSPECT · %s · FUEL %d/%d · %d%%" % ["ON" if running else "OFF", fuel, PortableGeneratorState.MAX_FUEL_TICKS, condition], PRIORITY)
        if running:
            _append(result, actor_id, target_id, placement, Actions.STOP, "STOP", PRIORITY + 8)
        else:
            if _generators.can_refuel(target_id):
                _append(result, actor_id, target_id, placement, Actions.REFUEL, "REFUEL", PRIORITY + 5)
            if _generators.can_start(target_id):
                _append(result, actor_id, target_id, placement, Actions.START, "START", PRIORITY + 8)
            if _generators.can_repair(target_id):
                _append(result, actor_id, target_id, placement, Actions.REPAIR, "REPAIR", PRIORITY + 6)
    return result

func _append(result: Array[InteractionOffer], actor_id: String, target_id: String, placement: WorldPlacement, action_id: StringName, label: String, priority: int) -> void:
    result.append(InteractionOffer.new(actor_id, target_id, action_id, label, WorldInteractionReachQuery.CONTACT_FORWARD, placement.world_cells(), priority, CATEGORY, true))

func _on_generator_changed(_generator_id: String, _version: int, reason: StringName) -> void:
    availability_changed.emit(reason)

func _on_state_reset() -> void:
    availability_changed.emit(&"generator_state_reset")
