extends SceneTree

const Store = preload("res://scripts/persistence/DurableSessionStore.gd")
const Bootstrap = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Conditions = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const Vehicles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const UtilityState = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")

const SEED := 20001
const SAVE_A := "user://slice13_verify.save"
const SAVE_B := "user://slice13_verify.backup.save"
const SAVE_T := "user://slice13_verify.tmp.save"
const INVALID_CELL := Vector2i(-999999, -999999)

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _cleanup_files()
    var game = await _boot_new_game()
    if game == null:
        _finish()
        return

    var freshness_query = game.get("_freshness_query")
    _check(freshness_query != null and freshness_query.get("_clock") == game.get("_world_time"), "freshness reads canonical world time rather than legacy TickKernel")

    var fixture: Dictionary = _establish_meaningful_state(game)
    _check(bool(fixture.get("ok", false)), "representative canonical persistence fixture established")
    if not bool(fixture.get("ok", false)):
        game.queue_free()
        await process_frame
        _finish()
        return

    _check(Bootstrap.active_seed() == SEED, "new game uses requested procedural seed")
    _check(game.save_menu_destination() == "res://main.tscn", "SAVE & MENU destination remains canonical")

    var save_result: Dictionary = game.call("save_durable_session", &"slice13_verifier")
    _check(bool(save_result.get("ok", false)), "real durable SAVE succeeds")
    var first_load: Dictionary = Store.new(SAVE_A, SAVE_B, SAVE_T).load_best()
    _check(bool(first_load.get("ok", false)), "saved session reloads from DurableSessionStore")
    if not bool(first_load.get("ok", false)):
        game.queue_free()
        await process_frame
        _finish()
        return

    var saved: Dictionary = first_load.get("session", {})
    _assert_schema2_contract(saved)
    var reference: Dictionary = _canonical_owners(saved)
    var far_id := String(fixture.get("far_infected_id", ""))
    var corpse_id := String(fixture.get("corpse_id", ""))
    var consumed_id := String(fixture.get("consumed_id", ""))
    var vehicle_id := String(fixture.get("vehicle_id", ""))
    var fortification_id := String(fixture.get("fortification_id", ""))
    var utility_component_id := String(fixture.get("utility_component_id", ""))
    var looted_item_id := String(fixture.get("looted_item_id", ""))

    game.queue_free()
    await process_frame

    var continued = await _boot_continue(saved)
    if continued == null:
        _finish()
        return
    _assert_restored_facts(continued, reference, far_id, corpse_id, consumed_id, vehicle_id, fortification_id, utility_component_id, looted_item_id, "first Continue")
    _check(int(continued.call("simple_turn_controller").turn_number()) == 0, "turn/controller runtime is reconstructed instead of persisted")
    var idle_before: Dictionary = _canonical_owners(continued.call("durable_session_snapshot"))
    var kernel_before := int(continued.get("_kernel").world_tick())
    for _i in range(20):
        await process_frame
    _check(_canonical_owners(continued.call("durable_session_snapshot")) == idle_before, "idle frames after Continue do not mutate durable gameplay state")
    _check(int(continued.get("_kernel").world_tick()) == kernel_before, "legacy TickKernel remains non-authoritative after Continue")

    var second_save: Dictionary = continued.call("save_durable_session", &"slice13_repeat")
    _check(bool(second_save.get("ok", false)), "second real SAVE succeeds")
    var second_load: Dictionary = Store.new(SAVE_A, SAVE_B, SAVE_T).load_best()
    _check(bool(second_load.get("ok", false)), "second saved session reloads")
    var second_session: Dictionary = second_load.get("session", {})
    _compare_canonical_owners(_canonical_owners(second_session), reference, "repeat save owner")

    continued.queue_free()
    await process_frame

    var continued_twice = await _boot_continue(second_session)
    if continued_twice == null:
        _finish()
        return
    _assert_restored_facts(continued_twice, reference, far_id, corpse_id, consumed_id, vehicle_id, fortification_id, utility_component_id, looted_item_id, "second Continue")
    _compare_canonical_owners(_canonical_owners(continued_twice.call("durable_session_snapshot")), reference, "second Continue idempotence owner")

    # Current schema-1 saves remain accepted, but their retired runtime payloads are
    # deliberately invalid here. Successful Continue proves canonical restore ignores them.
    var legacy: Dictionary = continued_twice.call("durable_session_snapshot").duplicate(true)
    legacy["schema_version"] = Store.LEGACY_SESSION_SCHEMA_VERSION
    var legacy_owners: Dictionary = legacy.get("owners", {})
    legacy_owners.erase("world_time")
    legacy_owners.erase("refrigeration")
    legacy_owners["kernel"] = {"retired_runtime_payload": "must_not_load"}
    legacy_owners["perception_memory"] = {"retired_runtime_payload": "must_not_load"}
    legacy_owners["combat_runtime"] = {"retired_runtime_payload": "must_not_load"}
    legacy["owners"] = legacy_owners
    _check(bool(Store.new(SAVE_A, SAVE_B, SAVE_T).validate_session(legacy).get("ok", false)), "current schema-1 lineage remains structurally compatible")
    var legacy_save: Dictionary = Store.new(SAVE_A, SAVE_B, SAVE_T).save(legacy)
    _check(bool(legacy_save.get("ok", false)), "schema-1 compatibility save writes through real store")
    var legacy_load: Dictionary = Store.new(SAVE_A, SAVE_B, SAVE_T).load_best()
    _check(bool(legacy_load.get("ok", false)), "schema-1 compatibility save reads through real store")

    continued_twice.queue_free()
    await process_frame

    var migrated = await _boot_continue(legacy_load.get("session", {}))
    if migrated != null:
        _assert_restored_facts(migrated, reference, far_id, corpse_id, consumed_id, vehicle_id, fortification_id, utility_component_id, looted_item_id, "schema-1 migration", true)
        var migrated_session: Dictionary = migrated.call("durable_session_snapshot")
        _check(int(migrated_session.get("schema_version", -1)) == Store.SESSION_SCHEMA_VERSION, "schema-1 Continue emits canonical schema 2 on next save")
        var legacy_ignored: Array[String] = ["refrigeration"]
        _compare_canonical_owners(_canonical_owners(migrated_session), reference, "schema-1 migration owner", legacy_ignored)
        _check(_canonical_owners(migrated_session).get("world_time", {}) == reference.get("world_time", {}), "schema-1 migration derives exact world time from restored survival anchors")
        _assert_legacy_refrigeration_migration(migrated_session)
        migrated.queue_free()
        await process_frame

    _cleanup_files()
    _finish()

