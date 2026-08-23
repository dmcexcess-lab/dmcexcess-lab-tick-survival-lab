extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")

const WINDOW: int = 128

var failures: Array[String] = []

func _initialize() -> void:
    var global_planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = GeneratorClass.new()
    var validator: GeneratedAreaValidator = ValidatorClass.new()
    var global_plan: GeneratedGlobalWorldPlan = global_planner.generate(GlobalFixtureClass.request())

    _check(global_plan.is_generated(), "canonical System 00D v6 world generates before rural-open projection")
    if not global_plan.is_generated():
        push_error("RURAL_OPEN_GLOBAL_FAILURE: %s" % global_plan.failure_reason)
        _finish()
        return

    var replay_global: GeneratedGlobalWorldPlan = global_planner.generate(GlobalFixtureClass.request())
    _check(replay_global.is_generated() and replay_global.signature() == global_plan.signature(), "System 00D v6 signature remains deterministic and unchanged by System 20C consumption")

    _test_profile_and_roadless_contract(generator)

    var roadless_bounds: Rect2i = _find_window(global_plan, projector, false, false)
    _check(roadless_bounds.size.x > 0, "canonical world contains a dry roadless rural-open test window")
    if roadless_bounds.size.x > 0:
        _test_rural_open_window("roadless", roadless_bounds, global_plan, projector, generator, validator, false)

    var roadside_bounds: Rect2i = _find_window(global_plan, projector, true, false)
    _check(roadside_bounds.size.x > 0, "canonical world contains a dry roadside rural-open test window")
    if roadside_bounds.size.x > 0:
        _test_rural_open_window("roadside", roadside_bounds, global_plan, projector, generator, validator, true)

    var field_bounds: Rect2i = _find_field_window(global_plan, projector, generator)
    _check(field_bounds.size.x > 0, "canonical lowland/rolling countryside produces real agricultural field cover")
    if field_bounds.size.x > 0:
        var field_projected: Dictionary = projector.project_rural_open_bounds(global_plan, "area.test.rural_open.field", field_bounds)
        var field_request: AreaGenerationRequest = field_projected.get("request") as AreaGenerationRequest
        var field_plan: GeneratedAreaPlan = generator.generate(field_request)
        _check(field_plan.is_generated(), "field-bearing rural-open window generates")
        if field_plan.is_generated():
            _check(_field_cells_valid(field_plan, field_request), "agricultural field cells exist only on lowland/rolling inherited geography")

    var upland_bounds: Rect2i = _find_upland_or_ridge_window(global_plan, projector)
    _check(upland_bounds.size.x > 0, "canonical world contains a dry upland/ridge rural-open test window")
    if upland_bounds.size.x > 0:
        var upland_projected: Dictionary = projector.project_rural_open_bounds(global_plan, "area.test.rural_open.upland", upland_bounds)
        var upland_request: AreaGenerationRequest = upland_projected.get("request") as AreaGenerationRequest
        var upland_plan: GeneratedAreaPlan = generator.generate(upland_request)
        _check(upland_plan.is_generated(), "upland/ridge rural-open window generates")
        if upland_plan.is_generated():
            _check(_field_cells(upland_plan).is_empty(), "upland/ridge countryside never fabricates agricultural field cover")

    var pair: Dictionary = _find_adjacent_roadless_pair(global_plan, projector)
    _check(not pair.is_empty(), "canonical world contains adjacent dry roadless windows for seam testing")
    if not pair.is_empty():
        _test_split_combined_equivalence(pair, global_plan, projector, generator)

    _test_river_rejection(global_plan, projector)
    _test_settlement_overlap_rejection(global_plan, projector)
    _finish()

