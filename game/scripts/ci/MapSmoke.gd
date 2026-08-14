extends SceneTree

const MapGen = preload("res://scripts/TacticalMapGenerator.gd")

func _init() -> void:
    var validation: Dictionary = MapGen.validate_all()
    if not bool(validation.get("ok", false)):
        push_error("MAP_BOOTSTRAP_VALIDATION_FAILED: %s" % str(validation.get("failures", [])))
        quit(1)
        return
    if MapGen.all_ids().size() != 7:
        push_error("MAP_BOOTSTRAP_EXPECTED_SEVEN_ENVIRONMENTS")
        quit(1)
        return
    print("TICK_SURVIVAL_MAP_SMOKE_OK")
    quit(0)
