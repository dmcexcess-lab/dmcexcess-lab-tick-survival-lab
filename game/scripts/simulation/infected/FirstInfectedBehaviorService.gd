extends RefCounted
class_name FirstInfectedBehaviorService

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const CombatActions = preload("res://scripts/simulation/combat/CombatActionService.gd")

## First resident-backed infected behavior adapter.
##
## This service owns only intention selection. It owns no second clock, movement,
## perception, hearing, health, collision, or combat truth. It consumes the
## infected actor's observer-scoped System-23/System-26 knowledge and submits
## ordinary actor actions to the existing WHEN/movement/combat owners.

signal intention_changed(actor_id, intention, target_cell, target_actor_id, observed_tick)
signal action_submitted(actor_id, action_serial, action_type, intention, target_cell)
signal behavior_stopped(actor_id, reason)

const IDLE: StringName = &"infected.idle"
const PURSUE_VISIBLE: StringName = &"infected.pursue_visible"
const PURSUE_LAST_SEEN: StringName = &"infected.pursue_last_seen"
const INVESTIGATE_SOUND: StringName = &"infected.investigate_sound"
const ATTACK_VISIBLE: StringName = &"infected.attack_visible"

const MAX_HISTORY: int = 32

var _world: WorldState = null
var _kernel: TickKernel = null
var _infected: InfectedState = null
var _perception: ObserverPerceptionService = null
var _sound: SpatialSoundService = null
var _movement: MovementActionService = null
var _combat: CombatActionService = null
var _health: ActorHealthState = null
var _actor_id: String = ""
var _player_id: String = ""

var _running: bool = false
var _recompute_guard: bool = false
var _intention: StringName = IDLE
var _target_cell: Vector2i = Vector2i.ZERO
var _target_actor_id: String = ""
var _observed_tick: int = -1
var _action_history: Array[Dictionary] = []
var _detour_facing: int = -1
var _detour_target: Vector2i = Vector2i.ZERO
var _detour_attempted_right: bool = false

func _init(
    world: WorldState = null,
    kernel: TickKernel = null,
    infected_state: InfectedState = null,
    perception: ObserverPerceptionService = null,
    sound: SpatialSoundService = null,
    movement: MovementActionService = null,
    combat: CombatActionService = null,
    health: ActorHealthState = null,
    actor_id: String = "",
    player_id: String = ""
) -> void:
    _world = world
    _kernel = kernel
    _infected = infected_state
    _perception = perception
    _sound = sound
    _movement = movement
    _combat = combat
    _health = health
    _actor_id = actor_id.strip_edges()
    _player_id = player_id.strip_edges()
    _connect_signals()

func is_ready() -> bool:
    if _world == null or _kernel == null or _infected == null or _perception == null \
        or _sound == null or _movement == null or _combat == null or _health == null:
        return false
    if _actor_id.is_empty() or _player_id.is_empty() or _actor_id == _player_id:
        return false
    if not _movement.is_ready() or not _combat.is_ready() or not _sound.is_ready() or not _perception.is_ready():
        return false
    if _perception.observer_id() != _actor_id or not _infected.is_infected(_actor_id):
        return false
    if not _health.has_actor(_actor_id) or _health.current_hp(_actor_id) <= 0:
        return false
    var placement: WorldPlacement = _world.placement(_actor_id)
    return placement != null and placement.channel == Layers.Channel.ACTOR and Facing.is_valid(placement.facing)

func start() -> bool:
    if _running:
        return true
    if not is_ready():
        return false
    _running = true
    _drive(&"behavior_started")
    return true

func is_running() -> bool:
    return _running

func actor_id() -> String:
    return _actor_id

func current_intention() -> StringName:
    return _intention

func target_cell() -> Vector2i:
    return _target_cell

func target_actor_id() -> String:
    return _target_actor_id

func observed_tick() -> int:
    return _observed_tick

func action_history() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for entry: Dictionary in _action_history:
        result.append(entry.duplicate(true))
    return result

func action_submission_count() -> int:
    return _action_history.size()

