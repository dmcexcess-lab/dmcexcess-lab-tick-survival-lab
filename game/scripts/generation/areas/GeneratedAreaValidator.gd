extends RefCounted
class_name GeneratedAreaValidator

const BuildingGeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BuildingValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")

var _building_generator: LocalBuildingGenerator
var _building_validator: GeneratedBuildingValidator

func _init() -> void:
    _building_generator = BuildingGeneratorClass.new()
    _building_validator = BuildingValidatorClass.new()

func validate(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> Dictionary:
    var failures: Array[String] = []
    if request == null or not request.is_valid() or plan == null or not plan.is_generated():
        return {"ok": false, "failures": ["invalid_area_plan_input"]}
    if plan.area_id != request.area_id or plan.seed != request.seed or plan.bounds != request.bounds:
        failures.append("area_provenance_mismatch")

    var ids: Dictionary = {}
    _validate_reservations(request, plan.reservations, ids, failures)

    var road_cells: Dictionary = {}
    var road_by_id: Dictionary = {}
    for road: Dictionary in plan.roads:
        _claim_id(ids, String(road.get("road_id", "")), failures)
        road_by_id[String(road.get("road_id", ""))] = road
        for value: Variant in road.get("corridor_cells", []):
            var cell: Vector2i = value
            if not request.bounds.has_point(cell):
                failures.append("road_out_of_bounds")
            road_cells[cell] = true
            if not bool(road.get("inherited", false)) and _cell_in_local_road_blocking_reservation(cell, plan.reservations):
                failures.append("local_road_overlaps_blocking_reservation")
        _validate_road_boundary(request, road, failures)

    for intersection: Dictionary in plan.intersections:
        _claim_id(ids, String(intersection.get("id", "")), failures)
        var cell: Vector2i = intersection.get("cell", Vector2i(-1, -1))
        if not request.bounds.has_point(cell):
            failures.append("intersection_out_of_bounds")
        for road_id_value: Variant in intersection.get("road_ids", []):
            if not road_by_id.has(String(road_id_value)):
                failures.append("intersection_road_missing")

    _validate_blocks(request, plan.blocks, plan.roads, plan.reservations, ids, failures)

    for first_index in range(plan.parcels.size()):
        var parcel: Dictionary = plan.parcels[first_index]
        _claim_id(ids, String(parcel.get("id", "")), failures)
        var rect: Rect2i = parcel.get("rect", Rect2i())
        if not _rect_inside(request.bounds, rect):
            failures.append("parcel_out_of_bounds")
        if not road_by_id.has(String(parcel.get("frontage_road_id", ""))):
            failures.append("parcel_frontage_missing")
        for value: Variant in road_cells.keys():
            if rect.has_point(value):
                failures.append("parcel_overlaps_road")
                break
        if _rect_intersects_parcel_blocking_reservation(rect, plan.reservations):
            failures.append("parcel_overlaps_infrastructure_reservation")
        for second_index in range(first_index + 1, plan.parcels.size()):
            if _rects_intersect(rect, plan.parcels[second_index].get("rect", Rect2i())):
                failures.append("parcel_overlap")
        _validate_parcel_access(request, parcel, failures)
        var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
        if envelope.size.x > 0:
            if not _rect_inside(parcel.get("buildable_rect", Rect2i()), envelope):
                failures.append("building_outside_buildable_region")
            if _rect_intersects_parcel_blocking_reservation(envelope, plan.reservations):
                failures.append("building_overlaps_infrastructure_reservation")
        var field_rect: Rect2i = parcel.get("field_rect", Rect2i())
        if field_rect.size.x > 0 and not _rect_inside(rect, field_rect):
            failures.append("field_outside_parcel")

    var building_ids: Dictionary = {}
    for building_request: BuildingGenerationRequest in plan.building_requests:
        _claim_id(ids, building_request.instance_id, failures)
        building_ids[building_request.instance_id] = true
        if _rect_intersects_parcel_blocking_reservation(building_request.envelope, plan.reservations):
            failures.append("building_request_overlaps_infrastructure_reservation")
        var subplan: GeneratedBuildingPlan = _building_generator.generate(building_request)
        if not subplan.is_generated():
            failures.append("system19_building_generation_failed")
            continue
        if not bool(_building_validator.validate(subplan).get("ok", false)):
            failures.append("system19_building_validation_failed")
    for parcel: Dictionary in plan.parcels:
        var building_id: String = String(parcel.get("building_instance_id", ""))
        if not building_id.is_empty() and not building_ids.has(building_id):
            failures.append("parcel_building_request_missing")

    var access_cells: Dictionary = {}
    for parcel: Dictionary in plan.parcels:
        for value: Variant in parcel.get("driveway_cells", []):
            access_cells[value] = true
        for value: Variant in parcel.get("parking_cells", []):
            access_cells[value] = true
    for prop: Dictionary in plan.outdoor_props:
        _claim_id(ids, String(prop.get("id", "")), failures)
        var cell: Vector2i = prop.get("cell", Vector2i(-1, -1))
        if not request.bounds.has_point(cell):
            failures.append("outdoor_prop_out_of_bounds")
        if road_cells.has(cell) or access_cells.has(cell):
            failures.append("outdoor_prop_blocks_access")
        if _cell_in_any_reservation(cell, plan.reservations):
            failures.append("outdoor_prop_overlaps_infrastructure_reservation")
        for parcel: Dictionary in plan.parcels:
            var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
            if envelope.size.x > 0 and envelope.has_point(cell):
                failures.append("outdoor_prop_overlaps_building_envelope")
                break

    for region: Dictionary in plan.ground_regions:
        _claim_id(ids, String(region.get("id", "")), failures)
        if region.has("rect"):
            if not _rect_inside(request.bounds, region.get("rect", Rect2i())):
                failures.append("ground_region_out_of_bounds")
        else:
            for value: Variant in region.get("cells", []):
                if not request.bounds.has_point(value):
                    failures.append("ground_cell_out_of_bounds")
                    break

    return {"ok": failures.is_empty(), "failures": failures}

func _validate_reservations(
    request: AreaGenerationRequest,
    reservations: Array[Dictionary],
    ids: Dictionary,
    failures: Array[String]
) -> void:
    for first_index in range(reservations.size()):
        var reservation: Dictionary = reservations[first_index]
        _claim_id(ids, String(reservation.get("id", "")), failures)
        if String(reservation.get("source_id", "")).strip_edges().is_empty():
            failures.append("reservation_source_missing")
        var role: StringName = StringName(reservation.get("reservation_role", &""))
        if role != &"facility" and role != &"corridor":
            failures.append("reservation_role_invalid")
        var rect: Rect2i = reservation.get("rect", Rect2i())
        if not _rect_inside(request.bounds, rect):
            failures.append("reservation_out_of_bounds")
        if not bool(reservation.get("blocks_parcels", false)):
            failures.append("reservation_does_not_block_parcels")
        for second_index in range(first_index + 1, reservations.size()):
            var other: Dictionary = reservations[second_index]
            var other_rect: Rect2i = other.get("rect", Rect2i())
            if not _rects_intersect(rect, other_rect):
                continue
            var other_role: StringName = StringName(other.get("reservation_role", &""))
            if role == &"facility" and (other_role == &"facility" or bool(other.get("blocks_local_roads", false))):
                failures.append("facility_reservation_overlap")
            elif other_role == &"facility" and bool(reservation.get("blocks_local_roads", false)):
                failures.append("facility_reservation_overlap")

func _validate_blocks(
    request: AreaGenerationRequest,
    blocks: Array[Dictionary],
    roads: Array[Dictionary],
    reservations: Array[Dictionary],
    ids: Dictionary,
    failures: Array[String]
) -> void:
    for first_index in range(blocks.size()):
        var block: Dictionary = blocks[first_index]
        _claim_id(ids, String(block.get("id", "")), failures)
        if StringName(block.get("kind", &"")) != &"town_block":
            failures.append("town_block_kind_invalid")
        var rect: Rect2i = block.get("rect", Rect2i())
        if not _rect_inside(request.bounds, rect):
            failures.append("town_block_out_of_bounds")
        if _rect_intersects_parcel_blocking_reservation(rect, reservations):
            failures.append("town_block_overlaps_infrastructure_reservation")
        if _rect_contains_road_cell(rect, roads):
            failures.append("town_block_overlaps_road")
        for second_index in range(first_index + 1, blocks.size()):
            if _rects_intersect(rect, blocks[second_index].get("rect", Rect2i())):
                failures.append("town_block_overlap")

func _validate_road_boundary(request: AreaGenerationRequest, road: Dictionary, failures: Array[String]) -> void:
    var allowed: Array = road.get("allowed_boundary_cells", [])
    for value: Variant in road.get("path_cells", []):
        var cell: Vector2i = value
        if not AreaGenerationRequest._is_boundary_cell(request.bounds, cell):
            continue
        if not allowed.has(cell):
            failures.append("unauthorized_road_boundary_exit")
    if bool(road.get("inherited", false)):
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        if not allowed.has(start) or not allowed.has(finish):
            failures.append("inherited_road_boundary_constraint_lost")

func _validate_parcel_access(request: AreaGenerationRequest, parcel: Dictionary, failures: Array[String]) -> void:
    var building_id: String = String(parcel.get("building_instance_id", ""))
    if building_id.is_empty():
        return
    var access: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
    var entry: Vector2i = parcel.get("building_entry_cell", Vector2i(-1, -1))
    var driveway: Array = parcel.get("driveway_cells", [])
    if access.x < 0 or entry.x < 0 or driveway.is_empty():
        failures.append("occupied_parcel_access_missing")
        return
    if driveway.front() != access or driveway.back() != entry:
        failures.append("driveway_endpoint_mismatch")
    for value: Variant in driveway:
        if not request.bounds.has_point(value):
            failures.append("driveway_out_of_bounds")
            return
    for value: Variant in parcel.get("parking_cells", []):
        if typeof(value) != TYPE_VECTOR2I or not request.bounds.has_point(value):
            failures.append("parking_apron_out_of_bounds")
            return

func _cell_in_local_road_blocking_reservation(cell: Vector2i, reservations: Array[Dictionary]) -> bool:
    for reservation: Dictionary in reservations:
        if not bool(reservation.get("blocks_local_roads", false)):
            continue
        if reservation.get("rect", Rect2i()).has_point(cell):
            return true
    return false

func _rect_intersects_parcel_blocking_reservation(rect: Rect2i, reservations: Array[Dictionary]) -> bool:
    if rect.size.x <= 0 or rect.size.y <= 0:
        return false
    for reservation: Dictionary in reservations:
        if not bool(reservation.get("blocks_parcels", false)):
            continue
        if _rects_intersect(rect, reservation.get("rect", Rect2i())):
            return true
    return false

func _cell_in_any_reservation(cell: Vector2i, reservations: Array[Dictionary]) -> bool:
    for reservation: Dictionary in reservations:
        if reservation.get("rect", Rect2i()).has_point(cell):
            return true
    return false

func _rect_contains_road_cell(rect: Rect2i, roads: Array[Dictionary]) -> bool:
    for road: Dictionary in roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I and rect.has_point(value):
                return true
    return false

func _claim_id(ids: Dictionary, value: String, failures: Array[String]) -> void:
    if value.strip_edges().is_empty():
        failures.append("empty_stable_id")
        return
    if ids.has(value):
        failures.append("duplicate_stable_id")
        return
    ids[value] = true

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y
