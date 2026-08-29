extends RefCounted
class_name UtilityPowerInfrastructureMaterializer

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

## One-time tactical physicalization of canonical 00D4 distribution topology.
## 00D remains topology authority; this class creates persistent WHAT supports/local service gear
## and a cached presentation edge list. Major source/substation facilities are owned by
## PowerFacilityMaterializer rather than represented by equipment-cluster stand-ins.

const URBAN_SPACING: int = 9
const SETTLEMENT_SPACING: int = 14
const RURAL_SPACING: int = 22
const ROAD_SHOULDER_OFFSET: int = 4
const EXPLICIT_CONSTRUCTED_VEHICLE_TERRAIN: Array[StringName] = [
    &"ground.gravel_dark",
    &"ground.gravel_light",
    &"ground.alley_stained",
    &"ground.concrete_oil",
]
const CONSTRUCTED_VEHICLE_TERRAIN_PREFIXES: Array[String] = [
    "ground.road_",
    "ground.parking",
    "ground.driveway_",
]

const COLLISION_SEMANTICS: Array[StringName] = [
    &"prop.utility_pole_wood",
    &"prop.utility_pole_transformer",
    &"prop.streetlight",
    &"prop.transformer",
    &"prop.utility_box",
]

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _plan: GeneratedGlobalWorldPlan = null
var _utilities: UtilityRuntimeState = null
var _wire_edges: Array[Dictionary] = []
var _created_ids: Array[String] = []
var _materialized: bool = false

func _init(
    world_state: WorldState = null,
    mutations: WorldMutationService = null,
    global_plan: GeneratedGlobalWorldPlan = null,
    utilities: UtilityRuntimeState = null
) -> void:
    _world = world_state
    _mutations = mutations
    _plan = global_plan
    _utilities = utilities

func is_ready() -> bool:
    return _world != null and _mutations != null and _plan != null and _plan.is_generated() \
        and _utilities != null and _utilities.is_ready()

func materialize() -> bool:
    if _materialized:
        return true
    if not is_ready():
        return false
    var projection: Dictionary = _build_projection()
    var props_value: Variant = projection.get("props", [])
    var wires_value: Variant = projection.get("wires", [])
    if typeof(props_value) != TYPE_ARRAY or typeof(wires_value) != TYPE_ARRAY:
        return false
    var props: Array = props_value
    if props.is_empty():
        return false

    _world.begin_change_batch(&"utility_power_infrastructure")
    var success: bool = true
    for value: Variant in props:
        if typeof(value) != TYPE_DICTIONARY:
            success = false
            break
        var prop: Dictionary = value
        if not _materialize_prop(prop):
            success = false
            break
    if not success:
        for entity_id: String in _created_ids.duplicate():
            if _world.has_entity(entity_id):
                _mutations.remove_entity(entity_id)
        _created_ids.clear()
        _wire_edges.clear()
        _world.end_change_batch()
        return false

    _wire_edges = []
    for value: Variant in wires_value:
        if typeof(value) == TYPE_DICTIONARY:
            _wire_edges.append((value as Dictionary).duplicate(true))
    _world.end_change_batch()
    _materialized = true
    return not _wire_edges.is_empty()

func wire_edges() -> Array[Dictionary]:
    return _wire_edges.duplicate(true)

func created_entity_ids() -> Array[String]:
    return _created_ids.duplicate()

func debug_snapshot() -> Dictionary:
    var counts: Dictionary = {}
    for entity_id: String in _created_ids:
        var record: WorldEntityRecord = _world.entity(entity_id)
        if record == null:
            continue
        var key: String = String(record.semantic_type)
        counts[key] = int(counts.get(key, 0)) + 1
    return {
        "ready": is_ready(),
        "materialized": _materialized,
        "entity_count": _created_ids.size(),
        "wire_count": _wire_edges.size(),
        "semantic_counts": counts,
    }

func _build_projection() -> Dictionary:
    var props: Array[Dictionary] = []
    var wires: Array[Dictionary] = []
    var reserved_cells: Dictionary = {}

    for segment: Dictionary in _plan.power_segments:
        var support_records: Array[Dictionary] = _segment_supports(segment, reserved_cells)
        for record: Dictionary in support_records:
            props.append(record)
            reserved_cells[record.get("cell", Vector2i.ZERO)] = true
        for index: int in range(1, support_records.size()):
            wires.append({
                "start_id": String(support_records[index - 1].get("id", "")),
                "end_id": String(support_records[index].get("id", "")),
                "network_id": String(segment.get("network_id", "")),
                "power_class": StringName(segment.get("power_class", &"")),
                "segment_id": String(segment.get("id", "")),
            })

    # Source and substation are now real generated facilities. Only settlement service gear
    # remains in this distribution projection.
    for node: Dictionary in _plan.power_nodes:
        if StringName(node.get("kind", &"")) != &"settlement_service":
            continue
        var node_records: Array[Dictionary] = _node_equipment(node, reserved_cells)
        for record: Dictionary in node_records:
            props.append(record)
            reserved_cells[record.get("cell", Vector2i.ZERO)] = true

    return {"props": props, "wires": wires}

