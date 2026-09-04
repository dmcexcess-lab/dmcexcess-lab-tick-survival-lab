extends SceneTree

const Profiles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const State = preload("res://scripts/simulation/vehicles/VehicleState.gd")
const Heading = preload("res://scripts/simulation/vehicles/VehicleHeading.gd")
const Items = preload("res://scripts/simulation/vehicles/VehicleItemCatalog.gd")
const Renderer = preload("res://scripts/render/VehicleRenderer.gd")
const Controls = preload("res://scripts/ui/VehiclePlayerControls.gd")

func _initialize() -> void:
    var errors: Array[String] = []
    var profiles := Profiles.new()
    _check(profiles.kinds().size() == 5, "five vehicle classes", errors)
    _check(profiles.movement_cells(Profiles.SKATEBOARD) == 2, "skateboard moves two cells", errors)
    _check(profiles.movement_cells(Profiles.BICYCLE) == 3, "bicycle moves three cells", errors)
    _check(not profiles.is_motorized(Profiles.BICYCLE), "bicycle has no fuel motor", errors)
    _check(profiles.fuel_per_move(Profiles.MOTORCYCLE) < profiles.fuel_per_move(Profiles.CAR), "motorcycle uses less fuel than car", errors)
    _check(profiles.cargo_grams(Profiles.MOTORCYCLE) < profiles.cargo_grams(Profiles.CAR), "motorcycle has less storage than car", errors)
    _check(profiles.hotwire_difficulty(Profiles.MOTORCYCLE) < profiles.hotwire_difficulty(Profiles.CAR), "motorcycle easier to hotwire", errors)
    _check(not (&"item.automotive.vehicle_key" in Items.semantic_types()), "vehicle item catalog has no collectible key", errors)
    var car_footprint := profiles.footprint(Profiles.CAR)
    _check(car_footprint.cell_count() == 3 and car_footprint.contains_relative(Vector2i(0, 2)) and not car_footprint.contains_relative(Vector2i(1, 0)), "car owns an exact real 1x3 footprint", errors)
    var truck_footprint := profiles.footprint(Profiles.TRUCK)
    _check(truck_footprint.cell_count() == 6 and truck_footprint.contains_relative(Vector2i(1, 2)) and not truck_footprint.contains_relative(Vector2i(2, 0)) and not truck_footprint.contains_relative(Vector2i(0, 3)), "truck owns an exact real 2x3 footprint", errors)

    _check(Heading.turn_right(0) == 1 and Heading.degrees(1) == 30.0, "turning changes heading 30 degrees", errors)
    _check(Heading.turn_left(0) == 11 and Heading.degrees(11) == 330.0, "left wrap is deterministic", errors)
    _check(Heading.completed_turn_heading(0, 1) == 3, "right turn completes at 90 degrees", errors)
    _check(Heading.completed_turn_heading(0, -1) == 9, "left turn completes at 270 degrees", errors)
    _check(Heading.turn_path(0, 1) == [Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1)], "right turn crosses three adjacent squares at 30-degree heading steps", errors)
    _check(Heading.turn_path(0, -1) == [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-2, -1)], "left turn mirrors the three-square arc", errors)
    var north := Heading.forward_path(0, 3)
    _check(north == [Vector2i(0, -1), Vector2i(0, -2), Vector2i(0, -3)], "north path is three checked cells", errors)
    _check(Heading.forward_path(1, 3).size() == 3, "30-degree path remains three integer steps", errors)
    _check(Heading.forward_path(0, 2).size() == 2, "brake path is two cells", errors)
    _check(Heading.reverse_path(0, 1) == [Vector2i(0, 1)], "north reverse moves one checked cell south without changing heading", errors)
    _check(Heading.reverse_path(3, 1) == [Vector2i(-1, 0)], "east reverse moves one checked cell west", errors)

    for asset_path: String in [
        "res://assets/vehicle_skateboard.svg",
        "res://assets/vehicle_bicycle.svg",
        "res://assets/vehicle_motorcycle.svg",
        "res://assets/vehicle_car.svg",
        "res://assets/vehicle_truck.svg",
    ]:
        _check(ResourceLoader.exists(asset_path), "dedicated vehicle sprite exists: %s" % asset_path, errors)
    for kind: StringName in profiles.kinds():
        _check(Renderer.has_dedicated_sprite(kind), "approved class resolves dedicated texture: %s" % String(kind), errors)
    var car_texture: Texture2D = load("res://assets/vehicle_car.svg")
    _check(car_texture != null and car_texture.get_size() == Vector2(64, 192), "car sprite canvas matches the real 1x3 footprint aspect", errors)

    var controls := Controls.new()
    get_root().add_child(controls)
    controls.call("_build_ui")
    _check(controls.find_child("ReverseButton", true, false) is Button, "real vehicle panel exposes ReverseButton", errors)
    controls.queue_free()

    var state := State.new()
    _check(state.create_vehicle("vehicle.test.car", Profiles.CAR, 20, false, 1, true), "vehicle state created", errors)
    var rec := state.record("vehicle.test.car")
    _check(int(rec.get("heading", -1)) == 1 and bool(rec.get("key_in_ignition", false)), "typed heading and key-in-ignition persist", errors)
    _check(not rec.has("key_item_id") and not bool(rec.get("locked", true)), "vehicle has no collectible-key or door-lock gate", errors)
    _check(state.set_driver("vehicle.test.car", "actor.test"), "driver attached", errors)
    _check(state.vehicle_for_driver("actor.test") == "vehicle.test.car", "driver lookup", errors)
    var snap := state.snapshot()
    var restored := State.new()
    _check(restored.load_snapshot(snap), "vehicle snapshot roundtrip", errors)
    var restored_rec := restored.record("vehicle.test.car")
    _check(restored_rec.get("kind", &"") == Profiles.CAR, "vehicle kind restored", errors)
    _check(bool(restored_rec.get("key_in_ignition", false)) and not restored_rec.has("key_item_id"), "ignition state restores without a key entity", errors)

    if errors.is_empty():
        print("VEHICLE_SMOKE_OK")
        quit(0)
        return
    for error: String in errors:
        push_error("VEHICLE_SMOKE_FAIL: %s" % error)
    quit(1)

func _check(condition: bool, message: String, errors: Array[String]) -> void:
    if not condition:
        errors.append(message)
