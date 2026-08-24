extends RefCounted
class_name WorldTimeProfile

## Validated scenario-local interpretation of authoritative WHEN ticks.
## WHEN itself remains unaware of seconds/minutes/days.

const SECONDS_PER_MINUTE: int = 60
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const SECONDS_PER_HOUR: int = SECONDS_PER_MINUTE * MINUTES_PER_HOUR
const SECONDS_PER_DAY: int = SECONDS_PER_HOUR * HOURS_PER_DAY

const DEFAULT_TICKS_PER_SECOND: int = 5
const DEFAULT_START_DAY_INDEX: int = 0
const DEFAULT_START_SECOND_OF_DAY: int = 8 * SECONDS_PER_HOUR

var ticks_per_second: int = DEFAULT_TICKS_PER_SECOND
var start_day_index: int = DEFAULT_START_DAY_INDEX
var start_second_of_day: int = DEFAULT_START_SECOND_OF_DAY

func _init(
    ticks_per_second_value: int = DEFAULT_TICKS_PER_SECOND,
    start_day_index_value: int = DEFAULT_START_DAY_INDEX,
    start_second_of_day_value: int = DEFAULT_START_SECOND_OF_DAY
) -> void:
    ticks_per_second = ticks_per_second_value
    start_day_index = start_day_index_value
    start_second_of_day = start_second_of_day_value

func is_valid() -> bool:
    return ticks_per_second > 0 \
        and start_day_index >= 0 \
        and start_second_of_day >= 0 \
        and start_second_of_day < SECONDS_PER_DAY

func copy() -> WorldTimeProfile:
    return WorldTimeProfile.new(ticks_per_second, start_day_index, start_second_of_day)

func ticks_per_minute() -> int:
    return ticks_per_second * SECONDS_PER_MINUTE

func ticks_per_hour() -> int:
    return ticks_per_second * SECONDS_PER_HOUR

func ticks_per_day() -> int:
    return ticks_per_second * SECONDS_PER_DAY
