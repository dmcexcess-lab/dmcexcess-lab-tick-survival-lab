extends RefCounted
class_name CraftingRecipe

const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

## Immutable-style System 32 recipe configuration. Requirements count real physical
## item entities; there is no stack/quantity abstraction hidden here. Every recipe also
## names the broad competence applied to those concrete physical requirements.

var recipe_id: StringName = &""
var label: String = ""
var duration_ticks: int = 0
var consumed_inputs: Array[Dictionary] = []
var required_tools: Array[Dictionary] = []
var workstation_capability: StringName = &""
var outputs: Array[Dictionary] = []
var skill_id: StringName = &""
var skill_difficulty: int = 0

func _init(
    id: StringName = &"",
    label_value: String = "",
    duration: int = 0,
    inputs: Array = [],
    tools: Array = [],
    workstation: StringName = &"",
    output_values: Array = [],
    skill: StringName = &"",
    difficulty: int = 0
) -> void:
    recipe_id = id
    label = label_value.strip_edges()
    duration_ticks = duration
    workstation_capability = workstation
    skill_id = skill
    skill_difficulty = difficulty
    for value: Variant in inputs:
        if typeof(value) == TYPE_DICTIONARY:
            consumed_inputs.append((value as Dictionary).duplicate(true))
    for value: Variant in tools:
        if typeof(value) == TYPE_DICTIONARY:
            required_tools.append((value as Dictionary).duplicate(true))
    for value: Variant in output_values:
        if typeof(value) == TYPE_DICTIONARY:
            outputs.append((value as Dictionary).duplicate(true))

func is_valid() -> bool:
    if String(recipe_id).strip_edges().is_empty() or label.is_empty() or duration_ticks < 1:
        return false
    if consumed_inputs.is_empty() or outputs.is_empty():
        return false
    if not SkillCatalog.is_valid(skill_id) or not SkillCatalog.is_valid_difficulty(skill_difficulty):
        return false
    if not _requirements_valid(consumed_inputs) or not _requirements_valid(required_tools) or not _requirements_valid(outputs):
        return false
    var input_semantics: Dictionary = {}
    for requirement: Dictionary in consumed_inputs:
        var semantic: String = String(requirement.get("semantic_type", ""))
        if input_semantics.has(semantic):
            return false
        input_semantics[semantic] = true
    for requirement: Dictionary in required_tools:
        var semantic: String = String(requirement.get("semantic_type", ""))
        if input_semantics.has(semantic):
            return false
    return true

func copy() -> CraftingRecipe:
    return CraftingRecipe.new(
        recipe_id,
        label,
        duration_ticks,
        consumed_inputs,
        required_tools,
        workstation_capability,
        outputs,
        skill_id,
        skill_difficulty
    )

func consumed_entity_count() -> int:
    return _requirement_count(consumed_inputs)

func tool_entity_count() -> int:
    return _requirement_count(required_tools)

func output_entity_count() -> int:
    return _requirement_count(outputs)

static func requirement(semantic_type: StringName, count: int = 1) -> Dictionary:
    return {"semantic_type": semantic_type, "count": count}

static func _requirements_valid(values: Array[Dictionary]) -> bool:
    for requirement_value: Dictionary in values:
        var semantic: String = String(requirement_value.get("semantic_type", "")).strip_edges()
        if not semantic.begins_with("item.") or semantic.length() <= 5:
            return false
        if int(requirement_value.get("count", 0)) < 1:
            return false
    return true

static func _requirement_count(values: Array[Dictionary]) -> int:
    var total: int = 0
    for requirement_value: Dictionary in values:
        total += int(requirement_value.get("count", 0))
    return total
