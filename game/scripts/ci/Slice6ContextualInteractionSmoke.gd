extends SceneTree

const REGRESSION_SEED := 20001
const PLAYER_ID := "actor.player"
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const ConditionStateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const SustainmentOffers = preload("res://scripts/simulation/interaction/SustainmentInteractionOfferProvider.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

const SAVE_PRIMARY := "user://slice6_session.save"
const SAVE_BACKUP := "user://slice6_session.backup.save"
const SAVE_TEMP := "user://slice6_session.tmp.save"

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SLICE6_CONTEXTUAL: " + message)
    quit(1)

func _run() -> void:
    _clear_save_files()
    var scene: PackedScene = load("res://gameplay.tscn")
    var game := scene.instantiate() if scene != null else null
    if game == null or not game.call("configure_world_seed_override", REGRESSION_SEED) \
        or not game.call("configure_session_paths", SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP):
        _fail("production scene/session setup failed")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    if not bool(game.call("canonical_boot_ok")) or not bool(game.call("session_boot_ok")):
        _fail("production/session boot failed")
        return

    var turns: SimpleTurnController = game.call("simple_turn_controller")
    var world: WorldState = turns._world if turns != null else null
    if turns == null or world == null or not turns.has_control():
        _fail("canonical simple turn route unavailable")
        return
    if game.get_node_or_null("SessionControls") != null or not game._shell.call("menu_has_session_actions") and game._shell.active_modal() == game._shell.MODAL_MENU:
        _fail("menu/save regression returned")
        return

    # Browsing contextual UI is zero-time.
    var panel = game.call("simple_contextual_panel")
    var affordances = game.call("simple_contextual_affordances")
    if panel == null or affordances == null:
        _fail("production contextual presentation/query unavailable")
        return
    var ui_turn := turns.turn_number()
    var ui_tick := int(game.call("survival_elapsed_tick"))
    var offers: Array[InteractionOffer] = affordances.offers()
    if offers.is_empty():
        _fail("real production world exposes no contextual offers")
        return
    if not panel.open_for_target(offers[0].target_entity_id, "INTERACT", [offers[0]]):
        _fail("contextual panel could not open real offer")
        return
    panel.close_panel()
    if turns.turn_number() != ui_turn or int(game.call("survival_elapsed_tick")) != ui_tick:
        _fail("contextual browsing advanced time")
        return

    # Rejected contextual action is zero-time.
    var rejected: Dictionary = game.call("run_simple_contextual_action", PLAYER_ID, "missing.target", &"door.open")
    if bool(rejected.get("success", false)) or turns.turn_number() != ui_turn or int(game.call("survival_elapsed_tick")) != ui_tick:
        _fail("rejected contextual action advanced time")
        return

    # Real generated edible item: take exact item, then consume it through the production inventory action route.
    var edible := _find_real_consumable(game, &"eat")
    if edible.is_empty() or not _place_player_for_target(world, String(edible["container_id"])):
        _fail("no reachable real generated edible item")
        return
    var take: Dictionary = turns.take_loot_item(String(edible["container_id"]), String(edible["item_id"]))
    if not bool(take.get("success", false)):
        _fail("could not take real edible item")
        return
    var eat_item := String(edible["item_id"])
    var satiety_before := game._condition_service.value(PLAYER_ID, ConditionStateClass.SATIETY)
    var eat_turn := turns.turn_number()
    var eat_tick := int(game.call("survival_elapsed_tick"))
    var eat: Dictionary = game.call("run_simple_inventory_consumption", eat_item)
    if not bool(eat.get("success", false)) or world.has_entity(eat_item):
        _fail("EAT did not consume exact authoritative item")
        return
    if game._condition_service.value(PLAYER_ID, ConditionStateClass.SATIETY) <= satiety_before:
        _fail("EAT did not improve canonical satiety")
        return
    if turns.turn_number() != eat_turn + 1 or int(game.call("survival_elapsed_tick")) != eat_tick + int(game.call("survival_ticks_per_turn")):
        _fail("EAT did not advance canonical turn/survival exactly once")
        return

    # Real generated drink item follows the same exact-identity path.
    var drinkable := _find_real_consumable(game, &"drink")
    if drinkable.is_empty() or not _place_player_for_target(world, String(drinkable["container_id"])):
        _fail("no reachable real generated drink item")
        return
    var drink_take: Dictionary = turns.take_loot_item(String(drinkable["container_id"]), String(drinkable["item_id"]))
    if not bool(drink_take.get("success", false)):
        _fail("could not take real drink item")
        return
    var drink_item := String(drinkable["item_id"])
    var hydration_before := game._condition_service.value(PLAYER_ID, ConditionStateClass.HYDRATION)
    var drink_turn := turns.turn_number()
    var drink: Dictionary = game.call("run_simple_inventory_consumption", drink_item)
    if not bool(drink.get("success", false)) or world.has_entity(drink_item):
        _fail("DRINK did not consume exact authoritative item")
        return
    if game._condition_service.value(PLAYER_ID, ConditionStateClass.HYDRATION) <= hydration_before or turns.turn_number() != drink_turn + 1:
        _fail("DRINK did not update hydration/turn correctly")
        return

    # Real bed offer -> REST and SLEEP through explicit elapsed-time overrides, never TickKernel.
    var bed := _find_target(game, func(entity: WorldEntityRecord) -> bool: return game._world_interaction_catalog.is_bed(entity.semantic_type))
    if bed.is_empty() or not _place_player_for_target(world, bed):
        _fail("real bed target unavailable")
        return
    var bed_offers := _offers_for_target(affordances, bed)
    if not _has_action(bed_offers, SustainmentOffers.REST_ON_FURNITURE) or not _has_action(bed_offers, SustainmentOffers.SLEEP_IN_BED):
        _fail("bed does not expose REST/SLEEP from target")
        return
    var rest_before := game._condition_service.value(PLAYER_ID, ConditionStateClass.REST)
    var legacy_before := game._kernel.world_tick()
    var rest_result: Dictionary = game.call("run_simple_contextual_action", PLAYER_ID, bed, SustainmentOffers.REST_ON_FURNITURE)
    if not bool(rest_result.get("success", false)) or game._condition_service.value(PLAYER_ID, ConditionStateClass.REST) <= rest_before:
        _fail("REST did not use canonical condition state")
        return
    if game._kernel.world_tick() != legacy_before or int(rest_result.get("elapsed_ticks", 0)) != game._world_time_profile.ticks_per_hour():
        _fail("REST used legacy scheduling or wrong elapsed time")
        return
    var sleep_before := game._condition_service.value(PLAYER_ID, ConditionStateClass.REST)
    game._condition_service.set_condition(PLAYER_ID, ConditionStateClass.REST, 10, &"slice6_sleep_setup")
    sleep_before = game._condition_service.value(PLAYER_ID, ConditionStateClass.REST)
    var sleep_result: Dictionary = game.call("run_simple_contextual_action", PLAYER_ID, bed, SustainmentOffers.SLEEP_IN_BED)
    if not bool(sleep_result.get("success", false)) or game._condition_service.value(PLAYER_ID, ConditionStateClass.REST) <= sleep_before:
        _fail("SLEEP did not restore canonical rest")
        return
    if int(sleep_result.get("elapsed_ticks", 0)) != game._world_time_profile.ticks_per_hour() * 8 or game._kernel.world_tick() != legacy_before:
        _fail("SLEEP used legacy scheduling or wrong elapsed time")
        return

    # Real door OPEN/CLOSE mutates authoritative door state and collision through existing owner.
    var door := _find_target(game, func(entity: WorldEntityRecord) -> bool: return game._world_interaction_catalog.is_door(entity.semantic_type) and game._door_state.has_door(entity.entity_id))
    if door.is_empty() or not _place_player_for_target(world, door):
        _fail("real door target unavailable")
        return
    game._world_interaction_state.set_locked(door, false, &"slice6_door_setup")
    var door_offers := _offers_for_target(affordances, door)
    var door_action := WorldActions.DOOR_CLOSE if game._door_state.state(door) == DoorValue.OPEN else WorldActions.DOOR_OPEN
    if not _has_action(door_offers, door_action):
        _fail("door does not expose authoritative OPEN/CLOSE action")
        return
    var door_before := game._door_state.state(door)
    var door_result: Dictionary = game.call("run_simple_contextual_action", PLAYER_ID, door, door_action)
    if not bool(door_result.get("success", false)) or game._door_state.state(door) == door_before:
        _fail("door contextual action did not mutate authoritative door state")
        return
    if game._kernel.world_tick() != legacy_before:
        _fail("contextual route advanced TickKernel")
        return

    # Contextual state remains saveable/Continue-compatible.
    var save: Dictionary = game.call("save_durable_session", &"slice6_contextual")
    if not bool(save.get("ok", false)):
        _fail("contextual state durable save failed")
        return
    var loaded: Dictionary = game._session_store.load_best()
    var probe := scene.instantiate()
    if not bool(loaded.get("ok", false)) or probe == null \
        or not probe.call("configure_session_paths", SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP) \
        or not probe.call("configure_continue_session", loaded.get("session", {})):
        _fail("contextual save is not Continue-compatible")
        return
    probe.free()

    print("SLICE6_CONTEXTUAL_OK seed=%d turns=%d survival_tick=%d eat=true drink=true rest=true sleep=true door=true save=true" % [REGRESSION_SEED, turns.turn_number(), game.call("survival_elapsed_tick")])
    _clear_save_files()
    quit(0)

func _find_real_consumable(game: Node, kind: StringName) -> Dictionary:
    for container_id: String in game._loot_state.container_ids():
        for item_id: String in game._inventory_state.direct_contents(container_id):
            if not game._world.has_entity(item_id): continue
            var entity: WorldEntityRecord = game._world.entity(item_id)
            var profile: Dictionary = game._sustainment_profiles.profile(entity.semantic_type) if entity != null else {}
            if not profile.is_empty() and StringName(profile.get("action_kind", &"")) == kind:
                return {"container_id": container_id, "item_id": item_id}
    return {}

func _find_target(game: Node, predicate: Callable) -> String:
    for entity_id: String in game._world.entity_ids():
        var entity: WorldEntityRecord = game._world.entity(entity_id)
        if entity != null and predicate.call(entity):
            return entity_id
    return ""

func _offers_for_target(query: InteractionAffordanceQuery, target_id: String) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    for offer: InteractionOffer in query.offers():
        if offer.target_entity_id == target_id: result.append(offer)
    return result

func _has_action(offers: Array[InteractionOffer], action_id: StringName) -> bool:
    for offer: InteractionOffer in offers:
        if offer.action_id == action_id: return true
    return false

func _place_player_for_target(world: WorldState, target_id: String) -> bool:
    var target: WorldPlacement = world.placement(target_id)
    if target == null: return false
    var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
    for target_cell: Vector2i in target.world_cells():
        for direction: Vector2i in directions:
            var player_cell := target_cell - direction
            if not world.has_terrain(player_cell): continue
            var occupied := false
            for actor_id: String in world.entities_at(player_cell, Layers.Channel.ACTOR):
                if actor_id != PLAYER_ID: occupied = true
            if not occupied:
                return world.move_entity(PLAYER_ID, player_cell, Facing.from_vector(direction))
    return false

func _clear_save_files() -> void:
    for path: String in [SAVE_PRIMARY, SAVE_BACKUP, SAVE_TEMP]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
