extends SceneTree

const Store = preload("res://scripts/persistence/DurableSessionStore.gd")
const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const WorldActions = preload("res://scripts/simulation/interaction/WorldInteractionActionService.gd")
const Sustainment = preload("res://scripts/simulation/interaction/SustainmentInteractionOfferProvider.gd")
const Conditions = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const Reach = preload("res://scripts/simulation/interaction/WorldInteractionReachQuery.gd")
const DoorValue = preload("res://scripts/simulation/doors/DoorStateValue.gd")

const PLAYER_ID := "actor.player"
const INVALID_CELL := Vector2i(-999999, -999999)

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _cleanup_default_save()
    root.size = Vector2i(390, 844)

    var startup_ms := Time.get_ticks_msec()
    var game = await _boot_real_new_game()
    if game == null:
        _finish()
        return
    startup_ms = Time.get_ticks_msec() - startup_ms

    _check(String(game.get_script().resource_path) == "res://scripts/app/ProductionGameMain.gd", "real startup reaches ProductionGameMain")
    _check(game.session_boot_ok(), "production session boot succeeds")
    _check(String(game.session_boot_error()).is_empty(), "production reports no boot error")

    var initial := _diagnostic_snapshot(game)
    print("RELEASE_DIAG startup_ms=%d seed=%d active_infected=%d known_infected=%d nearby_containers=%d nearby_items=%d nearby_consumables=%d nearby_tools=%d nearby_medical=%d nearby_materials=%d wide_consumables=%d wide_tools=%d active_regions=%d save_bytes=%d conditions=%s" % [
        startup_ms,
        Bootstrap.active_seed(),
        int(initial.get("active_infected", 0)),
        int(initial.get("known_infected", 0)),
        int(initial.get("nearby_containers", 0)),
        int(initial.get("nearby_items", 0)),
        int(initial.get("nearby_consumables", 0)),
        int(initial.get("nearby_tools", 0)),
        int(initial.get("nearby_medical", 0)),
        int(initial.get("nearby_materials", 0)),
        int(initial.get("wide_consumables", 0)),
        int(initial.get("wide_tools", 0)),
        int(initial.get("active_regions", 0)),
        int(initial.get("save_bytes", 0)),
        str(initial.get("conditions", {})),
    ])

    _check(int(initial.get("active_regions", 99)) <= 9, "streaming active work is bounded to at most 3x3 regions")
    _check(int(initial.get("nearby_containers", 0)) > 0, "generated start has at least one materialized loot container within expedition range")
    _check(int(initial.get("nearby_items", 0)) > 0, "generated start exposes real loot within expedition range")
    _check(int(initial.get("nearby_consumables", 0)) > 0, "generated start exposes food/drink within expedition range")
    _print_save_sizes("initial", game.durable_session_snapshot())

    var simple = game.simple_turn_controller()
    var kernel_before := int(game.get("_kernel").world_tick())
    var world_time_before := int(game.get("_world_time").world_tick())
    var action_count_before := int(simple.individual_actor_actions())
    var active_before: int = game.active_infected_ids().size()
    _check(_perform_real_movement(game), "player can perform real movement from production start")
    var action_delta := int(simple.individual_actor_actions()) - action_count_before
    var active_after: int = game.active_infected_ids().size()
    _check(action_delta <= maxi(active_before, active_after), "one movement action produces bounded local infected work")
    _check(int(game.get("_kernel").world_tick()) == kernel_before, "canonical movement does not advance compatibility TickKernel")
    _check(int(game.get("_world_time").world_tick()) > world_time_before, "canonical movement advances authoritative world time")

    var loot_result := _exercise_real_loot(game)
    _check(bool(loot_result.get("ok", false)), "real generated loot can be searched and an exact item taken")
    var taken_item := String(loot_result.get("item_id", ""))
    if not taken_item.is_empty() and bool(loot_result.get("consumable", false)):
        var consume_result: Dictionary = game.run_simple_inventory_consumption(taken_item)
        _check(bool(consume_result.get("success", false)), "real looted food/drink can be consumed through canonical action")
    else:
        _check(_exercise_consumption_fixture(game), "canonical exact-item consumption works")

    _check(_exercise_combat_fixture(game), "representative canonical melee combat works")
    _check(_exercise_real_context(game), "representative generated door/window contextual action works")
    _check(_exercise_crafting_fixture(game), "representative canonical crafting works")

    var far_fixture := _install_far_infected_fixture(game)
    _check(bool(far_fixture.get("ok", false)), "far persistent infected fixture installed outside active neighborhood")
    var far_id := String(far_fixture.get("actor_id", ""))
    var far_before := INVALID_CELL
    if not far_id.is_empty() and game.get("_world").placement(far_id) != null:
        far_before = game.get("_world").placement(far_id).anchor

    var long_time_before := int(game.get("_world_time").world_tick())
    var long_actor_before := int(simple.individual_actor_actions())
    var active_for_long: int = game.active_infected_ids().size()
    var eight_hours := int(game.get("_world_time_profile").ticks_per_hour()) * 8
    game.set("_simple_elapsed_override_ticks", eight_hours)
    _check(simple._begin_direct_action(&"condition.sleep"), "long survival action begins")
    var long_result: Dictionary = simple._complete_direct_action(&"condition.sleep", "")
    _check(bool(long_result.get("success", false)), "long survival action completes")
    _check(int(game.get("_world_time").world_tick()) - long_time_before == eight_hours, "eight-hour action advances world time exactly once")
    _check(int(simple.individual_actor_actions()) - long_actor_before <= active_for_long, "eight-hour action does not multiply zombie turns")
    if not far_id.is_empty() and far_before != INVALID_CELL:
        var far_after = game.get("_world").placement(far_id)
        _check(far_after != null and far_after.anchor == far_before, "far infected remains dormant through long time jump")

    var after_daypart: Dictionary = game.get("_condition_service").values(PLAYER_ID)
    print("RELEASE_DIAG post_8h_conditions=%s weather=%s time=%s" % [
        str(after_daypart),
        str(game.canonical_weather_snapshot()),
        str(game.canonical_world_time_snapshot()),
    ])
    _check(int(after_daypart.get(String(Conditions.SATIETY), -1)) >= 20, "eight-hour interval does not collapse satiety")
    _check(int(after_daypart.get(String(Conditions.HYDRATION), -1)) >= 15, "eight-hour interval does not make hydration immediately catastrophic")

    _check(_systems_available(game), "release-critical systems remain wired")

    var world = game.get("_world")
    var saved_player = world.placement(PLAYER_ID)
    var saved_anchor: Vector2i = saved_player.anchor
    var saved_facing: int = saved_player.facing
    var saved_hp := int(game.get("_health_state").current_hp(PLAYER_ID))
    var saved_time := int(game.get("_world_time").world_tick())
    var durable_before: Dictionary = game.durable_session_snapshot()
    var save_bytes := var_to_bytes(durable_before).size()
    _print_save_sizes("post_expedition", durable_before)
    print("RELEASE_DIAG durable_payload_bytes=%d world_entities=%d active_infected=%d known_infected=%d" % [
        save_bytes,
        game.get("_world").entity_ids().size(),
        game.active_infected_ids().size(),
        game.known_infected_ids().size(),
    ])

    game._on_shell_save_menu_requested()
    var menu = await _wait_for_scene_script("res://scripts/ui/StartupMenu.gd", 360)
    _check(menu != null, "SAVE & MENU returns through real StartupMenu")
    if menu == null:
        _finish()
        return

    _check(Store.new().has_compatible_save(), "real SAVE & MENU produced a compatible durable save")
    _check(_compressed_primary_save_is_valid(), "production save uses compressed payload envelope")
    _check(_legacy_uncompressed_envelope_loads(durable_before), "current store still reads pre-Slice-15 uncompressed save envelopes")
    menu.call("_on_continue_pressed")
    var continued = await _wait_for_scene_script("res://scripts/app/ProductionGameMain.gd", 480)
    _check(continued != null, "real StartupMenu CONTINUE returns to gameplay")
    if continued == null:
        _finish()
        return
    _check(continued.session_boot_ok(), "Continue session boots successfully")

    var restored = continued.get("_world").placement(PLAYER_ID)
    _check(restored != null and restored.anchor == saved_anchor and restored.facing == saved_facing, "Continue restores player location/facing")
    _check(int(continued.get("_health_state").current_hp(PLAYER_ID)) == saved_hp, "Continue restores player Health")
    _check(int(continued.get("_world_time").world_tick()) == saved_time, "Continue restores authoritative world time")
    _check(continued.durable_session_snapshot().get("world_seed", 0) == durable_before.get("world_seed", -1), "Continue restores same procedural world seed")
    if not far_id.is_empty():
        var restored_far = continued.get("_world").placement(far_id)
        _check(restored_far != null and restored_far.anchor == far_before, "Continue preserves far dormant infected")

    var idle_time := int(continued.get("_world_time").world_tick())
    var idle_actions := int(continued.simple_turn_controller().individual_actor_actions())
    for _i in range(30):
        await process_frame
    _check(int(continued.get("_world_time").world_tick()) == idle_time, "idle frames do not advance world time")
    _check(int(continued.simple_turn_controller().individual_actor_actions()) == idle_actions, "idle frames do not run actor simulation")

    _check(continued.get("_controller") == null and continued.get("_vehicle_controller") == null and continued.get("_combat_controller") == null, "deleted Slice 14 controller graph is not reconstructed")

    _cleanup_default_save()
    _finish()

