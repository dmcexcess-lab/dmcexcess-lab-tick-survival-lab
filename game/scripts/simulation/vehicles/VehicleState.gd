extends RefCounted
class_name VehicleState

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _records: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_vehicle(vehicle_id: String) -> bool:
    return _records.has(vehicle_id)

func vehicle_ids() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _records.keys():
        result.append(String(value))
    result.sort()
    return result

func record(vehicle_id: String) -> Dictionary:
    return Dictionary(_records.get(vehicle_id, {})).duplicate(true)

func create_vehicle(vehicle_id: String, kind: StringName, fuel: int, locked: bool, heading: int = 0) -> bool:
    var key := vehicle_id.strip_edges()
    if key.is_empty() or _records.has(key) or String(kind).is_empty():
        return false
    _records[key] = {
        "kind": kind,
        "heading": posmod(heading, 12),
        "moving": false,
        "driver_id": "",
        "fuel": maxi(0, fuel),
        "locked": locked,
        "powered": false,
        "hotwired": false,
        "body": 100,
        "propulsion": 100,
        "wheels": 100,
        "electrical": 100,
        "cargo_container_id": "%s:cargo" % key,
        "mods": [],
        "version": 1,
    }
    _revision += 1
    return true

func mutate(vehicle_id: String, patch: Dictionary) -> bool:
    if not _records.has(vehicle_id):
        return false
    var current: Dictionary = Dictionary(_records[vehicle_id]).duplicate(true)
    for field: Variant in patch.keys():
        current[field] = patch[field]
    current["heading"] = posmod(int(current.get("heading", 0)), 12)
    for field_name: String in ["body", "propulsion", "wheels", "electrical"]:
        current[field_name] = clampi(int(current.get(field_name, 100)), 0, 100)
    current["fuel"] = maxi(0, int(current.get("fuel", 0)))
    current["version"] = int(current.get("version", 0)) + 1
    _records[vehicle_id] = current
    _revision += 1
    return true

func set_driver(vehicle_id: String, actor_id: String) -> bool:
    return mutate(vehicle_id, {"driver_id": actor_id.strip_edges()})

func clear_driver(vehicle_id: String) -> bool:
    return mutate(vehicle_id, {"driver_id": "", "moving": false})

func vehicle_for_driver(actor_id: String) -> String:
    var actor := actor_id.strip_edges()
    if actor.is_empty():
        return ""
    for vehicle_id: String in vehicle_ids():
        if String(_records[vehicle_id].get("driver_id", "")) == actor:
            return vehicle_id
    return ""

func snapshot() -> Dictionary:
    var rows: Array[Dictionary] = []
    for vehicle_id: String in vehicle_ids():
        var row: Dictionary = record(vehicle_id)
        row["vehicle_id"] = vehicle_id
        row["kind"] = String(row.get("kind", &""))
        rows.append(row)
    return {"schema_version": SNAPSHOT_SCHEMA_VERSION, "records": rows}

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var rows: Variant = data.get("records", [])
    if typeof(rows) != TYPE_ARRAY:
        return false
    var next: Dictionary = {}
    for raw: Variant in rows:
        if typeof(raw) != TYPE_DICTIONARY:
            return false
        var row: Dictionary = Dictionary(raw).duplicate(true)
        var vehicle_id := String(row.get("vehicle_id", "")).strip_edges()
        var kind := StringName(String(row.get("kind", "")))
        if vehicle_id.is_empty() or String(kind).is_empty() or next.has(vehicle_id):
            return false
        row.erase("vehicle_id")
        row["kind"] = kind
        next[vehicle_id] = row
    _records = next
    _revision += 1
    return true
