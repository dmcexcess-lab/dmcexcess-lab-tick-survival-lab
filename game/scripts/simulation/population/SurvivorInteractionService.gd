extends RefCounted
class_name SurvivorInteractionService

var _world: WorldState = null
var _state: SurvivorNpcState = null
var _infected: InfectedState = null
var _health: ActorHealthState = null

func _init(world: WorldState = null, state: SurvivorNpcState = null, infected: InfectedState = null, health: ActorHealthState = null) -> void:
    _world = world
    _state = state
    _infected = infected
    _health = health

func is_ready() -> bool:
    return _world != null and _state != null and _infected != null and _health != null

func request_action(_actor_id: String, target_id: String, action_id: StringName) -> Dictionary:
    if not is_ready() or not _state.has_actor(target_id) or not _health.has_actor(target_id) or _health.current_hp(target_id) <= 0:
        return {"success": false, "reason": "survivor_unavailable"}
    var role := _state.role(target_id)
    if action_id == SurvivorInteractionOfferProvider.TALK:
        if role == SurvivorNpcState.RAIDER:
            return {"success": false, "reason": "They are hostile."}
        return {"success": true, "reason": conversation_line(target_id)}
    if action_id == SurvivorInteractionOfferProvider.RECRUIT:
        if role != SurvivorNpcState.NEUTRAL or not _state.set_role(target_id, SurvivorNpcState.FOLLOWER):
            return {"success": false, "reason": "They will not follow."}
        return {"success": true, "reason": "They agree to follow you."}
    if action_id == SurvivorInteractionOfferProvider.DISMISS:
        if role != SurvivorNpcState.FOLLOWER or not _state.set_role(target_id, SurvivorNpcState.NEUTRAL):
            return {"success": false, "reason": "They are not following you."}
        return {"success": true, "reason": "They will wait here."}
    return {"success": false, "reason": "unsupported_survivor_action"}

func conversation_line(target_id: String) -> String:
    if not _state.has_actor(target_id):
        return "No answer."
    if _health.current_hp(target_id) * 2 <= _health.max_hp(target_id):
        return "I'm hurt. We need somewhere safe."
    var placement: WorldPlacement = _world.placement(target_id)
    if placement != null:
        for infected_id: String in _infected.actor_ids():
            var other: WorldPlacement = _world.placement(infected_id)
            if other == null:
                continue
            var distance := absi(other.anchor.x - placement.anchor.x) + absi(other.anchor.y - placement.anchor.y)
            if distance <= 6:
                return "Keep your voice down. They're close."
    if _state.role(target_id) == SurvivorNpcState.FOLLOWER:
        return "I'm with you. Lead the way."
    return "I've been keeping low. Are you alone?"
