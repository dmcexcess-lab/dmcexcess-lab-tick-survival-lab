extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const DoorValues = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const ProfileClass = preload("res://scripts/simulation/perception/VisionProfile.gd")
const VisionQueryClass = preload("res://scripts/simulation/perception/VisionQuery.gd")
const MemoryClass = preload("res://scripts/simulation/perception/PerceptionMemoryStore.gd")
const PerceptionClass = preload("res://scripts/simulation/perception/ObserverPerceptionService.gd")
const OverlayClass = preload("res://scripts/render/PerceptionOverlayRenderer.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")

const OBSERVER_ID := "perception.observer"
const ACTOR_A_ID := "perception.actor.a"
const ACTOR_B_ID := "perception.actor.b"
const DOOR_ID := "perception.door"
const REMOVED_PROP_ID := "perception.prop.removed"
const STABLE_PROP_ID := "perception.prop.stable"
const LARGE_PROP_ID := "perception.prop.large"
const REMOVED_PROP_CELL := Vector2i(24, 17)
const STABLE_PROP_CELL := Vector2i(16, 17)
const LARGE_PROP_ANCHOR := Vector2i(24, 18)
const LARGE_PROP_VISIBLE_CELL := Vector2i(23, 18)
const CENTER := Vector2i(20, 20)

var _failures: Array[String] = []

