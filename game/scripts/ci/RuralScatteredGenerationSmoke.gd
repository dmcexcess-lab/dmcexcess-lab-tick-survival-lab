extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const AreaProfileCatalogClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const RoadPlannerClass = preload("res://scripts/generation/areas/LocalRoadPlanner.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

const HAMLET_SITE_IDS: Array[String] = [
    "area.rural.scattered.001",
    "area.rural.scattered.002",
    "area.rural.scattered.003",
]

const ALLOWED_RESIDENTIAL_ARCHETYPES: Array[StringName] = [
    &"residential.trailer.singlewide",
    &"residential.house.farm_small",
    &"residential.house.farm_large",
    &"residential.house.compact_laundry",
]

var failures: Array[String] = []

func _initialize() -> void:
    var global_planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = GeneratorClass.new()
    var validator: GeneratedAreaValidator = ValidatorClass.new()
    var global_plan: GeneratedGlobalWorldPlan = global_planner.generate(GlobalFixtureClass.request())

    _check(global_plan.is_generated() and global_plan.profile_version == 7, "canonical System 00D v7 world generates before hamlet projection")
    if not global_plan.is_generated():
        push_error("RURAL_SCATTERED_GLOBAL_FAILURE: %s" % global_plan.failure_reason)
        _finish()
        return

    for site_id: String in HAMLET_SITE_IDS:
        _test_canonical_site(site_id, global_plan, projector, generator, validator)
    _test_orientation_contract()
    _finish()

func _test_canonical_site(
    site_id: String,
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    generator: LocalAreaGenerator,
    validator: GeneratedAreaValidator
) -> void:
    var projected: Dictionary = projector.project_site(global_plan, site_id)
    _check(bool(projected.get("ok", false)), "%s projects from real System 00D facts" % site_id)
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    _check(request != null and request.is_valid(), "%s projected request is valid" % site_id)
    if request == null or not request.is_valid():
        push_error("RURAL_SCATTERED_PROJECTION_FAILURE %s: %s" % [site_id, String(projected.get("failure_reason", "unknown"))])
        return

    _check(request.area_profile_id == &"rural.scattered", "%s selects rural.scattered" % site_id)
    _check(request.environment_profile_id == &"temperate.rural", "%s keeps temperate.rural environment" % site_id)
    _check(_request_inherited_roads_match_projection(request, projector, global_plan), "%s preserves exact inherited regional road projection" % site_id)
    _check(_constraint_count(request, &"power", &"corridor") >= 1, "%s receives regional power feeder corridor facts" % site_id)
    _check(_constraint_count(request, &"power", &"service") == 1, "%s receives exactly one electrical settlement-service fact" % site_id)
    _check(_constraint_count(request, &"power", &"facility") == 0, "%s invents no rural electrical facility" % site_id)
    _check(_water_service_constraint_valid(request), "%s carries exactly one island-wide municipal water service fact" % site_id)
    _check(_constraint_count(request, &"potable_water", &"facility") == 0, "%s invents no local municipal-water facility" % site_id)
    _check(_constraint_count(request, &"potable_water", &"corridor") == 0, "%s invents no long-distance municipal-water corridor" % site_id)
    _check(_constraint_domain_count(request, &"wastewater") == 0, "%s carries no retired wastewater planning constraints" % site_id)

    var plan: GeneratedAreaPlan = generator.generate(request)
    _check(plan.is_generated(), "%s Rural-Scattered Candidate 001 generates" % site_id)
    if not plan.is_generated():
        push_error("RURAL_SCATTERED_PLAN_FAILURE %s: %s" % [site_id, plan.failure_reason])
        return

    _check(bool(validator.validate(request, plan).get("ok", false)), "%s passes generic System 20 validation" % site_id)
    _check(plan.area_profile_version == 2, "%s records rural.scattered v2" % site_id)
    _check(plan.environment_profile_version == 3, "%s records temperate.rural v3" % site_id)
    _check(plan.bounds.size == Vector2i(256, 256), "%s remains a 256x256 logical local planning area" % site_id)
    _check(_inherited_road_contract_is_exact(request, plan), "%s generated plan keeps inherited IDs/classes/geometry exact" % site_id)

    _check(_count_road_class(plan, &"local_rural") == 2, "%s creates exactly two local rural lanes" % site_id)
    _check(_local_lanes_have_candidate_contract(plan), "%s lanes are internal three-cell gravel frontage roads" % site_id)
    _check(_all_local_lanes_connect_to_inherited(plan), "%s local lanes connect to inherited regional road truth" % site_id)
    _check(_count_intersection_control(plan, &"signalized") == 0, "%s invents no traffic signal" % site_id)
    _check(_count_intersection_control(plan, &"uncontrolled") >= 2, "%s records ordinary uncontrolled lane junctions" % site_id)
    _check(plan.blocks.is_empty(), "%s creates no semantic town blocks" % site_id)

    _check(_count_land_use(plan, &"commercial_small") == 0, "%s has zero fake commercial opportunities" % site_id)
    _check(_count_land_use(plan, &"residential") == 4, "%s has four residential opportunities" % site_id)
    _check(_count_land_use(plan, &"farmstead") == 2, "%s has two farmstead opportunities" % site_id)
    _check(plan.building_requests.size() == 6, "%s materializable plan contains six existing-library homes/farmhouses" % site_id)
    _check(_occupied_on_road_class(plan, &"local_rural") >= 4, "%s keeps at least four of six occupied properties on local lanes" % site_id)
    _check(_count_land_use_on_road_class(plan, &"residential", &"local_rural") >= 3, "%s keeps at least three homes on local lanes" % site_id)
    _check(_count_land_use_on_road_class(plan, &"farmstead", &"local_rural") >= 1, "%s keeps at least one farmstead on a local lane" % site_id)
    _check(_only_approved_residential_buildings(plan), "%s uses no commercial or unapproved building archetype" % site_id)
    _check(_all_occupied_approaches_align_to_primary_doors(plan), "%s approaches terminate directly at real System 19 primary doors" % site_id)

    _check(_facility_reservation_count(plan) == 0, "%s carries no local utility facility reservations" % site_id)
    _check(_ordinary_properties_avoid_reservations(plan), "%s ordinary parcels/buildings avoid blocking upstream corridors and facilities" % site_id)
    _check(_unbuilt_nonroad_ratio(plan) >= 0.72, "%s keeps at least 72 percent of non-road area physically unbuilt" % site_id)
    _check(_natural_prop_count(plan) >= 60, "%s preserves substantial open-land natural dressing" % site_id)
    _check(_natural_coarse_bin_coverage(plan) >= 7, "%s natural dressing reaches broad portions of the site" % site_id)
    _check(_natural_xy_correlation_abs(plan) <= 0.70, "%s natural dressing does not collapse into a diagonal" % site_id)

    var replay: GeneratedAreaPlan = generator.generate(_copy_request_with_seed(request, request.seed))
    _check(replay.is_generated() and replay.signature() == plan.signature(), "%s same request/seed replays exactly" % site_id)

    var changed: bool = false
    for offset in range(1, 5):
        var alternate_request: AreaGenerationRequest = _copy_request_with_seed(request, request.seed + offset)
        var alternate: GeneratedAreaPlan = generator.generate(alternate_request)
        _check(alternate.is_generated(), "%s alternate local seed %d generates without reroll loops" % [site_id, alternate_request.seed])
        if alternate.is_generated():
            _check(_count_road_class(alternate, &"local_rural") == 2, "%s alternate seed %d keeps two local lanes" % [site_id, alternate_request.seed])
            _check(_count_land_use(alternate, &"residential") == 4 and _count_land_use(alternate, &"farmstead") == 2, "%s alternate seed %d keeps occupancy targets" % [site_id, alternate_request.seed])
            _check(_occupied_on_road_class(alternate, &"local_rural") >= 4, "%s alternate seed %d keeps local-lane majority" % [site_id, alternate_request.seed])
            if alternate.signature() != plan.signature():
                changed = true
    _check(changed, "%s alternate legal local seeds produce deterministic variation" % site_id)

func _test_orientation_contract() -> void:
    var profiles: AreaProfileCatalog = AreaProfileCatalogClass.new()
    var profile: Dictionary = profiles.profile(&"rural.scattered")
    var road_planner: LocalRoadPlanner = RoadPlannerClass.new()
    _check(not profile.is_empty(), "rural.scattered profile is available to direct road contract test")

    var bounds := Rect2i(0, 0, 256, 256)
    var horizontal_road := {
        "road_id": "road.test.hamlet.horizontal",
        "road_class": &"secondary",
        "start": Vector2i(0, 128),
        "end": Vector2i(255, 128),
        "width": 3,
        "allowed_boundary_cells": [Vector2i(0, 128), Vector2i(255, 128)],
    }
    var horizontal_request: AreaGenerationRequest = AreaRequestClass.new(
        "area.test.hamlet.horizontal", 31001, bounds, &"rural.scattered", &"temperate.rural", [horizontal_road], [], []
    )
    var horizontal: Dictionary = road_planner.plan(horizontal_request, profile, [])
    _check(bool(horizontal.get("ok", false)), "rural-scattered lanes generate from a horizontal inherited spine")
    _check(_road_result_local_lane_count(horizontal) == 2, "horizontal inherited spine creates exactly two local lanes")

    var vertical_road := {
        "road_id": "road.test.hamlet.vertical",
        "road_class": &"secondary",
        "start": Vector2i(128, 0),
        "end": Vector2i(128, 255),
        "width": 3,
        "allowed_boundary_cells": [Vector2i(128, 0), Vector2i(128, 255)],
    }
    var vertical_request: AreaGenerationRequest = AreaRequestClass.new(
        "area.test.hamlet.vertical", 31002, bounds, &"rural.scattered", &"temperate.rural", [vertical_road], [], []
    )
    var vertical: Dictionary = road_planner.plan(vertical_request, profile, [])
    _check(bool(vertical.get("ok", false)), "rural-scattered lanes generate from a vertical inherited spine")
    _check(_road_result_local_lane_count(vertical) == 2, "vertical inherited spine creates exactly two local lanes")

func _request_inherited_roads_match_projection(
    request: AreaGenerationRequest,
    projector: System20AreaRequestProjector,
    global_plan: GeneratedGlobalWorldPlan
) -> bool:
    var projected: Dictionary = projector.road_constraints_for_bounds(global_plan, request.bounds)
    if not bool(projected.get("ok", false)):
        return false
    var roads: Array = projected.get("roads", [])
    if roads.size() != request.inherited_roads.size():
        return false
    for expected_value: Variant in roads:
        if typeof(expected_value) != TYPE_DICTIONARY:
            return false
        var expected: Dictionary = expected_value
        var found: Dictionary = _road_constraint_by_id(request.inherited_roads, String(expected.get("road_id", "")))
        if found.is_empty() or not _same_road_constraint(found, expected):
            return false
    return true

func _road_constraint_by_id(roads: Array[Dictionary], road_id: String) -> Dictionary:
    for road: Dictionary in roads:
        if String(road.get("road_id", "")) == road_id:
            return road
    return {}

func _same_road_constraint(a: Dictionary, b: Dictionary) -> bool:
    if String(a.get("road_id", "")) != String(b.get("road_id", "")):
        return false
    if StringName(a.get("road_class", &"")) != StringName(b.get("road_class", &"")):
        return false
    if a.get("start", Vector2i.ZERO) != b.get("start", Vector2i.ZERO) or a.get("end", Vector2i.ZERO) != b.get("end", Vector2i.ZERO):
        return false
    if int(a.get("width", 0)) != int(b.get("width", 0)):
        return false
    var allowed_a: Array = a.get("allowed_boundary_cells", [])
    var allowed_b: Array = b.get("allowed_boundary_cells", [])
    return allowed_a == allowed_b

func _constraint_count(request: AreaGenerationRequest, domain: StringName, role: StringName) -> int:
    var count: int = 0
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("domain", &"")) == domain and StringName(constraint.get("reservation_role", &"")) == role:
            count += 1
    return count

