extends RefCounted
class_name GeneratedAreaPlan

var area_id: String = ""
var seed: int = 0
var bounds: Rect2i = Rect2i()
var area_profile_id: StringName = &""
var area_profile_version: int = 0
var environment_profile_id: StringName = &""
var environment_profile_version: int = 0
var reservations: Array[Dictionary] = []
var roads: Array[Dictionary] = []
var intersections: Array[Dictionary] = []
var blocks: Array[Dictionary] = []
var parcels: Array[Dictionary] = []
var building_requests: Array[BuildingGenerationRequest] = []
var hydrology_features: Array[Dictionary] = []
var ground_regions: Array[Dictionary] = []
var outdoor_props: Array[Dictionary] = []
var failure_reason: String = ""

func is_generated() -> bool:
    return failure_reason.is_empty() \
        and not area_id.is_empty() \
        and bounds.size.x > 0 and bounds.size.y > 0 \
        and area_profile_version > 0 and environment_profile_version > 0

func signature() -> String:
    if not is_generated():
        return "FAILED:%s" % failure_reason
    var parts := PackedStringArray()
    parts.append("area=%s" % area_id)
    parts.append("seed=%d" % seed)
    parts.append("bounds=%d,%d,%d,%d" % [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y])
    parts.append("profile=%s@%d" % [String(area_profile_id), area_profile_version])
    parts.append("environment=%s@%d" % [String(environment_profile_id), environment_profile_version])
    for reservation: Dictionary in reservations:
        parts.append(_reservation_signature(reservation))
    for road: Dictionary in roads:
        parts.append(_road_signature(road))
    for intersection: Dictionary in intersections:
        parts.append(_intersection_signature(intersection))
    for block: Dictionary in blocks:
        parts.append(_block_signature(block))
    for parcel: Dictionary in parcels:
        parts.append(_parcel_signature(parcel))
    for request: BuildingGenerationRequest in building_requests:
        parts.append("building=%s|%s|%d|%d,%d,%d,%d|%d|%d" % [
            request.instance_id,
            String(request.archetype_id),
            request.seed,
            request.envelope.position.x,
            request.envelope.position.y,
            request.envelope.size.x,
            request.envelope.size.y,
            request.orientation,
            request.frontage_side,
        ])
    for feature: Dictionary in hydrology_features:
        parts.append(_hydrology_signature(feature))
    for region: Dictionary in ground_regions:
        parts.append(_ground_signature(region))
    for prop: Dictionary in outdoor_props:
        var cell: Vector2i = prop.get("cell", Vector2i.ZERO)
        parts.append("prop=%s|%s|%d,%d|%d" % [
            String(prop.get("id", "")),
            String(prop.get("semantic", &"")),
            cell.x,
            cell.y,
            int(prop.get("facing", 0)),
        ])
    return "\n".join(parts)

func _reservation_signature(reservation: Dictionary) -> String:
    var rect: Rect2i = reservation.get("rect", Rect2i())
    return "reservation=%s|%s|%s|%s|%s|%d,%d,%d,%d|p%d|r%d" % [
        String(reservation.get("id", "")),
        String(reservation.get("source_id", "")),
        String(reservation.get("domain", &"")),
        String(reservation.get("kind", &"")),
        String(reservation.get("reservation_role", &"")),
        rect.position.x, rect.position.y, rect.size.x, rect.size.y,
        1 if bool(reservation.get("blocks_parcels", false)) else 0,
        1 if bool(reservation.get("blocks_local_roads", false)) else 0,
    ]

func _road_signature(road: Dictionary) -> String:
    var start: Vector2i = road.get("start", Vector2i.ZERO)
    var finish: Vector2i = road.get("end", Vector2i.ZERO)
    return "road=%s|%s|%d,%d>%d,%d|w%d|%s" % [
        String(road.get("road_id", "")),
        String(road.get("road_class", &"")),
        start.x, start.y, finish.x, finish.y,
        int(road.get("width", 0)),
        "I" if bool(road.get("inherited", false)) else "L",
    ]

