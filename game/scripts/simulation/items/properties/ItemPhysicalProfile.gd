extends RefCounted
class_name ItemPhysicalProfile

## Immutable-style semantic physical item definition used by 13D.

var semantic_type: StringName = &""
var weight_grams: int = 0

func _init(semantic_type_value: StringName = &"", weight_grams_value: int = 0) -> void:
    semantic_type = semantic_type_value
    weight_grams = weight_grams_value

func is_valid() -> bool:
    var semantic: String = String(semantic_type).strip_edges()
    return semantic.begins_with("item.") and semantic.length() > 5 and weight_grams > 0

func copy() -> ItemPhysicalProfile:
    return ItemPhysicalProfile.new(semantic_type, weight_grams)
