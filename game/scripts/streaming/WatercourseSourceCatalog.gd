extends RefCounted
class_name WatercourseSourceCatalog

## Compatibility shell for old fixture composition. Live island generation no longer owns rivers,
## so this catalog deliberately exposes zero sources and performs no hydrology work.
const CATALOG_VERSION: int = 2
const SOURCE_KIND: StringName = &"system20_watercourse"

var _plan: GeneratedGlobalWorldPlan = null
var _plan_signature: String = ""
var _failure_reason: String = ""

func _init(plan: GeneratedGlobalWorldPlan = null) -> void:
    if plan != null:
        configure(plan)

func configure(plan: GeneratedGlobalWorldPlan) -> bool:
    _plan = null
    _plan_signature = ""
    _failure_reason = ""
    if plan == null or not plan.is_generated():
        _failure_reason = "invalid_watercourse_catalog_input"
        return false
    _plan = plan
    _plan_signature = plan.signature()
    return true

func is_ready() -> bool:
    return _plan != null and _failure_reason.is_empty() and not _plan_signature.is_empty()

func failure_reason() -> String:
    return _failure_reason

func sources() -> Array[Dictionary]:
    return []

func descriptor(_source_id: String) -> Dictionary:
    return {}

func source_handle_for_id(_source_id: String) -> Dictionary:
    return {}

func source_handles_intersecting(_bounds_list: Array[Rect2i]) -> Array[Dictionary]:
    return []

func validate_source_bounds(plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if not is_ready() or plan != _plan:
        return {"ok": false, "failure_reason": "watercourse_catalog_plan_mismatch"}
    return {"ok": true, "failure_reason": ""}
