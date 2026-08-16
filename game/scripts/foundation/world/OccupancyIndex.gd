extends RefCounted
class_name OccupancyIndex

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Derived acceleration index: global cell -> channel -> sorted entity IDs.
## This is never authoritative; it is rebuilt from PlacementStore when needed.

var _by_cell: Dictionary = {}

func clear() -> void:
    _by_cell.clear()

func add(placement: WorldPlacement) -> void:
    if placement == null or not placement.is_valid():
        return
    for cell: Vector2i in placement.world_cells():
        var channel_map: Dictionary = _by_cell.get(cell, {})
        var ids: Array = channel_map.get(placement.channel, [])
        if not ids.has(placement.entity_id):
            ids.append(placement.entity_id)
            ids.sort()
        channel_map[placement.channel] = ids
        _by_cell[cell] = channel_map

func remove(placement: WorldPlacement) -> void:
    if placement == null or not placement.is_valid():
        return
    for cell: Vector2i in placement.world_cells():
        if not _by_cell.has(cell):
            continue
        var channel_map: Dictionary = _by_cell[cell]
        if not channel_map.has(placement.channel):
            continue
        var ids: Array = channel_map[placement.channel]
        ids.erase(placement.entity_id)
        if ids.is_empty():
            channel_map.erase(placement.channel)
        else:
            channel_map[placement.channel] = ids
        if channel_map.is_empty():
            _by_cell.erase(cell)
        else:
            _by_cell[cell] = channel_map

func ids_at(cell: Vector2i, channel: int = -1) -> Array[String]:
    var result: Array[String] = []
    if not _by_cell.has(cell):
        return result
    var channel_map: Dictionary = _by_cell[cell]

    if channel >= 0:
        if not Layers.is_valid(channel):
            return result
        for value: Variant in channel_map.get(channel, []):
            result.append(String(value))
        return result

    for current_channel: int in range(Layers.Channel.TERRAIN, Layers.Channel.EFFECT + 1):
        for value: Variant in channel_map.get(current_channel, []):
            result.append(String(value))
    return result

func rebuild(placements: PlacementStore) -> void:
    clear()
    if placements == null:
        return
    for entity_id: String in placements.ids():
        add(placements.get_placement(entity_id))
