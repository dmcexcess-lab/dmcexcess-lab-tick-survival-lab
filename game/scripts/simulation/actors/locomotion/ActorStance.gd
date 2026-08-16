extends RefCounted
class_name ActorStance

const STANDING: StringName = &"standing"
const CROUCHED: StringName = &"crouched"

static func is_valid(value: StringName) -> bool:
    return value == STANDING or value == CROUCHED

static func normalized(value: Variant) -> StringName:
    var stance := StringName(String(value).strip_edges())
    if not is_valid(stance):
        return &""
    return stance
