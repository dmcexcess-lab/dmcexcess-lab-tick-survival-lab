extends RefCounted
class_name PowerFacilityMaterializer

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")

## One-time physicalization of the generated grid's major facilities.
## The 00D power nodes remain topology connection points; these are the real persistent WHAT
## facilities attached to those points. No separate facility-map reality and no recurring work.

const PLANT_SIZE := Vector2i(31, 19)
const SUBSTATION_SIZE := Vector2i(15, 13)
const INVALID_CELL := Vector2i(2147483647, 2147483647)

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _plan: GeneratedGlobalWorldPlan = null
var _support_ids: Array[String] = []
var _created_ids: Array[String] = []
var _plant_machine_ids: Array[String] = []
var _substation_machine_ids: Array[String] = []
var _plant_tie_entity_ids: Array[String] = []
var _substation_tie_entity_ids: Array[String] = []
var _wire_edges: Array[Dictionary] = []
var _plant_rect := Rect2i()
var _substation_rect := Rect2i()
var _materialized: bool = false

func _init(
    world_state: WorldState = null,
    mutations: WorldMutationService = null,
    global_plan: GeneratedGlobalWorldPlan = null,
    infrastructure_entity_ids: Array[String] = []
) -> void:
    _world = world_state
    _mutations = mutations
    _plan = global_plan
    for entity_id: String in infrastructure_entity_ids:
        if entity_id.find(".support.") >= 0:
            _support_ids.append(entity_id)
    _support_ids.sort()

func is_ready() -> bool:
    return _world != null and _mutations != null and _plan != null and _plan.is_generated() and not _support_ids.is_empty()

func materialize() -> bool:
    if _materialized:
        return true
    if not is_ready():
        return false
    var source_node: Dictionary = _node_of_kind(&"regional_ingress")
    var substation_node: Dictionary = _node_of_kind(&"substation")
    if source_node.is_empty() or substation_node.is_empty():
        return false

    _plant_rect = _find_facility_rect(source_node.get("cell", Vector2i.ZERO), PLANT_SIZE, true)
    _substation_rect = _find_facility_rect(substation_node.get("cell", Vector2i.ZERO), SUBSTATION_SIZE, true)
    if _plant_rect.size == Vector2i.ZERO:
        _plant_rect = _find_facility_rect(source_node.get("cell", Vector2i.ZERO), PLANT_SIZE, false)
    if _substation_rect.size == Vector2i.ZERO:
        _substation_rect = _find_facility_rect(substation_node.get("cell", Vector2i.ZERO), SUBSTATION_SIZE, false)
    if _plant_rect.size == Vector2i.ZERO or _substation_rect.size == Vector2i.ZERO or _plant_rect.intersects(_substation_rect):
        return false

    _world.begin_change_batch(&"generated_power_facilities")
    var success: bool = _materialize_plant(source_node) and _materialize_substation(substation_node)
    _world.end_change_batch()
    if not success:
        for entity_id: String in _created_ids.duplicate():
            if _world.has_entity(entity_id):
                _mutations.remove_entity(entity_id)
        _created_ids.clear()
        _plant_machine_ids.clear()
        _substation_machine_ids.clear()
        _plant_tie_entity_ids.clear()
        _substation_tie_entity_ids.clear()
        _wire_edges.clear()
        return false
    _materialized = true
    return true

func created_entity_ids() -> Array[String]:
    return _created_ids.duplicate()

func plant_machine_ids() -> Array[String]:
    return _plant_machine_ids.duplicate()

func substation_machine_ids() -> Array[String]:
    return _substation_machine_ids.duplicate()

func plant_tie_entity_ids() -> Array[String]:
    return _plant_tie_entity_ids.duplicate()

func substation_tie_entity_ids() -> Array[String]:
    return _substation_tie_entity_ids.duplicate()

func wire_edges() -> Array[Dictionary]:
    return _wire_edges.duplicate(true)

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "materialized": _materialized,
        "plant_rect": _plant_rect,
        "substation_rect": _substation_rect,
        "plant_area": _plant_rect.size.x * _plant_rect.size.y,
        "substation_area": _substation_rect.size.x * _substation_rect.size.y,
        "plant_machine_count": _plant_machine_ids.size(),
        "substation_machine_count": _substation_machine_ids.size(),
        "facility_wire_count": _wire_edges.size(),
        "entity_count": _created_ids.size(),
    }

