extends RefCounted
class_name DurableSessionStore

const FORMAT_SCHEMA_VERSION: int = 1
const SESSION_SCHEMA_VERSION: int = 1
const DEFAULT_PRIMARY_PATH: String = "user://tick_lab_session.save"
const DEFAULT_BACKUP_PATH: String = "user://tick_lab_session.backup.save"
const DEFAULT_TEMP_PATH: String = "user://tick_lab_session.tmp.save"

const REQUIRED_OWNER_KEYS: Array[String] = [
    "world",
    "materialization_registry",
    "kernel",
    "collision_overrides",
    "doors",
    "locomotion",
    "hands",
    "inventory",
    "health",
    "skills",
    "freshness",
    "carry",
    "loot",
    "perception_memory",
    "forage",
    "conditions",
    "utilities",
    "power_network",
    "flashlight",
    "portable_generators",
    "vehicles",
    "world_interactions",
    "firearms",
    "corpses",
    "infected",
    "combat_runtime",
    "weather",
]

var _primary_path: String
var _backup_path: String
var _temp_path: String

func _init(
    primary_path: String = DEFAULT_PRIMARY_PATH,
    backup_path: String = DEFAULT_BACKUP_PATH,
    temp_path: String = DEFAULT_TEMP_PATH
) -> void:
    _primary_path = primary_path
    _backup_path = backup_path
    _temp_path = temp_path

func validate_session(session: Dictionary) -> Dictionary:
    if int(session.get("schema_version", -1)) != SESSION_SCHEMA_VERSION:
        return {"ok": false, "reason": "incompatible_session_version"}
    if int(session.get("world_seed", 0)) <= 0:
        return {"ok": false, "reason": "invalid_world_seed"}
    var owners_value: Variant = session.get("owners", {})
    if typeof(owners_value) != TYPE_DICTIONARY:
        return {"ok": false, "reason": "invalid_owner_payload"}
    var owners: Dictionary = owners_value
    for key: String in REQUIRED_OWNER_KEYS:
        if not owners.has(key) or typeof(owners[key]) != TYPE_DICTIONARY:
            return {"ok": false, "reason": "missing_owner:%s" % key}
    return {"ok": true, "reason": ""}

func has_compatible_save() -> bool:
    return bool(load_best().get("ok", false))

func load_best() -> Dictionary:
    var primary: Dictionary = _read_session_file(_primary_path)
    if bool(primary.get("ok", false)):
        primary["source"] = "primary"
        return primary
    var backup: Dictionary = _read_session_file(_backup_path)
    if bool(backup.get("ok", false)):
        backup["source"] = "backup"
        backup["primary_failure"] = String(primary.get("reason", "invalid_primary"))
        return backup
    var no_files: bool = not FileAccess.file_exists(_primary_path) and not FileAccess.file_exists(_backup_path)
    return {
        "ok": false,
        "session": {},
        "source": "",
        "reason": "no_save" if no_files else "no_valid_save",
        "primary_failure": String(primary.get("reason", "")),
        "backup_failure": String(backup.get("reason", "")),
    }

func storage_status() -> Dictionary:
    var probe_path: String = _temp_path + ".probe"
    _remove_file(probe_path)
    var writable: bool = _write_variant(probe_path, {"probe": FORMAT_SCHEMA_VERSION})
    if writable:
        var probe := FileAccess.open(probe_path, FileAccess.READ)
        writable = probe != null and typeof(probe.get_var(false)) == TYPE_DICTIONARY
        if probe != null:
            probe.close()
    _remove_file(probe_path)
    return {
        "writable": writable,
        "persistent": OS.is_userfs_persistent(),
    }

