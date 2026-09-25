extends RefCounted
class_name ActorFearPressureService

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const ModifierClass = preload("res://scripts/simulation/actors/condition/ActorConditionModifierQuery.gd")

## Canonical current-timestamp fear consequence owner.
## Observation adapters submit pressure; this service applies at most one Calm
## mutation per actor after same-timestamp spatial/combat consequences have settled.

signal fear_resolved(actor_id, pressure, calm_before, calm_after, tier_before, tier_after, sources, world_tick)

const FLUSH_EVENT: StringName = &"condition.fear.flush"
const FLUSH_OWNER: String = "when.zzz.condition.fear"
const FLUSH_PRIORITY: int = 2147483647
const MAX_PRESSURE_PER_TICK: int = 20

var _condition: ActorConditionService = null
var _modifiers: ActorConditionModifierQuery = null
var _kernel: TickKernel = null
var _pending_by_tick: Dictionary = {}
var _flush_serial_by_tick: Dictionary = {}

func _init(
    condition_service: ActorConditionService = null,
    modifier_query: ActorConditionModifierQuery = null,
    kernel: TickKernel = null
) -> void:
    _condition = condition_service
    _modifiers = modifier_query
    _kernel = kernel
    if _kernel != null:
        var due := Callable(self, "_on_external_event_due")
        if not _kernel.external_event_due.is_connected(due):
            _kernel.external_event_due.connect(due)
        var reset := Callable(self, "_on_timing_state_reset")
        if not _kernel.timing_state_reset.is_connected(reset):
            _kernel.timing_state_reset.connect(reset)

func is_ready() -> bool:
    return _condition != null and _condition.is_ready()         and _modifiers != null and _modifiers.is_ready() and _kernel != null

func queue_pressure(
    actor_id: String,
    pressure: int,
    source: StringName = &"fear_pressure"
) -> bool:
    var actor: String = actor_id.strip_edges()
    if not is_ready() or actor.is_empty() or not _condition.has_actor(actor) or pressure <= 0:
        return false
    var tick: int = _kernel.world_tick()
    var tick_pending: Dictionary = (_pending_by_tick.get(tick, {}) as Dictionary).duplicate(true)
    var entry: Dictionary = (tick_pending.get(actor, {}) as Dictionary).duplicate(true)
    entry["pressure"] = int(entry.get("pressure", 0)) + pressure
    var sources: Dictionary = (entry.get("sources", {}) as Dictionary).duplicate(true)
    sources[String(source)] = int(sources.get(String(source), 0)) + pressure
    entry["sources"] = sources
    tick_pending[actor] = entry
    _pending_by_tick[tick] = tick_pending
    return _ensure_flush(tick)

func pending_pressure(actor_id: String, world_tick: int = -1) -> int:
    var tick: int = _kernel.world_tick() if world_tick < 0 and _kernel != null else world_tick
    var tick_pending: Dictionary = _pending_by_tick.get(tick, {})
    var entry: Dictionary = tick_pending.get(actor_id.strip_edges(), {})
    return int(entry.get("pressure", 0))

func _ensure_flush(tick: int) -> bool:
    if _flush_serial_by_tick.has(tick):
        return true
    var serial: int = _kernel.schedule_event(
        tick,
        FLUSH_OWNER,
        FLUSH_EVENT,
        "",
        {"tick": tick},
        FLUSH_PRIORITY
    )
    if serial <= 0:
        return false
    _flush_serial_by_tick[tick] = serial
    return true

func _on_external_event_due(event: ScheduledEvent) -> void:
    if event == null or event.event_type != FLUSH_EVENT:
        return
    var tick: int = int(event.payload.get("tick", -1))
    if tick < 0 or int(_flush_serial_by_tick.get(tick, 0)) != event.serial:
        return
    _flush_serial_by_tick.erase(tick)
    _flush_tick(tick)

func _flush_tick(tick: int) -> void:
    var pending_value: Variant = _pending_by_tick.get(tick, {})
    _pending_by_tick.erase(tick)
    if typeof(pending_value) != TYPE_DICTIONARY:
        return
    var pending: Dictionary = pending_value
    var actor_ids: Array[String] = []
    for key: Variant in pending.keys():
        actor_ids.append(String(key))
    actor_ids.sort()
    for actor_id: String in actor_ids:
        if not _condition.has_actor(actor_id):
            continue
        var entry: Dictionary = pending.get(actor_id, {})
        var pressure: int = mini(MAX_PRESSURE_PER_TICK, maxi(0, int(entry.get("pressure", 0))))
        if pressure <= 0:
            continue
        var calm_before: int = _condition.value(actor_id, StateClass.CALM)
        var tier_before: StringName = _modifiers.fear_tier(actor_id)
        if calm_before < 0 or not _condition.change_condition(actor_id, StateClass.CALM, -pressure, &"fear_pressure"):
            continue
        var calm_after: int = _condition.value(actor_id, StateClass.CALM)
        var tier_after: StringName = _modifiers.fear_tier(actor_id)
        var source_keys: Array[String] = []
        var sources: Dictionary = entry.get("sources", {})
        for source_value: Variant in sources.keys():
            source_keys.append(String(source_value))
        source_keys.sort()
        fear_resolved.emit(
            actor_id,
            pressure,
            calm_before,
            calm_after,
            tier_before,
            tier_after,
            source_keys,
            tick
        )

func _on_timing_state_reset() -> void:
    _pending_by_tick.clear()
    _flush_serial_by_tick.clear()
