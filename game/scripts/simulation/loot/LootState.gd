extends RefCounted
class_name LootState

## Persistent System 24 provenance/capability state.
## Current item contents are never stored here; System 11 remains sole contents truth.

signal loot_source_initialized(source_key, revision)
signal loot_state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _revision: int = 0
var _sources: Dictionary = {}
var _containers: Dictionary = {}

func revision() -> int:
    return _revision

func has_source(source_key: String) -> bool:
    return _sources.has(source_key.strip_edges())

func has_container(container_id: String) -> bool:
    return _containers.has(container_id.strip_edges())

func source_record(source_key: String) -> Dictionary:
    var key: String = source_key.strip_edges()
    if not _sources.has(key):
        return {}
    return (_sources[key] as Dictionary).duplicate(true)

func container_record(container_id: String) -> Dictionary:
    var key: String = container_id.strip_edges()
    if not _containers.has(key):
        return {}
    return (_containers[key] as Dictionary).duplicate(true)

func source_keys() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _sources.keys():
        result.append(String(key))
    result.sort()
    return result

func container_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _containers.keys():
        result.append(String(key))
    result.sort()
    return result

func initialize_source(
    source_key: String,
    source_kind: StringName,
    source_id: String,
    plan_signature: String,
    catalog_version: int,
    container_records: Array[Dictionary]
) -> bool:
    var key: String = source_key.strip_edges()
    var sid: String = source_id.strip_edges()
    if key.is_empty() or String(source_kind).is_empty() or sid.is_empty() or plan_signature.is_empty() or catalog_version < 1:
        return false
    if _sources.has(key):
        return false

    var candidate_ids: Dictionary = {}
    var normalized_records: Array[Dictionary] = []
    for record_value: Variant in container_records:
        if typeof(record_value) != TYPE_DICTIONARY:
            return false
        var record: Dictionary = record_value
        var container_id: String = String(record.get("container_id", "")).strip_edges()
        var loot_profile_id: StringName = StringName(record.get("loot_profile_id", &""))
        var loot_profile_version: int = int(record.get("loot_profile_version", 0))
        var building_instance_id: String = String(record.get("building_instance_id", "")).strip_edges()
        if container_id.is_empty() or String(loot_profile_id).is_empty() or loot_profile_version < 1 or building_instance_id.is_empty():
            return false
        if candidate_ids.has(container_id) or _containers.has(container_id):
            return false
        candidate_ids[container_id] = true
        normalized_records.append({
            "container_id": container_id,
            "loot_profile_id": loot_profile_id,
            "loot_profile_version": loot_profile_version,
            "building_instance_id": building_instance_id,
            "source_key": key,
        })

    normalized_records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("container_id", "")) < String(b.get("container_id", ""))
    )
    _revision += 1
    for record: Dictionary in normalized_records:
        var container_id: String = String(record.get("container_id", ""))
        var stored: Dictionary = record.duplicate(true)
        stored["initialized_revision"] = _revision
        _containers[container_id] = stored

    var source_container_ids: Array[String] = []
    for record: Dictionary in normalized_records:
        source_container_ids.append(String(record.get("container_id", "")))
    _sources[key] = {
        "source_key": key,
        "source_kind": source_kind,
        "source_id": sid,
        "plan_signature": plan_signature,
        "catalog_version": catalog_version,
        "container_ids": source_container_ids,
        "initialized_revision": _revision,
    }
    loot_source_initialized.emit(key, _revision)
    return true

func snapshot() -> Dictionary:
    var sources_out: Array[Dictionary] = []
    for key: String in source_keys():
        sources_out.append(source_record(key))
    var containers_out: Array[Dictionary] = []
    for container_id: String in container_ids():
        containers_out.append(container_record(container_id))
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "sources": sources_out,
        "containers": containers_out,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var revision_value: int = int(data.get("revision", -1))
    if revision_value < 0:
        return false
    var sources_value: Variant = data.get("sources", [])
    var containers_value: Variant = data.get("containers", [])
    if typeof(sources_value) != TYPE_ARRAY or typeof(containers_value) != TYPE_ARRAY:
        return false

    var candidate_sources: Dictionary = {}
    var candidate_containers: Dictionary = {}
    for container_value: Variant in containers_value:
        if typeof(container_value) != TYPE_DICTIONARY:
            return false
        var container: Dictionary = container_value
        var container_id: String = String(container.get("container_id", "")).strip_edges()
        var profile_id: String = String(container.get("loot_profile_id", "")).strip_edges()
        var profile_version: int = int(container.get("loot_profile_version", 0))
        var building_id: String = String(container.get("building_instance_id", "")).strip_edges()
        var source_key: String = String(container.get("source_key", "")).strip_edges()
        var initialized_revision: int = int(container.get("initialized_revision", -1))
        if container_id.is_empty() or profile_id.is_empty() or profile_version < 1 \
            or building_id.is_empty() or source_key.is_empty() \
            or initialized_revision < 1 or initialized_revision > revision_value \
            or candidate_containers.has(container_id):
            return false
        candidate_containers[container_id] = container.duplicate(true)

    for source_value: Variant in sources_value:
        if typeof(source_value) != TYPE_DICTIONARY:
            return false
        var source: Dictionary = source_value
        var source_key: String = String(source.get("source_key", "")).strip_edges()
        var source_kind: String = String(source.get("source_kind", "")).strip_edges()
        var source_id: String = String(source.get("source_id", "")).strip_edges()
        var plan_signature: String = String(source.get("plan_signature", "")).strip_edges()
        var catalog_version: int = int(source.get("catalog_version", 0))
        var initialized_revision: int = int(source.get("initialized_revision", -1))
        if source_key.is_empty() or source_kind.is_empty() or source_id.is_empty() \
            or plan_signature.is_empty() or catalog_version < 1 \
            or initialized_revision < 1 or initialized_revision > revision_value \
            or candidate_sources.has(source_key):
            return false
        var ids_value: Variant = source.get("container_ids", [])
        if typeof(ids_value) != TYPE_ARRAY:
            return false
        var seen_ids: Dictionary = {}
        var normalized_ids: Array[String] = []
        for id_value: Variant in ids_value:
            var container_id: String = String(id_value).strip_edges()
            if container_id.is_empty() or seen_ids.has(container_id) or not candidate_containers.has(container_id):
                return false
            var container: Dictionary = candidate_containers[container_id]
            if String(container.get("source_key", "")) != source_key:
                return false
            seen_ids[container_id] = true
            normalized_ids.append(container_id)
        normalized_ids.sort()
        var source_copy: Dictionary = source.duplicate(true)
        source_copy["container_ids"] = normalized_ids
        candidate_sources[source_key] = source_copy

    for container_id: Variant in candidate_containers.keys():
        var record: Dictionary = candidate_containers[container_id]
        if not candidate_sources.has(String(record.get("source_key", ""))):
            return false

    _revision = revision_value
    _sources = candidate_sources
    _containers = candidate_containers
    loot_state_reset.emit()
    return true
