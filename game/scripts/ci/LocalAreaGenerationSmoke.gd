extends SceneTree

const FixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")
const BuildingGeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BuildingValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    var request: AreaGenerationRequest = FixtureClass.request()
    var plan: GeneratedAreaPlan = generator.generate(request)
    _test_candidate(generator, validator, request, plan)
    _test_seed_replay(generator)
    if failures.is_empty():
        print("LOCAL_AREA_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("LOCAL_AREA_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_candidate(
    generator: LocalAreaGenerator,
    validator: GeneratedAreaValidator,
    request: AreaGenerationRequest,
    plan: GeneratedAreaPlan
) -> void:
    _check(request.is_valid(), "Rural Crossroads Candidate 004 request is valid")
    _check(plan.is_generated(), "Rural Crossroads Candidate 004 generates")
    if not plan.is_generated():
        return
    _check(bool(validator.validate(request, plan).get("ok", false)), "Candidate 004 passes generic area validation")
    _check(plan.bounds == FixtureClass.BOUNDS and plan.bounds.size == Vector2i(256, 256), "Candidate 004 keeps the approved 256x256 global planning area")
    _check(plan.area_profile_version == 3, "rural.crossroads v3 records local-road frontage/setback morphology")
    _check(plan.environment_profile_version == 3, "temperate.rural v3 preserves accepted coordinate-noise ecology")

    _check(plan.roads.size() == 4, "Candidate 004 has two inherited roads plus two local rural roads")
    _check(_count_inherited_roads(plan) == 2, "the two regional roads remain inherited exactly")
    _check(_count_road_class(plan, &"local_rural") == 2, "two locally generated rural roads use interior open space")
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) != &"local_rural":
            continue
        _check(not bool(road.get("inherited", true)), "local road is locally owned rather than a fake major-road constraint")
        _check(int(road.get("width", 0)) == 3, "local road stays a small three-cell rural road")
        _check(_road_has_bends(road), "local road has multiple cardinal bends")
        _check(_road_stays_off_boundary(road, plan.bounds), "local road creates no unauthorized area-boundary exit")
        _check(bool(road.get("parcel_frontage_enabled", false)), "local road is now real parcel frontage")

    _check(_count_intersections(plan, &"signalized") == 1, "Candidate 004 preserves exactly one signalized crossroads")
    _check(_count_intersections(plan, &"uncontrolled") == 2, "two local-road junctions are ordinary uncontrolled intersections")
    _check(plan.intersections.size() == 3, "Candidate 004 has one crossroads plus two local-road junctions")
    if not plan.intersections.is_empty():
        _check(plan.intersections[0].get("cell", Vector2i(-1, -1)) == FixtureClass.CENTER, "signalized crossroads remains at inherited-road crossing")

    _check(_count_land_use(plan, &"commercial_small") == 3, "three commercial opportunities remain near the crossroads")
    _check(_count_land_use(plan, &"residential") == 6, "six rural residential parcels remain occupied candidates")
    _check(_count_land_use(plan, &"farmstead") == 4, "four farmstead parcels remain occupied candidates")
    _check(plan.building_requests.size() == 12, "existing library still supplies two commercial plus ten residential/farmstead buildings")
    _check(_count_building_archetype(plan, &"commercial.gas_station.small") == 1, "existing gas station is used once")
    _check(_count_building_archetype(plan, &"commercial.diner.rural_small") == 1, "accepted diner is used once")
    _check(_commercial_without_building(plan) == 1, "one commercial opportunity stays honestly vacant")
    _check(_occupied_on_road_class(plan, &"local_rural") >= 6, "most homes/farmsteads move off inherited roads onto local roads")

    var residential_archetypes: Dictionary = {}
    for parcel: Dictionary in plan.parcels:
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        if land_use != &"residential" and land_use != &"farmstead":
            continue
        var archetype: StringName = StringName(parcel.get("building_archetype_id", &""))
        if archetype != &"":
            residential_archetypes[archetype] = true
    for required: StringName in [
        &"residential.trailer.singlewide",
        &"residential.house.farm_small",
        &"residential.house.farm_large",
        &"residential.house.compact_laundry",
    ]:
        _check(residential_archetypes.has(required), "Candidate 004 exercises saved residential archetype %s" % String(required))

    _check(_average_distance(plan, &"commercial_small") < _average_distance(plan, &"residential"), "commercial density remains closest to crossroads")
    _check(_average_distance(plan, &"residential") < _average_distance(plan, &"farmstead"), "farmsteads remain materially farther from crossroads")
    var residential_driveway: float = _average_driveway(plan, &"residential")
    var commercial_driveway: float = _average_driveway(plan, &"commercial_small")
    var farm_driveway: float = _average_driveway(plan, &"farmstead")
    _check(residential_driveway <= 7.0, "ordinary houses sit close to their frontage road")
    _check(commercial_driveway <= 7.0, "small commercial buildings no longer float behind unused setback")
    _check(farm_driveway > residential_driveway and farm_driveway <= 11.0, "farmsteads keep a modest but not excessive rural setback")
    _check(_unbuilt_nonroad_ratio(plan) >= 0.60, "at least 60 percent of non-road area remains unbuilt")

    _check(_count_ground_semantic(plan, &"ground.road") == 0, "wide roads stay off generic topology tiles that created yellow boxes")
    _check(_count_ground_semantic(plan, &"ground.road_plain") == 2, "both inherited paved corridors preserve plain road surface")
    _check(_count_ground_semantic(plan, &"ground.road_yellow_line_h") == 1, "east-west road preserves one explicit horizontal centerline layer")
    _check(_count_ground_semantic(plan, &"ground.road_yellow_line_v") == 1, "north-south road preserves one explicit vertical centerline layer")
    _check(_count_ground_semantic(plan, &"ground.gravel_dark") == 2, "both local rural roads use unpainted gravel")

    _check(_count_prop_semantic(plan, &"prop.traffic_light") == 1, "one physical traffic light dresses the crossroads")
    _check(_count_prop_semantic(plan, &"prop.curb_mailbox") == 10, "occupied rural homes/farms receive one mailbox each")
    _check(_count_ground_semantic(plan, &"ground.field_green") >= 4, "farmstead/agricultural parcels expose real field zones")
    _check(_natural_prop_count(plan) >= 100, "open rural land keeps substantial noise-scattered natural dressing")
    _check(_count_prop_semantic(plan, &"prop.deciduous_large") + _count_prop_semantic(plan, &"prop.deciduous_small") > 0, "natural dressing includes trees")
    _check(_count_prop_semantic(plan, &"prop.dense_bush") + _count_prop_semantic(plan, &"prop.thorn_bush") > 0, "natural dressing includes shrubs")
    _check(_count_prop_semantic(plan, &"prop.rock_small") + _count_prop_semantic(plan, &"prop.rock_cluster") + _count_prop_semantic(plan, &"prop.mossy_rock") > 0, "natural dressing includes rocks")
    _check(_natural_props_avoid_fields(plan), "natural noise stays out of active field rectangles")
    var neighbor_ratio: float = _natural_neighbor_ratio(plan)
    _check(neighbor_ratio >= 0.20 and neighbor_ratio <= 0.90, "natural noise keeps local texture without collapsing into one dense chain")
    _check(_natural_coarse_bin_coverage(plan) >= 10, "natural noise reaches broad portions of the open map")
    _check(_natural_xy_correlation_abs(plan) <= 0.45, "natural noise keeps no strong diagonal X/Y correlation")

    var building_generator := BuildingGeneratorClass.new()
    var building_validator := BuildingValidatorClass.new()
    for building_request: BuildingGenerationRequest in plan.building_requests:
        _check(building_generator.supported_archetypes().has(building_request.archetype_id), "System 20 selects only registered System 19 archetypes")
        var subplan: GeneratedBuildingPlan = building_generator.generate(building_request)
        _check(subplan.is_generated(), "System 19 accepts area-selected building %s" % building_request.instance_id)
        if subplan.is_generated():
            _check(bool(building_validator.validate(subplan).get("ok", false)), "area-selected building validates through System 19")

    var art := ArtCatalogClass.new()
    for region: Dictionary in plan.ground_regions:
        _check(art.resolve_ground(region.get("semantic", &"")).is_found(), "System 20 ground semantic resolves through recovered art")
    for prop: Dictionary in plan.outdoor_props:
        _check(art.resolve_prop(prop.get("semantic", &"")).is_found(), "System 20 outdoor prop semantic resolves through recovered art")

