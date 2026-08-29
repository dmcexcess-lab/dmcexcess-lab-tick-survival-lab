extends SpoilageEnvironmentProvider
class_name UtilityRefrigerationEnvironmentProvider

## Analytic cumulative exposure clock for one real cold-storage appliance.
## Power/switch transitions settle one context clock; items themselves never tick.

const AMBIENT_RATE_PERMILLE: int = 1000
const POWERED_COLD_RATE_PERMILLE: int = 200

var _utilities: UtilityRuntimeState = null
var _appliance_id: String = ""
var _context_id: StringName = &""
var _anchor_world_tick: int = 0
var _saved_exposure_milliticks: int = 0
var _rate_permille: int = AMBIENT_RATE_PERMILLE

func _init(
    utilities: UtilityRuntimeState = null,
    appliance_id: String = "",
    world_tick: int = 0
) -> void:
    _utilities = utilities
    _appliance_id = appliance_id.strip_edges()
    _context_id = StringName("refrigerated.%s" % _appliance_id) if not _appliance_id.is_empty() else &""
    _anchor_world_tick = maxi(0, world_tick)
    _rate_permille = _current_rate()

func context_id() -> StringName:
    return _context_id

func is_valid() -> bool:
    return _utilities != null and _utilities.is_ready() \
        and not _appliance_id.is_empty() and not String(_context_id).is_empty()

func exposure_ticks_at(world_tick: int) -> int:
    if not is_valid() or world_tick < _anchor_world_tick:
        return -1
    var elapsed: int = world_tick - _anchor_world_tick
    return (_saved_exposure_milliticks + elapsed * _rate_permille) / 1000

func sync_at_tick(world_tick: int) -> bool:
    if not is_valid() or world_tick < _anchor_world_tick:
        return false
    var elapsed: int = world_tick - _anchor_world_tick
    _saved_exposure_milliticks += elapsed * _rate_permille
    _anchor_world_tick = world_tick
    _rate_permille = _current_rate()
    return true

func snapshot() -> Dictionary:
    if not is_valid():
        return {}
    return {
        "context_id": String(_context_id),
        "appliance_id": _appliance_id,
        "anchor_world_tick": _anchor_world_tick,
        "saved_exposure_milliticks": _saved_exposure_milliticks,
        "rate_permille": _rate_permille,
    }

func restore_snapshot(data: Dictionary) -> bool:
    if not is_valid() or String(data.get("context_id", "")) != String(_context_id) \
        or String(data.get("appliance_id", "")) != _appliance_id:
        return false
    var anchor: int = int(data.get("anchor_world_tick", -1))
    var saved: int = int(data.get("saved_exposure_milliticks", -1))
    var rate: int = int(data.get("rate_permille", -1))
    if anchor < 0 or saved < 0 or (rate != AMBIENT_RATE_PERMILLE and rate != POWERED_COLD_RATE_PERMILLE):
        return false
    _anchor_world_tick = anchor
    _saved_exposure_milliticks = saved
    _rate_permille = rate
    return true

func debug_snapshot(world_tick: int) -> Dictionary:
    return {
        "context_id": _context_id,
        "appliance_id": _appliance_id,
        "cold_available": _utilities != null and _utilities.cold_storage_available(_appliance_id),
        "rate_permille": _rate_permille,
        "exposure_ticks": exposure_ticks_at(world_tick),
    }

func _current_rate() -> int:
    if _utilities != null and _utilities.cold_storage_available(_appliance_id):
        return POWERED_COLD_RATE_PERMILLE
    return AMBIENT_RATE_PERMILLE
