extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const WorldTimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const WorldTimeServiceClass = preload("res://scripts/simulation/world_time/WorldTimeService.gd")
const DaylightProfileClass = preload("res://scripts/simulation/world_time/DaylightProfile.gd")
const AmbientServiceClass = preload("res://scripts/simulation/world_time/OutdoorAmbientLightService.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")
const EmitterClass = preload("res://scripts/simulation/lighting/LightEmitter.gd")
const LightingClass = preload("res://scripts/simulation/lighting/PhysicalLightingService.gd")
const LightingAcquisitionClass = preload("res://scripts/simulation/lighting/IlluminationVisualAcquisitionProvider.gd")
const VisionProfileClass = preload("res://scripts/simulation/perception/VisionProfile.gd")
const MemoryClass = preload("res://scripts/simulation/perception/PerceptionMemoryStore.gd")
const PerceptionClass = preload("res://scripts/simulation/perception/ObserverPerceptionService.gd")

const OBSERVER_ID := "lighting.perception.observer"
const TARGET_ID := "lighting.perception.target"
const OBSERVER_CELL := Vector2i(0, 6)
const TARGET_CELL := Vector2i(0, -2)
const NEAR_CELL := Vector2i(0, 5)
const WALL_CELL := Vector2i(0, 2)
const BOUNDS := Rect2i(-8, -8, 17, 17)

var _failures: Array[String] = []