func _test_seed_replay(generator: LocalAreaGenerator) -> void:
    var original_a: GeneratedAreaPlan = generator.generate(FixtureClass.request(20001))
    var original_b: GeneratedAreaPlan = generator.generate(FixtureClass.request(20001))
    _check(original_a.is_generated() and original_a.signature() == original_b.signature(), "same System 20 request and seed replay identically")
    var alternate: GeneratedAreaPlan = generator.generate(FixtureClass.request(20002))
    _check(alternate.is_generated() and alternate.signature() != original_a.signature(), "different area seed changes legal parcel/building/environment planning")
    for seed in range(20001, 20013):
        var plan: GeneratedAreaPlan = generator.generate(FixtureClass.request(seed))
        _check(plan.is_generated(), "rural crossroads v3 / temperate rural v3 seed %d generates without reroll loops" % seed)
        if plan.is_generated():
            _check(_count_intersections(plan, &"signalized") == 1, "seed %d preserves one signalized crossroads" % seed)
            _check(_count_road_class(plan, &"local_rural") == 2, "seed %d preserves two local rural roads" % seed)
            _check(plan.building_requests.size() == 12, "seed %d preserves approved occupied-building target" % seed)
            _check(_occupied_on_road_class(plan, &"local_rural") >= 6, "seed %d keeps most homes/farms on local roads" % seed)
            _check(_average_driveway(plan, &"residential") <= 7.0, "seed %d keeps residential setbacks compact" % seed)
            _check(_average_driveway(plan, &"farmstead") <= 11.0, "seed %d keeps farmstead setbacks bounded" % seed)
            _check(_natural_prop_count(plan) >= 80, "seed %d preserves meaningful natural dressing" % seed)
            _check(_natural_coarse_bin_coverage(plan) >= 8, "seed %d spreads natural dressing across the area" % seed)
            _check(_natural_xy_correlation_abs(plan) <= 0.60, "seed %d avoids diagonal natural-prop collapse" % seed)

