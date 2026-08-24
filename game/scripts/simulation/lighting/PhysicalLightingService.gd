extends RefCounted
class_name PhysicalLightingService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const FacingRules = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const DoorValues = preload("res://scripts/simulation/doors/DoorStateValue.gd")
const SampleClass = preload("res://scripts/simulation/lighting/IlluminationSample.gd")
const VisionRangePolicy = preload("res://scripts/simulation/lighting/VisionLightRangePolicy.gd")

## Authoritative headless physical illumination backend.
## Rendering may visualize these facts but never becomes gameplay/AI lighting authority.

signal lighting_rebuilt(revision: int)

const NIGHT_BASELINE_REFERENCE: float = 0.08
const SKY_DIFFUSE_SHARE: float = 0.72
const SKY_DIRECT_SHARE: float = 0.28
const INTERIOR_AMBIENT_SHARE: float = 0.015
const PORTAL_SCALE: float = 0.68
const PORTAL_DECAY: float = 0.72
const PORTAL_MIN_STRENGTH: float = 0.025
const PORTAL_MAX_STEPS: int = 8
const WINDOW_TRANSMISSION: float = 0.72
const OPEN_DOOR_TRANSMISSION: float = 0.95
const LOCAL_SPILL_STEP_SCALE: float = 0.50

const CARDINALS: Array[Vector2i] = [
    Vector2i(0, -1),
    Vector2i(1, 0),
    Vector2i(0, 1),
    Vector2i(-1, 0),
]

var _world: WorldState = null
var _doors: DoorStateStore = null
var _ambient: OutdoorAmbientLightService = null
var _atmosphere: AtmosphericOptics = AtmosphericOptics.clear()
var _emitters: Array[LightEmitter] = []

var _field_bounds: Rect2i = Rect2i()
var _field_valid: bool = false

var _sky_exposed: Dictionary = {}
var _portal_factor: Dictionary = {}
var _samples: Dictionary = {}
var _color_accum: Dictionary = {}
var _color_weight: Dictionary = {}
var _dominant_strength: Dictionary = {}

var _geometry_world_revision: int = -1
var _geometry_door_revision: int = -1
var _geometry_bounds: Rect2i = Rect2i()
var _last_world_revision: int = -1
var _last_door_revision: int = -1
var _last_ambient_level: float = -1.0
var _last_atmosphere_revision: int = -1
var _last_emitter_signature: String = ""
var _lighting_revision: int = 0

func _init(
    world_state: WorldState = null,
    door_state: DoorStateStore = null,
    ambient_service: OutdoorAmbientLightService = null
) -> void:
    _world = world_state
    _doors = door_state
    _ambient = ambient_service

func is_ready() -> bool:
    return (
        _world != null
        and _doors != null
        and _ambient != null and _ambient.is_ready()
        and _atmosphere != null and _atmosphere.is_valid()
        and _field_valid
    )

func set_field_bounds(bounds: Rect2i) -> bool:
    if bounds.size.x <= 0 or bounds.size.y <= 0:
        return false
    if _field_valid and bounds == _field_bounds:
        return true
    _field_bounds = bounds
    _field_valid = true
    _geometry_world_revision = -1
    _geometry_door_revision = -1
    _invalidate_light_cache()
    return true

func field_bounds() -> Rect2i:
    return _field_bounds

func set_atmosphere(optics: AtmosphericOptics) -> bool:
    if optics == null or not optics.is_valid():
        return false
    _atmosphere = optics.copy()
    _invalidate_light_cache()
    return true

func atmosphere() -> AtmosphericOptics:
    return _atmosphere.copy()

func set_emitters(values: Array) -> bool:
    var accepted: Array[LightEmitter] = []
    var seen: Dictionary = {}
    for value: Variant in values:
        if value == null or not value is LightEmitter:
            return false
        var emitter: LightEmitter = value
        if not emitter.is_valid() or seen.has(emitter.emitter_id):
            return false
        seen[emitter.emitter_id] = true
        accepted.append(emitter.copy())
    accepted.sort_custom(func(a: LightEmitter, b: LightEmitter) -> bool:
        return a.emitter_id < b.emitter_id
    )
    _emitters = accepted
    _invalidate_light_cache()
    return true

