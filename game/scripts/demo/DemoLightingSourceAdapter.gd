extends RefCounted
class_name DemoLightingSourceAdapter

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const EmitterClass = preload("res://scripts/simulation/lighting/LightEmitter.gd")
const EmitterProfileClass = preload("res://scripts/simulation/lighting/LightEmitterProfile.gd")

## DEV critique-world source provider for System 27 Slice B.
## These always-on sources exist only so the visual lighting stack can be exercised
## before real equipment, batteries, switches, utilities and Weather own source state.

signal emitters_changed(emitters)

const INVALID_CELL := Vector2i(2147483647, 2147483647)

var _world: WorldState = null
var _player_id: String = ""
var _door_cell: Vector2i = INVALID_CELL
var _interior_facing: int = -1
var _lamp_cell: Vector2i = INVALID_CELL
var _neon_cell: Vector2i = INVALID_CELL
var _streetlight_cell: Vector2i = INVALID_CELL
var _emitters: Array[LightEmitter] = []
var _source_signature: String = ""
var _revision: int = 0

func _init(world_state: WorldState = null, controlled_actor_id: String = "") -> void:
    _world = world_state
    _player_id = controlled_actor_id.strip_edges()
    if _world != null:
        _connect_world()
        _discover_static_sources()
        _rebuild_if_needed(false)

func is_ready() -> bool:
    return _world != null and not _player_id.is_empty() and _world.placement(_player_id) != null

func emitters() -> Array[LightEmitter]:
    var result: Array[LightEmitter] = []
    for emitter: LightEmitter in _emitters:
        result.append(emitter.copy())
    return result

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "revision": _revision,
        "emitter_count": _emitters.size(),
        "door_cell": _door_cell,
        "interior_facing": _interior_facing,
        "lamp_cell": _lamp_cell,
        "neon_cell": _neon_cell,
        "streetlight_cell": _streetlight_cell,
    }

func _discover_static_sources() -> void:
    _door_cell = INVALID_CELL
    _interior_facing = -1
    _lamp_cell = INVALID_CELL
    _neon_cell = INVALID_CELL
    _streetlight_cell = INVALID_CELL
    if not is_ready():
        return

    var player: WorldPlacement = _world.placement(_player_id)
    var candidate_facings: Array[int] = [
        player.facing,
        Facing.turn_left(player.facing),
        Facing.turn_right(player.facing),
        Facing.opposite(player.facing),
    ]
    for facing: int in candidate_facings:
        var cell: Vector2i = player.anchor + Facing.vector(facing)
        if _cell_has_door(cell):
            _door_cell = cell
            _interior_facing = facing
            break
    if _door_cell == INVALID_CELL:
        return

    var inward: Vector2i = Facing.vector(_interior_facing)
    var outward: Vector2i = Facing.vector(Facing.opposite(_interior_facing))
    var right: Vector2i = Facing.vector(Facing.turn_right(_interior_facing))
    _lamp_cell = _first_open_cell(_door_cell + inward, inward, 5)
    if _lamp_cell != INVALID_CELL:
        _neon_cell = _first_open_cell(_lamp_cell + right * 2, inward, 3)
        if _neon_cell == INVALID_CELL:
            _neon_cell = _first_open_cell(_lamp_cell + inward, inward, 3)
    _streetlight_cell = _first_open_cell(_door_cell + outward * 2, outward, 5)

func _rebuild_if_needed(emit_signal: bool = true) -> void:
    if not is_ready():
        return
    var player: WorldPlacement = _world.placement(_player_id)
    var signature: String = "%d,%d|%d|%s|%s|%s" % [
        player.anchor.x,
        player.anchor.y,
        player.facing,
        _cell_signature(_lamp_cell),
        _cell_signature(_neon_cell),
        _cell_signature(_streetlight_cell),
    ]
    if signature == _source_signature:
        return
    _source_signature = signature
    _revision += 1

    var next_emitters: Array[LightEmitter] = []
    next_emitters.append(EmitterClass.new(
        "dev.light.player_flashlight",
        player.anchor,
        player.facing,
        EmitterProfileClass.flashlight(),
        true,
        _revision
    ))
    if _lamp_cell != INVALID_CELL:
        next_emitters.append(EmitterClass.new(
            "dev.light.diner_lamp",
            _lamp_cell,
            Facing.Value.NORTH,
            EmitterProfileClass.lamp(),
            true,
            _revision
        ))
    if _neon_cell != INVALID_CELL:
        next_emitters.append(EmitterClass.new(
            "dev.light.diner_neon",
            _neon_cell,
            Facing.Value.NORTH,
            EmitterProfileClass.neon(Color(0.24, 0.58, 1.0)),
            true,
            _revision
        ))
    if _streetlight_cell != INVALID_CELL:
        next_emitters.append(EmitterClass.new(
            "dev.light.streetlight",
            _streetlight_cell,
            Facing.Value.NORTH,
            EmitterProfileClass.streetlight(),
            true,
            _revision
        ))
    _emitters = next_emitters
    if emit_signal:
        emitters_changed.emit(emitters())

func _cell_has_door(cell: Vector2i) -> bool:
    for entity_id: String in _world.entities_at(cell, Layers.Channel.STRUCTURE):
        var record: WorldEntityRecord = _world.entity(entity_id)
        if record != null and String(record.semantic_type).to_lower().contains("door"):
            return true
    return false

func _first_open_cell(start: Vector2i, direction: Vector2i, attempts: int) -> Vector2i:
    var candidate: Vector2i = start
    for _i in range(maxi(1, attempts)):
        if _valid_emitter_cell(candidate):
            return candidate
        candidate += direction
    return INVALID_CELL

func _valid_emitter_cell(cell: Vector2i) -> bool:
    return _world.has_terrain(cell) and _world.entities_at(cell, Layers.Channel.STRUCTURE).is_empty()

func _cell_signature(cell: Vector2i) -> String:
    return "none" if cell == INVALID_CELL else "%d,%d" % [cell.x, cell.y]

func _connect_world() -> void:
    var changed_callable := Callable(self, "_on_world_changed")
    var reset_callable := Callable(self, "_on_world_reset")
    if not _world.changed.is_connected(changed_callable):
        _world.changed.connect(changed_callable)
    if not _world.world_reset.is_connected(reset_callable):
        _world.world_reset.connect(reset_callable)

func _on_world_changed(_change) -> void:
    _rebuild_if_needed(true)

func _on_world_reset() -> void:
    _discover_static_sources()
    _source_signature = ""
    _rebuild_if_needed(true)