func _boot_new_game():
    var packed := load("res://gameplay.tscn") as PackedScene
    _check(packed != null, "production gameplay scene loads")
    if packed == null:
        return null
    var game = packed.instantiate()
    _check(game != null and game.has_method("slice13_runtime_owner_keys"), "production scene composes Slice13GameMain")
    if game == null:
        return null
    game.configure_session_paths(SAVE_A, SAVE_B, SAVE_T)
    _check(game.configure_world_seed_override(SEED), "new-game seed configured")
    root.add_child(game)
    await process_frame
    await process_frame
    _check(game.session_boot_ok(), "New Game boots: %s" % game.session_boot_error())
    return game if game.session_boot_ok() else null

func _boot_continue(session: Dictionary):
    var packed := load("res://gameplay.tscn") as PackedScene
    if packed == null:
        _check(false, "production gameplay scene reloads")
        return null
    var game = packed.instantiate()
    if game == null:
        _check(false, "production Continue scene instantiates")
        return null
    game.configure_session_paths(SAVE_A, SAVE_B, SAVE_T)
    _check(game.configure_continue_session(session), "Continue session accepted")
    root.add_child(game)
    await process_frame
    await process_frame
    _check(game.session_boot_ok(), "Continue boots: %s" % game.session_boot_error())
    return game if game.session_boot_ok() else null

