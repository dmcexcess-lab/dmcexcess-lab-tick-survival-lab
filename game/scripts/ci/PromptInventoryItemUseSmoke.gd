extends SceneTree

const AppScene = preload("res://main.tscn")

const APPLE_ID: String = "food.apple.001"
const APPLE_SIBLING_ID: String = "food.apple.002"
const WATER_ID: String = "drink.water.001"
const WATER_SIBLING_ID: String = "drink.water.002"
const APPLE_SEMANTIC: StringName = &"item.food.apple"
const WATER_SEMANTIC: StringName = &"item.drink.water_bottle"

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var app: Node = AppScene.instantiate()
    get_root().add_child(app)
    await process_frame

    var shell: Node = app.get_node_or_null("PlayerShell")
    _check(shell != null, "production PlayerShell exists")
    _check(app.get("_sustainment_actions") != null, "production sustainment owner is wired")
    _check(app.get("_world") != null and app.get("_world_mutations") != null, "production WHAT owner is wired")
    _check(app.get("_inventory_state") != null and app.get("_inventory_mutations") != null, "production inventory owner is wired")
    _check(app.get("_kernel") != null, "production WHEN kernel is wired")
    if not _failures.is_empty():
        _finish(app)
        return

    var actor_id: String = String(shell.get("_actor_id"))
    _check(not actor_id.is_empty(), "production PlayerShell has the authoritative actor id")
    _check(bool(app.get("_inventory_state").has_container(actor_id)), "actor root inventory is enrolled")

    _seed_carried_item(app, APPLE_SEMANTIC, APPLE_ID, actor_id)
    _seed_carried_item(app, APPLE_SEMANTIC, APPLE_SIBLING_ID, actor_id)
    _seed_carried_item(app, WATER_SEMANTIC, WATER_ID, actor_id)
    _seed_carried_item(app, WATER_SEMANTIC, WATER_SIBLING_ID, actor_id)

    _verify_inventory_offer(shell, APPLE_ID, "EAT", &"eat")
    _verify_timed_exact_consumption(app, actor_id, APPLE_ID, APPLE_SIBLING_ID)

    _verify_inventory_offer(shell, WATER_ID, "DRINK", &"drink")
    _verify_timed_exact_consumption(app, actor_id, WATER_ID, WATER_SIBLING_ID)

    _finish(app)

func _seed_carried_item(app: Node, semantic_type: StringName, item_id: String, actor_id: String) -> void:
    var world: Variant = app.get("_world")
    var world_mutations: Variant = app.get("_world_mutations")
    var inventory_mutations: Variant = app.get("_inventory_mutations")
    _check(not bool(world.has_entity(item_id)), "%s is fresh test identity" % item_id)
    if bool(world.has_entity(item_id)):
        return
    _check(String(world_mutations.create_entity(semantic_type, item_id)) == item_id, "%s persistent entity created" % item_id)
    _check(bool(inventory_mutations.set_container(item_id, actor_id)), "%s enters authoritative actor inventory" % item_id)

func _verify_inventory_offer(shell: Node, item_id: String, expected_label: String, expected_kind: StringName) -> void:
    shell.call("open_inventory")
    shell.call("_select_inventory_item", item_id)
    var offer: Dictionary = shell.call("_inventory_consumption_offer", item_id)
    _check(bool(offer.get("available", false)), "%s has ordinary Inventory action" % item_id)
    _check(String(offer.get("item_id", "")) == item_id, "%s Inventory offer preserves exact persistent item id" % item_id)
    _check(StringName(offer.get("action_kind", &"")) == expected_kind, "%s Inventory offer has %s action kind" % [item_id, String(expected_kind)])
    _check(String(offer.get("label", "")) == expected_label, "%s ordinary Inventory label is %s" % [item_id, expected_label])

    var button: Button = _find_inventory_action_button(shell, item_id)
    _check(button != null, "%s selected item renders an action button" % item_id)
    if button != null:
        _check(button.text == expected_label, "%s selected-item button reads %s" % [item_id, expected_label])
        _check(String(button.get_meta("inventory_action_item_id", "")) == item_id, "%s button preserves exact selected item id" % item_id)
        _check(button.pressed.get_connections().size() == 1, "%s action button is wired to the production Inventory handler" % item_id)
    shell.call("close_modal")

func _verify_timed_exact_consumption(app: Node, actor_id: String, item_id: String, sibling_id: String) -> void:
    var world: Variant = app.get("_world")
    var inventory_state: Variant = app.get("_inventory_state")
    var sustainment: Variant = app.get("_sustainment_actions")
    var kernel: Variant = app.get("_kernel")

    var serial: int = int(sustainment.begin_consume(actor_id, item_id))
    _check(serial > 0, "%s authoritative timed consume starts" % item_id)
    _check(bool(world.has_entity(item_id)), "%s still exists before timed completion" % item_id)
    _check(bool(inventory_state.contains_directly(actor_id, item_id)), "%s remains carried before timed completion" % item_id)
    _check(bool(world.has_entity(sibling_id)) and bool(inventory_state.contains_directly(actor_id, sibling_id)), "%s same-type sibling exists before completion" % sibling_id)

    kernel.run_until_stop()

    _check(not bool(world.has_entity(item_id)), "%s selected physical item is removed only after completion" % item_id)
    _check(bool(world.has_entity(sibling_id)), "%s same-type sibling is not consumed" % sibling_id)
    _check(bool(inventory_state.contains_directly(actor_id, sibling_id)), "%s same-type sibling remains in actor inventory" % sibling_id)

func _find_inventory_action_button(shell: Node, item_id: String) -> Button:
    var stack: Array[Node] = [shell]
    while not stack.is_empty():
        var node: Node = stack.pop_back()
        if node is Button and String((node as Button).get_meta("inventory_action_item_id", "")) == item_id:
            return node as Button
        for child: Node in node.get_children():
            stack.append(child)
    return null

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _finish(app: Node) -> void:
    if is_instance_valid(app):
        app.queue_free()
    if _failures.is_empty():
        print("PROMPT_INVENTORY_ITEM_USE_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PROMPT_INVENTORY_ITEM_USE_SMOKE_FAIL: %s" % failure)
    quit(1)
