extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("CONTEXTUAL_SUSTAINMENT: " + message)
    quit(1)

func _inventory_action_button(shell: CanonicalPlayerShell, item_id: String, label: String) -> Button:
    var body: VBoxContainer = shell.get("_body") as VBoxContainer
    if body == null:
        return null
    for child: Node in body.get_children():
        var button: Button = child as Button
        if button == null:
            continue
        if String(button.get_meta("inventory_action_item_id", "")) == item_id and button.text == label:
            return button
    return null

func _has_offer(offers: Array[InteractionOffer], action_id: StringName) -> bool:
    for offer: InteractionOffer in offers:
        if offer != null and offer.action_id == action_id:
            return true
    return false

func _forward_fixture_cell(reach: WorldInteractionReachQuery, world: WorldState, actor_id: String) -> Vector2i:
    var placement: WorldPlacement = world.placement(actor_id)
    if placement == null:
        return Vector2i(2147483647, 2147483647)
    var occupied: Dictionary = {}
    for cell: Vector2i in placement.world_cells():
        occupied[cell] = true
    for cell: Vector2i in reach.reachable_cells(actor_id):
        if not occupied.has(cell):
            return cell
    return Vector2i(2147483647, 2147483647)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return
    var game: Node = scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    if game.get_node_or_null("SurvivalControls") != null:
        _fail("obsolete permanent survival strip still exists")
        return

    var shell: CanonicalPlayerShell = game.get_node_or_null("PlayerShell") as CanonicalPlayerShell
    var world: WorldState = game.get("_world") as WorldState
    var mutations: WorldMutationService = game.get("_world_mutations") as WorldMutationService
    var inventory_mutations: InventoryContainmentMutationService = game.get("_inventory_mutations") as InventoryContainmentMutationService
    var kernel: TickKernel = game.get("_kernel") as TickKernel
    var sustainment: SurvivorSustainmentActionService = game.get("_sustainment_actions") as SurvivorSustainmentActionService
    var catalog: WorldInteractionCatalog = game.get("_world_interaction_catalog") as WorldInteractionCatalog
    var provider: SustainmentInteractionOfferProvider = game.get("_sustainment_interaction_offers") as SustainmentInteractionOfferProvider
    var controller: WorldInteractionPlayerController = game.get("_world_interaction_controller") as WorldInteractionPlayerController
    var reach: WorldInteractionReachQuery = game.get("_interaction_reach") as WorldInteractionReachQuery
    if shell == null or world == null or mutations == null or inventory_mutations == null or kernel == null         or sustainment == null or catalog == null or provider == null or controller == null or reach == null:
        _fail("production contextual sustainment owners are incomplete")
        return

    # Inventory is the ordinary action surface for carried food and drink.
    var apple_id := "item.verifier.contextual.apple"
    if mutations.create_entity(&"item.food.apple", apple_id) != apple_id         or not inventory_mutations.set_container(apple_id, Fixture.PLAYER_ID):
        _fail("could not create carried verifier food")
        return
    shell.open_inventory()
    shell._select_inventory_item(apple_id)
    var eat_button := _inventory_action_button(shell, apple_id, "EAT")
    if eat_button == null:
        _fail("selected edible item does not expose EAT in inventory")
        return
    var eat_tick := kernel.world_tick()
    eat_button.pressed.emit()
    if world.has_entity(apple_id) or kernel.world_tick() <= eat_tick:
        _fail("inventory EAT did not consume the exact item through authoritative WHEN")
        return

    var water_id := "item.verifier.contextual.water"
    if mutations.create_entity(&"item.drink.water_bottle", water_id) != water_id         or not inventory_mutations.set_container(water_id, Fixture.PLAYER_ID):
        _fail("could not create carried verifier drink")
        return
    shell._select_inventory_item(water_id)
    var drink_button := _inventory_action_button(shell, water_id, "DRINK")
    if drink_button == null:
        _fail("selected drink does not expose DRINK in inventory")
        return
    var drink_tick := kernel.world_tick()
    drink_button.pressed.emit()
    if world.has_entity(water_id) or kernel.world_tick() <= drink_tick:
        _fail("inventory DRINK did not consume the exact item through authoritative WHEN")
        return
    shell.close_modal()

    # Rest and sleep remain object affordances, not global commands.
    if catalog.rest_surface(&"prop.dining_chair") != &"chair"         or catalog.rest_surface(&"prop.armchair") != &"chair"         or catalog.rest_surface(&"prop.sofa") != &"sofa"         or catalog.rest_surface(&"prop.bed_single") != &"bed":
        _fail("furniture rest capability table changed")
        return

    var handlers: Dictionary = controller.get("_handlers") as Dictionary
    for action_id: StringName in [
        SustainmentInteractionOfferProvider.DRINK_FROM_FIXTURE,
        SustainmentInteractionOfferProvider.REST_ON_FURNITURE,
        SustainmentInteractionOfferProvider.SLEEP_IN_BED,
    ]:
        if not handlers.has(String(action_id)):
            _fail("contextual sustainment action is not registered with world interaction controller: %s" % String(action_id))
            return

    var fixture_cell := _forward_fixture_cell(reach, world, Fixture.PLAYER_ID)
    if fixture_cell.x == 2147483647:
        _fail("no forward contact cell available for contextual furniture fixture")
        return
    var player_placement: WorldPlacement = world.placement(Fixture.PLAYER_ID)

    var chair_id := "prop.verifier.contextual.chair"
    if mutations.create_entity(&"prop.dining_chair", chair_id) != chair_id         or not mutations.set_placement(chair_id, Layers.Channel.OBJECT, fixture_cell, player_placement.facing, null):
        _fail("could not place verifier chair")
        return
    var chair_offers: Array[InteractionOffer] = provider.offers_for_actor(Fixture.PLAYER_ID, [chair_id])
    if not _has_offer(chair_offers, SustainmentInteractionOfferProvider.REST_ON_FURNITURE)         or _has_offer(chair_offers, SustainmentInteractionOfferProvider.SLEEP_IN_BED):
        _fail("chair must offer REST and must not offer SLEEP")
        return
    mutations.remove_entity(chair_id)

    var bed_id := "prop.verifier.contextual.bed"
    if mutations.create_entity(&"prop.bed_single", bed_id) != bed_id         or not mutations.set_placement(bed_id, Layers.Channel.OBJECT, fixture_cell, player_placement.facing, null):
        _fail("could not place verifier bed")
        return
    var bed_offers: Array[InteractionOffer] = provider.offers_for_actor(Fixture.PLAYER_ID, [bed_id])
    if not _has_offer(bed_offers, SustainmentInteractionOfferProvider.REST_ON_FURNITURE)         or not _has_offer(bed_offers, SustainmentInteractionOfferProvider.SLEEP_IN_BED):
        _fail("bed must offer both REST and SLEEP")
        return

    if not catalog.is_water_fixture(&"prop.kitchen_sink")         or not handlers.has(String(SustainmentInteractionOfferProvider.DRINK_FROM_FIXTURE)):
        _fail("world-fixture DRINK route is not preserved")
        return

    print("CONTEXTUAL_SUSTAINMENT_OK strip=false inventory_eat=true inventory_drink=true chair_rest=true bed_rest=true bed_sleep=true fixture_drink_handler=true")
    quit(0)
