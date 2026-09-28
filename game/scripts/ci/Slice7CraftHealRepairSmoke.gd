extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn"); var game := scene.instantiate(); game.call("configure_world_seed_override", 20001); get_root().add_child(game); await process_frame; await process_frame
    var semantics := [&"item.material.metal_scrap", &"item.material.duct_tape", &"item.material.rag", &"item.kitchen.kitchen_knife", &"item.medical.first_aid_kit", &"item.tool.hammer", &"item.material.nails_box", &"item.food.canned_beans", &"item.kitchen.can_opener", &"prop.stove_range"]
    for semantic: StringName in semantics: print("SLICE7_COUNT ", semantic, " = ", game._world.entity_ids_of_type(semantic).size())
    quit(1)
