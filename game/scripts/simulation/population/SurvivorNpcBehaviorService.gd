extends CohortInfectedBehaviorService
class_name SurvivorNpcBehaviorService

## Reuses the proven event-driven movement/perception/combat adapter, but replaces
## infected intention policy with survivor roles. No second clock or AI scheduler.

const NPC_IDLE: StringName = &"survivor.idle"
const FOLLOW_PLAYER: StringName = &"survivor.follow_player"
const RAID_PURSUE_VISIBLE: StringName = &"raider.pursue_visible"
const RAID_PURSUE_LAST_SEEN: StringName = &"raider.pursue_last_seen"
const RAID_INVESTIGATE_SOUND: StringName = &"raider.investigate_sound"
const RAID_ATTACK_VISIBLE: StringName = &"raider.attack_visible"

var _npc_state: SurvivorNpcState = null

func configure_survivor_state(state: SurvivorNpcState) -> bool:
    if state == null:
        return false
    _npc_state = state
    return true

func is_ready() -> bool:
    if _npc_state == null or _world == null or _kernel == null or _perception == null or _sound == null \
        or _movement == null or _combat == null or _health == null or _actor_id.is_empty() or _player_id.is_empty():
        return false
    if not _npc_state.has_actor(_actor_id) or _infected.is_infected(_actor_id):
        return false
    if not _movement.is_ready() or not _combat.is_ready() or not _sound.is_ready() or not _perception.is_ready():
        return false
    if _perception.observer_id() != _actor_id or not _health.has_actor(_actor_id) or _health.current_hp(_actor_id) <= 0:
        return false
    var placement: WorldPlacement = _world.placement(_actor_id)
    return placement != null and placement.channel == SpatialLayer.Channel.ACTOR and SpatialFacing.is_valid(placement.facing)

func _refresh_intention(_reason: StringName) -> void:
    var role := _npc_state.role(_actor_id)
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null:
        return
    if role == SurvivorNpcState.FOLLOWER:
        var leader: WorldPlacement = _world.placement(_player_id)
        if leader != null:
            var distance := absi(leader.anchor.x - placement.anchor.x) + absi(leader.anchor.y - placement.anchor.y)
            if distance > 2:
                _reset_detour_if_target_changed(leader.anchor)
                _set_intention(FOLLOW_PLAYER, leader.anchor, _player_id, _kernel.world_tick())
                return
        _clear_detour()
        _set_intention(NPC_IDLE, placement.anchor, "", _kernel.world_tick())
        return
    if role != SurvivorNpcState.RAIDER:
        _clear_detour()
        _set_intention(NPC_IDLE, placement.anchor, "", _kernel.world_tick())
        return
    var visual: Dictionary = _current_visual_player_observation()
    if not visual.is_empty():
        var visual_cell: Vector2i = visual.get("cell", Vector2i.ZERO)
        var visual_tick: int = int(visual.get("observed_tick", _kernel.world_tick()))
        _reset_detour_if_target_changed(visual_cell)
        if _visible_target_is_in_forward_contact(visual_cell):
            _set_intention(RAID_ATTACK_VISIBLE, visual_cell, _player_id, visual_tick)
        else:
            _set_intention(RAID_PURSUE_VISIBLE, visual_cell, _player_id, visual_tick)
        return
    var remembered: Dictionary = _perception.memory_store().last_seen_actor(_actor_id, _player_id)
    if not remembered.is_empty():
        var remembered_cell: Vector2i = remembered.get("cell", Vector2i.ZERO)
        if placement.anchor != remembered_cell:
            _reset_detour_if_target_changed(remembered_cell)
            _set_intention(RAID_PURSUE_LAST_SEEN, remembered_cell, _player_id, int(remembered.get("observed_tick", -1)))
            return
    if _intention == RAID_INVESTIGATE_SOUND and placement.anchor != _target_cell:
        return
    var heard: HeardSoundObservation = _best_heard_observation()
    if heard != null and heard.perceived_cell != placement.anchor:
        _reset_detour_if_target_changed(heard.perceived_cell)
        _set_intention(RAID_INVESTIGATE_SOUND, heard.perceived_cell, "", heard.heard_tick)
        return
    _clear_detour()
    _set_intention(NPC_IDLE, placement.anchor, "", _kernel.world_tick())

func _submit_for_current_intention() -> void:
    if _intention == RAID_ATTACK_VISIBLE:
        if _submit_attack():
            return
        _set_intention(RAID_PURSUE_VISIBLE, _target_cell, _target_actor_id, _observed_tick)
    if _intention in [FOLLOW_PLAYER, RAID_PURSUE_VISIBLE, RAID_PURSUE_LAST_SEEN, RAID_INVESTIGATE_SOUND]:
        _submit_move_toward(_target_cell)

func _living_actor_available() -> bool:
    if _npc_state == null or not _npc_state.has_actor(_actor_id) or _infected.is_infected(_actor_id) \
        or not _health.has_actor(_actor_id) or _health.current_hp(_actor_id) <= 0:
        return false
    var placement: WorldPlacement = _world.placement(_actor_id)
    return placement != null and placement.channel == SpatialLayer.Channel.ACTOR
