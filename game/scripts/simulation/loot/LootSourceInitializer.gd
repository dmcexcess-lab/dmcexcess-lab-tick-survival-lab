extends RefCounted
class_name LootSourceInitializer

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _containment: InventoryContainmentState = null
var _containment_mutations: InventoryContainmentMutationService = null
var _loot_state: LootState = null
var _items: LootItemCatalog = null
var _containers: LootContainerProfileCatalog = null
var _physical: ItemPhysicalPropertyCatalog = null
var _freshness_mutations: ItemFreshnessMutationService = null

func _init(
    world_state: WorldState = null,
    world_mutations: WorldMutationService = null,
    containment_state: InventoryContainmentState = null,
    containment_mutations: InventoryContainmentMutationService = null,
    loot_state: LootState = null,
    item_catalog: LootItemCatalog = null,
    container_catalog: LootContainerProfileCatalog = null,
    physical_catalog: ItemPhysicalPropertyCatalog = null,
    freshness_mutations: ItemFreshnessMutationService = null
) -> void:
    _world = world_state
    _world_mutations = world_mutations
    _containment = containment_state
    _containment_mutations = containment_mutations
    _loot_state = loot_state
    _items = item_catalog
    _containers = container_catalog
    _physical = physical_catalog
    _freshness_mutations = freshness_mutations

func is_ready() -> bool:
    return _world != null \
        and _world_mutations != null and _world_mutations.is_ready() \
        and _containment != null \
        and _containment_mutations != null and _containment_mutations.is_ready() \
        and _loot_state != null \
        and _items != null \
        and _containers != null and _containers.validate_items(_items) \
        and _physical != null \
        and (_freshness_mutations == null or _freshness_mutations.is_ready())

func plan_source(source_key: String, building_plans: Array) -> Dictionary:
    var key: String = source_key.strip_edges()
    if not is_ready() or key.is_empty():
        return _failure("loot_initializer_not_ready")

    var ordered: Array[GeneratedBuildingPlan] = []
    for value: Variant in building_plans:
        var plan: GeneratedBuildingPlan = value as GeneratedBuildingPlan
        if plan == null or not plan.is_generated():
            return _failure("invalid_building_plan")
        ordered.append(plan)
    ordered.sort_custom(func(a: GeneratedBuildingPlan, b: GeneratedBuildingPlan) -> bool:
        return a.instance_id < b.instance_id
    )

    var planned_containers: Array[Dictionary] = []
    var seen_container_ids: Dictionary = {}
    for plan: GeneratedBuildingPlan in ordered:
        for prop: Dictionary in plan.props:
            var role: String = String(prop.get("role", "")).strip_edges()
            var semantic: StringName = StringName(prop.get("semantic", &""))
            var profile_id: StringName = _containers.classify(plan.archetype_id, role, semantic)
            if profile_id == &"":
                continue
            var profile: Dictionary = _containers.profile(profile_id)
            if profile.is_empty():
                return _failure("loot_profile_missing:%s" % String(profile_id))
            var container_id: String = plan.entity_id_for_role(role)
            if container_id.is_empty() or seen_container_ids.has(container_id):
                return _failure("loot_container_id_invalid:%s" % container_id)
            seen_container_ids[container_id] = true

            var rng := RandomNumberGenerator.new()
            rng.seed = _stable_seed(key, plan, container_id, profile_id, int(profile.get("version", 0)))
            var draw_min: int = int(profile.get("draw_min", 0))
            var draw_max: int = int(profile.get("draw_max", 0))
            var draw_count: int = rng.randi_range(draw_min, draw_max)
            var item_plans: Array[Dictionary] = []
            for ordinal: int in range(draw_count):
                var item_semantic: StringName = _draw_semantic(profile, rng)
                if item_semantic == &"" or not _items.has_item(item_semantic):
                    return _failure("loot_item_selection_invalid:%s" % String(profile_id))
                item_plans.append({
                    "item_id": "%s.loot.%03d" % [container_id, ordinal],
                    "semantic": item_semantic,
                })

            planned_containers.append({
                "container_id": container_id,
                "container_semantic": semantic,
                "loot_profile_id": profile_id,
                "loot_profile_version": int(profile.get("version", 0)),
                "building_instance_id": plan.instance_id,
                "building_archetype_id": plan.archetype_id,
                "items": item_plans,
            })

    planned_containers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("container_id", "")) < String(b.get("container_id", ""))
    )
    var signature_value: Array = []
    for container: Dictionary in planned_containers:
        var items_out: Array = []
        for item: Dictionary in container.get("items", []):
            items_out.append([String(item.get("item_id", "")), String(item.get("semantic", &""))])
        signature_value.append([
            String(container.get("container_id", "")),
            String(container.get("loot_profile_id", &"")),
            int(container.get("loot_profile_version", 0)),
            items_out,
        ])
    return {
        "ok": true,
        "reason": "",
        "source_key": key,
        "containers": planned_containers,
        "signature": JSON.stringify(signature_value),
    }

