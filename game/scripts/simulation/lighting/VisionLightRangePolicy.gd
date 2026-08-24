extends RefCounted
class_name VisionLightRangePolicy

## Pure policy translating target-cell physical illumination + atmospheric
## extinction into useful visual range. System 23/future AI own observer
## acquisition; System 27 owns only the physical visibility signal.

const DEFAULT_MIN_RANGE: int = 2
const VISIBILITY_RESPONSE_EXPONENT: float = 1.25

static func effective_range_for_luminance(
    luminance: float,
    geometric_max_range: int,
    near_awareness_radius: int = 1
) -> int:
    if geometric_max_range < 1:
        return 0
    var minimum: int = clampi(maxi(DEFAULT_MIN_RANGE, near_awareness_radius), 1, geometric_max_range)
    var normalized: float = clampf(luminance, 0.0, 1.0)
    # Human-readable gameplay curve: severe darkness collapses range quickly while
    # moderate light recovers useful distance before full daylight.
    var response: float = sqrt(normalized)
    return clampi(minimum + roundi(float(geometric_max_range - minimum) * response), minimum, geometric_max_range)

static func effective_range_for_conditions(
    luminance: float,
    visibility_extinction: float,
    geometric_max_range: int,
    near_awareness_radius: int = 1
) -> int:
    if geometric_max_range < 1:
        return 0
    var minimum: int = clampi(maxi(DEFAULT_MIN_RANGE, near_awareness_radius), 1, geometric_max_range)
    var light_range: int = effective_range_for_luminance(luminance, geometric_max_range, near_awareness_radius)
    var clarity: float = 1.0 - clampf(visibility_extinction, 0.0, 1.0)
    var atmosphere_response: float = pow(clarity, VISIBILITY_RESPONSE_EXPONENT)
    var atmosphere_range: int = clampi(
        minimum + roundi(float(geometric_max_range - minimum) * atmosphere_response),
        minimum,
        geometric_max_range
    )
    return mini(light_range, atmosphere_range)

static func target_within_light_range(
    offset: Vector2i,
    luminance: float,
    geometric_max_range: int,
    near_awareness_radius: int = 1
) -> bool:
    if offset == Vector2i.ZERO:
        return true
    if maxi(abs(offset.x), abs(offset.y)) <= near_awareness_radius:
        return true
    var effective_range: int = effective_range_for_luminance(
        luminance,
        geometric_max_range,
        near_awareness_radius
    )
    return offset.x * offset.x + offset.y * offset.y <= effective_range * effective_range

static func target_within_visual_range(
    offset: Vector2i,
    luminance: float,
    visibility_extinction: float,
    geometric_max_range: int,
    near_awareness_radius: int = 1
) -> bool:
    if offset == Vector2i.ZERO:
        return true
    if maxi(abs(offset.x), abs(offset.y)) <= near_awareness_radius:
        return true
    var effective_range: int = effective_range_for_conditions(
        luminance,
        visibility_extinction,
        geometric_max_range,
        near_awareness_radius
    )
    return offset.x * offset.x + offset.y * offset.y <= effective_range * effective_range
