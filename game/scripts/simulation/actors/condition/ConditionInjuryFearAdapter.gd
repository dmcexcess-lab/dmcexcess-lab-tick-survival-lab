extends RefCounted
class_name ConditionInjuryFearAdapter

## Health -> fear-pressure seam. Injury creates a bounded shock pulse; it does
## not directly mutate Calm and therefore aggregates with all other same-tick fear.

var _health: ActorHealthState = null
var _fear: ActorFearPressureService = null
var _actor_id: String = ""

func _init(
    health_state: ActorHealthState = null,
    fear_service: ActorFearPressureService = null,
    actor_id: String = ""
) -> void:
    _health = health_state
    _fear = fear_service
    _actor_id = actor_id.strip_edges()
    if _health != null:
        var callable := Callable(self, "_on_damage_applied")
        if not _health.damage_applied.is_connected(callable):
            _health.damage_applied.connect(callable)

func is_ready() -> bool:
    return _health != null and _fear != null and _fear.is_ready()         and not _actor_id.is_empty() and _health.has_actor(_actor_id)

func _on_damage_applied(
    actor_id: String,
    amount: int,
    _previous_hp: int,
    _current_hp: int,
    _version: int
) -> void:
    if not is_ready() or actor_id != _actor_id or amount <= 0:
        return
    _fear.queue_pressure(_actor_id, pressure_for_damage(amount), &"injury_shock")

static func pressure_for_damage(amount: int) -> int:
    if amount <= 0:
        return 0
    return clampi(2 + int(ceili(float(amount) / 2.0)), 3, 12)
