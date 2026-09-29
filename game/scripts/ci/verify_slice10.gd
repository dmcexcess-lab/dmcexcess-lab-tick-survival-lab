extends SceneTree

const Fixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const WorldRequest = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const WorldProfiles = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")
const IslandPlanner = preload("res://scripts/generation/world/IslandWorldPlanner.gd")
const SurfaceCatalog = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")
const SurfaceProjection = preload("res://scripts/generation/integration/IslandSurfaceRequestProjection.gd")
const SurfaceGenerator = preload("res://scripts/generation/areas/IslandSurfaceAreaGenerator.gd")
const SiteProjection = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const LocalGenerator = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const AreaProfiles = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const VehicleProfiles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const VehicleHeadingClass = preload("res://scripts/simulation/vehicles/VehicleHeading.gd")
const VehicleActions = preload("res://scripts/simulation/vehicles/VehicleActionService.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var reference_plan = _verify_road_hierarchy(Fixture.SEED)
    _verify_road_hierarchy(Fixture.SEED + 137)
    if reference_plan != null and reference_plan.is_generated():
        _verify_production_road_surfaces(reference_plan)
        _verify_local_dirt(reference_plan)
    await _verify_vehicle_production_route()
    _finish()

func _verify_road_hierarchy(seed: int):
    var request := WorldRequest.new(Fixture.WORLD_ID, seed, Fixture.BOUNDS, WorldProfiles.TEMPERATE_ISLAND_REGION)
    var plan = IslandPlanner.new().generate(request)
    _check(plan != null and plan.is_generated(), "island generates seed=%d" % seed)
    if plan == null or not plan.is_generated():
        return plan

    var arterial_routes: Dictionary = {}
    var two_lane := 0
    var gravel := 0
    for road: Dictionary in plan.road_segments:
        var route_id := String(road.get("route_id", ""))
        var road_type := StringName(road.get("road_type", &""))
        if route_id.begins_with("route.island.arterial."):
            arterial_routes[route_id] = true
            _check(road_type == &"four_lane", "arterial segment remains four-lane")
            _check(int(road.get("lane_count", 0)) == 4, "arterial lane count is four")
            _check(StringName(road.get("surface_family", &"")) == &"paved_centerline", "arterial is paved")
            _check(bool(road.get("paint_centerline", false)), "arterial receives markings")
        elif road_type == &"two_lane":
            two_lane += 1
            _check(StringName(road.get("surface_family", &"")) == &"paved_centerline" and bool(road.get("paint_centerline", false)), "secondary paved road metadata is coherent")
        elif road_type == &"gravel":
            gravel += 1
            _check(StringName(road.get("surface_family", &"")) == &"rural_gravel" and not bool(road.get("paint_centerline", true)), "gravel road has no paint")
    _check(arterial_routes.size() == 4, "four cross-island arterial routes exist")
    _check(two_lane > 0, "two-lane developed access exists")
    _check(gravel > 0, "gravel rural access exists")

    for settlement: Dictionary in plan.settlements:
        var center: Vector2i = settlement.get("center", Vector2i(-999999, -999999))
        var connected := false
        for road: Dictionary in plan.road_segments:
            if _point_on_segment(center, road.get("start", Vector2i.ZERO), road.get("end", Vector2i.ZERO)):
                connected = true
                break
        _check(connected, "settlement connects to road network: %s" % String(settlement.get("id", "")))
    return plan

func _verify_production_road_surfaces(plan) -> void:
    var catalog = SurfaceCatalog.new(plan)
    _check(catalog.is_ready(), "island surface source catalog is ready")
    if not catalog.is_ready():
        return
    var projection = SurfaceProjection.new()
    var generator = SurfaceGenerator.new()
    var saw_paved := false
    var saw_gravel := false
    for source: Dictionary in catalog.sources():
        var projected: Dictionary = projection.project(plan, String(source.get("source_id", "")), source.get("bounds", Rect2i()))
        if not bool(projected.get("ok", false)):
            continue
        var area = generator.generate(projected.get("request"))
        if area == null or not area.is_generated():
            continue
        for road: Dictionary in area.roads:
            var family := StringName(road.get("surface_family", &""))
            var semantic := _road_surface_semantic(area.ground_regions, String(road.get("road_id", "")))
            if family == &"paved_centerline":
                saw_paved = true
                _check(semantic == &"ground.asphalt", "production paved road materializes as asphalt")
                _check(bool(road.get("paint_centerline", false)), "production paved road retains centerline")
            elif family == &"rural_gravel":
                saw_gravel = true
                _check(semantic == &"ground.gravel_dark", "production gravel road materializes as gravel")
                _check(not bool(road.get("paint_centerline", true)), "production gravel road has no centerline")
        if saw_paved and saw_gravel:
            break
    _check(saw_paved, "production surface materialization sees paved road")
    _check(saw_gravel, "production surface materialization sees gravel road")

func _verify_local_dirt(plan) -> void:
    var site: Dictionary = {}
    for candidate: Dictionary in plan.area_sites:
        if StringName(candidate.get("area_profile_hint", &"")) == AreaProfiles.RURAL_SCATTERED:
            site = candidate
            break
    _check(not site.is_empty(), "reference island has rural scattered site")
    if site.is_empty():
        return
    var projected: Dictionary = SiteProjection.new().project_site(plan, String(site.get("id", "")))
    _check(bool(projected.get("ok", false)), "rural site projects through production path")
    if not bool(projected.get("ok", false)):
        return
    var area = LocalGenerator.new().generate(projected.get("request"))
    _check(area != null and area.is_generated(), "rural site generates")
    if area == null or not area.is_generated():
        return
    var saw_dirt := false
    for road: Dictionary in area.roads:
        if bool(road.get("inherited", false)):
            continue
        if StringName(road.get("surface_family", &"")) == &"rural_dirt":
            saw_dirt = true
            _check(_road_surface_semantic(area.ground_regions, String(road.get("road_id", ""))) == &"ground.dirt_road", "local rural road materializes as dirt")
            _check(not bool(road.get("paint_centerline", true)), "local dirt road has no paint")
    _check(saw_dirt, "rural local access uses dirt")

func _verify_vehicle_production_route() -> void:
    var packed := load("res://gameplay.tscn") as PackedScene
    _check(packed != null, "production gameplay scene loads")
    if packed == null:
        return
    var game := packed.instantiate()
    _check(game != null and game.has_method("run_simple_vehicle_action"), "production scene composes VehicleSimpleGameMain")
    if game == null:
        return
    _check(game.configure_world_seed_override(Fixture.SEED), "production seed configured")
    root.add_child(game)
    await process_frame
    await process_frame
    _check(game.session_boot_ok(), "production gameplay boots")
    if not game.session_boot_ok():
        game.queue_free()
        return

    var source := FileAccess.get_file_as_string("res://scripts/app/VehicleSimpleGameMain.gd")
    _check(not source.contains("_kernel.begin_action"), "canonical vehicle route does not schedule TickKernel actions")
    _check(not source.contains(".request_forward(") and not source.contains(".request_turn_") and not source.contains(".request_reverse("), "canonical vehicle route bypasses legacy timed request API")

    var state = game.get("_vehicle_state")
    var profiles = game.get("_vehicle_profiles")
    var world = game.get("_world")
    var mutations = game.get("_world_mutations")
    var inventory_mutations = game.get("_inventory_mutations")
    var spatial = game.get("_spatial_query")
    var skills = game.get("_skill_state")
    var simple = game.call("simple_turn_controller")
    _check(state != null and profiles != null and world != null and mutations != null and inventory_mutations != null and spatial != null and skills != null and simple != null, "vehicle authoritative owners are available")
    if state == null or profiles == null or world == null or mutations == null or inventory_mutations == null or spatial == null or skills == null or simple == null:
        game.queue_free()
        return

    var vehicle_id := _motor_vehicle_id(state)
    _check(not vehicle_id.is_empty(), "generated production start contains a motor vehicle for action verification")
    if vehicle_id.is_empty():
        game.queue_free()
        return

    var actor := "actor.player"
    _check(skills.set_skill(actor, SkillCatalog.MECHANICAL, SkillCatalog.LEVEL_MAX, 0), "verification player mechanical skill raised through authoritative state")
    var setup := _place_vehicle_for_drive(world, mutations, spatial, state, profiles, vehicle_id, actor)
    _check(bool(setup.get("ok", false)), "generated vehicle can be positioned in a clear production-world test corridor")
    if not bool(setup.get("ok", false)):
        game.queue_free()
        return

    state.mutate(vehicle_id, {"heading": 0, "moving": false, "powered": false, "fuel": profiles.max_fuel(VehicleProfiles.CAR), "key_in_ignition": true, "body": 55, "propulsion": 55, "wheels": 55, "electrical": 55})

    _verify_action(game, simple, VehicleActions.ENTER, "")
    _verify_action(game, simple, VehicleActions.START, "")
    var fuel_before := int(state.record(vehicle_id).get("fuel", 0))
    _verify_action(game, simple, VehicleActions.MOVE, "")
    _check(int(state.record(vehicle_id).get("fuel", 0)) < fuel_before, "forward movement consumes fuel")
    _verify_action(game, simple, VehicleActions.TURN_RIGHT, "")
    state.mutate(vehicle_id, {"moving": false})
    _verify_action(game, simple, VehicleActions.REVERSE, "")

    _ensure_item(world, mutations, inventory_mutations, actor, &"item.tool.adjustable_wrench", "slice10.wrench")
    _ensure_item(world, mutations, inventory_mutations, actor, &"item.material.screws_box", "slice10.parts")
    var body_before := int(state.record(vehicle_id).get("body", 0))
    _verify_action(game, simple, VehicleActions.REPAIR, "")
    _check(int(state.record(vehicle_id).get("body", 0)) > body_before, "repair improves authoritative vehicle condition")

    state.mutate(vehicle_id, {"fuel": 1})
    _ensure_item(world, mutations, inventory_mutations, actor, &"item.automotive.gas_can", "slice10.gas")
    _verify_action(game, simple, VehicleActions.REFUEL, "")
    _check(int(state.record(vehicle_id).get("fuel", 0)) == profiles.max_fuel(VehicleProfiles.CAR), "refuel restores authoritative fuel")

    _ensure_item(world, mutations, inventory_mutations, actor, &"item.material.wood_plank", "slice10.cargo")
    _verify_action(game, simple, &"vehicle.cargo_store", "slice10.cargo")
    _check(game.get("_inventory_state").contains_directly(vehicle_id, "slice10.cargo"), "cargo store uses authoritative containment")
    _verify_action(game, simple, &"vehicle.cargo_take", "slice10.cargo")
    _check(game.get("_inventory_state").contains_directly(actor, "slice10.cargo"), "cargo take returns authoritative containment")

    state.mutate(vehicle_id, {"moving": false})
    _verify_action(game, simple, VehicleActions.EXIT, "")
    _check(state.vehicle_for_driver(actor).is_empty(), "exit clears authoritative driver state")

    var durable: Dictionary = game.call("durable_session_snapshot")
    var owners: Dictionary = durable.get("owners", {})
    _check(typeof(owners.get("vehicles", null)) == TYPE_DICTIONARY, "durable snapshot includes authoritative vehicle state")

    game.queue_free()
    await process_frame

func _verify_action(game, simple, action_id: StringName, item_id: String) -> void:
    var turn_before: int = int(simple.turn_number())
    var actor_actions_before: int = int(simple.individual_actor_actions())
    var result: Dictionary = game.call("run_simple_vehicle_action", action_id, item_id)
    _check(bool(result.get("success", false)), "vehicle action succeeds: %s (%s)" % [String(action_id), String(result.get("reason", ""))])
    if not bool(result.get("success", false)):
        return
    _check(simple.turn_number() == turn_before + 1, "vehicle action completes exactly one simple turn: %s" % String(action_id))
    var actor_action_delta: int = simple.individual_actor_actions() - actor_actions_before
    var local_infected_count: int = game.call("simple_infected_actor_ids").size()
    _check(actor_action_delta <= local_infected_count, "vehicle action gives each relevant local infected at most one response: %s" % String(action_id))
    _check(int(result.get("elapsed_ticks", 0)) > 0, "vehicle action advances explicit elapsed time: %s" % String(action_id))
    _check(simple.has_control(), "vehicle action returns player control: %s" % String(action_id))

func _place_vehicle_for_drive(world, mutations, spatial, state, profiles, vehicle_id: String, actor_id: String) -> Dictionary:
    var actor_place = world.placement(actor_id)
    var vehicle_place = world.placement(vehicle_id)
    if actor_place == null or vehicle_place == null:
        return {"ok": false}
    var kind := StringName(state.record(vehicle_id).get("kind", &""))
    if kind != VehicleProfiles.CAR:
        state.mutate(vehicle_id, {"kind": VehicleProfiles.CAR})
        kind = VehicleProfiles.CAR
    var footprint = profiles.footprint(kind)
    for radius in range(8, 36):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if absi(dx) != radius and absi(dy) != radius:
                    continue
                var anchor: Vector2i = actor_place.anchor + Vector2i(dx, dy)
                var route_ok := true
                var sequence: Array[Vector2i] = [Vector2i.ZERO]
                sequence.append_array(VehicleHeadingClass.forward_path(0, 3))
                for offset: Vector2i in sequence:
                    var check = spatial.query_footprint(anchor + offset, Facing.Value.NORTH, footprint, vehicle_id, true)
                    if check == null or not check.is_clear():
                        route_ok = false
                        break
                if not route_ok:
                    continue
                var neighbor: Vector2i = anchor + Vector2i.RIGHT
                var actor_check = spatial.query_cell(neighbor, actor_id, true)
                if actor_check == null or not actor_check.is_clear():
                    continue
                if not mutations.set_placement(vehicle_id, Layers.Channel.OBJECT, anchor, Facing.Value.NORTH, footprint):
                    continue
                if not mutations.set_placement(actor_id, Layers.Channel.ACTOR, neighbor, Facing.Value.WEST, world.placement(actor_id).footprint):
                    continue
                return {"ok": true, "anchor": anchor}
    return {"ok": false}

func _motor_vehicle_id(state) -> String:
    for vehicle_id: String in state.vehicle_ids():
        var kind := StringName(state.record(vehicle_id).get("kind", &""))
        if kind == VehicleProfiles.CAR:
            return vehicle_id
    for vehicle_id: String in state.vehicle_ids():
        var kind := StringName(state.record(vehicle_id).get("kind", &""))
        if kind == VehicleProfiles.TRUCK or kind == VehicleProfiles.MOTORCYCLE:
            return vehicle_id
    return ""

func _ensure_item(world, mutations, inventory_mutations, actor_id: String, semantic: StringName, item_id: String) -> void:
    if not world.has_entity(item_id):
        _check(mutations.create_entity(semantic, item_id) == item_id, "test item created: %s" % item_id)
    if world.has_entity(item_id):
        _check(inventory_mutations.set_container(item_id, actor_id), "test item carried: %s" % item_id)

func _road_surface_semantic(regions: Array, road_id: String) -> StringName:
    var suffix := ".ground.road.%s.surface" % road_id
    for region: Dictionary in regions:
        if String(region.get("id", "")).ends_with(suffix):
            return StringName(region.get("semantic", &""))
    return &""

func _point_on_segment(point: Vector2i, start: Vector2i, finish: Vector2i) -> bool:
    if start.x == finish.x:
        return point.x == start.x and point.y >= mini(start.y, finish.y) and point.y <= maxi(start.y, finish.y)
    if start.y == finish.y:
        return point.y == start.y and point.x >= mini(start.x, finish.x) and point.x <= maxi(start.x, finish.x)
    return false

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("SLICE10_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("SLICE10_ROADS_VEHICLES_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("SLICE10_FAIL: %s" % failure)
    quit(1)
