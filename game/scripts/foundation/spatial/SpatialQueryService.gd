class_name SpatialQueryService
extends RefCounted

## Canonical read-only spatial query facade used by gameplay.
## WorldState owns placements/occupancy; this service exposes stable spatial reads.

var _world: WorldState


func _init(world: WorldState) -> void:
	_world = world


func query_entity_footprint(entity_id: String) -> Dictionary:
	if _world == null or not _world.has_placement(entity_id):
		return {}
	var placement: WorldPlacement = _world.placement(entity_id)
	if placement == null:
		return {}
	return {
		"entity_id": entity_id,
		"anchor": placement.anchor,
		"facing": placement.facing,
		"channel": placement.channel,
		"cells": placement.world_cells(),
	}


func query_tile_occupants(tile: Vector2i) -> Array[String]:
	if _world == null:
		return []
	return _world.entities_at(tile)


func query_entities_in_rect(rect: Rect2i) -> Array[String]:
	var result: Array[String] = []
	if _world == null or rect.size.x <= 0 or rect.size.y <= 0:
		return result
	var seen: Dictionary = {}
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			for entity_id: String in _world.entities_at(Vector2i(x, y)):
				if not seen.has(entity_id):
					seen[entity_id] = true
					result.append(entity_id)
	return result


func is_tile_occupied(tile: Vector2i, ignore_entity_id: String = "") -> bool:
	for entity_id: String in query_tile_occupants(tile):
		if ignore_entity_id.is_empty() or entity_id != ignore_entity_id:
			return true
	return false
