extends SceneTree

const FixtureClass = preload("res://scripts/demo/RuralCrossroadsPlanFixture.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")
const BuildingGeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BuildingValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

const COMMERCIAL_TARGET: int = 3
const RESIDENTIAL_TARGET: int = 6
const FARMSTEAD_TARGET: int = 4
const TOTAL_STRUCTURE_TARGET: int = COMMERCIAL_TARGET + RESIDENTIAL_TARGET + FARMSTEAD_TARGET

var failures: Array[String] = []

func _initialize() -> void:
    var generator: LocalAreaGenerator = GeneratorClass.new()
    var validator: GeneratedAreaValidator = ValidatorClass.new()
    var request: AreaGenerationRequest = FixtureClass.request()
    var plan: GeneratedAreaPlan = generator.generate(request)
    _test_candidate(validator, request, plan)
    _test_seed_replay(generator)
    if failures.is_empty():
        print("LOCAL_AREA_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("LOCAL_AREA_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_candidate(
    validator: GeneratedAreaValidator,
    request: AreaGenerationRequest,
    plan: GeneratedAreaPlan
) -> void:
    _check(request.is_valid(), "Rural Crossroads Candidate 006 request is valid")
    _check(plan.is_generated(), "Rural Crossroads Candidate 006 generates")
    if not plan.is_generated():
        return
    _check(bool(validator.validate(request, plan).get("ok", false)), "Candidate 006 passes generic area validation")
    _check(plan.bounds == FixtureClass.BOUNDS and plan.bounds.size == Vector2i(256, 256), "Candidate 006 keeps the approved 256x256 global planning area")
    _check(plan.area_profile_version == 6, "rural.crossroads v6 remains recorded")
    _check(plan.environment_profile_version == 3, "temperate.rural v3 remains recorded")

    # Regional roads are authoritative. Local roads are optional best-effort detail and
    # therefore must never be required merely to satisfy an aesthetic density target.
    _check(_count_inherited_roads(plan) == 2, "the two regional roads remain inherited exactly")
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) != &"local_rural":
            continue
        _check(not bool(road.get("inherited", true)), "any local rural road stays locally owned")
        _check(int(road.get("width", 0)) == 3, "any local rural road stays three cells wide")
        _check(_road_stays_off_boundary(road, plan.bounds), "any local rural road creates no unauthorized boundary exit")
        _check(bool(road.get("parcel_frontage_enabled", false)), "any local rural road remains real parcel frontage")

    _check(_count_intersections(plan, &"signalized") == 1, "Candidate 006 preserves exactly one signalized inherited crossroads")
    _check(plan.intersections.size() >= 1, "Candidate 006 preserves the inherited crossroads intersection")
    if not plan.intersections.is_empty():
        _check(plan.intersections[0].get("cell", Vector2i(-1, -1)) == FixtureClass.CENTER, "signalized crossroads remains at the inherited-road crossing")

    # Counts are soft goals/caps: generated geometry decides how many legal parcels fit.
    _check(_count_land_use(plan, &"commercial_small") <= COMMERCIAL_TARGET, "commercial density never exceeds its target")
    _check(_count_land_use(plan, &"residential") <= RESIDENTIAL_TARGET, "residential density never exceeds its target")
    _check(_count_land_use(plan, &"farmstead") <= FARMSTEAD_TARGET, "farmstead density never exceeds its target")
    _check(plan.building_requests.size() > 0, "rural crossroads still materializes real structures")
    _check(plan.building_requests.size() <= TOTAL_STRUCTURE_TARGET, "rural crossroads never exceeds its combined structure target")
    _check(_count_occupied_parcels(plan) == plan.building_requests.size(), "every generated building belongs to one occupied legal parcel")
    _check(_count_building_archetype(plan, &"commercial.gas_station.small") <= 1, "gas station archetype is never duplicated")
    _check(_count_building_archetype(plan, &"commercial.diner.rural_small") <= 1, "diner archetype is never duplicated")
    _check(_all_occupied_approaches_align_to_primary_doors(plan), "every occupied approach remains straight to the actual primary door")

    _check(_setbacks_within_limit(plan, &"residential", 5.0), "generated residential facades keep bounded setbacks")
    _check(_setbacks_within_limit(plan, &"commercial_small", 5.0), "generated commercial facades keep bounded setbacks")
    _check(_setbacks_within_limit(plan, &"farmstead", 8.0), "generated farmsteads keep bounded setbacks")

    _check(_all_paved_frontages_are_road_flush(plan), "every generated paved frontage extends continuously to the road edge")
    _check(_only_buildings_with_parking_frontage_get_aprons(plan), "System 20 invents no parking for buildings without real parking frontage")
    _check(_parking_ground_covers_aprons(plan), "every generated parking apron is covered by a parking ground semantic")

    _check(_unbuilt_nonroad_ratio(plan) >= 0.60, "at least 60 percent of non-road area remains unbuilt")
    _check(_count_ground_semantic(plan, &"ground.road") == 0, "wide roads stay off generic topology tiles that created yellow boxes")
    _check(_count_ground_semantic(plan, &"ground.road_plain") == 2, "both inherited paved corridors preserve plain road surface")
    _check(_count_ground_semantic(plan, &"ground.road_yellow_line_h") == 1, "east-west road preserves one horizontal centerline layer")
    _check(_count_ground_semantic(plan, &"ground.road_yellow_line_v") == 1, "north-south road preserves one vertical centerline layer")
    _check(_count_ground_semantic(plan, &"ground.gravel_dark") == _count_road_class(plan, &"local_rural"), "optional local rural roads remain unpainted gravel")

    _check(_count_prop_semantic(plan, &"prop.traffic_light") == 1, "one physical traffic light dresses the inherited crossroads")
    _check(_count_prop_semantic(plan, &"prop.curb_mailbox") == _occupied_home_or_farm_count(plan), "every generated rural home/farm receives one mailbox")
    _check(_natural_prop_count(plan) >= 60, "open rural land keeps substantial noise-scattered natural dressing")
    _check(_count_prop_semantic(plan, &"prop.deciduous_large") + _count_prop_semantic(plan, &"prop.deciduous_small") > 0, "natural dressing includes trees")
    _check(_count_prop_semantic(plan, &"prop.dense_bush") + _count_prop_semantic(plan, &"prop.thorn_bush") > 0, "natural dressing includes shrubs")
    _check(_count_prop_semantic(plan, &"prop.rock_small") + _count_prop_semantic(plan, &"prop.rock_cluster") + _count_prop_semantic(plan, &"prop.mossy_rock") > 0, "natural dressing includes rocks")
    _check(_natural_props_avoid_fields(plan), "natural noise stays out of active fields")
    _check(_natural_coarse_bin_coverage(plan) >= 7, "natural noise reaches broad portions of the map")
    _check(_natural_xy_correlation_abs(plan) <= 0.70, "natural noise keeps no strong diagonal X/Y correlation")

    var building_generator: LocalBuildingGenerator = BuildingGeneratorClass.new()
    var building_validator: GeneratedBuildingValidator = BuildingValidatorClass.new()
    for building_request: BuildingGenerationRequest in plan.building_requests:
        _check(building_generator.supported_archetypes().has(building_request.archetype_id), "System 20 selects only registered System 19 archetypes")
        var subplan: GeneratedBuildingPlan = building_generator.generate(building_request)
        _check(subplan.is_generated(), "System 19 accepts area-selected building %s" % building_request.instance_id)
        if subplan.is_generated():
            _check(bool(building_validator.validate(subplan).get("ok", false)), "area-selected building validates through System 19")

    var art: ArtCatalog = ArtCatalogClass.new()
    for region: Dictionary in plan.ground_regions:
        _check(art.resolve_ground(region.get("semantic", &"")).is_found(), "System 20 ground semantic resolves through recovered art")
    for prop: Dictionary in plan.outdoor_props:
        _check(art.resolve_prop(prop.get("semantic", &"")).is_found(), "System 20 outdoor prop semantic resolves through recovered art")

