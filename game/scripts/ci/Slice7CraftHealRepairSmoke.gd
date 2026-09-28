extends SceneTree
const PLAYER := "actor.player"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    var game := scene.instantiate()
    game.call("configure_world_seed_override", 20001)
    get_root().add_child(game)
    await process_frame
    await process_frame
    var id := "slice7.direct.remove"
    print("CREATE=", game._world.create_entity(&"item.outdoors.sturdy_stick", id), " CONTAIN=", game._inventory_mutations.set_container(id, PLAYER))
    var capture: Dictionary = game._capture_personal_item(id)
    print("CAPTURE=", capture)
    print("REMOVE=", game._remove_captured_item(capture), " WORLD=", game._world.has_entity(id), " CONTAINED=", game._inventory_state.is_contained(id))
    quit(1)