func _count_inherited_roads(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for road: Dictionary in plan.roads:
        if bool(road.get("inherited", false)):
            count += 1
    return count

func _count_road_class(plan: GeneratedAreaPlan, road_class: StringName) -> int:
    var count: int = 0
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) == road_class:
            count += 1
    return count

func _road_has_bends(road: Dictionary) -> bool:
    var path: Array = road.get("path_cells", [])
    var saw_horizontal: bool = false
    var saw_vertical: bool = false
    for index in range(1, path.size()):
        var before: Vector2i = path[index - 1]
        var current: Vector2i = path[index]
        if before.y == current.y and before.x != current.x:
            saw_horizontal = true
        if before.x == current.x and before.y != current.y:
            saw_vertical = true
    return saw_horizontal and saw_vertical and (road.get("waypoints", []) as Array).size() >= 5

func _road_stays_off_boundary(road: Dictionary, bounds: Rect2i) -> bool:
    var max_x: int = bounds.position.x + bounds.size.x - 1
    var max_y: int = bounds.position.y + bounds.size.y - 1
    for value: Variant in road.get("path_cells", []):
        var cell: Vector2i = value
        if cell.x == bounds.position.x or cell.x == max_x or cell.y == bounds.position.y or cell.y == max_y:
            return false
    return true

func _count_intersections(plan: GeneratedAreaPlan, control: StringName) -> int:
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

func _count_building_archetype(plan: GeneratedAreaPlan, archetype_id: StringName) -> int:
    var count: int = 0
    for request: BuildingGenerationRequest in plan.building_requests:
        if request.archetype_id == archetype_id:
            count += 1
    return count

func _commercial_without_building(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == &"commercial_small" and String(parcel.get("building_instance_id", "")).is_empty():
            count += 1
    return count

func _occupied_on_road_class(plan: GeneratedAreaPlan, road_class: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        if land_use != &"residential" and land_use != &"farmstead":
            continue
        if StringName(parcel.get("frontage_road_class", &"")) != road_class:
            continue
        if String(parcel.get("building_instance_id", "")).is_empty():
            continue
        count += 1
    return count

func _average_distance(plan: GeneratedAreaPlan, land_use: StringName) -> float:
    var total: int = 0
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) != land_use:
            continue
        total += int(parcel.get("distance_to_center", 0))
        count += 1
    return 999999.0 if count == 0 else float(total) / float(count)

func _average_driveway(plan: GeneratedAreaPlan, land_use: StringName) -> float:
    var total: int = 0
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) != land_use:
            continue
        var driveway: Array = parcel.get("driveway_cells", [])
        if driveway.is_empty():
            continue
        total += driveway.size()
        count += 1
    return 0.0 if count == 0 else float(total) / float(count)

