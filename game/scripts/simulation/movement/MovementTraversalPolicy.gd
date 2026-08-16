extends RefCounted
class_name MovementTraversalPolicy

const DecisionClass = preload("res://scripts/simulation/movement/MovementPolicyDecision.gd")

## Replaceable terrain traversal / base timing policy.
## Dynamic health, fatigue, encumbrance, equipment, stance, etc. belong in later
## policy adapters/providers, not in MovementActionService or WHEN.

const GOLDEN_TURN_TICKS: int = 3

var _turn_ticks: int = GOLDEN_TURN_TICKS
var _terrain_rules: Dictionary = {}

func _init(turn_ticks: int = GOLDEN_TURN_TICKS) -> void:
    _turn_ticks = maxi(1, turn_ticks)

func set_turn_ticks(turn_ticks: int) -> bool:
    if turn_ticks < 1:
        return false
    _turn_ticks = turn_ticks
    return true

func turn_duration(actor_id: String) -> int:
    if actor_id.strip_edges().is_empty():
        return 0
    return _turn_ticks

func register_terrain(semantic_type: StringName, traversable: bool, step_ticks: int = 0) -> bool:
    var key: String = String(semantic_type).strip_edges()
    if key.is_empty():
        return false
    if traversable and step_ticks < 1:
        return false
    _terrain_rules[key] = {
        "traversable": traversable,
        "step_ticks": step_ticks if traversable else 0,
    }
    return true

func has_terrain_rule(semantic_type: StringName) -> bool:
    return _terrain_rules.has(String(semantic_type))

func terrain_rule(semantic_type: StringName) -> Dictionary:
    var key: String = String(semantic_type)
    if not _terrain_rules.has(key):
        return {}
    var rule: Dictionary = _terrain_rules[key]
    return rule.duplicate(true)

func registered_terrain_types() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _terrain_rules.keys():
        result.append(String(key))
    result.sort()
    return result

func evaluate_step(actor_id: String, action_type: StringName, terrain_types: Array) -> MovementPolicyDecision:
    if actor_id.strip_edges().is_empty():
        return DecisionClass.denied(DecisionClass.Status.ACTOR_UNCLASSIFIED, "actor_unclassified")
    if String(action_type).strip_edges().is_empty():
        return DecisionClass.denied(DecisionClass.Status.CAPABILITY_UNKNOWN, "movement_action_unclassified")
    if terrain_types.is_empty():
        return DecisionClass.denied(DecisionClass.Status.TERRAIN_UNCLASSIFIED, "terrain_unclassified")

    var duration_ticks: int = 0
    for terrain_value: Variant in terrain_types:
        var terrain_key: String = String(terrain_value).strip_edges()
        if terrain_key.is_empty() or not _terrain_rules.has(terrain_key):
            return DecisionClass.denied(DecisionClass.Status.TERRAIN_UNCLASSIFIED, "terrain_unclassified")
        var rule: Dictionary = _terrain_rules[terrain_key]
        if not bool(rule.get("traversable", false)):
            return DecisionClass.denied(DecisionClass.Status.TERRAIN_BLOCKED, "terrain_blocked")
        duration_ticks = maxi(duration_ticks, int(rule.get("step_ticks", 0)))

    if duration_ticks < 1:
        return DecisionClass.denied(DecisionClass.Status.INVALID_DURATION, "invalid_duration")
    return DecisionClass.allowed(duration_ticks)

func evaluate_turn(actor_id: String, action_type: StringName) -> MovementPolicyDecision:
    if actor_id.strip_edges().is_empty():
        return DecisionClass.denied(DecisionClass.Status.ACTOR_UNCLASSIFIED, "actor_unclassified")
    if String(action_type).strip_edges().is_empty():
        return DecisionClass.denied(DecisionClass.Status.CAPABILITY_UNKNOWN, "movement_action_unclassified")
    if _turn_ticks < 1:
        return DecisionClass.denied(DecisionClass.Status.INVALID_DURATION, "invalid_duration")
    return DecisionClass.allowed(_turn_ticks)
