extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const MutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const DoorStateClass = preload("res://scripts/simulation/doors/DoorStateStore.gd")
const DoorMutationClass = preload("res://scripts/simulation/doors/DoorStateMutationService.gd")
const BuildingValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const BuildingMaterializerClass = preload("res://scripts/generation/buildings/GeneratedBuildingMaterializer.gd")
const GridClass = preload("res://scripts/streaming/StreamingRegionGrid.gd")
const StreamingClass = preload("res://scripts/streaming/WorldStreamingCoordinator.gd")
const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const GroundRendererClass = preload("res://scripts/render/GroundLayerRenderer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")

class CountingWorld:
    extends WorldState
    var snapshot_calls: int = 0

    func snapshot() -> Dictionary:
        snapshot_calls += 1
        return super.snapshot()

class CountingProvider:
    extends RefCounted
    var discovery_calls: int = 0

    func is_ready() -> bool:
        return true

    func source_kind() -> StringName:
        return &"perf.test"

    func source_handles_intersecting(_global_plan: GeneratedGlobalWorldPlan, _bounds_list: Array[Rect2i]) -> Array[Dictionary]:
        discovery_calls += 1
        return []

class CountingMaterialization:
    extends WorldMaterializationCoordinator
    var ensure_calls: int = 0

    func is_ready() -> bool:
        return true

    func source_providers() -> Array:
        return []

    func supports_source_kind(source_kind: StringName) -> bool:
        return source_kind == &"perf.test"

    func ensure_sources(_global_plan: GeneratedGlobalWorldPlan, _source_handles: Array) -> Dictionary:
        ensure_calls += 1
        return {
            "ok": true,
            "failure_reason": "",
            "newly_materialized": [],
            "already_materialized": [],
        }

var failures: Array[String] = []
var observed_changes: Array[WorldChange] = []
var redraw_events: Array[StringName] = []

func _initialize() -> void:
    _test_bulk_terrain_and_renderer_invalidation()
    _test_building_transaction_seam()
    _test_same_region_streaming_fast_path()
    _finish()

func _test_bulk_terrain_and_renderer_invalidation() -> void:
    observed_changes.clear()
    redraw_events.clear()
    var world: WorldState = WorldStateClass.new()
    var mutations: WorldMutationService = MutationClass.new(world)
    world.changed.connect(_on_world_changed)

    var renderer: GroundLayerRenderer = GroundRendererClass.new()
    renderer.redraw_requested.connect(_on_redraw_requested)
    _check(renderer.configure(world, CatalogClass.new()), "ground renderer configures for bulk invalidation")
    _check(renderer.set_visible_window(Vector2i(10, 10), Vector2i(4, 4), 32.0), "bulk test visible window configures")
    redraw_events.clear()

    var rect := Rect2i(10, 10, 64, 64)
    _check(mutations.set_terrain_rect(rect, &"ground.grass"), "64x64 terrain rectangle writes successfully")
    _check(world.revision() == 1, "4096-cell rectangle advances WHAT revision exactly once")
    _check(observed_changes.size() == 1 and observed_changes[0].kind == ChangeClass.Kind.TERRAIN_BATCH_SET, "rectangle emits one typed batch terrain change")
    if not observed_changes.is_empty():
        _check(observed_changes[0].terrain_rect == rect and observed_changes[0].terrain_after == &"ground.grass", "batch terrain record carries replay-safe rectangle + final semantic")
    _check(world.terrain_at(Vector2i(10, 10)) == &"ground.grass" and world.terrain_at(Vector2i(73, 73)) == &"ground.grass", "bulk rectangle writes both corners")
    _check(redraw_events.size() == 1 and redraw_events[0] == &"terrain_changed", "visible 4096-cell batch requests one ground redraw")

    redraw_events.clear()
    var revision_after_first: int = world.revision()
    var changes_after_first: int = observed_changes.size()
    _check(mutations.set_terrain_rect(rect, &"ground.grass"), "identical rectangle rewrite is accepted")
    _check(world.revision() == revision_after_first and observed_changes.size() == changes_after_first, "identical rectangle rewrite is a zero-revision/no-notification no-op")
    _check(redraw_events.is_empty(), "identical rectangle rewrite requests no redraw")

    var sparse: Array[Vector2i] = [Vector2i(9, 11), Vector2i(30, 30), Vector2i(9, 11)]
    _check(mutations.set_terrain_cells(sparse, &"ground.road"), "sparse batch terrain write succeeds")
    _check(world.revision() == revision_after_first + 1, "sparse batch advances revision once")
    var last_change: WorldChange = observed_changes.back()
    _check(last_change.kind == ChangeClass.Kind.TERRAIN_BATCH_SET and last_change.terrain_cells.size() == 2, "sparse batch deduplicates changed cells into one notification")
    _check(last_change.terrain_cells == [Vector2i(9, 11), Vector2i(30, 30)], "sparse batch notification ordering is deterministic y/x")
    _check(redraw_events.size() == 1, "one-cell cardinal halo inside sparse batch requests one redraw")

    redraw_events.clear()
    _check(mutations.set_terrain_rect(Rect2i(1000, 1000, 8, 8), &"ground.grass"), "distant rectangle batch succeeds")
    _check(redraw_events.is_empty(), "distant bulk terrain does not redraw visible ground")

    redraw_events.clear()
    _check(mutations.set_terrain_rect(Rect2i(9, 9, 1, 1), &"ground.road"), "diagonal batch succeeds")
    _check(redraw_events.is_empty(), "diagonal-only batch stays outside cardinal road-topology halo")