func _boot_real_new_game():
    for script_path: String in [
        "res://scripts/app/GameMain.gd",
        "res://scripts/app/CraftingGameMain.gd",
        "res://scripts/app/UtilityGameMain.gd",
        "res://scripts/app/System34GameMain.gd",
        "res://scripts/app/VehicleGameMain.gd",
        "res://scripts/app/CombatGameMain.gd",
        "res://scripts/app/EnvironmentalPressureGameMain.gd",
        "res://scripts/app/TurnBasedGameMain.gd",
        "res://scripts/app/Slice7GameMain.gd",
        "res://scripts/app/FortificationGameMain.gd",
        "res://scripts/app/UtilitySimpleGameMain.gd",
        "res://scripts/app/VehicleSimpleGameMain.gd",
        "res://scripts/app/ProductionGameMain.gd",
    ]:
        var script_resource := load(script_path)
        _check(script_resource != null, "fresh script load succeeds: %s" % script_path)
        if script_resource == null:
            return null

    var packed := load("res://main.tscn") as PackedScene
    _check(packed != null, "main.tscn loads")
    if packed == null:
        return null
    var menu = packed.instantiate()
    root.add_child(menu)
    current_scene = menu
    await process_frame
    await process_frame
    menu.call("_launch_game", {})
    return await _wait_for_scene_script("res://scripts/app/ProductionGameMain.gd", 480)

