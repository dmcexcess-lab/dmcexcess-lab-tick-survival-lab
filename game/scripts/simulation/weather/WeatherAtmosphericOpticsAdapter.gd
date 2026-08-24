extends RefCounted
class_name WeatherAtmosphericOpticsAdapter

const OpticsClass = preload("res://scripts/simulation/lighting/AtmosphericOptics.gd")

## System 28 -> System 27 neutral adapter. Weather supplies continuous physical
## atmosphere facts; Lighting remains the owner of illumination consequences.

static func current_optics(weather_service) -> AtmosphericOptics:
    if weather_service == null or not weather_service.has_method("current_sample"):
        return OpticsClass.clear(0)
    var sample: Dictionary = weather_service.current_sample()
    if sample.is_empty():
        return OpticsClass.clear(0)
    return from_sample(sample)

static func from_sample(sample: Dictionary) -> AtmosphericOptics:
    var precipitation: float = clampf(float(sample.get("precipitation", 0.0)), 0.0, 1.0)
    var cloud_cover: float = clampf(float(sample.get("cloud_cover", 0.0)), 0.0, 1.0)
    var fog_density: float = clampf(float(sample.get("fog_density", 0.0)), 0.0, 1.0)
    var wetness: float = clampf(float(sample.get("wetness", 0.0)), 0.0, 1.0)

    # Candidate 001 clear weather intentionally carries a little cloud/haze.
    # Normalize that baseline away so CLEAR remains essentially neutral while
    # continuous fields above it produce the physical atmosphere response.
    var cloud_pressure: float = clampf((cloud_cover - 0.14) / 0.86, 0.0, 1.0)
    var fog_pressure: float = clampf((fog_density - 0.02) / 0.80, 0.0, 1.0)

    var diffuse: float = clampf(
        1.0
        - cloud_pressure * 0.24
        - precipitation * 0.10
        - fog_pressure * 0.18
        - precipitation * cloud_pressure * 0.18,
        0.30,
        1.0
    )
    var direct: float = clampf(
        1.0
        - cloud_pressure * 0.82
        - precipitation * 0.12
        - fog_pressure * 0.35,
        0.02,
        1.0
    )
    var local_transmission: float = clampf(
        1.0 - precipitation * 0.08 - fog_pressure * 0.18,
        0.55,
        1.0
    )
    var scatter: float = clampf(
        cloud_pressure * 0.08 + precipitation * 0.22 + fog_pressure * 0.68,
        0.0,
        1.0
    )
    var visibility_extinction: float = clampf(
        cloud_pressure * 0.03 + precipitation * 0.18 + fog_pressure * 0.58,
        0.0,
        0.85
    )
    var cool_pressure: float = clampf(
        cloud_pressure * 0.18 + precipitation * 0.16 + fog_pressure * 0.18,
        0.0,
        0.55
    )
    var tint: Color = Color.WHITE.lerp(Color(0.76, 0.84, 0.96, 1.0), cool_pressure)
    return OpticsClass.new(
        diffuse,
        direct,
        local_transmission,
        scatter,
        tint,
        wetness,
        visibility_extinction,
        maxi(0, int(sample.get("environment_revision", 0)))
    )
