extends SceneTree

var failures: int = 0

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var world := WorldState.new()
    var mutations := WorldMutationService.new(world)
    var profiles := VehicleProfileCatalog.new()
    var state := VehicleState.new()
    var stack := TacticalRendererStack.new()
    root.add_child(stack)
    check(stack.configure_vehicles(world, state, profiles), "production stack wires vehicle ownership")
    var props: PropLayerRenderer = stack.get("_props")
    var vehicles: VehicleRenderer = stack.get("_vehicles")
    check(props.configure(world, ArtCatalog.new()), "prop renderer configured")
    check(props.set_visible_window(Vector2i.ZERO, Vector2i(20, 20), 32.0), "prop view")
    check(vehicles.set_visible_window(Vector2i.ZERO, Vector2i(20, 20), 32.0), "vehicle view")
    var x: int = 0
    for kind: StringName in profiles.kinds():
        var id: String = "vehicle.test." + String(kind)
        check(not mutations.create_entity(profiles.semantic_type(kind), id).is_empty(), "vehicle entity")
        check(state.create_vehicle(id, kind, 10, false), "vehicle record")
        check(mutations.set_placement(id, SpatialLayer.Channel.OBJECT, Vector2i(x, 2), 0, SpatialFootprint.single_cell()), "vehicle placement")
        check(vehicles.owns_entity(id), "dedicated sprite owns " + String(kind))
        check(props.plan_visible_commands().is_empty(), "no generic vehicle diagnostic " + String(kind))
        x += 2
    var board: String = "vehicle.test.skateboard"
    check(state.set_driver(board, "actor.test"), "mounted skateboard")
    check(props.plan_visible_commands().is_empty(), "mounted board has no square")
    check(mutations.set_placement(board, SpatialLayer.Channel.LOOSE_ITEM, Vector2i(1, 1), 0, SpatialFootprint.single_cell()), "loose board")
    check(vehicles.owns_entity(board), "loose skateboard still drawn")
    check(props.plan_visible_commands().is_empty(), "loose board no duplicate")
    check(mutations.set_placement(board, SpatialLayer.Channel.OBJECT, Vector2i(2, 1), 0, SpatialFootprint.single_cell()), "board remount placement")
    check(props.plan_visible_commands().is_empty(), "remounted board no square")
    mutations.create_entity(&"prop.unknown_test", "prop.unknown")
    mutations.set_placement("prop.unknown", SpatialLayer.Channel.OBJECT, Vector2i(4, 4), 0, SpatialFootprint.single_cell())
    var commands: Array[PropDrawCommand] = props.plan_visible_commands()
    check(commands.size() == 1 and commands[0].is_diagnostic(), "unrelated missing art remains diagnostic")
    props.set_vehicle_renderer(null)
    check(props.plan_visible_commands().size() == 6, "diagnostics return without dedicated renderer")
    stack.queue_free()
    await process_frame
    print("PROMPT_VEHICLE_VISUAL_SMOKE: PASS" if failures == 0 else "PROMPT_VEHICLE_VISUAL_SMOKE: FAIL")
    quit(0 if failures == 0 else 1)