func _establish_meaningful_state(game) -> Dictionary:
    var world = game.get("_world")
    var player_id := "actor.player"
    var simple = game.call("simple_turn_controller")

    _check(_move_player_one_cell(game), "player moves from initial placement through simple-turn route")
    _check(game.get("_health_state").apply_damage(player_id, 7), "player Health changed")
    _check(game.get("_condition_service").change_condition(player_id, Conditions.CALM, -5, &"slice13_fixture"), "player condition changed")

    var keep_id := "slice13.item.keep"
    var consumed_id := "slice13.item.consumed"
    if world.create_entity(&"item.tool.hammer", keep_id) != keep_id:
        return {"ok": false}
    if not game.get("_inventory_mutations").set_container(keep_id, player_id):
        return {"ok": false}
    var equip_slot := Slots.Value.PRIMARY_RIGHT
    if not game.get("_hand_state").item_in_slot(player_id, equip_slot).is_empty():
        equip_slot = Slots.Value.SECONDARY_LEFT
    if not game.get("_hand_state").item_in_slot(player_id, equip_slot).is_empty():
        game.get("_hand_mutations").clear_slot(player_id, equip_slot)
    if not game.get("_inventory_mutations").clear_container(keep_id):
        return {"ok": false}
    if not game.get("_hand_mutations").set_item(player_id, equip_slot, keep_id):
        return {"ok": false}

    if world.create_entity(&"item.material.wood_plank", consumed_id) != consumed_id:
        return {"ok": false}
    if not game.get("_inventory_mutations").set_container(consumed_id, player_id):
        return {"ok": false}
    if not game.get("_inventory_mutations").clear_container(consumed_id) or not world.remove_entity(consumed_id):
        return {"ok": false}

    var looted_item_id := _alter_loot_container(game)
    if looted_item_id.is_empty():
        return {"ok": false}

    var fortification_id := _fortify_existing_opening(game)
    if fortification_id.is_empty():
        return {"ok": false}

    var far_cell := _far_materialized_clear_cell(game)
    if far_cell == INVALID_CELL:
        return {"ok": false}
    var far_infected_id := "slice13.infected.far"
    if not _create_infected(game, far_infected_id, far_cell, 1):
        return {"ok": false}

    var dead_cell := _find_clear_cell(game, world.placement(player_id).anchor, 4, 16, true)
    if dead_cell == INVALID_CELL:
        return {"ok": false}
    var dead_id := "slice13.infected.dead"
    if not _create_infected(game, dead_id, dead_cell, 2):
        return {"ok": false}
    var max_hp := int(game.get("_health_state").max_hp(dead_id))
    if not game.get("_health_state").apply_damage(dead_id, max_hp):
        return {"ok": false}
    var corpse_id := String(game.get("_corpse_state").corpse_for_actor(dead_id))
    if corpse_id.is_empty():
        corpse_id = String(game.get("_death_transitions").transition_if_dead(dead_id))
    if corpse_id.is_empty():
        return {"ok": false}

    var known: Array[String] = game.call("simple_infected_actor_ids")
    for actor_id: String in [far_infected_id, dead_id]:
        if not known.has(actor_id):
            known.append(actor_id)
    game.set("_simple_infected_ids", known)
    if not game.call("_refresh_slice12_simulation_boundary"):
        return {"ok": false}
    _check(not game.call("slice12_active_infected_ids").has(far_infected_id), "far infected is persistent but dormant before save")

    var vehicle_id := _install_vehicle_fixture(game)
    if vehicle_id.is_empty():
        return {"ok": false}

    var utility_component_id := String(game.get("_utilities").power_source_component_id())
    if utility_component_id.is_empty() or not game.get("_utilities").set_power_component_state(utility_component_id, UtilityState.DAMAGED, &"slice13_fixture"):
        return {"ok": false}

    var weather_before := int(game.get("_weather").debug_snapshot().get("transition_serial", -1))
    var no_active_infected: Array[String] = []
    game.call("simple_turn_controller").set_infected_actor_ids(no_active_infected)
    var elapsed := int(game.get("_world_time_profile").ticks_per_hour()) * 8
    game.set("_simple_elapsed_override_ticks", elapsed)
    if not simple._begin_direct_action(&"condition.sleep"):
        return {"ok": false}
    var long_result: Dictionary = simple._complete_direct_action(&"condition.sleep", "")
    if not bool(long_result.get("success", false)):
        return {"ok": false}
    game.call("_refresh_slice12_simulation_boundary")
    _check(int(game.get("_weather").debug_snapshot().get("transition_serial", -1)) > weather_before, "world time/weather progression changed before save")

    return {
        "ok": true,
        "keep_id": keep_id,
        "consumed_id": consumed_id,
        "looted_item_id": looted_item_id,
        "fortification_id": fortification_id,
        "far_infected_id": far_infected_id,
        "corpse_id": corpse_id,
        "vehicle_id": vehicle_id,
        "utility_component_id": utility_component_id,
    }

