extends FirstInfectedBehaviorService
class_name CohortInfectedBehaviorService

const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## The exact first-infected behavior policy with measurement/lifecycle hooks for
## a streaming-managed active cohort. No behavior semantics or clock ownership move here.

var _evaluation_count: int = 0
var _evaluation_total_usec: int = 0
var _evaluation_max_usec: int = 0

func evaluation_count() -> int:
    return _evaluation_count

func evaluation_total_usec() -> int:
    return _evaluation_total_usec

func evaluation_max_usec() -> int:
    return _evaluation_max_usec

func deactivate(reason: StringName = &"stream_deactivated") -> void:
    _stop(reason)

func _drive(reason: StringName, refresh_perception: bool = true) -> void:
    if not is_running():
        return
    var started: int = Time.get_ticks_usec()
    _evaluation_count += 1
    super._drive(reason, refresh_perception)
    var elapsed: int = maxi(Time.get_ticks_usec() - started, 0)
    _evaluation_total_usec += elapsed
    _evaluation_max_usec = maxi(_evaluation_max_usec, elapsed)
    PerformanceTelemetry.record_timing(&"infected_behavior_evaluation", elapsed)
    PerformanceTelemetry.record_value(&"infected_behavior_evaluations", _evaluation_count)