extends RefCounted
class_name WorldEntityId

## Opaque persistent-entity identity helpers.
## Consumers may compare/store IDs but must not derive gameplay meaning from format.

const MAX_ID_LENGTH: int = 256

static func is_valid(value: String) -> bool:
    if value.is_empty() or value.length() > MAX_ID_LENGTH:
        return false
    if value != value.strip_edges():
        return false
    if value.contains("\n") or value.contains("\r") or value.contains("\t"):
        return false
    return true

static func runtime_id(serial: int) -> String:
    if serial < 1:
        push_error("WorldEntityId.runtime_id: serial must be >= 1")
        return ""
    return "entity_%016d" % serial
