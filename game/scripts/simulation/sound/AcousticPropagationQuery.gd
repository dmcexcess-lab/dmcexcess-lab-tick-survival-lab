extends RefCounted
class_name AcousticPropagationQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const MaterialCatalogClass = preload("res://scripts/simulation/sound/AcousticMaterialCatalog.gd")
const EnvironmentModifierClass = preload("res://scripts/simulation/sound/AcousticEnvironmentModifier.gd")

## Bounded deterministic weighted acoustic wavefront through current materialized
## WHAT + Door State geometry. One field is computed per physical emission.

const CARDINAL_COST: int = 10
const DIAGONAL_COST: int = 14
const MAX_RADIUS_CELLS: int = 128
const _NEIGHBORS: Array[Vector2i] = [
    Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
    Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var _world: WorldState = null
var _doors: DoorStateStore = null
var _materials: AcousticMaterialCatalog = null
var _environment: AcousticEnvironmentModifier = null

func _init(
    world: WorldState = null,
    door_state: DoorStateStore = null,
    materials: AcousticMaterialCatalog = null,
    environment_modifier: AcousticEnvironmentModifier = null
) -> void:
    _world = world
    _doors = door_state
    _materials = materials if materials != null else MaterialCatalogClass.new()
    _environment = environment_modifier if environment_modifier != null else EnvironmentModifierClass.new()

func is_ready() -> bool:
    return _world != null and _doors != null and _materials != null and _environment != null

func propagation_field(emission: SoundEmission) -> Dictionary:
    if not is_ready() or emission == null or not emission.is_valid():
        return {}
    if not _world.has_terrain(emission.origin_cell):
        return {}

    var field: Dictionary = {}
    var best_cost: Dictionary = {emission.origin_cell: 0}
    var best_barrier: Dictionary = {emission.origin_cell: 0}
    var heap: Array[Dictionary] = []
    _heap_push(heap, {"cell": emission.origin_cell, "cost": 0, "barrier_cost": 0})
    var radius_sq: int = MAX_RADIUS_CELLS * MAX_RADIUS_CELLS

    while not heap.is_empty():
        var current: Dictionary = _heap_pop(heap)
        var cell: Vector2i = current.get("cell", Vector2i.ZERO)
        var cost: int = int(current.get("cost", 0))
        if int(best_cost.get(cell, 2147483647)) != cost:
            continue
        var barrier_cost: int = int(best_barrier.get(cell, 0))
        field[cell] = {
            "cost": cost,
            "barrier_cost": barrier_cost,
            "remaining": emission.acoustic_power - cost,
        }

        for offset: Vector2i in _NEIGHBORS:
            var next_cell: Vector2i = cell + offset
            var from_origin: Vector2i = next_cell - emission.origin_cell
            if from_origin.length_squared() > radius_sq:
                continue
            if not _world.has_terrain(next_cell):
                continue
            var diagonal: bool = offset.x != 0 and offset.y != 0
            if diagonal and _diagonal_corner_sealed(cell, offset):
                continue
            var step_cost: int = DIAGONAL_COST if diagonal else CARDINAL_COST
            var structure_cost: int = _structure_cost(next_cell)
            var environment_cost: int = maxi(0, _environment.propagation_cost_addition(emission.profile_id, cell, next_cell))
            var next_cost: int = cost + step_cost + structure_cost + environment_cost
            if next_cost >= emission.acoustic_power:
                continue
            var previous_best: int = int(best_cost.get(next_cell, 2147483647))
            var next_barrier: int = barrier_cost + structure_cost + environment_cost
            if next_cost > previous_best:
                continue
            if next_cost == previous_best and next_barrier >= int(best_barrier.get(next_cell, 2147483647)):
                continue
            best_cost[next_cell] = next_cost
            best_barrier[next_cell] = next_barrier
            _heap_push(heap, {"cell": next_cell, "cost": next_cost, "barrier_cost": next_barrier})
    return field

func received(field: Dictionary, cell: Vector2i) -> Dictionary:
    var value: Variant = field.get(cell, null)
    if typeof(value) != TYPE_DICTIONARY:
        return {}
    return (value as Dictionary).duplicate(true)

func structure_cost_at(cell: Vector2i) -> int:
    if not is_ready() or not _world.has_terrain(cell):
        return MaterialCatalogClass.UNKNOWN_STRUCTURE_COST
    return _structure_cost(cell)

func _structure_cost(cell: Vector2i) -> int:
    var ids: Array[String] = _world.entities_at(cell, Layers.Channel.STRUCTURE)
    if ids.is_empty():
        return MaterialCatalogClass.OPEN_AIR_COST
    var result: int = 0
    for entity_id: String in ids:
        var entity: WorldEntityRecord = _world.entity(entity_id)
        if entity == null:
            result = maxi(result, MaterialCatalogClass.UNKNOWN_STRUCTURE_COST)
            continue
        var semantic: StringName = entity.semantic_type
        var door_state: StringName = &""
        if String(semantic).begins_with("door."):
            door_state = _doors.state(entity_id)
        result = maxi(result, _materials.structure_cost(semantic, door_state))
    return result

func _diagonal_corner_sealed(origin: Vector2i, offset: Vector2i) -> bool:
    var side_a := origin + Vector2i(offset.x, 0)
    var side_b := origin + Vector2i(0, offset.y)
    return _cell_strongly_sealed(side_a) and _cell_strongly_sealed(side_b)

func _cell_strongly_sealed(cell: Vector2i) -> bool:
    if not _world.has_terrain(cell):
        return true
    return _materials.is_strong_seal(_structure_cost(cell))

static func _heap_push(heap: Array[Dictionary], entry: Dictionary) -> void:
    heap.append(entry)
    var index: int = heap.size() - 1
    while index > 0:
        var parent: int = int(float(index - 1) / 2.0)
        if _entry_less(heap[parent], heap[index]):
            break
        var swap: Dictionary = heap[parent]
        heap[parent] = heap[index]
        heap[index] = swap
        index = parent

static func _heap_pop(heap: Array[Dictionary]) -> Dictionary:
    if heap.size() == 1:
        return heap.pop_back()
    var result: Dictionary = heap[0]
    heap[0] = heap.pop_back()
    var index: int = 0
    while true:
        var left: int = index * 2 + 1
        var right: int = left + 1
        var smallest: int = index
        if left < heap.size() and _entry_less(heap[left], heap[smallest]):
            smallest = left
        if right < heap.size() and _entry_less(heap[right], heap[smallest]):
            smallest = right
        if smallest == index:
            break
        var swap: Dictionary = heap[index]
        heap[index] = heap[smallest]
        heap[smallest] = swap
        index = smallest
    return result

static func _entry_less(a: Dictionary, b: Dictionary) -> bool:
    var cost_a: int = int(a.get("cost", 0))
    var cost_b: int = int(b.get("cost", 0))
    if cost_a != cost_b:
        return cost_a < cost_b
    var barrier_a: int = int(a.get("barrier_cost", 0))
    var barrier_b: int = int(b.get("barrier_cost", 0))
    if barrier_a != barrier_b:
        return barrier_a < barrier_b
    var cell_a: Vector2i = a.get("cell", Vector2i.ZERO)
    var cell_b: Vector2i = b.get("cell", Vector2i.ZERO)
    if cell_a.y == cell_b.y:
        return cell_a.x < cell_b.x
    return cell_a.y < cell_b.y