func _materialize_plant(source_node: Dictionary) -> bool:
    var cells: Array[Vector2i] = []
    for y: int in range(_plant_rect.position.y, _plant_rect.position.y + _plant_rect.size.y):
        for x: int in range(_plant_rect.position.x, _plant_rect.position.x + _plant_rect.size.x):
            cells.append(Vector2i(x, y))
    if not _mutations.set_terrain_cells(cells, &"ground.concrete_cracked"):
        return false

    var wall_ordinal: int = 0
    var door_x: int = _plant_rect.position.x + _plant_rect.size.x / 2
    for y: int in range(_plant_rect.position.y, _plant_rect.position.y + _plant_rect.size.y):
        for x: int in range(_plant_rect.position.x, _plant_rect.position.x + _plant_rect.size.x):
            var cell := Vector2i(x, y)
            var boundary: bool = x == _plant_rect.position.x or x == _plant_rect.position.x + _plant_rect.size.x - 1 \
                or y == _plant_rect.position.y or y == _plant_rect.position.y + _plant_rect.size.y - 1
            if not boundary:
                continue
            if y == _plant_rect.position.y + _plant_rect.size.y - 1 and absi(x - door_x) <= 1:
                continue
            if not _materialize_entity(
                "power.facility.plant.wall.%03d" % wall_ordinal,
                &"wall.plaster",
                Layers.Channel.STRUCTURE,
                cell
            ):
                return false
            wall_ordinal += 1

    # Real interior partitions: turbine hall | generator hall | control/switchgear wing.
    var partition_xs: Array[int] = [_plant_rect.position.x + 10, _plant_rect.position.x + 20]
    for partition_x: int in partition_xs:
        for y: int in range(_plant_rect.position.y + 1, _plant_rect.position.y + _plant_rect.size.y - 1):
            var local_y: int = y - _plant_rect.position.y
            if local_y in [5, 6, 12, 13]:
                continue
            if not _materialize_entity(
                "power.facility.plant.partition.%d.%03d" % [partition_x, y],
                &"wall.interior",
                Layers.Channel.STRUCTURE,
                Vector2i(partition_x, y)
            ):
                return false

    var right_start: int = _plant_rect.position.x + 21
    var horizontal_y: int = _plant_rect.position.y + 9
    for x: int in range(right_start, _plant_rect.position.x + _plant_rect.size.x - 1):
        if x in [right_start + 3, right_start + 4]:
            continue
        if not _materialize_entity(
            "power.facility.plant.partition.h.%03d" % x,
            &"wall.interior",
            Layers.Channel.STRUCTURE,
            Vector2i(x, horizontal_y)
        ):
            return false

    var machine_cells: Array[Vector2i] = [
        _plant_rect.position + Vector2i(4, 5),
        _plant_rect.position + Vector2i(4, 12),
        _plant_rect.position + Vector2i(14, 5),
        _plant_rect.position + Vector2i(14, 12),
        _plant_rect.position + Vector2i(24, 5),
        _plant_rect.position + Vector2i(25, 13),
    ]
    var machine_semantics: Array[StringName] = [
        &"prop.transformer", &"prop.transformer", &"prop.transformer",
        &"prop.utility_box", &"prop.utility_box", &"prop.utility_box",
    ]
    for index: int in range(machine_cells.size()):
        var entity_id: String = "power.facility.plant.machine.%02d" % index
        if not _materialize_entity(entity_id, machine_semantics[index], Layers.Channel.OBJECT, machine_cells[index]):
            return false
        _plant_machine_ids.append(entity_id)

    var light_cells: Array[Vector2i] = [
        _plant_rect.position + Vector2i(5, 9),
        _plant_rect.position + Vector2i(15, 9),
        _plant_rect.position + Vector2i(25, 5),
        _plant_rect.position + Vector2i(25, 13),
    ]
    for index: int in range(light_cells.size()):
        if not _materialize_entity(
            "power.facility.plant.room_light.%02d" % index,
            &"fixture.room_light",
            Layers.Channel.EFFECT,
            light_cells[index]
        ):
            return false

    var tie_cell := Vector2i(door_x + 3, _plant_rect.position.y + _plant_rect.size.y - 3)
    if not _plant_rect.has_point(tie_cell):
        tie_cell = _plant_rect.position + Vector2i(_plant_rect.size.x - 3, _plant_rect.size.y - 3)
    var tie_id: String = "power.facility.plant.grid_tie"
    if not _materialize_entity(tie_id, &"prop.utility_pole_transformer", Layers.Channel.OBJECT, tie_cell):
        return false
    _plant_tie_entity_ids.append(tie_id)
    return _append_facility_wire(tie_id, String(source_node.get("network_id", "")), &"plant_tie")

