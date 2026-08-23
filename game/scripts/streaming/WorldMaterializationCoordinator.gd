extends RefCounted
class_name WorldMaterializationCoordinator

const AreaMaterializerClass = preload("res://scripts/generation/areas/AreaMaterializationCoordinator.gd")
const SourceClass = preload("res://scripts/streaming/AreaSiteMaterializationSource.gd")
const RecordClass = preload("res://scripts/streaming/MaterializationRecord.gd")

var _world: WorldState = null
var _mutations: WorldMutationService = null
var _door_state: DoorStateStore = null
var _door_mutations: DoorStateMutationService = null
var _registry: MaterializationRegistry = null
var _source: AreaSiteMaterializationSource = null
var _area_materializer: AreaMaterializationCoordinator = null

func _init(
    world: WorldState = null,
    mutations: WorldMutationService = null,
    door_state: DoorStateStore = null,
    door_mutations: DoorStateMutationService = null,
    registry: MaterializationRegistry = null,
    source: AreaSiteMaterializationSource = null
) -> void:
    _world = world
    _mutations = mutations
    _door_state = door_state
    _door_mutations = door_mutations
    _registry = registry
    _source = source if source != null else SourceClass.new(registry)
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
    if site_ids.is_empty():
        return {
            "ok": true,
            "failure_reason": "",
            "newly_materialized": [],
            "already_materialized": [],
        }

    var source_bounds_check: Dictionary = _source.validate_source_bounds(global_plan)
    if not bool(source_bounds_check.get("ok", false)):
        return _failure(String(source_bounds_check.get("failure_reason", "materialization_source_bounds_invalid")))

    var requested_by_key: Dictionary = {}
    for site_value: Variant in site_ids:
        var site_id: String = String(site_value).strip_edges()
        if site_id.is_empty() or not _site_exists(global_plan, site_id):
            return _failure("unknown_area_site:%s" % site_id)
        var source_key: String = _source.source_key_for_site(site_id)
        if source_key.is_empty():
            return _failure("invalid_source_key:%s" % site_id)
        if not requested_by_key.has(source_key):
            requested_by_key[source_key] = site_id

    var ordered_keys: Array[String] = []
    for key_value: Variant in requested_by_key.keys():
        ordered_keys.append(String(key_value))
    ordered_keys.sort()

    var already: Array[String] = []
    var missing_site_ids: Array[String] = []
    for source_key: String in ordered_keys:
        if _registry.has_source(source_key):
            already.append(source_key)
        else:
            missing_site_ids.append(String(requested_by_key[source_key]))

    if missing_site_ids.is_empty():
        return {
            "ok": true,
            "failure_reason": "",
            "newly_materialized": [],
            "already_materialized": already,
        }

    var prepared: Array[Dictionary] = []
    for site_id: String in missing_site_ids:
        var result: Dictionary = _source.prepare(global_plan, site_id)
        if not bool(result.get("ok", false)):
            return _failure(String(result.get("failure_reason", "materialization_source_prepare_failed")), already)
        if not _prepared_result_valid(result):
            return _failure("materialization_source_prepare_invalid:%s" % site_id, already)
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

    return {
        "ok": true,
        "failure_reason": "",
        "newly_materialized": newly,
        "already_materialized": already,
    }

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

func _site_exists(global_plan: GeneratedGlobalWorldPlan, site_id: String) -> bool:
    for site: Dictionary in global_plan.area_sites:
        if String(site.get("id", "")) == site_id:
            return true
    return false

func _rollback(world_snapshot: Dictionary, door_snapshot: Dictionary, registry_snapshot: Dictionary) -> bool:
    var world_ok: bool = _world.load_snapshot(world_snapshot)
    var door_ok: bool = _door_state.load_snapshot(door_snapshot)
    var registry_ok: bool = _registry.load_snapshot(registry_snapshot)
    return world_ok and door_ok and registry_ok

func _failure(reason: String, already: Array[String] = []) -> Dictionary:
    return {
        "ok": false,
        "failure_reason": reason,
        "newly_materialized": [],
        "already_materialized": already.duplicate(),
    }