func _alter_loot_container(game) -> String:
    var world = game.get("_world")
    var loot_state = game.get("_loot_state")
    var inventory = game.get("_inventory_state")
    var mutations = game.get("_inventory_mutations")
    var player_id := "actor.player"
    for container_id: String in loot_state.container_ids():
        if not inventory.has_container(container_id):
            continue
        var contents: Array[String] = inventory.direct_contents(container_id)
        if contents.is_empty():
            continue
        var item_id := contents[0]
        if mutations.set_container(item_id, player_id):
            return item_id
    return ""

func _fortify_existing_opening(game) -> String:
    var world = game.get("_world")
    var catalog = game.get("_world_interaction_catalog")
    var state = game.get("_world_interaction_state")
    for entity_id: String in world.entity_ids():
        var entity = world.entity(entity_id)
        if entity == null:
            continue
        if catalog.is_door(entity.semantic_type) or catalog.is_window(entity.semantic_type):
            if state.set_board_count(entity_id, 2, &"slice13_fixture"):
                return entity_id
    return ""

func _create_infected(game, actor_id: String, cell: Vector2i, ordinal: int) -> bool:
    var world = game.get("_world")
    if world.has_entity(actor_id):
        return false
    if world.create_entity(&"actor.survivor", actor_id) != actor_id:
        return false
    if not world.set_placement(actor_id, Layers.Channel.ACTOR, cell, Facing.Value.SOUTH, Footprint.single_cell()):
        world.remove_entity(actor_id)
        return false
    if not game.call("_ensure_simple_infected_state", actor_id):
        world.remove_entity(actor_id)
        return false
    return game.get("_infected_state").record_hydration(actor_id, {
        "resident_id": actor_id,
        "infected": true,
        "building_id": "slice13.fixture.home",
        "resident_ordinal": ordinal,
        "settlement_id": "slice13.fixture",
        "area_site_id": "slice13.fixture",
        "home_cell": cell,
    })

func _install_vehicle_fixture(game) -> String:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    var profiles = game.get("_vehicle_profiles")
    var state = game.get("_vehicle_state")
    var inventory_mutations = game.get("_inventory_mutations")
    var player = world.placement("actor.player")
    var footprint = profiles.footprint(Vehicles.CAR)
    var first := _find_clear_vehicle_anchor(game, player.anchor, footprint, 10, 24)
    if first == INVALID_CELL:
        return ""
    var vehicle_id := "slice13.vehicle.car"
    if world.create_entity(profiles.semantic_type(Vehicles.CAR), vehicle_id) != vehicle_id:
        return ""
    if not world.set_placement(vehicle_id, Layers.Channel.OBJECT, first, Facing.Value.NORTH, footprint):
        world.remove_entity(vehicle_id)
        return ""
    if not inventory_mutations.enroll_container(vehicle_id):
        world.remove_entity(vehicle_id)
        return ""
    if not state.create_vehicle(vehicle_id, Vehicles.CAR, 17, false, 0, true):
        return ""
    if not state.mutate(vehicle_id, {"body": 61, "propulsion": 73, "fuel": 17}):
        return ""
    var cargo_id := "slice13.vehicle.cargo"
    if world.create_entity(&"item.material.wood_plank", cargo_id) != cargo_id:
        return ""
    if not inventory_mutations.set_container(cargo_id, vehicle_id):
        return ""
    var second := _find_clear_vehicle_anchor(game, first + Vector2i(8, 0), footprint, 0, 10)
    if second != INVALID_CELL:
        world.set_placement(vehicle_id, Layers.Channel.OBJECT, second, Facing.Value.EAST, footprint)
        state.mutate(vehicle_id, {"heading": 3})
    return vehicle_id

