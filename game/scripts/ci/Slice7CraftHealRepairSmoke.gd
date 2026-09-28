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
    print("SLICE7_STAGE boot")
    var stick := _take(game, &"item.outdoors.sturdy_stick")
    var knife := _take(game, &"item.kitchen.kitchen_knife")
    print("SLICE7_STAGE loot stick=", stick, " knife=", knife)
    var result: Dictionary = game.call("run_simple_craft", &"crafting.sharpened_stake", "")
    print("SLICE7_STAGE craft=", result)
    quit(1)
func _take(game: Node, semantic: StringName) -> String:
    for item_id: String in game._world.entity_ids_of_type(semantic):
        if not game._inventory_state.is_contained(item_id): continue
        var container_id := game._inventory_state.container_of(item_id)
        if not game._loot_state.has_container(container_id): continue
        if not game._inventory_mutations.clear_container(item_id): return ""
        if game._inventory_mutations.set_container(item_id, PLAYER): return item_id
        game._inventory_mutations.set_container(item_id, container_id)
        return ""
    return ""
