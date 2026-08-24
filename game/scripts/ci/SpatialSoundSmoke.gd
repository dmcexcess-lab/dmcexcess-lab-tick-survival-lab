extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorValues = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const SkillStateClass = preload("res://scripts/simulation/actors/skills/ActorSkillState.gd")
const NeedsStateClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const SoundEmissionClass = preload("res://scripts/simulation/sound/SoundEmission.gd")
const ProfilesClass = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const MaterialsClass = preload("res://scripts/simulation/sound/AcousticMaterialCatalog.gd")
const PropagationClass = preload("res://scripts/simulation/sound/AcousticPropagationQuery.gd")
const HearingClass = preload("res://scripts/simulation/sound/SurvivorHearingProfileProvider.gd")
const ObservationStoreClass = preload("res://scripts/simulation/sound/HeardSoundObservationStore.gd")
const SoundServiceClass = preload("res://scripts/simulation/sound/SpatialSoundService.gd")
const OverlayClass = preload("res://scripts/render/PerceptionOverlayRenderer.gd")

const POOR_ID := "sound.listener.poor"
const STRONG_ID := "sound.listener.strong"
const LISTENER_CELL := Vector2i(20, 20)

var _failures: Array[String] = []

func _initialize() -> void:
    var env: Dictionary = _build_environment()
    _test_profiles_and_hearing(env)
    _test_propagation(env)
    _test_detection_localization_and_knowledge(env)
    _test_grouping_pause_expiry_and_snapshot(env)
    _test_text_descriptor_contract()
    _benchmark_common_footstep(env)

    if _failures.is_empty():
        print("SPATIAL_SOUND_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SPATIAL_SOUND_SMOKE_FAIL: %s" % failure)
    quit(1)

func _build_environment() -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var doors := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(doors, world)
    _check(mutations.set_terrain_rect(Rect2i(Vector2i.ZERO, Vector2i(61, 61)), &"ground.grass"), "materialize acoustic fixture terrain")
    _check(_create_actor(mutations, POOR_ID, LISTENER_CELL, Facing.Value.NORTH), "create poor listener")
    _check(_create_actor(mutations, STRONG_ID, LISTENER_CELL, Facing.Value.NORTH), "create strong listener")

    var skills := SkillStateClass.new(world)
    var needs := NeedsStateClass.new(world)
    _check(skills.enroll_actor(POOR_ID) and skills.enroll_actor(STRONG_ID), "enroll hearing skills")
    _check(needs.enroll_actor(POOR_ID) and needs.enroll_actor(STRONG_ID), "enroll hearing needs")
    _check(skills.set_skill(STRONG_ID, &"survival", 10, 0), "set strong survival skill")
    _check(needs.set_all(POOR_ID, 100, 0, 0, 100), "set poor fatigue and sleep pressure")

    return {
        "world": world,
        "mutations": mutations,
        "doors": doors,
        "door_mutations": door_mutations,
        "skills": skills,
        "needs": needs,
    }

func _test_profiles_and_hearing(env: Dictionary) -> void:
    var profiles := ProfilesClass.new()
    _check(profiles.is_valid(), "sound profile catalog validates")
    _check(profiles.power(ProfilesClass.WALK_STEP) == 120, "walk acoustic budget is 120")
    _check(profiles.power(ProfilesClass.RUN_STRIDE) > profiles.power(ProfilesClass.WALK_STEP), "run is louder than walk")
    var hearing := HearingClass.new(env["skills"], env["needs"])
    var poor: Dictionary = hearing.profile(POOR_ID)
    var strong: Dictionary = hearing.profile(STRONG_ID)
    _check(int(poor.get("hearing_score", -1)) == 15, "fatigue plus sleep pressure degrade hearing to expected score")
    _check(int(strong.get("hearing_score", -1)) == 90, "survival 10 improves hearing to expected score")
    _check(int(strong.get("detection_threshold", 999)) < int(poor.get("detection_threshold", -1)), "strong listener detects weaker remaining energy")

