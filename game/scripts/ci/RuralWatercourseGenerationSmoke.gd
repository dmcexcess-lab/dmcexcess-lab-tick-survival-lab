extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")
const ProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const MaterializerClass = preload("res://scripts/generation/areas/AreaMaterializationCoordinator.gd")
const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const TraversalPolicyClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const CountrysideCatalogClass = preload("res://scripts/streaming/CountrysideSourceCatalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var global_planner: GlobalWorldPlanner = GlobalPlannerClass.new()
    var global_plan: GeneratedGlobalWorldPlan = global_planner.generate(GlobalFixtureClass.request())
    _check(global_plan != null and global_plan.is_generated(), "canonical System 00D v6 world generates before watercourse projection")
    if global_plan == null or not global_plan.is_generated():
        _finish()
        return

    var replay: GeneratedGlobalWorldPlan = global_planner.generate(GlobalFixtureClass.request())
    _check(replay.is_generated() and replay.signature() == global_plan.signature(), "System 00D v6 signature remains exact under System 20D consumption")
    _check(global_plan.profile_version == 6, "System 20D consumes System 00D profile v6 without changing it")

    var projector: System20AreaRequestProjector = ProjectorClass.new()
    var generator: LocalAreaGenerator = GeneratorClass.new()
    var validator: GeneratedAreaValidator = ValidatorClass.new()
    var hydrology: GlobalHydrologyQuery = HydrologyQueryClass.new()

    _test_profile_contract(generator)
    _check(not global_plan.bridge_intents.is_empty(), "canonical System 00D fixture exposes at least one real bridge intent")
    if global_plan.bridge_intents.is_empty():
        _finish()
        return

    var bridge: Dictionary = global_plan.bridge_intents[0]
    var full_deck: Rect2i = hydrology.bridge_deck_rect(bridge)
    _check(_bridge_deck_geometry_is_exact(bridge, full_deck), "bridge_deck_rect is exact road-width x river-width geometry centered on the global crossing")

    var bridge_bounds: Rect2i = _find_bridge_test_bounds(global_plan, projector, hydrology, bridge)
    _check(bridge_bounds.size.x > 0, "a canonical bridge-bearing watercourse rectangle can be projected")
    var bridge_request: AreaGenerationRequest = null
    var bridge_plan: GeneratedAreaPlan = null
    if bridge_bounds.size.x > 0:
        var bridge_projection: Dictionary = projector.project_watercourse_bounds(global_plan, "area.test.watercourse.bridge", bridge_bounds)
        _check(bool(bridge_projection.get("ok", false)), "bridge-bearing watercourse projection succeeds")
        bridge_request = bridge_projection.get("request") as AreaGenerationRequest
        _check(bridge_request != null and bridge_request.is_valid(), "bridge-bearing projected request is structurally valid")
        if bridge_request != null and bridge_request.is_valid():
            _check(_request_hydrology_matches_global(bridge_request, global_plan, hydrology), "projected bridge/river IDs, widths, axes, ordinals and geometry exactly match System 00D")
            bridge_plan = generator.generate(bridge_request)
            _check(bridge_plan.is_generated(), "bridge-bearing Rural Watercourse Candidate 001 plan generates")
            if bridge_plan.is_generated():
                _check(bool(validator.validate(bridge_request, bridge_plan).get("ok", false)), "bridge-bearing plan passes generic System 20 validation")
                _check(bridge_plan.area_profile_version == 1 and bridge_plan.environment_profile_version == 3, "bridge-bearing plan records rural.watercourse v1 + temperate.rural v3")
                _check(_watercourse_has_no_settlement_content(bridge_plan), "watercourse plan creates no local roads, parcels, blocks, buildings or outdoor props")
                _check(_bridge_plan_semantics_valid(bridge_request, bridge_plan), "bridge plan is water except exactly authorized bridge-deck cells")
                var bridge_replay: GeneratedAreaPlan = generator.generate(bridge_request)
                _check(bridge_replay.is_generated() and bridge_replay.signature() == bridge_plan.signature(), "same watercourse request replays with identical signature")
                _test_road_without_bridge_authorization(bridge_request, generator)
                _test_materialization_and_traversal(bridge_request, bridge_plan)
                _test_bridge_split_combined(global_plan, projector, generator, bridge_bounds)

        var rural_open_result: Dictionary = projector.project_rural_open_bounds(global_plan, "area.test.rural_open.bridge_reject", bridge_bounds)
        _check(not bool(rural_open_result.get("ok", false)) and String(rural_open_result.get("failure_reason", "")) == "rural_open_hydrology_not_materializable", "existing rural.open projection still rejects the real bridge/river window")

    var river_only_bounds: Rect2i = _find_river_only_bounds(global_plan, projector, hydrology)
    _check(river_only_bounds.size.x > 0, "a canonical river-only physical rectangle can be projected")
    if river_only_bounds.size.x > 0:
        var river_projection: Dictionary = projector.project_watercourse_bounds(global_plan, "area.test.watercourse.river_only", river_only_bounds)
        var river_request: AreaGenerationRequest = river_projection.get("request") as AreaGenerationRequest
        _check(bool(river_projection.get("ok", false)) and river_request != null, "river-only watercourse projection succeeds")
        if river_request != null:
            var river_plan: GeneratedAreaPlan = generator.generate(river_request)
            _check(river_plan.is_generated(), "river-only watercourse plan generates")
            if river_plan.is_generated():
                _check(_only_water_ground(river_plan), "river-only plan contains water ground and no invented bridge deck")
                _check(_watercourse_has_no_settlement_content(river_plan), "river-only plan creates no settlement morphology")
            _test_river_split_combined(global_plan, projector, generator, river_only_bounds)

    var mixed_bounds: Rect2i = _find_mixed_water_dry_bounds(global_plan, projector, hydrology)
    _check(mixed_bounds.size.x > 0, "a mixed dry/water rejection rectangle can be discovered")
    if mixed_bounds.size.x > 0:
        var mixed: Dictionary = projector.project_watercourse_bounds(global_plan, "area.test.watercourse.mixed_reject", mixed_bounds)
        _check(not bool(mixed.get("ok", false)) and String(mixed.get("failure_reason", "")) == "watercourse_bounds_not_fully_river", "mixed dry/water request fails instead of painting dry land as water")

    var catalog: CountrysideSourceCatalog = CountrysideCatalogClass.new(global_plan)
    _check(catalog.is_ready() and catalog.catalog_version() == 1, "00F2 countryside catalog remains v1 and valid")
    if bridge_bounds.size.x > 0:
        var known_river_cell: Vector2i = _find_water_cell(bridge_plan) if bridge_plan != null and bridge_plan.is_generated() else bridge_bounds.position
        _check(catalog.descriptor_for_cell(known_river_cell).is_empty(), "00F2 still excludes physical river corridor cells from dry countryside ownership")

    _finish()

func _test_profile_contract(generator: LocalAreaGenerator) -> void:
    var profiles: AreaProfileCatalog = ProfilesClass.new()
    var watercourse: Dictionary = profiles.profile(&"rural.watercourse")
    _check(not watercourse.is_empty() and int(watercourse.get("version", 0)) == 1, "rural.watercourse v1 is registered")
    _check(StringName(watercourse.get("river_ground_semantic", &"")) == &"ground.water_river", "rural.watercourse uses semantic river water terrain")
    _check(generator.area_profile_ids().has(&"rural.watercourse"), "LocalAreaGenerator exposes rural.watercourse")
    _check(int(profiles.profile(&"rural.crossroads").get("version", 0)) == 5, "rural.crossroads remains v5")
    _check(int(profiles.profile(&"smalltown.center").get("version", 0)) == 2, "smalltown.center remains v2")
    _check(int(profiles.profile(&"rural.scattered").get("version", 0)) == 1, "rural.scattered remains v1")
    _check(int(profiles.profile(&"rural.open").get("version", 0)) == 1, "rural.open remains v1")

func _bridge_deck_geometry_is_exact(bridge: Dictionary, deck: Rect2i) -> bool:
    var road_width: int = int(bridge.get("road_width", 0))
    var river_width: int = int(bridge.get("river_width", 0))
    var axis: StringName = StringName(bridge.get("bridge_axis", &""))
    var cell: Vector2i = bridge.get("cell", Vector2i.ZERO)
    if axis == &"horizontal":
        return deck.size == Vector2i(river_width, road_width) \
            and deck.position == cell - Vector2i(river_width / 2, road_width / 2)
    if axis == &"vertical":
        return deck.size == Vector2i(road_width, river_width) \
            and deck.position == cell - Vector2i(road_width / 2, river_width / 2)
    return false

func _find_bridge_test_bounds(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    hydrology: GlobalHydrologyQuery,
    bridge: Dictionary
) -> Rect2i:
    var deck: Rect2i = hydrology.bridge_deck_rect(bridge)
    if deck.size.x <= 0 or deck.size.y <= 0:
        return Rect2i()
    var axis: StringName = StringName(bridge.get("bridge_axis", &""))
    for pad in [6, 4, 3, 2, 1, 0]:
        var candidate: Rect2i = deck
        if axis == &"horizontal":
            candidate = Rect2i(deck.position - Vector2i(0, pad), deck.size + Vector2i(0, pad * 2))
        else:
            candidate = Rect2i(deck.position - Vector2i(pad, 0), deck.size + Vector2i(pad * 2, 0))
        if not _rect_inside(global_plan.bounds, candidate):
            continue
        var projected: Dictionary = projector.project_watercourse_bounds(global_plan, "area.scan.watercourse.bridge.%d" % pad, candidate)
        if bool(projected.get("ok", false)):
            return candidate
    return Rect2i()

func _find_river_only_bounds(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    hydrology: GlobalHydrologyQuery
) -> Rect2i:
    var bridge_decks: Array[Rect2i] = []
    for bridge: Dictionary in global_plan.bridge_intents:
        bridge_decks.append(hydrology.bridge_deck_rect(bridge))
    for river: Dictionary in global_plan.river_segments:
        var corridor: Rect2i = hydrology.segment_corridor_rect(river)
        if corridor.size.x <= 0 or corridor.size.y <= 0:
            continue
        var max_x: int = corridor.position.x + corridor.size.x - 3
        var max_y: int = corridor.position.y + corridor.size.y - 3
        for y in range(corridor.position.y, max_y + 1):
            for x in range(corridor.position.x, max_x + 1):
                var candidate := Rect2i(x, y, 3, 3)
                if not _rect_inside(global_plan.bounds, candidate) or _overlaps_any(candidate, bridge_decks):
                    continue
                var projected: Dictionary = projector.project_watercourse_bounds(global_plan, "area.scan.watercourse.river.%d.%d" % [x, y], candidate)
                if not bool(projected.get("ok", false)):
                    continue
                var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
                if request != null and _bridge_records(request).is_empty():
                    return candidate
    return Rect2i()

func _find_mixed_water_dry_bounds(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    hydrology: GlobalHydrologyQuery
) -> Rect2i:
    for river: Dictionary in global_plan.river_segments:
        var corridor: Rect2i = hydrology.segment_corridor_rect(river)
        if corridor.size.x <= 0 or corridor.size.y <= 0:
            continue
        var candidates: Array[Rect2i] = []
        if corridor.size.x >= corridor.size.y:
            var x: int = corridor.position.x + corridor.size.x / 2
            candidates.append(Rect2i(x, corridor.position.y - 1, 1, 2))
            candidates.append(Rect2i(x, corridor.position.y + corridor.size.y - 1, 1, 2))
        else:
            var y: int = corridor.position.y + corridor.size.y / 2
            candidates.append(Rect2i(corridor.position.x - 1, y, 2, 1))
            candidates.append(Rect2i(corridor.position.x + corridor.size.x - 1, y, 2, 1))
        for candidate: Rect2i in candidates:
            if not _rect_inside(global_plan.bounds, candidate):
                continue
            var projected: Dictionary = projector.project_watercourse_bounds(global_plan, "area.scan.watercourse.mixed.%d.%d" % [candidate.position.x, candidate.position.y], candidate)
            if not bool(projected.get("ok", false)) and String(projected.get("failure_reason", "")) == "watercourse_bounds_not_fully_river":
                return candidate
    return Rect2i()

func _request_hydrology_matches_global(
    request: AreaGenerationRequest,
    global_plan: GeneratedGlobalWorldPlan,
    hydrology: GlobalHydrologyQuery
) -> bool:
    for feature: Dictionary in request.inherited_hydrology:
        var kind: StringName = StringName(feature.get("kind", &""))
        if kind == &"river_segment":
            var source: Dictionary = _river_by_segment_id(global_plan, String(feature.get("segment_id", "")))
            if source.is_empty():
                return false
            if String(feature.get("river_id", "")) != String(source.get("river_id", "")) \
                or feature.get("start", Vector2i.ZERO) != source.get("start", Vector2i.ZERO) \
                or feature.get("end", Vector2i.ZERO) != source.get("end", Vector2i.ZERO) \
                or int(feature.get("width", 0)) != int(source.get("width", 0)) \
                or int(feature.get("ordinal", -1)) != int(source.get("ordinal", -2)):
                return false
            if feature.get("corridor_rect", Rect2i()) != _rect_intersection(hydrology.segment_corridor_rect(source), request.bounds):
                return false
        elif kind == &"bridge_intent":
            var source_bridge: Dictionary = _bridge_by_id(global_plan, String(feature.get("id", "")))
            if source_bridge.is_empty():
                return false
            for key: String in ["road_id", "route_id", "river_id", "river_segment_id", "bridge_axis", "road_width", "river_width"]:
                if feature.get(key) != source_bridge.get(key):
                    return false
            if feature.get("cell", Vector2i.ZERO) != source_bridge.get("cell", Vector2i.ZERO):
                return false
            if feature.get("deck_rect", Rect2i()) != _rect_intersection(hydrology.bridge_deck_rect(source_bridge), request.bounds):
                return false
        else:
            return false
    return true

func _watercourse_has_no_settlement_content(plan: GeneratedAreaPlan) -> bool:
    if not plan.reservations.is_empty() or not plan.blocks.is_empty() or not plan.parcels.is_empty() \
        or not plan.building_requests.is_empty() or not plan.outdoor_props.is_empty():
        return false
    for road: Dictionary in plan.roads:
        if not bool(road.get("inherited", false)):
            return false
    return true

func _bridge_plan_semantics_valid(request: AreaGenerationRequest, plan: GeneratedAreaPlan) -> bool:
    var final_ground: Dictionary = _ground_semantics(plan)
    var authorized: Dictionary = {}
    for bridge: Dictionary in _bridge_features(plan):
        var deck: Rect2i = bridge.get("deck_rect", Rect2i())
        for y in range(deck.position.y, deck.position.y + deck.size.y):
            for x in range(deck.position.x, deck.position.x + deck.size.x):
                authorized[Vector2i(x, y)] = true
    for y in range(request.bounds.position.y, request.bounds.position.y + request.bounds.size.y):
        for x in range(request.bounds.position.x, request.bounds.position.x + request.bounds.size.x):
            var cell := Vector2i(x, y)
            var expected: StringName = &"ground.road_plain" if authorized.has(cell) else &"ground.water_river"
            if StringName(final_ground.get(cell, &"")) != expected:
                return false
    return true

func _only_water_ground(plan: GeneratedAreaPlan) -> bool:
    if not _bridge_features(plan).is_empty():
        return false
    var ground: Dictionary = _ground_semantics(plan)
    if ground.size() != plan.bounds.size.x * plan.bounds.size.y:
        return false
    for semantic: Variant in ground.values():
        if StringName(semantic) != &"ground.water_river":
            return false
    return true

func _test_road_without_bridge_authorization(
    bridge_request: AreaGenerationRequest,
    generator: LocalAreaGenerator
) -> void:
    var river_only_hydrology: Array[Dictionary] = []
    for feature: Dictionary in bridge_request.inherited_hydrology:
        if StringName(feature.get("kind", &"")) == &"river_segment":
            river_only_hydrology.append(feature.duplicate(true))
    var no_bridge_request: AreaGenerationRequest = AreaRequestClass.new(
        "area.test.watercourse.road_without_bridge",
        bridge_request.seed,
        bridge_request.bounds,
        bridge_request.area_profile_id,
        bridge_request.environment_profile_id,
        bridge_request.inherited_roads,
        [],
        [],
        [],
        river_only_hydrology
    )
    _check(no_bridge_request.is_valid(), "road-without-bridge synthetic request remains structurally valid")
    if not no_bridge_request.is_valid():
        return
    var plan: GeneratedAreaPlan = generator.generate(no_bridge_request)
    _check(plan.is_generated(), "road-without-bridge watercourse plan generates")
    if plan.is_generated():
        _check(_only_water_ground(plan), "regional road overlap alone never authorizes bridge-deck ground")

func _test_materialization_and_traversal(
    request: AreaGenerationRequest,
    plan: GeneratedAreaPlan
) -> void:
    var world: WorldState = WorldStateClass.new()
    var mutations: WorldMutationService = WorldMutationClass.new(world)
    var doors: DoorStateStore = DoorStateClass.new()
    var door_mutations: DoorStateMutationService = DoorMutationClass.new(doors, world)
    var materializer: AreaMaterializationCoordinator = MaterializerClass.new(world, mutations, doors, door_mutations)
    _check(materializer.is_ready(), "existing area materializer is ready without a hydrology-specific state store")
    _check(materializer.materialize(request, plan), "existing area materializer writes System 20D ground transactionally")
    var bridge_cell: Vector2i = _find_bridge_cell(plan)
    var water_cell: Vector2i = _find_water_cell(plan)
    _check(bridge_cell != Vector2i(-999999, -999999) and world.terrain_at(bridge_cell) == &"ground.road_plain", "materialized bridge deck is persistent road terrain in WHAT")
    _check(water_cell != Vector2i(-999999, -999999) and world.terrain_at(water_cell) == &"ground.water_river", "materialized river is persistent water terrain in WHAT")

    var policy: MovementTraversalPolicy = TraversalPolicyClass.new()
    _check(policy.register_terrain(&"ground.water_river", false), "existing movement policy can explicitly classify river water as blocked")
    _check(policy.register_terrain(&"ground.road_plain", true, 10), "existing movement policy can classify bridge road terrain as traversable")
    _check(policy.terrain_walk_ticks("actor.test", [&"ground.water_river"]) == 0, "water is non-traversable without changing Movement source")
    _check(policy.terrain_walk_ticks("actor.test", [&"ground.road_plain"]) == 10, "bridge deck retains ordinary traversable road timing")

func _test_river_split_combined(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    generator: LocalAreaGenerator,
    bounds: Rect2i
) -> void:
    var pair: Dictionary = _split_bounds(bounds)
    if pair.is_empty():
        _check(false, "river-only bounds are splittable for seam test")
        return
    _test_split_combined_pair("river", pair, global_plan, projector, generator)

func _test_bridge_split_combined(
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    generator: LocalAreaGenerator,
    bounds: Rect2i
) -> void:
    var pair: Dictionary = _split_bounds(bounds)
    if pair.is_empty():
        _check(false, "bridge bounds are splittable for seam test")
        return
    _test_split_combined_pair("bridge", pair, global_plan, projector, generator)

func _test_split_combined_pair(
    label: String,
    pair: Dictionary,
    global_plan: GeneratedGlobalWorldPlan,
    projector: System20AreaRequestProjector,
    generator: LocalAreaGenerator
) -> void:
    var first_bounds: Rect2i = pair.get("first", Rect2i())
    var second_bounds: Rect2i = pair.get("second", Rect2i())
    var combined_bounds: Rect2i = pair.get("combined", Rect2i())
    var first_projection: Dictionary = projector.project_watercourse_bounds(global_plan, "area.test.watercourse.%s.split.first" % label, first_bounds)
    var second_projection: Dictionary = projector.project_watercourse_bounds(global_plan, "area.test.watercourse.%s.split.second" % label, second_bounds)
    var combined_projection: Dictionary = projector.project_watercourse_bounds(global_plan, "area.test.watercourse.%s.split.combined" % label, combined_bounds)
    _check(bool(first_projection.get("ok", false)) and bool(second_projection.get("ok", false)) and bool(combined_projection.get("ok", false)), "%s split and combined watercourse bounds all project" % label)
    if not bool(first_projection.get("ok", false)) or not bool(second_projection.get("ok", false)) or not bool(combined_projection.get("ok", false)):
        return
    var first: GeneratedAreaPlan = generator.generate(first_projection.get("request") as AreaGenerationRequest)
    var second: GeneratedAreaPlan = generator.generate(second_projection.get("request") as AreaGenerationRequest)
    var combined: GeneratedAreaPlan = generator.generate(combined_projection.get("request") as AreaGenerationRequest)
    _check(first.is_generated() and second.is_generated() and combined.is_generated(), "%s split and combined watercourse plans generate" % label)
    if not first.is_generated() or not second.is_generated() or not combined.is_generated():
        return
    var split: Dictionary = _ground_semantics(first)
    split.merge(_ground_semantics(second), true)
    _check(split == _ground_semantics(combined), "%s split-vs-combined final semantic terrain is identical by global cell" % label)

func _split_bounds(bounds: Rect2i) -> Dictionary:
    if bounds.size.x >= bounds.size.y and bounds.size.x >= 2:
        var first_width: int = bounds.size.x / 2
        return {
            "first": Rect2i(bounds.position, Vector2i(first_width, bounds.size.y)),
            "second": Rect2i(bounds.position + Vector2i(first_width, 0), Vector2i(bounds.size.x - first_width, bounds.size.y)),
            "combined": bounds,
        }
    if bounds.size.y >= 2:
        var first_height: int = bounds.size.y / 2
        return {
            "first": Rect2i(bounds.position, Vector2i(bounds.size.x, first_height)),
            "second": Rect2i(bounds.position + Vector2i(0, first_height), Vector2i(bounds.size.x, bounds.size.y - first_height)),
            "combined": bounds,
        }
    return {}

func _ground_semantics(plan: GeneratedAreaPlan) -> Dictionary:
    var ordered: Array[Dictionary] = plan.ground_regions.duplicate(true)
    ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ap: int = int(a.get("priority", 0))
        var bp: int = int(b.get("priority", 0))
        if ap != bp:
            return ap < bp
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    var result: Dictionary = {}
    for region: Dictionary in ordered:
        var semantic: StringName = StringName(region.get("semantic", &""))
        if region.has("rect"):
            var rect: Rect2i = region.get("rect", Rect2i())
            for y in range(rect.position.y, rect.position.y + rect.size.y):
                for x in range(rect.position.x, rect.position.x + rect.size.x):
                    result[Vector2i(x, y)] = semantic
        else:
            for value: Variant in region.get("cells", []):
                if typeof(value) == TYPE_VECTOR2I:
                    result[value] = semantic
    return result

func _bridge_records(request: AreaGenerationRequest) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for feature: Dictionary in request.inherited_hydrology:
        if StringName(feature.get("kind", &"")) == &"bridge_intent":
            result.append(feature)
    return result

func _bridge_features(plan: GeneratedAreaPlan) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for feature: Dictionary in plan.hydrology_features:
        if StringName(feature.get("kind", &"")) == &"bridge_intent":
            result.append(feature)
    return result

func _find_bridge_cell(plan: GeneratedAreaPlan) -> Vector2i:
    for bridge: Dictionary in _bridge_features(plan):
        var deck: Rect2i = bridge.get("deck_rect", Rect2i())
        if deck.size.x > 0 and deck.size.y > 0:
            return deck.position
    return Vector2i(-999999, -999999)

func _find_water_cell(plan: GeneratedAreaPlan) -> Vector2i:
    var ground: Dictionary = _ground_semantics(plan)
    var cells: Array = ground.keys()
    cells.sort_custom(func(a: Variant, b: Variant) -> bool:
        var ca: Vector2i = a
        var cb: Vector2i = b
        if ca.y != cb.y:
            return ca.y < cb.y
        return ca.x < cb.x
    )
    for value: Variant in cells:
        var cell: Vector2i = value
        if StringName(ground[cell]) == &"ground.water_river":
            return cell
    return Vector2i(-999999, -999999)

func _river_by_segment_id(global_plan: GeneratedGlobalWorldPlan, segment_id: String) -> Dictionary:
    for river: Dictionary in global_plan.river_segments:
        if String(river.get("segment_id", "")) == segment_id:
            return river
    return {}

func _bridge_by_id(global_plan: GeneratedGlobalWorldPlan, bridge_id: String) -> Dictionary:
    for bridge: Dictionary in global_plan.bridge_intents:
        if String(bridge.get("id", "")) == bridge_id:
            return bridge
    return {}

func _overlaps_any(rect: Rect2i, others: Array[Rect2i]) -> bool:
    for other: Rect2i in others:
        if _rects_overlap_positive(rect, other):
            return true
    return false

func _rect_intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start_x: int = maxi(a.position.x, b.position.x)
    var start_y: int = maxi(a.position.y, b.position.y)
    var end_x: int = mini(a.position.x + a.size.x, b.position.x + b.size.x)
    var end_y: int = mini(a.position.y + a.size.y, b.position.y + b.size.y)
    if end_x <= start_x or end_y <= start_y:
        return Rect2i()
    return Rect2i(Vector2i(start_x, start_y), Vector2i(end_x - start_x, end_y - start_y))

func _rects_overlap_positive(a: Rect2i, b: Rect2i) -> bool:
    var overlap: Rect2i = _rect_intersection(a, b)
    return overlap.size.x > 0 and overlap.size.y > 0

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(inner_max)

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("RURAL_WATERCOURSE_CHECK_FAILED: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("RURAL_WATERCOURSE_GENERATION_SMOKE_OK")
        quit(0)
        return
    push_error("RURAL_WATERCOURSE_GENERATION_SMOKE_FAIL:%s" % " | ".join(failures))
    quit(1)
