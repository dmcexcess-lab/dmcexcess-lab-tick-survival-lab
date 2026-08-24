extends Node2D
class_name TacticalRendererStack

const GroundRendererClass = preload("res://scripts/render/GroundLayerRenderer.gd")
const StructureRendererClass = preload("res://scripts/render/StructureLayerRenderer.gd")
const PropRendererClass = preload("res://scripts/render/PropLayerRenderer.gd")
const ActorRendererClass = preload("res://scripts/render/ActorLayerRenderer.gd")
const LightingRendererClass = preload("res://scripts/render/PhysicalLightingPresentationRenderer.gd")
const WeatherRendererClass = preload("res://scripts/render/WeatherPresentationRenderer.gd")
const PerceptionOverlayClass = preload("res://scripts/render/PerceptionOverlayRenderer.gd")

## Layer orchestration only. All drawing remains in the existing focused renderers.

var _ground: GroundLayerRenderer = null
var _structures: StructureLayerRenderer = null
var _props: PropLayerRenderer = null
var _actors: ActorLayerRenderer = null
var _lighting: PhysicalLightingPresentationRenderer = null
var _weather: WeatherPresentationRenderer = null
var _perception: PerceptionOverlayRenderer = null
var _configured: bool = false

func _ready() -> void:
    _ensure_layers()

func configure(
    world: WorldState,
    art_catalog: ArtCatalog,
    door_state: DoorStateStore,
    controlled_actor_id: String
) -> bool:
    _ensure_layers()
    if world == null or art_catalog == null or door_state == null:
        return false
    if not _ground.configure(world, art_catalog):
        return false
    if not _structures.configure(world, art_catalog, door_state):
        return false
    if not _props.configure(world, art_catalog):
        return false
    if not _actors.configure(world, art_catalog):
        return false
    if not _actors.set_controlled_actor_id(controlled_actor_id):
        return false
    _configured = true
    return true

func configure_physical_lighting(
    lighting_service: PhysicalLightingService,
    world: WorldState,
    door_state: DoorStateStore
) -> bool:
    _ensure_layers()
    return _lighting.configure(lighting_service, world, door_state)

func refresh_physical_lighting(reason: StringName = &"external") -> bool:
    _ensure_layers()
    if not _lighting.is_configured():
        return false
    return _lighting.refresh(reason)

func physical_lighting_debug_snapshot() -> Dictionary:
    _ensure_layers()
    return _lighting.presentation_snapshot()

func configure_weather(weather_service: WeatherService, sky_exposure: SkyExposureQuery) -> bool:
    _ensure_layers()
    return _weather.configure(weather_service, sky_exposure)

func set_camera_presentation(snapshot: Dictionary) -> bool:
    _ensure_layers()
    if not _weather.is_configured():
        return true
    var camera_value: Variant = snapshot.get("camera_global_position", null)
    if typeof(camera_value) != TYPE_VECTOR2:
        return false
    return _weather.set_camera_local_position(to_local(camera_value))

func force_weather_ambient_event(kind: StringName = &"leaf") -> bool:
    _ensure_layers()
    return _weather.force_ambient_event(kind)

func weather_debug_snapshot() -> Dictionary:
    _ensure_layers()
    return _weather.presentation_snapshot()

func configure_perception(
    perception_service: ObserverPerceptionService,
    memory_store: PerceptionMemoryStore,
    art_catalog: ArtCatalog,
    observer_id: String
) -> bool:
    _ensure_layers()
    return _perception.configure(perception_service, memory_store, art_catalog, observer_id)

func set_perception_ambient_light_level(level: float) -> bool:
    _ensure_layers()
    return _perception.set_ambient_light_level(level)

func set_auditory_cues(cues: Array) -> bool:
    _ensure_layers()
    return _perception.set_auditory_cues(cues)

func notify_observer_decision_unpaused() -> int:
    _ensure_layers()
    return _perception.notify_observer_decision_unpaused()

func perception_debug_snapshot() -> Dictionary:
    _ensure_layers()
    var result: Dictionary = _perception.planned_cell_counts()
    result["ambient_light_level"] = _perception.ambient_light_level()
    result["memory_luminance"] = _perception.memory_luminance()
    return result

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    _ensure_layers()
    if not _configured:
        return false
    var lighting_ok: bool = true
    if _lighting.is_configured():
        lighting_ok = _lighting.set_visible_window(origin, size_cells, cell_pixels)
    var weather_ok: bool = true
    if _weather.is_configured():
        weather_ok = _weather.set_visible_window(origin, size_cells, cell_pixels)
    return _ground.set_visible_window(origin, size_cells, cell_pixels) \
        and _structures.set_visible_window(origin, size_cells, cell_pixels) \
        and _props.set_visible_window(origin, size_cells, cell_pixels) \
        and _actors.set_visible_window(origin, size_cells, cell_pixels) \
        and lighting_ok \
        and weather_ok \
        and _perception.set_visible_window(origin, size_cells, cell_pixels)

func is_configured() -> bool:
    return _configured

func layer_command_counts() -> Dictionary:
    _ensure_layers()
    return {
        "ground": _ground.plan_visible_commands().size(),
        "structure": _structures.plan_visible_commands().size(),
        "prop": _props.plan_visible_commands().size(),
        "actor": _actors.plan_visible_commands().size(),
    }

func planned_diagnostic_counts() -> Dictionary:
    _ensure_layers()
    return {
        "ground": _count_diagnostics(_ground.plan_visible_commands()),
        "structure": _count_diagnostics(_structures.plan_visible_commands()),
        "prop": _count_diagnostics(_props.plan_visible_commands()),
        "actor": _count_diagnostics(_actors.plan_visible_commands()),
    }

func diagnostic_summary() -> Dictionary:
    _ensure_layers()
    return {
        "ground": _ground.diagnostic_reasons(),
        "structure": _structures.diagnostic_reasons(),
        "prop": _props.diagnostic_reasons(),
        "actor": _actors.diagnostic_reasons(),
    }

func _ensure_layers() -> void:
    if _ground != null:
        return
    _ground = GroundRendererClass.new()
    _ground.name = "Ground"
    _ground.z_index = 0
    add_child(_ground)

    _structures = StructureRendererClass.new()
    _structures.name = "Structures"
    _structures.z_index = 10
    add_child(_structures)

    _props = PropRendererClass.new()
    _props.name = "Props"
    _props.z_index = 20
    add_child(_props)

    _actors = ActorRendererClass.new()
    _actors.name = "Actors"
    _actors.z_index = 30
    add_child(_actors)

    _lighting = LightingRendererClass.new()
    _lighting.name = "PhysicalLighting"
    _lighting.z_index = 40
    add_child(_lighting)

    _weather = WeatherRendererClass.new()
    _weather.name = "Weather"
    _weather.z_index = 50
    add_child(_weather)

    _perception = PerceptionOverlayClass.new()
    _perception.name = "Perception"
    _perception.z_index = 100
    add_child(_perception)

static func _count_diagnostics(commands: Array) -> int:
    var count: int = 0
    for command: Variant in commands:
        if command != null and command.has_method("is_diagnostic") and bool(command.call("is_diagnostic")):
            count += 1
    return count