func _test_profile_and_roadless_contract(generator: LocalAreaGenerator) -> void:
    var profiles: AreaProfileCatalog = AreaProfilesClass.new()
    var rural_open: Dictionary = profiles.profile(&"rural.open")
    _check(not rural_open.is_empty() and int(rural_open.get("version", 0)) == 1, "rural.open v1 is registered")
    _check(generator.area_profile_ids().has(&"rural.open"), "LocalAreaGenerator exposes rural.open")

    var bounds := Rect2i(0, 0, 64, 64)
    var base_request: AreaGenerationRequest = AreaRequestClass.new(
        "area.test.roadless.base", 123, bounds, &"rural.open", &"temperate.rural", [], [], [], []
    )
    _check(base_request.is_valid(), "base AreaGenerationRequest now represents a roadless local area")

    for profile_id: StringName in [&"rural.crossroads", &"smalltown.center", &"rural.scattered"]:
        var request: AreaGenerationRequest = AreaRequestClass.new(
            "area.test.roadless.%s" % String(profile_id).replace(".", "_"),
            123,
            bounds,
            profile_id,
            &"temperate.rural",
            [],
            [],
            []
        )
        _check(request.is_valid(), "%s roadless request is structurally representable" % String(profile_id))
        var plan: GeneratedAreaPlan = generator.generate(request)
        _check(not plan.is_generated() and plan.failure_reason == "area_profile_requires_inherited_road", "%s still rejects roadlessness at the profile boundary" % String(profile_id))

func _test_rural_open_window(
    label: String,
    bounds: Rect2i,
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    generator: LocalAreaGenerator,
    validator: GeneratedAreaValidator,
    expect_roads: bool
) -> void:
    var projected: Dictionary = projector.project_rural_open_bounds(global_plan, "area.test.rural_open.%s" % label, bounds)
    _check(bool(projected.get("ok", false)), "%s rural-open window projects" % label)
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    _check(request != null and request.is_valid(), "%s projected request is valid" % label)
    if request == null or not request.is_valid():
        return
    _check(request.area_profile_id == &"rural.open", "%s selects rural.open v1" % label)
    _check(request.environment_profile_id == &"temperate.rural", "%s keeps temperate.rural" % label)
    _check(request.seed == global_plan.seed, "%s shares the global world seed rather than an area-local ecology seed" % label)
    _check(_geography_covers_request(request), "%s inherited geography covers every request cell exactly once" % label)
    _check(expect_roads == (not request.inherited_roads.is_empty()), "%s road presence matches test intent" % label)
    _check(_only_corridor_planning_constraints(request), "%s consumes only real intersecting infrastructure corridors" % label)

    var plan: GeneratedAreaPlan = generator.generate(request)
    _check(plan.is_generated(), "%s Rural-Open Candidate 001 generates" % label)
    if not plan.is_generated():
        push_error("RURAL_OPEN_PLAN_FAILURE %s: %s" % [label, plan.failure_reason])
        return
    _check(bool(validator.validate(request, plan).get("ok", false)), "%s passes generic System 20 validation" % label)
    _check(plan.area_profile_version == 1 and plan.environment_profile_version == 3, "%s records rural.open v1 + temperate.rural v3" % label)
    _check(plan.blocks.is_empty() and plan.parcels.is_empty() and plan.building_requests.is_empty(), "%s creates no town blocks, settlement parcels or buildings" % label)
    _check(_all_roads_inherited_and_exact(request, plan), "%s creates no local road and preserves projected regional-road truth" % label)
    _check(_all_intersections_uncontrolled(plan), "%s invents no countryside traffic signal" % label)
    _check(_natural_props_valid(request, plan), "%s natural props are global-cell-stable and avoid roads/fields/corridors" % label)

    var replay: GeneratedAreaPlan = generator.generate(request)
    _check(replay.is_generated() and replay.signature() == plan.signature(), "%s same request replays exactly" % label)