func _initialize() -> void:
    _test_profile_and_los()
    _test_memory_last_seen_and_sound_layering()
    _test_memory_snapshot_roundtrip()

    if _failures.is_empty():
        print("PERCEPTION_FOG_MEMORY_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PERCEPTION_FOG_MEMORY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_profile_and_los() -> void:
    var env: Dictionary = _build_environment()
    var world: WorldState = env["world"]
    var door_state: DoorStateStore = env["door_state"]
    var profile := ProfileClass.new()
    var vision := VisionQueryClass.new(world, door_state)

    _check(profile.is_valid(), "Candidate001 profile is valid")
    _check(profile.max_range == 12, "Candidate001 range is 12")
    _check(profile.near_awareness_radius == 1, "Candidate001 near awareness is radius 1")

    _check(vision.can_see(CENTER, Facing.Value.NORTH, CENTER + Vector2i(0, -3), profile), "north facing sees north target")
    _check(not vision.can_see(CENTER, Facing.Value.SOUTH, CENTER + Vector2i(0, -3), profile), "south facing does not see north target")
    _check(vision.can_see(CENTER, Facing.Value.EAST, CENTER + Vector2i(5, 0), profile), "east facing rotates cone")
    _check(vision.can_see(CENTER, Facing.Value.SOUTH, CENTER + Vector2i(0, 5), profile), "south facing rotates cone")
    _check(vision.can_see(CENTER, Facing.Value.WEST, CENTER + Vector2i(-5, 0), profile), "west facing rotates cone")
    _check(vision.can_see(CENTER, Facing.Value.NORTH, CENTER + Vector2i(0, 1), profile), "radius-one cell behind observer remains visible")
    _check(profile.contains_offset(Vector2i(0, -12), Facing.Value.NORTH), "range boundary is included")
    _check(not profile.contains_offset(Vector2i(0, -13), Facing.Value.NORTH), "beyond range boundary is excluded")
    _check(profile.contains_offset(Vector2i(3, -2), Facing.Value.NORTH), "integer cone includes inside-edge candidate")
    _check(not profile.contains_offset(Vector2i(4, -2), Facing.Value.NORTH), "integer cone excludes outside candidate")

    _check(vision.can_see(CENTER, Facing.Value.NORTH, Vector2i(20, 16), profile), "opaque wall target itself is visible")
    _check(not vision.can_see(CENTER, Facing.Value.NORTH, Vector2i(20, 15), profile), "wall blocks cell beyond")
    _check(vision.can_see(CENTER, Facing.Value.NORTH, Vector2i(22, 16), profile), "closed door target itself is visible")
    _check(not vision.can_see(CENTER, Facing.Value.NORTH, Vector2i(23, 14), profile), "closed door blocks collinear cell beyond")

    var door_mutations: DoorStateMutationService = env["door_mutations"]
    _check(door_mutations.set_state(DOOR_ID, DoorValues.OPEN), "door can be opened for LOS test")
    _check(vision.can_see(CENTER, Facing.Value.NORTH, Vector2i(23, 14), profile), "open door transmits LOS")
    _check(vision.can_see(CENTER, Facing.Value.NORTH, Vector2i(17, 14), profile), "window transmits LOS")
    _check(door_mutations.set_state(DOOR_ID, DoorValues.CLOSED), "door restored closed")

    var diagonal_origin := Vector2i(5, 5)
    _check(not vision.can_see(diagonal_origin, Facing.Value.NORTH, Vector2i(6, 4), profile), "sealed diagonal corner cannot be peeked through")

    var unknown_origin := Vector2i(28, 20)
    _check(vision.can_see(unknown_origin, Facing.Value.EAST, Vector2i(30, 20), profile), "unknown structure target is itself visible")
    _check(not vision.can_see(unknown_origin, Facing.Value.EAST, Vector2i(31, 20), profile), "unknown structure fails closed beyond target")

func _test_memory_last_seen_and_sound_layering() -> void:
    var env: Dictionary = _build_environment()
    var world: WorldState = env["world"]
    var mutations: WorldMutationService = env["mutations"]
    var door_state: DoorStateStore = env["door_state"]
    var door_mutations: DoorStateMutationService = env["door_mutations"]
    var unseen_cell := Vector2i(0, 0)
    _check(mutations.clear_terrain(unseen_cell), "remove far terrain before perception enrollment")

    var kernel := TickKernelClass.new(OBSERVER_ID)
    var memory := MemoryClass.new()
    var service := PerceptionClass.new(world, door_state, kernel, memory, OBSERVER_ID, ProfileClass.new())

    _check(service.is_ready(), "observer perception service is ready")
    var initial_tick: int = kernel.world_tick()
    _check(initial_tick == 0, "perception fixture starts at tick zero")

    var north_memory_cell := REMOVED_PROP_CELL
    _check(service.knowledge_state(north_memory_cell) == PerceptionClass.KnowledgeState.VISIBLE, "initial north cell is visible")
    _check(memory.has_seen_cell(OBSERVER_ID, north_memory_cell), "visible cell records explored memory")
    var visible_prop_memory: Dictionary = memory.environment_memory(OBSERVER_ID, REMOVED_PROP_CELL)
    var visible_props: Array = visible_prop_memory.get("props", [])
    _check(visible_props.size() == 1, "visible furniture is captured in environmental memory")
    if visible_props.size() == 1:
        _check(String(visible_props[0].get("entity_id", "")) == REMOVED_PROP_ID, "remembered furniture keeps stable entity identity")
        _check(String(visible_props[0].get("semantic_type", "")) == "prop.sofa", "remembered furniture keeps semantic art identity")

    _check(service.knowledge_state(LARGE_PROP_ANCHOR) != PerceptionClass.KnowledgeState.VISIBLE, "large prop anchor is outside the initial cone")
    _check(service.knowledge_state(LARGE_PROP_VISIBLE_CELL) == PerceptionClass.KnowledgeState.VISIBLE, "large prop non-anchor footprint cell is visible")
    var partial_prop_memory: Dictionary = memory.environment_memory(OBSERVER_ID, LARGE_PROP_VISIBLE_CELL)
    var partial_props: Array = partial_prop_memory.get("props", [])
    _check(_props_contain(partial_props, LARGE_PROP_ID), "visible non-anchor footprint cell remembers the whole stable prop identity")

    var closed_door_memory: Dictionary = memory.environment_memory(OBSERVER_ID, Vector2i(22, 16))
    var closed_structure: Dictionary = closed_door_memory.get("structure", {})
    _check(String(closed_structure.get("door_state", "")) == "closed", "visible closed door is remembered closed")
    _check(not memory.last_seen_actor(OBSERVER_ID, ACTOR_A_ID).is_empty(), "visible actor A creates last-seen observation")
    _check(not memory.last_seen_actor(OBSERVER_ID, ACTOR_B_ID).is_empty(), "visible actor B creates last-seen observation")

    _check(_face_actor(world, mutations, OBSERVER_ID, Facing.Value.SOUTH), "observer turns south")
    _check(service.knowledge_state(north_memory_cell) == PerceptionClass.KnowledgeState.REMEMBERED, "turning away changes explored north cell to remembered")
    _check(door_mutations.set_state(DOOR_ID, DoorValues.OPEN), "hidden door opens")
    var stale_door_memory: Dictionary = memory.environment_memory(OBSERVER_ID, Vector2i(22, 16))
    var stale_structure: Dictionary = stale_door_memory.get("structure", {})
    _check(String(stale_structure.get("door_state", "")) == "closed", "hidden live door change does not update remembered door")

    _check(mutations.remove_entity(REMOVED_PROP_ID), "hidden furniture is removed from live WHAT")
    var stale_prop_memory: Dictionary = memory.environment_memory(OBSERVER_ID, REMOVED_PROP_CELL)
    var stale_props: Array = stale_prop_memory.get("props", [])
    _check(stale_props.size() == 1 and String(stale_props[0].get("entity_id", "")) == REMOVED_PROP_ID, "hidden furniture removal does not update stale remembered clutter")

    _check(_move_actor(mutations, ACTOR_A_ID, Vector2i(8, 20), Facing.Value.WEST), "hidden actor A moves")
    var stale_actor_a: Dictionary = memory.last_seen_actor(OBSERVER_ID, ACTOR_A_ID)
    _check(stale_actor_a.get("cell", Vector2i.ZERO) == Vector2i(23, 18), "hidden actor movement does not move last-seen marker")

    _check(mutations.remove_entity(ACTOR_B_ID), "hidden actor B is removed")
    _check(not memory.last_seen_actor(OBSERVER_ID, ACTOR_B_ID).is_empty(), "hidden actor removal does not magically erase last-seen marker")

    var overlay := OverlayClass.new()
    var catalog := ArtCatalogClass.new()
    _check(overlay.configure(service, memory, catalog, OBSERVER_ID), "perception overlay configures")
    _check(overlay.set_visible_window(Vector2i.ZERO, Vector2i(41, 41), 8.0), "overlay accepts world-sized test view")
    var remembered_visuals: Array[Dictionary] = overlay.remembered_prop_visual_plans()
    var large_visual: Dictionary = _visual_plan(remembered_visuals, LARGE_PROP_ID)
    _check(not large_visual.is_empty(), "remembered large prop receives one deduplicated visual plan outside the cone")
    if not large_visual.is_empty():
        _check(String(large_visual.get("visual_id", "")) == "large_deciduous_tree_2x2", "remembered large prop reuses System-07B visual geometry")
        _check(large_visual.get("draw_span_cells", Vector2i.ZERO) == Vector2i(2, 2), "remembered large prop retains authored 2x2 draw span")
        _check(bool(large_visual.get("has_foreground", false)), "remembered large prop retains its foreground/overhang pass")

    _check(_face_actor(world, mutations, OBSERVER_ID, Facing.Value.WEST), "observer turns west")
    var updated_actor_a: Dictionary = memory.last_seen_actor(OBSERVER_ID, ACTOR_A_ID)
    _check(updated_actor_a.get("cell", Vector2i.ZERO) == Vector2i(8, 20), "seeing actor A elsewhere updates last-seen observation")

    _check(_face_actor(world, mutations, OBSERVER_ID, Facing.Value.NORTH), "observer returns north")
    _check(memory.last_seen_actor(OBSERVER_ID, ACTOR_B_ID).is_empty(), "seeing actor B's old empty cell disproves stale marker")
    var refreshed_door_memory: Dictionary = memory.environment_memory(OBSERVER_ID, Vector2i(22, 16))
    var refreshed_structure: Dictionary = refreshed_door_memory.get("structure", {})
    _check(String(refreshed_structure.get("door_state", "")) == "open", "re-observation refreshes remembered door state")
    var refreshed_prop_memory: Dictionary = memory.environment_memory(OBSERVER_ID, REMOVED_PROP_CELL)
    _check((refreshed_prop_memory.get("props", []) as Array).is_empty(), "re-observation clears stale furniture that is now visibly absent")

    _check(service.knowledge_state(unseen_cell) == PerceptionClass.KnowledgeState.UNSEEN, "far unmaterialized cell starts unseen")
    _check(mutations.set_terrain(unseen_cell, &"ground.concrete_clean"), "unseen terrain materializes after perception enrollment")
    _check(service.knowledge_state(unseen_cell) == PerceptionClass.KnowledgeState.UNSEEN, "new hidden world truth does not count as exploration")
    _check(not memory.has_seen_cell(OBSERVER_ID, unseen_cell), "materialization alone does not mark unseen cell explored")

    _check(_face_actor(world, mutations, OBSERVER_ID, Facing.Value.SOUTH), "observer turns away again for remembered-prop presentation")
    var unseen_sound := {
        "cue_id": "perception.sound.unseen",
        "group_id": "perception.group.unseen",
        "cell": unseen_cell,
        "radius_cells": 2,
        "strength": 0.7,
        "certainty": 0.4,
        "category": "impact",
        "word": "*thud*",
    }
    var seen_sound := {
        "cue_id": "perception.sound.seen",
        "group_id": "perception.group.seen",
        "cell": CENTER,
        "strength": 0.8,
        "certainty": 1.0,
        "category": "movement",
        "word": "*step step*",
    }
    _check(service.knowledge_state(CENTER) == PerceptionClass.KnowledgeState.VISIBLE, "observer cell remains visible for seen-sound classification")
    _check(overlay.set_auditory_cues([unseen_sound, seen_sound]), "seen and unseen auditory cues accepted")
    var counts: Dictionary = overlay.planned_cell_counts()
    _check(int(counts.get("remembered_props", 0)) >= 1, "overlay plans remembered furniture/clutter above dark fog")
    _check(int(counts.get("auditory", 0)) == 2, "both auditory cues are planned")
    _check(int(counts.get("auditory_seen_transient", 0)) == 1, "visible perceived-cell sound is classified as transient")
    _check(int(counts.get("auditory_unseen_latched", 0)) == 1, "unseen perceived-cell sound is classified as latched")
    _check(int(counts.get("unseen", 0)) > 0, "true fog remains present under auditory cue")
    _check(service.knowledge_state(unseen_cell) == PerceptionClass.KnowledgeState.UNSEEN, "auditory cue does not convert true fog to remembered")
    _check(not memory.has_seen_cell(OBSERVER_ID, unseen_cell), "auditory cue does not explore underlying terrain")
    _check(OverlayClass.TRUE_FOG_COLOR == Color.BLACK, "true fog presentation is fully black")

    _check(overlay.set_auditory_cues([]), "upstream auditory list can become empty")
    var latched_counts: Dictionary = overlay.planned_cell_counts()
    _check(int(latched_counts.get("auditory_unseen_latched", 0)) == 1, "unseen sound marker survives upstream tick expiry until next unpause")
    _check(overlay.notify_observer_decision_unpaused() == 1, "next observer unpause clears unseen hearing marker")
    var after_unpause_counts: Dictionary = overlay.planned_cell_counts()
    _check(int(after_unpause_counts.get("auditory_unseen_latched", 0)) == 0, "unseen marker is gone after unpause")
    _check(int(after_unpause_counts.get("auditory_seen_transient", 0)) <= 1, "seen sound lifetime remains independent one-second presentation fade")

    _check(kernel.world_tick() == initial_tick, "all perception/memory observation updates consume zero WHEN ticks")

    var start_us: int = Time.get_ticks_usec()
    for _index in range(100):
        _check(service.recompute(&"benchmark"), "benchmark recompute succeeds")
    var elapsed_us: int = Time.get_ticks_usec() - start_us
    var average_us: float = float(elapsed_us) / 100.0
    print("PERCEPTION_FOV_BENCH_AVG_US=%.2f" % average_us)
    _check(average_us < 16000.0, "Candidate001 FOV recompute averages below one 60Hz frame")
    _check(kernel.world_tick() == initial_tick, "benchmark recomputes also consume zero WHEN ticks")

func _test_memory_snapshot_roundtrip() -> void:
    var memory := MemoryClass.new()
    _check(memory.enroll_observer("observer.one"), "snapshot observer enrolls")
    var remembered_props: Array[Dictionary] = [{
        "entity_id": "prop.remembered",
        "semantic_type": "prop.sofa",
        "anchor": Vector2i(-3, 8),
        "facing": Facing.Value.EAST,
    }]
    _check(memory.remember_environment("observer.one", Vector2i(-3, 8), 42, &"ground.grass", {"present": false}, remembered_props), "snapshot environment with prop stores")
    _check(memory.remember_actor("observer.one", "actor.remembered", &"actor.infected", Vector2i(4, -2), Facing.Value.EAST, 43), "snapshot actor stores")
    var snapshot: Dictionary = memory.snapshot()
    _check(int(snapshot.get("schema_version", 0)) == 2, "perception memory snapshot schema records prop-capable v2")
    var restored := MemoryClass.new()
    _check(restored.load_snapshot(snapshot), "memory snapshot restores")
    _check(restored.snapshot() == snapshot, "memory snapshot roundtrip is deterministic")

func _build_environment() -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var door_state := DoorStateClass.new()
    var door_mutations := DoorMutationClass.new(door_state, world)
    _check(mutations.set_terrain_rect(Rect2i(Vector2i.ZERO, Vector2i(41, 41)), &"ground.grass"), "seed 41x41 materialized terrain")

    _check(_create_actor(mutations, OBSERVER_ID, CENTER, Facing.Value.NORTH, &"actor.survivor"), "create perception observer")
    _check(_create_actor(mutations, ACTOR_A_ID, Vector2i(23, 18), Facing.Value.WEST, &"actor.infected"), "create actor A")
    _check(_create_actor(mutations, ACTOR_B_ID, Vector2i(17, 18), Facing.Value.EAST, &"actor.infected"), "create actor B")
    _check(_create_prop(mutations, REMOVED_PROP_ID, REMOVED_PROP_CELL, Facing.Value.EAST, &"prop.sofa"), "create removable remembered furniture")
    _check(_create_prop(mutations, STABLE_PROP_ID, STABLE_PROP_CELL, Facing.Value.SOUTH, &"prop.refrigerator_white"), "create stable remembered clutter")
    var partial_footprint := Footprint.new([Vector2i.ZERO, Vector2i(-1, 0)])
    _check(_create_prop(mutations, LARGE_PROP_ID, LARGE_PROP_ANCHOR, Facing.Value.NORTH, &"prop.deciduous_large", partial_footprint), "create partially visible multi-cell large prop")

    _check(_create_structure(mutations, "perception.wall", Vector2i(20, 16), &"wall.house"), "create opaque wall")
    _check(_create_structure(mutations, DOOR_ID, Vector2i(22, 16), &"door.house"), "create door")
    _check(door_mutations.enroll(DOOR_ID, DoorValues.CLOSED), "enroll closed door")
    _check(_create_structure(mutations, "perception.window", Vector2i(18, 16), &"window.house"), "create transparent window")

    _check(_create_structure(mutations, "perception.corner.x", Vector2i(6, 5), &"wall.house"), "create diagonal corner x wall")
    _check(_create_structure(mutations, "perception.corner.y", Vector2i(5, 4), &"wall.house"), "create diagonal corner y wall")
    _check(_create_structure(mutations, "perception.unknown", Vector2i(30, 20), &"structure.unknown"), "create unknown fail-closed structure")

    return {
        "world": world,
        "mutations": mutations,
        "door_state": door_state,
        "door_mutations": door_mutations,
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
    return mutations.set_placement(actor_id, Layers.Channel.ACTOR, cell, facing, Footprint.single_cell())

func _create_prop(
    mutations: WorldMutationService,
    entity_id: String,
    cell: Vector2i,
    facing: int,
    semantic: StringName,
    footprint: SpatialFootprint = null
) -> bool:
    if mutations.create_entity(semantic, entity_id) != entity_id:
        return false
    var physical: SpatialFootprint = footprint if footprint != null else Footprint.single_cell()
    return mutations.set_placement(entity_id, Layers.Channel.OBJECT, cell, facing, physical)

func _create_structure(
    mutations: WorldMutationService,
    entity_id: String,
    cell: Vector2i,
    semantic: StringName
) -> bool:
    if mutations.create_entity(semantic, entity_id) != entity_id:
        return false
    return mutations.set_placement(
        entity_id,
        Layers.Channel.STRUCTURE,
        cell,
        Facing.Value.NORTH,
        Footprint.single_cell(),
        StructureGeometry.Axis.HORIZONTAL
    )

func _face_actor(
    world: WorldState,
    mutations: WorldMutationService,
    actor_id: String,
    facing: int
) -> bool:
    var placement: WorldPlacement = world.placement(actor_id)
    if placement == null:
        return false
    return mutations.set_placement(actor_id, Layers.Channel.ACTOR, placement.anchor, facing, placement.footprint)

func _move_actor(mutations: WorldMutationService, actor_id: String, cell: Vector2i, facing: int) -> bool:
    return mutations.set_placement(actor_id, Layers.Channel.ACTOR, cell, facing, Footprint.single_cell())

func _props_contain(values: Array, entity_id: String) -> bool:
    for value: Variant in values:
        if typeof(value) == TYPE_DICTIONARY and String((value as Dictionary).get("entity_id", "")) == entity_id:
            return true
    return false

func _visual_plan(values: Array[Dictionary], entity_id: String) -> Dictionary:
    for value: Dictionary in values:
        if String(value.get("entity_id", "")) == entity_id:
            return value
    return {}

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)