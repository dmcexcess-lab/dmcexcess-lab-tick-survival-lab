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
    for container_id: String in game._loot_state.container_ids():
        for item_id: String in game._inventory_state.direct_contents(container_id):
            if not game._world.has_entity(item_id): continue
            var entity: WorldEntityRecord = game._world.entity(item_id)
            if entity == null or entity.semantic_type != semantic: continue
            if not game._inventory_mutations.clear_container(item_id): return ""
            if game._inventory_mutations.set_container(item_id, PLAYER): return item_id
            return ""
    return ""
