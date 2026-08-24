extends RefCounted
class_name WorldTimeService

## Derived simulation-local clock. Authoritative advancement remains TickKernel.world_tick().

signal time_changed(snapshot)

var _kernel: TickKernel = null
var _profile: WorldTimeProfile = null

func _init(tick_kernel: TickKernel = null, profile: WorldTimeProfile = null) -> void:
    _kernel = tick_kernel
    _profile = null if profile == null else profile.copy()
    _connect_kernel()

func is_ready() -> bool:
    return _kernel != null and _profile != null and _profile.is_valid()

func profile() -> WorldTimeProfile:
    return null if _profile == null else _profile.copy()

func current_time() -> Dictionary:
    if not is_ready():
        return {}
    return time_for_tick(_kernel.world_tick())

func time_for_tick(world_tick: int) -> Dictionary:
    if _profile == null or not _profile.is_valid() or world_tick < 0:
        return {}

    var elapsed_seconds: int = int(world_tick / _profile.ticks_per_second)
    var subsecond_tick: int = world_tick % _profile.ticks_per_second
    var absolute_second_from_day_zero: int = _profile.start_second_of_day + elapsed_seconds
    var day_offset: int = int(absolute_second_from_day_zero / WorldTimeProfile.SECONDS_PER_DAY)
    var second_of_day: int = absolute_second_from_day_zero % WorldTimeProfile.SECONDS_PER_DAY
    var hour: int = int(second_of_day / WorldTimeProfile.SECONDS_PER_HOUR)
    var minute: int = int((second_of_day % WorldTimeProfile.SECONDS_PER_HOUR) / WorldTimeProfile.SECONDS_PER_MINUTE)
    var second: int = second_of_day % WorldTimeProfile.SECONDS_PER_MINUTE

    return {
        "world_tick": world_tick,
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

func _connect_kernel() -> void:
    if _kernel == null:
        return
    var advanced := Callable(self, "_on_world_tick_advanced")
    if not _kernel.world_tick_advanced.is_connected(advanced):
        _kernel.world_tick_advanced.connect(advanced)
    var reset := Callable(self, "_on_timing_state_reset")
    if not _kernel.timing_state_reset.is_connected(reset):
        _kernel.timing_state_reset.connect(reset)

func _on_world_tick_advanced(_previous_tick: int, _new_tick: int) -> void:
    if is_ready():
        time_changed.emit(current_time())

func _on_timing_state_reset() -> void:
    if is_ready():
        time_changed.emit(current_time())
