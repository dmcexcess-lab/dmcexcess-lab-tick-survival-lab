extends Node
class_name SimpleTurnController

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

signal action_resolved(intent: StringName, success: bool, reason: String, turn_number: int)
signal action_busy_changed(busy: bool)
signal turn_completed(turn_number: int, active_actor_count: int)

const ACTIVE_RADIUS: int = 24

var _world: WorldState
var _mutations: WorldMutationService
var _spatial: SpatialQueryService
var _player_id: String
var _infected_ids: Array[String] = []
var _turn_number := 0
var _busy := false
var _individual_actor_actions := 0

func _init(world: WorldState = null, mutations: WorldMutationService = null, spatial: SpatialQueryService = null, player_id: String = "") -> void:
    _world = world
    _mutations = mutations
    _spatial = spatial
    _player_id = player_id

func is_ready() -> bool:
    return _world != null and _mutations != null and _spatial != null and not _player_id.is_empty() and _world.placement(_player_id) != null

func has_control() -> bool:
    return is_ready() and not _busy

func turn_number() -> int:
    return _turn_number

func individual_actor_actions() -> int:
    return _individual_actor_actions

func set_infected_actor_ids(ids: Array[String]) -> void:
    _infected_ids.clear()
    for actor_id in ids:
        if not actor_id.is_empty() and actor_id != _player_id and not _infected_ids.has(actor_id):
            _infected_ids.append(actor_id)
    _infected_ids.sort()

func submit_intent(intent: StringName) -> void:
    if not has_control():
        return
    if not Intents.is_movement(intent):
        action_resolved.emit(intent, false, "not_migrated_to_simple_turns", _turn_number)
        return
    _set_busy(true)
    var success := _resolve_player_movement(intent)
    if not success:
        _set_busy(false)
        action_resolved.emit(intent, false, "movement_blocked", _turn_number)
        return
    _turn_number += 1
    var acted := _run_local_infected_turns()
    turn_completed.emit(_turn_number, acted)
    action_resolved.emit(intent, true, "", _turn_number)
    _set_busy(false)

func _resolve_player_movement(intent: StringName) -> bool:
    var current := _world.placement(_player_id)
    if current == null:
        return false
    var target_anchor := current.anchor
    var target_facing := current.facing
    match intent:
        Intents.TURN_LEFT:
            target_facing = Facing.turn_left(current.facing)
        Intents.TURN_RIGHT:
            target_facing = Facing.turn_right(current.facing)
        Intents.FORWARD, Intents.RUN_FORWARD:
            target_anchor += Facing.vector(current.facing)
        Intents.BACKWARD:
            target_anchor -= Facing.vector(current.facing)
        _:
            return false
    if target_anchor != current.anchor:
        var query := _spatial.query_entity_footprint(_player_id, target_anchor, target_facing, true)
        if query == null or not query.is_clear():
            return false
    return _mutations.set_placement(_player_id, current.channel, target_anchor, target_facing, current.footprint, current.structure_axis)

func _run_local_infected_turns() -> int:
    var player := _world.placement(_player_id)
    if player == null:
        return 0
    var acted := 0
    for actor_id in _infected_ids:
        var placement := _world.placement(actor_id)
        if placement == null:
            continue
        var delta := player.anchor - placement.anchor
        if maxi(abs(delta.x), abs(delta.y)) > ACTIVE_RADIUS:
            continue
        var step := _greedy_step(delta)
        if step == Vector2i.ZERO:
            continue
        var target := placement.anchor + step
        var facing := Facing.from_vector(step)
        var query := _spatial.query_entity_footprint(actor_id, target, facing, true)
        if query == null or not query.is_clear():
            continue
        if _mutations.set_placement(actor_id, placement.channel, target, facing, placement.footprint, placement.structure_axis):
            acted += 1
            _individual_actor_actions += 1
    return acted

func _greedy_step(delta: Vector2i) -> Vector2i:
    if delta == Vector2i.ZERO:
        return Vector2i.ZERO
    if abs(delta.x) >= abs(delta.y) and delta.x != 0:
        return Vector2i(signi(delta.x), 0)
    if delta.y != 0:
        return Vector2i(0, signi(delta.y))
    return Vector2i.ZERO

func _set_busy(value: bool) -> void:
    if value == _busy:
        return
    _busy = value
    action_busy_changed.emit(value)
