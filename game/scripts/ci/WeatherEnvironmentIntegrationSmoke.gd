extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const WeatherServiceClass = preload("res://scripts/simulation/weather/WeatherService.gd")
const WeatherOpticsClass = preload("res://scripts/simulation/weather/WeatherAtmosphericOpticsAdapter.gd")
const WeatherAcousticClass = preload("res://scripts/simulation/weather/WeatherAcousticEnvironmentModifier.gd")
const SkyExposureClass = preload("res://scripts/simulation/weather/SkyExposureQuery.gd")
const WeatherRendererClass = preload("res://scripts/render/WeatherPresentationRenderer.gd")
const VisionRangePolicy = preload("res://scripts/simulation/lighting/VisionLightRangePolicy.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_physical_optics_and_wetness()
    _test_visibility_extinction()
    _test_weather_acoustic_masking()
    _test_camera_compensated_weather_presentation()
    _test_unrendered_background_is_black()
    if _failures.is_empty():
        print("WEATHER_B_INTEGRATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("WEATHER_B_INTEGRATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_physical_optics_and_wetness() -> void:
    var kernel := TickKernelClass.new()
    var weather := WeatherServiceClass.new(kernel, 28028, &"clear")
    var clear_optics: AtmosphericOptics = WeatherOpticsClass.current_optics(weather)
    _check(clear_optics.is_valid(), "clear weather optics valid")
    _check(clear_optics.direct_sky_transmission > 0.95, "clear leaves direct daylight essentially neutral")
    _check(clear_optics.visibility_extinction < 0.02, "clear has negligible physical extinction")

    _check(weather.force_profile(&"rain"), "force rain for B optics")
    kernel.schedule_event(3000, "weather-b-smoke", &"advance")
    kernel.run_next_batch()
    var rain_sample: Dictionary = weather.current_sample()
    var rain_optics: AtmosphericOptics = WeatherOpticsClass.current_optics(weather)
    _check(rain_optics.direct_sky_transmission < clear_optics.direct_sky_transmission, "rain suppresses direct daylight")
    _check(rain_optics.visibility_extinction > clear_optics.visibility_extinction, "rain adds physical visibility extinction")
    _check(float(rain_sample.get("wetness", 0.0)) > 0.0, "rain advances real analytic wetness with WHEN")
    _check(is_equal_approx(rain_optics.wet_surface_factor, float(rain_sample.get("wetness", 0.0))), "lighting receives real Weather wetness")
    _check(rain_optics.revision == weather.environment_revision(), "optics revision follows quantized Weather revision")

    _check(weather.force_profile(&"fog"), "force fog for B optics")
    var fog_optics: AtmosphericOptics = WeatherOpticsClass.current_optics(weather)
    _check(fog_optics.scatter_strength > rain_optics.scatter_strength, "fog scatters local light more strongly than rain")
    _check(fog_optics.visibility_extinction > rain_optics.visibility_extinction, "fog extinction exceeds rain")

    _check(weather.force_profile(&"storm"), "force storm for B optics")
    var storm_optics: AtmosphericOptics = WeatherOpticsClass.current_optics(weather)
    _check(storm_optics.direct_sky_transmission < rain_optics.direct_sky_transmission, "storm suppresses direct daylight harder than rain")

func _test_visibility_extinction() -> void:
    var clear_range: int = VisionRangePolicy.effective_range_for_conditions(1.0, 0.0, 12, 1)
    var fog_range: int = VisionRangePolicy.effective_range_for_conditions(1.0, 0.60, 12, 1)
    _check(clear_range == 12, "clear full light preserves geometric max range")
    _check(fog_range < clear_range, "physical extinction shrinks useful acquisition range")
    _check(VisionRangePolicy.target_within_visual_range(Vector2i(10, 0), 1.0, 0.0, 12, 1), "clear bright ten-cell target remains acquirable")
    _check(not VisionRangePolicy.target_within_visual_range(Vector2i(10, 0), 1.0, 0.60, 12, 1), "fog hides same distant bright target")
    _check(VisionRangePolicy.target_within_visual_range(Vector2i(1, 0), 0.0, 1.0, 12, 1), "radius-one near awareness remains protected in opaque conditions")
    print("WEATHER_B_CLEAR_RANGE=%d" % clear_range)
    print("WEATHER_B_FOG_RANGE=%d" % fog_range)

func _test_weather_acoustic_masking() -> void:
    var kernel := TickKernelClass.new()
    var weather := WeatherServiceClass.new(kernel, 6060, &"clear")
    var modifier := WeatherAcousticClass.new(weather)
    _check(modifier.is_ready(), "weather acoustic modifier ready")
    var clear_threshold: int = modifier.detection_threshold_addition("listener", &"footstep.walk", Vector2i.ZERO)
    var clear_localization: float = modifier.localization_quality_adjustment("listener", &"footstep.walk", Vector2i.ZERO)
    _check(weather.force_profile(&"storm"), "force storm for acoustic masking")
    var storm_threshold: int = modifier.detection_threshold_addition("listener", &"footstep.walk", Vector2i.ZERO)
    var storm_localization: float = modifier.localization_quality_adjustment("listener", &"footstep.walk", Vector2i.ZERO)
    _check(storm_threshold > clear_threshold, "storm raises hearing detection threshold")
    _check(storm_localization < clear_localization, "storm worsens localization quality")
    _check(modifier.propagation_cost_addition(&"footstep.walk", Vector2i.ZERO, Vector2i.RIGHT) == 0, "rain/wind mask background without fake per-cell absorption")
    print("WEATHER_B_STORM_HEARING_MASK=%d" % storm_threshold)

func _test_camera_compensated_weather_presentation() -> void:
    var world := WorldStateClass.new()
    var mutation := WorldMutationClass.new(world)
    var bounds := Rect2i(-4, -4, 9, 9)
    _check(mutation.set_terrain_rect(bounds, &"ground.concrete"), "camera weather fixture terrain")
    var kernel := TickKernelClass.new()
    var weather := WeatherServiceClass.new(kernel, 9001, &"rain")
    var sky := SkyExposureClass.new(world)
    var renderer := WeatherRendererClass.new()
    get_root().add_child(renderer)
    _check(renderer.configure(weather, sky), "camera-compensated weather renderer configured")
    _check(renderer.set_visible_window(bounds.position, bounds.size, 16.0), "camera-compensated weather view configured")
    _check(renderer.set_camera_local_position(Vector2(64.0, 64.0)), "initial weather camera anchor accepted")
    var before: Dictionary = renderer.presentation_snapshot()
    var tick_before: int = kernel.world_tick()
    _check(renderer.set_camera_local_position(Vector2(80.0, 64.0)), "weather camera movement accepted")
    var after: Dictionary = renderer.presentation_snapshot()
    var offset: Vector2 = after.get("camera_offset_pixels", Vector2.ZERO)
    var virtual_offset: Vector2i = after.get("camera_virtual_offset", Vector2i.ZERO)
    _check(is_equal_approx(offset.x, 16.0), "weather immediately compensates one-cell camera motion")
    _check(virtual_offset.x == 4, "camera motion maps to coarse weather pixels without advancing phase")
    _check(int(after.get("camera_motion_redraws", 0)) == int(before.get("camera_motion_redraws", 0)) + 1, "camera movement requests immediate weather redraw")
    _check(int(after.get("presentation_updates", -1)) == int(before.get("presentation_updates", -2)), "camera redraw does not advance 20 Hz weather phase")
    _check(kernel.world_tick() == tick_before, "camera weather compensation advances zero WHEN ticks")
    print("WEATHER_B_CAMERA_REDRAWS=%d" % int(after.get("camera_motion_redraws", 0)))
    renderer.queue_free()

func _test_unrendered_background_is_black() -> void:
    var clear_color: Color = ProjectSettings.get_setting(
        "rendering/environment/defaults/default_clear_color",
        Color.WHITE
    )
    _check(clear_color.is_equal_approx(Color(0.0, 0.0, 0.0, 1.0)), "unrendered viewport background is true black")

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)
