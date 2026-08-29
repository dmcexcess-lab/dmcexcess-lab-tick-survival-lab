extends RefCounted
class_name ObserverPerceptionService

const VisionQueryClass = preload("res://scripts/simulation/perception/VisionQuery.gd")
const AcquisitionProviderClass = preload("res://scripts/simulation/perception/VisualAcquisitionProvider.gd")
const ChangeClass = preload("res://scripts/foundation/world/WorldChange.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## Event-driven controlled-observer visibility + knowledge refresh.
## It advances no time and never mutates WHAT or Door State.
## Geometric LOS is filtered through a neutral acquisition provider before
## current truth is admitted into VISIBLE or refreshed into observer memory.
## Explicit WHAT batches are consumed once through their local dirty summary.

signal perception_changed(reason: StringName)

enum KnowledgeState {
    UNSEEN,
    REMEMBERED,
    VISIBLE,
}

var _world: WorldState = null
var _door_state: DoorStateStore = null
var _kernel: TickKernel = null
var _memory: PerceptionMemoryStore = null
var _observer_id: String = ""
var _profile: VisionProfile = null
var _vision: VisionQuery = null
var _acquisition: VisualAcquisitionProvider = null
var _visible: Dictionary = {}
var _recompute_count: int = 0

func _init(
    world_state: WorldState = null,
    door_state: DoorStateStore = null,
    kernel: TickKernel = null,
    memory_store: PerceptionMemoryStore = null,
    observer_id: String = "",
    profile: VisionProfile = null,
    acquisition_provider: VisualAcquisitionProvider = null
) -> void:
    _world = world_state
    _door_state = door_state
    _kernel = kernel
    _memory = memory_store
    _observer_id = observer_id.strip_edges()
    _profile = profile.copy() if profile != null else VisionProfile.new()
    _vision = VisionQueryClass.new(_world, _door_state)
    _acquisition = acquisition_provider if acquisition_provider != null else AcquisitionProviderClass.new()
    if _memory != null and not _observer_id.is_empty():
        _memory.enroll_observer(_observer_id)
    _connect_signals()
    recompute(&"configured")

func is_ready() -> bool:
    if _world == null or _door_state == null or _kernel == null or _memory == null or _vision == null or _acquisition == null:
        return false
    if _observer_id.is_empty() or _profile == null or not _profile.is_valid() or not _vision.is_ready() or not _acquisition.is_ready():
        return false
    if not _memory.has_observer(_observer_id):
        return false
    var placement: WorldPlacement = _world.placement(_observer_id)
    return placement != null and placement.channel == Layers.Channel.ACTOR and FacingRules.is_valid(placement.facing)

func observer_id() -> String:
    return _observer_id

func profile() -> VisionProfile:
    return _profile.copy() if _profile != null else null

func set_profile(value: VisionProfile) -> bool:
    if value == null or not value.is_valid():
        return false
    _profile = value.copy()
    recompute(&"profile_changed")
    return true

func set_acquisition_provider(value: VisualAcquisitionProvider) -> bool:
    if value == null or not value.is_ready():
        return false
    _acquisition = value
    recompute(&"acquisition_provider_changed")
    return true

func acquisition_provider() -> VisualAcquisitionProvider:
    return _acquisition

func recompute(reason: StringName = &"manual") -> bool:
    var started: int = Time.get_ticks_usec()
    _recompute_count += 1
    if not is_ready():
        var had_visible: bool = not _visible.is_empty()
        _visible.clear()
        if had_visible:
            perception_changed.emit(reason)
        _record_recompute(started)
        return false

    var observer_placement: WorldPlacement = _world.placement(_observer_id)
    var geometric_cells: Array[Vector2i] = _vision.visible_cells(observer_placement.anchor, observer_placement.facing, _profile)
    var acquired_cells: Array[Vector2i] = []
    _visible.clear()
    for cell: Vector2i in geometric_cells:
        if not _acquisition.allows_target(_observer_id, observer_placement.anchor, cell, _profile):
            continue
        _visible[cell] = true
        acquired_cells.append(cell)

    _refresh_environment_memory(acquired_cells)
    _refresh_actor_memory(acquired_cells)
    perception_changed.emit(reason)
    _record_recompute(started)
    return true

func _record_recompute(started_usec: int) -> void:
    PerformanceTelemetry.record_timing(&"perception_recompute", Time.get_ticks_usec() - started_usec)
    PerformanceTelemetry.record_value(&"perception_recomputes", _recompute_count)

func recompute_count() -> int:
    return _recompute_count

func visible_cells() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for value: Variant in _visible.keys():
        var cell: Vector2i = value
        result.append(cell)
    result.sort_custom(_cell_less)
    return result

func is_visible(cell: Vector2i) -> bool:
    return _visible.has(cell)

func knowledge_state(cell: Vector2i) -> int:
    if _visible.has(cell):
        return KnowledgeState.VISIBLE
    if _memory != null and _memory.has_seen_cell(_observer_id, cell):
        return KnowledgeState.REMEMBERED
    return KnowledgeState.UNSEEN

func memory_store() -> PerceptionMemoryStore:
    return _memory

func _refresh_environment_memory(cells: Array[Vector2i]) -> void:
    var tick: int = _kernel.world_tick()
    for cell: Vector2i in cells:
        if not _world.has_terrain(cell):
            continue
        var structure: Dictionary = _vision.structure_observation(cell)
        if not bool(structure.get("valid", false)):
            continue
        var remembered_structure: Dictionary = {}
        if bool(structure.get("present", false)):
            remembered_structure = structure.duplicate(true)
        _memory.remember_environment(
            _observer_id,
            cell,
            tick,
            _world.terrain_at(cell),
            remembered_structure,
            _rememberable_props_at(cell)
        )

func _rememberable_props_at(cell: Vector2i) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var entity_ids: Array[String] = _world.entities_at(cell, Layers.Channel.OBJECT)
    entity_ids.sort()
    for entity_id: String in entity_ids:
        var entity: WorldEntityRecord = _world.entity(entity_id)
        var placement: WorldPlacement = _world.placement(entity_id)
        if entity == null or placement == null or placement.channel != Layers.Channel.OBJECT:
            continue
        if cell not in placement.world_cells() or not FacingRules.is_valid(placement.facing):
            continue
        var semantic: String = String(entity.semantic_type).strip_edges()
        if not semantic.begins_with("prop.") and not semantic.begins_with("fixture."):
            continue
        result.append({
            "entity_id": entity_id,
            "semantic_type": semantic,
            "anchor": placement.anchor,
            "facing": placement.facing,
        })
    return result

func _refresh_actor_memory(cells: Array[Vector2i]) -> void:
    var seen_actor_ids: Dictionary = {}
    var tick: int = _kernel.world_tick()
    for cell: Vector2i in cells:
        var actor_ids: Array[String] = _world.entities_at(cell, Layers.Channel.ACTOR)
        actor_ids.sort()
        for actor_id: String in actor_ids:
            if actor_id == _observer_id or seen_actor_ids.has(actor_id):
                continue
            var entity: WorldEntityRecord = _world.entity(actor_id)
            var placement: WorldPlacement = _world.placement(actor_id)
            if entity == null or placement == null or placement.channel != Layers.Channel.ACTOR:
                continue
            var semantic: String = String(entity.semantic_type).strip_edges()
            if semantic != "actor.survivor" and semantic != "actor.infected":
                continue
            if not _visible.has(placement.anchor):
                continue
            if _memory.remember_actor(_observer_id, actor_id, entity.semantic_type, placement.anchor, placement.facing, tick):
                seen_actor_ids[actor_id] = true

    var observations: Array[Dictionary] = _memory.actor_observations(_observer_id)
    for observation: Dictionary in observations:
        var actor_id: String = String(observation.get("actor_id", ""))
        if seen_actor_ids.has(actor_id):
            continue
        var last_cell: Vector2i = observation.get("cell", Vector2i.ZERO)
        if _visible.has(last_cell):
            _memory.forget_actor(_observer_id, actor_id)

func _connect_signals() -> void:
    if _world != null:
        var world_changed := Callable(self, "_on_world_changed")
        var batch_changed := Callable(self, "_on_world_batch_changed")
        var world_reset := Callable(self, "_on_world_reset")
        if not _world.changed.is_connected(world_changed):
            _world.changed.connect(world_changed)
        if not _world.batch_changed.is_connected(batch_changed):
            _world.batch_changed.connect(batch_changed)
        if not _world.world_reset.is_connected(world_reset):
            _world.world_reset.connect(world_reset)
    if _door_state != null:
        var enrolled := Callable(self, "_on_door_changed")
        var removed := Callable(self, "_on_door_removed")
        var changed := Callable(self, "_on_door_state_changed")
        var reset := Callable(self, "_on_door_reset")
        if not _door_state.door_enrolled.is_connected(enrolled):
            _door_state.door_enrolled.connect(enrolled)
        if not _door_state.door_removed.is_connected(removed):
            _door_state.door_removed.connect(removed)
        if not _door_state.door_state_changed.is_connected(changed):
            _door_state.door_state_changed.connect(changed)
        if not _door_state.door_state_reset.is_connected(reset):
            _door_state.door_state_reset.connect(reset)

func _on_world_changed(change: WorldChange) -> void:
    if change == null:
        return
    if _world.is_change_batch_active():
        return
    var observer_placement: WorldPlacement = _world.placement(_observer_id)
    if observer_placement == null:
        recompute(&"observer_missing")
        return
    if change.entity_id == _observer_id:
        recompute(&"observer_changed")
        return

    match change.kind:
        ChangeClass.Kind.TERRAIN_SET, ChangeClass.Kind.TERRAIN_REMOVED:
            if _cell_near_observer(change.terrain_cell, observer_placement.anchor):
                recompute(&"nearby_terrain_changed")
        ChangeClass.Kind.TERRAIN_BATCH_SET:
            if _terrain_batch_near_observer(change, observer_placement.anchor):
                recompute(&"nearby_terrain_changed")
        ChangeClass.Kind.PLACEMENT_SET, ChangeClass.Kind.PLACEMENT_REMOVED, ChangeClass.Kind.ENTITY_REMOVED:
            if _cells_near_observer(change.before_cells, observer_placement.anchor) or _cells_near_observer(change.after_cells, observer_placement.anchor):
                recompute(&"nearby_placement_changed")
        _:
            return

func _on_world_batch_changed(batch: WorldChangeBatch) -> void:
    if batch == null:
        return
    var observer_placement: WorldPlacement = _world.placement(_observer_id)
    if observer_placement == null:
        recompute(&"observer_missing_after_batch")
        return
    if _batch_near_observer(batch, observer_placement.anchor):
        recompute(&"nearby_world_batch_changed")

func _batch_near_observer(batch: WorldChangeBatch, observer_cell: Vector2i) -> bool:
    var range_value: int = _profile.max_range if _profile != null else 0
    var potential := Rect2i(
        observer_cell - Vector2i(range_value, range_value),
        Vector2i(range_value * 2 + 1, range_value * 2 + 1)
    )
    if batch.terrain_changed:
        var terrain_rect: Rect2i = batch.terrain_dirty_bounds()
        if terrain_rect.size.x > 0 and terrain_rect.size.y > 0 and potential.intersects(terrain_rect):
            return true
    for channel: int in [Layers.Channel.STRUCTURE, Layers.Channel.OBJECT, Layers.Channel.ACTOR]:
        if not batch.channel_changed(channel):
            continue
        var dirty: Rect2i = batch.dirty_rect_for_channel(channel)
        if dirty.size.x > 0 and dirty.size.y > 0 and potential.intersects(dirty):
            return true
    return false

func _on_world_reset() -> void:
    recompute(&"world_reset")

func _on_door_changed(door_id: String, _state: StringName, _version: int) -> void:
    _recompute_for_door(door_id)

func _on_door_removed(door_id: String, _previous_state: StringName, _version: int) -> void:
    _recompute_for_door(door_id)

func _on_door_state_changed(door_id: String, _previous_state: StringName, _new_state: StringName, _version: int) -> void:
    _recompute_for_door(door_id)

func _on_door_reset() -> void:
    recompute(&"door_state_reset")

func _recompute_for_door(door_id: String) -> void:
    var observer_placement: WorldPlacement = _world.placement(_observer_id)
    var door_placement: WorldPlacement = _world.placement(door_id)
    if observer_placement == null or door_placement == null:
        return
    if _cell_near_observer(door_placement.anchor, observer_placement.anchor):
        recompute(&"door_state_changed")

func _terrain_batch_near_observer(change: WorldChange, observer_cell: Vector2i) -> bool:
    var range_value: int = _profile.max_range if _profile != null else 0
    var potential := Rect2i(
        observer_cell - Vector2i(range_value, range_value),
        Vector2i(range_value * 2 + 1, range_value * 2 + 1)
    )
    if change.terrain_rect.size.x > 0 and change.terrain_rect.size.y > 0:
        return potential.intersects(change.terrain_rect)
    return _cells_near_observer(change.terrain_cells, observer_cell)

func _cells_near_observer(cells: Array[Vector2i], observer_cell: Vector2i) -> bool:
    for cell: Vector2i in cells:
        if _cell_near_observer(cell, observer_cell):
            return true
    return false

func _cell_near_observer(cell: Vector2i, observer_cell: Vector2i) -> bool:
    if _profile == null:
        return false
    var delta := cell - observer_cell
    return maxi(abs(delta.x), abs(delta.y)) <= _profile.max_range

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y:
        return a.x < b.x
    return a.y < b.y