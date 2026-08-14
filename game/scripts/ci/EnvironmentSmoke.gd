extends SceneTree

const Lighting = preload("res://scripts/TacticalLighting.gd")
const Sound = preload("res://scripts/TacticalSound.gd")
const Weather = preload("res://scripts/TacticalWeather.gd")

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
    var clear_weather: Dictionary = Weather.make_state(Weather.CLEAR)
    var storm_weather: Dictionary = Weather.make_state(Weather.STORM, Vector2(1.0, 0.25))
    var snow_weather: Dictionary = Weather.make_state(Weather.SNOW, Vector2(0.4, 0.2))
    if Weather.visibility_multiplier(storm_weather) >= Weather.visibility_multiplier(clear_weather):
        push_error("ENV_SMOKE_STORM_VISIBILITY_NOT_REDUCED")
        quit(1)
        return
    if Weather.light_multiplier(storm_weather) >= Weather.light_multiplier(clear_weather):
        push_error("ENV_SMOKE_STORM_LIGHT_NOT_REDUCED")
        quit(1)
        return
    if Weather.sound_mask(storm_weather) <= Weather.sound_mask(clear_weather):
        push_error("ENV_SMOKE_STORM_SOUND_MASK_MISSING")
        quit(1)
        return
    if Weather.precipitation(storm_weather) < 0.9 or Weather.wind_strength(storm_weather) < 0.7:
        push_error("ENV_SMOKE_STORM_PROFILE_TOO_WEAK")
        quit(1)
        return
    if Weather.snowfall(snow_weather) < 0.7 or Weather.precipitation(snow_weather) > 0.0:
        push_error("ENV_SMOKE_SNOW_PROFILE_INVALID")
        quit(1)
        return
    if Weather.outside_temperature_f(1, 15, 360, snow_weather) >= Weather.outside_temperature_f(1, 15, 360, clear_weather):
        push_error("ENV_SMOKE_SNOW_NOT_COLDER")
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
