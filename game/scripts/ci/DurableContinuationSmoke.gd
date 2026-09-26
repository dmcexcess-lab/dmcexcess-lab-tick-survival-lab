extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const ConditionState = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const StoreClass = preload("res://scripts/persistence/DurableSessionStore.gd")

const PRIMARY := "user://durable_continuation_smoke.save"
const BACKUP := "user://durable_continuation_smoke.backup.save"
const TEMP := "user://durable_continuation_smoke.tmp.save"

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("DURABLE_CONTINUATION: " + message)
    quit(1)

func _cleanup() -> void:
    for path: String in [PRIMARY, BACKUP, TEMP]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _boot(session: Dictionary = {}) -> Node:
    var scene: PackedScene = load("res://gameplay.tscn")
    if scene == null:
        _fail("production gameplay scene missing")
        return null
    var game: Node = scene.instantiate()
    if game == null or not game.has_method("configure_session_paths")         or not game.call("configure_session_paths", PRIMARY, BACKUP, TEMP):
        _fail("production durable-session configuration unavailable")
        return null
    if not session.is_empty() and (
        not game.has_method("configure_continue_session")
        or not game.call("configure_continue_session", session)
    ):
        _fail("Continue configuration rejected a valid saved session")
        return null
    get_root().add_child(game)
    await process_frame
    await process_frame
    if not game.has_method("session_boot_ok") or not bool(game.call("session_boot_ok")):
        _fail("production gameplay session failed to boot: %s" % String(game.call("session_boot_error")))
        return null
    return game

