extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

const SMALLTOWN_SITE_ID: String = "area.smalltown.center.001"

var failures: Array[String] = []

func _initialize() -> void:
    var global_planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = GeneratorClass.new()
    var validator: GeneratedAreaValidator = ValidatorClass.new()

    var global_plan: GeneratedGlobalWorldPlan = global_planner.generate(GlobalFixtureClass.request())
    _check(global_plan.is_generated(), "canonical v6 global plan generates before small-town projection")
    if not global_plan.is_generated():
        push_error("SMALLTOWN_GLOBAL_FAILURE: %s" % global_plan.failure_reason)
        _finish()
        return

    var projected: Dictionary = projector.project_site(global_plan, SMALLTOWN_SITE_ID)
    _check(bool(projected.get("ok", false)), "smalltown.center projects from real System 00D facts")
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    _check(request != null and request.is_valid(), "projected small-town AreaGenerationRequest is valid")
    if request == null or not request.is_valid():
        push_error("SMALLTOWN_PROJECTION_FAILURE: %s" % String(projected.get("failure_reason", "unknown")))
        _finish()
        return

    _check(request.area_profile_id == &"smalltown.center", "projected area profile is smalltown.center")
    _check(request.environment_profile_id == &"temperate.rural", "small town reuses temperate.rural environment")
    _check(not request.inherited_planning_constraints.is_empty(), "small town receives normalized global infrastructure constraints")
    _check(_constraint_count(request, &"power", &"facility") >= 1, "small-town request carries a power facility constraint")
    _check(_constraint_count(request, &"potable_water", &"facility") >= 2, "small-town request carries potable-water facility constraints")
    _check(_constraint_count(request, &"wastewater", &"facility") >= 1, "small-town request carries wastewater facility constraint")

    var plan: GeneratedAreaPlan = generator.generate(request)
    _check(plan.is_generated(), "Small-Town Center Candidate 001 generates")
    if not plan.is_generated():
        push_error("SMALLTOWN_PLAN_FAILURE: %s" % plan.failure_reason)
        _finish()
        return
    _test_candidate(request, plan, validator)
    _test_replay_and_seed_variation(request, generator)
    _finish()

func _test_candidate(
    request: AreaGenerationRequest,
    plan: GeneratedAreaPlan,
    validator: GeneratedAreaValidator
) -> void:
    _check(bool(validator.validate(request, plan).get("ok", false)), "Candidate 001 passes generic System 20 validation")
    _check(plan.area_profile_version == 2, "smalltown.center v2 is recorded")
    _check(plan.environment_profile_version == 3, "temperate.rural v3 remains the environment profile")
    _check(plan.bounds.size == Vector2i(256, 256), "small-town site remains 256x256")

    _check(_count_inherited_roads(plan) == request.inherited_roads.size(), "all projected inherited regional roads are preserved")
    _check(_inherited_road_contract_is_exact(request, plan), "inherited road IDs/classes/geometry remain exact")
    _check(_count_road_class(plan, &"local_town") == 4, "Candidate 001 creates four connected local-town streets")
    _check(_local_town_roads_stay_internal(plan), "local-town streets create no unauthorized boundary exits")
    _check(_all_roads_connected(plan), "regional and local-town streets form one connected road graph")
    _check(_count_intersection_control(plan, &"signalized") == 0, "Candidate 001 invents no traffic signal")

    _check(plan.blocks.size() >= 2, "Candidate 001 records semantic town blocks")
    _check(_blocks_are_legal(plan), "town blocks stay off roads and infrastructure reservations")

    _check(_count_land_use(plan, &"commercial_small") == 3, "Candidate 001 has three small-commercial opportunities on compact island topology")
    _check(_count_land_use(plan, &"residential") == 10, "Candidate 001 has ten residential opportunities")
    _check(_count_land_use(plan, &"farmstead") == 0, "town center has no farmstead target")
    _check(plan.building_requests.size() == 12, "existing library occupies two commercial and ten residential parcels")
    _check(_count_building_archetype(plan, &"commercial.gas_station.small") == 1, "existing gas station is used once")
    _check(_count_building_archetype(plan, &"commercial.diner.rural_small") == 1, "existing diner is used once")
    _check(_commercial_without_building(plan) == 1, "one commercial opportunity remains honestly vacant")
    _check(_count_land_use_on_road_class(plan, &"residential", &"local_town") >= 6, "a majority target of homes uses local-town frontage")
    _check(_all_occupied_approaches_align_to_primary_doors(plan), "occupied town parcels reach their real System 19 primary doors directly")

    _check(_count_reservation(plan, &"power", &"substation", &"facility") == 1, "one substation land reservation exists")
    _check(_count_reservation(plan, &"potable_water", &"groundwater_source", &"facility") == 1, "one groundwater-source land reservation exists")
    _check(_count_reservation(plan, &"potable_water", &"treatment_storage", &"facility") == 1, "one water treatment/storage land reservation exists")
    _check(_count_reservation(plan, &"wastewater", &"treatment_disposal", &"facility") == 1, "one wastewater treatment/disposal land reservation exists")
    _check(_facility_reservations_are_distinct(plan), "utility facility reservations are physically distinct")
    _check(_ordinary_properties_avoid_reservations(plan), "ordinary parcels and buildings never occupy blocking infrastructure land")
    _check(_local_roads_avoid_blocking_reservations(plan), "local streets honor facility/hydrology road exclusions")
    _check(_outdoor_props_avoid_reservations(plan), "random outdoor props stay out of reserved infrastructure land")

