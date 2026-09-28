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
    var turns: SimpleTurnController = game.call("simple_turn_controller")
    var recipe: CraftingRecipe = game._crafting_recipes.recipe(&"crafting.sharpened_stake")
    var i := 0
    for req: Dictionary in recipe.consumed_inputs + recipe.required_tools:
        for _n in range(int(req.get("count", 1))):
            i += 1
            var item_id := "slice7.recipe.%03d" % i
            print("CREATE ", item_id, " sem=", req.get("semantic_type"), " entity=", game._world.create_entity(StringName(req.get("semantic_type")), item_id), " contain=", game._inventory_mutations.set_container(item_id, PLAYER))
    var plan: Dictionary = game._crafting_plans.query(PLAYER, &"crafting.sharpened_stake", "")
    print("PLAN consumed=", plan.get("consumed_item_ids"), " tools=", plan.get("tool_item_ids"), " ready=", plan.get("ready"), " reason=", plan.get("reason"))
    var result: Dictionary = game.call("run_simple_craft", &"crafting.sharpened_stake", "")
    print("RESULT ", result)
    for value: Variant in result.get("consumed_item_ids", []):
        var id := String(value)
        print("CONSUMED_CHECK id=", id, " world=", game._world.has_entity(id), " contained=", game._inventory_state.is_contained(id), " container=", game._inventory_state.container_of(id))
    for value: Variant in result.get("output_item_ids", []):
        var id := String(value)
        print("OUTPUT_CHECK id=", id, " world=", game._world.has_entity(id), " contained=", game._inventory_state.is_contained(id), " container=", game._inventory_state.container_of(id))
    print("TURN ", turns.turn_number(), " kernel=", game._kernel.world_tick())
    quit(1)