func emitters() -> Array[LightEmitter]:
    var result: Array[LightEmitter] = []
    for emitter: LightEmitter in _emitters:
        result.append(emitter.copy())
    return result

func illumination_at(cell: Vector2i) -> IlluminationSample:
    _ensure_current()
    if _samples.has(cell):
        var stored: IlluminationSample = _samples[cell]
        return stored.copy()
    var result := SampleClass.new(cell)
    _stamp_sample(result)
    return result

func luminance_at(cell: Vector2i) -> float:
    return illumination_at(cell).useful_luminance

func effective_vision_range_at(
    target_cell: Vector2i,
    geometric_max_range: int,
    near_awareness_radius: int = 1
) -> int:
    return VisionRangePolicy.effective_range_for_luminance(
        luminance_at(target_cell),
        geometric_max_range,
        near_awareness_radius
    )

func target_within_light_range(
    origin: Vector2i,
    target: Vector2i,
    geometric_max_range: int,
    near_awareness_radius: int = 1
) -> bool:
    return VisionRangePolicy.target_within_light_range(
        target - origin,
        luminance_at(target),
        geometric_max_range,
        near_awareness_radius
    )

func lighting_revision() -> int:
    _ensure_current()
    return _lighting_revision

func debug_snapshot() -> Dictionary:
    _ensure_current()
    return {
        "ready": is_ready(),
        "lighting_revision": _lighting_revision,
        "world_revision": -1 if _world == null else _world.revision(),
        "door_revision": -1 if _doors == null else _doors.revision(),
        "ambient_light_level": 0.0 if _ambient == null else _ambient.ambient_light_level(),
        "atmosphere_revision": -1 if _atmosphere == null else _atmosphere.revision,
        "field_bounds": [_field_bounds.position.x, _field_bounds.position.y, _field_bounds.size.x, _field_bounds.size.y],
        "sky_exposed_cells": _sky_exposed.size(),
        "portal_influenced_cells": _portal_factor.size(),
        "sample_count": _samples.size(),
        "emitter_count": _emitters.size(),
    }

func _ensure_current() -> void:
    if not is_ready():
        return
    _ensure_geometry()
    var world_revision: int = _world.revision()
    var door_revision: int = _doors.revision()
    var ambient_level: float = _ambient.ambient_light_level()
    var emitter_signature: String = _emitter_signature()
    if (
        world_revision == _last_world_revision
        and door_revision == _last_door_revision
        and is_equal_approx(ambient_level, _last_ambient_level)
        and _atmosphere.revision == _last_atmosphere_revision
        and emitter_signature == _last_emitter_signature
        and not _samples.is_empty()
    ):
        return

    _rebuild_samples(ambient_level)
    _last_world_revision = world_revision
    _last_door_revision = door_revision
    _last_ambient_level = ambient_level
    _last_atmosphere_revision = _atmosphere.revision
    _last_emitter_signature = emitter_signature
    _lighting_revision += 1
    for value: Variant in _samples.values():
        var sample: IlluminationSample = value
        sample.lighting_revision = _lighting_revision
    lighting_rebuilt.emit(_lighting_revision)

func _ensure_geometry() -> void:
    var world_revision: int = _world.revision()
    if world_revision != _geometry_world_revision or _geometry_bounds != _field_bounds:
        _rebuild_sky_exposure()
        _geometry_world_revision = world_revision
        _geometry_door_revision = -1
        _geometry_bounds = _field_bounds
    var door_revision: int = _doors.revision()
    if door_revision != _geometry_door_revision:
        _rebuild_portal_transfer()
        _geometry_door_revision = door_revision

