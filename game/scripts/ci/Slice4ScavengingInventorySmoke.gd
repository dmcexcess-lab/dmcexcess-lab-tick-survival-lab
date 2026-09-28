extends SceneTree

const REGRESSION_SEED := 20001
const PLAYER_ID := "actor.player"
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("SLICE4_SCAVENGE_INVENTORY: " + message)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("canonical gameplay scene missing")
        return
    var game := scene.instantiate()
    if game == null or not game.call("configure_world_seed_override", REGRESSION_SEED):
        _fail("could not configure production world")
        return
    get_root().add_child(game)
    await process_frame
    await process_frame
    if not bool(game.call("canonical_boot_ok")):
        _fail("production boot failed")
        return

    var turns: SimpleTurnController = game.call("simple_turn_controller")
    if turns == null or not turns.is_ready() or not turns.has_control():
        _fail("simple turn controller not ready")
        return
    var world: WorldState = turns._world
    var containment: InventoryContainmentState = game._inventory_state
    var hands: ActorHandEquipmentState = game._hand_state
    var health: ActorHealthState = game.call("combat_health_state")
    var legacy_kernel = game._kernel
    if world == null or containment == null or hands == null or health == null:
        _fail("authoritative inventory/combat owners missing")
        return

    var source := _real_loot_source(game)
    if source.is_empty():
        _fail("no real generated nonempty loot source available")
        return
    var container_id: String = source["container_id"]
    var item_id: String = source["item_id"]
    if not _place_player_for_container(world, container_id):
        _fail("could not place player at real loot source")
        return

    # Pure inspection is read-only and costs no turn.
    var inspect_turn_before: int = turns.turn_number()
    var inspection: Dictionary = game._loot_inspection.query(PLAYER_ID, container_id)
    if not bool(inspection.get("ok", false)) or turns.turn_number() != inspect_turn_before:
        _fail("real container inspection failed or consumed a turn")
        return
    if not _inspection_has_item(inspection, item_id):
        _fail("inspection did not expose exact real item identity")
        return

    var infected_ids: Array[String] = []
    for value: Variant in game.call("simple_infected_actor_ids"):
        infected_ids.append(String(value))
    if infected_ids.size() < 3:
        _fail("not enough production infected for bounded-action proof")
        return
    var attacker := infected_ids[0]
    var combat_target := infected_ids[1]
    var distant := infected_ids[2]
    if not _place_adjacent_attacker(world, attacker, container_id):
        _fail("could not place adjacent infected for inventory-turn proof")
        return
    var player_pos: WorldPlacement = world.placement(PLAYER_ID)
    if player_pos == null or not world.move_entity(distant, player_pos.anchor + Vector2i(40, 40), Facing.Value.WEST):
        _fail("could not place distant infected")
        return
    for index in range(3, infected_ids.size()):
        world.move_entity(infected_ids[index], player_pos.anchor + Vector2i(40 + index, 40), Facing.Value.WEST)

    var search_turn_before: int = turns.turn_number()
    var actor_actions_before: int = turns.individual_actor_actions()
    var hp_before: int = health.current_hp(PLAYER_ID)
    var distant_before: WorldPlacement = world.placement(distant)
    var tick_before: int = legacy_kernel.world_tick()
    var search_result: Dictionary = turns.search_loot_container(container_id)
    if not bool(search_result.get("success", false)):
        _fail("real loot search rejected: %s" % String(search_result.get("reason", "unknown")))
        return
    if turns.turn_number() != search_turn_before + 1:
        _fail("search did not consume exactly one ordinary turn")
        return
    if turns.individual_actor_actions() != actor_actions_before + 1 or health.current_hp(PLAYER_ID) >= hp_before:
        _fail("nearby infected did not receive exactly one ordinary response to search")
        return
    var distant_after: WorldPlacement = world.placement(distant)
    if distant_before == null or distant_after == null or distant_before.anchor != distant_after.anchor:
        _fail("distant infected received an inventory-turn action")
        return
    if legacy_kernel.world_tick() != tick_before:
        _fail("search advanced retired TickKernel")
        return
    if not turns.has_control():
        _fail("control not returned after search")
        return

    # Keep later inventory assertions deterministic and focused.
    player_pos = world.placement(PLAYER_ID)
    world.move_entity(attacker, player_pos.anchor + Vector2i(42, 40), Facing.Value.WEST)

    var source_version_before_take: int = containment.container_version(container_id)
    var take_turn_before: int = turns.turn_number()
    tick_before = legacy_kernel.world_tick()
    var take_result: Dictionary = turns.take_loot_item(container_id, item_id)
    if not bool(take_result.get("success", false)):
        _fail("take failed: %s" % String(take_result.get("reason", "unknown")))
        return
    if turns.turn_number() != take_turn_before + 1 or legacy_kernel.world_tick() != tick_before:
        _fail("take did not consume exactly one simple turn or advanced TickKernel")
        return
    if containment.container_of(item_id) != PLAYER_ID or containment.direct_contents(container_id).has(item_id):
        _fail("exact item did not move from source to player containment")
        return
    if containment.container_version(container_id) <= source_version_before_take:
        _fail("source container version did not reflect exact removal")
        return
    var revisit: Dictionary = game._loot_inspection.query(PLAYER_ID, container_id)
    if _inspection_has_item(revisit, item_id):
        _fail("removed item respawned when revisiting source")
        return

    # Rejected actions consume no turn and do not mutate truth.
    var rejected_turn_before: int = turns.turn_number()
    var owner_before: String = containment.container_of(item_id)
    var rejected: Dictionary = turns.take_loot_item(container_id, item_id)
    if bool(rejected.get("success", false)) or turns.turn_number() != rejected_turn_before or containment.container_of(item_id) != owner_before:
        _fail("rejected duplicate take mutated state or consumed a turn")
        return

    # Equip exact identity and prove migrated combat reads that equipment truth.
    var equip_turn_before: int = turns.turn_number()
    tick_before = legacy_kernel.world_tick()
    var equip_result: Dictionary = turns.equip_inventory_item(item_id, Slots.Value.PRIMARY_RIGHT)
    if not bool(equip_result.get("success", false)):
        _fail("equip failed: %s" % String(equip_result.get("reason", "unknown")))
        return
    if turns.turn_number() != equip_turn_before + 1 or legacy_kernel.world_tick() != tick_before:
        _fail("equip turn semantics invalid")
        return
    if hands.primary_item(PLAYER_ID) != item_id or containment.is_contained(item_id):
        _fail("equip duplicated/orphaned exact item identity")
        return

    var arena := _find_clear_arena(world)
    if arena == Vector2i(-999999, -999999):
        _fail("could not locate combat regression arena")
        return
    if not world.move_entity(PLAYER_ID, arena, Facing.Value.EAST):
        _fail("could not position player for combat regression")
        return
    if not world.move_entity(combat_target, arena + Vector2i.RIGHT, Facing.Value.WEST):
        _fail("could not position combat target")
        return
    if not health.set_hp(combat_target, health.max_hp(combat_target)):
        _fail("could not reset combat target")
        return
    var expected_damage: int = turns._derived_melee_damage(turns._melee_profile(PLAYER_ID))
    var target_hp_before: int = health.current_hp(combat_target)
    var combat_turn_before: int = turns.turn_number()
    tick_before = legacy_kernel.world_tick()
    turns.submit_intent(Intents.COMBAT_FORWARD)
    if turns.turn_number() != combat_turn_before + 1 or legacy_kernel.world_tick() != tick_before:
        _fail("protected Slice 3 combat turn semantics regressed")
        return
    if health.current_hp(combat_target) != maxi(0, target_hp_before - expected_damage):
        _fail("migrated combat did not read the newly equipped exact item")
        return

    # Stow, drop and pick up preserve the same entity.
    var stow_turn_before: int = turns.turn_number()
    var stow_result: Dictionary = turns.stow_equipped_item(Slots.Value.PRIMARY_RIGHT)
    if not bool(stow_result.get("success", false)) or turns.turn_number() != stow_turn_before + 1:
        _fail("stow failed or wrong turn cost")
        return
    if not hands.primary_item(PLAYER_ID).is_empty() or containment.container_of(item_id) != PLAYER_ID:
        _fail("stow did not return exact item to player containment")
        return

    var drop_turn_before: int = turns.turn_number()
    tick_before = legacy_kernel.world_tick()
    var drop_result: Dictionary = turns.drop_inventory_item(item_id)
    if not bool(drop_result.get("success", false)) or turns.turn_number() != drop_turn_before + 1 or legacy_kernel.world_tick() != tick_before:
        _fail("drop failed or used legacy timing")
        return
    var dropped: WorldPlacement = world.placement(item_id)
    if containment.is_contained(item_id) or dropped == null or dropped.channel != Layers.Channel.LOOSE_ITEM:
        _fail("drop did not create authoritative loose exact item")
        return

    var pickup_turn_before: int = turns.turn_number()
    var pickup_result: Dictionary = turns.pickup_loose_item(item_id)
    if not bool(pickup_result.get("success", false)) or turns.turn_number() != pickup_turn_before + 1:
        _fail("pickup of dropped exact item failed")
        return
    if world.placement(item_id) != null or containment.container_of(item_id) != PLAYER_ID:
        _fail("pickup did not restore same exact item to personal containment")
        return

    # Return the same item to the original real loot source.
    if not _place_player_for_container(world, container_id):
        _fail("could not return player to original loot source")
        return
    var store_turn_before: int = turns.turn_number()
    var store_result: Dictionary = turns.store_loot_item(container_id, item_id)
    if not bool(store_result.get("success", false)) or turns.turn_number() != store_turn_before + 1:
        _fail("store failed or wrong turn cost")
        return
    if containment.container_of(item_id) != container_id:
        _fail("store did not restore exact identity to real source")
        return
    var restored_view: Dictionary = game._loot_inspection.query(PLAYER_ID, container_id)
    if not _inspection_has_item(restored_view, item_id):
        _fail("stored exact item not visible when revisiting source")
        return

    print("SLICE4_SCAVENGE_INVENTORY_OK seed=%d turns=%d container=%s item=%s melee_damage=%d" % [
        REGRESSION_SEED,
        turns.turn_number(),
        container_id,
        item_id,
        expected_damage,
    ])
    quit(0)