func _wait_for_scene_script(path: String, frames: int):
    for _i in range(frames):
        await process_frame
        if current_scene != null and current_scene.get_script() != null and String(current_scene.get_script().resource_path) == path:
            return current_scene
    return null

func _diagnostic_snapshot(game) -> Dictionary:
    var world = game.get("_world")
    var player = world.placement(PLAYER_ID)
    var loot_state = game.get("_loot_state")
    var inventory = game.get("_inventory_state")
    var loot_items = game.get("_loot_items")
    var sustainment = game.get("_sustainment_profiles")
    var nearby_containers := 0
    var nearby_items := 0
    var nearby_consumables := 0
    var nearby_tools := 0
    var nearby_medical := 0
    var nearby_materials := 0
    if player != null:
        for container_id: String in loot_state.container_ids():
            var placement = world.placement(container_id)
            if placement == null or _chebyshev(player.anchor, placement.anchor) > 48:
                continue
            nearby_containers += 1
            for item_id: String in inventory.direct_contents(container_id):
                if not world.has_entity(item_id):
                    continue
                nearby_items += 1
                var entity = world.entity(item_id)
                if entity == null:
                    continue
                if sustainment.has_profile(entity.semantic_type):
                    nearby_consumables += 1
                var family := String(loot_items.family(entity.semantic_type))
                if family == "tools":
                    nearby_tools += 1
                elif family == "medical":
                    nearby_medical += 1
                elif family == "construction":
                    nearby_materials += 1
    var wide_consumables := 0
    var wide_tools := 0
    if player != null:
        for container_id: String in loot_state.container_ids():
            var placement = world.placement(container_id)
            if placement == null or _chebyshev(player.anchor, placement.anchor) > 96:
                continue
            for item_id: String in inventory.direct_contents(container_id):
                if not world.has_entity(item_id):
                    continue
                var entity = world.entity(item_id)
                if entity == null:
                    continue
                if sustainment.has_profile(entity.semantic_type):
                    wide_consumables += 1
                if String(loot_items.family(entity.semantic_type)) == "tools":
                    wide_tools += 1
    var streaming = Bootstrap.streaming_coordinator()
    return {
        "active_infected": game.active_infected_ids().size(),
        "known_infected": game.known_infected_ids().size(),
        "nearby_containers": nearby_containers,
        "nearby_items": nearby_items,
        "nearby_consumables": nearby_consumables,
        "nearby_tools": nearby_tools,
        "nearby_medical": nearby_medical,
        "nearby_materials": nearby_materials,
        "wide_consumables": wide_consumables,
        "wide_tools": wide_tools,
        "active_regions": 0 if streaming == null else streaming.active_region_coords().size(),
        "save_bytes": var_to_bytes(game.durable_session_snapshot()).size(),
        "conditions": game.get("_condition_service").values(PLAYER_ID),
    }

