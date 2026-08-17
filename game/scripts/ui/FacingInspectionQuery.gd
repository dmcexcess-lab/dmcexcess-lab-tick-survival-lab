extends RefCounted
class_name FacingInspectionQuery

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Read-only one-cell-ahead physical inspection for the canonical HUD.
## This deliberately does not claim perception/visibility knowledge.

var _world: WorldState = null

func _init(world_state: WorldState = null) -> void:
    _world = world_state

func is_ready() -> bool:
    return _world != null

func query(actor_id: String) -> Dictionary:
    if _world == null:
        return _result(false, "inspection_unconfigured", Vector2i.ZERO, -1, Vector2i.ZERO, &"", "", "Unknown")
    if not _world.has_entity(actor_id):
        return _result(false, "actor_missing", Vector2i.ZERO, -1, Vector2i.ZERO, &"", "", "Unknown")
    if not _world.has_placement(actor_id):
        return _result(false, "actor_unplaced", Vector2i.ZERO, -1, Vector2i.ZERO, &"", "", "Unknown")

    var placement: WorldPlacement = _world.placement(actor_id)
    if placement == null or placement.channel != Layers.Channel.ACTOR:
        return _result(false, "actor_placement_invalid", Vector2i.ZERO, -1, Vector2i.ZERO, &"", "", "Unknown")
    if not Facing.is_valid(placement.facing):
        return _result(false, "actor_facing_invalid", placement.anchor, placement.facing, placement.anchor, &"", "", "Unknown")

    var target_cell: Vector2i = placement.anchor + Facing.vector(placement.facing)
    for channel: int in [
        Layers.Channel.STRUCTURE,
        Layers.Channel.OBJECT,
        Layers.Channel.ACTOR,
        Layers.Channel.LOOSE_ITEM,
    ]:
        var entity_ids: Array[String] = _world.entities_at(target_cell, channel)
        entity_ids.sort()
        for entity_id: String in entity_ids:
            if entity_id == actor_id:
                continue
            var entity: WorldEntityRecord = _world.entity(entity_id)
            if entity == null:
                continue
            return _result(
                true,
                "",
                placement.anchor,
                placement.facing,
                target_cell,
                entity.semantic_type,
                entity_id,
                semantic_label(entity.semantic_type)
            )

    if _world.has_terrain(target_cell):
        var terrain: StringName = _world.terrain_at(target_cell)
        return _result(
            true,
            "",
            placement.anchor,
            placement.facing,
            target_cell,
            terrain,
            "",
            semantic_label(terrain)
        )

    return _result(
        true,
        "",
        placement.anchor,
        placement.facing,
        target_cell,
        &"",
        "",
        "Unknown"
    )

static func semantic_label(semantic_type: StringName) -> String:
    var semantic: String = String(semantic_type).strip_edges()
    if semantic.is_empty():
        return "Unknown"
    var separator: int = semantic.find(".")
    if separator < 0:
        return _humanize(semantic)

    var family: String = semantic.substr(0, separator)
    var detail: String = semantic.substr(separator + 1)
    var detail_label: String = _humanize(detail)
    match family:
        "wall":
            return "%s Wall" % detail_label
        "door":
            return "%s Door" % detail_label
        "window":
            return "%s Window" % detail_label
        "ground":
            return detail_label
        "prop", "fixture", "vegetation", "item", "actor":
            return detail_label
        _:
            return _humanize(semantic)

static func facing_label(facing: int) -> String:
    if not Facing.is_valid(facing):
        return "UNKNOWN"
    return Facing.label(facing).to_upper()

static func _humanize(value: String) -> String:
    return value.replace("_", " ").replace(".", " ").capitalize()

static func _result(
    ok: bool,
    reason: String,
    actor_anchor: Vector2i,
    facing: int,
    target_cell: Vector2i,
    semantic_type: StringName,
    entity_id: String,
    label: String
) -> Dictionary:
    return {
        "ok": ok,
        "reason": reason,
        "actor_anchor": actor_anchor,
        "facing": facing,
        "facing_label": facing_label(facing),
        "target_cell": target_cell,
        "semantic_type": semantic_type,
        "entity_id": entity_id,
        "label": label,
    }
