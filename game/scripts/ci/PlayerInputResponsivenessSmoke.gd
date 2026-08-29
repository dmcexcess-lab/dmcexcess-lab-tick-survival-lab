extends SceneTree

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://main.tscn")
    var main: Node = scene.instantiate()
    get_root().add_child(main)
    await process_frame
    var controller: PlayerActionController = _find_controller(main)
    if controller == null:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: controller missing")
        quit(1)
        return
    var world: WorldState = main.get("_world")
    var kernel: TickKernel = main.get("_kernel")
    var perception: ObserverPerceptionService = main.get("_perception")
    var lighting: PhysicalLightingService = main.get("_physical_lighting")
    var world_view: TacticalRendererStack = main.get("_world_view")
    var before: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if before == null:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: player placement missing")
        quit(1)
        return

    # A successful boot is not sufficient: the canonical frame must contain
    # actual visible knowledge and an initialized nonzero lighting presentation.
    # This protects against browser-black regressions that headless startup alone
    # cannot detect.
    var initial_perception: Dictionary = world_view.perception_debug_snapshot()
    var initial_light_view: Dictionary = world_view.physical_lighting_debug_snapshot()
    if not perception.is_visible(before.anchor) or int(initial_perception.get("visible", 0)) <= 1:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: canonical frame has no usable visible field")
        quit(1)
        return
    if not bool(initial_light_view.get("multiply_texture_ready", false)) \
        or not bool(initial_light_view.get("glow_texture_ready", false)) \
        or float(initial_light_view.get("max_luminance", 0.0)) <= 0.001:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: canonical lighting presentation is effectively black")
        quit(1)
        return

    var perception_before: int = perception.recompute_count()
    var lighting_before: int = int(lighting.debug_snapshot().get("field_rebuilds", 0))
    controller.submit_intent(Intents.TURN_RIGHT)
    controller.submit_intent(Intents.TURN_RIGHT)
    controller.submit_intent(Intents.TURN_RIGHT)
    if not controller.is_busy():
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: action did not yield")
        quit(1)
        return
    for _frame: int in range(8):
        if not controller.is_busy():
            break
        await process_frame
    var after: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if after == null or after.facing == before.facing:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: accepted turn did not commit")
        quit(1)
        return
    if after.facing != ((before.facing + 1) % 4):
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: buffered turns were not dropped")
        quit(1)
        return
    if controller.is_busy() or not kernel.is_decision_paused():
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: input unlocked before decision pause")
        quit(1)
        return
    if perception.recompute_count() != perception_before + 1:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: action did not coalesce perception refresh")
        quit(1)
        return
    if int(lighting.debug_snapshot().get("field_rebuilds", 0)) != lighting_before + 1:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: action did not coalesce lighting rebuild")
        quit(1)
        return

    # The next real pause accepts immediately; there is no wall-clock cooldown.
    controller.submit_intent(Intents.TURN_RIGHT)
    if not controller.is_busy():
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: next pause did not accept immediate input")
        quit(1)
        return
    for _frame: int in range(8):
        if not controller.is_busy():
            break
        await process_frame
    var second: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if second == null or second.facing != ((before.facing + 2) % 4):
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: immediate next-pause action did not commit")
        quit(1)
        return

    var final_perception: Dictionary = world_view.perception_debug_snapshot()
    var final_light_view: Dictionary = world_view.physical_lighting_debug_snapshot()
    var visible_size: Vector2i = final_light_view.get("visible_size", Vector2i.ZERO)
    var texture_size: Vector2i = final_light_view.get("texture_size", Vector2i.ZERO)
    if visible_size != Fixture.RENDER_WINDOW_SIZE or texture_size != visible_size:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: recovery lighting no longer covers the canonical render window")
        quit(1)
        return
    if not perception.is_visible(second.anchor) or int(final_perception.get("visible", 0)) <= 1:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: visibility collapsed after a settled action")
        quit(1)
        return
    if float(final_light_view.get("max_luminance", 0.0)) <= 0.001:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: lighting collapsed to black after a settled action")
        quit(1)
        return
    print("PLAYER_INPUT_RESPONSIVENESS_SMOKE_OK")
    quit(0)

func _find_controller(node: Node) -> PlayerActionController:
    if node is PlayerActionController:
        return node
    for child: Node in node.get_children():
        var found: PlayerActionController = _find_controller(child)
        if found != null:
            return found
    return null