func _perform_real_movement(game) -> bool:
    var simple = game.simple_turn_controller()
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    for _attempt in range(4):
        var player = world.placement(PLAYER_ID)
        var target: Vector2i = player.anchor + Facing.vector(player.facing)
        var check = query.query_cell(target, PLAYER_ID, true)
        if check != null and check.is_clear():
            var before: Vector2i = player.anchor
            simple.submit_intent(Intents.FORWARD)
            return world.placement(PLAYER_ID).anchor != before
        simple.submit_intent(Intents.TURN_RIGHT)
    return false

func _exercise_real_loot(game) -> Dictionary:
    var world = game.get("_world")
    var loot_state = game.get("_loot_state")
    var inventory = game.get("_inventory_state")
    var sustainment = game.get("_sustainment_profiles")
    var player = world.placement(PLAYER_ID)
    var candidates: Array[Dictionary] = []
    for container_id: String in loot_state.container_ids():
        var placement = world.placement(container_id)
        if placement == null:
            continue
        var contents: Array[String] = inventory.direct_contents(container_id)
        if contents.is_empty():
            continue
        candidates.append({
            "container_id": container_id,
            "distance": _chebyshev(player.anchor, placement.anchor),
        })
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["distance"]) < int(b["distance"]))
    for candidate: Dictionary in candidates:
        var container_id := String(candidate["container_id"])
        if not _place_player_reachable(game, container_id):
            continue
        var search: Dictionary = game.simple_turn_controller().search_loot_container(container_id)
        if not bool(search.get("success", false)):
            continue
        var contents: Array[String] = inventory.direct_contents(container_id)
        if contents.is_empty():
            continue
        var preferred := contents[0]
        var consumable := false
        for item_id: String in contents:
            var entity = world.entity(item_id)
            if entity != null and sustainment.has_profile(entity.semantic_type):
                preferred = item_id
                consumable = true
                break
        var take: Dictionary = game.simple_turn_controller().take_loot_item(container_id, preferred)
        if bool(take.get("success", false)):
            return {"ok": true, "item_id": preferred, "consumable": consumable, "container_id": container_id}
    return {"ok": false}