func _constraint_domain_count(request: AreaGenerationRequest, domain: StringName) -> int:
    var count: int = 0
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("domain", &"")) == domain:
            count += 1
    return count

func _water_service_constraint_valid(request: AreaGenerationRequest) -> bool:
    var found: int = 0
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("domain", &"")) != &"potable_water":
            continue
        if StringName(constraint.get("reservation_role", &"")) != &"service":
            return false
        if StringName(constraint.get("kind", &"")) != &"island_wide_municipal_service":
            return false
        if StringName(constraint.get("service_mode", &"")) != &"island_wide_municipal":
            return false
        if StringName(constraint.get("source_type", &"")) != &"treated_municipal":
            return false
        if String(constraint.get("plant_id", "")).is_empty():
            return false
        if not bool(constraint.get("island_wide", false)):
            return false
        found += 1
    return found == 1

func _inherited_road_contract_is_exact(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> bool:
    var inherited_count: int = 0
    for road: Dictionary in plan.roads:
        if bool(road.get("inherited", false)):
            inherited_count += 1
    if inherited_count != request.inherited_roads.size():
        return false
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
        if (found.get("allowed_boundary_cells", []) as Array) != (expected.get("allowed_boundary_cells", []) as Array):
            return false
    return true

func _count_road_class(plan: GeneratedAreaPlan, road_class: StringName) -> int:
    var count: int = 0
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) == road_class:
            count += 1
    return count