func _find_clear_vehicle_anchor(game, origin: Vector2i, footprint, min_radius: int, max_radius: int) -> Vector2i:
    var query = game.get("_spatial_query")
    var world = game.get("_world")
    for radius in range(min_radius, max_radius + 1):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if radius > 0 and absi(dx) != radius and absi(dy) != radius:
                    continue
                var cell := origin + Vector2i(dx, dy)
                if not world.has_terrain(cell):
                    continue
                var check = query.query_footprint(cell, Facing.Value.NORTH, footprint, "", true)
                if check != null and check.is_clear():
                    return cell
    return INVALID_CELL

func _move_player_one_cell(game) -> bool:
    var simple = game.call("simple_turn_controller")
    var world = game.get("_world")
    for _i in range(4):
        var placement = world.placement("actor.player")
        var target: Vector2i = placement.anchor + Facing.vector(placement.facing)
        var check = game.get("_spatial_query").query_cell(target, "actor.player", true)
        if check != null and check.is_clear():
            var before: Vector2i = placement.anchor
            simple.submit_intent(Intents.FORWARD)
            return world.placement("actor.player").anchor != before
        simple.submit_intent(Intents.TURN_RIGHT)
    return false

func _far_materialized_clear_cell(game) -> Vector2i:
    var streaming = Bootstrap.streaming_coordinator()
    var plan = Bootstrap.global_plan()
    var world = game.get("_world")
    var player = world.placement("actor.player")
    if streaming == null or plan == null or player == null:
        return INVALID_CELL
    var active_bounds: Array[Rect2i] = streaming.active_region_bounds()
    for bounds: Rect2i in active_bounds:
        var candidates: Array[Vector2i] = [
            bounds.position + Vector2i(bounds.size.x + 48, bounds.size.y / 2),
            bounds.position + Vector2i(-48, bounds.size.y / 2),
            bounds.position + Vector2i(bounds.size.x / 2, bounds.size.y + 48),
            bounds.position + Vector2i(bounds.size.x / 2, -48),
        ]
        for candidate: Vector2i in candidates:
            if not plan.bounds.has_point(candidate) or streaming.is_cell_active(candidate):
                continue
            var result: Dictionary = streaming.update_focus(candidate)
            if not bool(result.get("ok", false)):
                continue
            var clear := _find_clear_cell(game, candidate, 0, 20, true)
            streaming.update_focus(player.anchor)
            if clear != INVALID_CELL:
                return clear
    return INVALID_CELL

func _find_clear_cell(game, origin: Vector2i, min_radius: int, max_radius: int, require_active: bool) -> Vector2i:
    var world = game.get("_world")
    var query = game.get("_spatial_query")
    for radius in range(min_radius, max_radius + 1):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if radius > 0 and absi(dx) != radius and absi(dy) != radius:
                    continue
                var cell := origin + Vector2i(dx, dy)
                if require_active and not game.call("slice12_cell_active", cell):
                    continue
                if not world.has_terrain(cell):
                    continue
                var check = query.query_cell(cell, "", true)
                if check != null and check.is_clear():
                    return cell
    return INVALID_CELL