func _exercise_consumption_fixture(game) -> bool:
    var item_id := "slice15.consume.water"
    var world = game.get("_world")
    if world.has_entity(item_id):
        world.remove_entity(item_id)
    if game.get("_world_mutations").create_entity(&"item.drink.water_bottle", item_id) != item_id:
        return false
    if not game.get("_inventory_mutations").set_container(item_id, PLAYER_ID):
        world.remove_entity(item_id)
        return false
    var result: Dictionary = game.run_simple_inventory_consumption(item_id)
    return bool(result.get("success", false)) and not world.has_entity(item_id)

func _exercise_combat_fixture(game) -> bool:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    var player = world.placement(PLAYER_ID)
    if player == null:
        return false
    var chosen_facing := -1
    var target_cell := INVALID_CELL
    for facing_value: int in [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]:
        var cell: Vector2i = player.anchor + Facing.vector(facing_value)
        var check = query.query_cell(cell, "", true)
        if check != null and check.is_clear():
            chosen_facing = facing_value
            target_cell = cell
            break
    if chosen_facing < 0:
        return false
    if not world.move_entity(PLAYER_ID, player.anchor, chosen_facing):
        return false
    var actor_id := "slice15.infected.combat"
    if world.has_entity(actor_id):
        world.remove_entity(actor_id)
    if world.create_entity(&"actor.survivor", actor_id) != actor_id:
        return false
    if not world.set_placement(actor_id, Layers.Channel.ACTOR, target_cell, Facing.from_vector(player.anchor - target_cell), Footprint.single_cell()):
        world.remove_entity(actor_id)
        return false
    if not game.call("_ensure_simple_infected_state", actor_id):
        return false
    var known: Array[String] = game.simple_infected_actor_ids()
    if not known.has(actor_id):
        known.append(actor_id)
    game.set("_simple_infected_ids", known)
    if not game.call("_refresh_simulation_boundary"):
        return false
    var hp_before := int(game.get("_health_state").current_hp(actor_id))
    game.simple_turn_controller().submit_intent(Intents.COMBAT_FORWARD)
    var hp_after := int(game.get("_health_state").current_hp(actor_id))
    return hp_after < hp_before

func _exercise_real_context(game) -> bool:
    var world = game.get("_world")
    var catalog = game.get("_world_interaction_catalog")
    var state = game.get("_world_interaction_state")
    var door_state = game.get("_door_state")
    for target_id: String in world.entity_ids():
        var entity = world.entity(target_id)
        if entity == null or not catalog.is_door(entity.semantic_type) or not door_state.has_door(target_id):
            continue
        if not _place_player_reachable(game, target_id):
            continue
        state.set_locked(target_id, false, &"slice15_acceptance")
        state.set_board_count(target_id, 0, &"slice15_acceptance")
        state.set_broken(target_id, false, &"slice15_acceptance")
        var action_id: StringName = WorldActions.DOOR_CLOSE if door_state.state(target_id) == DoorValue.OPEN else WorldActions.DOOR_OPEN
        var result: Dictionary = game.run_simple_contextual_action(PLAYER_ID, target_id, action_id)
        if bool(result.get("success", false)):
            return true
    return false

func _exercise_crafting_fixture(game) -> bool:
    var world = game.get("_world")
    for spec in [
        ["slice15.craft.paper", &"item.junk.stale_newspaper"],
        ["slice15.craft.cardboard", &"item.junk.worn_cardboard"],
        ["slice15.craft.scissors", &"item.office.scissors"],
    ]:
        var item_id: String = spec[0]
        var semantic: StringName = spec[1]
        if world.has_entity(item_id):
            world.remove_entity(item_id)
        if game.get("_world_mutations").create_entity(semantic, item_id) != item_id:
            return false
        if not game.get("_inventory_mutations").set_container(item_id, PLAYER_ID):
            return false
    var result: Dictionary = game.run_simple_craft(&"crafting.paper_bundle", "")
    return bool(result.get("success", false))