func _segment_supports(segment: Dictionary, reserved_cells: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var start: Vector2i = segment.get("start", Vector2i.ZERO)
    var finish: Vector2i = segment.get("end", Vector2i.ZERO)
    var delta: Vector2i = finish - start
    if delta == Vector2i.ZERO or (delta.x != 0 and delta.y != 0):
        return result
    var direction := Vector2i(signi(delta.x), signi(delta.y))
    var length: int = absi(delta.x) + absi(delta.y)
    var side: int = -1 if _stable_parity(String(segment.get("id", ""))) == 0 else 1
    var distance: int = 0
    var ordinal: int = 0
    while distance <= length:
        var route_cell: Vector2i = start + direction * distance
        var support_cell: Vector2i = _find_support_cell(route_cell, direction, side, reserved_cells)
        if support_cell != Vector2i(2147483647, 2147483647):
            var semantic: StringName = _support_semantic(support_cell, ordinal)
            result.append({
                "id": "power.physical.%s.support.%03d" % [_stable_token(String(segment.get("id", "segment"))), ordinal],
                "semantic": semantic,
                "cell": support_cell,
                "facing": _facing_toward_road(direction, side),
            })
            reserved_cells[support_cell] = true
            ordinal += 1
        var spacing: int = _spacing_for(route_cell)
        distance += maxi(1, spacing)

    if result.size() == 1 and length > 0:
        var end_cell: Vector2i = _find_support_cell(finish, direction, side, reserved_cells)
        if end_cell != Vector2i(2147483647, 2147483647):
            result.append({
                "id": "power.physical.%s.support.%03d" % [_stable_token(String(segment.get("id", "segment"))), ordinal],
                "semantic": _support_semantic(end_cell, ordinal),
                "cell": end_cell,
                "facing": _facing_toward_road(direction, side),
            })
            reserved_cells[end_cell] = true
    return result

func _support_semantic(cell: Vector2i, ordinal: int) -> StringName:
    var density: int = _density_for(cell)
    var light_stride: int = 5
    var transformer_stride: int = 5
    if density == 0:
        light_stride = 1
        transformer_stride = 7
    elif density == 1:
        light_stride = 2
        transformer_stride = 5
    if ordinal > 0 and ordinal % transformer_stride == 0:
        return &"prop.utility_pole_transformer"
    if ordinal % light_stride == 0:
        return &"prop.streetlight"
    return &"prop.utility_pole_wood"

func _spacing_for(cell: Vector2i) -> int:
    match _density_for(cell):
        0:
            return URBAN_SPACING
        1:
            return SETTLEMENT_SPACING
        _:
            return RURAL_SPACING

func _density_for(cell: Vector2i) -> int:
    var best_distance: int = 2147483647
    var best_profile: StringName = &""
    for site: Dictionary in _plan.area_sites:
        var bounds: Rect2i = site.get("bounds", Rect2i())
        var center := Vector2i(bounds.position.x + bounds.size.x / 2, bounds.position.y + bounds.size.y / 2)
        var distance: int = absi(cell.x - center.x) + absi(cell.y - center.y)
        if bounds.has_point(cell):
            distance = 0
        if distance < best_distance:
            best_distance = distance
            best_profile = StringName(site.get("area_profile_hint", &""))
    if best_profile == &"smalltown.center" and best_distance <= 180:
        return 0
    if best_distance <= 110:
        return 1
    return 2

func _find_support_cell(
    route_cell: Vector2i,
    direction: Vector2i,
    preferred_side: int,
    reserved_cells: Dictionary
) -> Vector2i:
    var perpendicular := Vector2i(-direction.y, direction.x)
    var offsets: Array[int] = [
        preferred_side * ROAD_SHOULDER_OFFSET,
        -preferred_side * ROAD_SHOULDER_OFFSET,
        preferred_side * (ROAD_SHOULDER_OFFSET + 1),
        -preferred_side * (ROAD_SHOULDER_OFFSET + 1),
        preferred_side * (ROAD_SHOULDER_OFFSET - 1),
        -preferred_side * (ROAD_SHOULDER_OFFSET - 1),
    ]
    for offset: int in offsets:
        var candidate: Vector2i = route_cell + perpendicular * offset
        if not _plan.bounds.has_point(candidate) or reserved_cells.has(candidate):
            continue
        if _is_support_blocked_surface_cell(candidate):
            continue
        if not _world.entities_at(candidate).is_empty():
            continue
        return candidate
    return Vector2i(2147483647, 2147483647)

func _is_support_blocked_surface_cell(cell: Vector2i) -> bool:
    if _is_planned_global_road_surface(cell):
        return true
    if not _world.has_terrain(cell):
        return false
    return _is_constructed_vehicle_surface_terrain(_world.terrain_at(cell))

static func _is_constructed_vehicle_surface_terrain(semantic_type: StringName) -> bool:
    var semantic: String = String(semantic_type)
    for prefix: String in CONSTRUCTED_VEHICLE_TERRAIN_PREFIXES:
        if semantic.begins_with(prefix):
            return true
    return EXPLICIT_CONSTRUCTED_VEHICLE_TERRAIN.has(semantic_type)

func _is_planned_global_road_surface(cell: Vector2i) -> bool:
    for road: Dictionary in _plan.road_segments:
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        var width: int = int(road.get("width", 0))
        if width <= 0:
            continue
        var half_width: int = width / 2
        if start.y == finish.y:
            if cell.x >= mini(start.x, finish.x) and cell.x <= maxi(start.x, finish.x) \
                and absi(cell.y - start.y) <= half_width:
                return true
        elif start.x == finish.x:
            if cell.y >= mini(start.y, finish.y) and cell.y <= maxi(start.y, finish.y) \
                and absi(cell.x - start.x) <= half_width:
                return true
    return false

func _node_equipment(node: Dictionary, reserved_cells: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if StringName(node.get("kind", &"")) != &"settlement_service":
        return result
    var node_cell: Vector2i = node.get("cell", Vector2i.ZERO)
    var anchor: Vector2i = _find_service_anchor(node_cell, reserved_cells)
    if anchor == Vector2i(2147483647, 2147483647):
        return result

    var semantics: Array[StringName] = [
        &"prop.utility_pole_transformer",
        &"prop.utility_box",
    ]
    var offsets: Array[Vector2i] = [Vector2i.ZERO, Vector2i(2, 0)]
    var token: String = _stable_token(String(node.get("id", "node")))
    for index: int in range(semantics.size()):
        var cell: Vector2i = anchor + offsets[index]
        if not _plan.bounds.has_point(cell) or reserved_cells.has(cell) or not _world.entities_at(cell).is_empty():
            continue
        result.append({
            "id": "power.physical.%s.service_equipment.%02d" % [token, index],
            "semantic": semantics[index],
            "cell": cell,
            "facing": Facing.Value.NORTH,
        })
        reserved_cells[cell] = true
    return result

func _find_service_anchor(node_cell: Vector2i, reserved_cells: Dictionary) -> Vector2i:
    var candidates: Array[Vector2i] = [
        node_cell + Vector2i(6, 6),
        node_cell + Vector2i(-6, 6),
        node_cell + Vector2i(6, -6),
        node_cell + Vector2i(-6, -6),
        node_cell + Vector2i(8, 0),
        node_cell + Vector2i(-8, 0),
        node_cell + Vector2i(0, 8),
        node_cell + Vector2i(0, -8),
    ]
    for candidate: Vector2i in candidates:
        if not _plan.bounds.has_point(candidate) or reserved_cells.has(candidate):
            continue
        if _is_support_blocked_surface_cell(candidate):
            continue
        if _world.entities_at(candidate).is_empty():
            return candidate
    return Vector2i(2147483647, 2147483647)

func _materialize_prop(prop: Dictionary) -> bool:
    var entity_id: String = String(prop.get("id", "")).strip_edges()
    var semantic: StringName = StringName(prop.get("semantic", &""))
    var cell: Vector2i = prop.get("cell", Vector2i.ZERO)
    var facing: int = int(prop.get("facing", Facing.Value.NORTH))
    if entity_id.is_empty() or String(semantic).is_empty() or not _plan.bounds.has_point(cell):
        return false
    if _world.has_entity(entity_id):
        var existing: WorldEntityRecord = _world.entity(entity_id)
        var placement: WorldPlacement = _world.placement(entity_id)
        return existing != null and existing.semantic_type == semantic and placement != null and placement.anchor == cell
    if _mutations.create_entity(semantic, entity_id) != entity_id:
        return false
    _created_ids.append(entity_id)
    return _mutations.set_placement(
        entity_id,
        Layers.Channel.OBJECT,
        cell,
        facing,
        FootprintClass.single_cell()
    )

func _facing_toward_road(direction: Vector2i, side: int) -> int:
    var perpendicular := Vector2i(-direction.y, direction.x) * -side
    if perpendicular == Vector2i(0, -1):
        return Facing.Value.NORTH
    if perpendicular == Vector2i(1, 0):
        return Facing.Value.EAST
    if perpendicular == Vector2i(0, 1):
        return Facing.Value.SOUTH
    return Facing.Value.WEST

static func _stable_token(value: String) -> String:
    var normalized: String = value.strip_edges().to_lower()
    for character: String in [" ", "/", "\\", ":", "|", ">", "<"]:
        normalized = normalized.replace(character, ".")
    return normalized

static func _stable_parity(value: String) -> int:
    var total: int = 0
    for index: int in range(value.length()):
        total = (total + value.unicode_at(index) * (index + 1)) & 0x7fffffff
    return total % 2
