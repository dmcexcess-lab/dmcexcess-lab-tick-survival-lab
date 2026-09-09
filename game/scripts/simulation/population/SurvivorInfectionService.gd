extends RefCounted
class_name SurvivorInfectionService

## Minimal causal local transmission: successful melee contact from an infected
## adds deterministic exposure. Crossing the threshold changes the same resident
## identity into infected state; no replacement zombie is spawned.

signal survivor_infected(actor_id, source_actor_id, resident_record)

const EXPOSURE_THRESHOLD: int = 20

var _combat: CombatActionService = null
var _infected: InfectedState = null
var _survivors: SurvivorNpcState = null
var _health: ActorHealthState = null
var _kernel: TickKernel = null
var _exposure: Dictionary = {}

func _init(combat: CombatActionService = null, infected: InfectedState = null, survivors: SurvivorNpcState = null, health: ActorHealthState = null, kernel: TickKernel = null) -> void:
    _combat = combat
    _infected = infected
    _survivors = survivors
    _health = health
    _kernel = kernel
    if _combat != null:
        _combat.impact_resolved.connect(_on_impact_resolved)

func is_ready() -> bool:
    return _combat != null and _combat.is_ready() and _infected != null and _survivors != null and _health != null and _kernel != null

func exposure(actor_id: String) -> int:
    return int(_exposure.get(actor_id.strip_edges(), 0))

func _on_impact_resolved(attacker_id: String, target_id: String, _serial: int, _cell: Vector2i, damage: int, _contact_mode: String) -> void:
    if not is_ready() or damage <= 0 or not _infected.is_infected(attacker_id) or not _survivors.has_actor(target_id):
        return
    if not _health.has_actor(target_id) or _health.current_hp(target_id) <= 0:
        return
    var next := exposure(target_id) + 5 + damage * 2
    _exposure[target_id] = next
    if next >= EXPOSURE_THRESHOLD:
        _convert(target_id, attacker_id)

func force_exposure_for_verification(actor_id: String, source_actor_id: String, amount: int) -> bool:
    if amount <= 0 or not _survivors.has_actor(actor_id) or not _infected.is_infected(source_actor_id):
        return false
    _exposure[actor_id] = exposure(actor_id) + amount
    return _convert(actor_id, source_actor_id) if exposure(actor_id) >= EXPOSURE_THRESHOLD else true

func _convert(actor_id: String, source_actor_id: String) -> bool:
    if not _survivors.has_actor(actor_id) or _infected.is_infected(actor_id):
        return false
    var record := _survivors.resident_record(actor_id)
    record["infected"] = true
    record["infected_tick"] = _kernel.world_tick()
    record["infection_source_actor_id"] = source_actor_id
    if not _infected.record_hydration(actor_id, record):
        return false
    if not _survivors.remove_actor(actor_id, &"infected"):
        return false
    _exposure.erase(actor_id)
    survivor_infected.emit(actor_id, source_actor_id, record.duplicate(true))
    return true
