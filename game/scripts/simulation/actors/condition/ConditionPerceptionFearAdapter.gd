extends RefCounted
class_name ConditionPerceptionFearAdapter

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## Visible-threat -> canonical fear-pressure adapter.
## It records encounter threat bands so repeated perception refreshes do not
## repeatedly charge the same danger. Only a worse band or a meaningfully new
## encounter produces new visual fear pressure.

const BAND_FAR: int = 1
const BAND_NEAR: int = 2
const BAND_CLOSE: int = 3
const BAND_CONTACT: int = 4
const ENCOUNTER_RESET_MINUTES: int = 5

const BAND_PRESSURE: Dictionary = {
    BAND_FAR: 2,
    BAND_NEAR: 4,
    BAND_CLOSE: 7,
    BAND_CONTACT: 12,
}
const DIMINISHING_BP: Array[int] = [10000, 6000, 3500, 2000, 1500]

var _world: WorldState = null
var _perception: ObserverPerceptionService = null
var _fear: ActorFearPressureService = null
var _kernel: TickKernel = null
var _time_profile: WorldTimeProfile = null
var _actor_id: String = ""
var _visible_threats: Dictionary = {}
var _highest_band_by_threat: Dictionary = {}
var _threat_free_since_tick: int = -1

func _init(
    world_state: WorldState = null,
    perception_service: ObserverPerceptionService = null,
    fear_service: ActorFearPressureService = null,
    kernel: TickKernel = null,
    time_profile: WorldTimeProfile = null,
    actor_id: String = ""
) -> void:
    _world = world_state
    _perception = perception_service
    _fear = fear_service
    _kernel = kernel
    _time_profile = time_profile
    _actor_id = actor_id.strip_edges()
    if _perception != null:
        var callable := Callable(self, "_on_perception_changed")
        if not _perception.perception_changed.is_connected(callable):
            _perception.perception_changed.connect(callable)
    _refresh_visible_threats()

func is_ready() -> bool:
    return _world != null and _perception != null and _perception.is_ready()         and _fear != null and _fear.is_ready() and _kernel != null         and _time_profile != null and _time_profile.is_valid()         and not _actor_id.is_empty()

func visible_threat_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _visible_threats.keys():
        result.append(String(key))
    result.sort()
    return result

func _on_perception_changed(_reason: StringName) -> void:
    _refresh_visible_threats()

func _refresh_visible_threats() -> void:
    if not is_ready():
        return
    var observer: WorldPlacement = _world.placement(_actor_id)
    if observer == null:
        return

    var now: int = _kernel.world_tick()
    var current: Dictionary = {}
    var worsened: Array[Dictionary] = []

    for cell: Vector2i in _perception.visible_cells():
        for entity_id: String in _world.entities_at(cell, Layers.Channel.ACTOR):
            if entity_id == _actor_id or current.has(entity_id):
                continue
            var entity: WorldEntityRecord = _world.entity(entity_id)
            var placement: WorldPlacement = _world.placement(entity_id)
            if entity == null or placement == null or entity.semantic_type != &"actor.infected":
                continue
            if not _perception.is_visible(placement.anchor):
                continue
            current[entity_id] = true
            var band: int = _band_for_distance(_chebyshev(observer.anchor, placement.anchor))
            var previous: int = int(_highest_band_by_threat.get(entity_id, 0))
            if band > previous:
                worsened.append({
                    "actor_id": entity_id,
                    "pressure": int(BAND_PRESSURE.get(band, 0)) - int(BAND_PRESSURE.get(previous, 0)),
                    "band": band,
                })
                _highest_band_by_threat[entity_id] = band

    if current.is_empty():
        if not _visible_threats.is_empty() and _threat_free_since_tick < 0:
            _threat_free_since_tick = now
    else:
        if _threat_free_since_tick >= 0:
            var reset_ticks: int = _time_profile.ticks_per_minute() * ENCOUNTER_RESET_MINUTES
            if now - _threat_free_since_tick >= reset_ticks:
                _highest_band_by_threat.clear()
                # Re-evaluate current threats as a genuinely new encounter.
                worsened.clear()
                for entity_id: String in _sorted_keys(current):
                    var placement: WorldPlacement = _world.placement(entity_id)
                    if placement == null:
                        continue
                    var band: int = _band_for_distance(_chebyshev(observer.anchor, placement.anchor))
                    worsened.append({
                        "actor_id": entity_id,
                        "pressure": int(BAND_PRESSURE.get(band, 0)),
                        "band": band,
                    })
                    _highest_band_by_threat[entity_id] = band
            _threat_free_since_tick = -1

    _visible_threats = current
    if worsened.is_empty():
        return

    worsened.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var pa: int = int(a.get("pressure", 0))
        var pb: int = int(b.get("pressure", 0))
        if pa != pb:
            return pa > pb
        return String(a.get("actor_id", "")) < String(b.get("actor_id", ""))
    )
    var total: int = 0
    for index: int in range(worsened.size()):
        var weight_bp: int = DIMINISHING_BP[mini(index, DIMINISHING_BP.size() - 1)]
        total += int(ceili(float(int(worsened[index].get("pressure", 0)) * weight_bp) / 10000.0))
    if total > 0:
        _fear.queue_pressure(_actor_id, total, &"visible_infected_threat")

static func _band_for_distance(distance: int) -> int:
    if distance <= 1:
        return BAND_CONTACT
    if distance <= 3:
        return BAND_CLOSE
    if distance <= 6:
        return BAND_NEAR
    return BAND_FAR

static func _chebyshev(a: Vector2i, b: Vector2i) -> int:
    var delta: Vector2i = a - b
    return maxi(absi(delta.x), absi(delta.y))

static func _sorted_keys(values: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for key: Variant in values.keys():
        result.append(String(key))
    result.sort()
    return result
