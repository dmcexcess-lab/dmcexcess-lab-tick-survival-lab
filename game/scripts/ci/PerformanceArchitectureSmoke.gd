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
const LightingClass = preload("res://scripts/simulation/lighting/PhysicalLightingService.gd")
const SkyExposureClass = preload("res://scripts/simulation/weather/SkyExposureQuery.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    PerformanceTelemetry.reset()
    _test_domain_revisions_and_batch_summary()
    _test_geometry_consumers_ignore_actor_object_churn()
    if _failures.is_empty():
        print("PERFORMANCE_ARCHITECTURE_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PERFORMANCE_ARCHITECTURE_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_domain_revisions_and_batch_summary() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var footprint := FootprintClass.single_cell()
    _check(mutations.set_terrain_rect(Rect2i(0, 0, 32, 32), &"ground.asphalt"), "batch terrain created")
    var terrain_before: int = world.terrain_revision()
    var object_before: int = world.placement_revision(Layers.Channel.OBJECT)
    var structure_before: int = world.placement_revision(Layers.Channel.STRUCTURE)
    var batches: Array = []
    world.batch_changed.connect(func(batch): batches.append(batch))
    _check(world.begin_change_batch(&"ci_object_materialization"), "batch begins")
    for i in range(128):
        var entity_id: String = "test.bulk.object.%03d" % i
        _check(mutations.create_entity(&"prop.test", entity_id) == entity_id, "bulk object created")
        _check(mutations.set_placement(entity_id, Layers.Channel.OBJECT, Vector2i(1 + (i % 16), 1 + int(i / 16)), Facing.Value.NORTH, footprint), "bulk object placed")
    var completed = world.end_change_batch()
    _check(completed != null, "batch returns summary")
    _check(batches.size() == 1, "bulk mutation emits one completed batch signal")
    if completed != null:
        _check(completed.change_count == 256, "batch counts creates plus placements")
        _check(completed.channel_changed(Layers.Channel.OBJECT), "OBJECT marked dirty")
        _check(not completed.channel_changed(Layers.Channel.STRUCTURE), "STRUCTURE remains clean")
    _check(world.terrain_revision() == terrain_before, "OBJECT batch leaves terrain revision alone")
    _check(world.placement_revision(Layers.Channel.OBJECT) == object_before + 128, "OBJECT revision advances for placements")
    _check(world.placement_revision(Layers.Channel.STRUCTURE) == structure_before, "OBJECT batch leaves STRUCTURE revision alone")
    print("PERF_ARCH_BATCH_CHANGES=%d" % (0 if completed == null else completed.change_count))
    print("PERF_ARCH_BATCH_SIGNALS=%d" % batches.size())

func _test_geometry_consumers_ignore_actor_object_churn() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var footprint := FootprintClass.single_cell()
    var bounds := Rect2i(-16, -16, 32, 32)
    _check(mutations.set_terrain_rect(bounds, &"ground.concrete"), "geometry terrain created")
    var doors := DoorStateClass.new()
    var kernel := TickKernelClass.new()
    var clock := WorldTimeServiceClass.new(kernel, WorldTimeProfileClass.new())
    var flat_night := DaylightProfileClass.new(DaylightProfileClass.DEFAULT_DAWN_START_SECOND, DaylightProfileClass.DEFAULT_DAY_START_SECOND, DaylightProfileClass.DEFAULT_DUSK_START_SECOND, DaylightProfileClass.DEFAULT_NIGHT_START_SECOND, 0.08, 0.08)
    var ambient := AmbientServiceClass.new(clock, flat_night)
    var lighting := LightingClass.new(world, doors, ambient)
    _check(lighting.set_field_bounds(bounds), "lighting bounds accepted")
    _check(lighting.set_atmosphere(AtmosphereClass.clear()), "lighting atmosphere accepted")
    lighting.prepare_query()
    var sky := SkyExposureClass.new(world)
    _check(sky.is_exposed(Vector2i(-15, -15), bounds), "sky mask initializes")
    var start_light: Dictionary = lighting.debug_snapshot()
    var start_sky: Dictionary = sky.debug_snapshot(bounds)

    var actor_id := "actor.performance.test"
    _check(mutations.create_entity(&"actor.survivor", actor_id) == actor_id, "actor created")
    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i.ZERO, Facing.Value.NORTH, footprint), "actor placed")
    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(0, 1), Facing.Value.NORTH, footprint), "actor moved")
    lighting.prepare_query(); sky.is_exposed(Vector2i(-15, -15), bounds)
    var actor_light: Dictionary = lighting.debug_snapshot(); var actor_sky: Dictionary = sky.debug_snapshot(bounds)
    var actor_geo: int = int(actor_light.get("geometry_rebuilds", -1)) - int(start_light.get("geometry_rebuilds", -1))
    var actor_field: int = int(actor_light.get("field_rebuilds", -1)) - int(start_light.get("field_rebuilds", -1))
    var actor_sky_delta: int = int(actor_sky.get("rebuild_count", -1)) - int(start_sky.get("rebuild_count", -1))
    _check(actor_geo == 0 and actor_field == 0 and actor_sky_delta == 0, "ACTOR churn leaves lighting/shelter caches intact")

    var object_id := "test.performance.object"
    _check(mutations.create_entity(&"prop.test", object_id) == object_id, "object created")
    _check(mutations.set_placement(object_id, Layers.Channel.OBJECT, Vector2i(2, 2), Facing.Value.NORTH, footprint), "object placed")
    _check(mutations.set_placement(object_id, Layers.Channel.OBJECT, Vector2i(3, 2), Facing.Value.NORTH, footprint), "object moved")
    lighting.prepare_query(); sky.is_exposed(Vector2i(-15, -15), bounds)
    var object_light: Dictionary = lighting.debug_snapshot(); var object_sky: Dictionary = sky.debug_snapshot(bounds)
    var object_geo: int = int(object_light.get("geometry_rebuilds", -1)) - int(actor_light.get("geometry_rebuilds", -1))
    var object_field: int = int(object_light.get("field_rebuilds", -1)) - int(actor_light.get("field_rebuilds", -1))
    var object_sky_delta: int = int(object_sky.get("rebuild_count", -1)) - int(actor_sky.get("rebuild_count", -1))
    _check(object_geo == 0 and object_field == 0 and object_sky_delta == 0, "OBJECT churn leaves lighting/shelter caches intact")

    var structure_id := "test.performance.wall"
    _check(mutations.create_entity(&"wall.house", structure_id) == structure_id, "structure created")
    _check(mutations.set_placement(structure_id, Layers.Channel.STRUCTURE, Vector2i(5, 5), Facing.Value.NORTH, footprint, StructureGeometry.Axis.HORIZONTAL), "structure placed")
    lighting.prepare_query(); sky.is_exposed(Vector2i(-15, -15), bounds)
    var structure_light: Dictionary = lighting.debug_snapshot(); var structure_sky: Dictionary = sky.debug_snapshot(bounds)
    var structure_geo: int = int(structure_light.get("geometry_rebuilds", -1)) - int(object_light.get("geometry_rebuilds", -1))
    var structure_sky_delta: int = int(structure_sky.get("rebuild_count", -1)) - int(object_sky.get("rebuild_count", -1))
    _check(structure_geo == 1, "STRUCTURE change rebuilds lighting geometry exactly once")
    _check(structure_sky_delta == 1, "STRUCTURE change rebuilds shelter mask exactly once")

    print("PERF_ARCH_LIGHT_GEOMETRY_ACTOR_DELTA=%d" % actor_geo)
    print("PERF_ARCH_LIGHT_FIELD_ACTOR_DELTA=%d" % actor_field)
    print("PERF_ARCH_LIGHT_GEOMETRY_OBJECT_DELTA=%d" % object_geo)
    print("PERF_ARCH_LIGHT_FIELD_OBJECT_DELTA=%d" % object_field)
    print("PERF_ARCH_LIGHT_GEOMETRY_STRUCTURE_DELTA=%d" % structure_geo)
    print("PERF_ARCH_SKY_ACTOR_DELTA=%d" % actor_sky_delta)
    print("PERF_ARCH_SKY_OBJECT_DELTA=%d" % object_sky_delta)
    print("PERF_ARCH_SKY_STRUCTURE_DELTA=%d" % structure_sky_delta)

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)
