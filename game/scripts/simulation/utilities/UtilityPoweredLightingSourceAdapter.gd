extends RefCounted
class_name UtilityPoweredLightingSourceAdapter

const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const EmitterClass = preload("res://scripts/simulation/lighting/LightEmitter.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")

## Truthful System-33/System-27 source provider.
## Fixed emitters are real WHAT fixture entities at their real placements and are
## gated by the power service for that cell. The controlled actor emits a flashlight
## cone only while an actual item.tool.flashlight entity is assigned to either hand.
## Battery/toggle truth is deliberately not invented here.

signal emitters_changed(emitters)

const FLASHLIGHT_SEMANTIC: StringName = &"item.tool.flashlight"
const FIXED_LIGHT_TYPES: Array[StringName] = [
    &"prop.streetlight",
    &"prop.traffic_light",
    &"prop.crosswalk_beacon",
    &"prop.floor_lamp",
    &"prop.lamp",
    &"prop.neon_sign",
]

var _world: WorldState = null
var _hand_state: ActorHandEquipmentState = null
var _player_id: String = ""
var _utilities: UtilityRuntimeState = null
var _fixed_entities: Dictionary = {}
var _signature: String = ""

func _init(
    world_state: WorldState = null,
    hand_state: ActorHandEquipmentState = null,
    controlled_actor_id: String = "",
    utilities: UtilityRuntimeState = null
) -> void:
    _world = world_state
    _hand_state = hand_state
    _player_id = controlled_actor_id.strip_edges()
    _utilities = utilities
    if not is_ready():
        return
    _discover_existing_fixed_emitters()
    _signature = _current_signature()
    _connect_signals()

func is_ready() -> bool:
    return _world != null \
        and _hand_state != null \
        and not _player_id.is_empty() \
        and _utilities != null \
        and _utilities.is_ready()

func emitters() -> Array[LightEmitter]:
    var result: Array[LightEmitter] = []
    if not is_ready():
        return result

    var flashlight_item_id: String = _equipped_flashlight_item_id()
    var player: WorldPlacement = _world.placement(_player_id)
    if not flashlight_item_id.is_empty() and player != null:
        result.append(EmitterClass.new(
            _flashlight_emitter_id(flashlight_item_id),
            player.anchor,
            player.facing,
            EmitterProfileClass.flashlight(),
            true,
            1
        ))

    for entity_id: String in _sorted_fixed_entity_ids():
        if not _world.has_entity(entity_id):
            continue
        var record: WorldEntityRecord = _world.entity(entity_id)
        var placement: WorldPlacement = _world.placement(entity_id)
        if record == null or placement == null:
            continue
        var profile: LightEmitterProfile = _profile_for_semantic(record.semantic_type)
        if profile == null:
            continue
        var appliance_id: String = String(_fixed_entities.get(entity_id, ""))
        if appliance_id.is_empty() or not _utilities.appliance_powered(appliance_id):
            continue
        result.append(EmitterClass.new(
            appliance_id,
            placement.anchor,
            placement.facing,
            profile,
            true,
            1
        ))
    return result

func fixed_emitter_ids() -> Array[String]:
    var result: Array[String] = []
    for entity_id: String in _sorted_fixed_entity_ids():
        result.append(String(_fixed_entities.get(entity_id, "")))
    return result

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "fixed_fixture_count": _fixed_entities.size(),
        "fixed_emitter_ids": fixed_emitter_ids(),
        "equipped_flashlight_item_id": _equipped_flashlight_item_id(),
        "fake_sources_retired": true,
    }

func _discover_existing_fixed_emitters() -> void:
    _fixed_entities.clear()
    if not is_ready():
        return
    for semantic_type: StringName in FIXED_LIGHT_TYPES:
        for entity_id: String in _world.entity_ids_of_type(semantic_type):
            _refresh_fixed_entity(entity_id)

func _refresh_fixed_entity(entity_id: String) -> void:
    var key: String = entity_id.strip_edges()
    if key.is_empty() or not _world.has_entity(key):
        _fixed_entities.erase(key)
        return
    var record: WorldEntityRecord = _world.entity(key)
    var placement: WorldPlacement = _world.placement(key)
    if record == null or placement == null or _profile_for_semantic(record.semantic_type) == null:
        _fixed_entities.erase(key)
        return
    var power_service_id: String = _utilities.power_service_for_cell(placement.anchor)
    if power_service_id.is_empty():
        _fixed_entities.erase(key)
        return
    var appliance_id: String = _fixed_appliance_id(key)
    _fixed_entities[key] = appliance_id
    if not _utilities.bind_appliance(appliance_id, &"fixed_light", power_service_id, key, true):
        _fixed_entities.erase(key)

func _equipped_flashlight_item_id() -> String:
    if _hand_state == null or not _hand_state.has_actor(_player_id):
        return ""
    var candidates: Array[String] = [
        _hand_state.primary_item(_player_id),
        _hand_state.secondary_item(_player_id),
    ]
    for item_id: String in candidates:
        if item_id.is_empty() or not _world.has_entity(item_id):
            continue
        var item: WorldEntityRecord = _world.entity(item_id)
        if item != null and item.semantic_type == FLASHLIGHT_SEMANTIC:
            return item_id
    return ""

