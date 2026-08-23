extends RefCounted
class_name MaterializationRecord

var source_key: String = ""
var source_kind: StringName = &""
var source_id: String = ""
var bounds: Rect2i = Rect2i()
var source_seed: int = 0
var area_profile_id: StringName = &""
var area_profile_version: int = 0
var environment_profile_id: StringName = &""
var environment_profile_version: int = 0
var plan_signature: String = ""
var world_revision_after: int = 0
var door_revision_after: int = 0

func _init(
    p_source_key: String = "",
    p_source_kind: StringName = &"",
    p_source_id: String = "",
    p_bounds: Rect2i = Rect2i(),
    p_source_seed: int = 0,
    p_area_profile_id: StringName = &"",
    p_area_profile_version: int = 0,
    p_environment_profile_id: StringName = &"",
    p_environment_profile_version: int = 0,
    p_plan_signature: String = "",
    p_world_revision_after: int = 0,
    p_door_revision_after: int = 0
) -> void:
    source_key = p_source_key.strip_edges()
    source_kind = p_source_kind
    source_id = p_source_id.strip_edges()
    bounds = p_bounds
    source_seed = p_source_seed
    area_profile_id = p_area_profile_id
    area_profile_version = p_area_profile_version
    environment_profile_id = p_environment_profile_id
    environment_profile_version = p_environment_profile_version
    plan_signature = p_plan_signature
    world_revision_after = p_world_revision_after
    door_revision_after = p_door_revision_after

func is_valid() -> bool:
    return not source_key.is_empty() \
        and source_key == source_key.strip_edges() \
        and not String(source_kind).strip_edges().is_empty() \
        and not source_id.is_empty() \
        and source_id == source_id.strip_edges() \
        and bounds.size.x > 0 and bounds.size.y > 0 \
        and not String(area_profile_id).strip_edges().is_empty() \
        and area_profile_version > 0 \
        and not String(environment_profile_id).strip_edges().is_empty() \
        and environment_profile_version > 0 \
        and not plan_signature.is_empty() \
        and world_revision_after >= 0 \
        and door_revision_after >= 0

func copy() -> MaterializationRecord:
    return MaterializationRecord.new(
        source_key,
        source_kind,
        source_id,
        bounds,
        source_seed,
        area_profile_id,
        area_profile_version,
        environment_profile_id,
        environment_profile_version,
        plan_signature,
        world_revision_after,
        door_revision_after
    )

func equivalent(other: MaterializationRecord) -> bool:
    if other == null:
        return false
    return source_key == other.source_key \
        and source_kind == other.source_kind \
        and source_id == other.source_id \
        and bounds == other.bounds \
        and source_seed == other.source_seed \
        and area_profile_id == other.area_profile_id \
        and area_profile_version == other.area_profile_version \
        and environment_profile_id == other.environment_profile_id \
        and environment_profile_version == other.environment_profile_version \
        and plan_signature == other.plan_signature \
        and world_revision_after == other.world_revision_after \
        and door_revision_after == other.door_revision_after

func to_snapshot() -> Dictionary:
    return {
        "source_key": source_key,
        "source_kind": String(source_kind),
        "source_id": source_id,
        "bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
        "source_seed": source_seed,
        "area_profile_id": String(area_profile_id),
        "area_profile_version": area_profile_version,
        "environment_profile_id": String(environment_profile_id),
        "environment_profile_version": environment_profile_version,
        "plan_signature": plan_signature,
        "world_revision_after": world_revision_after,
        "door_revision_after": door_revision_after,
    }

static func from_snapshot(data: Dictionary) -> MaterializationRecord:
    var bounds_value: Variant = data.get("bounds", [])
    if typeof(bounds_value) != TYPE_ARRAY:
        return null
    var encoded: Array = bounds_value
    if encoded.size() != 4:
        return null
    var record := MaterializationRecord.new(
        String(data.get("source_key", "")),
        StringName(String(data.get("source_kind", ""))),
        String(data.get("source_id", "")),
        Rect2i(int(encoded[0]), int(encoded[1]), int(encoded[2]), int(encoded[3])),
        int(data.get("source_seed", 0)),
        StringName(String(data.get("area_profile_id", ""))),
        int(data.get("area_profile_version", 0)),
        StringName(String(data.get("environment_profile_id", ""))),
        int(data.get("environment_profile_version", 0)),
        String(data.get("plan_signature", "")),
        int(data.get("world_revision_after", -1)),
        int(data.get("door_revision_after", -1))
    )
    return record if record.is_valid() else null
