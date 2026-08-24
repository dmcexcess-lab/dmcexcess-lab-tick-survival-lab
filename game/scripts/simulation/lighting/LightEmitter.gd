extends RefCounted
class_name LightEmitter

const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

## Exact active physical light descriptor. Source systems own switch/power/battery truth.

var emitter_id: String = ""
var origin_cell: Vector2i = Vector2i.ZERO
var facing: int = FacingRules.Value.NORTH
var profile: LightEmitterProfile = null
var active: bool = true
var revision: int = 1

func _init(
    id_value: String = "",
    origin_value: Vector2i = Vector2i.ZERO,
    facing_value: int = FacingRules.Value.NORTH,
    profile_value: LightEmitterProfile = null,
    active_value: bool = true,
    revision_value: int = 1
) -> void:
    emitter_id = id_value
    origin_cell = origin_value
    facing = facing_value
    profile = null if profile_value == null else profile_value.copy()
    active = active_value
    revision = revision_value

func is_valid() -> bool:
    return (
        not emitter_id.strip_edges().is_empty()
        and FacingRules.is_valid(facing)
        and profile != null and profile.is_valid()
        and revision >= 0
    )

func copy() -> LightEmitter:
    return LightEmitter.new(emitter_id, origin_cell, facing, profile, active, revision)

func signature() -> String:
    if not is_valid():
        return "invalid"
    return "%s|%d,%d|%d|%s|%d|%d" % [
        emitter_id,
        origin_cell.x,
        origin_cell.y,
        facing,
        String(profile.profile_id),
        1 if active else 0,
        revision,
    ]
