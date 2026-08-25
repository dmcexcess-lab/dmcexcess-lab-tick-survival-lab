extends RefCounted
class_name PerformanceTelemetry

## Low-overhead DEV/CI observation only. Never drives gameplay decisions.

static var _timings: Dictionary = {}
static var _values: Dictionary = {}
static var _last_batch: Dictionary = {}
static var _batch_count: int = 0

static func reset() -> void:
    _timings.clear()
    _values.clear()
    _last_batch.clear()
    _batch_count = 0

static func record_timing(metric: StringName, usec: int) -> void:
    var key: String = String(metric)
    var entry: Dictionary = _timings.get(key, {
        "last_usec": 0,
        "max_usec": 0,
        "total_usec": 0,
        "count": 0,
    })
    var value: int = maxi(usec, 0)
    entry["last_usec"] = value
    entry["max_usec"] = maxi(int(entry.get("max_usec", 0)), value)
    entry["total_usec"] = int(entry.get("total_usec", 0)) + value
    entry["count"] = int(entry.get("count", 0)) + 1
    _timings[key] = entry

static func record_value(metric: StringName, value: Variant) -> void:
    _values[String(metric)] = value

static func increment(metric: StringName, amount: int = 1) -> void:
    var key: String = String(metric)
    _values[key] = int(_values.get(key, 0)) + amount

static func record_batch(batch: WorldChangeBatch) -> void:
    if batch == null:
        return
    _batch_count += 1
    _last_batch = batch.to_debug_dict()
    _values["world_batches"] = _batch_count
    _values["last_batch_changes"] = batch.change_count

static func snapshot() -> Dictionary:
    return {
        "timings": _timings.duplicate(true),
        "values": _values.duplicate(true),
        "last_batch": _last_batch.duplicate(true),
        "batch_count": _batch_count,
    }
