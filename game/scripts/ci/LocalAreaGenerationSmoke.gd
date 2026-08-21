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
    _check(request.is_valid(), "Candidate 001 request is valid")
    _check(plan.is_generated(), "Candidate 001 generates")
    if not plan.is_generated():
        return
    _check(bool(validator.validate(request, plan).get("ok", false)), "Candidate 001 passes generic area validation")
    _check(plan.bounds == FixtureClass.BOUNDS and plan.bounds.size == Vector2i(256, 256), "Candidate 001 keeps the approved 256x256 global planning area")
    _check(plan.roads.size() == 2, "Candidate 001 uses only the two inherited crossing roads")
    for road: Dictionary in plan.roads:
        _check(bool(road.get("inherited", false)), "Candidate 001 road remains inherited rather than locally invented")
    _check(_count_intersections(plan, &"signalized") == 1, "Candidate 001 has exactly one signalized intersection")
    _check(plan.intersections.size() == 1, "Candidate 001 has only the central crossroads intersection")
    if not plan.intersections.is_empty():
        _check(plan.intersections[0].get("cell", Vector2i(-1, -1)) == FixtureClass.CENTER, "signalized crossroads is at inherited-road crossing")

    _check(_count_land_use(plan, &"commercial_small") == 3, "three commercial opportunities cluster at the crossroads")
    _check(_count_land_use(plan, &"residential") == 6, "six nearer rural residential parcels are occupied candidates")
    _check(_count_land_use(plan, &"farmstead") == 4, "four outer farmstead parcels are occupied candidates")
    _check(plan.building_requests.size() == 12, "existing library supplies two commercial plus ten residential/farmstead buildings")
    _check(_count_building_archetype(plan, &"commercial.gas_station.small") == 1, "existing gas station is used once")
    _check(_count_building_archetype(plan, &"commercial.diner.rural_small") == 1, "accepted diner is used once")
    _check(_commercial_without_building(plan) == 1, "one commercial opportunity stays honestly vacant")

    var residential_archetypes: Dictionary = {}
    for parcel: Dictionary in plan.parcels:
        var land_use: StringName = parcel.get("land_use", &"")
        if land_use != &"residential" and land_use != &"farmstead":
            continue
        var archetype: StringName = parcel.get("building_archetype_id", &"")
        if archetype != &"":
            residential_archetypes[archetype] = true
    for required: StringName in [
        &"residential.trailer.singlewide",
        &"residential.house.farm_small",
        &"residential.house.farm_large",
        &"residential.house.compact_laundry",
    ]:
        _check(residential_archetypes.has(required), "Candidate 001 exercises saved residential archetype %s" % String(required))

    _check(_average_distance(plan, &"commercial_small") < _average_distance(plan, &"residential"), "commercial density is closest to crossroads")
    _check(_average_distance(plan, &"residential") < _average_distance(plan, &"farmstead"), "farmsteads sit materially farther from crossroads")
    _check(_average_driveway(plan, &"farmstead") > _average_driveway(plan, &"residential"), "farmstead driveways are longer than residential driveways")
    _check(_unbuilt_nonroad_ratio(plan) >= 0.60, "at least 60 percent of non-road area remains unbuilt")

    _check(_count_prop_semantic(plan, &"prop.traffic_light") == 1, "one physical traffic light dresses the crossroads")
    _check(_count_prop_semantic(plan, &"prop.curb_mailbox") == 10, "occupied rural homes/farms receive one mailbox each")
    _check(_count_ground_semantic(plan, &"ground.field_green") >= 4, "farmstead/agricultural parcels expose real field zones")

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
    _check(alternate.is_generated() and alternate.signature() != original_a.signature(), "different area seed changes legal parcel/building planning")
    for seed in range(20001, 20013):
        var plan: GeneratedAreaPlan = generator.generate(FixtureClass.request(seed))
        _check(plan.is_generated(), "rural crossroads seed %d generates without reroll loops" % seed)
        if plan.is_generated():
            _check(_count_intersections(plan, &"signalized") == 1, "seed %d preserves one signalized crossroads" % seed)
            _check(plan.building_requests.size() == 12, "seed %d preserves approved occupied-building target" % seed)

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

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