func _intersection_signature(intersection: Dictionary) -> String:
    var cell: Vector2i = intersection.get("cell", Vector2i.ZERO)
    var road_ids: Array = intersection.get("road_ids", [])
    var names := PackedStringArray()
    for value: Variant in road_ids:
        names.append(String(value))
    names.sort()
    return "intersection=%s|%d,%d|%s|%s" % [
        String(intersection.get("id", "")),
        cell.x, cell.y,
        String(intersection.get("control", &"")),
        ",".join(names),
    ]

func _block_signature(block: Dictionary) -> String:
    var rect: Rect2i = block.get("rect", Rect2i())
    return "block=%s|%s|%d,%d,%d,%d" % [
        String(block.get("id", "")),
        String(block.get("kind", &"")),
        rect.position.x, rect.position.y, rect.size.x, rect.size.y,
    ]

func _parcel_signature(parcel: Dictionary) -> String:
    var rect: Rect2i = parcel.get("rect", Rect2i())
    var access: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
    var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
    return "parcel=%s|%s|%s|%d,%d,%d,%d|a%d,%d|b%s@%d,%d,%d,%d" % [
        String(parcel.get("id", "")),
        String(parcel.get("land_use", &"")),
        String(parcel.get("frontage_road_id", "")),
        rect.position.x, rect.position.y, rect.size.x, rect.size.y,
        access.x, access.y,
        String(parcel.get("building_archetype_id", &"")),
        envelope.position.x, envelope.position.y, envelope.size.x, envelope.size.y,
    ]

func _hydrology_signature(feature: Dictionary) -> String:
    var kind: StringName = StringName(feature.get("kind", &""))
    if kind == &"river_segment":
        var start: Vector2i = feature.get("start", Vector2i.ZERO)
        var finish: Vector2i = feature.get("end", Vector2i.ZERO)
        var corridor: Rect2i = feature.get("corridor_rect", Rect2i())
        return "hydrology=river|%s|%s|%d,%d>%d,%d|w%d|o%d|r%d,%d,%d,%d" % [
            String(feature.get("segment_id", "")),
            String(feature.get("river_id", "")),
            start.x, start.y, finish.x, finish.y,
            int(feature.get("width", 0)),
            int(feature.get("ordinal", 0)),
            corridor.position.x, corridor.position.y, corridor.size.x, corridor.size.y,
        ]
    if kind == &"bridge_intent":
        var cell: Vector2i = feature.get("cell", Vector2i.ZERO)
        var deck: Rect2i = feature.get("deck_rect", Rect2i())
        return "hydrology=bridge|%s|%s|%s|%s|%s|%d,%d|%s|rw%d|ww%d|r%d,%d,%d,%d" % [
            String(feature.get("id", "")),
            String(feature.get("road_id", "")),
            String(feature.get("route_id", "")),
            String(feature.get("river_id", "")),
            String(feature.get("river_segment_id", "")),
            cell.x, cell.y,
            String(feature.get("bridge_axis", &"")),
            int(feature.get("road_width", 0)),
            int(feature.get("river_width", 0)),
            deck.position.x, deck.position.y, deck.size.x, deck.size.y,
        ]
    return "hydrology=unknown|%s" % String(kind)

func _ground_signature(region: Dictionary) -> String:
    if region.has("rect"):
        var rect: Rect2i = region.get("rect", Rect2i())
        return "ground=%s|%s|rect:%d,%d,%d,%d|p%d" % [
            String(region.get("id", "")),
            String(region.get("semantic", &"")),
            rect.position.x, rect.position.y, rect.size.x, rect.size.y,
            int(region.get("priority", 0)),
        ]
    var cells: Array = region.get("cells", [])
    var encoded := PackedStringArray()
    for value: Variant in cells:
        var cell: Vector2i = value
        encoded.append("%d,%d" % [cell.x, cell.y])
    return "ground=%s|%s|cells:%s|p%d" % [
        String(region.get("id", "")),
        String(region.get("semantic", &"")),
        ";".join(encoded),
        int(region.get("priority", 0)),
    ]