func _assert_schema2_contract(session: Dictionary) -> void:
    _check(int(session.get("schema_version", -1)) == Store.SESSION_SCHEMA_VERSION, "new saves use schema 2")
    var owners: Dictionary = session.get("owners", {})
    for key: String in ["kernel", "perception_memory", "combat_runtime"]:
        _check(not owners.has(key), "schema 2 excludes retired runtime owner: %s" % key)
    for key: String in Store.REQUIRED_OWNER_KEYS_V2:
        _check(owners.has(key) and typeof(owners[key]) == TYPE_DICTIONARY, "schema 2 includes canonical owner: %s" % key)
    var no_vehicle_copy := session.duplicate(true)
    var no_vehicle_owners: Dictionary = no_vehicle_copy.get("owners", {})
    no_vehicle_owners["vehicles"] = {"schema_version": 1, "records": []}
    no_vehicle_copy["owners"] = no_vehicle_owners
    _check(bool(Store.new(SAVE_A, SAVE_B, SAVE_T).validate_session(no_vehicle_copy).get("ok", false)), "persistence accepts a structurally valid zero-vehicle state")

func _assert_restored_facts(game, reference: Dictionary, far_id: String, corpse_id: String, consumed_id: String, vehicle_id: String, fortification_id: String, utility_component_id: String, looted_item_id: String, label: String, legacy_migration: bool = false) -> void:
    var session: Dictionary = game.call("durable_session_snapshot")
    _assert_schema2_contract(session)
    _check(int(session.get("world_seed", 0)) == SEED, "%s preserves world seed" % label)
    var ignored_owner_keys: Array[String] = ["refrigeration"] if legacy_migration else []
    _compare_canonical_owners(_canonical_owners(session), reference, "%s owner" % label, ignored_owner_keys)
    var world = game.get("_world")
    _check(not world.has_entity(consumed_id), "%s does not resurrect consumed item" % label)
    _check(world.has_entity(corpse_id), "%s preserves corpse entity" % label)
    _check(game.get("_corpse_state").source_actor(corpse_id) != "", "%s preserves corpse mapping" % label)
    _check(game.get("_vehicle_state").has_vehicle(vehicle_id), "%s preserves vehicle state" % label)
    _check(game.get("_world_interaction_state").board_count(fortification_id) == 2, "%s preserves fortification" % label)
    _check(StringName(_utility_component_state(game, utility_component_id)) == UtilityState.DAMAGED, "%s preserves damaged utility" % label)
    _check(game.get("_inventory_state").container_of(looted_item_id) == "actor.player", "%s preserves looted item containment" % label)
    _check(game.get("_infected_state").is_infected(far_id), "%s preserves infected identity" % label)
    _check(world.placement(far_id) != null, "%s preserves dormant infected placement" % label)
    _check(not game.call("slice12_active_infected_ids").has(far_id), "%s reconstructs far infected as dormant" % label)
    for actor_id: String in game.call("slice12_active_infected_ids"):
        var placement = world.placement(actor_id)
        _check(placement != null and game.call("slice12_cell_active", placement.anchor), "%s active roster derives from streaming" % label)

func _utility_component_state(game, component_id: String) -> StringName:
    var snapshot: Dictionary = game.get("_utilities").snapshot()
    for row_value: Variant in snapshot.get("power_components", []):
        if typeof(row_value) != TYPE_DICTIONARY:
            continue
        var row: Dictionary = row_value
        if String(row.get("component_id", "")) == component_id:
            return StringName(row.get("operational_state", &""))
    return &""

func _compare_canonical_owners(actual: Dictionary, expected: Dictionary, label: String, ignored_keys: Array[String] = []) -> void:
    for key: String in Store.REQUIRED_OWNER_KEYS_V2:
        if ignored_keys.has(key):
            continue
        if not actual.has(key) or not expected.has(key):
            _check(false, "%s missing: %s" % [label, key])
            continue
        if actual[key] != expected[key]:
            _check(false, "%s mismatch: %s" % [label, key])