func _connect_signals() -> void:
    if _kernel != null:
        var started := Callable(self, "_on_action_started")
        var finished := Callable(self, "_on_action_finished")
        if not _kernel.action_started.is_connected(started):
            _kernel.action_started.connect(started)
        if not _kernel.action_finished.is_connected(finished):
            _kernel.action_finished.connect(finished)
    if _perception != null:
        var changed := Callable(self, "_on_perception_changed")
        if not _perception.perception_changed.is_connected(changed):
            _perception.perception_changed.connect(changed)
    if _sound != null:
        var heard := Callable(self, "_on_sound_observations_changed")
        if not _sound.listener_observations_changed.is_connected(heard):
            _sound.listener_observations_changed.connect(heard)
    if _health != null:
        var hp := Callable(self, "_on_hp_changed")
        if not _health.hp_changed.is_connected(hp):
            _health.hp_changed.connect(hp)

func _on_action_started(action: TimedAction) -> void:
    if not _running or action == null:
        return
    # Player commitment opens the shared WHEN clock. If the infected is ready,
    # choose and submit its ordinary action at the same current world tick.
    if action.actor_id == _player_id:
        _drive(&"player_action_started")

func _on_action_finished(action: TimedAction) -> void:
    if not _running or action == null:
        return
    if action.actor_id == _actor_id:
        _drive(&"infected_action_finished")

func _on_perception_changed(_reason: StringName) -> void:
    if not _running or _recompute_guard:
        return
    _drive(&"perception_changed", false)

func _on_sound_observations_changed(listener_id: String) -> void:
    if not _running or listener_id != _actor_id:
        return
    _drive(&"sound_observation_changed", false)

func _on_hp_changed(actor_id: String, _previous_hp: int, current_hp: int, _max_hp: int, _version: int) -> void:
    if not _running or actor_id != _actor_id:
        return
    if current_hp <= 0:
        _stop(&"dead")

func _drive(reason: StringName, refresh_perception: bool = true) -> void:
    if not _running:
        return
    if not _living_actor_available():
        _stop(&"actor_unavailable")
        return
    if refresh_perception and not _recompute_guard:
        _recompute_guard = true
        _perception.recompute(&"infected_behavior_decision")
        _recompute_guard = false
    _refresh_intention(reason)
    if _kernel.is_hard_paused() or _kernel.is_decision_paused() or _kernel.has_active_action(_actor_id):
        return
    _submit_for_current_intention()

func _refresh_intention(_reason: StringName) -> void:
    var visual: Dictionary = _current_visual_player_observation()
    if not visual.is_empty():
        var visual_cell: Vector2i = visual.get("cell", Vector2i.ZERO)
        var visual_tick: int = int(visual.get("observed_tick", _kernel.world_tick()))
        _reset_detour_if_target_changed(visual_cell)
        if _visible_target_is_in_forward_contact(visual_cell):
            _set_intention(ATTACK_VISIBLE, visual_cell, _player_id, visual_tick)
        else:
            _set_intention(PURSUE_VISIBLE, visual_cell, _player_id, visual_tick)
        return

    var remembered: Dictionary = _perception.memory_store().last_seen_actor(_actor_id, _player_id)
    if not remembered.is_empty():
        var remembered_cell: Vector2i = remembered.get("cell", Vector2i.ZERO)
        var placement: WorldPlacement = _world.placement(_actor_id)
        if placement != null and placement.anchor != remembered_cell:
            _reset_detour_if_target_changed(remembered_cell)
            _set_intention(
                PURSUE_LAST_SEEN,
                remembered_cell,
                _player_id,
                int(remembered.get("observed_tick", -1))
            )
            return

    var placement_now: WorldPlacement = _world.placement(_actor_id)
    if _intention == INVESTIGATE_SOUND and placement_now != null and placement_now.anchor != _target_cell:
        # Auditory investigation is intentionally latched to the uncertain
        # perceived cell. New self-generated footstep cues cannot teleport the
        # intention back to exact source truth while the investigation is active.
        return

    var heard: HeardSoundObservation = _best_heard_observation()
    if heard != null and placement_now != null and heard.perceived_cell != placement_now.anchor:
        _reset_detour_if_target_changed(heard.perceived_cell)
        _set_intention(INVESTIGATE_SOUND, heard.perceived_cell, "", heard.heard_tick)
        return

    _clear_detour()
    _set_intention(IDLE, placement_now.anchor if placement_now != null else Vector2i.ZERO, "", _kernel.world_tick())

