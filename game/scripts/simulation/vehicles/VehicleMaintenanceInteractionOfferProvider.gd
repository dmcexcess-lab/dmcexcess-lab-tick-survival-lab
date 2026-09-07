extends InteractionOfferProvider
class_name VehicleMaintenanceInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Actions = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")

const PRIORITY: int = 155
const CATEGORY: StringName = &"vehicle"

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _state: VehicleState = null
var _profiles: VehicleProfileCatalog = null

func _init(
    world: WorldState = null,
    reach: WorldInteractionReachQuery = null,
    state: VehicleState = null,
    profiles: VehicleProfileCatalog = null
) -> void:
    _world = world
    _reach = reach
    _state = state
    _profiles = profiles
    if _state != null:
        _state.changed.connect(_on_vehicle_changed)
        _state.state_reset.connect(_on_state_reset)

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() and _state != null and _profiles != null

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready() or not _state.vehicle_for_driver(actor_id).is_empty():
        return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if not _state.has_vehicle(target_id) or not _world.has_entity(target_id):
            continue
        var placement: WorldPlacement = _world.placement(target_id)
        if placement == null or placement.channel not in [Layers.Channel.OBJECT, Layers.Channel.LOOSE_ITEM] \
            or not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        var record: Dictionary = _state.record(target_id)
        var kind: StringName = StringName(record.get("kind", &""))
        if not _profiles.has_profile(kind):
            continue

        if _needs_repair(record):
            _append(result, actor_id, target_id, placement, Actions.REPAIR, "REPAIR", PRIORITY + 7)
        if _profiles.is_motorized(kind) and int(record.get("fuel", 0)) < _profiles.max_fuel(kind):
            _append(result, actor_id, target_id, placement, Actions.REFUEL, "REFUEL", PRIORITY + 6)
        var mods: Array = record.get("mods", [])
        if _profiles.cargo_grams(kind) > 0 and &"cargo_rack" not in mods:
            _append(result, actor_id, target_id, placement, Actions.MODIFY, "ADD RACK", PRIORITY + 5)

        # HOTWIRE is intentionally absent. It is a mounted driving-control action only.
    return result

func _needs_repair(record: Dictionary) -> bool:
    for field_name: String in ["body", "propulsion", "wheels", "electrical"]:
        if int(record.get(field_name, 100)) < 100:
            return true
    return false

func _append(
    result: Array[InteractionOffer],
    actor_id: String,
    target_id: String,
    placement: WorldPlacement,
    action_id: StringName,
    label: String,
    priority: int
) -> void:
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

func _on_vehicle_changed(_vehicle_id: String, _revision: int) -> void:
    availability_changed.emit(&"vehicle_maintenance_changed")

func _on_state_reset(_revision: int) -> void:
    availability_changed.emit(&"vehicle_maintenance_reset")