func _player_references_item(item_id: String) -> bool:
    if _hand_state == null or not _hand_state.has_actor(_player_id):
        return false
    return _hand_state.primary_item(_player_id) == item_id \
        or _hand_state.secondary_item(_player_id) == item_id

func _profile_for_semantic(semantic_type: StringName) -> LightEmitterProfile:
    match semantic_type:
        &"prop.streetlight", &"prop.traffic_light", &"prop.crosswalk_beacon":
            return EmitterProfileClass.streetlight()
        &"prop.floor_lamp", &"prop.lamp":
            return EmitterProfileClass.lamp()
        &"prop.neon_sign":
            return EmitterProfileClass.neon()
        _:
            return null

func _fixed_appliance_id(entity_id: String) -> String:
    return "utility.light:%s" % entity_id

func _flashlight_emitter_id(item_id: String) -> String:
    return "equipment.flashlight:%s" % item_id

func _sorted_fixed_entity_ids() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _fixed_entities.keys():
        result.append(String(value))
    result.sort()
    return result

func _connect_signals() -> void:
    var world_callable := Callable(self, "_on_world_changed")
    var world_reset_callable := Callable(self, "_on_world_reset")
    var hand_callable := Callable(self, "_on_hand_assignment_changed")
    var hand_reset_callable := Callable(self, "_on_hand_equipment_reset")
    var actor_enrolled_callable := Callable(self, "_on_actor_enrolled")
    var actor_removed_callable := Callable(self, "_on_actor_removed")
    var power_callable := Callable(self, "_on_power_changed")
    var appliance_callable := Callable(self, "_on_appliances_changed")
    var utility_reset_callable := Callable(self, "_on_utility_reset")
    if not _world.changed.is_connected(world_callable):
        _world.changed.connect(world_callable)
    if not _world.world_reset.is_connected(world_reset_callable):
        _world.world_reset.connect(world_reset_callable)
    if not _hand_state.hand_assignment_changed.is_connected(hand_callable):
        _hand_state.hand_assignment_changed.connect(hand_callable)
    if not _hand_state.hand_equipment_reset.is_connected(hand_reset_callable):
        _hand_state.hand_equipment_reset.connect(hand_reset_callable)
    if not _hand_state.actor_enrolled.is_connected(actor_enrolled_callable):
        _hand_state.actor_enrolled.connect(actor_enrolled_callable)
    if not _hand_state.actor_removed.is_connected(actor_removed_callable):
        _hand_state.actor_removed.connect(actor_removed_callable)
    if not _utilities.power_changed.is_connected(power_callable):
        _utilities.power_changed.connect(power_callable)
    if not _utilities.appliances_changed.is_connected(appliance_callable):
        _utilities.appliances_changed.connect(appliance_callable)
    if not _utilities.utility_reset.is_connected(utility_reset_callable):
        _utilities.utility_reset.connect(utility_reset_callable)

func _on_world_changed(change: WorldChange) -> void:
    if change == null:
        return
    var relevant: bool = false
    if change.entity_id == _player_id:
        relevant = change.kind == ChangeClass.Kind.PLACEMENT_SET \
            or change.kind == ChangeClass.Kind.PLACEMENT_REMOVED \
            or change.kind == ChangeClass.Kind.ENTITY_REMOVED
    if _player_references_item(change.entity_id):
        relevant = true

    if _fixed_entities.has(change.entity_id):
        if change.kind == ChangeClass.Kind.ENTITY_REMOVED \
            or change.kind == ChangeClass.Kind.PLACEMENT_REMOVED:
            _fixed_entities.erase(change.entity_id)
        else:
            _refresh_fixed_entity(change.entity_id)
        relevant = true
    elif change.kind == ChangeClass.Kind.ENTITY_CREATED \
        or change.kind == ChangeClass.Kind.PLACEMENT_SET:
        var record: WorldEntityRecord = _world.entity(change.entity_id)
        if record != null and _profile_for_semantic(record.semantic_type) != null:
            _refresh_fixed_entity(change.entity_id)
            relevant = true

    if relevant:
        _emit_if_changed()

func _on_world_reset() -> void:
    _discover_existing_fixed_emitters()
    _emit_if_changed()

func _on_hand_assignment_changed(actor_id: String, _slot: int, _previous_item_id: String, _new_item_id: String, _version: int) -> void:
    if actor_id == _player_id:
        _emit_if_changed()

func _on_hand_equipment_reset() -> void:
    _emit_if_changed()

func _on_actor_enrolled(actor_id: String, _version: int) -> void:
    if actor_id == _player_id:
        _emit_if_changed()

func _on_actor_removed(actor_id: String, _primary_item_id: String, _secondary_item_id: String, _version: int) -> void:
    if actor_id == _player_id:
        _emit_if_changed()

func _on_power_changed(_revision: int, _reason: StringName) -> void:
    _emit_if_changed()

func _on_appliances_changed(_revision: int, _reason: StringName) -> void:
    _emit_if_changed()

func _on_utility_reset() -> void:
    _discover_existing_fixed_emitters()
    _emit_if_changed()

func _emit_if_changed() -> void:
    var next_signature: String = _current_signature()
    if next_signature == _signature:
        return
    _signature = next_signature
    emitters_changed.emit(emitters())

func _current_signature() -> String:
    if not is_ready():
        return "not_ready"
    var parts: PackedStringArray = []
    for emitter: LightEmitter in emitters():
        parts.append(emitter.signature())
    return "|".join(parts)