func _find_window(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    require_road: bool,
    require_field_landform: bool
) -> Rect2i:
    var start: Vector2i = global_plan.bounds.position
    var end: Vector2i = global_plan.bounds.position + global_plan.bounds.size
    for y in range(start.y, end.y - WINDOW + 1, WINDOW):
        for x in range(start.x, end.x - WINDOW + 1, WINDOW):
            var bounds := Rect2i(x, y, WINDOW, WINDOW)
            var projected: Dictionary = projector.project_rural_open_bounds(global_plan, "area.scan.rural_open.%d.%d" % [x, y], bounds)
            if not bool(projected.get("ok", false)):
                continue
            var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
            if request == null:
                continue
            if require_road != (not request.inherited_roads.is_empty()):
                continue
            if require_field_landform and not _request_has_landform(request, [&"lowland", &"rolling"]):
                continue
            return bounds
    return Rect2i()

func _find_field_window(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    generator: LocalAreaGenerator
) -> Rect2i:
    var start: Vector2i = global_plan.bounds.position
    var end: Vector2i = global_plan.bounds.position + global_plan.bounds.size
    for y in range(start.y, end.y - WINDOW + 1, WINDOW):
        for x in range(start.x, end.x - WINDOW + 1, WINDOW):
            var bounds := Rect2i(x, y, WINDOW, WINDOW)
            var projected: Dictionary = projector.project_rural_open_bounds(global_plan, "area.scan.rural_open.field.%d.%d" % [x, y], bounds)
            if not bool(projected.get("ok", false)):
                continue
            var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
            if request == null or not _request_has_landform(request, [&"lowland", &"rolling"]):
                continue
            var plan: GeneratedAreaPlan = generator.generate(request)
            if plan.is_generated() and not _field_cells(plan).is_empty():
                return bounds
    return Rect2i()

func _find_upland_or_ridge_window(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector
) -> Rect2i:
    for geography: Dictionary in global_plan.geography_cells:
        var landform: StringName = StringName(geography.get("landform", &""))
        if landform != &"upland" and landform != &"ridge":
            continue
        var source_rect: Rect2i = geography.get("rect", Rect2i())
        if source_rect.size.x < 64 or source_rect.size.y < 64:
            continue
        var bounds := Rect2i(source_rect.position + Vector2i(32, 32), Vector2i(64, 64))
        if not _rect_inside(global_plan.bounds, bounds):
            continue
        var projected: Dictionary = projector.project_rural_open_bounds(global_plan, "area.scan.rural_open.upland.%d.%d" % [bounds.position.x, bounds.position.y], bounds)
        if bool(projected.get("ok", false)):
            return bounds
    return Rect2i()

func _find_adjacent_roadless_pair(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector
) -> Dictionary:
    var start: Vector2i = global_plan.bounds.position
    var end: Vector2i = global_plan.bounds.position + global_plan.bounds.size
    for y in range(start.y, end.y - WINDOW + 1, WINDOW):
        for x in range(start.x, end.x - WINDOW * 2 + 1, WINDOW):
            var left := Rect2i(x, y, WINDOW, WINDOW)
            var right := Rect2i(x + WINDOW, y, WINDOW, WINDOW)
            var combined := Rect2i(x, y, WINDOW * 2, WINDOW)
            var left_result: Dictionary = projector.project_rural_open_bounds(global_plan, "area.scan.rural_open.left.%d.%d" % [x, y], left)
            var right_result: Dictionary = projector.project_rural_open_bounds(global_plan, "area.scan.rural_open.right.%d.%d" % [x, y], right)
            var combined_result: Dictionary = projector.project_rural_open_bounds(global_plan, "area.scan.rural_open.combined.%d.%d" % [x, y], combined)
            if not bool(left_result.get("ok", false)) or not bool(right_result.get("ok", false)) or not bool(combined_result.get("ok", false)):
                continue
            var left_request: AreaGenerationRequest = left_result.get("request") as AreaGenerationRequest
            var right_request: AreaGenerationRequest = right_result.get("request") as AreaGenerationRequest
            var combined_request: AreaGenerationRequest = combined_result.get("request") as AreaGenerationRequest
            if left_request == null or right_request == null or combined_request == null:
                continue
            if not left_request.inherited_roads.is_empty() or not right_request.inherited_roads.is_empty() or not combined_request.inherited_roads.is_empty():
                continue
            return {"left": left, "right": right, "combined": combined}
    return {}

