extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorValues = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const WorldTimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const WorldTimeServiceClass = preload("res://scripts/simulation/world_time/WorldTimeService.gd")
const DaylightProfileClass = preload("res://scripts/simulation/world_time/DaylightProfile.gd")
const AmbientServiceClass = preload("res://scripts/simulation/world_time/OutdoorAmbientLightService.gd")
const AtmosphereClass = preload("res://scripts/simulation/lighting/AtmosphericOptics.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")
const EmitterClass = preload("res://scripts/simulation/lighting/LightEmitter.gd")
const LightingClass = preload("res://scripts/simulation/lighting/PhysicalLightingService.gd")
const VisionRangePolicy = preload("res://scripts/simulation/lighting/VisionLightRangePolicy.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_daylight_enclosure_and_portals()
    _test_flashlight_occlusion_and_window_transmission()
    _test_weather_optics()
    _test_light_driven_vision_range()
    _test_determinism_and_zero_tick_cost()
    _profile_rebuild_cost()

    if _failures.is_empty():
        print("PHYSICAL_LIGHTING_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PHYSICAL_LIGHTING_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_daylight_enclosure_and_portals() -> void:
    var fixture: Dictionary = _build_room_fixture(DoorValues.OPEN)
    var service: PhysicalLightingService = _lighting_for_fixture(fixture, false)
    _check(service.is_ready(), "daylight lighting service is ready")

    var outside: float = service.luminance_at(Vector2i(0, -6))
    var window_near: float = service.luminance_at(Vector2i(0, -2))
    var deep_inside: float = service.luminance_at(Vector2i(-2, 2))
    var door_near_open: float = service.luminance_at(Vector2i(2, 0))

    _check(outside > 0.85, "clear daytime exterior is brightly illuminated")
    _check(deep_inside < outside * 0.35, "roofed deep interior is materially darker than exterior")
    _check(window_near > deep_inside, "window portal brightens nearby interior")
    _check(door_near_open > deep_inside, "open door portal brightens nearby interior")

    var door_mutation: DoorStateMutationService = fixture["door_mutation"]
    _check(door_mutation.set_state(String(fixture["door_id"]), DoorValues.CLOSED), "door closes truthfully")
    var door_near_closed: float = service.luminance_at(Vector2i(2, 0))
    _check(door_near_closed < door_near_open, "closing exterior door reduces portal daylight")

func _test_flashlight_occlusion_and_window_transmission() -> void:
    var fixture: Dictionary = _build_room_fixture(DoorValues.CLOSED)
    var service: PhysicalLightingService = _lighting_for_fixture(fixture, true)
    var flashlight := EmitterClass.new(
        "test.flashlight.west",
        Vector2i(-6, 0),
        Facing.Value.EAST,
        EmitterProfileClass.flashlight(),
        true,
        1
    )
    _check(service.set_emitters([flashlight]), "flashlight emitter accepted")

    var before_wall = service.illumination_at(Vector2i(-4, 0))
    var behind_wall = service.illumination_at(Vector2i(-1, 0))
    _check(before_wall.local_artificial > 0.10, "flashlight lights open cell before wall")
    _check(behind_wall.local_artificial < before_wall.local_artificial * 0.10, "wall produces physical flashlight shadow")

    var through_window := EmitterClass.new(
        "test.flashlight.window",
        Vector2i(0, -6),
        Facing.Value.SOUTH,
        EmitterProfileClass.flashlight(),
        true,
        2
    )
    _check(service.set_emitters([through_window]), "window flashlight emitter accepted")
    var outside_beam = service.illumination_at(Vector2i(0, -4))
    var inside_window = service.illumination_at(Vector2i(0, -2))
    _check(inside_window.local_artificial > 0.01, "window transmits flashlight into room")
    _check(inside_window.local_artificial < outside_beam.local_artificial, "window attenuates transmitted flashlight")

    var through_door := EmitterClass.new(
        "test.flashlight.door",
        Vector2i(6, 0),
        Facing.Value.WEST,
        EmitterProfileClass.flashlight(),
        true,
        3
    )
    _check(service.set_emitters([through_door]), "door flashlight emitter accepted")
    var closed_value: float = service.illumination_at(Vector2i(2, 0)).local_artificial
    _check(closed_value < 0.01, "closed door blocks direct flashlight light")
    var door_mutation: DoorStateMutationService = fixture["door_mutation"]
    _check(door_mutation.set_state(String(fixture["door_id"]), DoorValues.OPEN), "test door opens")
    var open_value: float = service.illumination_at(Vector2i(2, 0)).local_artificial
    _check(open_value > closed_value + 0.05, "open door transmits flashlight light")

func _test_weather_optics() -> void:
    var fixture: Dictionary = _build_room_fixture(DoorValues.OPEN)
    var service: PhysicalLightingService = _lighting_for_fixture(fixture, true)
    var flashlight := EmitterClass.new(
        "test.flashlight.fog",
        Vector2i(-6, 6),
        Facing.Value.EAST,
        EmitterProfileClass.flashlight(),
        true,
        1
    )
    _check(service.set_emitters([flashlight]), "fog test emitter accepted")
    _check(service.set_atmosphere(AtmosphereClass.clear(10)), "clear atmosphere accepted")
    var clear_sample = service.illumination_at(Vector2i(4, 6))
    _check(service.set_atmosphere(AtmosphereClass.fog(11)), "fog atmosphere accepted")
    var fog_sample = service.illumination_at(Vector2i(4, 6))
    _check(fog_sample.local_artificial < clear_sample.local_artificial, "fog reduces useful distant local light")
    _check(fog_sample.scatter > clear_sample.scatter, "fog increases light scatter descriptor")

    _check(service.set_atmosphere(AtmosphereClass.clear(12)), "clear daylight atmosphere restored")
    var clear_day: float = service.illumination_at(Vector2i(6, -6)).direct_celestial
    _check(service.set_atmosphere(AtmosphereClass.overcast(13)), "overcast atmosphere accepted")
    var overcast_day: float = service.illumination_at(Vector2i(6, -6)).direct_celestial
    _check(overcast_day < clear_day * 0.30, "overcast suppresses direct sunlight strongly")

func _test_light_driven_vision_range() -> void:
    _check(VisionRangePolicy.effective_range_for_luminance(0.0, 12, 1) == 2, "zero light shrinks useful vision to Candidate001 minimum")
    _check(VisionRangePolicy.effective_range_for_luminance(1.0, 12, 1) == 12, "full light restores geometric vision maximum")
    var dark_range: int = VisionRangePolicy.effective_range_for_luminance(0.04, 12, 1)
    var dim_range: int = VisionRangePolicy.effective_range_for_luminance(0.25, 12, 1)
    var bright_range: int = VisionRangePolicy.effective_range_for_luminance(0.64, 12, 1)
    _check(dark_range < dim_range and dim_range < bright_range, "vision range grows monotonically with physical light")

    var fixture: Dictionary = _build_room_fixture(DoorValues.CLOSED)
    var service: PhysicalLightingService = _lighting_for_fixture(fixture, true)
    var target := Vector2i(-2, 2)
    var unlit_range: int = service.effective_vision_range_at(target, 12, 1)
    var lamp := EmitterClass.new(
        "test.lamp.interior",
        target,
        Facing.Value.NORTH,
        EmitterProfileClass.lamp(),
        true,
        1
    )
    _check(service.set_emitters([lamp]), "interior lamp accepted")
    var lit_range: int = service.effective_vision_range_at(target, 12, 1)
    _check(lit_range > unlit_range, "lighting a target cell expands useful vision range toward it")
    _check(service.target_within_light_range(Vector2i(-2, -2), target, 12, 1), "lit target can fall inside light-dependent useful range")

func _test_determinism_and_zero_tick_cost() -> void:
    var fixture: Dictionary = _build_room_fixture(DoorValues.OPEN)
    var kernel: TickKernel = fixture["kernel"]
    var service: PhysicalLightingService = _lighting_for_fixture(fixture, false)
    var first := EmitterClass.new("test.a", Vector2i(-5, 5), Facing.Value.EAST, EmitterProfileClass.neon(Color(0.2, 0.5, 1.0)), true, 1)
    var second := EmitterClass.new("test.b", Vector2i(5, 5), Facing.Value.WEST, EmitterProfileClass.lamp(), true, 1)
    var before_tick: int = kernel.world_tick()
    _check(service.set_emitters([first, second]), "ordered emitter set accepted")
    var sample_a: Dictionary = service.illumination_at(Vector2i(0, 5)).to_dictionary()
    _check(service.set_emitters([second, first]), "reversed emitter set accepted")
    var sample_b: Dictionary = service.illumination_at(Vector2i(0, 5)).to_dictionary()
    _check(is_equal_approx(float(sample_a["useful_luminance"]), float(sample_b["useful_luminance"])), "emitter input ordering does not change luminance")
    _check(sample_a["tint"] == sample_b["tint"], "emitter input ordering does not change tint")
    _check(kernel.world_tick() == before_tick, "lighting queries and rebuilds consume zero WHEN ticks")

func _profile_rebuild_cost() -> void:
    var fixture: Dictionary = _build_room_fixture(DoorValues.OPEN)
    var service: PhysicalLightingService = _lighting_for_fixture(fixture, true)
    var started: int = Time.get_ticks_usec()
    var iterations: int = 50
    for i in range(iterations):
        var emitter := EmitterClass.new(
            "test.profile.flashlight",
            Vector2i(-6 + (i % 2), 4),
            Facing.Value.EAST,
            EmitterProfileClass.flashlight(),
            true,
            i + 1
        )
        service.set_emitters([emitter])
        service.illumination_at(Vector2i(4, 4))
    var elapsed: int = Time.get_ticks_usec() - started
    var average: float = float(elapsed) / float(iterations)
    print("PHYSICAL_LIGHTING_REBUILD_AVG_US=%.2f" % average)
    _check(average < 50000.0, "representative bounded lighting rebuild averages under 50ms on CI fixture")

func _lighting_for_fixture(fixture: Dictionary, force_night: bool) -> PhysicalLightingService:
    var ambient: OutdoorAmbientLightService
    if force_night:
        var flat_night := DaylightProfileClass.new(
            DaylightProfileClass.DEFAULT_DAWN_START_SECOND,
            DaylightProfileClass.DEFAULT_DAY_START_SECOND,
            DaylightProfileClass.DEFAULT_DUSK_START_SECOND,
            DaylightProfileClass.DEFAULT_NIGHT_START_SECOND,
            0.08,
            0.08
        )
        ambient = AmbientServiceClass.new(fixture["clock"], flat_night)
    else:
        ambient = AmbientServiceClass.new(fixture["clock"], DaylightProfileClass.new())
    var service := LightingClass.new(fixture["world"], fixture["doors"], ambient)
    service.set_field_bounds(fixture["bounds"])
    service.set_atmosphere(AtmosphereClass.clear())
    return service

func _build_room_fixture(initial_door_state: StringName) -> Dictionary:
    var world := WorldStateClass.new()
    var mutation := WorldMutationClass.new(world)
    var bounds := Rect2i(-8, -8, 17, 17)
    _check(mutation.set_terrain_rect(bounds, &"ground.concrete"), "fixture terrain created")

    var footprint := FootprintClass.single_cell()
    var serial: int = 0
    for x in range(-3, 4):
        if x != 0:
            serial += 1
            _place_structure(mutation, "test.wall.n.%d" % serial, &"wall.house", Vector2i(x, -3), StructureGeometry.Axis.HORIZONTAL, footprint)
        serial += 1
        _place_structure(mutation, "test.wall.s.%d" % serial, &"wall.house", Vector2i(x, 3), StructureGeometry.Axis.HORIZONTAL, footprint)
    for y in range(-2, 3):
        serial += 1
        _place_structure(mutation, "test.wall.w.%d" % serial, &"wall.house", Vector2i(-3, y), StructureGeometry.Axis.VERTICAL, footprint)
        if y != 0:
            serial += 1
            _place_structure(mutation, "test.wall.e.%d" % serial, &"wall.house", Vector2i(3, y), StructureGeometry.Axis.VERTICAL, footprint)

    _place_structure(mutation, "test.window.north", &"window.house", Vector2i(0, -3), StructureGeometry.Axis.HORIZONTAL, footprint)
    var door_id: String = "test.door.east"
    _place_structure(mutation, door_id, &"door.house", Vector2i(3, 0), StructureGeometry.Axis.VERTICAL, footprint)

    var doors := DoorStateClass.new()
    var door_mutation := DoorMutationClass.new(doors, world)
    _check(door_mutation.enroll(door_id, initial_door_state), "fixture door enrolled")

    var kernel := TickKernelClass.new()
    var clock := WorldTimeServiceClass.new(kernel, WorldTimeProfileClass.new())
    return {
        "world": world,
        "mutation": mutation,
        "doors": doors,
        "door_mutation": door_mutation,
        "door_id": door_id,
        "bounds": bounds,
        "kernel": kernel,
        "clock": clock,
    }

func _place_structure(
    mutation: WorldMutationService,
    entity_id: String,
    semantic: StringName,
    cell: Vector2i,
    axis: int,
    footprint: SpatialFootprint
) -> void:
    _check(mutation.create_entity(semantic, entity_id) == entity_id, "fixture structure entity %s created" % entity_id)
    _check(
        mutation.set_placement(entity_id, Layers.Channel.STRUCTURE, cell, Facing.Value.NORTH, footprint, axis),
        "fixture structure %s placed" % entity_id
    )

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)
