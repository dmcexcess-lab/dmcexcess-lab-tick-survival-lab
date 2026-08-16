extends RefCounted
class_name TickEventQueue

## Deterministic min-heap. Queue state is timing infrastructure, not gameplay state.

var _heap: Array[ScheduledEvent] = []
var _known_serials: Dictionary = {}
var _canceled_serials: Dictionary = {}

func clear() -> void:
    _heap.clear()
    _known_serials.clear()
    _canceled_serials.clear()

func active_count() -> int:
    return _known_serials.size()

func is_empty() -> bool:
    _discard_canceled_top()
    return _heap.is_empty()

func contains(serial: int) -> bool:
    return _known_serials.has(serial)

func push(event: ScheduledEvent) -> bool:
    if event == null or not event.is_valid(-1, true):
        return false
    if _known_serials.has(event.serial) or _canceled_serials.has(event.serial):
        return false
    var stored: ScheduledEvent = event.copy()
    _heap.append(stored)
    _known_serials[stored.serial] = true
    _sift_up(_heap.size() - 1)
    return true

func peek() -> ScheduledEvent:
    _discard_canceled_top()
    if _heap.is_empty():
        return null
    return _heap[0]

func pop() -> ScheduledEvent:
    _discard_canceled_top()
    if _heap.is_empty():
        return null
    var result: ScheduledEvent = _heap[0]
    _remove_root()
    _known_serials.erase(result.serial)
    return result

func cancel(serial: int) -> bool:
    if not _known_serials.has(serial):
        return false
    _known_serials.erase(serial)
    _canceled_serials[serial] = true
    return true

func cancel_action_events(action_serial: int) -> int:
    if action_serial < 1:
        return 0
    var canceled_count: int = 0
    var serials: Array[int] = []
    for event: ScheduledEvent in _heap:
        if event.action_serial == action_serial and _known_serials.has(event.serial):
            serials.append(event.serial)
    for serial: int in serials:
        if cancel(serial):
            canceled_count += 1
    return canceled_count

func snapshot_entries() -> Array:
    var ordered: Array[ScheduledEvent] = []
    for event: ScheduledEvent in _heap:
        if _known_serials.has(event.serial):
            ordered.append(event.copy())
    ordered.sort_custom(ScheduledEvent.less)
    var result: Array = []
    for event: ScheduledEvent in ordered:
        result.append(event.to_snapshot())
    return result

func restored_copy() -> TickEventQueue:
    var result := TickEventQueue.new()
    var ordered: Array[ScheduledEvent] = []
    for event: ScheduledEvent in _heap:
        if _known_serials.has(event.serial):
            ordered.append(event.copy())
    ordered.sort_custom(ScheduledEvent.less)
    for event: ScheduledEvent in ordered:
        result.push(event)
    return result

func _discard_canceled_top() -> void:
    while not _heap.is_empty() and _canceled_serials.has(_heap[0].serial):
        var serial: int = _heap[0].serial
        _remove_root()
        _canceled_serials.erase(serial)

func _remove_root() -> void:
    var last_index: int = _heap.size() - 1
    if last_index < 0:
        return
    if last_index == 0:
        _heap.pop_back()
        return
    _heap[0] = _heap[last_index]
    _heap.pop_back()
    _sift_down(0)

func _sift_up(index: int) -> void:
    var child: int = index
    while child > 0:
        var parent: int = (child - 1) / 2
        if not ScheduledEvent.less(_heap[child], _heap[parent]):
            break
        var temp: ScheduledEvent = _heap[parent]
        _heap[parent] = _heap[child]
        _heap[child] = temp
        child = parent

func _sift_down(index: int) -> void:
    var parent: int = index
    var size: int = _heap.size()
    while true:
        var left: int = parent * 2 + 1
        var right: int = left + 1
        var smallest: int = parent
        if left < size and ScheduledEvent.less(_heap[left], _heap[smallest]):
            smallest = left
        if right < size and ScheduledEvent.less(_heap[right], _heap[smallest]):
            smallest = right
        if smallest == parent:
            return
        var temp: ScheduledEvent = _heap[parent]
        _heap[parent] = _heap[smallest]
        _heap[smallest] = temp
        parent = smallest
