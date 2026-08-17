extends RefCounted
class_name MovementRunImpactDamageService

## Stateless Movement -> Health coordination for System 17A hard Run impacts.
## Movement owns impact facts. Health owns HP truth.

const IMPACT_DAMAGE_HP: int = 5

var _movement: MovementActionService = null
var _health: ActorHealthState = null

func _init(
    movement_service: MovementActionService = null,
    health_state: ActorHealthState = null
) -> void:
    _movement = movement_service
    _health = health_state
    if _movement != null and not _movement.run_impact.is_connected(_on_run_impact):
        _movement.run_impact.connect(_on_run_impact)

func is_ready() -> bool:
    return _movement != null and _health != null

func _on_run_impact(
    actor_id: String,
    _action_serial: int,
    _stride_index: int,
    _target_anchor: Vector2i,
    _target_facing: int,
    _blocking_entity_ids: Array
) -> void:
    if not is_ready() or not _health.has_actor(actor_id):
        return
    _health.apply_damage(actor_id, IMPACT_DAMAGE_HP)