func _install_far_infected_fixture(game) -> Dictionary:
    var streaming = Bootstrap.streaming_coordinator()
    var plan = Bootstrap.global_plan()
    var world = game.get("_world")
    var player = world.placement(PLAYER_ID)
    if streaming == null or plan == null or player == null:
        return {"ok": false}
    var active_bounds: Array[Rect2i] = streaming.active_region_bounds()
    for bounds: Rect2i in active_bounds:
        for candidate: Vector2i in [
            bounds.position + Vector2i(bounds.size.x + 48, bounds.size.y / 2),
            bounds.position + Vector2i(-48, bounds.size.y / 2),
            bounds.position + Vector2i(bounds.size.x / 2, bounds.size.y + 48),
            bounds.position + Vector2i(bounds.size.x / 2, -48),
        ]:
            if not plan.bounds.has_point(candidate) or streaming.is_cell_active(candidate):
                continue
            var focus: Dictionary = streaming.update_focus(candidate)
            if not bool(focus.get("ok", false)):
                continue
            var far_cell := _find_clear_cell(game, candidate, 0, 18, true)
            if far_cell == INVALID_CELL:
                streaming.update_focus(player.anchor)
                continue
            var actor_id := "slice15.infected.far"
            if world.has_entity(actor_id):
                world.remove_entity(actor_id)
            if world.create_entity(&"actor.survivor", actor_id) != actor_id:
                streaming.update_focus(player.anchor)
                continue
            if not world.set_placement(actor_id, Layers.Channel.ACTOR, far_cell, Facing.Value.SOUTH, Footprint.single_cell()):
                world.remove_entity(actor_id)
                streaming.update_focus(player.anchor)
                continue
            if not game.call("_ensure_simple_infected_state", actor_id):
                world.remove_entity(actor_id)
                streaming.update_focus(player.anchor)
                continue
            var known: Array[String] = game.simple_infected_actor_ids()
            if not known.has(actor_id):
                known.append(actor_id)
            game.set("_simple_infected_ids", known)
            streaming.update_focus(player.anchor)
            game.call("_refresh_simulation_boundary")
            if game.active_infected_ids().has(actor_id):
                return {"ok": false}
            return {"ok": true, "actor_id": actor_id, "cell": far_cell}
    return {"ok": false}

func _place_player_reachable(game, target_id: String) -> bool:
    var world = game.get("_world")
    var target = world.placement(target_id)
    var query = game.get("_spatial_query")
    if target == null:
        return false
    for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
        var cell: Vector2i = target.anchor + direction
        var check = query.query_cell(cell, PLAYER_ID, true)
        if check == null or not check.is_clear():
            continue
        var facing := Facing.from_vector(target.anchor - cell)
        if facing < 0:
            continue
        if world.move_entity(PLAYER_ID, cell, facing):
            var reach = game.get("_interaction_reach")
            if reach != null and reach.target_reachable(PLAYER_ID, target_id, Reach.CONTACT_FORWARD):
                game.call("_refresh_simulation_boundary")
                return true
    return false

func _find_clear_cell(game, origin: Vector2i, min_radius: int, max_radius: int, require_active: bool) -> Vector2i:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    for radius in range(min_radius, max_radius + 1):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if radius > 0 and absi(dx) != radius and absi(dy) != radius:
                    continue
                var cell := origin + Vector2i(dx, dy)
                if require_active and not game.cell_active(cell):
                    continue
                if not world.has_terrain(cell):
                    continue
                var check = query.query_cell(cell, "", true)
                if check != null and check.is_clear():
                    return cell
    return INVALID_CELL

