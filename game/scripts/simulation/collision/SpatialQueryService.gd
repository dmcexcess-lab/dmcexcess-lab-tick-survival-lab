extends RefCounted
class_name SpatialQueryService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const ResultClass = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")

## Read-only WHERE + WHAT + collision query facade.
## This service decides hard entity occupancy collision only; it never moves anything.

var _world: WorldState = null
var _catalog: CollisionCatalog = null
var _overrides: CollisionOverrideState = null

func _init(
    world_state: WorldState = null,
    collision_catalog: CollisionCatalog = null,
    collision_overrides: CollisionOverrideState = null
) -> void:
    _world = world_state
    _catalog = collision_catalog
    _overrides = collision_overrides

func is_ready() -> bool:
    return _world != null and _catalog != null and _overrides != null

func has_terrain(cell: Vector2i) -> bool:
    return _world != null and _world.has_terrain(cell)

func terrain_at(cell: Vector2i) -> StringName:
    if _world == null:
        return &""
    return _world.terrain_at(cell)

func entities_at(cell: Vector2i, channel: int = -1) -> Array[String]:
    if _world == null:
        var empty: Array[String] = []
        return empty
    return _world.entities_at(cell, channel)

func placements_at(cell: Vector2i, channel: int = -1) -> Array[WorldPlacement]:
    var result: Array[WorldPlacement] = []
    if _world == null:
        return result
    for entity_id: String in _world.entities_at(cell, channel):
        var placement: WorldPlacement = _world.placement(entity_id)
        if placement != null:
            result.append(placement)
    return result

func query_cell(
    cell: Vector2i,
    ignore_entity_id: String = "",
    require_terrain: bool = true
) -> SpatialQueryResult:
    var cells: Array[Vector2i] = [cell]
    return query_cells(cells, ignore_entity_id, require_terrain)

func query_cells(
    target_cells: Array,
    ignore_entity_id: String = "",
    require_terrain: bool = true
) -> SpatialQueryResult:
    var result := ResultClass.new()
    result.cells = _canonical_cells(target_cells)
    if not is_ready() or result.cells.is_empty():
        return result

    var blockers: Dictionary = {}
    var unclassified: Dictionary = {}
    var missing_terrain: Dictionary = {}

    for cell: Vector2i in result.cells:
        if require_terrain and not _world.has_terrain(cell):
            missing_terrain[cell] = true

        for entity_id: String in _world.entities_at(cell):
            if not ignore_entity_id.is_empty() and entity_id == ignore_entity_id:
                continue

            var placement: WorldPlacement = _world.placement(entity_id)
            if placement == null:
                unclassified[entity_id] = true
                continue

            if _overrides.has_override(entity_id):
                if _overrides.blocks_movement(entity_id):
                    blockers[entity_id] = true
                continue

            var record: WorldEntityRecord = _world.entity(entity_id)
            if record == null:
                unclassified[entity_id] = true
                continue

            var profile: CollisionProfile = _catalog.profile_for(record.semantic_type)
            if profile != null:
                if profile.blocks_movement:
                    blockers[entity_id] = true
                continue

            if _requires_profile(placement.channel):
                unclassified[entity_id] = true

    result.blocking_entity_ids = _sorted_string_keys(blockers)
    result.unclassified_entity_ids = _sorted_string_keys(unclassified)
    result.missing_terrain_cells = _sorted_cell_keys(missing_terrain)

    if not result.missing_terrain_cells.is_empty() or not result.unclassified_entity_ids.is_empty():
        result.status = ResultClass.Status.UNKNOWN
    elif not result.blocking_entity_ids.is_empty():
        result.status = ResultClass.Status.BLOCKED
    else:
        result.status = ResultClass.Status.CLEAR
    return result

func query_footprint(
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint,
    ignore_entity_id: String = "",
    require_terrain: bool = true
) -> SpatialQueryResult:
    if footprint == null or footprint.cell_count() < 1 or not FacingRules.is_valid(facing):
        return ResultClass.new()
    return query_cells(footprint.world_cells(anchor, facing), ignore_entity_id, require_terrain)

func query_entity_footprint(
    entity_id: String,
    target_anchor: Vector2i,
    target_facing: int = -1,
    require_terrain: bool = true
) -> SpatialQueryResult:
    if _world == null or not _world.has_entity(entity_id):
        return ResultClass.new()
    var current: WorldPlacement = _world.placement(entity_id)
    if current == null or current.footprint == null:
        return ResultClass.new()

    var resolved_facing: int = target_facing
    if resolved_facing < 0:
        resolved_facing = current.facing
    if not FacingRules.is_valid(resolved_facing):
        return ResultClass.new()

    return query_footprint(
        target_anchor,
        resolved_facing,
        current.footprint,
        entity_id,
        require_terrain
    )

func collision_coverage_report() -> Dictionary:
    var missing_required_profiles: Array[String] = []
    var orphan_overrides: Array[String] = []
    if not is_ready():
        return {
            "missing_required_profiles": missing_required_profiles,
            "orphan_overrides": orphan_overrides,
        }

    for entity_id: String in _world.entity_ids():
        if not _world.has_placement(entity_id):
            continue
        var placement: WorldPlacement = _world.placement(entity_id)
        if placement == null or not _requires_profile(placement.channel):
            continue
        if _overrides.has_override(entity_id):
            continue
        var record: WorldEntityRecord = _world.entity(entity_id)
        if record == null or not _catalog.has_profile(record.semantic_type):
            missing_required_profiles.append(entity_id)

    for entity_id: String in _overrides.entity_ids():
        if not _world.has_entity(entity_id):
            orphan_overrides.append(entity_id)

    missing_required_profiles.sort()
    orphan_overrides.sort()
    return {
        "missing_required_profiles": missing_required_profiles,
        "orphan_overrides": orphan_overrides,
    }

static func _requires_profile(channel: int) -> bool:
    return channel == Layers.Channel.STRUCTURE \
        or channel == Layers.Channel.OBJECT \
        or channel == Layers.Channel.ACTOR

static func _canonical_cells(values: Array) -> Array[Vector2i]:
    var seen: Dictionary = {}
    for value: Variant in values:
        if typeof(value) == TYPE_VECTOR2I:
            seen[value] = true
    return _sorted_cell_keys(seen)

static func _sorted_string_keys(values: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for value: Variant in values.keys():
        result.append(String(value))
    result.sort()
    return result

static func _sorted_cell_keys(values: Dictionary) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for value: Variant in values.keys():
        if typeof(value) == TYPE_VECTOR2I:
            result.append(value)
    result.sort_custom(_cell_less)
    return result

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