func _test_building_transaction_seam() -> void:
    var standalone_world := CountingWorld.new()
    var standalone_mutations := MutationClass.new(standalone_world)
    var standalone_doors := DoorStateClass.new()
    var standalone_door_mutations := DoorMutationClass.new(standalone_doors, standalone_world)
    var validator := BuildingValidatorClass.new()
    var standalone := BuildingMaterializerClass.new(
        standalone_world,
        standalone_mutations,
        standalone_doors,
        standalone_door_mutations,
        validator
    )
    var plan: GeneratedBuildingPlan = _simple_building_plan("perf.building.standalone", Vector2i(0, 0))
    _check(bool(validator.validate(plan).get("ok", false)), "performance fixture building is valid")
    _check(standalone.materialize(plan), "standalone building materialization succeeds")
    _check(standalone_world.snapshot_calls == 1, "standalone building materialization still owns exactly one rollback snapshot")

    var enclosed_world := CountingWorld.new()
    var enclosed_mutations := MutationClass.new(enclosed_world)
    var enclosed_doors := DoorStateClass.new()
    var enclosed_door_mutations := DoorMutationClass.new(enclosed_doors, enclosed_world)
    var enclosed := BuildingMaterializerClass.new(
        enclosed_world,
        enclosed_mutations,
        enclosed_doors,
        enclosed_door_mutations,
        validator
    )
    var enclosed_plan: GeneratedBuildingPlan = _simple_building_plan("perf.building.enclosed", Vector2i(20, 20))
    _check(enclosed.materialize_in_transaction(enclosed_plan), "enclosed building materialization succeeds")
    _check(enclosed_world.snapshot_calls == 0, "enclosed building materialization takes no nested full-world snapshot")
    _check(enclosed_world.has_entity("perf.building.enclosed.door.exterior.primary"), "enclosed building still writes canonical WHAT")

