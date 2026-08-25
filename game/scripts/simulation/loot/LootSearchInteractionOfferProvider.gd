extends InteractionOfferProvider
class_name LootSearchInteractionOfferProvider

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## System-24-owned read-only adapter into System 29. SEARCH remains a System-24
## action; this provider merely reports when an already-real searchable container is
## presently a legal reach candidate.

const SEARCH_ACTION_ID: StringName = &"scavenge.search_container"
const SEARCH_LABEL: String = "SEARCH"
const CATEGORY: StringName = &"container"
const PRESENTATION_PRIORITY: int = 100

var _world: WorldState = null
var _containment: InventoryContainmentState = null
var _loot_state: LootState = null
var _profiles: LootContainerProfileCatalog = null
var _reach: WorldInteractionReachQuery = null

func _init(
    world_state: WorldState = null,
    containment_state: InventoryContainmentState = null,
    loot_state: LootState = null,
    profile_catalog: LootContainerProfileCatalog = null,
    reach_query: WorldInteractionReachQuery = null
) -> void:
    _world = world_state
    _containment = containment_state
    _loot_state = loot_state
    _profiles = profile_catalog
    _reach = reach_query
    _connect_sources()

func is_ready() -> bool:
    return _world != null \
        and _containment != null \
        and _loot_state != null \
        and _profiles != null \
        and _reach != null and _reach.is_ready()

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    if not is_ready():
        return result
    var actor: String = actor_id.strip_edges()
    if actor.is_empty():
        return result

    var ordered: Array[String] = candidate_target_ids.duplicate()
    ordered.sort()
    for container_id: String in ordered:
        if not _loot_state.has_container(container_id) or not _containment.has_container(container_id):
            continue
        if not _world.has_entity(container_id):
            continue
        var placement: WorldPlacement = _world.placement(container_id)
        if placement == null or placement.channel != Layers.Channel.OBJECT:
            continue
        if not _reach.target_reachable(actor, container_id, WorldInteractionReachQuery.CONTACT_FORWARD):
            continue

        var record: Dictionary = _loot_state.container_record(container_id)
        var profile_id: StringName = StringName(record.get("loot_profile_id", &""))
        var profile: Dictionary = _profiles.profile(profile_id)
        if profile.is_empty() or int(profile.get("version", 0)) != int(record.get("loot_profile_version", -1)):
            continue
        if int(profile.get("search_ticks", 0)) < 1:
            continue

        result.append(InteractionOffer.new(
            actor,
            container_id,
            SEARCH_ACTION_ID,
            SEARCH_LABEL,
            WorldInteractionReachQuery.CONTACT_FORWARD,
            placement.world_cells(),
            PRESENTATION_PRIORITY,
            CATEGORY,
            true
        ))
    return result

func _connect_sources() -> void:
    if _loot_state != null:
        var initialized := Callable(self, "_on_loot_source_initialized")
        var reset := Callable(self, "_on_loot_state_reset")
        if not _loot_state.loot_source_initialized.is_connected(initialized):
            _loot_state.loot_source_initialized.connect(initialized)
        if not _loot_state.loot_state_reset.is_connected(reset):
            _loot_state.loot_state_reset.connect(reset)
    if _containment != null:
        var enrolled := Callable(self, "_on_container_enrolled")
        var removed := Callable(self, "_on_container_removed")
        var reset := Callable(self, "_on_containment_reset")
        if not _containment.container_enrolled.is_connected(enrolled):
            _containment.container_enrolled.connect(enrolled)
        if not _containment.container_removed.is_connected(removed):
            _containment.container_removed.connect(removed)
        if not _containment.containment_reset.is_connected(reset):
            _containment.containment_reset.connect(reset)

func _on_loot_source_initialized(_source_key: String, _revision: int) -> void:
    availability_changed.emit(&"loot_source_initialized")

func _on_loot_state_reset() -> void:
    availability_changed.emit(&"loot_state_reset")

func _on_container_enrolled(_container_id: String, _version: int) -> void:
    availability_changed.emit(&"container_enrolled")

func _on_container_removed(_container_id: String, _previous_version: int) -> void:
    availability_changed.emit(&"container_removed")

func _on_containment_reset() -> void:
    availability_changed.emit(&"containment_reset")
