extends RefCounted
class_name ActorMoodlet

## One derived readable status record owned by 13F presentation logic.

enum Severity {
    POSITIVE,
    NOTICE,
    WARNING,
    CRITICAL,
}

var moodlet_id: StringName = &""
var display_name: String = ""
var severity: int = Severity.NOTICE
var priority: int = 0

func _init(
    moodlet_id_value: StringName = &"",
    display_name_value: String = "",
    severity_value: int = Severity.NOTICE,
    priority_value: int = 0
) -> void:
    moodlet_id = moodlet_id_value
    display_name = display_name_value
    severity = severity_value
    priority = priority_value

func is_valid() -> bool:
    return (
        not String(moodlet_id).strip_edges().is_empty()
        and not display_name.strip_edges().is_empty()
        and severity >= Severity.POSITIVE
        and severity <= Severity.CRITICAL
    )

func copy() -> ActorMoodlet:
    return ActorMoodlet.new(moodlet_id, display_name, severity, priority)
