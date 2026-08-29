extends RefCounted
class_name ItemFreshnessQuery

## O(1)-style analytic freshness query. No time-passage notifications or item scans.

enum Status { UNKNOWN = 0, SHELF_STABLE = 1, KNOWN = 2, INVALID = 3 }

const FRESH: StringName = &"FRESH"
const AGING: StringName = &"AGING"
const STALE: StringName = &"STALE"
const SPOILED: StringName = &"SPOILED"

var _world: WorldState = null
var _state: ItemFreshnessState = null
var _profiles: ItemFreshnessProfileCatalog = null
var _kernel: TickKernel = null
var _providers: Dictionary = {}

func _init(
    world_state: WorldState = null,
    freshness_state: ItemFreshnessState = null,
    profile_catalog: ItemFreshnessProfileCatalog = null,
    kernel: TickKernel = null,
    providers: Array[SpoilageEnvironmentProvider] = []
) -> void:
    _world = world_state
    _state = freshness_state
    _profiles = profile_catalog
    _kernel = kernel
    for provider: SpoilageEnvironmentProvider in providers:
        if provider != null and provider.is_valid():
            _providers[String(provider.context_id())] = provider

func register_provider(provider: SpoilageEnvironmentProvider) -> bool:
    if provider == null or not provider.is_valid():
        return false
    var key: String = String(provider.context_id())
    if key.is_empty():
        return false
    if _providers.has(key):
        return _providers[key] == provider
    _providers[key] = provider
    return true

func is_ready() -> bool:
    return _world != null and _state != null and _profiles != null and _kernel != null

func query(item_id: String) -> Dictionary:
    if not is_ready():
        return _failure(Status.UNKNOWN, "freshness_query_not_ready")
    return query_at_tick(item_id, _kernel.world_tick())

func query_at_tick(item_id: String, world_tick: int) -> Dictionary:
    var key: String = item_id.strip_edges()
    if _world == null or _state == null or _profiles == null or key.is_empty() or world_tick < 0:
        return _failure(Status.UNKNOWN, "freshness_query_not_ready")
    if not _world.has_entity(key):
        return _failure(Status.UNKNOWN, "item_missing")
    var entity: WorldEntityRecord = _world.entity(key)
    if entity == null or not String(entity.semantic_type).begins_with("item."):
        return _failure(Status.INVALID, "not_item_entity")
    if not _profiles.has_profile(entity.semantic_type):
        if _state.has_item(key):
            return _failure(Status.INVALID, "shelf_stable_item_has_freshness_state")
        return {
            "status": Status.SHELF_STABLE,
            "reason": "",
            "item_id": key,
            "semantic_type": entity.semantic_type,
            "perishable": false,
            "stage": &"",
            "age_ticks": 0,
            "lifetime_ticks": 0,
            "age_permille": 0,
            "exposure_context_id": &"",
        }
    if not _state.has_item(key):
        return _failure(Status.UNKNOWN, "perishable_item_unenrolled")
    var record_value: ItemFreshnessRecord = _state.record(key)
    var profile: ItemFreshnessProfile = _profiles.profile(entity.semantic_type)
    if record_value == null or profile == null \
        or record_value.profile_id != entity.semantic_type \
        or record_value.profile_version != profile.profile_version:
        return _failure(Status.INVALID, "freshness_profile_mismatch")
    var provider: SpoilageEnvironmentProvider = _provider(record_value.exposure_context_id)
    if provider == null:
        return _failure(Status.UNKNOWN, "exposure_context_unknown")
    var exposure_now: int = provider.exposure_ticks_at(world_tick)
    if exposure_now < record_value.exposure_anchor_ticks:
        return _failure(Status.INVALID, "exposure_clock_regressed")
    var age_ticks: int = record_value.saved_effective_age_ticks + exposure_now - record_value.exposure_anchor_ticks
    var age_permille: int = (age_ticks * 1000) / profile.ambient_lifetime_ticks
    return {
        "status": Status.KNOWN,
        "reason": "",
        "item_id": key,
        "semantic_type": entity.semantic_type,
        "perishable": true,
        "stage": _stage(age_permille),
        "age_ticks": age_ticks,
        "lifetime_ticks": profile.ambient_lifetime_ticks,
        "age_permille": age_permille,
        "exposure_context_id": record_value.exposure_context_id,
        "origin_world_tick": record_value.origin_world_tick,
        "record_version": record_value.version,
    }

func _provider(context_id: StringName) -> SpoilageEnvironmentProvider:
    var key: String = String(context_id)
    if not _providers.has(key):
        return null
    return _providers[key] as SpoilageEnvironmentProvider

static func _stage(age_permille: int) -> StringName:
    if age_permille >= 1000:
        return SPOILED
    if age_permille >= 850:
        return STALE
    if age_permille >= 600:
        return AGING
    return FRESH

static func _failure(status_value: int, reason: String) -> Dictionary:
    return {
        "status": status_value,
        "reason": reason,
        "item_id": "",
        "semantic_type": &"",
        "perishable": false,
        "stage": &"",
        "age_ticks": 0,
        "lifetime_ticks": 0,
        "age_permille": 0,
        "exposure_context_id": &"",
    }
