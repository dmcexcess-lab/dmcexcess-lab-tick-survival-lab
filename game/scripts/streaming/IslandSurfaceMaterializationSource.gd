extends RefCounted
class_name IslandSurfaceMaterializationSource

const ProjectionClass = preload("res://scripts/generation/integration/IslandSurfaceRequestProjection.gd")
const GeneratorClass = preload("res://scripts/generation/areas/IslandSurfaceAreaGenerator.gd")
const CatalogClass = preload("res://scripts/streaming/IslandSurfaceSourceCatalog.gd")

const SOURCE_KIND: StringName = &"system20_island_surface"

var _registry: MaterializationRegistry = null
var _catalog: IslandSurfaceSourceCatalog = null
var _projection: IslandSurfaceRequestProjection = ProjectionClass.new()
var _generator: IslandSurfaceAreaGenerator = GeneratorClass.new()

func _init(registry: MaterializationRegistry = null, catalog: IslandSurfaceSourceCatalog = null) -> void:
    _registry = registry
    _catalog = catalog

func is_ready() -> bool:
    return _registry != null and _catalog != null and _catalog.is_ready()

func source_kind() -> StringName:
    return SOURCE_KIND

func validate_source_bounds(plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if not is_ready():
        return {"ok": false, "failure_reason": "island_surface_source_not_ready"}
    return _catalog.validate_source_bounds(plan)

func source_handle(plan: GeneratedGlobalWorldPlan, source_id: String) -> Dictionary:
    if plan == null or not plan.is_generated() or not bool(validate_source_bounds(plan).get("ok", false)):
        return {}
    return _catalog.source_handle_for_id(source_id)

func source_handles_intersecting(plan: GeneratedGlobalWorldPlan, bounds_list: Array[Rect2i]) -> Array[Dictionary]:
    if plan == null or not plan.is_generated() or not bool(validate_source_bounds(plan).get("ok", false)):
        return []
    return _catalog.source_handles_intersecting(bounds_list)

func prepare(plan: GeneratedGlobalWorldPlan, source_id: String) -> Dictionary:
    if not is_ready() or plan == null or not plan.is_generated():
        return _failure("invalid_island_surface_materialization_input")
    var descriptor: Dictionary = _catalog.descriptor(source_id)
    if descriptor.is_empty():
        return _failure("island_surface_source_missing")
    var source_key: String = String(descriptor.get("source_key", ""))
    if _registry.has_source(source_key):
        return _failure("source_already_materialized")
    var projected: Dictionary = _projection.project(plan, source_id, descriptor.get("bounds", Rect2i()))
    if not bool(projected.get("ok", false)):
        return _failure("island_surface_projection_failed:%s" % String(projected.get("failure_reason", "unknown")))
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    var generated: GeneratedAreaPlan = _generator.generate(request)
    if generated == null or not generated.is_generated():
        return _failure("island_surface_generation_failed:%s" % ("null" if generated == null else generated.failure_reason))
    return {
        "ok": true,
        "failure_reason": "",
        "source_key": source_key,
        "source_kind": SOURCE_KIND,
        "source_id": source_id,
        "bounds": descriptor.get("bounds", Rect2i()),
        "source_seed": int(descriptor.get("source_seed", plan.seed)),
        "request": request,
        "plan": generated,
        "plan_signature": generated.signature(),
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