func _initialize() -> void:
    _test_light_gated_acquisition_and_memory()
    _profile_light_aware_recompute()

    if _failures.is_empty():
        print("ILLUMINATION_PERCEPTION_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("ILLUMINATION_PERCEPTION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_light_gated_acquisition_and_memory() -> void:
    var env: Dictionary = _build_environment()
    var kernel: TickKernel = env["kernel"]
    var lighting: PhysicalLightingService = env["lighting"]
    var memory := MemoryClass.new()
    var acquisition := LightingAcquisitionClass.new(lighting)
    var perception := PerceptionClass.new(
        env["world"],
        env["doors"],
        kernel,
        memory,
        OBSERVER_ID,
        VisionProfileClass.new(),
        acquisition
    )

    _check(acquisition.is_ready(), "illumination acquisition provider is ready")
    _check(perception.is_ready(), "lighting-aware observer perception is ready")
    _check(perception.is_visible(NEAR_CELL), "near awareness remains acquired in darkness")
    _check(not perception.is_visible(TARGET_CELL), "distant geometric target is not acquired in deep night")
    _check(perception.knowledge_state(TARGET_CELL) == PerceptionClass.KnowledgeState.UNSEEN, "never-acquired dark target remains UNSEEN")
    _check(not memory.has_seen_cell(OBSERVER_ID, TARGET_CELL), "dark target does not refresh observer memory")

    var target_lamp := EmitterClass.new(
        "test.light.target",
        TARGET_CELL,
        Facing.Value.NORTH,
        EmitterProfileClass.lamp(),
        true,
        1
    )
    _check(lighting.set_emitters([target_lamp]), "target lamp accepted")
    _check(perception.recompute(&"target_lit"), "perception recomputes after target light")
    _check(perception.is_visible(TARGET_CELL), "physical target illumination expands actual acquired vision")
    _check(memory.has_seen_cell(OBSERVER_ID, TARGET_CELL), "acquired lit target refreshes environment memory")
    _check(not memory.last_seen_actor(OBSERVER_ID, TARGET_ID).is_empty(), "lit infected target creates observer-specific actor knowledge")

    _check(lighting.set_emitters([]), "target lamp can be removed")
    _check(perception.recompute(&"target_dark"), "perception recomputes after target goes dark")
    _check(not perception.is_visible(TARGET_CELL), "target leaves current acquisition when illumination falls")
    _check(perception.knowledge_state(TARGET_CELL) == PerceptionClass.KnowledgeState.REMEMBERED, "previously seen dark target cell becomes REMEMBERED")
    _check(memory.has_seen_cell(OBSERVER_ID, TARGET_CELL), "darkness does not erase stale environment memory")
    var stale_actor: Dictionary = memory.last_seen_actor(OBSERVER_ID, TARGET_ID)
    _check(stale_actor.get("cell", Vector2i.ZERO) == TARGET_CELL, "darkness does not magically track or erase last-seen actor knowledge")

    var side_lamp := EmitterClass.new(
        "test.light.third_party",
        TARGET_CELL + Vector2i(2, 0),
        Facing.Value.NORTH,
        EmitterProfileClass.streetlight(),
        true,
        2
    )
    _check(lighting.set_emitters([side_lamp]), "third-party light accepted")
    _check(perception.recompute(&"third_party_light"), "perception recomputes under third-party illumination")
    _check(perception.is_visible(TARGET_CELL), "another physical source can illuminate a target for the observer")

    var mutations: WorldMutationService = env["mutations"]
    _place_wall(mutations, "test.light.wall", WALL_CELL)
    _check(perception.recompute(&"wall_added"), "perception recomputes after wall insertion")
    _check(not perception.is_visible(TARGET_CELL), "bright target cannot be acquired through opaque geometry")
    _check(perception.is_visible(WALL_CELL), "blocking wall itself remains visually acquireable")

    _check(kernel.world_tick() == 0, "lighting-aware visual acquisition consumes zero WHEN ticks")

func _profile_light_aware_recompute() -> void:
    var env: Dictionary = _build_environment()
    var lighting: PhysicalLightingService = env["lighting"]
    var memory := MemoryClass.new()
    var acquisition := LightingAcquisitionClass.new(lighting)
    var perception := PerceptionClass.new(
        env["world"],
        env["doors"],
        env["kernel"],
        memory,
        OBSERVER_ID,
        VisionProfileClass.new(),
        acquisition
    )
    var iterations: int = 40
    var started: int = Time.get_ticks_usec()
    for i in range(iterations):
        var moving_light := EmitterClass.new(
            "test.light.profile",
            Vector2i((i % 3) - 1, -2),
            Facing.Value.NORTH,
            EmitterProfileClass.lamp(),
            true,
            i + 1
        )
        _check(lighting.set_emitters([moving_light]), "profile moving light accepted")
        _check(perception.recompute(&"lighting_profile"), "profile lighting-aware recompute succeeds")
    var elapsed: int = Time.get_ticks_usec() - started
    var average: float = float(elapsed) / float(iterations)
    print("PERCEPTION_LIGHTING_RECOMPUTE_AVG_US=%.2f" % average)
    _check(average < 50000.0, "lighting-aware perception recompute remains below 50ms on focused CI fixture")
    _check((env["kernel"] as TickKernel).world_tick() == 0, "profile recomputes consume zero WHEN ticks")

func _build_environment() -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var doors := DoorStateClass.new()
    _check(mutations.set_terrain_rect(BOUNDS, &"ground.concrete"), "lighting-perception terrain seeded")
    _check(_create_actor(mutations, OBSERVER_ID, OBSERVER_CELL, Facing.Value.NORTH, &"actor.survivor"), "observer created")
    _check(_create_actor(mutations, TARGET_ID, TARGET_CELL, Facing.Value.SOUTH, &"actor.infected"), "target actor created")

    var kernel := TickKernelClass.new(OBSERVER_ID)
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
    _check(lighting.set_field_bounds(BOUNDS), "lighting field bounds accepted")
    _check(lighting.is_ready(), "lighting backend is ready before perception provider")
    return {
        "world": world,
        "mutations": mutations,
        "doors": doors,
        "kernel": kernel,
        "lighting": lighting,
    }

func _create_actor(
    mutations: WorldMutationService,
    actor_id: String,
    cell: Vector2i,
    facing: int,
    semantic: StringName
) -> bool:
    if mutations.create_entity(semantic, actor_id) != actor_id:
        return false
    return mutations.set_placement(actor_id, Layers.Channel.ACTOR, cell, facing, FootprintClass.single_cell())

func _place_wall(mutations: WorldMutationService, wall_id: String, cell: Vector2i) -> void:
    _check(mutations.create_entity(&"wall.house", wall_id) == wall_id, "blocking wall entity created")
    _check(
        mutations.set_placement(
            wall_id,
            Layers.Channel.STRUCTURE,
            cell,
            Facing.Value.NORTH,
            FootprintClass.single_cell(),
            StructureGeometry.Axis.HORIZONTAL
        ),
        "blocking wall placed"
    )

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)