func _print_save_sizes(label: String, session: Dictionary) -> void:
    var raw: PackedByteArray = var_to_bytes(session)
    var compressed: PackedByteArray = raw.compress(FileAccess.COMPRESSION_DEFLATE)
    print("RELEASE_DIAG save_%s raw=%d deflate=%d ratio=%.3f" % [
        label, raw.size(), compressed.size(),
        0.0 if raw.is_empty() else float(compressed.size()) / float(raw.size())
    ])
    var owners_value: Variant = session.get("owners", {})
    if typeof(owners_value) != TYPE_DICTIONARY:
        return
    var rows: Array[Dictionary] = []
    var owners: Dictionary = owners_value
    for key: Variant in owners.keys():
        rows.append({"key": String(key), "bytes": var_to_bytes(owners[key]).size()})
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["bytes"]) > int(b["bytes"]))
    for row: Dictionary in rows:
        print("RELEASE_DIAG save_owner_%s %s=%d" % [label, String(row["key"]), int(row["bytes"])])

func _compressed_primary_save_is_valid() -> bool:
    var file := FileAccess.open(Store.DEFAULT_PRIMARY_PATH, FileAccess.READ)
    if file == null:
        return false
    var envelope: Variant = file.get_var(false)
    var file_size := file.get_length()
    file.close()
    if typeof(envelope) != TYPE_DICTIONARY:
        return false
    var data: Dictionary = envelope
    var payload_value: Variant = data.get("payload", PackedByteArray())
    if typeof(payload_value) != TYPE_PACKED_BYTE_ARRAY:
        return false
    var payload: PackedByteArray = payload_value
    var raw_size := int(data.get("payload_uncompressed_size", -1))
    print("RELEASE_DIAG stored_save_file_bytes=%d compressed_payload_bytes=%d uncompressed_payload_bytes=%d" % [file_size, payload.size(), raw_size])
    return String(data.get("payload_compression", "")) == "deflate" and raw_size > payload.size() and payload.size() > 0

func _legacy_uncompressed_envelope_loads(session: Dictionary) -> bool:
    var legacy_primary := "user://slice15_uncompressed_compat.save"
    var legacy_backup := "user://slice15_uncompressed_compat.backup.save"
    var legacy_temp := "user://slice15_uncompressed_compat.tmp.save"
    for path in [legacy_primary, legacy_backup, legacy_temp]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var payload: PackedByteArray = var_to_bytes(session)
    var envelope := {
        "format_schema_version": Store.FORMAT_SCHEMA_VERSION,
        "payload_sha256": _sha256(payload),
        "payload": payload,
    }
    var out := FileAccess.open(legacy_primary, FileAccess.WRITE)
    if out == null:
        return false
    out.store_var(envelope, false)
    var write_ok := out.get_error() == OK
    out.close()
    if not write_ok:
        return false
    var loaded: Dictionary = Store.new(legacy_primary, legacy_backup, legacy_temp).load_best()
    for path in [legacy_primary, legacy_backup, legacy_temp]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    return bool(loaded.get("ok", false))

func _sha256(bytes: PackedByteArray) -> String:
    var context := HashingContext.new()
    if context.start(HashingContext.HASH_SHA256) != OK:
        return ""
    if context.update(bytes) != OK:
        return ""
    return context.finish().hex_encode()

func _systems_available(game) -> bool:
    return game.get("_inventory_state") != null         and game.get("_hand_state") != null         and game.get("_health_state") != null         and game.get("_crafting_recipes") != null         and game.get("_first_aid_actions") != null         and game.get("_world_interaction_state") != null         and game.get("_utilities") != null         and game.get("_power_network") != null         and game.get("_portable_generators") != null         and game.get("_vehicle_state") != null         and game.get("_vehicle_profiles") != null         and game.get("_world_time") != null         and game.get("_weather") != null         and game.get("_perception") != null         and game.get("_ambient_daylight") != null

func _chebyshev(a: Vector2i, b: Vector2i) -> int:
    var d := a - b
    return maxi(absi(d.x), absi(d.y))

func _cleanup_default_save() -> void:
    for path in [Store.DEFAULT_PRIMARY_PATH, Store.DEFAULT_BACKUP_PATH, Store.DEFAULT_TEMP_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("SLICE15_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("SLICE15_RELEASE_ACCEPTANCE_OK")
        quit(0)
        return
    quit(1)