func _real_loot_source(game: Node) -> Dictionary:
    for container_id: String in game._loot_state.container_ids():
        var inspection: Dictionary = game._loot_inspection.query(PLAYER_ID, container_id)
        if not bool(inspection.get("ok", false)):
            continue
        for value: Variant in inspection.get("items", []):
            if typeof(value) != TYPE_DICTIONARY:
                continue
            var item: Dictionary = value
            var item_id: String = String(item.get("item_id", ""))
            var semantic: String = String(item.get("semantic_type", ""))
            if not item_id.is_empty() and bool(item.get("valid", false)) and semantic != "item.firearm.service_pistol":
                return {"container_id": container_id, "item_id": item_id}
    return {}

func _place_player_for_container(world: WorldState, container_id: String) -> bool:
    var container: WorldPlacement = world.placement(container_id)
    if container == null:
        return false
    var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
    for target_cell: Vector2i in container.world_cells():
        for direction: Vector2i in directions:
            var player_cell := target_cell - direction
            if not world.has_terrain(player_cell):
                continue
            var blocked := false
            for actor_id: String in world.entities_at(player_cell, Layers.Channel.ACTOR):
                if actor_id != PLAYER_ID:
                    blocked = true
                    break
            if blocked:
                continue
            return world.move_entity(PLAYER_ID, player_cell, Facing.from_vector(direction))
    return false