func _test_split_combined_equivalence(
    pair: Dictionary,
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    generator: LocalAreaGenerator
) -> void:
    var left_bounds: Rect2i = pair.get("left", Rect2i())
    var right_bounds: Rect2i = pair.get("right", Rect2i())
    var combined_bounds: Rect2i = pair.get("combined", Rect2i())

    var left_request: AreaGenerationRequest = (projector.project_rural_open_bounds(global_plan, "area.test.rural_open.split.left", left_bounds)).get("request") as AreaGenerationRequest
    var right_request: AreaGenerationRequest = (projector.project_rural_open_bounds(global_plan, "area.test.rural_open.split.right", right_bounds)).get("request") as AreaGenerationRequest
    var combined_request: AreaGenerationRequest = (projector.project_rural_open_bounds(global_plan, "area.test.rural_open.split.combined", combined_bounds)).get("request") as AreaGenerationRequest
    var left: GeneratedAreaPlan = generator.generate(left_request)
    var right: GeneratedAreaPlan = generator.generate(right_request)
    var combined: GeneratedAreaPlan = generator.generate(combined_request)
    _check(left.is_generated() and right.is_generated() and combined.is_generated(), "split and combined rural-open seam plans all generate")
    if not left.is_generated() or not right.is_generated() or not combined.is_generated():
        return

    var split_ground: Dictionary = _ground_semantics(left)
    split_ground.merge(_ground_semantics(right), true)
    var combined_ground: Dictionary = _ground_semantics(combined)
    _check(split_ground == combined_ground, "split-vs-combined countryside ground semantics are identical by global cell")

    var split_props: Dictionary = _prop_semantics(left)
    split_props.merge(_prop_semantics(right), true)
    var combined_props: Dictionary = _prop_semantics(combined)
    _check(split_props == combined_props, "split-vs-combined countryside natural prop identity/semantics are identical by global cell")

func _test_river_rejection(global_plan: GeneratedGlobalWorldPlan, projector: System20AreaRequestProjector) -> void:
    var found: bool = false
    for river: Dictionary in global_plan.river_segments:
        var start: Vector2i = river.get("start", Vector2i.ZERO)
        var finish: Vector2i = river.get("end", Vector2i.ZERO)
        var midpoint := Vector2i((start.x + finish.x) / 2, (start.y + finish.y) / 2)
        var bounds := Rect2i(midpoint - Vector2i(24, 24), Vector2i(48, 48))
        if not _rect_inside(global_plan.bounds, bounds) or _overlaps_any_site(bounds, global_plan.area_sites):
            continue
        var result: Dictionary = projector.project_rural_open_bounds(global_plan, "area.test.rural_open.river", bounds)
        if not bool(result.get("ok", false)) and String(result.get("failure_reason", "")) == "rural_open_hydrology_not_materializable":
            found = true
            break
    _check(found, "real regional-river countryside fails honestly until local hydrology/bridge materialization exists")

func _test_settlement_overlap_rejection(global_plan: GeneratedGlobalWorldPlan, projector: System20AreaRequestProjector) -> void:
    _check(not global_plan.area_sites.is_empty(), "canonical world exposes settlement sites for rural-open exclusion test")
    if global_plan.area_sites.is_empty():
        return
    var site: Dictionary = global_plan.area_sites[0]
    var result: Dictionary = projector.project_rural_open_bounds(global_plan, "area.test.rural_open.settlement_overlap", site.get("bounds", Rect2i()))
    _check(not bool(result.get("ok", false)) and String(result.get("failure_reason", "")) == "rural_open_overlaps_settlement_site", "rural-open projection cannot overwrite a settlement site's morphology")