func _current_visual_player_observation() -> Dictionary:
    if _perception == null or _perception.memory_store() == null:
        return {}
    var observation: Dictionary = _perception.memory_store().last_seen_actor(_actor_id, _player_id)
    if observation.is_empty():
        return {}
    var cell_value: Variant = observation.get("cell", null)
    if typeof(cell_value) != TYPE_VECTOR2I:
        return {}
    var cell: Vector2i = cell_value
    if not _perception.is_visible(cell):
        return {}
    return observation

func _best_heard_observation() -> HeardSoundObservation:
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null:
        return null
    var best: HeardSoundObservation = null
    for observation: HeardSoundObservation in _sound.active_observations(_actor_id):
        if observation == null:
            continue
        # A listener knows a cue localized to its own occupied cell is not a
        # useful investigation destination. This also prevents ordinary self
        # footsteps from replacing a latched external investigation.
        if observation.perceived_cell == placement.anchor:
            continue
        if best == null \
            or observation.heard_tick > best.heard_tick \
            or (observation.heard_tick == best.heard_tick and observation.perceived_strength > best.perceived_strength) \
            or (observation.heard_tick == best.heard_tick and is_equal_approx(observation.perceived_strength, best.perceived_strength) and observation.cue_id < best.cue_id):
            best = observation
    return best.copy() if best != null else null

func _submit_for_current_intention() -> void:
    if _intention == ATTACK_VISIBLE:
        if _submit_attack():
            return
        # If contact changed after the perception snapshot, ordinary movement
        # owns the recovery. No combat-only snapping or homing is allowed.
        _set_intention(PURSUE_VISIBLE, _target_cell, _target_actor_id, _observed_tick)
    if _intention in [PURSUE_VISIBLE, PURSUE_LAST_SEEN, INVESTIGATE_SOUND]:
        _submit_move_toward(_target_cell)

func _submit_attack() -> bool:
    if _target_actor_id.is_empty() or not _visible_target_is_in_forward_contact(_target_cell):
        return false
    var offers: Array[Dictionary] = _combat.action_offers_for_target(_actor_id, _target_actor_id)
    for preferred: StringName in [CombatActions.STRIKE_PRIMARY, CombatActions.STRIKE_SECONDARY, CombatActions.STRIKE_UNARMED]:
        for offer: Dictionary in offers:
            if StringName(String(offer.get("action_id", ""))) != preferred:
                continue
            var result: Dictionary = _combat.request_action(_actor_id, _target_actor_id, preferred)
            if bool(result.get("accepted", false)):
                _record_submission(int(result.get("action_serial", 0)), preferred)
                return true
    return false

func _submit_move_toward(destination: Vector2i) -> bool:
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null or placement.anchor == destination:
        if _intention == INVESTIGATE_SOUND:
            _set_intention(IDLE, placement.anchor if placement != null else destination, "", _kernel.world_tick())
        return false

    if Facing.is_valid(_detour_facing) and _detour_target == destination:
        if placement.facing != _detour_facing:
            return _submit_turn_toward(placement.facing, _detour_facing)
        var detour_step: MovementActionResult = _movement.request_step_forward(_actor_id)
        if detour_step != null and detour_step.is_accepted():
            _record_submission(detour_step.action_serial, detour_step.action_type)
            _clear_detour()
            return true
        if not _detour_attempted_right:
            _detour_attempted_right = true
            _detour_facing = Facing.turn_right(Facing.turn_right(_detour_facing))
            return _submit_turn_toward(placement.facing, _detour_facing)
        _clear_detour()
        return false

    var delta: Vector2i = destination - placement.anchor
    var desired_facing: int = _preferred_facing(delta)
    if not Facing.is_valid(desired_facing):
        return false
    if placement.facing != desired_facing:
        return _submit_turn_toward(placement.facing, desired_facing)

    var step: MovementActionResult = _movement.request_step_forward(_actor_id)
    if step != null and step.is_accepted():
        _record_submission(step.action_serial, step.action_type)
        return true

    # Bounded local avoidance only. Full navigation remains a later scaling
    # problem; the movement owner still validates every actual step.
    _detour_target = destination
    _detour_facing = Facing.turn_left(placement.facing)
    _detour_attempted_right = false
    return _submit_turn_toward(placement.facing, _detour_facing)