func _run() -> void:
    _cleanup()
    var first: Node = await _boot()
    if first == null:
        return

    var world: WorldState = first.get("_world") as WorldState
    var mutations: WorldMutationService = first.get("_world_mutations") as WorldMutationService
    var inventory: InventoryContainmentState = first.get("_inventory_state") as InventoryContainmentState
    var inventory_mutations: InventoryContainmentMutationService = first.get("_inventory_mutations") as InventoryContainmentMutationService
    var condition: ActorConditionService = first.get("_condition_service") as ActorConditionService
    var vehicles: VehicleState = first.get("_vehicle_state") as VehicleState
    var movement: MovementActionService = first.get("_movement") as MovementActionService
    var kernel: TickKernel = first.get("_kernel") as TickKernel
    if world == null or mutations == null or inventory == null or inventory_mutations == null         or condition == null or vehicles == null or movement == null or kernel == null:
        _fail("production authoritative owners are incomplete")
        return

    var item_id := "item.verifier.durable.apple"
    if mutations.create_entity(&"item.food.apple", item_id) != item_id         or not inventory_mutations.set_container(item_id, Fixture.PLAYER_ID):
        _fail("could not make a durable inventory mutation")
        return
    var hydration_before: int = condition.value(Fixture.PLAYER_ID, ConditionState.HYDRATION)
    if hydration_before < 0 or not condition.change_condition(Fixture.PLAYER_ID, ConditionState.HYDRATION, -7, &"durable_smoke"):
        _fail("could not make a durable condition mutation")
        return
    var hydration_expected: int = condition.value(Fixture.PLAYER_ID, ConditionState.HYDRATION)

    var vehicle_ids: Array[String] = vehicles.vehicle_ids()
    if vehicle_ids.is_empty():
        _fail("production world has no vehicle state to persist")
        return
    var vehicle_id: String = vehicle_ids[0]
    var vehicle_record: Dictionary = vehicles.record(vehicle_id)
    var fuel_expected: int = maxi(0, int(vehicle_record.get("fuel", 0)) - 3)
    if not vehicles.mutate(vehicle_id, {"fuel": fuel_expected}):
        _fail("could not make a durable vehicle mutation")
        return

    var power_assets: Array[String] = first.call("power_infrastructure_asset_ids")
    if power_assets.is_empty():
        _fail("production world has no power asset to persist")
        return
    var power_asset_id: String = power_assets[0]
    if not first.call("damage_power_infrastructure", power_asset_id, 7, &"durable_smoke"):
        _fail("could not make a durable utility mutation")
        return
    var power_before: Dictionary = first.call("power_infrastructure_debug_snapshot")

    var turn: MovementActionResult = movement.request_turn_left(Fixture.PLAYER_ID)
    if turn == null or not turn.is_accepted():
        _fail("could not leave a committed action pending at save boundary")
        return
    var pending_serial: int = turn.action_serial
    var target_facing: int = turn.target_facing
    if kernel.active_action_for_actor(Fixture.PLAYER_ID) == null:
        _fail("pending action disappeared before save")
        return

    var save_result: Dictionary = first.call("save_durable_session", &"ci_explicit_save")
    if not bool(save_result.get("ok", false)):
        _fail("explicit save failed: %s" % String(save_result.get("reason", "")))
        return
    var seed: int = Fixture.active_seed()
    var store = StoreClass.new(PRIMARY, BACKUP, TEMP)
    var loaded: Dictionary = store.load_best()
    if not bool(loaded.get("ok", false)) or String(loaded.get("source", "")) != "primary":
        _fail("fresh save was not readable from primary")
        return
    var first_session: Dictionary = loaded.get("session", {})

    first.queue_free()
    await process_frame
    await process_frame

    var second: Node = await _boot(first_session)
    if second == null:
        return
    if Fixture.active_seed() != seed:
        _fail("Continue regenerated a different world seed")
        return

    world = second.get("_world") as WorldState
    inventory = second.get("_inventory_state") as InventoryContainmentState
    condition = second.get("_condition_service") as ActorConditionService
    vehicles = second.get("_vehicle_state") as VehicleState
    kernel = second.get("_kernel") as TickKernel
    if not world.has_entity(item_id) or inventory.container_of(item_id) != Fixture.PLAYER_ID:
        _fail("inventory item reset or duplicated across Continue")
        return
    if condition.value(Fixture.PLAYER_ID, ConditionState.HYDRATION) != hydration_expected:
        _fail("condition state did not survive Continue")
        return
    if int(vehicles.record(vehicle_id).get("fuel", -1)) != fuel_expected:
        _fail("vehicle state did not survive Continue")
        return
    var power_after: Dictionary = second.call("power_infrastructure_debug_snapshot")
    if power_after.get("condition", {}) != power_before.get("condition", {}):
        _fail("utility damage state did not survive Continue")
        return
    var restored_action: TimedAction = kernel.active_action_for_actor(Fixture.PLAYER_ID)
    if restored_action == null or restored_action.serial != pending_serial:
        _fail("pending committed action was canceled or replaced by Continue")
        return

    var stop_reason: int = kernel.run_until_stop()
    if kernel.active_action_for_actor(Fixture.PLAYER_ID) != null:
        _fail("restored pending action did not resolve")
        return
    var placement: WorldPlacement = world.placement(Fixture.PLAYER_ID)
    if placement == null or placement.facing != target_facing:
        _fail("restored pending action consequence did not commit exactly once")
        return

    save_result = second.call("save_durable_session", &"ci_post_resolution")
    if not bool(save_result.get("ok", false)):
        _fail("second save failed")
        return
    loaded = store.load_best()
    var second_session: Dictionary = loaded.get("session", {})
    second.queue_free()
    await process_frame
    await process_frame

    var third: Node = await _boot(second_session)
    if third == null:
        return
    kernel = third.get("_kernel") as TickKernel
    world = third.get("_world") as WorldState
    if kernel.active_action_for_actor(Fixture.PLAYER_ID) != null:
        _fail("resolved action resurrected on repeated load")
        return
    placement = world.placement(Fixture.PLAYER_ID)
    if placement == null or placement.facing != target_facing:
        _fail("repeated load duplicated or reset movement consequence")
        return

    # Corrupt/incompatible primary files must fall back to the last valid backup.
    var corrupt := FileAccess.open(PRIMARY, FileAccess.WRITE)
    if corrupt == null:
        _fail("could not exercise invalid-primary fallback")
        return
    corrupt.store_string("not a Tick Lab save")
    corrupt.close()
    var fallback: Dictionary = store.load_best()
    if not bool(fallback.get("ok", false)) or String(fallback.get("source", "")) != "backup":
        _fail("invalid primary did not preserve/fall back to last valid backup")
        return

    var incompatible := FileAccess.open(PRIMARY, FileAccess.WRITE)
    if incompatible == null:
        _fail("could not exercise incompatible-primary fallback")
        return
    incompatible.store_var({"format_schema_version": 999}, false)
    incompatible.close()
    fallback = store.load_best()
    if not bool(fallback.get("ok", false)) or String(fallback.get("source", "")) != "backup":
        _fail("incompatible primary did not preserve/fall back to last valid backup")
        return

    var impossible_store = StoreClass.new(
        "user://durable_missing_dir/save.save",
        "user://durable_missing_dir/backup.save",
        "user://durable_missing_dir/temp.save"
    )
    var failure: Dictionary = impossible_store.save(second_session)
    if bool(failure.get("ok", false)):
        _fail("storage write failure was not surfaced")
        return

    third.queue_free()
    await process_frame
    _cleanup()
    print("DURABLE_CONTINUATION_OK seed=%d item=true condition=true vehicle=true utility=true pending_action=true repeat_load=true backup_fallback=true storage_failure=true stop=%d" % [seed, stop_reason])
    quit(0)
