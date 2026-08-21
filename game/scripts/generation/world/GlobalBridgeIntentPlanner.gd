extends RefCounted
class_name GlobalBridgeIntentPlanner

const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")

var _hydrology: GlobalHydrologyQuery

func _init() -> void:
    _hydrology = HydrologyQueryClass.new()

func plan(road_segments: Array[Dictionary], river_segments: Array[Dictionary]) -> Dictionary:
    var bridge_intents: Array[Dictionary] = []
    if road_segments.is_empty() or river_segments.is_empty():
        return {"ok": false, "failure_reason": "invalid_bridge_intent_input", "bridge_intents": bridge_intents}

    var crossing_records: Dictionary = {}
    for road: Dictionary in road_segments:
        for river: Dictionary in river_segments:
            if _hydrology.collinear_overlap_length(road, river) > 0:
                return {"ok": false, "failure_reason": "global_road_river_collinear_overlap", "bridge_intents": []}
            var crossing: Vector2i = _hydrology.perpendicular_crossing(road, river)
            if crossing.x < -900000:
                continue
            var route_id: String = String(road.get("route_id", ""))
            var river_id: String = String(river.get("river_id", ""))
            var key: String = "%s|%s|%d,%d" % [route_id, river_id, crossing.x, crossing.y]
            if crossing_records.has(key):
                var existing: Dictionary = crossing_records[key]
                var existing_road_id: String = String(existing.get("road_id", ""))
                var candidate_road_id: String = String(road.get("road_id", ""))
                if candidate_road_id < existing_road_id:
                    crossing_records[key] = _crossing_record(road, river, crossing)
                continue
            crossing_records[key] = _crossing_record(road, river, crossing)

    var keys: Array = crossing_records.keys()
    keys.sort_custom(func(a: Variant, b: Variant) -> bool:
        return String(a) < String(b)
    )
    var ordinal: int = 1
    for key_value: Variant in keys:
        var record: Dictionary = crossing_records[key_value]
        record["id"] = "bridge.intent.%03d" % ordinal
        bridge_intents.append(record)
        ordinal += 1

    if bridge_intents.is_empty():
        return {"ok": false, "failure_reason": "global_bridge_intent_missing", "bridge_intents": []}
    return {"ok": true, "failure_reason": "", "bridge_intents": bridge_intents}

func _crossing_record(road: Dictionary, river: Dictionary, crossing: Vector2i) -> Dictionary:
    var road_start: Vector2i = road.get("start", Vector2i.ZERO)
    var road_end: Vector2i = road.get("end", Vector2i.ZERO)
    var axis: StringName = &"horizontal" if road_start.y == road_end.y else &"vertical"
    return {
        "id": "",
        "road_id": String(road.get("road_id", "")),
        "route_id": String(road.get("route_id", "")),
        "river_id": String(river.get("river_id", "")),
        "river_segment_id": String(river.get("segment_id", "")),
        "cell": crossing,
        "bridge_axis": axis,
        "road_width": int(road.get("width", 0)),
        "river_width": int(river.get("width", 0)),
    }