func save(session: Dictionary) -> Dictionary:
    var validation: Dictionary = validate_session(session)
    if not bool(validation.get("ok", false)):
        return {"ok": false, "reason": String(validation.get("reason", "invalid_session")), "persistent": OS.is_userfs_persistent()}

    _remove_file(_temp_path)
    if not _write_session_file(_temp_path, session):
        return {"ok": false, "reason": "temp_write_failed", "persistent": OS.is_userfs_persistent()}
    var temp_check: Dictionary = _read_session_file(_temp_path)
    if not bool(temp_check.get("ok", false)):
        _remove_file(_temp_path)
        return {"ok": false, "reason": "temp_verification_failed", "persistent": OS.is_userfs_persistent()}

    var old_primary: Dictionary = _read_session_file(_primary_path)
    if bool(old_primary.get("ok", false)):
        if not _copy_file(_primary_path, _backup_path):
            _remove_file(_temp_path)
            return {"ok": false, "reason": "backup_write_failed", "persistent": OS.is_userfs_persistent()}
        if not bool(_read_session_file(_backup_path).get("ok", false)):
            _remove_file(_temp_path)
            return {"ok": false, "reason": "backup_verification_failed", "persistent": OS.is_userfs_persistent()}

    if not _copy_file(_temp_path, _primary_path):
        _remove_file(_temp_path)
        return {"ok": false, "reason": "primary_write_failed", "persistent": OS.is_userfs_persistent()}
    var primary_check: Dictionary = _read_session_file(_primary_path)
    if not bool(primary_check.get("ok", false)):
        var backup_check: Dictionary = _read_session_file(_backup_path)
        if bool(backup_check.get("ok", false)):
            _copy_file(_backup_path, _primary_path)
        _remove_file(_temp_path)
        return {"ok": false, "reason": "primary_verification_failed", "persistent": OS.is_userfs_persistent()}

    _remove_file(_temp_path)
    return {
        "ok": true,
        "reason": "",
        "persistent": OS.is_userfs_persistent(),
        "path": _primary_path,
    }

func _write_session_file(path: String, session: Dictionary) -> bool:
    var payload: PackedByteArray = var_to_bytes(session, false)
    if payload.is_empty():
        return false
    var envelope := {
        "format_schema_version": FORMAT_SCHEMA_VERSION,
        "payload_sha256": _sha256(payload),
        "payload": payload,
    }
    return _write_variant(path, envelope)

func _read_session_file(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {"ok": false, "session": {}, "reason": "missing"}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {"ok": false, "session": {}, "reason": "open_failed"}
    var envelope: Variant = file.get_var(false)
    file.close()
    if typeof(envelope) != TYPE_DICTIONARY:
        return {"ok": false, "session": {}, "reason": "invalid_envelope"}
    var data: Dictionary = envelope
    if int(data.get("format_schema_version", -1)) != FORMAT_SCHEMA_VERSION:
        return {"ok": false, "session": {}, "reason": "incompatible_format_version"}
    var payload_value: Variant = data.get("payload", PackedByteArray())
    if typeof(payload_value) != TYPE_PACKED_BYTE_ARRAY:
        return {"ok": false, "session": {}, "reason": "invalid_payload_bytes"}
    var payload: PackedByteArray = payload_value
    if payload.is_empty() or String(data.get("payload_sha256", "")) != _sha256(payload):
        return {"ok": false, "session": {}, "reason": "checksum_failed"}
    var decoded: Variant = bytes_to_var(payload, false)
    if typeof(decoded) != TYPE_DICTIONARY:
        return {"ok": false, "session": {}, "reason": "invalid_session_payload"}
    var session: Dictionary = decoded
    var validation: Dictionary = validate_session(session)
    if not bool(validation.get("ok", false)):
        return {"ok": false, "session": {}, "reason": String(validation.get("reason", "invalid_session"))}
    return {"ok": true, "session": session.duplicate(true), "reason": ""}

func _write_variant(path: String, value: Variant) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_var(value, false)
    var error: Error = file.get_error()
    file.close()
    return error == OK

func _copy_file(source: String, destination: String) -> bool:
    var source_file := FileAccess.open(source, FileAccess.READ)
    if source_file == null:
        return false
    var length: int = source_file.get_length()
    if length <= 0:
        source_file.close()
        return false
    var bytes: PackedByteArray = source_file.get_buffer(length)
    source_file.close()
    if bytes.size() != length:
        return false
    var destination_file := FileAccess.open(destination, FileAccess.WRITE)
    if destination_file == null:
        return false
    destination_file.store_buffer(bytes)
    var error: Error = destination_file.get_error()
    destination_file.close()
    return error == OK

func _remove_file(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func _sha256(bytes: PackedByteArray) -> String:
    var context := HashingContext.new()
    if context.start(HashingContext.HASH_SHA256) != OK:
        return ""
    if context.update(bytes) != OK:
        return ""
    return context.finish().hex_encode()