func _local_lanes_have_candidate_contract(plan: GeneratedAreaPlan) -> bool:
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) != &"local_rural":
            continue
        if bool(road.get("inherited", true)) or int(road.get("width", 0)) != 3:
            return false
        if not bool(road.get("rural_scattered_lane", false)) or not bool(road.get("parcel_frontage_enabled", false)):
            return false
        if StringName(road.get("surface_family", &"")) != &"rural_gravel" or bool(road.get("paint_centerline", true)):
            return false
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) != TYPE_VECTOR2I or not plan.bounds.has_point(value):
                return false
            if _is_boundary_cell(plan.bounds, value):
                return false
    return true

func _all_local_lanes_connect_to_inherited(plan: GeneratedAreaPlan) -> bool:
    var inherited_path: Dictionary = {}
    for road: Dictionary in plan.roads:
        if not bool(road.get("inherited", false)):
            continue
        for value: Variant in road.get("path_cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                inherited_path[value] = true
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) != &"local_rural":
            continue
        var connected: bool = false
        for value: Variant in road.get("path_cells", []):
            if typeof(value) == TYPE_VECTOR2I and inherited_path.has(value):
                connected = true
                break
        if not connected:
            return false
    return true

func _count_intersection_control(plan: GeneratedAreaPlan, control: StringName) -> int:
    var count: int = 0
    for intersection: Dictionary in plan.intersections:
        if StringName(intersection.get("control", &"")) == control:
            count += 1
    return count

