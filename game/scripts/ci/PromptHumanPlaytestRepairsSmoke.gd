extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const QueryResult = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const Actions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Shell = preload("res://scripts/ui/CanonicalPlayerShell.gd")
const Indicator = preload("res://scripts/ui/WorldResolutionIndicator.gd")

const MAX_STARTUP_FRAMES: int = 1200

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Intents.label(&"window.open") == "Open", "world action labels are human-readable")
    _check(Intents.label(&"survival.forage_nearby") == "Forage Nearby", "forage label is human-readable")
    _check(Indicator.ZOMBIES_TEXT == "ZOMBIES NEARBY", "resolution message describes nearby threat")
    _check(Indicator.LABEL_SIZE.x <= 200.0 and Indicator.FONT_SIZE <= 16, "threat indicator remains compact")

    var packed: PackedScene = load(Shell.STARTUP_SCENE_PATH)
    _check(packed != null, "production title scene loads")
    if packed == null:
        _finish()
        return
    var startup: Node = packed.instantiate()
    root.add_child(startup)
    current_scene = startup
    await process_frame
    var new_game: Button = _find_button(startup, "NEW GAME")
    _check(new_game != null, "NEW GAME is available")
    if new_game == null:
        _finish()
        return
    new_game.pressed.emit()

    var game: Node = null
    for _frame: int in range(MAX_STARTUP_FRAMES):
        await process_frame
        if current_scene != null and current_scene.scene_file_path == "res://gameplay.tscn":
            game = current_scene
            if game.get("_world") != null and game.get("_shell") != null and game.get("_world_interaction_offers") != null:
                break
    _check(game != null, "NEW GAME reaches production gameplay")
    if game == null:
        _finish()
        return

    var world: WorldState = game.get("_world") as WorldState
    var mutations: WorldMutationService = game.get("_world_mutations") as WorldMutationService
    var spatial: SpatialQueryService = game.get("_spatial_query") as SpatialQueryService
    var offers: WorldInteractionOfferProvider = game.get("_world_interaction_offers") as WorldInteractionOfferProvider
    var actions: WorldInteractionActionService = game.get("_world_interaction_actions") as WorldInteractionActionService
    var shell: CanonicalPlayerShell = game.get("_shell") as CanonicalPlayerShell
    _check(world != null and mutations != null and spatial != null, "production world services are ready")
    _check(offers != null and offers.is_ready() and actions != null and actions.is_ready(), "window interaction services are ready")
    _check(shell != null and shell.is_configured(), "production player shell is ready")

    if world != null and mutations != null and spatial != null and offers != null and actions != null:
        _check_blocked_window_offer(world, mutations, spatial, offers, actions)

    if shell != null:
        var item_text: String = shell.call("_item_text", {
            "valid": true,
            "label": "Canned Beans",
            "item_id": "item.instance.long-debug-id",
            "weight_known": true,
            "weight_grams": 425,
        })
        _check(item_text == "Canned Beans — Weight: 0.4 kg", "inventory hides internal item IDs")
        shell.open_death()
        _check(shell.active_modal() == Shell.MODAL_DEATH, "player death opens a terminal death modal")
        _check(shell.presentation_snapshot().get("hard_paused", false), "death modal hard-pauses gameplay")
        var return_button: Button = _find_button(shell, "RETURN TO TITLE")
        _check(return_button != null, "death modal offers return to title")
        if return_button != null:
            return_button.pressed.emit()
            for _frame: int in range(30):
                await process_frame
                if current_scene != null and current_scene.scene_file_path == Shell.STARTUP_SCENE_PATH:
                    break
            _check(current_scene != null and current_scene.scene_file_path == Shell.STARTUP_SCENE_PATH, "death return uses the in-game title scene")
            _check(not OS.has_feature("web") or JavaScriptBridge.eval("window.location.hostname", true) != "www.google.com", "return never redirects to Google")
    _finish()

func _check_blocked_window_offer(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, offers: WorldInteractionOfferProvider, actions: WorldInteractionActionService) -> void:
    var actor_id: String = Fixture.PLAYER_ID
    var window_id: String = ""
    for entity_id: String in world.entity_ids():
        var entity: WorldEntityRecord = world.entity(entity_id)
        if entity == null or not String(entity.semantic_type).begins_with("window."):
            continue
        if _place_actor_facing(world, mutations, spatial, actor_id, entity_id):
            window_id = entity_id
            break
    _check(not window_id.is_empty(), "a generated window has a clear climb approach")
    if window_id.is_empty():
        return
    var interaction_state: WorldInteractableState = offers.get("_state") as WorldInteractableState
    _check(interaction_state != null, "window state is available")
    if interaction_state == null:
        return
    interaction_state.set_window_open(window_id, true, &"prompt_playtest_repair")
    _check(actions.can_window_climb(actor_id, window_id), "clear window destination is climbable")
    _check(_has_offer(offers.offers_for_actor(actor_id, [window_id]), Actions.WINDOW_CLIMB), "clear window offers CLIMB THROUGH")

    var actor: WorldPlacement = world.placement(actor_id)
    var window: WorldPlacement = world.placement(window_id)
    var direction: Vector2i = window.anchor - actor.anchor
    var destination: Vector2i = window.anchor + direction
    var blocker_id: String = mutations.create_entity(&"prop.chair", "ci.prompt.window.blocker")
    _check(not blocker_id.is_empty(), "window blocker is created")
    _check(mutations.set_placement(blocker_id, Layers.Channel.OBJECT, destination, Facing.Value.NORTH, Footprint.single_cell()), "window blocker occupies far side")
    _check(not actions.can_window_climb(actor_id, window_id), "blocked window destination is rejected")
    _check(not _has_offer(offers.offers_for_actor(actor_id, [window_id]), Actions.WINDOW_CLIMB), "blocked window does not offer CLIMB THROUGH")

func _place_actor_facing(world: WorldState, mutations: WorldMutationService, spatial: SpatialQueryService, actor_id: String, target_id: String) -> bool:
    var actor: WorldPlacement = world.placement(actor_id)
    var target: WorldPlacement = world.placement(target_id)
    if actor == null or target == null or actor.footprint == null:
        return false
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var actor_cell: Vector2i = target.anchor - direction
        var destination: Vector2i = target.anchor + direction
        var facing: int = Facing.from_vector(direction)
        if not world.has_terrain(actor_cell) or not world.has_terrain(destination) or facing < 0:
            continue
        if spatial.query_entity_footprint(actor_id, destination, facing, true).status != QueryResult.Status.CLEAR:
            continue
        if mutations.set_placement(actor_id, actor.channel, actor_cell, facing, actor.footprint):
            return true
    return false

func _has_offer(values: Array[InteractionOffer], action_id: StringName) -> bool:
    for offer: InteractionOffer in values:
        if offer.action_id == action_id:
            return true
    return false

func _find_button(node: Node, text_value: String) -> Button:
    var button := node as Button
    if button != null and button.text == text_value:
        return button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, text_value)
        if found != null:
            return found
    return null

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_HUMAN_PLAYTEST_REPAIRS_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PROMPT_HUMAN_PLAYTEST_REPAIRS_FAIL: %s" % failure)
    quit(1)
