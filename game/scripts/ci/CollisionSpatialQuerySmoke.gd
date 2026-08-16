extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const CatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const OverrideClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const QueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const ResultClass = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var overrides := OverrideClass.new()
    var query := QueryClass.new(world, catalog, overrides)

    _check(query.is_ready(), "query service composes WHAT + collision state")

    for y: int in range(0, 5):
        for x: int in range(0, 7):
            _check(mutations.set_terrain(Vector2i(x, y), &"ground.test"), "terrain setup")

    _check(catalog.register(&"structure.wall", true), "wall profile registers")
    _check(catalog.register(&"structure.door", true), "door profile registers")
    _check(catalog.register(&"object.chair", true), "chair profile registers")
    _check(catalog.register(&"object.table", true), "table profile registers")
    _check(catalog.register(&"object.bush", false), "explicit non-blocking object profile registers")
    _check(catalog.register(&"actor.person", true), "actor profile registers")

    var copied_profile: CollisionProfile = catalog.profile_for(&"structure.wall")
    _check(copied_profile != null and copied_profile.blocks_movement, "catalog profile read works")
    copied_profile.blocks_movement = false
    var reread_profile: CollisionProfile = catalog.profile_for(&"structure.wall")
    _check(reread_profile != null and reread_profile.blocks_movement, "catalog reads are mutation-safe copies")

    var actor_id := mutations.create_entity(&"actor.person", "actor_player")
    var wall_id := mutations.create_entity(&"structure.wall", "wall_test")
    var bush_id := mutations.create_entity(&"object.bush", "bush_test")
    var unknown_id := mutations.create_entity(&"object.unknown", "unknown_test")
    var loose_id := mutations.create_entity(&"item.can", "loose_can")
    var door_id := mutations.create_entity(&"structure.door", "door_test")
    var chair_id := mutations.create_entity(&"object.chair", "chair_test")
    var table_id := mutations.create_entity(&"object.table", "table_test")
    var vehicle_id := mutations.create_entity(&"actor.person", "multi_actor")

    _check(actor_id == "actor_player" and wall_id == "wall_test", "stable requested IDs created")

    _check(mutations.set_placement(actor_id, Layers.Channel.ACTOR, Vector2i(0, 0), Facing.Value.NORTH, Footprint.single_cell()), "place actor")
    _check(mutations.set_placement(wall_id, Layers.Channel.STRUCTURE, Vector2i(2, 0), Facing.Value.NORTH, Footprint.single_cell()), "place wall")
    _check(mutations.set_placement(bush_id, Layers.Channel.OBJECT, Vector2i(1, 1), Facing.Value.NORTH, Footprint.single_cell()), "place bush")
    _check(mutations.set_placement(unknown_id, Layers.Channel.OBJECT, Vector2i(3, 1), Facing.Value.NORTH, Footprint.single_cell()), "place unclassified object")
    _check(mutations.set_placement(loose_id, Layers.Channel.LOOSE_ITEM, Vector2i(4, 1), Facing.Value.NORTH, Footprint.single_cell()), "place loose item")
    _check(mutations.set_placement(door_id, Layers.Channel.STRUCTURE, Vector2i(5, 1), Facing.Value.NORTH, Footprint.single_cell()), "place door")
    _check(mutations.set_placement(chair_id, Layers.Channel.OBJECT, Vector2i(2, 2), Facing.Value.NORTH, Footprint.single_cell()), "place chair")
    _check(mutations.set_placement(table_id, Layers.Channel.OBJECT, Vector2i(2, 2), Facing.Value.NORTH, Footprint.single_cell()), "place overlapping table")
    _check(mutations.set_placement(vehicle_id, Layers.Channel.ACTOR, Vector2i(0, 3), Facing.Value.NORTH, Footprint.rectangle(2, 1)), "place multi-cell actor")

    var self_result: SpatialQueryResult = query.query_entity_footprint(actor_id, Vector2i(0, 0))
    _check(self_result.status == ResultClass.Status.CLEAR, "self-ignore avoids colliding with current footprint")

    var wall_result: SpatialQueryResult = query.query_cell(Vector2i(2, 0))
    _check(wall_result.status == ResultClass.Status.BLOCKED and wall_result.blocking_entity_ids == [wall_id], "classified wall blocks movement")

    var bush_result: SpatialQueryResult = query.query_cell(Vector2i(1, 1))
    _check(bush_result.status == ResultClass.Status.CLEAR, "explicit non-blocking object remains clear")

    var unknown_result: SpatialQueryResult = query.query_cell(Vector2i(3, 1))
    _check(unknown_result.status == ResultClass.Status.UNKNOWN and unknown_result.unclassified_entity_ids == [unknown_id], "unclassified OBJECT fails closed as UNKNOWN")

    var loose_result: SpatialQueryResult = query.query_cell(Vector2i(4, 1))
    _check(loose_result.status == ResultClass.Status.CLEAR, "unclassified loose item does not become false blocker")

    var missing_result: SpatialQueryResult = query.query_cell(Vector2i(20, 20))
    _check(missing_result.status == ResultClass.Status.UNKNOWN and missing_result.missing_terrain_cells == [Vector2i(20, 20)], "missing terrain is UNKNOWN, not empty")

    var door_closed: SpatialQueryResult = query.query_cell(Vector2i(5, 1))
    _check(door_closed.status == ResultClass.Status.BLOCKED, "door type default blocks")
    _check(overrides.set_override(door_id, false), "dynamic door-style non-blocking override sets")
    var door_open: SpatialQueryResult = query.query_cell(Vector2i(5, 1))
    _check(door_open.status == ResultClass.Status.CLEAR, "entity override supersedes blocking type default")
    _check(overrides.clear_override(door_id), "dynamic override clears")
    _check(query.query_cell(Vector2i(5, 1)).status == ResultClass.Status.BLOCKED, "cleared override returns to type default")

    var double_blocker: SpatialQueryResult = query.query_cell(Vector2i(2, 2))
    _check(double_blocker.status == ResultClass.Status.BLOCKED, "overlapping blockers are blocked")
    _check(double_blocker.blocking_entity_ids == [chair_id, table_id], "blocking IDs are deterministic and deduplicated")

    var rotated_multi: SpatialQueryResult = query.query_entity_footprint(vehicle_id, Vector2i(2, 2), Facing.Value.EAST)
    _check(rotated_multi.cells == [Vector2i(2, 2), Vector2i(2, 3)], "rotated multi-cell footprint queries every target cell")
    _check(rotated_multi.status == ResultClass.Status.BLOCKED, "multi-cell target fails when one occupied cell blocks")
    _check(rotated_multi.blocking_entity_ids == [chair_id, table_id], "multi-cell blockers are aggregated deterministically")

    var placements: Array[WorldPlacement] = query.placements_at(Vector2i(2, 2), Layers.Channel.OBJECT)
    _check(placements.size() == 2, "spatial query exposes mutation-safe placement copies at a cell")
    if not placements.is_empty():
        placements[0].anchor = Vector2i(99, 99)
    _check(world.placement(chair_id).anchor == Vector2i(2, 2), "placement query cannot mutate WHAT")

    var initial_report: Dictionary = query.collision_coverage_report()
    _check(initial_report["missing_required_profiles"] == [unknown_id], "coverage reports missing required physics profile")
    _check(initial_report["orphan_overrides"].is_empty(), "coverage starts without orphan overrides")

    _check(overrides.set_override("orphan_collision_state", true), "sparse orphan override can exist independently of WHAT")
    var orphan_report: Dictionary = query.collision_coverage_report()
    _check(orphan_report["orphan_overrides"] == ["orphan_collision_state"], "coverage reports orphan collision override")

    _check(overrides.set_override(unknown_id, false), "explicit override can classify otherwise unknown entity")
    _check(query.query_cell(Vector2i(3, 1)).status == ResultClass.Status.CLEAR, "explicit false override resolves missing type profile")
    var resolved_report: Dictionary = query.collision_coverage_report()
    _check(resolved_report["missing_required_profiles"].is_empty(), "override satisfies required collision classification")

    var snap: Dictionary = overrides.snapshot()
    var restored := OverrideClass.new()
    _check(restored.load_snapshot(snap), "collision override snapshot restores")
    _check(restored.snapshot() == snap, "collision override snapshot round-trips deterministically")

    var before_bad: Dictionary = restored.snapshot()
    var malformed: Dictionary = before_bad.duplicate(true)
    malformed["overrides"] = [{"entity_id": unknown_id, "blocks_movement": "not_bool"}]
    _check(not restored.load_snapshot(malformed), "malformed collision override snapshot rejected")
    _check(restored.snapshot() == before_bad, "failed collision override restore is atomic")

    if _failures.is_empty():
        print("COLLISION_SPATIAL_QUERY_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("COLLISION_SPATIAL_QUERY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