func _count_land_use(plan: GeneratedAreaPlan, land_use: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == land_use:
            count += 1
    return count

func _occupied_on_road_class(plan: GeneratedAreaPlan, road_class: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        var use: StringName = StringName(parcel.get("land_use", &""))
        if use != &"residential" and use != &"farmstead" and use != &"commercial_small":
            continue
        if StringName(parcel.get("frontage_road_class", &"")) == road_class and not String(parcel.get("building_instance_id", "")).is_empty():
            count += 1
    return count

func _count_land_use_on_road_class(plan: GeneratedAreaPlan, land_use: StringName, road_class: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == land_use and StringName(parcel.get("frontage_road_class", &"")) == road_class:
            count += 1
    return count

func _only_approved_residential_buildings(plan: GeneratedAreaPlan) -> bool:
    if plan.building_requests.size() != 6:
        return false
    for request: BuildingGenerationRequest in plan.building_requests:
        if not ALLOWED_RESIDENTIAL_ARCHETYPES.has(request.archetype_id):
            return false
        if String(request.archetype_id).begins_with("commercial."):
            return false
    return true

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

func _facility_reservation_count(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for reservation: Dictionary in plan.reservations:
        if StringName(reservation.get("reservation_role", &"")) == &"facility":
            count += 1
    return count

func _ordinary_properties_avoid_reservations(plan: GeneratedAreaPlan) -> bool:
    for reservation: Dictionary in plan.reservations:
        if not bool(reservation.get("blocks_parcels", false)):
            continue
        var reserved: Rect2i = reservation.get("rect", Rect2i())
        for parcel: Dictionary in plan.parcels:
            if _rects_intersect(reserved, parcel.get("rect", Rect2i())):
                return false
            var building: Rect2i = parcel.get("building_envelope", Rect2i())
            if building.size.x > 0 and building.size.y > 0 and _rects_intersect(reserved, building):
                return false
            for value: Variant in parcel.get("driveway_cells", []):
                if typeof(value) == TYPE_VECTOR2I and reserved.has_point(value):
                    return false
    return true

func _unbuilt_nonroad_ratio(plan: GeneratedAreaPlan) -> float:
    var road_cells: Dictionary = {}
    for road: Dictionary in plan.roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                road_cells[value] = true
    var built_cells: Dictionary = {}
    for parcel: Dictionary in plan.parcels:
        if String(parcel.get("building_instance_id", "")).is_empty():
            continue
        var rect: Rect2i = parcel.get("building_envelope", Rect2i())
        for y in range(rect.position.y, rect.position.y + rect.size.y):
            for x in range(rect.position.x, rect.position.x + rect.size.x):
                var cell := Vector2i(x, y)
                if plan.bounds.has_point(cell) and not road_cells.has(cell):
                    built_cells[cell] = true
    var nonroad: int = plan.bounds.size.x * plan.bounds.size.y - road_cells.size()
    if nonroad <= 0:
        return 0.0
    return float(nonroad - built_cells.size()) / float(nonroad)

func _natural_prop_count(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for prop: Dictionary in plan.outdoor_props:
        if _is_natural_semantic(StringName(prop.get("semantic", &""))):
            count += 1
    return count

func _natural_coarse_bin_coverage(plan: GeneratedAreaPlan) -> int:
    var bins: Dictionary = {}
    for prop: Dictionary in plan.outdoor_props:
        if not _is_natural_semantic(StringName(prop.get("semantic", &""))):
            continue
        var cell: Vector2i = prop.get("cell", Vector2i.ZERO)
        var local_x: int = cell.x - plan.bounds.position.x
        var local_y: int = cell.y - plan.bounds.position.y
        bins[Vector2i(clampi(local_x / 64, 0, 3), clampi(local_y / 64, 0, 3))] = true
    return bins.size()

func _natural_xy_correlation_abs(plan: GeneratedAreaPlan) -> float:
    var xs: Array[float] = []
    var ys: Array[float] = []
    for prop: Dictionary in plan.outdoor_props:
        if not _is_natural_semantic(StringName(prop.get("semantic", &""))):
            continue
        var cell: Vector2i = prop.get("cell", Vector2i.ZERO)
        xs.append(float(cell.x - plan.bounds.position.x))
        ys.append(float(cell.y - plan.bounds.position.y))
    if xs.size() < 3:
        return 1.0
    var mean_x: float = 0.0
    var mean_y: float = 0.0
    for value: float in xs:
        mean_x += value
    for value: float in ys:
        mean_y += value
    mean_x /= float(xs.size())
    mean_y /= float(ys.size())
    var covariance: float = 0.0
    var variance_x: float = 0.0
    var variance_y: float = 0.0
    for index in range(xs.size()):
        var dx: float = xs[index] - mean_x
        var dy: float = ys[index] - mean_y
        covariance += dx * dy
        variance_x += dx * dx
        variance_y += dy * dy
    if variance_x <= 0.0001 or variance_y <= 0.0001:
        return 1.0
    return absf(covariance / sqrt(variance_x * variance_y))

func _is_natural_semantic(semantic: StringName) -> bool:
    return semantic == &"prop.deciduous_large" \
        or semantic == &"prop.deciduous_small" \
        or semantic == &"prop.dense_bush" \
        or semantic == &"prop.thorn_bush" \
        or semantic == &"prop.rock_small" \
        or semantic == &"prop.rock_cluster" \
        or semantic == &"prop.mossy_rock"

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

func _road_result_local_lane_count(result: Dictionary) -> int:
    var count: int = 0
    for road_value: Variant in result.get("roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            continue
        var road: Dictionary = road_value
        if StringName(road.get("road_class", &"")) == &"local_rural" and bool(road.get("rural_scattered_lane", false)):
            count += 1
    return count

func _is_boundary_cell(rect: Rect2i, cell: Vector2i) -> bool:
    if not rect.has_point(cell):
        return false
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    return cell.x == rect.position.x or cell.x == max_x or cell.y == rect.position.y or cell.y == max_y

func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    return a.position.x < b.position.x + b.size.x \
        and a.position.x + a.size.x > b.position.x \
        and a.position.y < b.position.y + b.size.y \
        and a.position.y + a.size.y > b.position.y

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("RURAL_SCATTERED_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("RURAL_SCATTERED_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)