func _rebuild_sky_exposure() -> void:
    _sky_exposed.clear()
    if not _field_valid:
        return
    var queue: Array[Vector2i] = []
    var queued: Dictionary = {}
    var min_x: int = _field_bounds.position.x
    var min_y: int = _field_bounds.position.y
    var max_x: int = min_x + _field_bounds.size.x - 1
    var max_y: int = min_y + _field_bounds.size.y - 1

    for x in range(min_x, max_x + 1):
        _queue_exterior_seed(Vector2i(x, min_y), queue, queued)
        _queue_exterior_seed(Vector2i(x, max_y), queue, queued)
    for y in range(min_y + 1, max_y):
        _queue_exterior_seed(Vector2i(min_x, y), queue, queued)
        _queue_exterior_seed(Vector2i(max_x, y), queue, queued)

    var head: int = 0
    while head < queue.size():
        var cell: Vector2i = queue[head]
        head += 1
        _sky_exposed[cell] = true
        for direction: Vector2i in CARDINALS:
            var neighbor: Vector2i = cell + direction
            if not _field_bounds.has_point(neighbor) or queued.has(neighbor):
                continue
            if not _world.has_terrain(neighbor) or _is_envelope_structure(neighbor):
                continue
            queued[neighbor] = true
            queue.append(neighbor)

func _queue_exterior_seed(cell: Vector2i, queue: Array[Vector2i], queued: Dictionary) -> void:
    if queued.has(cell) or not _world.has_terrain(cell) or _is_envelope_structure(cell):
        return
    queued[cell] = true
    queue.append(cell)

func _rebuild_portal_transfer() -> void:
    _portal_factor.clear()
    if not _field_valid:
        return

    var queue_cells: Array[Vector2i] = []
    var queue_strength: Array[float] = []
    var queue_steps: Array[int] = []

    for cell: Vector2i in _all_field_cells():
        if not _world.has_terrain(cell):
            continue
        var transmission: float = _portal_transmission(cell)
        if transmission <= 0.0 or not _touches_sky_exposed(cell):
            continue
        for direction: Vector2i in CARDINALS:
            var interior: Vector2i = cell + direction
            if not _field_bounds.has_point(interior) or not _world.has_terrain(interior):
                continue
            if _sky_exposed.has(interior):
                continue
            if _cell_diffuse_transmission(interior) <= 0.0:
                continue
            var seed_strength: float = transmission * 0.86
            if seed_strength > float(_portal_factor.get(interior, 0.0)):
                _portal_factor[interior] = seed_strength
                queue_cells.append(interior)
                queue_strength.append(seed_strength)
                queue_steps.append(0)

    var head: int = 0
    while head < queue_cells.size():
        var cell: Vector2i = queue_cells[head]
        var strength: float = queue_strength[head]
        var steps: int = queue_steps[head]
        head += 1
        if steps >= PORTAL_MAX_STEPS:
            continue
        for direction: Vector2i in CARDINALS:
            var neighbor: Vector2i = cell + direction
            if not _field_bounds.has_point(neighbor) or not _world.has_terrain(neighbor):
                continue
            if _sky_exposed.has(neighbor):
                continue
            var step_transmission: float = _cell_diffuse_transmission(neighbor)
            if step_transmission <= 0.0:
                continue
            var next_strength: float = strength * PORTAL_DECAY * step_transmission
            if next_strength < PORTAL_MIN_STRENGTH:
                continue
            if next_strength <= float(_portal_factor.get(neighbor, 0.0)) + 0.0001:
                continue
            _portal_factor[neighbor] = next_strength
            queue_cells.append(neighbor)
            queue_strength.append(next_strength)
            queue_steps.append(steps + 1)

