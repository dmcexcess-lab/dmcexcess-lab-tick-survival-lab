extends RefCounted
class_name AreaGenerationRequest

const EntityId = preload("res://scripts/foundation/world/WorldEntityId.gd")

var area_id: String = ""
var seed: int = 0
var bounds: Rect2i = Rect2i()
var area_profile_id: StringName = &""
var environment_profile_id: StringName = &""
var inherited_roads: Array[Dictionary] = []
var forbidden_regions: Array[Rect2i] = []
var inherited_planning_constraints: Array[Dictionary] = []
var inherited_geography: Array[Dictionary] = []
## Optional upstream world seed for natural ecology that must remain coherent
## across neighboring logical area bounds. Null preserves the historical local
## request-seed/local-coordinate dressing behavior for standalone fixtures.
var inherited_ecology_seed: Variant = null

func _init(
    p_area_id: String = "",
    p_seed: int = 0,
    p_bounds: Rect2i = Rect2i(),
    p_area_profile_id: StringName = &"",
    p_environment_profile_id: StringName = &"",
    p_inherited_roads: Array[Dictionary] = [],
    p_forbidden_regions: Array[Rect2i] = [],
    p_inherited_planning_constraints: Array[Dictionary] = [],
    p_inherited_geography: Array[Dictionary] = []
) -> void:
    area_id = p_area_id.strip_edges()
    seed = p_seed
    bounds = p_bounds
    area_profile_id = p_area_profile_id
    environment_profile_id = p_environment_profile_id
    inherited_roads = p_inherited_roads.duplicate(true)
    forbidden_regions = p_forbidden_regions.duplicate()
    inherited_planning_constraints = p_inherited_planning_constraints.duplicate(true)
    inherited_geography = p_inherited_geography.duplicate(true)

func is_valid() -> bool:
    if not EntityId.is_valid(area_id):
        return false
    if bounds.size.x <= 0 or bounds.size.y <= 0:
        return false
    if String(area_profile_id).strip_edges().is_empty() or String(environment_profile_id).strip_edges().is_empty():
        return false
    if inherited_ecology_seed != null and typeof(inherited_ecology_seed) != TYPE_INT:
        return false
    for road: Dictionary in inherited_roads:
        if not _road_constraint_valid(road):
            return false
    for region: Rect2i in forbidden_regions:
        if region.size.x <= 0 or region.size.y <= 0 or not _rect_inside(bounds, region):
            return false
    var constraint_ids: Dictionary = {}
    for constraint: Dictionary in inherited_planning_constraints:
        if not _planning_constraint_valid(constraint):
            return false
        var constraint_id: String = String(constraint.get("id", ""))
        if constraint_ids.has(constraint_id):
            return false
        constraint_ids[constraint_id] = true
    var geography_ids: Dictionary = {}
    for geography: Dictionary in inherited_geography:
        if not _geography_record_valid(geography):
            return false
        var geography_id: String = String(geography.get("id", ""))
        if geography_ids.has(geography_id):
            return false
        geography_ids[geography_id] = true
    return true

func _road_constraint_valid(road: Dictionary) -> bool:
    var road_id: String = String(road.get("road_id", "")).strip_edges()
    var road_class: StringName = road.get("road_class", &"")
    var start: Vector2i = road.get("start", Vector2i(-999999, -999999))
    var finish: Vector2i = road.get("end", Vector2i(-999999, -999999))
    var width: int = int(road.get("width", 0))
    if not EntityId.is_valid(road_id) or String(road_class).is_empty():
        return false
    if width <= 0 or width % 2 == 0:
        return false
    if start == finish or (start.x != finish.x and start.y != finish.y):
        return false
    if not bounds.has_point(start) or not bounds.has_point(finish):
        return false

    var allowed: Array = road.get("allowed_boundary_cells", [])
    for value: Variant in allowed:
        if typeof(value) != TYPE_VECTOR2I:
            return false
        var cell: Vector2i = value
        if not _is_boundary_cell(bounds, cell):
            return false

    var start_on_boundary: bool = _is_boundary_cell(bounds, start)
    var finish_on_boundary: bool = _is_boundary_cell(bounds, finish)
    if start_on_boundary and not allowed.has(start):
        return false
    if finish_on_boundary and not allowed.has(finish):
        return false
    if not start_on_boundary and allowed.has(start):
        return false
    if not finish_on_boundary and allowed.has(finish):
        return false
    if allowed.is_empty() and (start_on_boundary or finish_on_boundary):
        return false
    return true

func _planning_constraint_valid(constraint: Dictionary) -> bool:
    var constraint_id: String = String(constraint.get("id", "")).strip_edges()
    var domain: StringName = StringName(constraint.get("domain", &""))
    var kind: StringName = StringName(constraint.get("kind", &""))
    var role: StringName = StringName(constraint.get("reservation_role", &""))
    if not EntityId.is_valid(constraint_id) or String(domain).is_empty() or String(kind).is_empty():
        return false
    if role != &"facility" and role != &"corridor" and role != &"service":
        return false
    if role == &"corridor":
        var start: Vector2i = constraint.get("start", Vector2i(-999999, -999999))
        var finish: Vector2i = constraint.get("end", Vector2i(-999999, -999999))
        var width: int = int(constraint.get("width", 0))
        if width <= 0 or start == finish or (start.x != finish.x and start.y != finish.y):
            return false
        return bounds.has_point(start) and bounds.has_point(finish)
    var cell: Vector2i = constraint.get("cell", Vector2i(-999999, -999999))
    return bounds.has_point(cell)

func _geography_record_valid(geography: Dictionary) -> bool:
    var geography_id: String = String(geography.get("id", "")).strip_edges()
    var rect: Rect2i = geography.get("rect", Rect2i())
    var grid_value: Variant = geography.get("grid", null)
    var elevation: int = int(geography.get("elevation", -1))
    var landform: StringName = StringName(geography.get("landform", &""))
    if not EntityId.is_valid(geography_id):
        return false
    if rect.size.x <= 0 or rect.size.y <= 0 or not _rect_inside(bounds, rect):
        return false
    if typeof(grid_value) != TYPE_VECTOR2I:
        return false
    if elevation < 0 or elevation > 100:
        return false
    return landform == &"lowland" or landform == &"rolling" or landform == &"upland" or landform == &"ridge"

static func _is_boundary_cell(rect: Rect2i, cell: Vector2i) -> bool:
    if not rect.has_point(cell):
        return false
    var max_x: int = rect.position.x + rect.size.x - 1
    var max_y: int = rect.position.y + rect.size.y - 1
    return cell.x == rect.position.x or cell.x == max_x or cell.y == rect.position.y or cell.y == max_y

static func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)