func _place_adjacent_attacker(world: WorldState, actor_id: String, container_id: String) -> bool:
    var player: WorldPlacement = world.placement(PLAYER_ID)
    var container: WorldPlacement = world.placement(container_id)
    if player == null or container == null:
        return false
    var container_cells: Dictionary = {}
    for cell: Vector2i in container.world_cells():
        container_cells[cell] = true
    for delta: Vector2i in [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]:
        var cell := player.anchor + delta
        if container_cells.has(cell) or not world.has_terrain(cell):
            continue
        return world.move_entity(actor_id, cell, Facing.from_vector(-delta))
    return false

func _inspection_has_item(inspection: Dictionary, item_id: String) -> bool:
    for value: Variant in inspection.get("items", []):
        if typeof(value) == TYPE_DICTIONARY and String((value as Dictionary).get("item_id", "")) == item_id:
            return true
    return false

func _find_clear_arena(world: WorldState) -> Vector2i:
    var player: WorldPlacement = world.placement(PLAYER_ID)
    if player == null:
        return Vector2i(-999999, -999999)
    for radius in range(0, 10):
        for y in range(-radius, radius + 1):
            for x in range(-radius, radius + 1):
                if radius > 0 and absi(x) != radius and absi(y) != radius:
                    continue
                var center := player.anchor + Vector2i(x, y)
                var cells := [center, center + Vector2i.RIGHT]
                var valid := true
                for cell: Vector2i in cells:
                    if not world.has_terrain(cell):
                        valid = false
                        break
                    for actor_id: String in world.entities_at(cell, Layers.Channel.ACTOR):
                        if actor_id != PLAYER_ID:
                            valid = false
                            break
                    if not valid:
                        break
                if valid:
                    return center
    return Vector2i(-999999, -999999)
