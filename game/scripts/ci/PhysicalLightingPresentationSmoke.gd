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
const AtmosphereClass = preload("res://scripts/simulation/lighting/AtmosphericOptics.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")
const EmitterClass = preload("res://scripts/simulation/lighting/LightEmitter.gd")
const LightingClass = preload("res://scripts/simulation/lighting/PhysicalLightingService.gd")
const PresentationClass = preload("res://scripts/render/PhysicalLightingPresentationRenderer.gd")
const DemoSourcesClass = preload("res://scripts/demo/DemoLightingSourceAdapter.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_backend_driven_presentation_maps()
    _test_dev_source_adapter_tracks_player_facing()

    if _failures.is_empty():
        print("PHYSICAL_LIGHTING_PRESENTATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PHYSICAL_LIGHTING_PRESENTATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_backend_driven_presentation_maps() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var bounds := Rect2i(0, 0, 17, 17)
    _check(mutations.set_terrain_rect(bounds, &"ground.concrete"), "presentation fixture terrain created")
    var footprint := FootprintClass.single_cell()
    for y in range(3, 14):
        var wall_id: String = "presentation.wall.%d" % y
        _check(mutations.create_entity(&"wall.test", wall_id) == wall_id, "presentation wall entity created")
        _check(
            mutations.set_placement(wall_id, Layers.Channel.STRUCTURE, Vector2i(8, y), Facing.Value.NORTH, footprint, StructureGeometry.Axis.VERTICAL),
            "presentation wall placed"
        )

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
    _check(lighting.set_field_bounds(bounds), "presentation lighting bounds accepted")
    _check(lighting.set_atmosphere(AtmosphereClass.rain(7)), "rain optics accepted for presentation")
    var flashlight := EmitterClass.new(
        "presentation.flashlight",
        Vector2i(4, 8),
        Facing.Value.EAST,
        EmitterProfileClass.flashlight(),
        true,
        1
    )
    var neon := EmitterClass.new(
        "presentation.neon",
        Vector2i(5, 5),
        Facing.Value.NORTH,
        EmitterProfileClass.neon(Color(0.2, 0.55, 1.0)),
        true,
        1
    )
    _check(lighting.set_emitters([flashlight, neon]), "presentation emitters accepted")

    var renderer := PresentationClass.new()
    get_root().add_child(renderer)
    _check(renderer.configure(lighting, world, doors), "presentation renderer configures")
    var before_tick: int = kernel.world_tick()
    _check(renderer.set_visible_window(bounds.position, bounds.size, 16.0), "presentation renderer accepts visible window")
    var snapshot: Dictionary = renderer.presentation_snapshot()
    _check(bool(snapshot.get("multiply_texture_ready", false)), "multiply light map texture is built")
    _check(bool(snapshot.get("glow_texture_ready", false)), "glow light map texture is built")
    _check(snapshot.get("texture_size", Vector2i.ZERO) == bounds.size, "light map texture matches bounded tactical field")
    _check(float(snapshot.get("max_luminance", 0.0)) > float(snapshot.get("min_luminance", 0.0)), "presentation preserves physical luminance contrast")
    _check(int(snapshot.get("glow_cells", 0)) > 0, "local/portal light produces glow-map energy")
    _check(int(snapshot.get("emitter_count", 0)) == 2, "presentation reads exact active emitter descriptors")
    _check(float(snapshot.get("wetness", 0.0)) > 0.8, "rain wet-surface factor reaches presentation shader")
    _check(kernel.world_tick() == before_tick, "presentation rebuild consumes zero WHEN ticks")

    var lit: Dictionary = renderer.presentation_values_for_cell(Vector2i(6, 8))
    var shadow: Dictionary = renderer.presentation_values_for_cell(Vector2i(10, 8))
    _check(float(lit.get("local_artificial", 0.0)) > float(shadow.get("local_artificial", 0.0)) + 0.10, "presentation uses backend flashlight shadow rather than a decorative beam")
    _check(float(lit.get("glow_strength", 0.0)) > float(shadow.get("glow_strength", 0.0)), "glow map respects backend shadow contrast")

    var revision_before: int = int(snapshot.get("presentation_revision", 0))
    _check(lighting.set_atmosphere(AtmosphereClass.fog(8)), "fog optics accepted for presentation")
    _check(renderer.refresh(&"fog_changed"), "presentation refreshes after atmosphere change")
    var fog_snapshot: Dictionary = renderer.presentation_snapshot()
    _check(int(fog_snapshot.get("presentation_revision", 0)) > revision_before, "presentation revision advances on visual rebuild")
    _check(float(fog_snapshot.get("scatter_strength", 0.0)) > float(snapshot.get("scatter_strength", 0.0)), "fog scatter reaches glow shader")
    _check(kernel.world_tick() == before_tick, "atmosphere presentation refresh remains zero tick")
    renderer.queue_free()

func _test_dev_source_adapter_tracks_player_facing() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    _check(mutations.set_terrain_rect(Rect2i(-5, -5, 11, 11), &"ground.concrete"), "DEV source fixture terrain created")
    var footprint := FootprintClass.single_cell()
    var player_id: String = "actor.presentation.test"
    _check(mutations.create_entity(&"actor.survivor", player_id) == player_id, "DEV source player created")
    _check(mutations.set_placement(player_id, Layers.Channel.ACTOR, Vector2i.ZERO, Facing.Value.EAST, footprint), "DEV source player placed")
    var door_id: String = "door.presentation.test"
    _check(mutations.create_entity(&"door.test", door_id) == door_id, "DEV source door created")
    _check(
        mutations.set_placement(door_id, Layers.Channel.STRUCTURE, Vector2i(1, 0), Facing.Value.NORTH, footprint, StructureGeometry.Axis.VERTICAL),
        "DEV source door placed"
    )

    var sources := DemoSourcesClass.new(world, player_id)
    _check(sources.is_ready(), "DEV lighting source adapter is ready")
    var initial: Array[LightEmitter] = sources.emitters()
    _check(initial.size() >= 2, "DEV lighting source adapter exposes flashlight plus critique-world static source")
    var initial_flashlight: LightEmitter = _emitter_by_id(initial, "dev.light.player_flashlight")
    _check(initial_flashlight != null and initial_flashlight.origin_cell == Vector2i.ZERO, "DEV flashlight follows controlled actor cell")
    _check(initial_flashlight != null and initial_flashlight.facing == Facing.Value.EAST, "DEV flashlight follows controlled actor facing")

    _check(mutations.set_placement(player_id, Layers.Channel.ACTOR, Vector2i.ZERO, Facing.Value.SOUTH, footprint), "DEV source player turns")
    var turned: Array[LightEmitter] = sources.emitters()
    var turned_flashlight: LightEmitter = _emitter_by_id(turned, "dev.light.player_flashlight")
    _check(turned_flashlight != null and turned_flashlight.facing == Facing.Value.SOUTH, "DEV flashlight descriptor updates after turn")
    _check(turned_flashlight != null and initial_flashlight != null and turned_flashlight.revision > initial_flashlight.revision, "DEV source revision advances when physical descriptor changes")

func _emitter_by_id(values: Array[LightEmitter], emitter_id: String) -> LightEmitter:
    for emitter: LightEmitter in values:
        if emitter.emitter_id == emitter_id:
            return emitter
    return null

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)
