extends Node
class_name PlayerMapBootstrap

const IslandFixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

var _configured: bool = false
var _failure_reason: String = ""

func _ready() -> void:
    call_deferred("_configure_from_composition_root")

func is_configured() -> bool:
    return _configured

func failure_reason() -> String:
    return _failure_reason

func _configure_from_composition_root() -> void:
    var composition_root: Node = get_parent()
    if composition_root == null:
        _fail("missing composition root")
        return
    var camera_controls := composition_root.get_node_or_null("CameraControls") as CameraControls
    var world: WorldState = composition_root.get("_world") as WorldState
    var plan: GeneratedGlobalWorldPlan = IslandFixture.global_plan()
    if camera_controls == null:
        _fail("missing CameraControls")
        return
    if world == null:
        _fail("canonical WorldState was not booted")
        return
    if plan == null or not plan.is_generated():
        _fail("generated island plan was not booted")
        return
    if not camera_controls.configure_map(plan, world, IslandFixture.PLAYER_ID):
        _fail("CameraControls rejected canonical island map configuration")
        return
    _configured = true
    _failure_reason = ""

func _fail(reason: String) -> void:
    _configured = false
    _failure_reason = reason
    push_error("PlayerMapBootstrap: %s" % reason)