func _test_seed_replay(generator: LocalAreaGenerator) -> void:
    var original_a: GeneratedAreaPlan = generator.generate(FixtureClass.request(20001))
    var original_b: GeneratedAreaPlan = generator.generate(FixtureClass.request(20001))
    _check(original_a.is_generated() and original_a.signature() == original_b.signature(), "same System 20 request and seed replay identically")
    var alternate: GeneratedAreaPlan = generator.generate(FixtureClass.request(20002))
    _check(alternate.is_generated() and alternate.signature() != original_a.signature(), "different area seed changes legal local planning")
    for seed in range(20001, 20013):
        var plan: GeneratedAreaPlan = generator.generate(FixtureClass.request(seed))
        _check(plan.is_generated(), "rural crossroads v6 / temperate rural v3 seed %d generates without reroll loops" % seed)
        if not plan.is_generated():
            continue
        _check(plan.area_profile_version == 6, "seed %d records rural.crossroads v6" % seed)
        _check(_count_inherited_roads(plan) == 2, "seed %d preserves both inherited roads" % seed)
        _check(_count_intersections(plan, &"signalized") == 1, "seed %d preserves one signalized crossroads" % seed)
        _check(_count_land_use(plan, &"commercial_small") <= COMMERCIAL_TARGET, "seed %d respects commercial density cap" % seed)
        _check(_count_land_use(plan, &"residential") <= RESIDENTIAL_TARGET, "seed %d respects residential density cap" % seed)
        _check(_count_land_use(plan, &"farmstead") <= FARMSTEAD_TARGET, "seed %d respects farmstead density cap" % seed)
        _check(plan.building_requests.size() <= TOTAL_STRUCTURE_TARGET, "seed %d respects combined structure cap" % seed)
        _check(_count_occupied_parcels(plan) == plan.building_requests.size(), "seed %d keeps one legal parcel per generated building" % seed)
        _check(_all_occupied_approaches_align_to_primary_doors(plan), "seed %d keeps straight door-aligned approaches" % seed)
        _check(_all_paved_frontages_are_road_flush(plan), "seed %d keeps generated parking frontage flush to road" % seed)
        _check(_only_buildings_with_parking_frontage_get_aprons(plan), "seed %d invents no parking apron" % seed)
        _check(_parking_ground_covers_aprons(plan), "seed %d covers every generated parking apron" % seed)
        _check(_setbacks_within_limit(plan, &"residential", 5.0), "seed %d keeps residential setbacks bounded" % seed)
        _check(_setbacks_within_limit(plan, &"farmstead", 8.0), "seed %d keeps farmstead setbacks bounded" % seed)
        _check(_natural_prop_count(plan) >= 50, "seed %d preserves meaningful natural dressing" % seed)
        _check(_natural_coarse_bin_coverage(plan) >= 6, "seed %d spreads natural dressing across the area" % seed)
        _check(_natural_xy_correlation_abs(plan) <= 0.75, "seed %d avoids diagonal natural-prop collapse" % seed)