func _test_propagation(env: Dictionary) -> void:
    var world: WorldState = env["world"]
    var mutations: WorldMutationService = env["mutations"]
    var doors: DoorStateStore = env["doors"]
    var door_mutations: DoorStateMutationService = env["door_mutations"]
    var materials := MaterialsClass.new()
    var propagation := PropagationClass.new(world, doors, materials)
    _check(propagation.is_ready(), "propagation query ready")

    var open_emission := SoundEmissionClass.new("sound.test.open", 0, Vector2i(5, 5), ProfilesClass.TEST_IMPACT, 300)
    var open_field: Dictionary = propagation.propagation_field(open_emission)
    _check(int((open_field.get(Vector2i(6, 5), {}) as Dictionary).get("cost", -1)) == 10, "cardinal open-air cost is 10")
    _check(int((open_field.get(Vector2i(6, 6), {}) as Dictionary).get("cost", -1)) == 14, "diagonal open-air cost is 14")

    _check(_create_structure(mutations, "sound.door", &"door.wood", Vector2i(11, 5)), "create acoustic door")
    _check(door_mutations.enroll("sound.door", DoorValues.OPEN), "enroll acoustic door open")
    var door_emission := SoundEmissionClass.new("sound.test.door", 0, Vector2i(10, 5), ProfilesClass.TEST_IMPACT, 300)
    var open_door_field: Dictionary = propagation.propagation_field(door_emission)
    var open_door_cost: int = int((open_door_field.get(Vector2i(11, 5), {}) as Dictionary).get("cost", -1))
    _check(door_mutations.set_state("sound.door", DoorValues.CLOSED), "close acoustic door")
    var closed_door_field: Dictionary = propagation.propagation_field(door_emission)
    var closed_door_cost: int = int((closed_door_field.get(Vector2i(11, 5), {}) as Dictionary).get("cost", -1))
    _check(closed_door_cost > open_door_cost, "closed door attenuates more than open door")

    _check(_create_structure(mutations, "sound.window", &"window.glass", Vector2i(11, 8)), "create acoustic window")
    var window_emission := SoundEmissionClass.new("sound.test.window", 0, Vector2i(10, 8), ProfilesClass.TEST_IMPACT, 300)
    var window_field: Dictionary = propagation.propagation_field(window_emission)
    var window_cost: int = int((window_field.get(Vector2i(11, 8), {}) as Dictionary).get("cost", -1))
    _check(window_cost > open_door_cost and window_cost < closed_door_cost, "window attenuation is between open and closed door")

    _check(_create_structure(mutations, "sound.wall", &"wall.exterior", Vector2i(11, 11)), "create acoustic wall")
    var wall_emission := SoundEmissionClass.new("sound.test.wall", 0, Vector2i(10, 11), ProfilesClass.TEST_IMPACT, 300)
    var wall_field: Dictionary = propagation.propagation_field(wall_emission)
    var wall_cost: int = int((wall_field.get(Vector2i(11, 11), {}) as Dictionary).get("cost", -1))
    _check(wall_cost > closed_door_cost, "wall attenuates more than closed door")

    _check(_create_structure(mutations, "sound.route.wall", &"wall.interior", Vector2i(6, 20)), "create route-around wall")
    var route_emission := SoundEmissionClass.new("sound.test.route", 0, Vector2i(5, 20), ProfilesClass.TEST_IMPACT, 300)
    var route_field: Dictionary = propagation.propagation_field(route_emission)
    var route_target: Dictionary = route_field.get(Vector2i(7, 20), {})
    _check(int(route_target.get("cost", 9999)) < 100, "weighted field routes around high-loss wall when open path is cheaper")

    var edge_emission := SoundEmissionClass.new("sound.test.edge", 0, Vector2i(0, 0), ProfilesClass.TEST_IMPACT, 300)
    var edge_field: Dictionary = propagation.propagation_field(edge_emission)
    _check(not edge_field.has(Vector2i(-1, 0)), "unmaterialized space is not invented for detailed propagation")

func _test_detection_localization_and_knowledge(env: Dictionary) -> void:
    var poor_service: SpatialSoundService = _new_service(env, [POOR_ID, STRONG_ID])
    var event_id: String = poor_service.emit_sound(ProfilesClass.WALK_STEP, Vector2i(20, 12), "", "detection")
    _check(not event_id.is_empty(), "weak walk emission resolves")
    _check(poor_service.active_observations(POOR_ID).is_empty(), "weak distant walk is unheard by poor listener")
    _check(poor_service.active_observations(STRONG_ID).size() == 1, "same weak distant walk is heard by strong listener")

    var rear_service: SpatialSoundService = _new_service(env, [POOR_ID])
    _check(not rear_service.emit_sound(ProfilesClass.TEST_IMPACT, Vector2i(15, 25), "hidden.source", "rear-left").is_empty(), "rear-left impact emits")
    var rear_observations: Array[HeardSoundObservation] = rear_service.active_observations(POOR_ID)
    _check(rear_observations.size() == 1, "poor listener hears strong rear-left impact")
    if rear_observations.size() == 1:
        var perceived: Vector2i = rear_observations[0].perceived_cell
        _check(perceived.y > LISTENER_CELL.y, "true rear sound never localizes into front half-plane")
        _check(perceived.x < LISTENER_CELL.x, "true left sound remains on listener left side")
        var snapshot: Dictionary = rear_observations[0].to_snapshot()
        _check(not snapshot.has("origin_cell") and not snapshot.has("source_entity_id"), "listener observation exposes no exact hidden source truth")

    var front_service: SpatialSoundService = _new_service(env, [POOR_ID])
    _check(not front_service.emit_sound(ProfilesClass.TEST_IMPACT, Vector2i(25, 15), "hidden.source", "front-right").is_empty(), "front-right impact emits")
    var front_observations: Array[HeardSoundObservation] = front_service.active_observations(POOR_ID)
    _check(front_observations.size() == 1, "poor listener hears strong front-right impact")
    if front_observations.size() == 1:
        var perceived_front: Vector2i = front_observations[0].perceived_cell
        _check(perceived_front.y < LISTENER_CELL.y, "true front sound never localizes into rear half-plane")
        _check(perceived_front.x > LISTENER_CELL.x, "true right sound remains on listener right side")

    var stable_service: SpatialSoundService = _new_service(env, [POOR_ID])
    stable_service.emit_sound(ProfilesClass.TEST_IMPACT, Vector2i(15, 25), "hidden.source", "stable")
    var first: Vector2i = stable_service.active_observations(POOR_ID)[0].perceived_cell
    var descriptors: Array[Dictionary] = stable_service.presentation_descriptors(POOR_ID)
    _check(descriptors.size() == 1 and descriptors[0].get("cell", Vector2i.ZERO) == first, "presentation uses stored perceived cell without rerolling")