func _materialize_substation(substation_node: Dictionary) -> bool:
    var cells: Array[Vector2i] = []
    for y: int in range(_substation_rect.position.y, _substation_rect.position.y + _substation_rect.size.y):
        for x: int in range(_substation_rect.position.x, _substation_rect.position.x + _substation_rect.size.x):
            cells.append(Vector2i(x, y))
    if not _mutations.set_terrain_cells(cells, &"ground.concrete_oil"):
        return false

    var gate_x: int = _substation_rect.position.x + _substation_rect.size.x / 2
    var fence_ordinal: int = 0
    for y: int in range(_substation_rect.position.y, _substation_rect.position.y + _substation_rect.size.y):
        for x: int in range(_substation_rect.position.x, _substation_rect.position.x + _substation_rect.size.x):
            var boundary: bool = x == _substation_rect.position.x or x == _substation_rect.position.x + _substation_rect.size.x - 1 \
                or y == _substation_rect.position.y or y == _substation_rect.position.y + _substation_rect.size.y - 1
            if not boundary:
                continue
            if y == _substation_rect.position.y + _substation_rect.size.y - 1 and absi(x - gate_x) <= 1:
                continue
            if not _materialize_entity(
                "power.facility.substation.fence.%03d" % fence_ordinal,
                &"prop.chainlink_fence",
                Layers.Channel.OBJECT,
                Vector2i(x, y)
            ):
                return false
            fence_ordinal += 1

    var machine_cells: Array[Vector2i] = [
        _substation_rect.position + Vector2i(3, 4),
        _substation_rect.position + Vector2i(7, 4),
        _substation_rect.position + Vector2i(11, 4),
        _substation_rect.position + Vector2i(5, 8),
        _substation_rect.position + Vector2i(9, 8),
    ]
    var machine_semantics: Array[StringName] = [
        &"prop.transformer", &"prop.transformer", &"prop.transformer",
        &"prop.utility_box", &"prop.utility_box",
    ]
    for index: int in range(machine_cells.size()):
        var entity_id: String = "power.facility.substation.machine.%02d" % index
        if not _materialize_entity(entity_id, machine_semantics[index], Layers.Channel.OBJECT, machine_cells[index]):
            return false
        _substation_machine_ids.append(entity_id)

    var tie_cell := _substation_rect.position + Vector2i(_substation_rect.size.x / 2, _substation_rect.size.y - 3)
    var tie_id: String = "power.facility.substation.grid_tie"
    if not _materialize_entity(tie_id, &"prop.utility_pole_transformer", Layers.Channel.OBJECT, tie_cell):
        return false
    _substation_tie_entity_ids.append(tie_id)
    return _append_facility_wire(tie_id, String(substation_node.get("network_id", "")), &"substation_tie")

func _append_facility_wire(tie_id: String, network_id: String, role: StringName) -> bool:
    var tie_placement: WorldPlacement = _world.placement(tie_id)
    if tie_placement == null:
        return false
    var nearest_id: String = ""
    var nearest_distance: int = 2147483647
    for support_id: String in _support_ids:
        var placement: WorldPlacement = _world.placement(support_id)
        if placement == null:
            continue
        var distance: int = absi(placement.anchor.x - tie_placement.anchor.x) + absi(placement.anchor.y - tie_placement.anchor.y)
        if distance < nearest_distance or (distance == nearest_distance and (nearest_id.is_empty() or support_id < nearest_id)):
            nearest_distance = distance
            nearest_id = support_id
    if nearest_id.is_empty():
        return false
    _wire_edges.append({
        "start_id": tie_id,
        "end_id": nearest_id,
        "network_id": network_id,
        "power_class": &"facility_tie",
        "segment_id": "power.facility.tie.%s" % String(role),
        "facility_role": role,
    })
    return true

