extends RefCounted
class_name DaylightProfile

## Baseline outdoor daylight curve. Weather/local artificial lighting are separate future inputs.

const DEFAULT_DAWN_START_SECOND: int = 5 * WorldTimeProfile.SECONDS_PER_HOUR + 30 * WorldTimeProfile.SECONDS_PER_MINUTE
const DEFAULT_DAY_START_SECOND: int = 7 * WorldTimeProfile.SECONDS_PER_HOUR + 30 * WorldTimeProfile.SECONDS_PER_MINUTE
const DEFAULT_DUSK_START_SECOND: int = 18 * WorldTimeProfile.SECONDS_PER_HOUR + 30 * WorldTimeProfile.SECONDS_PER_MINUTE
const DEFAULT_NIGHT_START_SECOND: int = 20 * WorldTimeProfile.SECONDS_PER_HOUR + 30 * WorldTimeProfile.SECONDS_PER_MINUTE
const DEFAULT_NIGHT_LEVEL: float = 0.08
const DEFAULT_DAY_LEVEL: float = 1.0

var dawn_start_second: int = DEFAULT_DAWN_START_SECOND
var day_start_second: int = DEFAULT_DAY_START_SECOND
var dusk_start_second: int = DEFAULT_DUSK_START_SECOND
var night_start_second: int = DEFAULT_NIGHT_START_SECOND
var night_level: float = DEFAULT_NIGHT_LEVEL
var day_level: float = DEFAULT_DAY_LEVEL

func _init(
    dawn_start_second_value: int = DEFAULT_DAWN_START_SECOND,
    day_start_second_value: int = DEFAULT_DAY_START_SECOND,
    dusk_start_second_value: int = DEFAULT_DUSK_START_SECOND,
    night_start_second_value: int = DEFAULT_NIGHT_START_SECOND,
    night_level_value: float = DEFAULT_NIGHT_LEVEL,
    day_level_value: float = DEFAULT_DAY_LEVEL
) -> void:
    dawn_start_second = dawn_start_second_value
    day_start_second = day_start_second_value
    dusk_start_second = dusk_start_second_value
    night_start_second = night_start_second_value
    night_level = night_level_value
    day_level = day_level_value

func is_valid() -> bool:
    return dawn_start_second >= 0 \
        and dawn_start_second < day_start_second \
        and day_start_second < dusk_start_second \
        and dusk_start_second < night_start_second \
        and night_start_second < WorldTimeProfile.SECONDS_PER_DAY \
        and night_level >= 0.0 \
        and night_level <= 1.0 \
        and day_level >= 0.0 \
        and day_level <= 1.0 \
        and day_level >= night_level

func copy() -> DaylightProfile:
    return DaylightProfile.new(
        dawn_start_second,
        day_start_second,
        dusk_start_second,
        night_start_second,
        night_level,
        day_level
    )