func _test_replay_and_seed_variation(request: AreaGenerationRequest, generator: LocalAreaGenerator) -> void:
    var replay: GeneratedAreaPlan = generator.generate(_copy_request_with_seed(request, request.seed))
    var original: GeneratedAreaPlan = generator.generate(_copy_request_with_seed(request, request.seed))
    _check(replay.is_generated() and original.is_generated() and replay.signature() == original.signature(), "same small-town request/seed replays exactly")

    var changed: bool = false
    for offset in range(1, 6):
        var alternate_request: AreaGenerationRequest = _copy_request_with_seed(request, request.seed + offset)
        var alternate: GeneratedAreaPlan = generator.generate(alternate_request)
        _check(alternate.is_generated(), "smalltown.center alternate seed %d generates without reroll loops" % alternate_request.seed)
        if alternate.is_generated() and original.is_generated() and alternate.signature() != original.signature():
            changed = true
    _check(changed, "alternate legal small-town seeds produce deterministic morphology/content variation")

func _copy_request_with_seed(request: AreaGenerationRequest, seed: int) -> AreaGenerationRequest:
    return AreaRequestClass.new(
        request.area_id,
        seed,
        request.bounds,
        request.area_profile_id,
        request.environment_profile_id,
        request.inherited_roads,
        request.forbidden_regions,
        request.inherited_planning_constraints
    )

func _constraint_count(request: AreaGenerationRequest, domain: StringName, role: StringName) -> int:
    var count: int = 0
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("domain", &"")) == domain and StringName(constraint.get("reservation_role", &"")) == role:
            count += 1
    return count

func _count_inherited_roads(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for road: Dictionary in plan.roads:
        if bool(road.get("inherited", false)):
            count += 1
    return count

func _inherited_road_contract_is_exact(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> bool:
    for expected: Dictionary in request.inherited_roads:
        var found: Dictionary = {}
        for road: Dictionary in plan.roads:
            if bool(road.get("inherited", false)) and String(road.get("road_id", "")) == String(expected.get("road_id", "")):
                found = road
                break
        if found.is_empty():
            return false
        if StringName(found.get("road_class", &"")) != StringName(expected.get("road_class", &"")):
            return false
        if found.get("start", Vector2i.ZERO) != expected.get("start", Vector2i.ZERO) or found.get("end", Vector2i.ZERO) != expected.get("end", Vector2i.ZERO):
            return false
        if int(found.get("width", 0)) != int(expected.get("width", 0)):
            return false
    return true

func _count_road_class(plan: GeneratedAreaPlan, road_class: StringName) -> int:
    var count: int = 0
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) == road_class:
            count += 1
    return count

func _local_town_roads_stay_internal(plan: GeneratedAreaPlan) -> bool:
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) != &"local_town":
            continue
        for value: Variant in road.get("path_cells", []):
            var cell: Vector2i = value
            if _is_boundary_cell(plan.bounds, cell):
                return false
    return true

func _all_roads_connected(plan: GeneratedAreaPlan) -> bool:
    if plan.roads.is_empty():
        return false
    var adjacency: Dictionary = {}
    for road: Dictionary in plan.roads:
        adjacency[String(road.get("road_id", ""))] = []
    for intersection: Dictionary in plan.intersections:
        var ids: Array = intersection.get("road_ids", [])
        if ids.size() != 2:
            continue
        var a: String = String(ids[0])
        var b: String = String(ids[1])
        if not adjacency.has(a) or not adjacency.has(b):
            continue
        var a_neighbors: Array = adjacency[a]
        var b_neighbors: Array = adjacency[b]
        if not a_neighbors.has(b):
            a_neighbors.append(b)
        if not b_neighbors.has(a):
            b_neighbors.append(a)
        adjacency[a] = a_neighbors
        adjacency[b] = b_neighbors
    var start: String = String(plan.roads[0].get("road_id", ""))
    var seen: Dictionary = {start: true}
    var queue: Array[String] = [start]
    var index: int = 0
    while index < queue.size():
        var current: String = queue[index]
        index += 1
        for neighbor_value: Variant in adjacency.get(current, []):
            var neighbor: String = String(neighbor_value)
            if seen.has(neighbor):
                continue
            seen[neighbor] = true
            queue.append(neighbor)
    return seen.size() == plan.roads.size()

func _count_intersection_control(plan: GeneratedAreaPlan, control: StringName) -> int:
    var count: int = 0
    for intersection: Dictionary in plan.intersections:
        if StringName(intersection.get("control", &"")) == control:
            count += 1
    return count

