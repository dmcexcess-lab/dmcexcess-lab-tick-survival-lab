extends Node2D
class_name TacticalRendererStack

const GroundRendererClass = preload("res://scripts/render/GroundLayerRenderer.gd")
const StructureRendererClass = preload("res://scripts/render/StructureLayerRenderer.gd")
const PropRendererClass = preload("res://scripts/render/PropLayerRenderer.gd")
const ActorRendererClass = preload("res://scripts/render/ActorLayerRenderer.gd")

## Layer orchestration only. All drawing remains in the existing focused renderers.

var _ground: GroundLayerRenderer = null
var _structures: StructureLayerRenderer = null
var _props: PropLayerRenderer = null
var _actors: ActorLayerRenderer = null
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

func set_visible_window(origin: Vector2i, size_cells: Vector2i, cell_pixels: float) -> bool:
    _ensure_layers()
    if not _configured:
        return false
    return _ground.set_visible_window(origin, size_cells, cell_pixels) \
        and _structures.set_visible_window(origin, size_cells, cell_pixels) \
        and _props.set_visible_window(origin, size_cells, cell_pixels) \
        and _actors.set_visible_window(origin, size_cells, cell_pixels)

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
