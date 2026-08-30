extends RefCounted
class_name UtilityNetworkConditionStore

## Shared data-only condition substrate for physical utility assets.
## Condition changes only through real damage, repair, or another explicit owner event.
## This store owns no timers, scheduled wear, recurring updates, or spontaneous failures.

const TICKS_PER_DAY: int = 86400
const FAILURE_THRESHOLD: int = 250
const MAX_TICK: int = 9223372036854775807

const DISTRIBUTION_SUPPORT: StringName = &"distribution_support"
const DISTRIBUTION_SPAN: StringName = &"distribution_span"
const VALID_KINDS: Array[StringName] = [DISTRIBUTION_SUPPORT, DISTRIBUTION_SPAN]

var _assets: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func register_asset(
    asset_id: String,
    kind: StringName,
    section_id: String,
    entity_id: String = "",
    generated_at_tick: int = 0
) -> bool:
    var key: String = asset_id.strip_edges()
    if key.is_empty() or not VALID_KINDS.has(kind) or generated_at_tick < 0:
        return false
    if _assets.has(key):
        var existing: Dictionary = _assets[key]
        return StringName(existing.get("kind", &"")) == kind \
            and String(existing.get("section_id", "")) == section_id.strip_edges() \
            and String(existing.get("entity_id", "")) == entity_id.strip_edges()
    var seed: int = _stable_hash("condition:%s" % key)
    var initial_condition: int = 850 + (seed % 151)
    if kind == DISTRIBUTION_SPAN:
        initial_condition = 825 + (seed % 176)
    _assets[key] = {
        "asset_id": key,
        "kind": kind,
        "section_id": section_id.strip_edges(),
        "entity_id": entity_id.strip_edges(),
        "condition_at_event": initial_condition,
        "last_event_tick": generated_at_tick,
        "failure_threshold": FAILURE_THRESHOLD,
        "last_damage_source": &"generated_initial_condition",
    }
    _revision += 1
    return true

func has_asset(asset_id: String) -> bool:
    return _assets.has(asset_id.strip_edges())

func asset_ids(kind: StringName = &"") -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _assets.keys():
        var asset_id: String = String(key)
        var record: Dictionary = _assets[asset_id]
        if String(kind).is_empty() or StringName(record.get("kind", &"")) == kind:
            result.append(asset_id)
    result.sort()
    return result

func asset_record(asset_id: String, world_tick: int = -1) -> Dictionary:
    var key: String = asset_id.strip_edges()
    if not _assets.has(key):
        return {}
    var record: Dictionary = (_assets[key] as Dictionary).duplicate(true)
    if world_tick >= 0:
        record["derived_condition"] = condition_at(key, world_tick)
        record["failed"] = is_failed_at(key, world_tick)
        record["predicted_failure_tick"] = failure_tick(key)
    return record

func condition_at(asset_id: String, world_tick: int) -> int:
    var record: Dictionary = _assets.get(asset_id.strip_edges(), {})
    if record.is_empty() or world_tick < 0:
        return 0
    return clampi(int(record.get("condition_at_event", 0)), 0, 1000)

func is_failed_at(asset_id: String, world_tick: int) -> bool:
    var record: Dictionary = _assets.get(asset_id.strip_edges(), {})
    if record.is_empty() or world_tick < 0:
        return false
    return condition_at(asset_id, world_tick) <= int(record.get("failure_threshold", FAILURE_THRESHOLD))

## Kept as a compatibility/query seam. Healthy assets have no predicted automatic failure.
func failure_tick(asset_id: String) -> int:
    var record: Dictionary = _assets.get(asset_id.strip_edges(), {})
    if record.is_empty():
        return MAX_TICK
    var condition: int = int(record.get("condition_at_event", 0))
    var threshold: int = int(record.get("failure_threshold", FAILURE_THRESHOLD))
    if condition <= threshold:
        return int(record.get("last_event_tick", 0))
    return MAX_TICK

