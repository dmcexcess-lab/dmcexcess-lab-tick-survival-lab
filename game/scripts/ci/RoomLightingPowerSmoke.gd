extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const WorldTimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const WorldTimeServiceClass = preload("res://scripts/simulation/world_time/WorldTimeService.gd")
const DaylightProfileClass = preload("res://scripts/simulation/world_time/DaylightProfile.gd")
const AmbientServiceClass = preload("res://scripts/simulation/world_time/OutdoorAmbientLightService.gd")
const AtmosphereClass = preload("res://scripts/simulation/lighting/AtmosphericOptics.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")
const EmitterClass = preload("res://scripts/simulation/lighting/LightEmitter.gd")
const LightingClass = preload("res://scripts/simulation/lighting/PhysicalLightingService.gd")
const RendererClass = preload("res://scripts/render/PhysicalLightingPresentationRenderer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_non_bloom_room_light()
    if _failures.is_empty():
        print("ROOM_LIGHTING_POWER_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("ROOM_LIGHTING_POWER_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_non_bloom_room_light() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var bounds := Rect2i(-4, -4, 9, 9)
    _check(mutations.set_terrain_rect(bounds, &"ground.concrete"), "room-light fixture terrain created")
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
    _check(lighting.set_field_bounds(bounds), "room-light field bounds accepted")
    _check(lighting.set_atmosphere(AtmosphereClass.clear()), "room-light clear atmosphere accepted")

    var renderer := RendererClass.new()
    _check(renderer.configure(lighting, world, doors), "room-light presentation renderer configured")
    _check(renderer.set_visible_window(bounds.position, bounds.size, 1.0), "room-light presentation window configured")
    var target := Vector2i.ZERO
    var before: Dictionary = renderer.presentation_values_for_cell(target)

    var profile: LightEmitterProfile = EmitterProfileClass.room_ambient()
    _check(profile.is_valid(), "room ambient profile is valid")
    _check(is_zero_approx(profile.presentation_glow_scale), "room ambient profile has zero presentation glow scale")
    var room_light := EmitterClass.new(
        "test.room.ambient",
        target,
        Facing.Value.NORTH,
        profile,
        true,
        1
    )
    _check(lighting.set_emitters([room_light]), "room ambient emitter accepted")
    _check(renderer.refresh(&"room_light_on"), "room-light presentation refresh succeeds")
    var lit: Dictionary = renderer.presentation_values_for_cell(target)
    _check(float(lit.get("local_artificial", 0.0)) > 0.50, "room ambient raises real local artificial illumination")
    _check(float(lit.get("luminance", 0.0)) > float(before.get("luminance", 0.0)) + 0.45, "room ambient materially raises actual local light level")
    _check(float(lit.get("glow_strength", 1.0)) < 0.01, "room ambient adds no graphic bloom/glow")
    _check(float(lit.get("glare", 1.0)) < 0.01 and float(lit.get("scatter", 1.0)) < 0.01, "room ambient adds no source glare/scatter descriptors")

    var ordinary_lamp := EmitterClass.new(
        "test.room.visible_lamp",
        target,
        Facing.Value.NORTH,
        EmitterProfileClass.lamp(),
        true,
        2
    )
    _check(lighting.set_emitters([ordinary_lamp]), "ordinary visible lamp emitter accepted")
    _check(renderer.refresh(&"visible_lamp_on"), "visible-lamp presentation refresh succeeds")
    var visible_lamp: Dictionary = renderer.presentation_values_for_cell(target)
    _check(float(visible_lamp.get("glow_strength", 0.0)) > 0.10, "ordinary light profiles retain visible bloom")

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
