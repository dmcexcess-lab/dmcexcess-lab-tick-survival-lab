extends RefCounted
class_name FirearmSoundEmitterAdapter

const Profiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")

## Firearm discharge is a truthful System-26 emission. The event identity is gunshot-specific;
## the existing combat acoustic vocabulary supplies recognition/category while source power is overridden.

var _firearms: FirearmActionService = null
var _sound: SpatialSoundService = null

func _init(firearms: FirearmActionService = null, sound: SpatialSoundService = null) -> void:
    _firearms = firearms
    _sound = sound
    if _firearms != null: _firearms.firearm_discharged.connect(_on_discharge)

func is_ready() -> bool:
    return _firearms != null and _firearms.is_ready() and _sound != null and _sound.is_ready()

func _on_discharge(actor_id: String, serial: int, _firearm_id: String, _round_id: String, cell: Vector2i, power: int) -> void:
    if not is_ready(): return
    _sound.emit_sound(Profiles.COMBAT_IMPACT, cell, actor_id, "combat.gunshot.%s.%d" % [actor_id, serial], power)