func initialize_source(
    source_key: String,
    source_kind: StringName,
    source_id: String,
    building_plans: Array
) -> Dictionary:
    var key: String = source_key.strip_edges()
    var sid: String = source_id.strip_edges()
    if not is_ready() or key.is_empty() or String(source_kind).is_empty() or sid.is_empty():
        return _failure("loot_initializer_not_ready")
    if _loot_state.has_source(key):
        return {
            "ok": true,
            "reason": "",
            "already_initialized": true,
            "source_key": key,
            "container_ids": _loot_state.source_record(key).get("container_ids", []).duplicate(),
            "item_ids": [],
        }

    var plan_result: Dictionary = plan_source(key, building_plans)
    if not bool(plan_result.get("ok", false)):
        return plan_result
    var container_plans: Array = plan_result.get("containers", [])

    # Preflight against physical current truth before taking any rollback snapshot.
    for container_value: Variant in container_plans:
        var container: Dictionary = container_value
        var container_id: String = String(container.get("container_id", ""))
        var expected_semantic: String = String(container.get("container_semantic", &""))
        if not _world.has_entity(container_id):
            return _failure("loot_container_missing:%s" % container_id)
        var entity: WorldEntityRecord = _world.entity(container_id)
        var placement: WorldPlacement = _world.placement(container_id)
        if entity == null or String(entity.semantic_type) != expected_semantic \
            or placement == null or placement.channel != Layers.Channel.OBJECT:
            return _failure("loot_container_physical_mismatch:%s" % container_id)
        if _containment.has_container(container_id) and not _containment.direct_contents(container_id).is_empty():
            return _failure("loot_container_prepopulated:%s" % container_id)
        for item_value: Variant in container.get("items", []):
            var item: Dictionary = item_value
            var item_id: String = String(item.get("item_id", ""))
            var semantic: StringName = StringName(item.get("semantic", &""))
            if item_id.is_empty() or _world.has_entity(item_id) or not _items.has_item(semantic):
                return _failure("loot_item_preflight_failed:%s" % item_id)
            var expected_weight: int = _items.weight_grams(semantic)
            if not _physical.has_profile(semantic) or _physical.weight_grams(semantic) != expected_weight:
                return _failure("loot_item_weight_unknown:%s" % String(semantic))
            if _freshness_mutations != null \
                and _freshness_mutations.is_perishable(semantic) \
                and _freshness_mutations.has_record(item_id):
                return _failure("loot_item_freshness_prepopulated:%s" % item_id)

    var world_snapshot: Dictionary = _world.snapshot()
    var containment_snapshot: Dictionary = _containment.snapshot()
    var loot_snapshot: Dictionary = _loot_state.snapshot()
    var freshness_snapshot: Dictionary = {}
    if _freshness_mutations != null:
        freshness_snapshot = _freshness_mutations.snapshot_state()
    var created_item_ids: Array[String] = []
    var state_container_records: Array[Dictionary] = []

    for container_value: Variant in container_plans:
        var container: Dictionary = container_value
        var container_id: String = String(container.get("container_id", ""))
        if not _containment.has_container(container_id):
            if not _containment_mutations.enroll_container(container_id):
                return _rollback_failure(world_snapshot, containment_snapshot, loot_snapshot, freshness_snapshot, "loot_container_enroll_failed:%s" % container_id)
        for item_value: Variant in container.get("items", []):
            var item: Dictionary = item_value
            var item_id: String = String(item.get("item_id", ""))
            var semantic: StringName = StringName(item.get("semantic", &""))
            if _world_mutations.create_entity(semantic, item_id) != item_id:
                return _rollback_failure(world_snapshot, containment_snapshot, loot_snapshot, freshness_snapshot, "loot_item_create_failed:%s" % item_id)
            if _freshness_mutations != null and _freshness_mutations.is_perishable(semantic):
                if not _freshness_mutations.enroll_virgin_item(item_id, 0):
                    return _rollback_failure(world_snapshot, containment_snapshot, loot_snapshot, freshness_snapshot, "loot_item_freshness_enroll_failed:%s" % item_id)
            if not _containment_mutations.set_container(item_id, container_id):
                return _rollback_failure(world_snapshot, containment_snapshot, loot_snapshot, freshness_snapshot, "loot_item_contain_failed:%s" % item_id)
            created_item_ids.append(item_id)
        state_container_records.append({
            "container_id": container_id,
            "loot_profile_id": container.get("loot_profile_id", &""),
            "loot_profile_version": int(container.get("loot_profile_version", 0)),
            "building_instance_id": String(container.get("building_instance_id", "")),
        })

    if not _loot_state.initialize_source(
        key,
        source_kind,
        sid,
        String(plan_result.get("signature", "")),
        _containers.catalog_version(),
        state_container_records
    ):
        return _rollback_failure(world_snapshot, containment_snapshot, loot_snapshot, freshness_snapshot, "loot_state_commit_failed")

    var container_ids: Array[String] = []
    for record: Dictionary in state_container_records:
        container_ids.append(String(record.get("container_id", "")))
    container_ids.sort()
    created_item_ids.sort()
    return {
        "ok": true,
        "reason": "",
        "already_initialized": false,
        "source_key": key,
        "container_ids": container_ids,
        "item_ids": created_item_ids,
    }