func _blocks_are_legal(plan: GeneratedAreaPlan) -> bool:
    for block: Dictionary in plan.blocks:
        var rect: Rect2i = block.get("rect", Rect2i())
        if not _rect_inside(plan.bounds, rect):
            return false
        for road: Dictionary in plan.roads:
            for value: Variant in road.get("corridor_cells", []):
                if rect.has_point(value):
                    return false
        for reservation: Dictionary in plan.reservations:
            if bool(reservation.get("blocks_parcels", false)) and _rects_intersect(rect, reservation.get("rect", Rect2i())):
                return false
    return true

func _count_land_use(plan: GeneratedAreaPlan, land_use: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == land_use:
            count += 1
    return count

func _count_land_use_on_road_class(plan: GeneratedAreaPlan, land_use: StringName, road_class: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == land_use and StringName(parcel.get("frontage_road_class", &"")) == road_class:
            count += 1
    return count

func _count_building_archetype(plan: GeneratedAreaPlan, archetype: StringName) -> int:
    var count: int = 0
    for request: BuildingGenerationRequest in plan.building_requests:
        if request.archetype_id == archetype:
            count += 1
    return count

func _commercial_without_building(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == &"commercial_small" and String(parcel.get("building_instance_id", "")).is_empty():
            count += 1
    return count

func _all_occupied_approaches_align_to_primary_doors(plan: GeneratedAreaPlan) -> bool:
    for parcel: Dictionary in plan.parcels:
        var building_id: String = String(parcel.get("building_instance_id", ""))
        if building_id.is_empty():
            continue
        var access: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
        var entry: Vector2i = parcel.get("building_entry_cell", Vector2i(-1, -1))
        var frontage: int = int(parcel.get("frontage_side", -1))
        var driveway: Array = parcel.get("driveway_cells", [])
        if access.x < 0 or entry.x < 0 or driveway.is_empty() or not Facing.is_valid(frontage):
            return false
        if driveway[0] != access or driveway[driveway.size() - 1] != entry:
            return false
        if frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH:
            if access.x != entry.x:
                return false
            for value: Variant in driveway:
                if (value as Vector2i).x != access.x:
                    return false
        else:
            if access.y != entry.y:
                return false
            for value: Variant in driveway:
                if (value as Vector2i).y != access.y:
                    return false
    return true

func _count_reservation(plan: GeneratedAreaPlan, domain: StringName, kind: StringName, role: StringName) -> int:
    var count: int = 0
    for reservation: Dictionary in plan.reservations:
        if StringName(reservation.get("domain", &"")) == domain \
            and StringName(reservation.get("kind", &"")) == kind \
            and StringName(reservation.get("reservation_role", &"")) == role:
            count += 1
    return count

func _facility_reservations_are_distinct(plan: GeneratedAreaPlan) -> bool:
    var facilities: Array[Rect2i] = []
    for reservation: Dictionary in plan.reservations:
        if StringName(reservation.get("reservation_role", &"")) == &"facility":
            facilities.append(reservation.get("rect", Rect2i()))
    for first in range(facilities.size()):
        for second in range(first + 1, facilities.size()):
            if _rects_intersect(facilities[first], facilities[second]):
                return false
    return facilities.size() >= 4

func _ordinary_properties_avoid_reservations(plan: GeneratedAreaPlan) -> bool:
    for parcel: Dictionary in plan.parcels:
        var rect: Rect2i = parcel.get("rect", Rect2i())
        var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
        for reservation: Dictionary in plan.reservations:
            if not bool(reservation.get("blocks_parcels", false)):
                continue
            var reserved: Rect2i = reservation.get("rect", Rect2i())
            if _rects_intersect(rect, reserved):
                return false
            if envelope.size.x > 0 and _rects_intersect(envelope, reserved):
                return false
    return true

func _local_roads_avoid_blocking_reservations(plan: GeneratedAreaPlan) -> bool:
    for road: Dictionary in plan.roads:
        if bool(road.get("inherited", false)):
            continue
        for value: Variant in road.get("corridor_cells", []):
            var cell: Vector2i = value
            for reservation: Dictionary in plan.reservations:
                if bool(reservation.get("blocks_local_roads", false)) and reservation.get("rect", Rect2i()).has_point(cell):
                    return false
    return true

func _outdoor_props_avoid_reservations(plan: GeneratedAreaPlan) -> bool:
    for prop: Dictionary in plan.outdoor_props:
        var cell: Vector2i = prop.get("cell", Vector2i(-1, -1))
        for reservation: Dictionary in plan.reservations:
            if reservation.get("rect", Rect2i()).has_point(cell):
                return false
    return true

func _is_boundary_cell(rect: Rect2i, cell: Vector2i) -> bool:
    if not rect.has_point(cell):
        return false
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    return cell.x == rect.position.x or cell.x == max_x or cell.y == rect.position.y or cell.y == max_y

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

func _finish() -> void:
    if failures.is_empty():
        print("SMALLTOWN_CENTER_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("SMALLTOWN_CENTER_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)