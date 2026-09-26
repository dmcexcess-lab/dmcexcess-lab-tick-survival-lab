extends SceneTree

const PLAYER_ID := "actor.player.demo"

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SURVIVAL_CONTROLS: " + message)
    quit(1)

func _button(root: Node, name_value: String) -> Button:
    return root.find_child(name_value, true, false) as Button

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return
    var game: Node = scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    var controls: ConditionPlayerControls = game.get_node_or_null("SurvivalControls") as ConditionPlayerControls
    if controls == null:
        _fail("SurvivalControls missing from production scene")
        return
    var panel: Control = controls.get_node_or_null("SurvivalActionPanel") as Control
    if panel == null:
        _fail("survival action panel missing")
        return
    if panel.position.y + panel.size.y > 638.0:
        _fail("survival panel overlaps movement control row")
        return
    if panel.position.x < 0.0 or panel.position.x + panel.size.x > 640.0:
        _fail("survival panel exceeds phone-width layout")
        return

    var names := ["EatButton", "DrinkButton", "TapButton", "RestButton", "SleepButton"]
    for name_value: String in names:
        var button := _button(controls, name_value)
        if button == null:
            _fail("%s missing" % name_value)
            return
        if button.pressed.get_connections().is_empty():
            _fail("%s has no ordinary pressed route" % name_value)
            return

    var mutations: WorldMutationService = game.get("_world_mutations") as WorldMutationService
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations") as InventoryContainmentMutationService
    var world: WorldState = game.get("_world") as WorldState
    var kernel: TickKernel = game.get("_kernel") as TickKernel
    if mutations == null or inventory_mutations == null or world == null or kernel == null:
        _fail("authoritative production services unavailable")
        return

    var apple_id := "item.verifier.survival.apple"
    if mutations.create_entity(&"item.food.apple", apple_id) != apple_id:
        _fail("could not create real verifier apple")
        return
    if not inventory_mutations.set_container(apple_id, PLAYER_ID):
        _fail("could not carry verifier apple")
        return
    var before_eat_tick := kernel.world_tick()
    _button(controls, "EatButton").emit_signal("pressed")
    if world.has_entity(apple_id):
        _fail("EAT button did not consume exact carried apple")
        return
    if kernel.world_tick() <= before_eat_tick:
        _fail("EAT button did not advance authoritative WHEN")
        return

    var drink_id := "item.verifier.survival.water"
    if mutations.create_entity(&"item.drink.water_bottle", drink_id) != drink_id:
        _fail("could not create real verifier water bottle")
        return
    if not inventory_mutations.set_container(drink_id, PLAYER_ID):
        _fail("could not carry verifier water bottle")
        return
    var before_drink_tick := kernel.world_tick()
    _button(controls, "DrinkButton").emit_signal("pressed")
    if world.has_entity(drink_id):
        _fail("DRINK button did not consume exact carried bottle")
        return
    if kernel.world_tick() <= before_drink_tick:
        _fail("DRINK button did not advance authoritative WHEN")
        return

    var before_tap_status := controls.status_text()
    _button(controls, "TapButton").emit_signal("pressed")
    var after_tap_status := controls.status_text()
    if after_tap_status == before_tap_status or not after_tap_status.begins_with("SURVIVAL —"):
        _fail("TAP button did not route to truthful sustainment result")
        return

    print("SURVIVAL_CONTROLS_OK buttons=5 eat=true drink=true tap_status=%s panel_bottom=%d" % [
        after_tap_status,
        int(panel.position.y + panel.size.y),
    ])
    quit(0)
