extends RefCounted
class_name PlacementStore

## Internal persistent placement store keyed by entity ID.

var _by_id: Dictionary = {}

func has(entity_id: String) -> bool:
    return _by_id.has(entity_id)

func set_placement(placement: WorldPlacement) -> bool:
    if placement == null or not placement.is_valid():
        return false
    _by_id[placement.entity_id] = placement.copy()
    return true

func remove(entity_id: String) -> WorldPlacement:
    if not has(entity_id):
        return null
    var placement: WorldPlacement = _by_id[entity_id]
    _by_id.erase(entity_id)
    return placement

func get_placement(entity_id: String) -> WorldPlacement:
    if not has(entity_id):
        return null
    return _by_id[entity_id]

func ids() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _by_id.keys():
        result.append(String(value))
    result.sort()
    return result

func clear() -> void:
    _by_id.clear()

func snapshot_entries() -> Array:
    var entries: Array = []
    for entity_id: String in ids():
        var placement: WorldPlacement = _by_id[entity_id]
        entries.append(placement.to_snapshot())
    return entries
