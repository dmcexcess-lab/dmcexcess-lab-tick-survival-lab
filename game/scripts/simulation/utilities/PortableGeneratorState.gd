extends RefCounted
class_name PortableGeneratorState

## Persistent System-33 state for real portable-generator WHAT entities. Fuel is
## stored as remaining service ticks and is settled only when WHEN advances.

signal generator_changed(generator_id, version, reason)
signal state_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1
const SEMANTIC: StringName = &"prop.portable_generator"
const MAX_FUEL_TICKS: int = 240
const MAX_CONDITION: int = 100
const MIN_START_CONDITION: int = 40

var _records: Dictionary = {}
var _active_scopes: Dictionary = {}
var _running_ids: Dictionary = {}
var _revision: int = 0

func enroll(generator_id: String, power_service_id: String, power_scope_id: String, world_tick: int = 0) -> bool:
    var key: String = generator_id.strip_edges()
    var service: String = power_service_id.strip_edges()
    var scope: String = power_scope_id.strip_edges()
    if key.is_empty() or service.is_empty() or scope.is_empty() or world_tick < 0:
        return false
    if _records.has(key):
        var existing: Dictionary = _records[key]
        return String(existing.get("power_service_id", "")) == service \
            and String(existing.get("power_scope_id", "")) == scope
    _records[key] = {
        "generator_id": key,
        "power_service_id": service,
        "power_scope_id": scope,
        "fuel_ticks": 0,
        "condition": MAX_CONDITION,
        "running": false,
        "last_world_tick": world_tick,
        "version": 1,
    }
    _revision += 1
    _rebuild_active_scopes()
    generator_changed.emit(key, 1, &"generator_enrolled")
    return true

func has_generator(generator_id: String) -> bool:
    return _records.has(generator_id.strip_edges())

func generator_ids() -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _records.keys():
        result.append(String(value))
    result.sort()
    return result

func record(generator_id: String) -> Dictionary:
    var key: String = generator_id.strip_edges()
    return (_records[key] as Dictionary).duplicate(true) if _records.has(key) else {}

func local_power_available(power_service_id: String, power_scope_id: String) -> bool:
    return _active_scopes.has(_scope_key(power_service_id, power_scope_id))

func can_start(generator_id: String) -> bool:
    var value: Dictionary = _records.get(generator_id.strip_edges(), {})
    return not value.is_empty() and not bool(value.get("running", false)) \
        and int(value.get("fuel_ticks", 0)) > 0 \
        and int(value.get("condition", 0)) >= MIN_START_CONDITION

func can_refuel(generator_id: String) -> bool:
    var value: Dictionary = _records.get(generator_id.strip_edges(), {})
    return not value.is_empty() and not bool(value.get("running", false)) \
        and int(value.get("fuel_ticks", 0)) < MAX_FUEL_TICKS

func can_repair(generator_id: String) -> bool:
    var value: Dictionary = _records.get(generator_id.strip_edges(), {})
    return not value.is_empty() and not bool(value.get("running", false)) \
        and int(value.get("condition", 0)) < MAX_CONDITION

func refuel(generator_id: String, world_tick: int) -> bool:
    if not can_refuel(generator_id) or world_tick < 0:
        return false
    return _patch(generator_id, {
        "fuel_ticks": MAX_FUEL_TICKS,
        "last_world_tick": world_tick,
    }, &"generator_refueled")

func start(generator_id: String, world_tick: int) -> bool:
    if not can_start(generator_id) or world_tick < 0:
        return false
    return _patch(generator_id, {"running": true, "last_world_tick": world_tick}, &"generator_started")

func stop(generator_id: String, world_tick: int) -> bool:
    var value: Dictionary = _records.get(generator_id.strip_edges(), {})
    if value.is_empty() or not bool(value.get("running", false)) or world_tick < 0:
        return false
    if not advance_to_tick(world_tick):
        return false
    return _patch(generator_id, {"running": false, "last_world_tick": world_tick}, &"generator_stopped")

func damage(generator_id: String, amount: int, world_tick: int) -> bool:
    var key: String = generator_id.strip_edges()
    if not _records.has(key) or amount <= 0 or world_tick < 0:
        return false
    if not advance_to_tick(world_tick):
        return false
    var value: Dictionary = _records[key]
    var condition: int = maxi(0, int(value.get("condition", 0)) - amount)
    return _patch(key, {
        "condition": condition,
        "running": bool(value.get("running", false)) and condition >= MIN_START_CONDITION,
        "last_world_tick": world_tick,
    }, &"generator_damaged")