func _assert_legacy_refrigeration_migration(session: Dictionary) -> void:
    var owners_value: Variant = session.get("owners", {})
    if typeof(owners_value) != TYPE_DICTIONARY:
        _check(false, "schema-1 migration emits owner dictionary")
        return
    var owners: Dictionary = owners_value
    var refrigeration_value: Variant = owners.get("refrigeration", {})
    _check(typeof(refrigeration_value) == TYPE_DICTIONARY, "schema-1 migration emits refrigeration owner")
    if typeof(refrigeration_value) != TYPE_DICTIONARY:
        return
    var refrigeration: Dictionary = refrigeration_value
    _check(int(refrigeration.get("schema_version", -1)) == 1, "schema-1 migration emits canonical refrigeration schema")
    var providers_value: Variant = refrigeration.get("providers", [])
    _check(typeof(providers_value) == TYPE_ARRAY, "schema-1 migration emits refrigeration providers")
    if typeof(providers_value) != TYPE_ARRAY:
        return

    var provider_by_context: Dictionary = {}
    for raw: Variant in providers_value:
        if typeof(raw) != TYPE_DICTIONARY:
            _check(false, "schema-1 migration refrigeration provider is structured")
            continue
        var row: Dictionary = raw
        var context_id := String(row.get("context_id", ""))
        _check(not context_id.is_empty(), "schema-1 migration refrigeration provider has context")
        _check(int(row.get("anchor_world_tick", -1)) >= 0, "schema-1 migration refrigeration provider has nonnegative world-time anchor")
        _check(int(row.get("saved_exposure_milliticks", -1)) >= 0, "schema-1 migration refrigeration provider has nonnegative exposure")
        if not context_id.is_empty():
            provider_by_context[context_id] = row

    var freshness_value: Variant = owners.get("freshness", {})
    if typeof(freshness_value) != TYPE_DICTIONARY:
        return
    for raw_record: Variant in (freshness_value as Dictionary).get("records", []):
        if typeof(raw_record) != TYPE_DICTIONARY:
            continue
        var record: Dictionary = raw_record
        var context_id := String(record.get("exposure_context_id", ""))
        if not context_id.begins_with("refrigerated."):
            continue
        _check(provider_by_context.has(context_id), "schema-1 migration provides saved refrigerated exposure context: %s" % context_id)
        if not provider_by_context.has(context_id):
            continue
        var provider: Dictionary = provider_by_context[context_id]
        var saved_exposure_ticks := int(provider.get("saved_exposure_milliticks", 0)) / 1000
        _check(saved_exposure_ticks >= int(record.get("exposure_anchor_ticks", 0)), "schema-1 migration refrigeration exposure never regresses: %s" % context_id)

func _canonical_owners(session: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    var owners_value: Variant = session.get("owners", {})
    if typeof(owners_value) != TYPE_DICTIONARY:
        return result
    var owners: Dictionary = owners_value
    for key: String in Store.REQUIRED_OWNER_KEYS_V2:
        if owners.has(key):
            result[key] = _normalized_durable_fact(owners[key])
    return result

func _normalized_durable_fact(value: Variant) -> Variant:
    if typeof(value) == TYPE_DICTIONARY:
        var source: Dictionary = value
        var normalized: Dictionary = {}
        for raw_key: Variant in source.keys():
            var key := String(raw_key)
            if key == "revision" or key == "version" or key.ends_with("_revision"):
                continue
            normalized[raw_key] = _normalized_durable_fact(source[raw_key])
        return normalized
    if typeof(value) == TYPE_ARRAY:
        var normalized_array: Array = []
        for entry: Variant in value:
            normalized_array.append(_normalized_durable_fact(entry))
        return normalized_array
    return value

func _cleanup_files() -> void:
    for path in [SAVE_A, SAVE_B, SAVE_T]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("SLICE13_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("SLICE13_PERSISTENCE_OK")
        quit(0)
        return
    quit(1)
