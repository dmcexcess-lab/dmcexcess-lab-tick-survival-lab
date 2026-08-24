extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const WorldTimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const WorldTimeServiceClass = preload("res://scripts/simulation/world_time/WorldTimeService.gd")
const DaylightProfileClass = preload("res://scripts/simulation/world_time/DaylightProfile.gd")
const AmbientServiceClass = preload("res://scripts/simulation/world_time/OutdoorAmbientLightService.gd")
const WeatherServiceClass = preload("res://scripts/simulation/weather/WeatherService.gd")
const WeatherOpticsClass = preload("res://scripts/simulation/weather/WeatherAtmosphericOpticsAdapter.gd")
const SkyExposureClass = preload("res://scripts/simulation/weather/SkyExposureQuery.gd")
const WeatherRendererClass = preload("res://scripts/render/WeatherPresentationRenderer.gd")
const LightingClass = preload("res://scripts/simulation/lighting/PhysicalLightingService.gd")
const VisionRangePolicy = preload("res://scripts/simulation/lighting/VisionLightRangePolicy.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_deterministic_physical_lightning()
    if _failures.is_empty():
        print("WEATHER_C_LIGHTNING_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("WEATHER_C_LIGHTNING_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_deterministic_physical_lightning() -> void:
    var fixture: Dictionary = _build_windowed_night_fixture(424242)
    var kernel: TickKernel = fixture["kernel"]
    var weather: WeatherService = fixture["weather"]
    var lighting: PhysicalLightingService = fixture["lighting"]
    var renderer: WeatherPresentationRenderer = fixture["renderer"]

    var outside_cell := Vector2i(0, -4)
    var inside_cell := Vector2i(0, -1)
    _check(lighting.set_atmosphere(WeatherOpticsClass.current_optics(weather)), "storm baseline optics accepted")
    var before_outside: float = lighting.luminance_at(outside_cell)
    var before_inside: float = lighting.luminance_at(inside_cell)
    var range_before: int = VisionRangePolicy.effective_range_for_conditions(before_outside, lighting.atmosphere().visibility_extinction, 12, 1)

    _check(weather.force_lightning(), "DEV force schedules a real future lightning event")
    _check(kernel.run_next_batch(), "WHEN resolves forced lightning start")
    var lightning: LightningEvent = weather.active_lightning()
    _check(lightning != null and lightning.is_valid(), "lightning becomes active physical Weather truth")
    _check(kernel.world_tick() == 1, "forced lightning begins on the next authoritative tick")
    var flash_optics: AtmosphericOptics = WeatherOpticsClass.current_optics(weather)
    _check(flash_optics.transient_sky_light >= 0.78, "active lightning exposes strong transient sky light")
    _check(lighting.set_atmosphere(flash_optics), "lightning optics accepted by physical lighting")
    var flash_outside: float = lighting.luminance_at(outside_cell)
    var flash_inside: float = lighting.luminance_at(inside_cell)
    var range_flash: int = VisionRangePolicy.effective_range_for_conditions(flash_outside, flash_optics.visibility_extinction, 12, 1)
    _check(flash_outside > before_outside + 0.45, "physical lightning brightly illuminates outdoor cells at night")
    _check(flash_inside > before_inside + 0.05, "physical lightning enters roofed space through the real window portal")
    _check(range_flash > range_before, "lightning can temporarily improve physical visual acquisition conditions")
    _check(bool(renderer.presentation_snapshot().get("lightning_visual_active", false)), "same physical lightning event starts the low-res visual bolt envelope")

    var kernel_snapshot: Dictionary = kernel.snapshot()
    var weather_snapshot: Dictionary = weather.snapshot()
    var saved_seed: int = lightning.bolt_seed
    var saved_intensity: float = lightning.intensity

    _check(kernel.run_next_batch(), "WHEN resolves lightning end")
    _check(weather.active_lightning() == null, "lightning physical state ends on schedule")
    var ended_optics: AtmosphericOptics = WeatherOpticsClass.current_optics(weather)
    _check(ended_optics.transient_sky_light <= 0.001, "ended lightning removes transient physical sky light")
    _check(lighting.set_atmosphere(ended_optics), "post-lightning atmosphere accepted")
    var ended_outside: float = lighting.luminance_at(outside_cell)
    _check(ended_outside < flash_outside * 0.60, "physical illumination collapses after the flash ends")

    _check(kernel.load_snapshot(kernel_snapshot), "WHEN active-flash snapshot restored")
    _check(weather.load_snapshot(weather_snapshot), "Weather active-flash snapshot restored")
    var restored: LightningEvent = weather.active_lightning()
    _check(restored != null and restored.bolt_seed == saved_seed, "snapshot restores exact active lightning identity/seed")
    _check(is_equal_approx(restored.intensity, saved_intensity), "snapshot restores exact lightning intensity")
    _check(WeatherOpticsClass.current_optics(weather).transient_sky_light > 0.0, "restored active lightning restores physical optics")

    var second: Dictionary = _build_windowed_night_fixture(424242)
    var second_kernel: TickKernel = second["kernel"]
    var second_weather: WeatherService = second["weather"]
    _check(second_weather.force_lightning(), "second deterministic lightning force scheduled")
    _check(second_kernel.run_next_batch(), "second deterministic lightning start resolved")
    var second_event: LightningEvent = second_weather.active_lightning()
    _check(second_event != null, "second deterministic lightning active")
    _check(second_event.bolt_seed == saved_seed, "same scenario seed/tick produces same bolt seed")
    _check(is_equal_approx(second_event.intensity, saved_intensity), "same scenario seed/tick produces same flash intensity")

    var tick_before_cosmetic: int = kernel.world_tick()
    renderer.advance_presentation(0.20)
    _check(kernel.world_tick() == tick_before_cosmetic, "lightning visual animation consumes zero WHEN ticks")

    print("WEATHER_C_LIGHTNING_BEFORE=%.3f" % before_outside)
    print("WEATHER_C_LIGHTNING_FLASH=%.3f" % flash_outside)
    print("WEATHER_C_LIGHTNING_PORTAL=%.3f" % flash_inside)
    print("WEATHER_C_LIGHTNING_SEED=%d" % saved_seed)

    renderer.queue_free()
    var second_renderer: WeatherPresentationRenderer = second["renderer"]
    second_renderer.queue_free()

func _build_windowed_night_fixture(seed: int) -> Dictionary:
    var world := WorldStateClass.new()
    var mutation := WorldMutationClass.new(world)
    var bounds := Rect2i(-5, -5, 11, 11)
    _check(mutation.set_terrain_rect(bounds, &"ground.concrete"), "lightning fixture terrain created")
    var footprint := FootprintClass.single_cell()
    var serial: int = 0
    for x in range(-2, 3):
        serial += 1
        var north_semantic: StringName = &"window.house" if x == 0 else &"wall.house"
        _place_structure(mutation, "lightning.n.%d" % serial, north_semantic, Vector2i(x, -2), StructureGeometry.Axis.HORIZONTAL, footprint)
        serial += 1
        _place_structure(mutation, "lightning.s.%d" % serial, &"wall.house", Vector2i(x, 2), StructureGeometry.Axis.HORIZONTAL, footprint)
    for y in range(-1, 2):
        serial += 1
        _place_structure(mutation, "lightning.w.%d" % serial, &"wall.house", Vector2i(-2, y), StructureGeometry.Axis.VERTICAL, footprint)
        serial += 1
        _place_structure(mutation, "lightning.e.%d" % serial, &"wall.house", Vector2i(2, y), StructureGeometry.Axis.VERTICAL, footprint)

    var doors := DoorStateClass.new()
    var kernel := TickKernelClass.new()
    var clock := WorldTimeServiceClass.new(kernel, WorldTimeProfileClass.new())
    var flat_night := DaylightProfileClass.new(
        DaylightProfileClass.DEFAULT_DAWN_START_SECOND,
        DaylightProfileClass.DEFAULT_DAY_START_SECOND,
        DaylightProfileClass.DEFAULT_DUSK_START_SECOND,
        DaylightProfileClass.DEFAULT_NIGHT_START_SECOND,
        0.08,
        0.08
    )
    var ambient := AmbientServiceClass.new(clock, flat_night)
    var lighting := LightingClass.new(world, doors, ambient)
    _check(lighting.set_field_bounds(bounds), "lightning lighting bounds accepted")
    var weather := WeatherServiceClass.new(kernel, seed, &"storm")
    var sky := SkyExposureClass.new(world)
    var renderer := WeatherRendererClass.new()
    get_root().add_child(renderer)
    _check(renderer.configure(weather, sky), "lightning presentation configured")
    _check(renderer.set_visible_window(bounds.position, bounds.size, 16.0), "lightning presentation bounds configured")
    return {
        "world": world,
        "kernel": kernel,
        "weather": weather,
        "lighting": lighting,
        "renderer": renderer,
    }

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