func _find_facility_rect(node_cell: Vector2i, size: Vector2i, avoid_area_sites: bool) -> Rect2i:
    var radii: Array[int] = [24, 40, 64, 88, 112, 144, 176, 208]
    var directions: Array[Vector2i] = [
        Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
        Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
    ]
    for radius: int in radii:
        for direction: Vector2i in directions:
            var center: Vector2i = node_cell + direction * radius
            var rect: Rect2i = _clamped_rect(center, size)
            if _facility_rect_valid(rect, avoid_area_sites):
                return rect
    return Rect2i()

func _clamped_rect(center: Vector2i, size: Vector2i) -> Rect2i:
    var margin: int = 4
    var min_x: int = _plan.bounds.position.x + margin
    var min_y: int = _plan.bounds.position.y + margin
    var max_x: int = _plan.bounds.position.x + _plan.bounds.size.x - size.x - margin
    var max_y: int = _plan.bounds.position.y + _plan.bounds.size.y - size.y - margin
    if max_x < min_x or max_y < min_y:
        return Rect2i()
    var origin := Vector2i(
        clampi(center.x - size.x / 2, min_x, max_x),
        clampi(center.y - size.y / 2, min_y, max_y)
    )
    return Rect2i(origin, size)

func _facility_rect_valid(rect: Rect2i, avoid_area_sites: bool) -> bool:
    if rect.size == Vector2i.ZERO:
        return false
    var end: Vector2i = rect.position + rect.size
    if not _plan.bounds.has_point(rect.position) or not _plan.bounds.has_point(end - Vector2i.ONE):
        return false
    if avoid_area_sites:
        for site: Dictionary in _plan.area_sites:
            var site_bounds: Rect2i = site.get("bounds", Rect2i())
            if site_bounds.grow(8).intersects(rect):
                return false
    for y: int in range(rect.position.y, end.y):
        for x: int in range(rect.position.x, end.x):
            var cell := Vector2i(x, y)
            if _is_planned_global_road_surface(cell) or not _world.entities_at(cell).is_empty():
                return false
    return true

func _is_planned_global_road_surface(cell: Vector2i) -> bool:
    for road: Dictionary in _plan.road_segments:
        var start: Vector2i = road.get("start", Vector2i.ZERO)
        var finish: Vector2i = road.get("end", Vector2i.ZERO)
        var width: int = int(road.get("width", 0))
        if width <= 0:
            continue
        var half_width: int = width / 2
        if start.y == finish.y:
            if cell.x >= mini(start.x, finish.x) and cell.x <= maxi(start.x, finish.x) and absi(cell.y - start.y) <= half_width:
                return true
        elif start.x == finish.x:
            if cell.y >= mini(start.y, finish.y) and cell.y <= maxi(start.y, finish.y) and absi(cell.x - start.x) <= half_width:
                return true
    return false

func _node_of_kind(kind: StringName) -> Dictionary:
    for node: Dictionary in _plan.power_nodes:
        if StringName(node.get("kind", &"")) == kind:
            return node
    return {}

func _materialize_entity(
    entity_id: String,
    semantic: StringName,
    channel: int,
    cell: Vector2i,
    facing: int = Facing.Value.NORTH
) -> bool:
    if entity_id.is_empty() or String(semantic).is_empty() or not _plan.bounds.has_point(cell):
        return false
    if _world.has_entity(entity_id) or not _world.entities_at(cell, channel).is_empty():
        return false
    if _mutations.create_entity(semantic, entity_id) != entity_id:
        return false
    _created_ids.append(entity_id)
    return _mutations.set_placement(entity_id, channel, cell, facing, FootprintClass.single_cell())