func _test_grouping_pause_expiry_and_snapshot(env: Dictionary) -> void:
    var kernel := TickKernelClass.new()
    var service: SpatialSoundService = _new_service(env, [STRONG_ID], kernel)
    _check(not service.emit_sound(ProfilesClass.TEST_IMPACT, Vector2i(20, 14), "source.one", "repeated").is_empty(), "first repeated cue emits")
    _check(not service.emit_sound(ProfilesClass.TEST_IMPACT, Vector2i(20, 13), "source.one", "repeated").is_empty(), "second repeated cue emits")
    _check(service.active_observations(STRONG_ID).size() == 1, "repeated source/category refreshes one listener cue")

    var snapshot: Dictionary = service.observation_snapshot()
    var restored_store := ObservationStoreClass.new()
    _check(restored_store.load_snapshot(snapshot), "active heard observations restore")
    _check(restored_store.snapshot() == snapshot, "heard-observation snapshot roundtrip deterministic")

    var before_tick: int = kernel.world_tick()
    kernel.set_hard_paused(true)
    _check(kernel.schedule_event(40, "sound-test", &"noop") > 0, "schedule future tick for cue aging")
    kernel.run_until_stop()
    _check(kernel.world_tick() == before_tick, "hard pause advances no cue/world time")
    _check(service.active_observations(STRONG_ID).size() == 1, "cue remains readable during hard pause")
    kernel.set_hard_paused(false)
    kernel.run_until_stop()
    _check(kernel.world_tick() == 40, "world advances after hard pause released")
    _check(service.active_observations(STRONG_ID).is_empty(), "cue expires only after authoritative world ticks pass expiry")

func _test_text_descriptor_contract() -> void:
    var overlay := OverlayClass.new()
    _check(overlay.set_auditory_cues([{
        "cell": Vector2i(100, 100),
        "strength": 0.75,
        "certainty": 0.25,
        "category": "movement",
        "word": "footsteps",
    }]), "text auditory descriptor accepted by perception overlay")
    var cues: Array[Dictionary] = overlay.auditory_cues()
    _check(cues.size() == 1 and String(cues[0].get("word", "")) == "FOOTSTEPS", "auditory presentation normalizes yellow word vocabulary")

func _benchmark_common_footstep(env: Dictionary) -> void:
    var propagation := PropagationClass.new(env["world"], env["doors"], MaterialsClass.new())
    var emission := SoundEmissionClass.new("sound.benchmark", 0, Vector2i(30, 30), ProfilesClass.WALK_STEP, 120)
    var start_us: int = Time.get_ticks_usec()
    for _index in range(100):
        var field: Dictionary = propagation.propagation_field(emission)
        _check(not field.is_empty(), "benchmark footstep field resolves")
    var elapsed_us: int = Time.get_ticks_usec() - start_us
    var average_us: float = float(elapsed_us) / 100.0
    print("SPATIAL_SOUND_FOOTSTEP_AVG_US=%.2f" % average_us)
    _check(average_us < 16000.0, "common footstep propagation averages below one 60Hz frame budget")

func _new_service(env: Dictionary, listeners: Array[String], kernel_override: TickKernel = null) -> SpatialSoundService:
    var kernel: TickKernel = kernel_override if kernel_override != null else TickKernelClass.new()
    var profiles := ProfilesClass.new()
    var materials := MaterialsClass.new()
    var propagation := PropagationClass.new(env["world"], env["doors"], materials)
    var hearing := HearingClass.new(env["skills"], env["needs"])
    var store := ObservationStoreClass.new()
    var service := SoundServiceClass.new(env["world"], kernel, profiles, propagation, hearing, store)
    _check(service.is_ready(), "spatial sound service ready")
    for listener_id: String in listeners:
        _check(service.register_listener(listener_id), "register sound listener %s" % listener_id)
    return service

func _create_actor(mutations: WorldMutationService, actor_id: String, cell: Vector2i, facing: int) -> bool:
    if mutations.create_entity(&"actor.survivor", actor_id) != actor_id:
        return false
    return mutations.set_placement(actor_id, Layers.Channel.ACTOR, cell, facing, Footprint.single_cell())

func _create_structure(mutations: WorldMutationService, entity_id: String, semantic: StringName, cell: Vector2i) -> bool:
    if mutations.create_entity(semantic, entity_id) != entity_id:
        return false
    return mutations.set_placement(entity_id, Layers.Channel.STRUCTURE, cell, Facing.Value.NORTH, Footprint.single_cell())

func _check(condition: bool, label: String) -> void:
    if not condition:
        _failures.append(label)
