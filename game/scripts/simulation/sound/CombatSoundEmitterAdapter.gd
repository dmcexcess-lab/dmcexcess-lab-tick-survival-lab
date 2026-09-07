extends RefCounted
class_name CombatSoundEmitterAdapter

const Profiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")

## Combat reports truthful physical phases; System 26 remains the sound owner.

var _world: WorldState = null
var _combat: CombatActionService = null
var _sound: SpatialSoundService = null

func _init(world: WorldState = null, combat: CombatActionService = null, sound: SpatialSoundService = null) -> void:
    _world = world
    _combat = combat
    _sound = sound
    if _combat != null:
        _combat.attack_contact.connect(_on_attack_contact)
        _combat.impact_resolved.connect(_on_impact_resolved)

func is_ready() -> bool:
    return _world != null and _combat != null and _combat.is_ready() and _sound != null and _sound.is_ready()

func _on_attack_contact(attacker_id: String, action_serial: int, _strike_cell: Vector2i, _item_id: String) -> void:
    if not is_ready():
        return
    var placement: WorldPlacement = _world.placement(attacker_id)
    if placement != null:
        _sound.emit_sound(Profiles.COMBAT_SWING, placement.anchor, attacker_id, "combat.swing.%s.%d" % [attacker_id, action_serial])

func _on_impact_resolved(attacker_id: String, target_id: String, action_serial: int, strike_cell: Vector2i, damage: int, _contact_mode: StringName) -> void:
    if not is_ready():
        return
    var power: int = 160 + mini(180, maxi(0, damage) * 12)
    _sound.emit_sound(Profiles.COMBAT_IMPACT, strike_cell, attacker_id, "combat.impact.%s.%s.%d" % [attacker_id, target_id, action_serial], power)
