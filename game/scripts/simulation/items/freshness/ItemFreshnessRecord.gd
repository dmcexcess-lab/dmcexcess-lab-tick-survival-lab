extends RefCounted
class_name ItemFreshnessRecord

var item_id: String = ""
var profile_id: StringName = &""
var profile_version: int = 0
var exposure_context_id: StringName = &""
var saved_effective_age_ticks: int = 0
var exposure_anchor_ticks: int = 0
var origin_world_tick: int = 0
var version: int = 0

func _init(
    item_id_value: String = "",
    profile_id_value: StringName = &"",
    profile_version_value: int = 0,
    exposure_context_id_value: StringName = &"",
    saved_effective_age_ticks_value: int = 0,
    exposure_anchor_ticks_value: int = 0,
    origin_world_tick_value: int = 0,
    version_value: int = 0
) -> void:
    item_id = item_id_value.strip_edges()
    profile_id = profile_id_value
    profile_version = profile_version_value
    exposure_context_id = exposure_context_id_value
    saved_effective_age_ticks = saved_effective_age_ticks_value
    exposure_anchor_ticks = exposure_anchor_ticks_value
    origin_world_tick = origin_world_tick_value
    version = version_value

func is_valid() -> bool:
    return not item_id.is_empty() \
        and String(profile_id).begins_with("item.") \
        and profile_version > 0 \
        and not String(exposure_context_id).is_empty() \
        and saved_effective_age_ticks >= 0 \
        and exposure_anchor_ticks >= 0 \
        and origin_world_tick >= 0 \
        and version > 0

func copy() -> ItemFreshnessRecord:
    return ItemFreshnessRecord.new(
        item_id,
        profile_id,
        profile_version,
        exposure_context_id,
        saved_effective_age_ticks,
        exposure_anchor_ticks,
        origin_world_tick,
        version
    )

func to_dictionary() -> Dictionary:
    return {
        "item_id": item_id,
        "profile_id": profile_id,
        "profile_version": profile_version,
        "exposure_context_id": exposure_context_id,
        "saved_effective_age_ticks": saved_effective_age_ticks,
        "exposure_anchor_ticks": exposure_anchor_ticks,
        "origin_world_tick": origin_world_tick,
        "version": version,
    }

static func from_dictionary(data: Dictionary) -> ItemFreshnessRecord:
    var record := ItemFreshnessRecord.new(
        String(data.get("item_id", "")),
        StringName(data.get("profile_id", &"")),
        int(data.get("profile_version", 0)),
        StringName(data.get("exposure_context_id", &"")),
        int(data.get("saved_effective_age_ticks", -1)),
        int(data.get("exposure_anchor_ticks", -1)),
        int(data.get("origin_world_tick", -1)),
        int(data.get("version", 0))
    )
    return record if record.is_valid() else null