func _geography_covers_request(request: AreaGenerationRequest) -> bool:
    var counts: Dictionary = {}
    for geography: Dictionary in request.inherited_geography:
        var rect: Rect2i = geography.get("rect", Rect2i())
        for y in range(rect.position.y, rect.position.y + rect.size.y):
            for x in range(rect.position.x, rect.position.x + rect.size.x):
                var cell := Vector2i(x, y)
                counts[cell] = int(counts.get(cell, 0)) + 1
    if counts.size() != request.bounds.size.x * request.bounds.size.y:
        return false
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        for x in range(request.bounds.position.x, request.bounds.position.x + request.bounds.size.x):
            if int(counts.get(Vector2i(x, y), 0)) != 1:
                return false
    return true

func _request_has_landform(request: AreaGenerationRequest, landforms: Array[StringName]) -> bool:
    for geography: Dictionary in request.inherited_geography:
        if landforms.has(StringName(geography.get("landform", &""))):
            return true
    return false

func _field_cells_valid(plan: GeneratedAreaPlan, request: AreaGenerationRequest) -> bool:
    var fields: Dictionary = _field_cells(plan)
    if fields.is_empty():
        return false
    for cell_value: Variant in fields.keys():
        var cell: Vector2i = cell_value
        var geography: Dictionary = _geography_at(request, cell)
        var landform: StringName = StringName(geography.get("landform", &""))
        if landform != &"lowland" and landform != &"rolling":
            return false
    return true

func _field_cells(plan: GeneratedAreaPlan) -> Dictionary:
    var result: Dictionary = {}
    for region: Dictionary in plan.ground_regions:
        if StringName(region.get("semantic", &"")) != &"ground.field_green":
            continue
        for value: Variant in region.get("cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                result[value] = true
    return result

func _geography_at(request: AreaGenerationRequest, cell: Vector2i) -> Dictionary:
    for geography: Dictionary in request.inherited_geography:
        var rect: Rect2i = geography.get("rect", Rect2i())
        if rect.has_point(cell):
            return geography
    return {}

func _only_corridor_planning_constraints(request: AreaGenerationRequest) -> bool:
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("reservation_role", &"")) != &"corridor":
            return false
        var domain: StringName = StringName(constraint.get("domain", &""))
        if domain != &"power" and domain != &"potable_water" and domain != &"wastewater":
            return false
    return true