func _rebuild_samples(ambient_level: float) -> void:
    _samples.clear()
    _color_accum.clear()
    _color_weight.clear()
    _dominant_strength.clear()

    var day_factor: float = clampf(
        (ambient_level - NIGHT_BASELINE_REFERENCE) / (1.0 - NIGHT_BASELINE_REFERENCE),
        0.0,
        1.0
    )
    var diffuse_outdoor: float = clampf(
        ambient_level * SKY_DIFFUSE_SHARE * _atmosphere.diffuse_sky_transmission,
        0.0,
        1.0
    )
    var direct_outdoor: float = clampf(
        day_factor * SKY_DIRECT_SHARE * _atmosphere.direct_sky_transmission,
        0.0,
        1.0
    )
    var outdoor_total: float = clampf(diffuse_outdoor + direct_outdoor, 0.0, 1.0)
    var sky_color: Color = _atmosphere_tinted(_sky_color(day_factor))
    var direct_color: Color = _atmosphere_tinted(_direct_color(day_factor))

    for cell: Vector2i in _all_field_cells():
        if not _world.has_terrain(cell):
            continue
        var sample := SampleClass.new(cell)
        if _sky_exposed.has(cell):
            sample.sky_diffuse = diffuse_outdoor
            sample.direct_celestial = direct_outdoor
        elif _is_envelope_structure(cell) and _touches_sky_exposed(cell):
            sample.sky_diffuse = diffuse_outdoor * 0.82
            sample.direct_celestial = direct_outdoor * 0.72
        else:
            sample.sky_diffuse = ambient_level * INTERIOR_AMBIENT_SHARE * _atmosphere.diffuse_sky_transmission

        sample.portal = clampf(float(_portal_factor.get(cell, 0.0)) * outdoor_total * PORTAL_SCALE, 0.0, 1.0)
        _samples[cell] = sample
        _accumulate_color(cell, sample.sky_diffuse, sky_color)
        _accumulate_color(cell, sample.direct_celestial, direct_color)
        _accumulate_color(cell, sample.portal, sky_color)

    for emitter: LightEmitter in _emitters:
        if emitter.active and emitter.is_valid():
            _apply_emitter(emitter)

    var current_time: Dictionary = _ambient.current_snapshot()
    for cell_value: Variant in _samples.keys():
        var cell: Vector2i = cell_value
        var sample: IlluminationSample = _samples[cell]
        sample.useful_luminance = clampf(
            sample.sky_diffuse + sample.direct_celestial + sample.portal + sample.local_artificial,
            0.0,
            1.0
        )
        var weight: float = float(_color_weight.get(cell, 0.0))
        if weight > 0.0001:
            var accum: Vector3 = _color_accum[cell]
            sample.tint = Color(
                clampf(accum.x / weight, 0.0, 1.0),
                clampf(accum.y / weight, 0.0, 1.0),
                clampf(accum.z / weight, 0.0, 1.0),
                1.0
            )
        sample.world_tick = int(current_time.get("world_tick", 0))
        sample.world_revision = _world.revision()
        sample.door_revision = _doors.revision()

func _apply_emitter(emitter: LightEmitter) -> void:
    var profile: LightEmitterProfile = emitter.profile
    var direct_field: Dictionary = {}
    for cell: Vector2i in _all_field_cells():
        if not _world.has_terrain(cell):
            continue
        var offset: Vector2i = cell - emitter.origin_cell
        var distance: float = Vector2(float(offset.x), float(offset.y)).length()
        if distance > float(profile.useful_range):
            continue
        if profile.shape == LightEmitterProfile.Shape.CONE and not _inside_cone(offset, emitter.facing, profile.cone_half_angle_degrees):
            continue
        var transmission: float = _transmission_between(emitter.origin_cell, cell)
        if transmission <= 0.0:
            continue
        var normalized_distance: float = clampf(distance / float(profile.useful_range + 1), 0.0, 1.0)
        var falloff: float = pow(1.0 - normalized_distance, profile.falloff_exponent)
        var atmospheric_loss: float = pow(clampf(_atmosphere.local_light_transmission, 0.0, 1.0), distance)
        var amount: float = profile.base_luminance * falloff * transmission * atmospheric_loss
        if amount <= 0.001:
            continue
        direct_field[cell] = amount

    var spill_field: Dictionary = {}
    if profile.diffuse_spill > 0.0:
        for cell_value: Variant in direct_field.keys():
            var source_cell: Vector2i = cell_value
            var source_amount: float = float(direct_field[source_cell])
            for direction: Vector2i in CARDINALS:
                var neighbor: Vector2i = source_cell + direction
                if not _field_bounds.has_point(neighbor) or not _world.has_terrain(neighbor):
                    continue
                var step_transmission: float = _cell_diffuse_transmission(neighbor)
                if step_transmission <= 0.0:
                    continue
                var spill: float = source_amount * profile.diffuse_spill * LOCAL_SPILL_STEP_SCALE * step_transmission
                if spill > float(spill_field.get(neighbor, 0.0)):
                    spill_field[neighbor] = spill

    for cell_value: Variant in direct_field.keys():
        var cell: Vector2i = cell_value
        _add_local_light(cell, float(direct_field[cell]), emitter)
    for cell_value: Variant in spill_field.keys():
        var cell: Vector2i = cell_value
        _add_local_light(cell, float(spill_field[cell]), emitter, false)