func repair(generator_id: String, world_tick: int) -> bool:
    if not can_repair(generator_id) or world_tick < 0:
        return false
    return _patch(generator_id, {
        "condition": MAX_CONDITION,
        "last_world_tick": world_tick,
    }, &"generator_repaired")

## One bounded pass per WHEN advance. There are no scheduled events, Nodes, timers,
## process callbacks, or work proportional to unrelated world entities.
func advance_to_tick(world_tick: int) -> bool:
    if world_tick < 0:
        return false
    var changed: Array[String] = []
    var running_ids: Array[String] = []
    for value: Variant in _running_ids.keys():
        running_ids.append(String(value))
    running_ids.sort()
    for generator_id: String in running_ids:
        var value: Dictionary = _records[generator_id]
        var previous_tick: int = int(value.get("last_world_tick", 0))
        if world_tick < previous_tick:
            return false
        var elapsed: int = world_tick - previous_tick
        if elapsed <= 0:
            continue
        var fuel: int = maxi(0, int(value.get("fuel_ticks", 0)) - elapsed)
        value["fuel_ticks"] = fuel
        value["running"] = fuel > 0 and int(value.get("condition", 0)) >= MIN_START_CONDITION
        value["last_world_tick"] = world_tick
        value["version"] = int(value.get("version", 0)) + 1
        _records[generator_id] = value
        changed.append(generator_id)
    if changed.is_empty():
        return true
    _revision += 1
    _rebuild_active_scopes()
    for generator_id: String in changed:
        var value: Dictionary = _records[generator_id]
        generator_changed.emit(
            generator_id,
            int(value.get("version", 0)),
            &"generator_fuel_depleted" if not bool(value.get("running", false)) else &"generator_fuel_consumed"
        )
    return true

func snapshot() -> Dictionary:
    var records: Array = []
    for generator_id: String in generator_ids():
        records.append(record(generator_id))
    return {"schema_version": SNAPSHOT_SCHEMA_VERSION, "revision": _revision, "records": records}

func restore_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION \
        or typeof(data.get("records", [])) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for value: Variant in data.get("records", []):
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var item: Dictionary = (value as Dictionary).duplicate(true)
        var generator_id: String = String(item.get("generator_id", "")).strip_edges()
        var service: String = String(item.get("power_service_id", "")).strip_edges()
        var scope: String = String(item.get("power_scope_id", "")).strip_edges()
        var fuel: int = int(item.get("fuel_ticks", -1))
        var condition: int = int(item.get("condition", -1))
        var last_tick: int = int(item.get("last_world_tick", -1))
        if generator_id.is_empty() or service.is_empty() or scope.is_empty() or restored.has(generator_id) \
            or fuel < 0 or fuel > MAX_FUEL_TICKS or condition < 0 or condition > MAX_CONDITION \
            or last_tick < 0 or int(item.get("version", 0)) < 1 \
            or (bool(item.get("running", false)) and (fuel <= 0 or condition < MIN_START_CONDITION)):
            return false
        restored[generator_id] = item
    _records = restored
    _revision = maxi(0, int(data.get("revision", 0)))
    _rebuild_active_scopes()
    state_reset.emit()
    return true

func _patch(generator_id: String, patch: Dictionary, reason: StringName) -> bool:
    var key: String = generator_id.strip_edges()
    if not _records.has(key):
        return false
    var value: Dictionary = _records[key]
    for field: Variant in patch.keys():
        value[field] = patch[field]
    value["version"] = int(value.get("version", 0)) + 1
    _records[key] = value
    _revision += 1
    _rebuild_active_scopes()
    generator_changed.emit(key, int(value["version"]), reason)
    return true

func _rebuild_active_scopes() -> void:
    _active_scopes.clear()
    _running_ids.clear()
    for value: Variant in _records.values():
        var item: Dictionary = value
        if bool(item.get("running", false)) and int(item.get("fuel_ticks", 0)) > 0 \
            and int(item.get("condition", 0)) >= MIN_START_CONDITION:
            _running_ids[String(item.get("generator_id", ""))] = true
            _active_scopes[_scope_key(
                String(item.get("power_service_id", "")),
                String(item.get("power_scope_id", ""))
            )] = true

static func _scope_key(power_service_id: String, power_scope_id: String) -> String:
    return "%s|%s" % [power_service_id.strip_edges(), power_scope_id.strip_edges()]
