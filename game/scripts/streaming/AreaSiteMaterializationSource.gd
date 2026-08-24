extends RefCounted
class_name AreaSiteMaterializationSource

const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")

const SOURCE_KIND: StringName = &"system20_area_site"

var _registry: MaterializationRegistry = null
var _projector: System20AreaRequestProjector = null
var _generator: LocalAreaGenerator = null

func _init(
    registry: MaterializationRegistry = null,
    projector: System20AreaRequestProjector = null,
    generator: LocalAreaGenerator = null
) -> void:
    _registry = registry
    _projector = projector if projector != null else ProjectorClass.new()
    _generator = generator if generator != null else GeneratorClass.new()

func is_ready() -> bool:
    return _registry != null and _projector != null and _generator != null

func source_kind() -> StringName:
    return SOURCE_KIND

func source_key_for_site(site_id: String) -> String:
    var clean: String = site_id.strip_edges()
    if clean.is_empty():
        return ""
    return "system20_area_site:%s" % clean

func source_handle(global_plan: GeneratedGlobalWorldPlan, source_id: String) -> Dictionary:
    return source_handle_for_site(global_plan, source_id)

func source_handle_for_site(global_plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    if global_plan == null or not global_plan.is_generated():
        return {}
    var clean_site_id: String = site_id.strip_edges()
    var site: Dictionary = _site_by_id(global_plan.area_sites, clean_site_id)
    if clean_site_id.is_empty() or site.is_empty():
        return {}
    var bounds: Rect2i = site.get("bounds", Rect2i())
    var source_key: String = source_key_for_site(clean_site_id)
    if source_key.is_empty() or bounds.size.x <= 0 or bounds.size.y <= 0:
        return {}
    return {
        "source_kind": SOURCE_KIND,
        "source_id": clean_site_id,
        "source_key": source_key,
        "bounds": bounds,
    }

func source_handles_intersecting(
    global_plan: GeneratedGlobalWorldPlan,
    bounds_list: Array[Rect2i]
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for site_id: String in site_ids_intersecting(global_plan, bounds_list):
        var handle: Dictionary = source_handle_for_site(global_plan, site_id)
        if not handle.is_empty():
            result.append(handle)
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("source_key", "")) < String(b.get("source_key", ""))
    )
    return result

func validate_source_bounds(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if global_plan == null or not global_plan.is_generated():
        return {"ok": false, "failure_reason": "invalid_global_plan"}
    var ordered: Array[Dictionary] = global_plan.area_sites.duplicate(true)
    ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    for index in range(ordered.size()):
        var site: Dictionary = ordered[index]
        var site_id: String = String(site.get("id", "")).strip_edges()
        var bounds: Rect2i = site.get("bounds", Rect2i())
        if site_id.is_empty() or bounds.size.x <= 0 or bounds.size.y <= 0 or not _rect_inside(global_plan.bounds, bounds):
            return {"ok": false, "failure_reason": "area_site_bounds_invalid:%s" % site_id}
        for other_index in range(index + 1, ordered.size()):
            var other: Dictionary = ordered[other_index]
            var other_bounds: Rect2i = other.get("bounds", Rect2i())
            if _rects_overlap_positive(bounds, other_bounds):
                return {
                    "ok": false,
                    "failure_reason": "area_site_bounds_overlap:%s:%s" % [site_id, String(other.get("id", ""))],
                }
    return {"ok": true, "failure_reason": ""}

func site_ids_intersecting(global_plan: GeneratedGlobalWorldPlan, bounds_list: Array[Rect2i]) -> Array[String]:
    var result: Array[String] = []
    if global_plan == null or not global_plan.is_generated() or bounds_list.is_empty():
        return result
    for site: Dictionary in global_plan.area_sites:
        var site_id: String = String(site.get("id", "")).strip_edges()
        var site_bounds: Rect2i = site.get("bounds", Rect2i())
        if site_id.is_empty() or site_bounds.size.x <= 0 or site_bounds.size.y <= 0:
            continue
        var intersects: bool = false
        for query_bounds: Rect2i in bounds_list:
            if _rects_overlap_positive(site_bounds, query_bounds):
                intersects = true
                break
        if intersects:
            result.append(site_id)
    result.sort()
    return result

func prepare(global_plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    if not is_ready() or global_plan == null or not global_plan.is_generated():
        return _failure("invalid_materialization_source_input")
    var clean_site_id: String = site_id.strip_edges()
    if clean_site_id.is_empty():
        return _failure("area_site_id_invalid")
    var site: Dictionary = _site_by_id(global_plan.area_sites, clean_site_id)
    if site.is_empty():
        return _failure("area_site_missing")
    var source_key: String = source_key_for_site(clean_site_id)
    if source_key.is_empty():
        return _failure("source_key_invalid")
    if _registry.has_source(source_key):
        return _failure("source_already_materialized")

    var projected: Dictionary = _projector.project_site(global_plan, clean_site_id)
    if not bool(projected.get("ok", false)):
        return _failure("site_projection_failed:%s" % String(projected.get("failure_reason", "unknown")))
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    if request == null or not request.is_valid():
        return _failure("site_projection_request_invalid")

    var plan: GeneratedAreaPlan = _generator.generate(request)
    if plan == null or not plan.is_generated():
        var reason: String = "null_plan" if plan == null else plan.failure_reason
        return _failure("site_local_generation_failed:%s" % reason)

    var site_bounds: Rect2i = site.get("bounds", Rect2i())
    var site_seed: int = int(site.get("seed", 0))
    if request.area_id != clean_site_id or plan.area_id != clean_site_id:
        return _failure("prepared_area_identity_mismatch")
    if request.bounds != site_bounds or plan.bounds != site_bounds:
        return _failure("prepared_area_bounds_mismatch")
    if request.seed != site_seed or plan.seed != site_seed:
        return _failure("prepared_area_seed_mismatch")

    return {
        "ok": true,
        "failure_reason": "",
        "source_key": source_key,
        "source_kind": SOURCE_KIND,
        "source_id": clean_site_id,
        "bounds": site_bounds,
        "source_seed": site_seed,
        "request": request,
        "plan": plan,
        "plan_signature": plan.signature(),
    }

func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "source_key": "",
        "source_kind": SOURCE_KIND,
        "source_id": "",
        "request": null,
        "plan": null,
    }

func _site_by_id(sites: Array[Dictionary], site_id: String) -> Dictionary:
    for site: Dictionary in sites:
        if String(site.get("id", "")) == site_id:
            return site
    return {}

func _rects_overlap_positive(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    var a_end: Vector2i = a.position + a.size
    var b_end: Vector2i = b.position + b.size
    return a.position.x < b_end.x and a_end.x > b.position.x \
        and a.position.y < b_end.y and a_end.y > b.position.y

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if outer.size.x <= 0 or outer.size.y <= 0 or inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_last: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(inner_last)
