extends ObserverPerceptionService
class_name InteractionTestPerception

## Focused CI double for System-29 knowledge filtering. It preserves the real
## ObserverPerceptionService type/signal contract while allowing deterministic
## VISIBLE/REMEMBERED/UNSEEN fixtures without coupling reach tests to LOS geometry.

var _test_observer_id: String = ""
var _states: Dictionary = {}

func _init(observer_id: String = "") -> void:
    _test_observer_id = observer_id.strip_edges()

func is_ready() -> bool:
    return not _test_observer_id.is_empty()

func observer_id() -> String:
    return _test_observer_id

func knowledge_state(cell: Vector2i) -> int:
    return int(_states.get(cell, ObserverPerceptionService.KnowledgeState.UNSEEN))

func set_knowledge_state(cell: Vector2i, state: int) -> bool:
    if state < ObserverPerceptionService.KnowledgeState.UNSEEN \
        or state > ObserverPerceptionService.KnowledgeState.VISIBLE:
        return false
    _states[cell] = state
    perception_changed.emit(&"test_knowledge_changed")
    return true

func set_states(states: Dictionary) -> bool:
    var normalized: Dictionary = {}
    for key: Variant in states.keys():
        if typeof(key) != TYPE_VECTOR2I:
            return false
        var state: int = int(states[key])
        if state < ObserverPerceptionService.KnowledgeState.UNSEEN \
            or state > ObserverPerceptionService.KnowledgeState.VISIBLE:
            return false
        normalized[key] = state
    _states = normalized
    perception_changed.emit(&"test_knowledge_reset")
    return true
