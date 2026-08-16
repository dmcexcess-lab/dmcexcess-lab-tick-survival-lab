extends RefCounted
class_name TickRules

## Shared foundation timing enums and validation. No gameplay meanings live here.

enum InterruptionPolicy {
    COMMITTED,
    RESUMABLE,
    CANCELABLE,
}

enum ActionStatus {
    RUNNING,
    COMPLETED,
    INTERRUPTED,
    CANCELED,
    FAILED,
}

enum EventKind {
    EXTERNAL,
    ACTION_PHASE,
    ACTION_COMPLETE,
}

enum RunStopReason {
    DECISION_REQUIRED,
    HARD_PAUSED,
    IDLE,
    SAFETY_LIMIT,
    BATCH_COMPLETE,
}

const DEFAULT_PRIORITY: int = 0
const DEFAULT_MAX_OPERATIONS: int = 100000
const TRACE_LIMIT: int = 256

static func is_valid_policy(value: int) -> bool:
    return value >= InterruptionPolicy.COMMITTED and value <= InterruptionPolicy.CANCELABLE

static func is_valid_action_status(value: int) -> bool:
    return value >= ActionStatus.RUNNING and value <= ActionStatus.FAILED

static func is_terminal_action_status(value: int) -> bool:
    return value in [ActionStatus.COMPLETED, ActionStatus.CANCELED, ActionStatus.FAILED]

static func is_valid_event_kind(value: int) -> bool:
    return value >= EventKind.EXTERNAL and value <= EventKind.ACTION_COMPLETE

static func is_valid_run_stop_reason(value: int) -> bool:
    return value >= RunStopReason.DECISION_REQUIRED and value <= RunStopReason.BATCH_COMPLETE

static func is_safe_payload(payload: Dictionary) -> bool:
    return _is_safe_value(payload)

static func copy_payload(payload: Dictionary) -> Dictionary:
    return payload.duplicate(true)

static func _is_safe_value(value: Variant) -> bool:
    match typeof(value):
        TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME:
            return true
        TYPE_ARRAY:
            for child: Variant in value:
                if not _is_safe_value(child):
                    return false
            return true
        TYPE_DICTIONARY:
            for key: Variant in value.keys():
                if typeof(key) not in [TYPE_STRING, TYPE_STRING_NAME]:
                    return false
                if not _is_safe_value(value[key]):
                    return false
            return true
        _:
            return false