func _all_roads_inherited_and_exact(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> bool:
    if plan.roads.size() != request.inherited_roads.size():
        return false
    for road: Dictionary in plan.roads:
        if not bool(road.get("inherited", false)):
            return false
        var source: Dictionary = {}
        for candidate: Dictionary in request.inherited_roads:
            if String(candidate.get("road_id", "")) == String(road.get("road_id", "")):
                source = candidate
                break
        if source.is_empty():
            return false
        if StringName(source.get("road_class", &"")) != StringName(road.get("road_class", &"")):
            return false
        if source.get("start", Vector2i.ZERO) != road.get("start", Vector2i.ZERO) or source.get("end", Vector2i.ZERO) != road.get("end", Vector2i.ZERO):
            return false
        if int(source.get("width", 0)) != int(road.get("width", 0)):
            return false
    return true

func _all_intersections_uncontrolled(plan: GeneratedAreaPlan) -> bool:
    for intersection: Dictionary in plan.intersections:
        if StringName(intersection.get("control", &"")) != &"uncontrolled":
            return false
    return true

func _natural_props_valid(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> bool:
    var allowed: Dictionary = {
        &"prop.deciduous_large": true,
        &"prop.deciduous_small": true,
        &"prop.dense_bush": true,
        &"prop.thorn_bush": true,
        &"prop.rock_small": true,
        &"prop.rock_cluster": true,
        &"prop.mossy_rock": true,
    }
    var road_cells: Dictionary = {}
    for road: Dictionary in plan.roads:
        for value: Variant in road.get("corridor_cells", []):
            if typeof(value) == TYPE_VECTOR2I:
                road_cells[value] = true
    var fields: Dictionary = _field_cells(plan)
    for prop: Dictionary in plan.outdoor_props:
        var cell: Vector2i = prop.get("cell", Vector2i(-999999, -999999))
        var expected_id: String = "rural_open.natural.%d.%d" % [cell.x, cell.y]
        if String(prop.get("id", "")) != expected_id:
            return false
        if not allowed.has(StringName(prop.get("semantic", &""))):
            return false
        if road_cells.has(cell) or fields.has(cell):
            return false
        if _cell_on_planning_corridor(request, cell):
            return false
    return true

func _cell_on_planning_corridor(request: AreaGenerationRequest, cell: Vector2i) -> bool:
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("reservation_role", &"")) != &"corridor":
            continue
        var start: Vector2i = constraint.get("start", Vector2i.ZERO)
        var finish: Vector2i = constraint.get("end", Vector2i.ZERO)
        var half_width: int = int(constraint.get("width", 1)) / 2
        if start.y == finish.y and cell.x >= mini(start.x, finish.x) and cell.x <= maxi(start.x, finish.x) and absi(cell.y - start.y) <= half_width:
            return true
        if start.x == finish.x and cell.y >= mini(start.y, finish.y) and cell.y <= maxi(start.y, finish.y) and absi(cell.x - start.x) <= half_width:
            return true
    return false

func _ground_semantics(plan: GeneratedAreaPlan) -> Dictionary:
    var semantics: Dictionary = {}
    var priorities: Dictionary = {}
    for region: Dictionary in plan.ground_regions:
        var priority: int = int(region.get("priority", 0))
        var semantic: StringName = StringName(region.get("semantic", &""))
        if region.has("rect"):
            var rect: Rect2i = region.get("rect", Rect2i())
            for y in range(rect.position.y, rect.position.y + rect.size.y):
                for x in range(rect.position.x, rect.position.x + rect.size.x):
                    _set_ground_cell(semantics, priorities, Vector2i(x, y), semantic, priority)
        else:
            for value: Variant in region.get("cells", []):
                if typeof(value) == TYPE_VECTOR2I:
                    _set_ground_cell(semantics, priorities, value, semantic, priority)
    return semantics

func _set_ground_cell(semantics: Dictionary, priorities: Dictionary, cell: Vector2i, semantic: StringName, priority: int) -> void:
    if priorities.has(cell) and int(priorities[cell]) > priority:
        return
    priorities[cell] = priority
    semantics[cell] = semantic

func _prop_semantics(plan: GeneratedAreaPlan) -> Dictionary:
    var result: Dictionary = {}
    for prop: Dictionary in plan.outdoor_props:
        var cell: Vector2i = prop.get("cell", Vector2i(-999999, -999999))
        result[cell] = "%s|%s" % [String(prop.get("id", "")), String(prop.get("semantic", &""))]
    return result

func _overlaps_any_site(bounds: Rect2i, sites: Array[Dictionary]) -> bool:
    for site: Dictionary in sites:
        if _rects_overlap_positive(bounds, site.get("bounds", Rect2i())):
            return true
    return false

func _rects_overlap_positive(a: Rect2i, b: Rect2i) -> bool:
    var a_end: Vector2i = a.position + a.size
    var b_end: Vector2i = b.position + b.size
    return a.position.x < b_end.x and a_end.x > b.position.x and a.position.y < b_end.y and a_end.y > b.position.y

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var last: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(last)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error("RURAL_OPEN_COUNTRYSIDE_FAILURE: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("RURAL_OPEN_COUNTRYSIDE_GENERATION_SMOKE_OK")
        quit(0)
        return
    push_error("RURAL_OPEN_COUNTRYSIDE_GENERATION_SMOKE_FAILED count=%d" % failures.size())
    quit(1)