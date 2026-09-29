extends SceneTree

const Fixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const VehicleProfiles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    for offset in [0, 137, 911]:
        await _verify_seed(Fixture.SEED + offset)
    _finish()

func _verify_seed(seed: int) -> void:
    var packed := load("res://gameplay.tscn") as PackedScene
    _check(packed != null, "production gameplay scene loads")
    if packed == null:
        return
    var game = packed.instantiate()
    _check(game != null, "production gameplay scene instantiates")
    if game == null:
        return
    _check(game.configure_world_seed_override(seed), "seed override accepted: %d" % seed)
    root.add_child(game)
    await process_frame
    await process_frame
    _check(game.session_boot_ok(), "production boot succeeds: %d" % seed)
    if not game.session_boot_ok():
        game.queue_free()
        await process_frame
        return

    var state = game.get("_vehicle_state")
    var world = game.get("_world")
    _check(state != null and world != null, "vehicle owners available: %d" % seed)
    if state == null or world == null:
        game.queue_free()
        await process_frame
        return

    var player = world.placement("actor.player")
    _check(player != null, "player placement available: %d" % seed)
    if player == null:
        game.queue_free()
        await process_frame
        return

    var nearby: Array[String] = []
    var kinds: Dictionary = {}
    for vehicle_id: String in state.vehicle_ids():
        var placement = world.placement(vehicle_id)
        if placement == null or placement.anchor.distance_to(player.anchor) > 42.0:
            continue
        nearby.append(vehicle_id)
        var kind := StringName(state.record(vehicle_id).get("kind", &""))
        kinds[kind] = true
        _check(placement.anchor.distance_to(player.anchor) >= 10.0, "vehicle is not planted beside player: %s" % vehicle_id)
        var terrain := String(world.terrain_at(placement.anchor)).to_lower()
        _check("parking" in terrain or "driveway" in terrain or "pavement" in terrain or "road" in terrain, "vehicle uses plausible vehicle surface: %s" % vehicle_id)

    _check(nearby.size() <= 6, "initial local vehicle materialization is capped: %d" % seed)
    _check(kinds.size() < VehicleProfiles.new().kinds().size(), "start is not guaranteed one of every vehicle kind: %d" % seed)

    game.queue_free()
    await process_frame

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("VEHICLE_SPAWN_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("VEHICLE_SPAWN_DISTRIBUTION_OK")
        quit(0)
        return
    quit(1)
