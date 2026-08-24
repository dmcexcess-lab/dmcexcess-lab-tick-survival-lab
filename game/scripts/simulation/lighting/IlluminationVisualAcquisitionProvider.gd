extends VisualAcquisitionProvider
class_name IlluminationVisualAcquisitionProvider

## System 27 -> System 23 adapter. Physical lighting supplies target-cell
## useful range; System 23 remains sole owner of observer knowledge/memory.

var _lighting: PhysicalLightingService = null

func _init(lighting_service: PhysicalLightingService = null) -> void:
    _lighting = lighting_service

func is_ready() -> bool:
    return _lighting != null and _lighting.is_ready()

func allows_target(
    _observer_id: String,
    origin: Vector2i,
    target: Vector2i,
    profile: VisionProfile
) -> bool:
    if not is_ready() or profile == null or not profile.is_valid():
        return false
    return _lighting.target_within_light_range(
        origin,
        target,
        profile.max_range,
        profile.near_awareness_radius
    )

func target_luminance(target: Vector2i) -> float:
    if not is_ready():
        return 0.0
    return _lighting.luminance_at(target)
