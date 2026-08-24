extends SceneTree

const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const WorldTimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const WorldTimeServiceClass = preload("res://scripts/simulation/world_time/WorldTimeService.gd")
const DaylightProfileClass = preload("res://scripts/simulation/world_time/DaylightProfile.gd")
const AmbientServiceClass = preload("res://scripts/simulation/world_time/OutdoorAmbientLightService.gd")
const OverlayClass = preload("res://scripts/render/PerceptionOverlayRenderer.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_tick_to_clock_mapping()
    _test_kernel_pause_and_restore()
    _test_daylight_curve()
    _test_perception_ambient_contract()

    if _failures.is_empty():
        print("WORLD_TIME_AMBIENT_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("WORLD_TIME_AMBIENT_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_tick_to_clock_mapping() -> void:
    var profile := WorldTimeProfileClass.new()
    _check(profile.is_valid(), "default world-time profile is valid")
    _check(profile.ticks_per_second == 5, "Candidate001 uses five ticks per simulation second")
    _check(profile.ticks_per_minute() == 300, "Candidate001 minute mapping is exact")
    _check(profile.ticks_per_hour() == 18000, "Candidate001 hour mapping is exact")
    _check(profile.ticks_per_day() == 432000, "Candidate001 day mapping is exact")

    var kernel := TickKernelClass.new()
    var clock := WorldTimeServiceClass.new(kernel, profile)
    _check(clock.is_ready(), "world-time service is ready")
    _assert_clock(clock.time_for_tick(0), 0, 8, 0, 0, "start time is day zero 08:00:00")
    _assert_clock(clock.time_for_tick(5), 0, 8, 0, 1, "five ticks advance one simulation second")
    _assert_clock(clock.time_for_tick(300), 0, 8, 1, 0, "300 ticks advance one simulation minute")
    _assert_clock(clock.time_for_tick(18000), 0, 9, 0, 0, "18000 ticks advance one simulation hour")
    _assert_clock(clock.time_for_tick(287999), 0, 23, 59, 59, "last subsecond before midnight remains day zero")
    _assert_clock(clock.time_for_tick(288000), 1, 0, 0, 0, "midnight increments scenario day index")

func _test_kernel_pause_and_restore() -> void:
    var profile := WorldTimeProfileClass.new()
    var kernel := TickKernelClass.new()
    var clock := WorldTimeServiceClass.new(kernel, profile)
    var due_tick: int = 100
    _check(kernel.schedule_event(due_tick, "world_time_test", &"clock_probe") > 0, "test event schedules")
    kernel.set_hard_paused(true)
    var paused_result: int = kernel.run_until_stop()
    _check(paused_result == TickRules.RunStopReason.HARD_PAUSED, "hard pause stops WHEN")
    _check(kernel.world_tick() == 0, "hard pause advances zero authoritative ticks")
    _assert_clock(clock.current_time(), 0, 8, 0, 0, "world time does not advance during hard pause")

    kernel.set_hard_paused(false)
    kernel.run_until_stop()
    _check(kernel.world_tick() == due_tick, "WHEN advances to scheduled test tick")
    _assert_clock(clock.current_time(), 0, 8, 0, 20, "world time derives from advanced WHEN tick")

    var snapshot: Dictionary = kernel.snapshot()
    var restored_kernel := TickKernelClass.new()
    _check(restored_kernel.load_snapshot(snapshot), "WHEN snapshot restores")
    var restored_clock := WorldTimeServiceClass.new(restored_kernel, profile)
    _check(restored_clock.is_ready(), "restored world-time service is ready")
    _check(restored_clock.current_time() == clock.current_time(), "world time is deterministic after WHEN restore")

func _test_daylight_curve() -> void:
    var clock := WorldTimeServiceClass.new(TickKernelClass.new(), WorldTimeProfileClass.new())
    var profile := DaylightProfileClass.new()
    var ambient := AmbientServiceClass.new(clock, profile)
    _check(profile.is_valid(), "default daylight profile is valid")
    _check(ambient.is_ready(), "ambient daylight service is ready")
    _check(ambient.current_phase() == AmbientServiceClass.PHASE_DAY, "08:00 scenario start is daylight")
    _check(is_equal_approx(ambient.ambient_light_level(), 1.0), "08:00 scenario start has full baseline daylight")

    var dawn_start: int = 5 * 3600 + 30 * 60
    var dawn_mid: int = 6 * 3600 + 30 * 60
    var day_start: int = 7 * 3600 + 30 * 60
    var dusk_start: int = 18 * 3600 + 30 * 60
    var dusk_mid: int = 19 * 3600 + 30 * 60
    var night_start: int = 20 * 3600 + 30 * 60

    _check(ambient.phase_for_second_of_day(2 * 3600) == AmbientServiceClass.PHASE_NIGHT, "deep night phase classified")
    _check(is_equal_approx(ambient.level_for_second_of_day(2 * 3600), 0.08), "deep night uses baseline night level")
    _check(ambient.phase_for_second_of_day(dawn_start) == AmbientServiceClass.PHASE_DAWN, "dawn boundary classified")
    _check(is_equal_approx(ambient.level_for_second_of_day(dawn_start), 0.08), "dawn starts at night level")
    _check(is_equal_approx(ambient.level_for_second_of_day(dawn_mid), 0.54), "dawn midpoint interpolates smoothly")
    _check(ambient.phase_for_second_of_day(day_start) == AmbientServiceClass.PHASE_DAY, "day boundary classified")
    _check(is_equal_approx(ambient.level_for_second_of_day(day_start), 1.0), "day begins at full baseline light")
    _check(ambient.phase_for_second_of_day(dusk_start) == AmbientServiceClass.PHASE_DUSK, "dusk boundary classified")
    _check(is_equal_approx(ambient.level_for_second_of_day(dusk_start), 1.0), "dusk starts at full baseline light")
    _check(is_equal_approx(ambient.level_for_second_of_day(dusk_mid), 0.54), "dusk midpoint interpolates smoothly")
    _check(ambient.phase_for_second_of_day(night_start) == AmbientServiceClass.PHASE_NIGHT, "night boundary classified")
    _check(is_equal_approx(ambient.level_for_second_of_day(night_start), 0.08), "night boundary returns to baseline night level")

func _test_perception_ambient_contract() -> void:
    var overlay := OverlayClass.new()
    _check(OverlayClass.TRUE_FOG_COLOR == Color.BLACK, "UNSEEN remains fully black")
    _check(overlay.set_ambient_light_level(1.0), "day ambient accepted by System23")
    _check(is_equal_approx(overlay.memory_luminance(), 0.30), "day remembered luminance preserves prior appearance")
    _check(overlay.set_ambient_light_level(0.08), "night baseline ambient accepted by System23")
    _check(is_equal_approx(overlay.memory_luminance(), 0.116), "night remembered luminance darkens without becoming true fog")
    _check(overlay.memory_luminance() > 0.0, "REMEMBERED stays distinguishable from UNSEEN at night")
    _check(OverlayClass.TRUE_FOG_COLOR == Color.BLACK, "ambient input never changes true fog")

func _assert_clock(snapshot: Dictionary, day_index: int, hour: int, minute: int, second: int, description: String) -> void:
    _check(not snapshot.is_empty(), "%s snapshot exists" % description)
    if snapshot.is_empty():
        return
    _check(int(snapshot.get("day_index", -1)) == day_index, "%s day" % description)
    _check(int(snapshot.get("hour", -1)) == hour, "%s hour" % description)
    _check(int(snapshot.get("minute", -1)) == minute, "%s minute" % description)
    _check(int(snapshot.get("second", -1)) == second, "%s second" % description)

func _check(condition: bool, description: String) -> void:
    if not condition:
        _failures.append(description)