extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const WeatherServiceClass = preload("res://scripts/simulation/weather/WeatherService.gd")
const SkyExposureClass = preload("res://scripts/simulation/weather/SkyExposureQuery.gd")
const WeatherRendererClass = preload("res://scripts/render/WeatherPresentationRenderer.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_deterministic_transition_plan()
    _test_analytic_wetness_and_snapshot()
    _test_pause_separation_and_gpu_presentation()
    _test_shelter_mask_and_single_surface()
    if _failures.is_empty():
        print("WEATHER_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("WEATHER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_deterministic_transition_plan() -> void:
    var first_kernel := TickKernelClass.new()
    var second_kernel := TickKernelClass.new()
    var first := WeatherServiceClass.new(first_kernel, 123456, &"clear")
    var second := WeatherServiceClass.new(second_kernel, 123456, &"clear")
    _check(first.is_ready() and second.is_ready(), "deterministic services ready")
    var a: Dictionary = first.debug_snapshot()
    var b: Dictionary = second.debug_snapshot()
    _check(a["target_profile_id"] == b["target_profile_id"], "same seed chooses same next weather")
    _check(a["transition_end_tick"] == b["transition_end_tick"], "same seed chooses same transition duration")
    _check(first_kernel.pending_event_count() == 1 and second_kernel.pending_event_count() == 1, "weather schedules one meaningful transition event")

func _test_analytic_wetness_and_snapshot() -> void:
    var kernel := TickKernelClass.new()
    var service := WeatherServiceClass.new(kernel, 77, &"rain")
    _check(service.is_ready(), "rain service ready")
    var start_wetness: float = service.wetness_at()
    kernel.schedule_event(3000, "weather-smoke", &"test.advance")
    kernel.run_next_batch()
    var wet_wetness: float = service.wetness_at()
    _check(wet_wetness > start_wetness, "rain analytically increases wetness only after WHEN advances")

    var kernel_snapshot: Dictionary = kernel.snapshot()
    var weather_snapshot: Dictionary = service.snapshot()
    var saved_debug: Dictionary = service.debug_snapshot()
    _check(service.force_profile(&"fog"), "DEV force profile accepted")
    _check(kernel.load_snapshot(kernel_snapshot), "WHEN snapshot restored")
    _check(service.load_snapshot(weather_snapshot), "weather snapshot restored")
    var restored: Dictionary = service.debug_snapshot()
    _check(restored["current_profile_id"] == saved_debug["current_profile_id"], "weather current profile restored")
    _check(restored["target_profile_id"] == saved_debug["target_profile_id"], "future profile restored")
    _check(restored["transition_end_tick"] == saved_debug["transition_end_tick"], "future deterministic transition restored")

func _test_pause_separation_and_gpu_presentation() -> void:
    var fixture: Dictionary = _build_room_fixture()
    var kernel := TickKernelClass.new("player")
    var service := WeatherServiceClass.new(kernel, 222, &"rain")
    var sky := SkyExposureClass.new(fixture["world"])
    var renderer := WeatherRendererClass.new()
    get_root().add_child(renderer)
    _check(renderer.configure(service, sky), "weather renderer configured")
    _check(renderer.set_visible_window(Vector2i(-4, -4), Vector2i(9, 9), 16.0), "weather view configured")
    var before_tick: int = kernel.world_tick()
    var before_weather: Dictionary = service.current_sample()
    var before_present: Dictionary = renderer.presentation_snapshot()
    var steps: int = renderer.advance_presentation(0.50)
    var after_weather: Dictionary = service.current_sample()
    var presentation: Dictionary = renderer.presentation_snapshot()
    _check(steps == 4, "CPU housekeeping catch-up is bounded after a long frame")
    _check(kernel.world_tick() == before_tick, "cosmetic weather advances zero WHEN ticks while decision-paused")
    _check(is_equal_approx(float(before_weather["wetness"]), float(after_weather["wetness"])), "cosmetic animation changes no physical wetness")
    _check(bool(presentation.get("shader_atmosphere", false)), "continuous atmosphere is shader-driven")
    _check(int(presentation.get("atmosphere_surface_count", 0)) == 1, "weather owns exactly one persistent atmosphere surface")
    _check(int(presentation.get("target_hz", 0)) == 10, "CPU weather housekeeping is reduced to 10 Hz")
    _check(int(presentation.get("weather_pixel_size", 0)) == 2, "weather pixel scale matches the finer world-art language")
    _check(int(presentation.get("cpu_continuous_redraws", -1)) == 0, "continuous rain/fog requires zero CPU redraw loop")
    _check(int(presentation.get("redraw_requests", -1)) == int(before_present.get("redraw_requests", -2)), "continuous atmosphere does not request canvas redraws")
    _check(int(presentation.get("virtual_pixel_count", 0)) <= 256 * 256, "cached shelter texture remains structurally tiny")
    renderer.queue_free()

func _test_shelter_mask_and_single_surface() -> void:
    var fixture: Dictionary = _build_room_fixture()
    var world: WorldState = fixture["world"]
    var sky := SkyExposureClass.new(world)
    var bounds := Rect2i(-4, -4, 9, 9)
    _check(sky.is_exposed(Vector2i(0, -4), bounds), "outside cell is sky exposed")
    _check(not sky.is_exposed(Vector2i(0, 0), bounds), "enclosed room center is sheltered")
    _check(not sky.is_exposed(Vector2i(0, 0), bounds), "door semantic in envelope does not make room unroofed")

    var kernel := TickKernelClass.new()
    var service := WeatherServiceClass.new(kernel, 333, &"clear")
    var renderer := WeatherRendererClass.new()
    get_root().add_child(renderer)
    _check(renderer.configure(service, sky), "single-surface renderer configured")
    _check(renderer.set_visible_window(bounds.position, bounds.size, 16.0), "single-surface window configured")
    _check(renderer.get_child_count() == 1, "weather creates one atmosphere surface and no per-particle Nodes")
    _check(renderer.force_ambient_event(&"leaf"), "forced calm leaf event accepted")
    renderer.advance_presentation(0.20)
    var snapshot: Dictionary = renderer.presentation_snapshot()
    var surface: Dictionary = snapshot.get("surface", {})
    _check(int(snapshot.get("active_debris", 0)) <= 1, "calm ambient debris stays within one-piece cap")
    _check(int(snapshot.get("max_debris", 0)) == 3, "hard debris cap remains tiny")
    _check(snapshot.get("exposure_mask_size", Vector2i.ZERO) == bounds.size, "shelter mask is one texel per tactical cell")
    _check(bool(surface.get("exposure_texture_ready", false)), "single atmosphere surface receives cached shelter texture")
    _check(is_equal_approx(float(surface.get("rain_pixel_size", 0.0)), 2.0), "GPU rain uses two-screen-pixel art scale")
    print("WEATHER_VIRTUAL_PIXELS=%d" % int(snapshot["virtual_pixel_count"]))
    print("WEATHER_ACTIVE_DEBRIS=%d" % int(snapshot["active_debris"]))
    print("WEATHER_PRESENTATION_UPDATES=%d" % int(snapshot["presentation_updates"]))
    print("WEATHER_CPU_CONTINUOUS_REDRAWS=%d" % int(snapshot["cpu_continuous_redraws"]))
    renderer.queue_free()

func _build_room_fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var mutation := WorldMutationClass.new(world)
    var bounds := Rect2i(-4, -4, 9, 9)
    _check(mutation.set_terrain_rect(bounds, &"ground.concrete"), "weather fixture terrain created")
    var footprint := FootprintClass.single_cell()
    var serial: int = 0
    for x in range(-2, 3):
        serial += 1
        var north_semantic: StringName = &"door.house" if x == 0 else &"wall.house"
        _place_structure(mutation, "weather.n.%d" % serial, north_semantic, Vector2i(x, -2), StructureGeometry.Axis.HORIZONTAL, footprint)
        serial += 1
        _place_structure(mutation, "weather.s.%d" % serial, &"wall.house", Vector2i(x, 2), StructureGeometry.Axis.HORIZONTAL, footprint)
    for y in range(-1, 2):
        serial += 1
        _place_structure(mutation, "weather.w.%d" % serial, &"wall.house", Vector2i(-2, y), StructureGeometry.Axis.VERTICAL, footprint)
        serial += 1
        _place_structure(mutation, "weather.e.%d" % serial, &"wall.house", Vector2i(2, y), StructureGeometry.Axis.VERTICAL, footprint)
    return {"world": world, "bounds": bounds}

func _place_structure(
    mutation: WorldMutationService,
    entity_id: String,
    semantic: StringName,
    cell: Vector2i,
    axis: int,
    footprint: SpatialFootprint
) -> void:
    _check(mutation.create_entity(semantic, entity_id) == entity_id, "fixture structure created %s" % entity_id)
    _check(mutation.set_placement(entity_id, Layers.Channel.STRUCTURE, cell, Facing.Value.NORTH, footprint, axis), "fixture structure placed %s" % entity_id)

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)
