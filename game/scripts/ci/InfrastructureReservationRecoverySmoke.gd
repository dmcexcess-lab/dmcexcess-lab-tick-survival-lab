extends SceneTree

const PlannerClass = preload("res://scripts/generation/areas/InfrastructureReservationPlanner.gd")
const RequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")

func _initialize() -> void:
    var bounds := Rect2i(Vector2i.ZERO, Vector2i(128, 128))
    var road := {"road_id":"road.edge", "start":Vector2i(0, 8), "end":Vector2i(127, 8), "width":5}
    var constraint := {"id":"constraint.power.edge", "source_id":"node.edge", "domain":&"power", "kind":&"substation", "reservation_role":&"facility", "cell":Vector2i(2, 8), "blocks_parcels":true, "blocks_local_roads":true}
    var request = RequestClass.new("area.smalltown.edge", 99173, bounds, &"smalltown.center", &"temperate.rural", [road], [], [constraint])
    var profile := {"reservation_substation_size":Vector2i(14, 12), "reservation_road_gap":2}
    var result: Dictionary = PlannerClass.new().plan(request, profile, [road])
    if not bool(result.get("ok", false)):
        push_error("INFRASTRUCTURE_RESERVATION_RECOVERY_FAIL: %s" % String(result.get("failure_reason", "unknown")))
        quit(1)
        return
    var reservations: Array = result.get("reservations", [])
    if reservations.size() != 1:
        push_error("INFRASTRUCTURE_RESERVATION_RECOVERY_FAIL: reservation_count=%d" % reservations.size())
        quit(1)
        return
    var rect: Rect2i = reservations[0].get("rect", Rect2i())
    if not bounds.encloses(rect) or rect.size != Vector2i(14, 12):
        push_error("INFRASTRUCTURE_RESERVATION_RECOVERY_FAIL: illegal_rect=%s" % rect)
        quit(1)
        return
    print("INFRASTRUCTURE_RESERVATION_RECOVERY_OK rect=%s source=%s" % [rect, constraint.cell])
    quit(0)
