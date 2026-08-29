extends RefCounted
class_name ItemFreshnessMutationService

## Sparse per-instance freshness mutation owner. Time passing alone never calls here.

var _world: WorldState = null
var _state: ItemFreshnessState = null
var _profiles: ItemFreshnessProfileCatalog = null
var _providers: Dictionary = {}

func _init(
    world_state: WorldState = null,
    freshness_state: ItemFreshnessState = null,
    profile_catalog: ItemFreshnessProfileCatalog = null,
    providers: Array[SpoilageEnvironmentProvider] = []
) -> void:
    _world = world_state
    _state = freshness_state
    _profiles = profile_catalog
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
    return _world != null and _state != null and _profiles != null and _providers.has("ambient")

func is_perishable(semantic_type: StringName) -> bool:
    return is_ready() and _profiles.has_profile(semantic_type)

func has_record(item_id: String) -> bool:
    return is_ready() and _state.has_item(item_id)

func snapshot_state() -> Dictionary:
    if not is_ready():
        return {}
    return _state.snapshot()

func restore_state(snapshot: Dictionary) -> bool:
    return is_ready() and _state.load_snapshot(snapshot)

func enroll_virgin_item(item_id: String, origin_world_tick: int = 0) -> bool:
    var key: String = item_id.strip_edges()
    if not is_ready() or key.is_empty() or origin_world_tick < 0 or _state.has_item(key):
        return false
    if not _world.has_entity(key):
        return false
    var entity: WorldEntityRecord = _world.entity(key)
    if entity == null or not _profiles.has_profile(entity.semantic_type):
        return false
    var profile: ItemFreshnessProfile = _profiles.profile(entity.semantic_type)
    var provider: SpoilageEnvironmentProvider = _provider(&"ambient")
    if profile == null or provider == null:
        return false
    var anchor_exposure: int = provider.exposure_ticks_at(origin_world_tick)
    if anchor_exposure < 0:
        return false
    var start_permille: int = _virgin_age_permille(key, profile.virgin_initial_age_max_permille)
    var start_age: int = (profile.ambient_lifetime_ticks * start_permille) / 1000
    var record_value := ItemFreshnessRecord.new(
        key,
        profile.semantic_type,
        profile.profile_version,
        provider.context_id(),
        start_age,
        anchor_exposure,
        origin_world_tick,
        1
    )
    return _state._set_record(record_value)

func remove_item(item_id: String) -> bool:
    if not is_ready():
        return false
    return _state._remove_record(item_id)

func reanchor(item_id: String, new_context_id: StringName, world_tick: int) -> bool:
    var key: String = item_id.strip_edges()
    if not is_ready() or key.is_empty() or world_tick < 0 or not _state.has_item(key):
        return false
    var current: ItemFreshnessRecord = _state.record(key)
    var old_provider: SpoilageEnvironmentProvider = _provider(current.exposure_context_id)
    var new_provider: SpoilageEnvironmentProvider = _provider(new_context_id)
    if old_provider == null or new_provider == null:
        return false
    var old_exposure: int = old_provider.exposure_ticks_at(world_tick)
    var new_exposure: int = new_provider.exposure_ticks_at(world_tick)
    if old_exposure < current.exposure_anchor_ticks or new_exposure < 0:
        return false
    current.saved_effective_age_ticks += old_exposure - current.exposure_anchor_ticks
    current.exposure_context_id = new_provider.context_id()
    current.exposure_anchor_ticks = new_exposure
    return _state._set_record(current)

func _provider(context_id: StringName) -> SpoilageEnvironmentProvider:
    var key: String = String(context_id)
    if not _providers.has(key):
        return null
    return _providers[key] as SpoilageEnvironmentProvider

static func _virgin_age_permille(item_id: String, max_permille: int) -> int:
    if max_permille <= 0:
        return 0
    return posmod(item_id.hash(), max_permille + 1)
