extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

const ALPHA_ID: String = "item.prompt.human_mobile.alpha"
const BETA_ID: String = "prop.prompt.human_mobile.beta"
const ALPHA_ACTION: StringName = &"prompt_human_mobile_alpha"
const BETA_ACTION: StringName = &"prompt_human_mobile_beta"

var _failures: Array[String] = []
var _captured_target: String = ""
var _captured_action: StringName = &""

class PromptOfferProvider:
    extends InteractionOfferProvider

    var _offers: Array[InteractionOffer] = []

    func _init(offers: Array[InteractionOffer]) -> void:
        _offers = offers

    func is_ready() -> bool:
        return not _offers.is_empty()

    func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
        var result: Array[InteractionOffer] = []
        for offer: InteractionOffer in _offers:
            if offer != null and offer.actor_id == actor_id and candidate_target_ids.has(offer.target_entity_id):
                result.append(offer.copy())
        return result

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    _expect(packed != null, "production main scene loads")
    if packed == null:
        _finish()
        return

    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame

    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var reach: WorldInteractionReachQuery = game.get("_interaction_reach")
    var affordances: InteractionAffordanceQuery = game.get("_interaction_affordances")
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller")
    var panel: WorldInteractionPanel = game.get("_world_interaction_panel")
    var pointer: DoorPointerInputAdapter = game.get("_door_pointer")

    _expect(world != null and mutations != null, "authoritative world owners are ready")
    _expect(reach != null and reach.is_ready(), "world interaction reach is ready")
    _expect(affordances != null and affordances.is_ready(), "shared affordance query is ready")
    _expect(controller != null and controller.is_ready(), "shared world interaction controller is ready")
    _expect(panel != null and pointer != null and pointer.is_enabled(), "production chooser and pointer adapter are ready")
    if not _failures.is_empty():
        game.queue_free()
        _finish()
        return

    var target_cell: Vector2i = _pick_reachable_cell(world, reach)
    _expect(target_cell != Vector2i(2147483647, 2147483647), "found reachable production world cell")
    if target_cell == Vector2i(2147483647, 2147483647):
        game.queue_free()
        _finish()
        return

    _expect(mutations.create_entity(&"item.prompt.human_mobile.alpha", ALPHA_ID) == ALPHA_ID, "created loose-item overlap target")
    _expect(mutations.set_placement(ALPHA_ID, Layers.Channel.LOOSE_ITEM, target_cell, Facing.Value.NORTH, Footprint.single_cell()), "placed loose-item overlap target")
    _expect(mutations.create_entity(&"prop.prompt.human_mobile.beta", BETA_ID) == BETA_ID, "created object overlap target")
    _expect(mutations.set_placement(BETA_ID, Layers.Channel.OBJECT, target_cell, Facing.Value.NORTH, Footprint.single_cell()), "placed object overlap target")

    var offers: Array[InteractionOffer] = [
        InteractionOffer.new(
            Fixture.PLAYER_ID,
            ALPHA_ID,
            ALPHA_ACTION,
            "PICK ALPHA",
            WorldInteractionReachQuery.CONTACT_FORWARD,
            [target_cell],
            1000,
            &"prompt",
            true
        ),
        InteractionOffer.new(
            Fixture.PLAYER_ID,
            BETA_ID,
            BETA_ACTION,
            "USE BETA",
            WorldInteractionReachQuery.CONTACT_FORWARD,
            [target_cell],
            999,
            &"prompt",
            true
        ),
    ]
    var provider := PromptOfferProvider.new(offers)
    _expect(affordances.register_provider(provider), "registered prompt-local overlap offers")
    _expect(controller.register_delegated_handler(ALPHA_ACTION, Callable(self, "_capture_action")), "registered alpha prompt handler")
    _expect(controller.register_delegated_handler(BETA_ACTION, Callable(self, "_capture_action")), "registered beta prompt handler")

    controller.submit_world_cell(target_cell)
    await process_frame

    _expect(panel.is_open(), "overlap click opens the production interaction chooser")
    _expect(not pointer.is_enabled(), "open chooser blocks world pointer input")

    var alpha_button: Button = _find_action_button(panel, ALPHA_ID, ALPHA_ACTION)
    var beta_button: Button = _find_action_button(panel, BETA_ID, BETA_ACTION)
    _expect(alpha_button != null, "higher-priority clicked target remains available")
    _expect(beta_button != null, "lower-priority overlapping clicked target is also reachable")
    if alpha_button != null:
        _expect(alpha_button.custom_minimum_size.y >= 48.0 and alpha_button.size.y >= 48.0, "alpha action has touch-practical height")
    if beta_button != null:
        _expect(beta_button.custom_minimum_size.y >= 48.0 and beta_button.size.y >= 48.0, "beta action has touch-practical height")

    var panel_container := panel.find_child("WorldInteractionPanelContainer", true, false) as PanelContainer
    _expect(panel_container != null, "responsive panel container exists")
    if panel_container != null:
        var viewport_size: Vector2 = panel.get_viewport().get_visible_rect().size
        var rect := Rect2(panel_container.position, panel_container.size)
        _expect(rect.position.x >= 0.0 and rect.position.y >= 0.0, "chooser begins on-screen")
        _expect(rect.end.x <= viewport_size.x + 0.5 and rect.end.y <= viewport_size.y + 0.5, "chooser remains fully on-screen")
        _expect(panel_container.size.x >= 280.0, "chooser keeps a practical phone-width surface")

    if beta_button != null:
        beta_button.emit_signal("pressed")
    _expect(_captured_target == BETA_ID and _captured_action == BETA_ACTION, "choosing overlapping beta dispatches the exact clicked target identity")
    _expect(not panel.is_open(), "chooser closes after action selection")
    _expect(pointer.is_enabled(), "world pointer input restores after chooser closes")

    game.queue_free()
    await process_frame
    _finish()

func _pick_reachable_cell(world: WorldState, reach: WorldInteractionReachQuery) -> Vector2i:
    for cell: Vector2i in reach.reachable_cells(Fixture.PLAYER_ID, WorldInteractionReachQuery.CONTACT_FORWARD):
        if world.has_terrain(cell):
            return cell
    return Vector2i(2147483647, 2147483647)

func _capture_action(_actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    _captured_target = target_id
    _captured_action = action_id
    return {"success": true, "reason": "captured"}

func _find_action_button(root_node: Node, target_id: String, action_id: StringName) -> Button:
    if root_node == null:
        return null
    for child: Node in root_node.get_children():
        if child is Button and not child.is_queued_for_deletion() \
            and child.has_meta("world_target_id") and child.has_meta("world_action_id") \
            and String(child.get_meta("world_target_id")) == target_id \
            and StringName(child.get_meta("world_action_id")) == action_id:
            return child as Button
        var nested: Button = _find_action_button(child, target_id, action_id)
        if nested != null:
            return nested
    return null

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("PASS: %s" % message)
    else:
        _failures.append(message)
        push_error("FAIL: %s" % message)

func _finish() -> void:
    if _failures.is_empty():
        print("PROMPT_HUMAN_MOBILE_INTERACTION_SMOKE: PASS")
        quit(0)
        return
    push_error("PROMPT_HUMAN_MOBILE_INTERACTION_SMOKE: FAIL (%d)" % _failures.size())
    for failure: String in _failures:
        push_error(" - %s" % failure)
    quit(1)
