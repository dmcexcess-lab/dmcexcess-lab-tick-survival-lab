extends SceneTree

const Calendar = preload("res://scripts/WorldCalendar.gd")

func _init() -> void:
    if Calendar.TICKS_PER_DAY != 7200 or Calendar.TICKS_PER_MINUTE != 5:
        push_error("CALENDAR_SMOKE_RATE_CHANGED")
        quit(1)
        return
    if Calendar.elapsed_minutes(10) != 2:
        push_error("CALENDAR_SMOKE_ACTION_TIME_MAPPING")
        quit(1)
        return
    if Calendar.minute_of_day(6 * 60, 0, 300) != 7 * 60:
        push_error("CALENDAR_SMOKE_HOUR_ADVANCE")
        quit(1)
        return
    if Calendar.phase(5 * 60 + 29) != Calendar.PHASE_NIGHT:
        push_error("CALENDAR_SMOKE_PRE_DAWN")
        quit(1)
        return
    if Calendar.phase(5 * 60 + 30) != Calendar.PHASE_DAWN:
        push_error("CALENDAR_SMOKE_DAWN")
        quit(1)
        return
    if Calendar.phase(7 * 60) != Calendar.PHASE_DAY:
        push_error("CALENDAR_SMOKE_DAY")
        quit(1)
        return
    if Calendar.phase(18 * 60 + 30) != Calendar.PHASE_DUSK:
        push_error("CALENDAR_SMOKE_DUSK")
        quit(1)
        return
    if Calendar.phase(20 * 60) != Calendar.PHASE_NIGHT:
        push_error("CALENDAR_SMOKE_NIGHT")
        quit(1)
        return
    var md: Vector2i = Calendar.month_day(8, 31, 23 * 60 + 50, 0, 100)
    if md != Vector2i(9, 1):
        push_error("CALENDAR_SMOKE_DATE_ROLLOVER_%s" % str(md))
        quit(1)
        return
    print("TICK_SURVIVAL_CALENDAR_SMOKE_OK")
    quit(0)
