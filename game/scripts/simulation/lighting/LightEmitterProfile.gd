extends RefCounted
class_name LightEmitterProfile

## Semantic physical-light profile. Source systems decide whether a real emitter is active.

enum Shape {
    OMNI,
    CONE,
}

var profile_id: StringName = &""
var shape: int = Shape.OMNI
var useful_range: int = 8
var base_luminance: float = 0.8
var tint: Color = Color.WHITE
var falloff_exponent: float = 1.4
var cone_half_angle_degrees: float = 28.0
var diffuse_spill: float = 0.08

func _init(
    id_value: StringName = &"light.generic",
    shape_value: int = Shape.OMNI,
    range_value: int = 8,
    luminance_value: float = 0.8,
    tint_value: Color = Color.WHITE,
    falloff_value: float = 1.4,
    cone_half_angle_value: float = 28.0,
    spill_value: float = 0.08
) -> void:
    profile_id = id_value
    shape = shape_value
    useful_range = range_value
    base_luminance = luminance_value
    tint = tint_value
    falloff_exponent = falloff_value
    cone_half_angle_degrees = cone_half_angle_value
    diffuse_spill = spill_value

func is_valid() -> bool:
    return (
        not String(profile_id).strip_edges().is_empty()
        and (shape == Shape.OMNI or shape == Shape.CONE)
        and useful_range >= 1 and useful_range <= 128
        and base_luminance > 0.0
        and falloff_exponent > 0.0
        and cone_half_angle_degrees > 0.0 and cone_half_angle_degrees <= 90.0
        and diffuse_spill >= 0.0 and diffuse_spill <= 0.5
    )

func copy() -> LightEmitterProfile:
    return LightEmitterProfile.new(
        profile_id,
        shape,
        useful_range,
        base_luminance,
        tint,
        falloff_exponent,
        cone_half_angle_degrees,
        diffuse_spill
    )

static func flashlight() -> LightEmitterProfile:
    return LightEmitterProfile.new(
        &"light.flashlight.candidate001",
        Shape.CONE,
        14,
        1.0,
        Color(1.0, 0.96, 0.84),
        1.15,
        31.0,
        0.07
    )

static func lamp() -> LightEmitterProfile:
    return LightEmitterProfile.new(
        &"light.lamp.candidate001",
        Shape.OMNI,
        7,
        0.72,
        Color(1.0, 0.74, 0.46),
        1.55,
        45.0,
        0.11
    )

static func streetlight() -> LightEmitterProfile:
    return LightEmitterProfile.new(
        &"light.streetlight.candidate001",
        Shape.OMNI,
        10,
        0.82,
        Color(1.0, 0.78, 0.48),
        1.35,
        45.0,
        0.08
    )

static func neon(tint_value: Color = Color(0.30, 0.72, 1.0)) -> LightEmitterProfile:
    return LightEmitterProfile.new(
        &"light.neon.candidate001",
        Shape.OMNI,
        6,
        0.58,
        tint_value,
        1.35,
        45.0,
        0.10
    )