func _rollback_failure(
    world_snapshot: Dictionary,
    containment_snapshot: Dictionary,
    loot_snapshot: Dictionary,
    freshness_snapshot: Dictionary,
    reason: String
) -> Dictionary:
    var world_ok: bool = _world.load_snapshot(world_snapshot)
    var containment_ok: bool = _containment.load_snapshot(containment_snapshot)
    var loot_ok: bool = _loot_state.load_snapshot(loot_snapshot)
    var freshness_ok: bool = true
    if _freshness_mutations != null:
        freshness_ok = _freshness_mutations.restore_state(freshness_snapshot)
    if not world_ok or not containment_ok or not loot_ok or not freshness_ok:
        return _failure("loot_initialization_failed_and_rollback_failed:%s" % reason)
    return _failure(reason)

func _draw_semantic(profile: Dictionary, rng: RandomNumberGenerator) -> StringName:
    var entries: Array = profile.get("entries", [])
    var total: int = 0
    for entry_value: Variant in entries:
        var entry: Dictionary = entry_value
        total += int(entry.get("weight", 0))
    if total <= 0:
        return &""
    var roll: int = rng.randi_range(1, total)
    var cursor: int = 0
    for entry_value: Variant in entries:
        var entry: Dictionary = entry_value
        cursor += int(entry.get("weight", 0))
        if roll <= cursor:
            return StringName(entry.get("semantic", &""))
    return &""

static func _stable_seed(
    source_key: String,
    plan: GeneratedBuildingPlan,
    container_id: String,
    profile_id: StringName,
    profile_version: int
) -> int:
    var token: String = "%s|%s|%d|%s|%s|%d" % [
        source_key,
        plan.instance_id,
        plan.seed,
        container_id,
        String(profile_id),
        profile_version,
    ]
    return token.hash()

static func _failure(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason}
