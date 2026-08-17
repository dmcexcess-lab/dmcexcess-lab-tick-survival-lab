extends RefCounted
class_name ActorInjuryRecord

## One persistent injury fact owned by 13A Health.

enum Severity {
    MINOR = 1,
    SERIOUS = 2,
    CRITICAL = 3,
}

const HEAD: StringName = &"head"
const TORSO: StringName = &"torso"
const LEFT_ARM: StringName = &"left_arm"
const RIGHT_ARM: StringName = &"right_arm"
const LEFT_LEG: StringName = &"left_leg"
const RIGHT_LEG: StringName = &"right_leg"

var injury_id: String = ""
var injury_type: StringName = &""
var body_region: StringName = &""
var severity: int = Severity.MINOR
var stabilized: bool = false
var treated: bool = false

func _init(
    injury_id_value: String = "",
    injury_type_value: StringName = &"",
    body_region_value: StringName = &"",
    severity_value: int = Severity.MINOR,
    stabilized_value: bool = false,
    treated_value: bool = false
) -> void:
    injury_id = injury_id_value
    injury_type = injury_type_value
    body_region = body_region_value
    severity = severity_value
    stabilized = stabilized_value
    treated = treated_value

func copy() -> ActorInjuryRecord:
    return ActorInjuryRecord.new(injury_id, injury_type, body_region, severity, stabilized, treated)

func is_valid() -> bool:
    return (
        not injury_id.is_empty()
        and injury_id == injury_id.strip_edges()
        and not String(injury_type).strip_edges().is_empty()
        and is_valid_region(body_region)
        and is_valid_severity(severity)
    )

func to_snapshot() -> Dictionary:
    return {
        "injury_id": injury_id,
        "injury_type": String(injury_type),
        "body_region": String(body_region),
        "severity": severity,
        "stabilized": stabilized,
        "treated": treated,
    }

static func from_snapshot(data: Dictionary) -> ActorInjuryRecord:
    var value := ActorInjuryRecord.new(
        String(data.get("injury_id", "")),
        StringName(String(data.get("injury_type", ""))),
        StringName(String(data.get("body_region", ""))),
        int(data.get("severity", -1)),
        bool(data.get("stabilized", false)),
        bool(data.get("treated", false))
    )
    if not value.is_valid():
        return null
    return value

static func regions() -> Array[StringName]:
    return [HEAD, TORSO, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG]

static func is_valid_region(value: StringName) -> bool:
    return value == HEAD or value == TORSO or value == LEFT_ARM or value == RIGHT_ARM or value == LEFT_LEG or value == RIGHT_LEG

static func is_valid_severity(value: int) -> bool:
    return value >= Severity.MINOR and value <= Severity.CRITICAL
