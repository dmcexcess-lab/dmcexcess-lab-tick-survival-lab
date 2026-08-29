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
## Presentation attribution only. Physical illumination always uses base_luminance.
## A value of zero means the source raises real local light without additive bloom/glare.
var presentation_glow_scale: float = 1.0

func _init(
    id_value: StringName = &"light.generic",
    shape_value: int = Shape.OMNI,
    range_value: int = 8,
    luminance_value: float = 0.8,
    tint_value: Color = Color.WHITE,
    falloff_value: float = 1.4,
    cone_half_angle_value: float = 28.0,
    spill_value: float = 0.08,
    presentation_glow_scale_value: float = 1.0
) -> void:
    profile_id = id_value
    shape = shape_value
    useful_range = range_value
    base_luminance = luminance_value
    tint = tint_value
    falloff_exponent = falloff_value
    cone_half_angle_degrees = cone_half_angle_value
    diffuse_spill = spill_value
    presentation_glow_scale = presentation_glow_scale_value

func is_valid() -> bool:
    return (
        not String(profile_id).strip_edges().is_empty()
        and (shape == Shape.OMNI or shape == Shape.CONE)
        and useful_range >= 1 and useful_range <= 128
        and base_luminance > 0.0
        and falloff_exponent > 0.0
        and cone_half_angle_degrees > 0.0 and cone_half_angle_degrees <= 90.0
        and diffuse_spill >= 0.0 and diffuse_spill <= 0.5
        and presentation_glow_scale >= 0.0 and presentation_glow_scale <= 1.0
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
        diffuse_spill,
        presentation_glow_scale
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
        0.94,
        Color(0.94, 0.97, 1.0),
        1.30,
        45.0,
        0.09,
        1.0
    )

static func neon(tint_value: Color = Color(0.22, 0.70, 1.0)) -> LightEmitterProfile:
    return LightEmitterProfile.new(
        &"light.neon.candidate001",
        Shape.OMNI,
        6,
        0.70,
        tint_value,
        1.28,
        45.0,
        0.12,
        1.0
    )

static func gas_sign() -> LightEmitterProfile:
    return LightEmitterProfile.new(
        &"light.gas_sign.candidate001",
        Shape.OMNI,
        8,
        0.78,
        Color(1.0, 0.16, 0.07),
        1.24,
        45.0,
        0.13,
        1.0
    )

static func traffic_red() -> LightEmitterProfile:
    return _traffic(&"light.traffic.red.candidate001", Color(1.0, 0.06, 0.04))

static func traffic_yellow() -> LightEmitterProfile:
    return _traffic(&"light.traffic.yellow.candidate001", Color(1.0, 0.72, 0.05))

static func traffic_green() -> LightEmitterProfile:
    return _traffic(&"light.traffic.green.candidate001", Color(0.08, 1.0, 0.22))

static func _traffic(id_value: StringName, tint_value: Color) -> LightEmitterProfile:
    return LightEmitterProfile.new(
        id_value,
        Shape.OMNI,
        4,
        0.48,
        tint_value,
        1.18,
        45.0,
        0.08,
        1.0
    )

static func room_ambient() -> LightEmitterProfile:
    return LightEmitterProfile.new(
        &"light.room_ambient.candidate001",
        Shape.OMNI,
        6,
        0.62,
        Color(1.0, 0.88, 0.70),
        1.25,
        45.0,
        0.12,
        0.0
    )
