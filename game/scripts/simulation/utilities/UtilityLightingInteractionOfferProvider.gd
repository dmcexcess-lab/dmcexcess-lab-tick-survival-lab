extends InteractionOfferProvider
class_name UtilityLightingInteractionOfferProvider

const Actions = preload("res://scripts/simulation/utilities/UtilityLightingInteractionActionService.gd")

## Read-only ordinary interaction offers for real fixed-light fixtures already bound as
## System-33 appliances. Power availability affects the label/emission result but never
## becomes a second switch state.

const PRIORITY: int = 148
const CATEGORY: StringName = &"utility"

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _utilities: UtilityRuntimeState = null

func _init(
    world: WorldState = null,
    reach: WorldInteractionReachQuery = null,
    utilities: UtilityRuntimeState = null
) -> void:
    _world = world
    _reach = reach
    _utilities = utilities
    if _utilities != null:
        var power_callable := Callable(self, "_on_utility_changed")
        var appliance_callable := Callable(self, "_on_appliance_changed")
        if not _utilities.power_changed.is_connected(power_callable):
            _utilities.power_changed.connect(power_callable)
        if not _utilities.appliances_changed.is_connected(appliance_callable):
            _utilities.appliances_changed.connect(appliance_callable)

func is_ready() -> bool:
    return _world != null and _reach != null and _reach.is_ready() \
        and _utilities != null and _utilities.is_ready()

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready():
        return result
    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for target_id: String in ordered:
        if not _world.has_entity(target_id):
            continue
        var placement: WorldPlacement = _world.placement(target_id)
        if placement == null or not _reach.target_reachable(actor_id, target_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue
        var appliance_id: String = Actions.appliance_id_for_target(target_id)
        var record: Dictionary = _utilities.appliance_record(appliance_id)
        if record.is_empty() \
            or StringName(record.get("kind", &"")) != Actions.FIXED_LIGHT_KIND \
            or String(record.get("owner_entity_id", "")) != target_id:
            continue
        var switched_on: bool = bool(record.get("switched_on", false))
        var operational: bool = StringName(record.get("operational_state", &"")) == UtilityRuntimeState.OPERATIONAL
        var powered: bool = _utilities.appliance_powered(appliance_id)
        var label: String = "TURN OFF" if switched_on else "TURN ON"
        if not operational:
            label += " · DAMAGED"
        elif not switched_on and not _power_available_for_record(record):
            label += " · NO POWER"
        elif switched_on and not powered:
            label += " · NO POWER"
        result.append(InteractionOffer.new(
            actor_id,
            target_id,
            Actions.ACTION_TOGGLE,
            label,
            WorldInteractionReachQuery.CONTACT_FORWARD,
            placement.world_cells(),
            PRIORITY,
            CATEGORY,
            true
        ))
    return result

func _power_available_for_record(record: Dictionary) -> bool:
    return _utilities.power_service_available_for_scope(
        String(record.get("power_service_id", "")),
        String(record.get("power_scope_id", ""))
    )

func _on_utility_changed(_revision: int, reason: StringName) -> void:
    availability_changed.emit(reason)

func _on_appliance_changed(_revision: int, reason: StringName) -> void:
    availability_changed.emit(reason)
