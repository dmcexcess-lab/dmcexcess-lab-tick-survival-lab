class_name SpatialQueryService
extends RefCounted

## Canonical read-only spatial query facade used by gameplay.
## SpatialModel owns the implementation; this service keeps callers on one stable API.

var _model: SpatialModel


func _init(model: SpatialModel) -> void:
	_model = model


func query_entity_footprint(entity_id: String) -> Dictionary:
	if _model == null or not _model.has_method("query_entity_footprint"):
		return {}
	var result: Variant = _model.call("query_entity_footprint", entity_id)
	return result as Dictionary if result is Dictionary else {}


func query_tile_occupants(tile: Vector2i) -> Array[String]:
	if _model == null or not _model.has_method("query_tile_occupants"):
		return []
	var raw: Variant = _model.call("query_tile_occupants", tile)
	var result: Array[String] = []
	if raw is Array:
		for value: Variant in raw:
			result.append(str(value))
	return result


func query_entities_in_rect(rect: Rect2i) -> Array[String]:
	if _model == null or not _model.has_method("query_entities_in_rect"):
		return []
	var raw: Variant = _model.call("query_entities_in_rect", rect)
	var result: Array[String] = []
	if raw is Array:
		for value: Variant in raw:
			result.append(str(value))
	return result


func is_tile_occupied(tile: Vector2i, ignore_entity_id: String = "") -> bool:
	for entity_id: String in query_tile_occupants(tile):
		if ignore_entity_id.is_empty() or entity_id != ignore_entity_id:
			return true
	return false