func _test_same_region_streaming_fast_path() -> void:
    var global_plan: GeneratedGlobalWorldPlan = _minimal_global_plan()
    _check(global_plan.is_generated(), "minimal streaming performance global plan satisfies public generated contract")
    var grid: StreamingRegionGrid = GridClass.new(global_plan.bounds, Vector2i(256, 256))
    var provider := CountingProvider.new()
    var materialization := CountingMaterialization.new()
    var streaming: WorldStreamingCoordinator = StreamingClass.new(
        global_plan,
        grid,
        materialization,
        provider,
        0
    )
    _check(streaming.is_ready(), "counting streaming fixture is ready")

    var first_cell: Vector2i = global_plan.bounds.position + Vector2i(10, 10)
    var first: Dictionary = streaming.update_focus(first_cell)
    _check(bool(first.get("ok", false)) and not bool(first.get("fast_path", true)), "first focus uses normal discovery path")
    _check(provider.discovery_calls == 1 and materialization.ensure_calls == 1, "first focus discovers and ensures exactly once")

    var second_cell: Vector2i = first_cell + Vector2i(1, 0)
    var second: Dictionary = streaming.update_focus(second_cell)
    _check(bool(second.get("ok", false)) and bool(second.get("fast_path", false)), "same technical region uses explicit fast path")
    _check(streaming.focus_cell() == second_cell, "same-region fast path still updates precise focus cell")
    _check(provider.discovery_calls == 1 and materialization.ensure_calls == 1, "same-region move performs zero provider discovery/materialization calls")

    var third_cell: Vector2i = global_plan.bounds.position + Vector2i(266, 10)
    var third: Dictionary = streaming.update_focus(third_cell)
    _check(bool(third.get("ok", false)) and not bool(third.get("fast_path", true)), "cross-region move returns to normal path")
    _check(provider.discovery_calls == 2 and materialization.ensure_calls == 2, "cross-region move discovers and ensures once more")

func _simple_building_plan(instance_id: String, origin: Vector2i) -> GeneratedBuildingPlan:
    var plan := GeneratedBuildingPlan.new()
    plan.instance_id = instance_id
    plan.archetype_id = &"perf.test"
    plan.archetype_version = 1
    plan.seed = 1
    plan.footprint_rect = Rect2i(origin, Vector2i(3, 3))
    plan.orientation = Facing.Value.NORTH
    plan.frontage_side = Facing.Value.WEST
    for y in range(origin.y, origin.y + 3):
        for x in range(origin.x, origin.x + 3):
            plan.ground_entries.append({"cell": Vector2i(x, y), "semantic": &"ground.hardwood_h"})
    plan.structures = [{
        "role": "door.exterior.primary",
        "cell": origin + Vector2i(0, 1),
        "semantic": &"door.house",
        "axis": StructureGeometry.Axis.VERTICAL,
        "facing": Facing.Value.WEST,
        "kind": "door",
    }]
    plan.props = []
    var room_cells: Array[Vector2i] = []
    for y in range(origin.y, origin.y + 3):
        for x in range(origin.x, origin.x + 3):
            room_cells.append(Vector2i(x, y))
    plan.rooms = [{"purpose": "test_room", "cells": room_cells}]
    return plan

func _minimal_global_plan() -> GeneratedGlobalWorldPlan:
    var plan := GeneratedGlobalWorldPlan.new()
    plan.world_id = "perf.world"
    plan.seed = 1
    plan.bounds = Rect2i(100, 200, 512, 512)
    plan.profile_id = &"perf.world"
    plan.profile_version = 1
    plan.geography_cells = [{"id": "g"}]
    plan.settlements = [{"id": "s"}]
    plan.road_segments = [{"road_id": "r"}]
    plan.power_nodes = [{"id": "pn"}]
    plan.power_segments = [{"id": "ps"}]
    plan.water_services = [{"id": "ws"}]
    plan.water_nodes = [{"id": "wn"}]
    plan.water_segments = [{"id": "wseg"}]
    plan.wastewater_services = [{"id": "wws"}]
    plan.wastewater_nodes = [{"id": "wwn"}]
    plan.wastewater_segments = [{"id": "wwseg"}]
    return plan

func _on_world_changed(change: WorldChange) -> void:
    observed_changes.append(change)

func _on_redraw_requested(reason: StringName) -> void:
    redraw_events.append(reason)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("PERFORMANCE_RAZOR_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PERFORMANCE_RAZOR_SMOKE_FAIL: %s" % failure)
    quit(1)
