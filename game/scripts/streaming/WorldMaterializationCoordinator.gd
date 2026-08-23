extends RefCounted
class_name WorldMaterializationCoordinator

const AreaMaterializerClass = preload("res://scripts/generation/areas/AreaMaterializationCoordinator.gd")
const AreaSourceClass = preload("res://scripts/streaming/AreaSiteMaterializationSource.gd")
const RecordClass = preload("res://scripts/streaming/MaterializationRecord.gd")

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _door_state: DoorStateStore = null
var _door_mutations: DoorStateMutationService = null
var _registry: MaterializationRegistry = null
var _source: AreaSiteMaterializationSource = null
var _countryside_source: CountrysideMaterializationSource = null
var _area_materializer: AreaMaterializationCoordinator = null

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    door_state: DoorStateStore = null,
    door_mutations: DoorStateMutationService = null,
    registry: MaterializationRegistry = null,
    source: AreaSiteMaterializationSource = null,
    countryside_source: CountrysideMaterializationSource = null
) -> void:
    _world = world
    _mutations = mutations
    _door_state = door_state
    _door_mutations = door_mutations
    _registry = registry
    _source = source if source != null else AreaSourceClass.new(registry)
    _countryside_source = countryside_source
    _area_materializer = AreaMaterializerClass.new(world, mutations, door_state, door_mutations)

func is_ready() -> bool:
    return _world != null and _mutations != null and _mutations.is_ready() \
        and _door_state != null and _door_mutations != null and _door_mutations.is_ready() \
        and _registry != null and _source != null and _source.is_ready() \
        and _area_materializer != null and _area_materializer.is_ready()

func registry() -> MaterializationRegistry:
    return _registry

func ensure_area_site(global_plan: GeneratedGlobalWorldPlan, site_id: String) -> Dictionary:
    return ensure_area_sites(global_plan, [site_id])

func ensure_area_sites(global_plan: GeneratedGlobalWorldPlan, site_ids: Array) -> Dictionary:
    if not is_ready() or global_plan == null or not global_plan.is_generated():
        return _failure("invalid_world_materialization_input")
    var handles: Array[Dictionary] = []
    for site_value: Variant in site_ids:
        var site_id: String = String(site_value).strip_edges()
        var handle: Dictionary = _source.source_handle_for_site(global_plan, site_id)
        if handle.is_empty():
            return _failure("unknown_area_site:%s" % site_id)
        handles.append(handle)
    return ensure_sources(global_plan, handles)

func ensure_sources(global_plan: GeneratedGlobalWorldPlan, source_handles: Array) -> Dictionary:
    if not is_ready() or global_plan == null or not global_plan.is_generated():
        return _failure("invalid_world_materialization_input")

    var catalog_check: Dictionary = _validate_source_catalogs(global_plan)
    if not bool(catalog_check.get("ok", false)):
        return _failure(String(catalog_check.get("failure_reason", "materialization_source_bounds_invalid")))

    if source_handles.is_empty():
        return _success([], [])

    var requested_by_key: Dictionary = {}
    for handle_value: Variant in source_handles:
        if typeof(handle_value) != TYPE_DICTIONARY:
            return _failure("materialization_source_handle_invalid")
        var supplied: Dictionary = handle_value
        var canonical: Dictionary = _canonical_handle(global_plan, supplied)
        if canonical.is_empty():
            return _failure("materialization_source_handle_unknown")
        if not _handles_equivalent(supplied, canonical):
            return _failure("materialization_source_handle_mismatch:%s" % String(supplied.get("source_key", "")))
        var source_key: String = String(canonical.get("source_key", ""))
        if requested_by_key.has(source_key):
            var existing: Dictionary = requested_by_key[source_key]
            if not _handles_equivalent(existing, canonical):
                return _failure("materialization_source_handle_conflict:%s" % source_key)
        else:
            requested_by_key[source_key] = canonical

    var ordered_keys: Array[String] = []
    for key_value: Variant in requested_by_key.keys():
        ordered_keys.append(String(key_value))
    ordered_keys.sort()

    var already: Array[String] = []
    var missing: Array[Dictionary] = []
    for source_key: String in ordered_keys:
        if _registry.has_source(source_key):
            already.append(source_key)
        else:
            missing.append((requested_by_key[source_key] as Dictionary).duplicate(true))

    if missing.is_empty():
        return _success([], already)

    var prepared: Array[Dictionary] = []
    for handle: Dictionary in missing:
        var result: Dictionary = _prepare_handle(global_plan, handle)
        if not bool(result.get("ok", false)):
            return _failure(String(result.get("failure_reason", "materialization_source_prepare_failed")), already)
        if not _prepared_result_valid(result) or not _prepared_matches_handle(result, handle):
            return _failure("materialization_source_prepare_invalid:%s" % String(handle.get("source_key", "")), already)
        prepared.append(result)
    prepared.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("source_key", "")) < String(b.get("source_key", ""))
    )

    var world_snapshot: Dictionary = _world.snapshot()
    var door_snapshot: Dictionary = _door_state.snapshot()
    var registry_snapshot: Dictionary = _registry.snapshot()
    var newly: Array[String] = []

    for entry: Dictionary in prepared:
        var request: AreaGenerationRequest = entry.get("request") as AreaGenerationRequest
        var plan: GeneratedAreaPlan = entry.get("plan") as GeneratedAreaPlan
        if request == null or plan == null or not _area_materializer.materialize(request, plan):
            if not _rollback(world_snapshot, door_snapshot, registry_snapshot):
                return _failure("materialization_failed_and_rollback_failed", already)
            return _failure("area_materialization_failed:%s" % String(entry.get("source_id", "")), already)

        var record := RecordClass.new(
            String(entry.get("source_key", "")),
            StringName(entry.get("source_kind", &"")),
            String(entry.get("source_id", "")),
            entry.get("bounds", Rect2i()),
            int(entry.get("source_seed", 0)),
            plan.area_profile_id,
            plan.area_profile_version,
            plan.environment_profile_id,
            plan.environment_profile_version,
            String(entry.get("plan_signature", "")),
            _world.revision(),
            _door_state.revision()
        )
        if not record.is_valid() or not _registry.mark_materialized(record):
            if not _rollback(world_snapshot, door_snapshot, registry_snapshot):
                return _failure("registry_commit_failed_and_rollback_failed", already)
            return _failure("materialization_registry_commit_failed:%s" % String(entry.get("source_id", "")), already)
        newly.append(record.source_key)

    return _success(newly, already)

