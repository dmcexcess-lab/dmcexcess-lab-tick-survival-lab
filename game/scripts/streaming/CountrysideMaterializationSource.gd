extends RefCounted
class_name CountrysideMaterializationSource

const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const CatalogClass = preload("res://scripts/streaming/CountrysideSourceCatalog.gd")

const SOURCE_KIND: StringName = &"system20_rural_open"

var _registry: MaterializationRegistry = null
var _catalog: CountrysideSourceCatalog = null
var _projector: System20AreaRequestProjector = null
var _generator: LocalAreaGenerator = null

func _init(
    registry: MaterializationRegistry = null,
    catalog: CountrysideSourceCatalog = null,
    projector: System20AreaRequestProjector = null,
    generator: LocalAreaGenerator = null
) -> void:
    _registry = registry
    _catalog = catalog
    _projector = projector if projector != null else ProjectorClass.new()
    _generator = generator if generator != null else GeneratorClass.new()

func is_ready() -> bool:
    return _registry != null and _catalog != null and _catalog.is_ready() \
        and _projector != null and _generator != null

func catalog() -> CountrysideSourceCatalog:
    return _catalog

func validate_source_bounds(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if not is_ready():
        return {"ok": false, "failure_reason": "countryside_materialization_source_not_ready"}
    return _catalog.validate_source_bounds(global_plan)

func source_handle_for_id(source_id: String) -> Dictionary:
    if not is_ready():
        return {}
    return _catalog.source_handle_for_id(source_id)

func source_handles_intersecting(
    global_plan: GeneratedGlobalWorldPlan,
    bounds_list: Array[Rect2i]
) -> Array[Dictionary]:
    if not is_ready() or global_plan == null or not global_plan.is_generated():
        return []
    var validation: Dictionary = _catalog.validate_source_bounds(global_plan)
    if not bool(validation.get("ok", false)):
        return []
    return _catalog.source_handles_intersecting(bounds_list)

func prepare(global_plan: GeneratedGlobalWorldPlan, source_id: String) -> Dictionary:
    if not is_ready() or global_plan == null or not global_plan.is_generated():
        return _failure("invalid_countryside_materialization_source_input")
    var validation: Dictionary = _catalog.validate_source_bounds(global_plan)
    if not bool(validation.get("ok", false)):
        return _failure("countryside_catalog_invalid:%s" % String(validation.get("failure_reason", "unknown")))

    var clean_source_id: String = source_id.strip_edges()
    var descriptor: Dictionary = _catalog.descriptor(clean_source_id)
    if clean_source_id.is_empty() or descriptor.is_empty():
        return _failure("countryside_source_missing")
    if StringName(descriptor.get("source_kind", &"")) != SOURCE_KIND:
        return _failure("countryside_source_kind_invalid")

    var source_key: String = String(descriptor.get("source_key", "")).strip_edges()
    var bounds: Rect2i = descriptor.get("bounds", Rect2i())
    var source_seed: int = int(descriptor.get("source_seed", 0))
    if source_key.is_empty() or bounds.size.x <= 0 or bounds.size.y <= 0:
        return _failure("countryside_source_descriptor_invalid")
    if _registry.has_source(source_key):
        return _failure("source_already_materialized")

    var projected: Dictionary = _projector.project_rural_open_bounds(global_plan, clean_source_id, bounds)
    if not bool(projected.get("ok", false)):
        return _failure("countryside_projection_failed:%s" % String(projected.get("failure_reason", "unknown")))
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    if request == null or not request.is_valid():
        return _failure("countryside_projection_request_invalid")
    if request.area_id != clean_source_id \
        or request.bounds != bounds \
        or request.seed != source_seed \
        or request.area_profile_id != AreaProfilesClass.RURAL_OPEN \
        or request.environment_profile_id != EnvironmentProfilesClass.TEMPERATE_RURAL:
        return _failure("countryside_projected_identity_mismatch")

    var plan: GeneratedAreaPlan = _generator.generate(request)
    if plan == null or not plan.is_generated():
        var reason: String = "null_plan" if plan == null else plan.failure_reason
        return _failure("countryside_local_generation_failed:%s" % reason)
    if plan.area_id != clean_source_id \
        or plan.bounds != bounds \
        or plan.seed != source_seed \
        or plan.area_profile_id != AreaProfilesClass.RURAL_OPEN \
        or plan.environment_profile_id != EnvironmentProfilesClass.TEMPERATE_RURAL:
        return _failure("prepared_countryside_identity_mismatch")

    return {
        "ok": true,
        "failure_reason": "",
        "source_key": source_key,
        "source_kind": SOURCE_KIND,
        "source_id": clean_source_id,
        "bounds": bounds,
        "source_seed": source_seed,
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
