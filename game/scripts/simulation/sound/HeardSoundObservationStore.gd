extends RefCounted
class_name HeardSoundObservationStore

const ObservationClass = preload("res://scripts/simulation/sound/HeardSoundObservation.gd")

## Active listener auditory knowledge keyed by listener + opaque repeated group.

signal observations_changed(listener_id)
signal observations_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _listeners: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func listener_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _listeners.keys():
        result.append(String(key))
    result.sort()
    return result

func has_listener(listener_id: String) -> bool:
    return _listeners.has(listener_id.strip_edges())

func enroll_listener(listener_id: String) -> bool:
    var normalized: String = listener_id.strip_edges()
    if normalized.is_empty():
        return false
    if _listeners.has(normalized):
        return true
    _listeners[normalized] = {}
    _revision += 1
    observations_changed.emit(normalized)
    return true

func remove_listener(listener_id: String) -> bool:
    var normalized: String = listener_id.strip_edges()
    if not _listeners.has(normalized):
        return false
    _listeners.erase(normalized)
    _revision += 1
    observations_changed.emit(normalized)
    return true

func upsert(observation: HeardSoundObservation) -> bool:
    if observation == null or not observation.is_valid() or not _listeners.has(observation.listener_id):
        return false
    var groups: Dictionary = _listeners[observation.listener_id]
    groups[observation.group_id] = observation.copy()
    _listeners[observation.listener_id] = groups
    _revision += 1
    observations_changed.emit(observation.listener_id)
    return true

func active_observations(listener_id: String, world_tick: int) -> Array[HeardSoundObservation]:
    var normalized: String = listener_id.strip_edges()
    var result: Array[HeardSoundObservation] = []
    if world_tick < 0 or not _listeners.has(normalized):
        return result
    var groups: Dictionary = _listeners[normalized]
    var ordered_keys: Array[String] = []
    for key: Variant in groups.keys():
        ordered_keys.append(String(key))
    ordered_keys.sort()
    for group_key: String in ordered_keys:
        var observation: HeardSoundObservation = groups[group_key]
        if observation != null and observation.expiry_tick >= world_tick:
            result.append(observation.copy())
    result.sort_custom(func(a: HeardSoundObservation, b: HeardSoundObservation) -> bool:
        if a.heard_tick == b.heard_tick:
            return a.cue_id < b.cue_id
        return a.heard_tick < b.heard_tick
    )
    return result

func prune_expired(world_tick: int) -> int:
    if world_tick < 0:
        return 0
    var removed: int = 0
    var changed_listeners: Array[String] = []
    for listener_id: String in listener_ids():
        var groups: Dictionary = _listeners[listener_id]
        var changed: bool = false
        for key: Variant in groups.keys():
            var observation: HeardSoundObservation = groups[key]
            if observation == null or observation.expiry_tick < world_tick:
                groups.erase(key)
                removed += 1
                changed = true
        if changed:
            _listeners[listener_id] = groups
            changed_listeners.append(listener_id)
    if removed > 0:
        _revision += 1
        for listener_id: String in changed_listeners:
            observations_changed.emit(listener_id)
    return removed

func snapshot() -> Dictionary:
    var listeners: Array = []
    for listener_id: String in listener_ids():
        var entries: Array = []
        var groups: Dictionary = _listeners[listener_id]
        var keys: Array[String] = []
        for key: Variant in groups.keys():
            keys.append(String(key))
        keys.sort()
        for key: String in keys:
            var observation: HeardSoundObservation = groups[key]
            if observation != null:
                entries.append(observation.to_snapshot())
        listeners.append({"listener_id": listener_id, "observations": entries})
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "listeners": listeners,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var revision_value: int = int(data.get("revision", -1))
    var listeners_value: Variant = data.get("listeners", [])
    if revision_value < 0 or typeof(listeners_value) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for listener_value: Variant in listeners_value:
        if typeof(listener_value) != TYPE_DICTIONARY:
            return false
        var listener: Dictionary = listener_value
        var listener_id: String = String(listener.get("listener_id", "")).strip_edges()
        var observations_value: Variant = listener.get("observations", [])
        if listener_id.is_empty() or restored.has(listener_id) or typeof(observations_value) != TYPE_ARRAY:
            return false
        var groups: Dictionary = {}
        for observation_value: Variant in observations_value:
            if typeof(observation_value) != TYPE_DICTIONARY:
                return false
            var observation: HeardSoundObservation = ObservationClass.from_snapshot(observation_value)
            if observation == null or observation.listener_id != listener_id or groups.has(observation.group_id):
                return false
            groups[observation.group_id] = observation
        restored[listener_id] = groups
    _listeners = restored
    _revision = revision_value
    observations_reset.emit()
    for listener_id: String in listener_ids():
        observations_changed.emit(listener_id)
    return true