func _validate_source_catalogs(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var site_check: Dictionary = _source.validate_source_bounds(global_plan)
    if not bool(site_check.get("ok", false)):
        return site_check
    if _countryside_source != null:
        if not _countryside_source.is_ready():
            return {"ok": false, "failure_reason": "countryside_materialization_source_not_ready"}
        var countryside_check: Dictionary = _countryside_source.validate_source_bounds(global_plan)
        if not bool(countryside_check.get("ok", false)):
            return countryside_check
    return {"ok": true, "failure_reason": ""}

func _canonical_handle(global_plan: GeneratedGlobalWorldPlan, supplied: Dictionary) -> Dictionary:
    var source_kind: StringName = StringName(supplied.get("source_kind", &""))
    var source_id: String = String(supplied.get("source_id", "")).strip_edges()
    if source_id.is_empty():
        return {}
    if source_kind == AreaSiteMaterializationSource.SOURCE_KIND:
        return _source.source_handle_for_site(global_plan, source_id)
    if source_kind == CountrysideSourceCatalog.SOURCE_KIND:
        if _countryside_source == null or not _countryside_source.is_ready():
            return {}
        return _countryside_source.source_handle_for_id(source_id)
    return {}

func _prepare_handle(global_plan: GeneratedGlobalWorldPlan, handle: Dictionary) -> Dictionary:
    var source_kind: StringName = StringName(handle.get("source_kind", &""))
    var source_id: String = String(handle.get("source_id", ""))
    if source_kind == AreaSiteMaterializationSource.SOURCE_KIND:
        return _source.prepare(global_plan, source_id)
    if source_kind == CountrysideSourceCatalog.SOURCE_KIND and _countryside_source != null:
        return _countryside_source.prepare(global_plan, source_id)
    return {
        "ok": false,
        "failure_reason": "unsupported_materialization_source_kind:%s" % String(source_kind),
    }

func _handles_equivalent(a: Dictionary, b: Dictionary) -> bool:
    if a.is_empty() or b.is_empty():
        return false
    return StringName(a.get("source_kind", &"")) == StringName(b.get("source_kind", &"")) \
        and String(a.get("source_id", "")).strip_edges() == String(b.get("source_id", "")).strip_edges() \
        and String(a.get("source_key", "")).strip_edges() == String(b.get("source_key", "")).strip_edges() \
        and a.get("bounds", Rect2i()) == b.get("bounds", Rect2i())

func _prepared_matches_handle(entry: Dictionary, handle: Dictionary) -> bool:
    return StringName(entry.get("source_kind", &"")) == StringName(handle.get("source_kind", &"")) \
        and String(entry.get("source_id", "")) == String(handle.get("source_id", "")) \
        and String(entry.get("source_key", "")) == String(handle.get("source_key", "")) \
        and entry.get("bounds", Rect2i()) == handle.get("bounds", Rect2i())

func _prepared_result_valid(entry: Dictionary) -> bool:
    var source_key: String = String(entry.get("source_key", "")).strip_edges()
    var source_id: String = String(entry.get("source_id", "")).strip_edges()
    var source_kind: StringName = StringName(entry.get("source_kind", &""))
    var bounds: Rect2i = entry.get("bounds", Rect2i())
    var request: AreaGenerationRequest = entry.get("request") as AreaGenerationRequest
    var plan: GeneratedAreaPlan = entry.get("plan") as GeneratedAreaPlan
    return not source_key.is_empty() and not source_id.is_empty() \
        and not String(source_kind).is_empty() \
        and bounds.size.x > 0 and bounds.size.y > 0 \
        and request != null and request.is_valid() \
        and plan != null and plan.is_generated() \
        and String(entry.get("plan_signature", "")) == plan.signature()

func _rollback(world_snapshot: Dictionary, door_snapshot: Dictionary, registry_snapshot: Dictionary) -> bool:
    var world_ok: bool = _world.load_snapshot(world_snapshot)
    var door_ok: bool = _door_state.load_snapshot(door_snapshot)
    var registry_ok: bool = _registry.load_snapshot(registry_snapshot)
    return world_ok and door_ok and registry_ok

func _success(newly: Array[String], already: Array[String]) -> Dictionary:
    return {
        "ok": true,
        "failure_reason": "",
        "newly_materialized": newly.duplicate(),
        "already_materialized": already.duplicate(),
    }

func _failure(reason: String, already: Array[String] = []) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "newly_materialized": [],
        "already_materialized": already.duplicate(),
    }
