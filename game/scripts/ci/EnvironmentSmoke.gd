extends SceneTree

const Lighting = preload("res://scripts/TacticalLighting.gd")
const Sound = preload("res://scripts/TacticalSound.gd")

func _init() -> void:
    var source: Dictionary = Lighting.make_source(Vector2i(5, 5), "neon_cyan", 3, true)
    if Lighting.source_active(source, false):
        push_error("ENV_SMOKE_POWERED_SOURCE_ACTIVE_WITHOUT_POWER")
        quit(1)
        return
    if Lighting.radial_contribution(Vector2i(5, 5), source) <= 0.0:
        push_error("ENV_SMOKE_LIGHT_SOURCE_HAS_NO_CONTRIBUTION")
        quit(1)
        return
    if Lighting.ambient_level("house", "night", true) >= Lighting.ambient_level("house", "night", false):
        push_error("ENV_SMOKE_INDOOR_NIGHT_AMBIENT_NOT_DARKER")
        quit(1)
        return
    var flashlight := {"light": "cone", "light_range": 8.0, "light_strength": 1.0, "light_spread": 0.5}
    if Lighting.item_contribution(Vector2i(5, 5), Vector2i.RIGHT, Vector2i(8, 5), flashlight) <= 0.0:
        push_error("ENV_SMOKE_FLASHLIGHT_CONE_MISSING")
        quit(1)
        return
    if Lighting.item_contribution(Vector2i(5, 5), Vector2i.RIGHT, Vector2i(2, 5), flashlight) > 0.0:
        push_error("ENV_SMOKE_FLASHLIGHT_CONE_POINTS_BACKWARD")
        quit(1)
        return
    if Sound.surface_step_label("wood", false) != "creak":
        push_error("ENV_SMOKE_WOOD_STEP_LABEL_CHANGED")
        quit(1)
        return
    if Sound.zombie_location_error(50) != 0 or Sound.zombie_location_error(10) != 2:
        push_error("ENV_SMOKE_SOUND_LOCALIZATION_BANDS_CHANGED")
        quit(1)
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 77
    var estimate: Vector2i = Sound.estimate_location(Vector2i(8, 8), Vector2i(4, 4), 2, rng, 20, 18)
    var estimate_error: int = absi(estimate.x - 8) + absi(estimate.y - 8)
    if estimate_error > 2:
        push_error("ENV_SMOKE_SOUND_ESTIMATE_OUTSIDE_ERROR")
        quit(1)
        return
    print("TICK_SURVIVAL_ENVIRONMENT_SMOKE_OK")
    quit(0)
