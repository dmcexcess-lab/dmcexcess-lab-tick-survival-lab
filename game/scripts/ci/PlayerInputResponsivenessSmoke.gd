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
    var controller: DemoPlayerActionController = _find_controller(main)
    if controller == null:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: controller missing")
        quit(1)
        return
    var world: WorldState = main.get("_world")
    var before: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    controller.submit_intent(Intents.TURN_RIGHT)
    controller.submit_intent(Intents.TURN_RIGHT)
    controller.submit_intent(Intents.TURN_RIGHT)
    if not controller.is_busy():
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: action did not yield")
        quit(1)
        return
    await process_frame
    await process_frame
    var after: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if before == null or after == null or after.facing == before.facing:
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: accepted turn did not commit")
        quit(1)
        return
    if after.facing != ((before.facing + 1) % 4):
        push_error("PLAYER_INPUT_RESPONSIVENESS_SMOKE: buffered turns were not dropped")
        quit(1)
        return
    print("PLAYER_INPUT_RESPONSIVENESS_SMOKE_OK")
    quit(0)

func _find_controller(node: Node) -> DemoPlayerActionController:
    if node is DemoPlayerActionController:
        return node
    for child: Node in node.get_children():
        var found: DemoPlayerActionController = _find_controller(child)
        if found != null:
            return found
    return null