func _unbuilt_nonroad_ratio(plan: GeneratedAreaPlan) -> float:
    var road_cells: Dictionary = {}
    for road: Dictionary in plan.roads:
        for value: Variant in road.get("corridor_cells", []):
            road_cells[value] = true
    var building_cells: int = 0
    for request: BuildingGenerationRequest in plan.building_requests:
        building_cells += request.envelope.size.x * request.envelope.size.y
    var total_cells: int = plan.bounds.size.x * plan.bounds.size.y
    var nonroad: int = total_cells - road_cells.size()
    return float(nonroad - building_cells) / float(nonroad)

func _count_prop_semantic(plan: GeneratedAreaPlan, semantic: StringName) -> int:
    var count: int = 0
    for prop: Dictionary in plan.outdoor_props:
        if StringName(prop.get("semantic", &"")) == semantic:
            count += 1
    return count

func _count_ground_semantic(plan: GeneratedAreaPlan, semantic: StringName) -> int:
    var count: int = 0
    for region: Dictionary in plan.ground_regions:
        if StringName(region.get("semantic", &"")) == semantic:
            count += 1
    return count

func _natural_cells(plan: GeneratedAreaPlan) -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    for prop: Dictionary in plan.outdoor_props:
        if String(prop.get("id", "")).contains(".prop.natural."):
            cells.append(prop.get("cell", Vector2i.ZERO))
    return cells

func _natural_prop_count(plan: GeneratedAreaPlan) -> int:
    return _natural_cells(plan).size()

func _natural_props_avoid_fields(plan: GeneratedAreaPlan) -> bool:
    var fields: Array[Rect2i] = []
    for parcel: Dictionary in plan.parcels:
        var field_rect: Rect2i = parcel.get("field_rect", Rect2i())
        if field_rect.size.x > 0 and field_rect.size.y > 0:
            fields.append(field_rect)
    for cell: Vector2i in _natural_cells(plan):
        for field_rect: Rect2i in fields:
            if field_rect.has_point(cell):
                return false
    return true

func _natural_neighbor_ratio(plan: GeneratedAreaPlan) -> float:
    var cells: Array[Vector2i] = _natural_cells(plan)
    if cells.is_empty():
        return 0.0
    var near_count: int = 0
    for index in range(cells.size()):
        var has_neighbor: bool = false
        for other_index in range(cells.size()):
            if index == other_index:
                continue
            var distance: int = absi(cells[index].x - cells[other_index].x) + absi(cells[index].y - cells[other_index].y)
            if distance <= 4:
                has_neighbor = true
                break
        if has_neighbor:
            near_count += 1
    return float(near_count) / float(cells.size())

func _natural_coarse_bin_coverage(plan: GeneratedAreaPlan) -> int:
    var occupied: Dictionary = {}
    for cell: Vector2i in _natural_cells(plan):
        var local: Vector2i = cell - plan.bounds.position
        var bin_x: int = clampi(int(float(local.x) * 4.0 / float(plan.bounds.size.x)), 0, 3)
        var bin_y: int = clampi(int(float(local.y) * 4.0 / float(plan.bounds.size.y)), 0, 3)
        occupied[Vector2i(bin_x, bin_y)] = true
    return occupied.size()

func _natural_xy_correlation_abs(plan: GeneratedAreaPlan) -> float:
    var cells: Array[Vector2i] = _natural_cells(plan)
    if cells.size() < 3:
        return 1.0
    var mean_x: float = 0.0
    var mean_y: float = 0.0
    for cell: Vector2i in cells:
        mean_x += float(cell.x)
        mean_y += float(cell.y)
    mean_x /= float(cells.size())
    mean_y /= float(cells.size())

    var covariance: float = 0.0
    var variance_x: float = 0.0
    var variance_y: float = 0.0
    for cell: Vector2i in cells:
        var dx: float = float(cell.x) - mean_x
        var dy: float = float(cell.y) - mean_y
        covariance += dx * dy
        variance_x += dx * dx
        variance_y += dy * dy
    if variance_x <= 0.0 or variance_y <= 0.0:
        return 1.0
    return absf(covariance / sqrt(variance_x * variance_y))

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
