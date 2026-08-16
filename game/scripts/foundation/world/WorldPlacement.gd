extends RefCounted
class_name WorldPlacement

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const StructureGeometry = preload("res://scripts/foundation/spatial/SpatialStructureGeometry.gd")

## Persistent placement value. Geometry comes exclusively from WHERE.

const NO_STRUCTURE_AXIS: int = -1

var entity_id: String = ""
var channel: int = -1
var anchor: Vector2i = Vector2i.ZERO
var facing: int = -1
var footprint: SpatialFootprint = null
var structure_axis: int = NO_STRUCTURE_AXIS

func _init(
    placed_entity_id: String = "",
    placed_channel: int = -1,
    placed_anchor: Vector2i = Vector2i.ZERO,
    placed_facing: int = -1,
    placed_footprint: SpatialFootprint = null,
    placed_structure_axis: int = NO_STRUCTURE_AXIS
) -> void:
    entity_id = placed_entity_id
    channel = placed_channel
    anchor = placed_anchor
    facing = placed_facing
    structure_axis = placed_structure_axis
    if placed_footprint == null:
        footprint = Footprint.single_cell()
    else:
        footprint = Footprint.new(placed_footprint.offsets())

func is_valid() -> bool:
    if not EntityIdRules.is_valid(entity_id):
        return false
    if not Layers.is_valid(channel):
        return false
    if not FacingRules.is_valid(facing):
        return false
    if footprint == null or footprint.cell_count() < 1:
        return false
    if structure_axis == NO_STRUCTURE_AXIS:
        return true
    if channel != Layers.Channel.STRUCTURE:
        return false
    return StructureGeometry.is_valid_axis(structure_axis)

func copy() -> WorldPlacement:
    return WorldPlacement.new(entity_id, channel, anchor, facing, footprint, structure_axis)

func world_cells() -> Array[Vector2i]:
    if footprint == null:
        return []
    return footprint.world_cells(anchor, facing)

func equivalent(other: WorldPlacement) -> bool:
    if other == null:
        return false
    if entity_id != other.entity_id:
        return false
    if channel != other.channel or anchor != other.anchor or facing != other.facing:
        return false
    if structure_axis != other.structure_axis:
        return false
    var own_offsets: Array[Vector2i] = footprint.offsets() if footprint != null else []
    var other_offsets: Array[Vector2i] = other.footprint.offsets() if other.footprint != null else []
    if own_offsets.size() != other_offsets.size():
        return false
    var own_set: Dictionary = {}
    for offset: Vector2i in own_offsets:
        own_set[offset] = true
    for offset: Vector2i in other_offsets:
        if not own_set.has(offset):
            return false
    return true

func to_snapshot() -> Dictionary:
    var serialized_offsets: Array = []
    var offsets: Array[Vector2i] = footprint.offsets() if footprint != null else []
    offsets.sort_custom(_cell_less)
    for offset: Vector2i in offsets:
        serialized_offsets.append([offset.x, offset.y])
    return {
        "entity_id": entity_id,
        "channel": channel,
        "anchor": [anchor.x, anchor.y],
        "facing": facing,
        "footprint": serialized_offsets,
        "structure_axis": structure_axis,
    }

static func from_snapshot(data: Dictionary) -> WorldPlacement:
    var anchor_value: Variant = data.get("anchor", [])
    var footprint_value: Variant = data.get("footprint", [])
    if typeof(anchor_value) != TYPE_ARRAY or anchor_value.size() != 2:
        return null
    if typeof(footprint_value) != TYPE_ARRAY or footprint_value.is_empty():
        return null

    var offsets: Array[Vector2i] = []
    for value: Variant in footprint_value:
        if typeof(value) != TYPE_ARRAY or value.size() != 2:
            return null
        offsets.append(Vector2i(int(value[0]), int(value[1])))

    var placement := WorldPlacement.new(
        String(data.get("entity_id", "")),
        int(data.get("channel", -1)),
        Vector2i(int(anchor_value[0]), int(anchor_value[1])),
        int(data.get("facing", -1)),
        Footprint.new(offsets),
        int(data.get("structure_axis", NO_STRUCTURE_AXIS))
    )
    if not placement.is_valid():
        return null
    return placement

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y
