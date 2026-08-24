extends VisualAcquisitionProvider
class_name IlluminationVisualAcquisitionProvider

const VisionRangePolicy = preload("res://scripts/simulation/lighting/VisionLightRangePolicy.gd")

## System 27 -> System 23 adapter. Physical lighting supplies target-cell
## luminance + atmospheric visibility; System 23 remains sole owner of observer
## knowledge/memory.
##
## The lighting service is a bounded query/cache context, not a camera-owned
## truth surface. Before an acquisition batch this adapter guarantees that the
## observer's full geometric vision envelope is inside the active light field.
## If the presentation window already contains that envelope, its cached field
## is reused; if the camera has panned elsewhere, gameplay temporarily requests
## its own observer-centered field instead.

var _lighting: PhysicalLightingService = null

func _init(lighting_service: PhysicalLightingService = null) -> void:
    _lighting = lighting_service

func is_ready() -> bool:
    # Field bounds are demand-owned and may not exist until the first observer
    # query. Having the injected lighting owner is enough to establish them.
    return _lighting != null

func allows_target(
    _observer_id: String,
    origin: Vector2i,
    target: Vector2i,
    profile: VisionProfile
) -> bool:
    if not is_ready() or profile == null or not profile.is_valid():
        return false
    if not _ensure_observer_field(origin, profile) or not _lighting.is_ready():
        return false
    var optics: AtmosphericOptics = _lighting.atmosphere()
    return VisionRangePolicy.target_within_visual_range(
        target - origin,
        _lighting.luminance_at(target),
        optics.visibility_extinction,
        profile.max_range,
        profile.near_awareness_radius
    )

func target_luminance(target: Vector2i) -> float:
    if _lighting == null or not _lighting.is_ready():
        return 0.0
    return _lighting.luminance_at(target)

func visibility_extinction() -> float:
    if _lighting == null:
        return 0.0
    return _lighting.atmosphere().visibility_extinction

func _ensure_observer_field(origin: Vector2i, profile: VisionProfile) -> bool:
    var radius: int = profile.max_range
    var required := Rect2i(
        origin - Vector2i(radius, radius),
        Vector2i(radius * 2 + 1, radius * 2 + 1)
    )
    var current: Rect2i = _lighting.field_bounds()
    if _rect_contains_rect(current, required):
        return true
    return _lighting.set_field_bounds(required)

static func _rect_contains_rect(container: Rect2i, required: Rect2i) -> bool:
    if container.size.x <= 0 or container.size.y <= 0 or required.size.x <= 0 or required.size.y <= 0:
        return false
    var required_last: Vector2i = required.position + required.size - Vector2i.ONE
    return container.has_point(required.position) and container.has_point(required_last)
