extends RefCounted
class_name WorldTimeService

## Authoritative scenario-local clock. Legacy callers may still mirror TickKernel,
## while canonical turn-based play switches this owner to explicit manual advancement.

signal time_changed(snapshot)

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _kernel: TickKernel = null
var _profile: WorldTimeProfile = null
var _manual_mode: bool = false
var _manual_tick: int = 0

func _init(tick_kernel: TickKernel = null, profile: WorldTimeProfile = null) -> void:
    _kernel = tick_kernel
    _profile = null if profile == null else profile.copy()
    _manual_tick = 0 if _kernel == null else maxi(0, _kernel.world_tick())
    _connect_kernel()

func is_ready() -> bool:
    return _profile != null and _profile.is_valid() and (_manual_mode or _kernel != null)

func profile() -> WorldTimeProfile:
    return null if _profile == null else _profile.copy()

func uses_manual_clock() -> bool:
    return _manual_mode

func world_tick() -> int:
    if _manual_mode:
        return _manual_tick
    return 0 if _kernel == null else _kernel.world_tick()

func configure_manual_clock(start_tick: int) -> bool:
    if _profile == null or not _profile.is_valid() or start_tick < 0:
        return false
    _disconnect_kernel()
    _manual_mode = true
    _manual_tick = start_tick
    time_changed.emit(current_time())
    return true

func advance_ticks(elapsed_ticks: int) -> bool:
    if not _manual_mode or elapsed_ticks < 1:
        return false
    _manual_tick += elapsed_ticks
    time_changed.emit(current_time())
    return true

func advance_to_tick(target_tick: int) -> bool:
    if not _manual_mode or target_tick < _manual_tick:
        return false
    if target_tick == _manual_tick:
        return true
    _manual_tick = target_tick
    time_changed.emit(current_time())
    return true

func current_time() -> Dictionary:
    if not is_ready():
        return {}
    return time_for_tick(world_tick())

func time_for_tick(world_tick_value: int) -> Dictionary:
    if _profile == null or not _profile.is_valid() or world_tick_value < 0:
        return {}

    var elapsed_seconds: int = int(world_tick_value / _profile.ticks_per_second)
    var subsecond_tick: int = world_tick_value % _profile.ticks_per_second
    var absolute_second_from_day_zero: int = _profile.start_second_of_day + elapsed_seconds
    var day_offset: int = int(absolute_second_from_day_zero / WorldTimeProfile.SECONDS_PER_DAY)
    var second_of_day: int = absolute_second_from_day_zero % WorldTimeProfile.SECONDS_PER_DAY
    var hour: int = int(second_of_day / WorldTimeProfile.SECONDS_PER_HOUR)
    var minute: int = int((second_of_day % WorldTimeProfile.SECONDS_PER_HOUR) / WorldTimeProfile.SECONDS_PER_MINUTE)
    var second: int = second_of_day % WorldTimeProfile.SECONDS_PER_MINUTE

    return {
        "world_tick": world_tick_value,
        "elapsed_seconds": elapsed_seconds,
        "subsecond_tick": subsecond_tick,
        "ticks_per_second": _profile.ticks_per_second,
        "day_index": _profile.start_day_index + day_offset,
        "second_of_day": second_of_day,
        "hour": hour,
        "minute": minute,
        "second": second,
        "day_fraction": float(second_of_day) / float(WorldTimeProfile.SECONDS_PER_DAY),
    }

func snapshot() -> Dictionary:
    if not is_ready():
        return {}
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "world_tick": world_tick(),
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var restored_tick := int(data.get("world_tick", -1))
    if restored_tick < 0:
        return false
    return configure_manual_clock(restored_tick)

func _connect_kernel() -> void:
    if _kernel == null or _manual_mode:
        return
    var advanced := Callable(self, "_on_world_tick_advanced")
    if not _kernel.world_tick_advanced.is_connected(advanced):
        _kernel.world_tick_advanced.connect(advanced)
    var reset := Callable(self, "_on_timing_state_reset")
    if not _kernel.timing_state_reset.is_connected(reset):
        _kernel.timing_state_reset.connect(reset)

func _disconnect_kernel() -> void:
    if _kernel == null:
        return
    var advanced := Callable(self, "_on_world_tick_advanced")
    if _kernel.world_tick_advanced.is_connected(advanced):
        _kernel.world_tick_advanced.disconnect(advanced)
    var reset := Callable(self, "_on_timing_state_reset")
    if _kernel.timing_state_reset.is_connected(reset):
        _kernel.timing_state_reset.disconnect(reset)

func _on_world_tick_advanced(_previous_tick: int, _new_tick: int) -> void:
    if is_ready() and not _manual_mode:
        time_changed.emit(current_time())

func _on_timing_state_reset() -> void:
    if is_ready() and not _manual_mode:
        time_changed.emit(current_time())
