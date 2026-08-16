extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const MutationServiceClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")

var failures: Array[String] = []
var observed_changes: Array[WorldChange] = []
var reset_count: int = 0

func _initialize() -> void:
    _test_entity_identity_and_reads()
    _test_terrain_and_changes()
    _test_placement_and_occupancy()
    _test_structure_axis_validation()
    _test_snapshot_restore_and_atomic_rejection()

    if failures.is_empty():
        print("WORLD_STATE_SMOKE_OK")
        quit(0)
        return

    for failure: String in failures:
        push_error("WORLD_STATE_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fresh() -> Dictionary:
    var state := WorldStateClass.new()
    var mutations := MutationServiceClass.new(state)
    return {"state": state, "mutations": mutations}

func _test_entity_identity_and_reads() -> void:
    var fixture: Dictionary = _fresh()
    var state: WorldState = fixture["state"]
    var mutations: WorldMutationService = fixture["mutations"]

    var first: String = mutations.create_entity(&"actor.person")
    var second: String = mutations.create_entity(&"actor.person")
    _expect(not first.is_empty() and not second.is_empty() and first != second, "runtime IDs are unique")

    var requested: String = mutations.create_entity(&"actor.person", "person.family.alex")
    _expect(requested == "person.family.alex", "caller-supplied stable ID accepted")
    _expect(mutations.create_entity(&"actor.person", "person.family.alex").is_empty(), "duplicate ID rejected")
    _expect(mutations.create_entity(&"actor.person", " bad_id ").is_empty(), "invalid padded ID rejected")
    _expect(mutations.create_entity(&"").is_empty(), "empty semantic type rejected")

    var copy = state.entity(requested)
    _expect(copy != null, "entity read returns record")
    if copy != null:
        copy.semantic_type = &"tampered.type"
    _expect(state.entity(requested).semantic_type == &"actor.person", "entity read cannot mutate canonical record")

    var ids: Array[String] = state.entity_ids()
    var sorted_ids: Array[String] = ids.duplicate()
    sorted_ids.sort()
    _expect(ids == sorted_ids, "entity IDs are returned deterministically sorted")

func _test_terrain_and_changes() -> void:
    observed_changes.clear()
    var fixture: Dictionary = _fresh()
    var state: WorldState = fixture["state"]
    var mutations: WorldMutationService = fixture["mutations"]
    state.changed.connect(_on_world_changed)

    var cell := Vector2i(-120, 45)
    _expect(mutations.set_terrain(cell, &"terrain.grass"), "terrain set")
    _expect(state.terrain_at(cell) == &"terrain.grass", "terrain read at negative global coordinate")
    _expect(state.revision() == 1, "terrain set increments revision")
    _expect(observed_changes.size() == 1 and observed_changes[0].kind == ChangeClass.Kind.TERRAIN_SET, "terrain set emits typed change")
    _expect(observed_changes[0].sequence == 1, "change sequence matches revision")

    _expect(mutations.set_terrain(cell, &"terrain.grass"), "identical terrain set accepted")
    _expect(state.revision() == 1, "identical terrain set is a no-op")

    _expect(mutations.set_terrain(cell, &"terrain.asphalt"), "terrain replace")
    _expect(state.revision() == 2, "terrain replace increments revision")
    _expect(observed_changes.back().terrain_before == &"terrain.grass" and observed_changes.back().terrain_after == &"terrain.asphalt", "terrain change carries before/after")

    _expect(mutations.clear_terrain(cell), "terrain clear")
    _expect(not state.has_terrain(cell), "terrain removed")
    _expect(observed_changes.back().kind == ChangeClass.Kind.TERRAIN_REMOVED, "terrain removal emits change")

func _test_placement_and_occupancy() -> void:
    var fixture: Dictionary = _fresh()
    var state: WorldState = fixture["state"]
    var mutations: WorldMutationService = fixture["mutations"]

    var chair_id: String = mutations.create_entity(&"furniture.chair", "chair.a")
    var car_id: String = mutations.create_entity(&"vehicle.sedan", "car.a")
    var overlap_id: String = mutations.create_entity(&"furniture.crate", "crate.a")

    var chair_anchor := Vector2i(-3, -7)
    _expect(mutations.set_placement(chair_id, Layers.Channel.OBJECT, chair_anchor, FacingRules.Value.NORTH, Footprint.single_cell()), "single-cell placement")
    _expect(state.entities_at(chair_anchor, Layers.Channel.OBJECT) == [chair_id], "single-cell occupancy indexed")

    var car_footprint = Footprint.rectangle(2, 4)
    var car_anchor := Vector2i(20, 30)
    _expect(mutations.set_placement(car_id, Layers.Channel.OBJECT, car_anchor, FacingRules.Value.EAST, car_footprint), "rotated multi-cell placement")
    var expected_car_cells: Array[Vector2i] = car_footprint.world_cells(car_anchor, FacingRules.Value.EAST)
    for cell: Vector2i in expected_car_cells:
        _expect(car_id in state.entities_at(cell, Layers.Channel.OBJECT), "rotated footprint occupancy %s" % cell)

    _expect(mutations.set_placement(overlap_id, Layers.Channel.OBJECT, car_anchor, FacingRules.Value.NORTH, Footprint.single_cell()), "overlapping placement allowed by WHAT")
    var overlap_ids: Array[String] = state.entities_at(car_anchor, Layers.Channel.OBJECT)
    _expect(car_id in overlap_ids and overlap_id in overlap_ids, "occupancy index allows overlap without inventing collision policy")

    var moved_anchor := Vector2i(40, 12)
    _expect(mutations.set_placement(car_id, Layers.Channel.OBJECT, moved_anchor, FacingRules.Value.SOUTH, car_footprint), "placement move/rotate")
    for cell: Vector2i in expected_car_cells:
        if cell != car_anchor:
            _expect(car_id not in state.entities_at(cell, Layers.Channel.OBJECT), "old rotated footprint occupancy removed %s" % cell)
    var moved_cells: Array[Vector2i] = car_footprint.world_cells(moved_anchor, FacingRules.Value.SOUTH)
    for cell: Vector2i in moved_cells:
        _expect(car_id in state.entities_at(cell, Layers.Channel.OBJECT), "new moved footprint occupancy added %s" % cell)

    var before_noop_revision: int = state.revision()
    _expect(mutations.set_placement(car_id, Layers.Channel.OBJECT, moved_anchor, FacingRules.Value.SOUTH, car_footprint), "identical placement accepted")
    _expect(state.revision() == before_noop_revision, "identical placement is a no-op")

    _expect(mutations.unplace_entity(car_id), "entity can be unplaced without destruction")
    _expect(state.has_entity(car_id) and not state.has_placement(car_id), "unplaced entity remains persistent")
    for cell: Vector2i in moved_cells:
        _expect(car_id not in state.entities_at(cell, Layers.Channel.OBJECT), "unplace clears occupancy %s" % cell)

    _expect(mutations.set_placement(chair_id, Layers.Channel.OBJECT, chair_anchor, FacingRules.Value.NORTH, Footprint.single_cell()), "existing placement reset")
    _expect(mutations.remove_entity(chair_id), "remove placed entity")
    _expect(not state.has_entity(chair_id) and chair_id not in state.entities_at(chair_anchor, Layers.Channel.OBJECT), "entity removal also clears occupancy")

    _expect(not mutations.set_placement("missing", Layers.Channel.OBJECT, Vector2i.ZERO, FacingRules.Value.NORTH, Footprint.single_cell()), "placement requires existing entity")
    _expect(not mutations.set_placement(overlap_id, 99, Vector2i.ZERO, FacingRules.Value.NORTH, Footprint.single_cell()), "invalid layer rejected")
    _expect(not mutations.set_placement(overlap_id, Layers.Channel.OBJECT, Vector2i.ZERO, 99, Footprint.single_cell()), "invalid facing rejected")

func _test_structure_axis_validation() -> void:
    var fixture: Dictionary = _fresh()
    var state: WorldState = fixture["state"]
    var mutations: WorldMutationService = fixture["mutations"]

    var door_id: String = mutations.create_entity(&"door.house", "door.a")
    _expect(mutations.set_placement(door_id, Layers.Channel.STRUCTURE, Vector2i(5, 5), FacingRules.Value.NORTH, Footprint.single_cell(), StructureGeometry.Axis.HORIZONTAL), "structure axis stored on structure placement")
    var placed = state.placement(door_id)
    _expect(placed != null and placed.structure_axis == StructureGeometry.Axis.HORIZONTAL, "structure axis persists in placement")

    _expect(not mutations.set_placement(door_id, Layers.Channel.STRUCTURE, Vector2i(5, 5), FacingRules.Value.NORTH, Footprint.single_cell(), 99), "invalid structure axis rejected")
    _expect(not mutations.set_placement(door_id, Layers.Channel.OBJECT, Vector2i(5, 5), FacingRules.Value.NORTH, Footprint.single_cell(), StructureGeometry.Axis.VERTICAL), "axis on non-structure rejected")

func _test_snapshot_restore_and_atomic_rejection() -> void:
    reset_count = 0
    var fixture: Dictionary = _fresh()
    var state: WorldState = fixture["state"]
    var mutations: WorldMutationService = fixture["mutations"]

    mutations.set_terrain(Vector2i(4, -2), &"terrain.wood_floor")
    mutations.create_entity(&"furniture.sofa", "z.sofa")
    mutations.create_entity(&"furniture.table", "a.table")
    var runtime_id: String = mutations.create_entity(&"actor.person")
    mutations.set_placement("z.sofa", Layers.Channel.OBJECT, Vector2i(9, 9), FacingRules.Value.WEST, Footprint.rectangle(1, 2))

    var saved: Dictionary = state.snapshot()
    var entity_entries: Array = saved["entities"]
    _expect(String(entity_entries[0]["id"]) == "a.table", "snapshot entity records sorted by ID")

    var restored := WorldStateClass.new()
    restored.world_reset.connect(_on_world_reset)
    _expect(restored.load_snapshot(saved), "valid snapshot restores")
    _expect(reset_count == 1, "snapshot restore emits whole-world reset")
    _expect(restored.snapshot() == saved, "snapshot round trip is deterministic")
    _expect("z.sofa" in restored.entities_at(Vector2i(9, 9), Layers.Channel.OBJECT), "occupancy rebuilt from restored placement")

    var restored_mutations := MutationServiceClass.new(restored)
    var next_runtime_id: String = restored_mutations.create_entity(&"actor.person")
    _expect(not next_runtime_id.is_empty() and next_runtime_id != runtime_id and restored.has_entity(next_runtime_id), "restored runtime ID allocation continues without collision")

    var before_bad_restore: Dictionary = restored.snapshot()
    var malformed: Dictionary = before_bad_restore.duplicate(true)
    malformed["placements"].append({
        "entity_id": "missing.entity",
        "channel": Layers.Channel.OBJECT,
        "anchor": [0, 0],
        "facing": FacingRules.Value.NORTH,
        "footprint": [[0, 0]],
        "structure_axis": -1,
    })
    _expect(not restored.load_snapshot(malformed), "malformed snapshot rejected")
    _expect(restored.snapshot() == before_bad_restore, "malformed snapshot rejection is atomic")

func _on_world_changed(change: WorldChange) -> void:
    observed_changes.append(change)

func _on_world_reset() -> void:
    reset_count += 1

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