func _submit_turn_toward(current_facing: int, desired_facing: int) -> bool:
    if current_facing == desired_facing:
        return false
    var left: int = Facing.turn_left(current_facing)
    var right: int = Facing.turn_right(current_facing)
    var result: MovementActionResult = null
    if desired_facing == right:
        result = _movement.request_turn_right(_actor_id)
    elif desired_facing == left:
        result = _movement.request_turn_left(_actor_id)
    else:
        # Opposite direction: left is the stable deterministic tie-break.
        result = _movement.request_turn_left(_actor_id)
    if result != null and result.is_accepted():
        _record_submission(result.action_serial, result.action_type)
        return true
    return false

func _preferred_facing(delta: Vector2i) -> int:
    if delta == Vector2i.ZERO:
        return -1
    if absi(delta.x) >= absi(delta.y) and delta.x != 0:
        return Facing.Value.EAST if delta.x > 0 else Facing.Value.WEST
    if delta.y != 0:
        return Facing.Value.SOUTH if delta.y > 0 else Facing.Value.NORTH
    return Facing.Value.EAST if delta.x > 0 else Facing.Value.WEST

func _visible_target_is_in_forward_contact(visual_cell: Vector2i) -> bool:
    var placement: WorldPlacement = _world.placement(_actor_id)
    if placement == null or not _perception.is_visible(visual_cell):
        return false
    return visual_cell == placement.anchor + Facing.vector(placement.facing)

func _set_intention(value: StringName, cell: Vector2i, target_actor: String, tick: int) -> void:
    var changed: bool = value != _intention or cell != _target_cell or target_actor != _target_actor_id or tick != _observed_tick
    _intention = value
    _target_cell = cell
    _target_actor_id = target_actor
    _observed_tick = tick
    if changed:
        intention_changed.emit(_actor_id, _intention, _target_cell, _target_actor_id, _observed_tick)

func _record_submission(serial: int, action_type: StringName) -> void:
    if serial <= 0:
        return
    _action_history.append({
        "actor_id": _actor_id,
        "action_serial": serial,
        "action_type": String(action_type),
        "intention": String(_intention),
        "target_cell": _target_cell,
        "target_actor_id": _target_actor_id,
        "submitted_tick": _kernel.world_tick(),
    })
    while _action_history.size() > MAX_HISTORY:
        _action_history.pop_front()
    action_submitted.emit(_actor_id, serial, action_type, _intention, _target_cell)

func _reset_detour_if_target_changed(destination: Vector2i) -> void:
    if Facing.is_valid(_detour_facing) and _detour_target != destination:
        _clear_detour()

func _clear_detour() -> void:
    _detour_facing = -1
    _detour_target = Vector2i.ZERO
    _detour_attempted_right = false

func _living_actor_available() -> bool:
    if not _infected.is_infected(_actor_id) or not _health.has_actor(_actor_id) or _health.current_hp(_actor_id) <= 0:
        return false
    var placement: WorldPlacement = _world.placement(_actor_id)
    return placement != null and placement.channel == Layers.Channel.ACTOR

func _stop(reason: StringName) -> void:
    if not _running:
        return
    _running = false
    _clear_detour()
    _set_intention(IDLE, _target_cell, "", _kernel.world_tick() if _kernel != null else -1)
    behavior_stopped.emit(_actor_id, reason)
