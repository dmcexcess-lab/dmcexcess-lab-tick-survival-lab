extends RefCounted
class_name AtmosphericOptics

## Neutral physical-lighting input owned by System 27.
## Weather may provide equivalent snapshots; Lighting does not own weather state.

var diffuse_sky_transmission: float = 1.0
var direct_sky_transmission: float = 1.0
var local_light_transmission: float = 1.0
var scatter_strength: float = 0.0
var tint: Color = Color.WHITE
var wet_surface_factor: float = 0.0
var visibility_extinction: float = 0.0
var revision: int = 1
var transient_sky_light: float = 0.0
var transient_sky_tint: Color = Color(0.78, 0.88, 1.0, 1.0)

func _init(
    diffuse_value: float = 1.0,
    direct_value: float = 1.0,
    local_value: float = 1.0,
    scatter_value: float = 0.0,
    tint_value: Color = Color.WHITE,
    wet_value: float = 0.0,
    visibility_value: float = 0.0,
    revision_value: int = 1,
    transient_sky_value: float = 0.0,
    transient_tint_value: Color = Color(0.78, 0.88, 1.0, 1.0)
) -> void:
    diffuse_sky_transmission = diffuse_value
    direct_sky_transmission = direct_value
    local_light_transmission = local_value
    scatter_strength = scatter_value
    tint = tint_value
    wet_surface_factor = wet_value
    visibility_extinction = visibility_value
    revision = revision_value
    transient_sky_light = transient_sky_value
    transient_sky_tint = transient_tint_value

func is_valid() -> bool:
    return (
        diffuse_sky_transmission >= 0.0 and diffuse_sky_transmission <= 1.0
        and direct_sky_transmission >= 0.0 and direct_sky_transmission <= 1.0
        and local_light_transmission >= 0.0 and local_light_transmission <= 1.0
        and scatter_strength >= 0.0 and scatter_strength <= 1.0
        and wet_surface_factor >= 0.0 and wet_surface_factor <= 1.0
        and visibility_extinction >= 0.0 and visibility_extinction <= 1.0
        and transient_sky_light >= 0.0 and transient_sky_light <= 1.0
        and revision >= 0
    )

func copy() -> AtmosphericOptics:
    return AtmosphericOptics.new(
        diffuse_sky_transmission,
        direct_sky_transmission,
        local_light_transmission,
        scatter_strength,
        tint,
        wet_surface_factor,
        visibility_extinction,
        revision,
        transient_sky_light,
        transient_sky_tint
    )

static func clear(revision_value: int = 1) -> AtmosphericOptics:
    return AtmosphericOptics.new(1.0, 1.0, 1.0, 0.0, Color.WHITE, 0.0, 0.0, revision_value)

static func overcast(revision_value: int = 1) -> AtmosphericOptics:
    return AtmosphericOptics.new(0.78, 0.18, 0.96, 0.12, Color(0.91, 0.94, 1.0), 0.15, 0.08, revision_value)

static func rain(revision_value: int = 1) -> AtmosphericOptics:
    return AtmosphericOptics.new(0.70, 0.24, 0.90, 0.28, Color(0.87, 0.92, 1.0), 0.90, 0.16, revision_value)

static func fog(revision_value: int = 1) -> AtmosphericOptics:
    return AtmosphericOptics.new(0.62, 0.20, 0.82, 0.72, Color(0.92, 0.95, 0.97), 0.25, 0.55, revision_value)

static func storm(revision_value: int = 1) -> AtmosphericOptics:
    return AtmosphericOptics.new(0.38, 0.04, 0.76, 0.45, Color(0.78, 0.84, 0.94), 1.0, 0.36, revision_value)