func _add_local_light(cell: Vector2i, amount: float, emitter: LightEmitter, direct: bool = true) -> void:
    if not _samples.has(cell) or amount <= 0.0:
        return
    var sample: IlluminationSample = _samples[cell]
    sample.local_artificial += amount
    sample.glare = maxf(sample.glare, clampf(amount * 1.10, 0.0, 1.0))
    sample.scatter = maxf(sample.scatter, clampf(amount * _atmosphere.scatter_strength, 0.0, 1.0))
    _accumulate_color(cell, amount, _atmosphere_tinted(emitter.profile.tint))
    if direct and amount > float(_dominant_strength.get(cell, 0.0)):
        _dominant_strength[cell] = amount
        sample.dominant_direction = Vector2i(
            signi(emitter.origin_cell.x - cell.x),
            signi(emitter.origin_cell.y - cell.y)
        )

func _inside_cone(offset: Vector2i, facing: int, half_angle_degrees: float) -> bool:
    if offset == Vector2i.ZERO:
        return true
    if not FacingRules.is_valid(facing):
        return false
    var forward_i: Vector2i = FacingRules.vector(facing)
    var forward := Vector2(float(forward_i.x), float(forward_i.y))
    var direction := Vector2(float(offset.x), float(offset.y)).normalized()
    var threshold: float = cos(deg_to_rad(half_angle_degrees))
    return forward.dot(direction) >= threshold

func _transmission_between(origin: Vector2i, target: Vector2i) -> float:
    if origin == target:
        return 1.0
    if not _world.has_terrain(origin) or not _world.has_terrain(target):
        return 0.0

    var delta: Vector2i = target - origin
    var nx: int = abs(delta.x)
    var ny: int = abs(delta.y)
    var step_x: int = signi(delta.x)
    var step_y: int = signi(delta.y)
    var ix: int = 0
    var iy: int = 0
    var current: Vector2i = origin
    var transmission: float = 1.0

    while ix < nx or iy < ny:
        var decision: int = (1 + 2 * ix) * ny - (1 + 2 * iy) * nx
        if decision == 0:
            var side_x: Vector2i = current + Vector2i(step_x, 0)
            var side_y: Vector2i = current + Vector2i(0, step_y)
            var tx: float = _cell_direct_transmission(side_x)
            var ty: float = _cell_direct_transmission(side_y)
            if tx <= 0.0 and ty <= 0.0:
                return 0.0
            transmission *= maxf(tx, ty)
            current += Vector2i(step_x, step_y)
            ix += 1
            iy += 1
        elif decision < 0:
            current += Vector2i(step_x, 0)
            ix += 1
        else:
            current += Vector2i(0, step_y)
            iy += 1

        if current == target:
            return clampf(transmission, 0.0, 1.0)
        var step_transmission: float = _cell_direct_transmission(current)
        if step_transmission <= 0.0:
            return 0.0
        transmission *= step_transmission
        if transmission <= 0.001:
            return 0.0

    return clampf(transmission, 0.0, 1.0)

