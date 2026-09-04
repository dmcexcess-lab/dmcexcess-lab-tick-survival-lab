extends SceneTree

const Profiles = preload("res://scripts/simulation/vehicles/VehicleProfileCatalog.gd")
const State = preload("res://scripts/simulation/vehicles/VehicleState.gd")
const Heading = preload("res://scripts/simulation/vehicles/VehicleHeading.gd")

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

    _check(Heading.turn_right(0) == 1 and Heading.degrees(1) == 30.0, "turning changes heading 30 degrees", errors)
    _check(Heading.turn_left(0) == 11 and Heading.degrees(11) == 330.0, "left wrap is deterministic", errors)
    var north := Heading.forward_path(0, 3)
    _check(north == [Vector2i(0, -1), Vector2i(0, -2), Vector2i(0, -3)], "north path is three checked cells", errors)
    _check(Heading.forward_path(1, 3).size() == 3, "30-degree path remains three integer steps", errors)
    _check(Heading.forward_path(0, 2).size() == 2, "brake path is two cells", errors)

    var state := State.new()
    _check(state.create_vehicle("vehicle.test.car", Profiles.CAR, 20, true, 1, "item.key.test"), "vehicle state created", errors)
    var rec := state.record("vehicle.test.car")
    _check(int(rec.get("heading", -1)) == 1 and String(rec.get("key_item_id", "")) == "item.key.test", "typed heading and key persist", errors)
    _check(state.set_driver("vehicle.test.car", "actor.test"), "driver attached", errors)
    _check(state.vehicle_for_driver("actor.test") == "vehicle.test.car", "driver lookup", errors)
    var snap := state.snapshot()
    var restored := State.new()
    _check(restored.load_snapshot(snap), "vehicle snapshot roundtrip", errors)
    _check(restored.record("vehicle.test.car").get("kind", &"") == Profiles.CAR, "vehicle kind restored", errors)

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
