extends RefCounted
class_name WorldCalendar

# Calendar compression is deliberately separate from action costs. The world
# scheduler owns authoritative ticks; this module only maps those ticks onto
# human-readable world time.
const TICKS_PER_DAY := 7200
const MINUTES_PER_DAY := 1440
const TICKS_PER_MINUTE := TICKS_PER_DAY / MINUTES_PER_DAY # 5
const DAYS_IN_MONTH := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

const PHASE_NIGHT := "night"
const PHASE_DAWN := "dawn"
const PHASE_DAY := "day"
const PHASE_DUSK := "dusk"

static func elapsed_minutes(elapsed_ticks: int) -> int:
    return maxi(0, elapsed_ticks) / TICKS_PER_MINUTE

static func total_minutes(anchor_minutes: int, anchor_tick: int, world_tick: int) -> int:
    return anchor_minutes + elapsed_minutes(world_tick - anchor_tick)

static func minute_of_day(anchor_minutes: int, anchor_tick: int, world_tick: int) -> int:
    return posmod(total_minutes(anchor_minutes, anchor_tick, world_tick), MINUTES_PER_DAY)

static func day_offset(anchor_minutes: int, anchor_tick: int, world_tick: int) -> int:
    return total_minutes(anchor_minutes, anchor_tick, world_tick) / MINUTES_PER_DAY

static func month_day(anchor_month: int, anchor_day: int, anchor_minutes: int, anchor_tick: int, world_tick: int) -> Vector2i:
    var month: int = clampi(anchor_month, 1, 12)
    var day: int = maxi(1, anchor_day) + day_offset(anchor_minutes, anchor_tick, world_tick)
    while day > DAYS_IN_MONTH[month - 1]:
        day -= DAYS_IN_MONTH[month - 1]
        month += 1
        if month > 12:
            month = 1
    return Vector2i(month, day)

static func phase(minute: int) -> String:
    var m: int = posmod(minute, MINUTES_PER_DAY)
    if m >= 5 * 60 + 30 and m < 7 * 60:
        return PHASE_DAWN
    if m >= 7 * 60 and m < 18 * 60 + 30:
        return PHASE_DAY
    if m >= 18 * 60 + 30 and m < 20 * 60:
        return PHASE_DUSK
    return PHASE_NIGHT

static func days_in_month(month: int) -> int:
    return DAYS_IN_MONTH[clampi(month, 1, 12) - 1]