func _cell_direct_transmission(cell: Vector2i) -> float:
    if not _world.has_terrain(cell):
        return 0.0
    var structure_ids: Array[String] = _world.entities_at(cell, Layers.Channel.STRUCTURE)
    if structure_ids.is_empty():
        return 1.0
    if structure_ids.size() != 1:
        return 0.0
    var entity: WorldEntityRecord = _world.entity(structure_ids[0])
    if entity == null:
        return 0.0
    var semantic: String = String(entity.semantic_type)
    if semantic.begins_with("window."):
        return WINDOW_TRANSMISSION
    if semantic.begins_with("door."):
        return OPEN_DOOR_TRANSMISSION if _doors.state(structure_ids[0]) == DoorValues.OPEN else 0.0
    return 0.0

func _cell_diffuse_transmission(cell: Vector2i) -> float:
    return _cell_direct_transmission(cell)

func _portal_transmission(cell: Vector2i) -> float:
    var structure_ids: Array[String] = _world.entities_at(cell, Layers.Channel.STRUCTURE)
    if structure_ids.size() != 1:
        return 0.0
    var entity: WorldEntityRecord = _world.entity(structure_ids[0])
    if entity == null:
        return 0.0
    var semantic: String = String(entity.semantic_type)
    if semantic.begins_with("window."):
        return WINDOW_TRANSMISSION
    if semantic.begins_with("door.") and _doors.state(structure_ids[0]) == DoorValues.OPEN:
        return OPEN_DOOR_TRANSMISSION
    return 0.0

func _is_envelope_structure(cell: Vector2i) -> bool:
    return not _world.entities_at(cell, Layers.Channel.STRUCTURE).is_empty()

func _touches_sky_exposed(cell: Vector2i) -> bool:
    for direction: Vector2i in CARDINALS:
        if _sky_exposed.has(cell + direction):
            return true
    return false

func _accumulate_color(cell: Vector2i, amount: float, color: Color) -> void:
    if amount <= 0.0:
        return
    var previous: Vector3 = _color_accum.get(cell, Vector3.ZERO)
    _color_accum[cell] = previous + Vector3(color.r, color.g, color.b) * amount
    _color_weight[cell] = float(_color_weight.get(cell, 0.0)) + amount

func _sky_color(day_factor: float) -> Color:
    return Color(0.48, 0.56, 0.68).lerp(Color(0.86, 0.92, 1.0), day_factor)

func _direct_color(day_factor: float) -> Color:
    return Color(1.0, 0.63, 0.38).lerp(Color(1.0, 0.97, 0.88), day_factor)

func _atmosphere_tinted(color: Color) -> Color:
    return Color(
        color.r * _atmosphere.tint.r,
        color.g * _atmosphere.tint.g,
        color.b * _atmosphere.tint.b,
        1.0
    )

func _all_field_cells() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not _field_valid:
        return result
    var end_x: int = _field_bounds.position.x + _field_bounds.size.x
    var end_y: int = _field_bounds.position.y + _field_bounds.size.y
    for y in range(_field_bounds.position.y, end_y):
        for x in range(_field_bounds.position.x, end_x):
            result.append(Vector2i(x, y))
    return result

func _emitter_signature() -> String:
    var parts: PackedStringArray = []
    for emitter: LightEmitter in _emitters:
        parts.append(emitter.signature())
    return "||".join(parts)

func _stamp_sample(sample: IlluminationSample) -> void:
    if sample == null:
        return
    sample.world_revision = -1 if _world == null else _world.revision()
    sample.door_revision = -1 if _doors == null else _doors.revision()
    sample.lighting_revision = _lighting_revision
    if _ambient != null and _ambient.is_ready():
        sample.world_tick = int(_ambient.current_snapshot().get("world_tick", 0))

func _invalidate_light_cache() -> void:
    _samples.clear()
    _last_world_revision = -1
    _last_door_revision = -1
    _last_ambient_level = -1.0
    _last_atmosphere_revision = -1
    _last_emitter_signature = ""