func _all_occupied_approaches_align_to_primary_doors(plan: GeneratedAreaPlan) -> bool:
    for parcel: Dictionary in plan.parcels:
        if String(parcel.get("building_instance_id", "")).is_empty():
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
                var cell: Vector2i = value
                if cell.x != access.x:
                    return false
        else:
            if access.y != entry.y:
                return false
            for value: Variant in driveway:
                var cell: Vector2i = value
                if cell.y != access.y:
                    return false
    return true

func _all_paved_frontages_are_road_flush(plan: GeneratedAreaPlan) -> bool:
    for parcel: Dictionary in plan.parcels:
        var edge_entries: Array = parcel.get("road_flush_paved_frontage", [])
        if edge_entries.is_empty():
            continue
        var parking_set: Dictionary = {}
        for value: Variant in parcel.get("parking_cells", []):
            parking_set[value] = true
        var access: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
        var frontage: int = int(parcel.get("frontage_side", -1))
        if access.x < 0 or not Facing.is_valid(frontage):
            return false
        var direction: Vector2i = Facing.vector(frontage)
        for edge_value: Variant in edge_entries:
            if typeof(edge_value) != TYPE_DICTIONARY:
                return false
            var current: Vector2i = (edge_value as Dictionary).get("cell", Vector2i(-999999, -999999))
            var previous_distance: int = _frontage_axis_distance(current, access, frontage)
            if previous_distance <= 0:
                return false
            for _step in range(64):
                current += direction
                var distance: int = _frontage_axis_distance(current, access, frontage)
                if distance == 0:
                    break
                if distance >= previous_distance or not parking_set.has(current):
                    return false
                previous_distance = distance
            if _frontage_axis_distance(current, access, frontage) != 0:
                return false
    return true

func _only_buildings_with_parking_frontage_get_aprons(plan: GeneratedAreaPlan) -> bool:
    for parcel: Dictionary in plan.parcels:
        var has_edge: bool = not (parcel.get("road_flush_paved_frontage", []) as Array).is_empty()
        var has_apron: bool = not (parcel.get("parking_cells", []) as Array).is_empty()
        if has_edge != has_apron:
            return false
    return true

