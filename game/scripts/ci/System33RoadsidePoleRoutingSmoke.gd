extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const LocalTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")
const NeighborhoodUtilityStateClass = preload("res://scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd")
const NeighborhoodInfrastructureClass = preload("res://scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd")
const IslandFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

const INVALID_CELL := Vector2i(2147483647, 2147483647)
const ROAD_POLE_SEARCH_RADIUS: int = 8
const ROAD_POLE_SPACING: int = 10
const SIDE_HOLD_POLES: int = 2

var _failures: Array[String] = []

func _initialize() -> void:
    _test_generated_access_surface_rejection()
    _test_side_aware_candidate_selection()
    _test_turn_continuity_policy()
    _test_materialized_trunk_does_not_immediately_cross_back()
    if _failures.is_empty():
        print("SYSTEM33_ROADSIDE_POLE_ROUTING_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SYSTEM33_ROADSIDE_POLE_ROUTING_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_generated_access_surface_rejection() -> void:
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.generate_global_plan()
    _check(plan != null and plan.is_generated(), "canonical island plan generated for access-surface regression")
    if plan == null or not plan.is_generated():
        return
    var topology: Dictionary = LocalTopologyPlannerClass.new().plan(plan)
    _check(bool(topology.get("ok", false)), "local utility topology plans for access-surface regression")
    if not bool(topology.get("ok", false)):
        return

    var exclusion_lookup: Dictionary = {}
    for value: Variant in topology.get("pole_exclusion_cells", []):
        if typeof(value) == TYPE_VECTOR2I:
            exclusion_lookup[value] = true
    _check(not exclusion_lookup.is_empty(), "generated driveways/parking access surfaces are carried into pole exclusions")

    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var utilities := NeighborhoodUtilityStateClass.new(topology)
    _check(utilities.initialize_from_plan(plan), "utility state initializes for access-surface regression")
    if not utilities.is_ready():
        return
    var infrastructure := NeighborhoodInfrastructureClass.new(world, mutations, plan, utilities, topology)
    _check(infrastructure.materialize(), "neighborhood infrastructure materializes for access-surface regression")
    if infrastructure.wire_edges().is_empty():
        return

    var road_pole_count: int = 0
    for entity_id: String in infrastructure.created_entity_ids():
        if entity_id.find(".road.") < 0 and entity_id.find(".customer.") < 0:
            continue
        var placement: WorldPlacement = world.placement(entity_id)
        if placement == null:
            continue
        road_pole_count += 1
        _check(not exclusion_lookup.has(placement.anchor), "power pole avoids generated driveway/parking access surface: %s" % entity_id)
    _check(road_pole_count > 0, "access-surface regression inspects real local power poles")

func _test_side_aware_candidate_selection() -> void:
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.generate_global_plan()
    if plan == null or not plan.is_generated():
        _check(false, "canonical island plan generated for side-selection regression")
        return
    var topology: Dictionary = LocalTopologyPlannerClass.new().plan(plan)
    if not bool(topology.get("ok", false)):
        _check(false, "local utility topology plans for side-selection regression")
        return

    var fixture: Dictionary = _find_two_sided_route_fixture(plan, topology)
    _check(not fixture.is_empty(), "found a straight generated road cell with legal pole positions on both sides")
    if fixture.is_empty():
        return
    var route_cell: Vector2i = fixture.get("route_cell", INVALID_CELL)
    var direction: Vector2i = fixture.get("direction", Vector2i.ZERO)
    var preferred_side: int = int(fixture.get("preferred_side", -1))
    var preferred_cell: Vector2i = fixture.get("preferred_cell", INVALID_CELL)
    _check(route_cell != INVALID_CELL and direction != Vector2i.ZERO and preferred_cell != INVALID_CELL, "side-selection fixture is valid")
    if route_cell == INVALID_CELL or direction == Vector2i.ZERO or preferred_cell == INVALID_CELL:
        return

    var blocked_topology: Dictionary = topology.duplicate(true)
    var blocked_cells: Array = blocked_topology.get("pole_exclusion_cells", [])
    blocked_cells.append(preferred_cell)
    blocked_topology["pole_exclusion_cells"] = blocked_cells
    var blocked_world := WorldStateClass.new()
    var blocked_materializer := NeighborhoodInfrastructureClass.new(
        blocked_world,
        WorldMutationClass.new(blocked_world),
        plan,
        null,
        blocked_topology
    )
    var replacement: Vector2i = blocked_materializer._find_roadside_available(
        route_cell,
        direction,
        preferred_side,
        {},
        ROAD_POLE_SEARCH_RADIUS,
        false
    )
    _check(replacement != INVALID_CELL and replacement != preferred_cell, "explicit generated access exclusion displaces a roadside pole")
    if replacement != INVALID_CELL:
        _check(_side_of(route_cell, replacement, direction) == preferred_side, "access exclusion keeps replacement pole on the same road side")

    var crossing_topology: Dictionary = topology.duplicate(true)
    var crossing_exclusions: Array = crossing_topology.get("pole_exclusion_cells", [])
    for y: int in range(-ROAD_POLE_SEARCH_RADIUS, ROAD_POLE_SEARCH_RADIUS + 1):
        for x: int in range(-ROAD_POLE_SEARCH_RADIUS, ROAD_POLE_SEARCH_RADIUS + 1):
            var candidate: Vector2i = route_cell + Vector2i(x, y)
            if _side_of(route_cell, candidate, direction) == preferred_side:
                crossing_exclusions.append(candidate)
    crossing_topology["pole_exclusion_cells"] = crossing_exclusions
    var crossing_world := WorldStateClass.new()
    var crossing_materializer := NeighborhoodInfrastructureClass.new(
        crossing_world,
        WorldMutationClass.new(crossing_world),
        plan,
        null,
        crossing_topology
    )
    var crossed_cell: Vector2i = crossing_materializer._find_roadside_available(
        route_cell,
        direction,
        preferred_side,
        {},
        ROAD_POLE_SEARCH_RADIUS,
        true
    )
    _check(crossed_cell != INVALID_CELL, "roadside placement can cross when the current side is genuinely blocked")
    if crossed_cell == INVALID_CELL:
        return
    var crossed_side: int = _side_of(route_cell, crossed_cell, direction)
    _check(crossed_side == -preferred_side, "forced roadside move crosses to the opposite side")

    var hold_materializer := NeighborhoodInfrastructureClass.new(
        WorldStateClass.new(),
        null,
        plan,
        null,
        topology
    )
    for pole_offset: int in range(1, SIDE_HOLD_POLES + 1):
        var next_route: Vector2i = route_cell + direction * (ROAD_POLE_SPACING * pole_offset)
        if not plan.bounds.has_point(next_route):
            break
        var held_cell: Vector2i = hold_materializer._find_roadside_available(
            next_route,
            direction,
            crossed_side,
            {},
            ROAD_POLE_SEARCH_RADIUS,
            false
        )
        _check(held_cell != INVALID_CELL, "post-crossing hold finds a legal pole on the new side at offset %d" % pole_offset)
        if held_cell != INVALID_CELL:
            _check(_side_of(next_route, held_cell, direction) == crossed_side, "post-crossing pole %d stays on the new side" % pole_offset)

func _test_turn_continuity_policy() -> void:
    var parent_state := {
        "side": -1,
        "direction": Vector2i(1, 0),
        "hold": SIDE_HOLD_POLES,
    }
    var child_route := Vector2i(20, 20)
    var child_direction := Vector2i(0, 1)
    # Simulate a real same-bank displacement near an incoming corner. The child's
    # direction-local sign differs from the parent's sign; copying the old sign is
    # exactly the behavior that produced visible road zig-zags at bends.
    var displaced_parent_pole := Vector2i(17, 10)
    var child_side: int = NeighborhoodInfrastructureClass._continuous_road_side(
        child_route,
        child_direction,
        displaced_parent_pole,
        parent_state
    )
    _check(child_side == 1, "road turn chooses the geometrically continuous physical bank instead of copying a direction-local sign")

    var straight_parent_state := {
        "side": -1,
        "direction": Vector2i(1, 0),
        "hold": SIDE_HOLD_POLES,
    }
    var straight_side: int = NeighborhoodInfrastructureClass._continuous_road_side(
        Vector2i(20, 10),
        Vector2i(1, 0),
        Vector2i(10, 8),
        straight_parent_state
    )
    _check(straight_side == -1, "straight feeder preserves the existing physical roadside bank")

func _test_materialized_trunk_does_not_immediately_cross_back() -> void:
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.generate_global_plan()
    if plan == null or not plan.is_generated():
        _check(false, "canonical island plan generated for full trunk side regression")
        return
    var topology: Dictionary = LocalTopologyPlannerClass.new().plan(plan)
    if not bool(topology.get("ok", false)):
        _check(false, "local utility topology plans for full trunk side regression")
        return
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var utilities := NeighborhoodUtilityStateClass.new(topology)
    if not utilities.initialize_from_plan(plan):
        _check(false, "utility state initializes for full trunk side regression")
        return
    var infrastructure := NeighborhoodInfrastructureClass.new(world, mutations, plan, utilities, topology)
    _check(infrastructure.materialize(), "full neighborhood infrastructure materializes for trunk side regression")
    if infrastructure.wire_edges().is_empty():
        return

    var outgoing: Dictionary = {}
    var trunk_edges: Array[Dictionary] = []
    for wire: Dictionary in infrastructure.wire_edges():
        if StringName(wire.get("wire_role", &"")) != &"shared_trunk":
            continue
        trunk_edges.append(wire)
        var start_id: String = String(wire.get("start_id", ""))
        var edges: Array = outgoing.get(start_id, [])
        edges.append(wire)
        outgoing[start_id] = edges

    var crossing_count: int = 0
    for edge: Dictionary in trunk_edges:
        var route_start: Vector2i = edge.get("route_start_cell", INVALID_CELL)
        var route_end: Vector2i = edge.get("route_end_cell", INVALID_CELL)
        var direction: Vector2i = _cardinal_direction(route_start, route_end)
        if direction == Vector2i.ZERO:
            continue
        var start_placement: WorldPlacement = world.placement(String(edge.get("start_id", "")))
        var end_placement: WorldPlacement = world.placement(String(edge.get("end_id", "")))
        if start_placement == null or end_placement == null:
            continue
        var start_side: int = _side_of(route_start, start_placement.anchor, direction)
        var end_side: int = _side_of(route_end, end_placement.anchor, direction)
        if start_side == 0 or end_side == 0 or start_side == end_side:
            continue
        crossing_count += 1
        var held_services: Array[String] = _service_ids(edge)
        var held_state := {
            "side": end_side,
            "direction": direction,
            "hold": SIDE_HOLD_POLES,
        }
        _assert_hold_from(
            String(edge.get("end_id", "")),
            SIDE_HOLD_POLES,
            outgoing,
            world,
            held_services,
            held_state
        )
    print("SYSTEM33_ROADSIDE_CROSSINGS=%d" % crossing_count)
    _check(not trunk_edges.is_empty(), "full trunk side regression inspects real shared feeder spans")

func _assert_hold_from(
    start_id: String,
    remaining: int,
    outgoing: Dictionary,
    world: WorldState,
    held_services: Array[String],
    parent_state: Dictionary
) -> void:
    if remaining <= 0 or held_services.is_empty():
        return
    for edge_value: Variant in outgoing.get(start_id, []):
        if typeof(edge_value) != TYPE_DICTIONARY:
            continue
        var edge: Dictionary = edge_value
        var continuing_services: Array[String] = _service_intersection(held_services, _service_ids(edge))
        if continuing_services.is_empty():
            continue
        var route_start: Vector2i = edge.get("route_start_cell", INVALID_CELL)
        var route_end: Vector2i = edge.get("route_end_cell", INVALID_CELL)
        var edge_direction: Vector2i = _cardinal_direction(route_start, route_end)
        if edge_direction == Vector2i.ZERO:
            continue
        var start_placement: WorldPlacement = world.placement(String(edge.get("start_id", "")))
        var end_id: String = String(edge.get("end_id", ""))
        var end_placement: WorldPlacement = world.placement(end_id)
        if start_placement == null or end_placement == null:
            continue
        var expected_side: int = NeighborhoodInfrastructureClass._continuous_road_side(
            route_end,
            edge_direction,
            start_placement.anchor,
            parent_state
        )
        var end_side: int = _side_of(route_end, end_placement.anchor, edge_direction)
        if expected_side != 0 and end_side != 0:
            _check(
                end_side == expected_side,
                "shared trunk stays on the same physical roadside bank for %d poles after a crossing, including through road turns" % SIDE_HOLD_POLES
            )
        var child_state := {
            "side": end_side,
            "direction": edge_direction,
            "hold": maxi(0, int(parent_state.get("hold", remaining)) - 1),
        }
        _assert_hold_from(
            end_id,
            remaining - 1,
            outgoing,
            world,
            continuing_services,
            child_state
        )

func _service_ids(edge: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for value: Variant in edge.get("service_settlement_ids", []):
        var service_id: String = String(value).strip_edges()
        if not service_id.is_empty() and not result.has(service_id):
            result.append(service_id)
    result.sort()
    return result

func _service_intersection(a: Array[String], b: Array[String]) -> Array[String]:
    var result: Array[String] = []
    for value: String in a:
        if b.has(value):
            result.append(value)
    return result

func _find_two_sided_route_fixture(plan: GeneratedGlobalWorldPlan, topology: Dictionary) -> Dictionary:
    var world := WorldStateClass.new()
    var materializer := NeighborhoodInfrastructureClass.new(world, WorldMutationClass.new(world), plan, null, topology)
    for road_value: Variant in topology.get("local_roads", []):
        if typeof(road_value) != TYPE_DICTIONARY:
            continue
        var road: Dictionary = road_value
        var start: Vector2i = road.get("start", INVALID_CELL)
        var finish: Vector2i = road.get("end", INVALID_CELL)
        var direction: Vector2i = _cardinal_direction(start, finish)
        if direction == Vector2i.ZERO:
            continue
        var length: int = absi(finish.x - start.x) + absi(finish.y - start.y)
        if length < ROAD_POLE_SPACING * 3:
            continue
        for distance: int in range(ROAD_POLE_SPACING, length - ROAD_POLE_SPACING):
            var route_cell: Vector2i = start + direction * distance
            var negative: Vector2i = materializer._find_roadside_available(route_cell, direction, -1, {}, ROAD_POLE_SEARCH_RADIUS, false)
            var positive: Vector2i = materializer._find_roadside_available(route_cell, direction, 1, {}, ROAD_POLE_SEARCH_RADIUS, false)
            if negative != INVALID_CELL and positive != INVALID_CELL:
                return {
                    "route_cell": route_cell,
                    "direction": direction,
                    "preferred_side": -1,
                    "preferred_cell": negative,
                    "opposite_cell": positive,
                }
    return {}

static func _cardinal_direction(start: Vector2i, finish: Vector2i) -> Vector2i:
    var delta: Vector2i = finish - start
    if delta.x != 0 and delta.y == 0:
        return Vector2i(signi(delta.x), 0)
    if delta.y != 0 and delta.x == 0:
        return Vector2i(0, signi(delta.y))
    return Vector2i.ZERO

static func _same_axis(a: Vector2i, b: Vector2i) -> bool:
    if a == Vector2i.ZERO or b == Vector2i.ZERO:
        return false
    return (a.x != 0 and b.x != 0) or (a.y != 0 and b.y != 0)

static func _side_of(route_cell: Vector2i, support_cell: Vector2i, direction: Vector2i) -> int:
    if route_cell == INVALID_CELL or support_cell == INVALID_CELL or direction == Vector2i.ZERO:
        return 0
    var offset: Vector2i = support_cell - route_cell
    return signi(direction.x * offset.y - direction.y * offset.x)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