func apply_damage(
    asset_id: String,
    base_damage: int,
    world_tick: int,
    source_kind: StringName = &"direct"
) -> Dictionary:
    var key: String = asset_id.strip_edges()
    if not _assets.has(key) or base_damage <= 0 or world_tick < 0:
        return {"ok": false, "transitioned": false, "failed": false}
    var before_failed: bool = is_failed_at(key, world_tick)
    var record: Dictionary = _assets[key]
    var current: int = condition_at(key, world_tick)
    record["condition_at_event"] = clampi(current - base_damage, 0, 1000)
    record["last_event_tick"] = world_tick
    record["last_damage_source"] = source_kind
    _assets[key] = record
    _revision += 1
    var after_failed: bool = is_failed_at(key, world_tick)
    return {
        "ok": true,
        "transitioned": before_failed != after_failed,
        "failed": after_failed,
        "condition": condition_at(key, world_tick),
        "predicted_failure_tick": failure_tick(key),
    }

func repair_requirements(asset_id: String) -> Dictionary:
    var record: Dictionary = _assets.get(asset_id.strip_edges(), {})
    if record.is_empty():
        return {}
    match StringName(record.get("kind", &"")):
        DISTRIBUTION_SUPPORT:
            return {"electrical_skill": 2, "material_units": 2, "restored_condition": 850}
        DISTRIBUTION_SPAN:
            return {"electrical_skill": 2, "material_units": 1, "restored_condition": 900}
    return {}

func repair_asset(
    asset_id: String,
    electrical_skill: int,
    available_material_units: int,
    world_tick: int
) -> Dictionary:
    var key: String = asset_id.strip_edges()
    var requirements: Dictionary = repair_requirements(key)
    if requirements.is_empty() or not _assets.has(key) or world_tick < 0:
        return {"ok": false, "material_units_consumed": 0, "reason": &"unknown_asset"}
    var required_skill: int = int(requirements.get("electrical_skill", 0))
    var required_materials: int = int(requirements.get("material_units", 0))
    if electrical_skill < required_skill:
        return {"ok": false, "material_units_consumed": 0, "reason": &"insufficient_electrical_skill"}
    if available_material_units < required_materials:
        return {"ok": false, "material_units_consumed": 0, "reason": &"insufficient_materials"}
    var was_failed: bool = is_failed_at(key, world_tick)
    var record: Dictionary = _assets[key]
    record["condition_at_event"] = int(requirements.get("restored_condition", 900))
    record["last_event_tick"] = world_tick
    record["last_damage_source"] = &"repair"
    _assets[key] = record
    _revision += 1
    return {
        "ok": true,
        "material_units_consumed": required_materials,
        "reason": &"repaired",
        "transitioned": was_failed,
        "failed": false,
        "condition": condition_at(key, world_tick),
        "predicted_failure_tick": failure_tick(key),
    }

func snapshot() -> Dictionary:
    var records: Array = []
    for asset_id: String in asset_ids():
        records.append((_assets[asset_id] as Dictionary).duplicate(true))
    return {"schema_version": 2, "revision": _revision, "assets": records}

func restore_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != 2:
        return false
    var values: Variant = data.get("assets", [])
    if typeof(values) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for value: Variant in values:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var record: Dictionary = (value as Dictionary).duplicate(true)
        var asset_id: String = String(record.get("asset_id", "")).strip_edges()
        var kind: StringName = StringName(record.get("kind", &""))
        var condition: int = int(record.get("condition_at_event", -1))
        var last_event_tick: int = int(record.get("last_event_tick", -1))
        if asset_id.is_empty() or not VALID_KINDS.has(kind) or restored.has(asset_id) \
            or condition < 0 or condition > 1000 or last_event_tick < 0:
            return false
        restored[asset_id] = record
    _assets = restored
    _revision = maxi(0, int(data.get("revision", 0)))
    return true

func debug_snapshot(world_tick: int = -1) -> Dictionary:
    var failed_count: int = 0
    if world_tick >= 0:
        for asset_id: String in asset_ids():
            if is_failed_at(asset_id, world_tick):
                failed_count += 1
    return {
        "revision": _revision,
        "asset_count": _assets.size(),
        "support_count": asset_ids(DISTRIBUTION_SUPPORT).size(),
        "span_count": asset_ids(DISTRIBUTION_SPAN).size(),
        "failed_count": failed_count,
    }

static func _stable_hash(value: String) -> int:
    var result: int = 2166136261
    for index: int in range(value.length()):
        result = int((result ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
    return result