func _parking_ground_covers_aprons(plan: GeneratedAreaPlan) -> bool:
    var covered: Dictionary = {}
    for region: Dictionary in plan.ground_regions:
        if not String(region.get("semantic", &"")).begins_with("ground.parking"):
            continue
        for value: Variant in region.get("cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                covered[value] = true
    for parcel: Dictionary in plan.parcels:
        for value: Variant in parcel.get("parking_cells", []):
            if not covered.has(value):
                return false
    return true

func _frontage_axis_distance(a: Vector2i, b: Vector2i, frontage: int) -> int:
    if frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH:
        return absi(a.y - b.y)
    return absi(a.x - b.x)

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

func _count_occupied_parcels(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if not String(parcel.get("building_instance_id", "")).is_empty():
            count += 1
    return count

func _occupied_home_or_farm_count(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        if land_use != &"residential" and land_use != &"farmstead":
            continue
        if not String(parcel.get("building_instance_id", "")).is_empty():
            count += 1
    return count

func _count_building_archetype(plan: GeneratedAreaPlan, archetype: StringName) -> int:
    var count: int = 0
    for request: BuildingGenerationRequest in plan.building_requests:
        if request.archetype_id == archetype:
            count += 1
    return count

func _setbacks_within_limit(plan: GeneratedAreaPlan, land_use: StringName, limit: float) -> bool:
    var average: float = _average_front_setback(plan, land_use)
    return average < 0.0 or average <= limit

func _average_front_setback(plan: GeneratedAreaPlan, land_use: StringName) -> float:
    var total: int = 0
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) != land_use:
            continue
        var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
        var access: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
        var frontage: int = int(parcel.get("frontage_side", -1))
        if envelope.size.x <= 0 or envelope.size.y <= 0 or access.x < 0 or not Facing.is_valid(frontage):
            continue
        var max_x: int = envelope.position.x + envelope.size.x - 1
        var max_y: int = envelope.position.y + envelope.size.y - 1
        var distance: int = 0
        match frontage:
            Facing.Value.NORTH:
                distance = maxi(0, envelope.position.y - access.y - 1)
            Facing.Value.SOUTH:
                distance = maxi(0, access.y - max_y - 1)
            Facing.Value.WEST:
                distance = maxi(0, envelope.position.x - access.x - 1)
            Facing.Value.EAST:
                distance = maxi(0, access.x - max_x - 1)
        total += distance
        count += 1
    return -1.0 if count == 0 else float(total) / float(count)

func _unbuilt_nonroad_ratio(plan: GeneratedAreaPlan) -> float:
    var road_cells: Dictionary = {}
    for road: Dictionary in plan.roads:
        for value: Variant in road.get("corridor_cells", []):
            road_cells[value] = true
    var built_cells: Dictionary = {}
    for parcel: Dictionary in plan.parcels:
        var envelope: Rect2i = parcel.get("building_envelope", Rect2i())
        for y in range(envelope.position.y, envelope.position.y + envelope.size.y):
            for x in range(envelope.position.x, envelope.position.x + envelope.size.x):
                built_cells[Vector2i(x, y)] = true
    var total_cells: int = plan.bounds.size.x * plan.bounds.size.y
    var nonroad: int = total_cells - road_cells.size()
    if nonroad <= 0:
        return 0.0
    var built_nonroad: int = 0
    for value: Variant in built_cells.keys():
        if not road_cells.has(value):
            built_nonroad += 1
    return float(nonroad - built_nonroad) / float(nonroad)

func _count_ground_semantic(plan: GeneratedAreaPlan, semantic: StringName) -> int:
    var count: int = 0
    for region: Dictionary in plan.ground_regions:
        if StringName(region.get("semantic", &"")) == semantic:
            count += 1
    return count

func _count_prop_semantic(plan: GeneratedAreaPlan, semantic: StringName) -> int:
    var count: int = 0
    for prop: Dictionary in plan.outdoor_props:
        if StringName(prop.get("semantic", &"")) == semantic:
            count += 1
    return count

func _natural_prop_count(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for prop: Dictionary in plan.outdoor_props:
        if String(prop.get("id", "")).contains(".prop.natural."):
            count += 1
    return count

func _natural_props_avoid_fields(plan: GeneratedAreaPlan) -> bool:
    var fields: Array[Rect2i] = []
    for parcel: Dictionary in plan.parcels:
        var field: Rect2i = parcel.get("field_rect", Rect2i())
        if field.size.x > 0 and field.size.y > 0:
            fields.append(field)
    for prop: Dictionary in plan.outdoor_props:
        if not String(prop.get("id", "")).contains(".prop.natural."):
            continue
        var cell: Vector2i = prop.get("cell", Vector2i.ZERO)
        for field: Rect2i in fields:
            if field.has_point(cell):
                return false
    return true

func _natural_coarse_bin_coverage(plan: GeneratedAreaPlan) -> int:
    var bins: Dictionary = {}
    var bin_w: int = maxi(1, plan.bounds.size.x / 4)
    var bin_h: int = maxi(1, plan.bounds.size.y / 4)
    for prop: Dictionary in plan.outdoor_props:
        if not String(prop.get("id", "")).contains(".prop.natural."):
            continue
        var cell: Vector2i = prop.get("cell", Vector2i.ZERO) - plan.bounds.position
        var bx: int = mini(3, cell.x / bin_w)
        var by: int = mini(3, cell.y / bin_h)
        bins[Vector2i(bx, by)] = true
    return bins.size()

func _natural_xy_correlation_abs(plan: GeneratedAreaPlan) -> float:
    var cells: Array[Vector2i] = []
    for prop: Dictionary in plan.outdoor_props:
        if String(prop.get("id", "")).contains(".prop.natural."):
            cells.append(prop.get("cell", Vector2i.ZERO))
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
