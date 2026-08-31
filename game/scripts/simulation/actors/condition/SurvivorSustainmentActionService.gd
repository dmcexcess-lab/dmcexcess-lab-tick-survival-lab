extends RefCounted
class_name SurvivorSustainmentActionService

const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const Rules = preload("res://scripts/foundation/time/TickRules.gd")
const ProfilesClass = preload("res://scripts/simulation/actors/condition/SurvivorSustainmentProfileCatalog.gd")

## Real System 34 eating/drinking/rest/sleep actions.
## Item consumption removes the actual carried WHAT entity after a committed WHEN action.
## Tap water requires an injected truthful System-33-access provider; no building-wide magic drink.

const ACTION_CONSUME: StringName = &"condition.consume"
const ACTION_TAP_DRINK: StringName = &"condition.tap_drink"
const ACTION_REST: StringName = &"condition.rest"
const ACTION_SLEEP: StringName = &"condition.sleep"

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _freshness_query: ItemFreshnessQuery = null
var _freshness_mutations: ItemFreshnessMutationService = null
var _carry_query: ActorCarryQuery = null
var _kernel: TickKernel = null
var _time_profile: WorldTimeProfile = null
var _condition: ActorConditionService = null
var _profiles: SurvivorSustainmentProfileCatalog = null
var _potable_source_provider: Callable = Callable()
var _sleep_surface_provider: Callable = Callable()

func _init(
    world_state: WorldState = null,
    world_mutations: WorldMutationService = null,
    hand_state: ActorHandEquipmentState = null,
    hand_mutations: ActorHandEquipmentMutationService = null,
    inventory_state: InventoryContainmentState = null,
    inventory_mutations: InventoryContainmentMutationService = null,
    freshness_query: ItemFreshnessQuery = null,
    freshness_mutations: ItemFreshnessMutationService = null,
    carry_query: ActorCarryQuery = null,
    kernel: TickKernel = null,
    time_profile: WorldTimeProfile = null,
    condition_service: ActorConditionService = null,
    profile_catalog: SurvivorSustainmentProfileCatalog = null
) -> void:
    _world = world_state
    _world_mutations = world_mutations
    _hands = hand_state
    _hand_mutations = hand_mutations
    _inventory = inventory_state
    _inventory_mutations = inventory_mutations
    _freshness_query = freshness_query
    _freshness_mutations = freshness_mutations
    _carry_query = carry_query
    _kernel = kernel
    _time_profile = time_profile
    _condition = condition_service
    _profiles = profile_catalog
    if _kernel != null:
        var finished_callable := Callable(self, "_on_action_finished")
        if not _kernel.action_finished.is_connected(finished_callable):
            _kernel.action_finished.connect(finished_callable)

func is_ready() -> bool:
    return _world != null and _world_mutations != null \
        and _hands != null and _hand_mutations != null \
        and _inventory != null and _inventory_mutations != null \
        and _freshness_query != null and _freshness_mutations != null \
        and _carry_query != null and _kernel != null \
        and _time_profile != null and _time_profile.is_valid() \
        and _condition != null and _condition.is_ready() and _profiles != null

func set_potable_source_provider(provider: Callable) -> bool:
    if not provider.is_valid():
        return false
    _potable_source_provider = provider
    return true

func set_sleep_surface_provider(provider: Callable) -> bool:
    if not provider.is_valid():
        return false
    _sleep_surface_provider = provider
    return true

func begin_first_consumable(actor_id: String, action_kind: StringName) -> int:
    if not is_ready() or action_kind not in [&"eat", &"drink"]:
        return 0
    var carry: Dictionary = _carry_query.query(actor_id)
    if int(carry.get("status", -1)) != ActorCarryQuery.Status.KNOWN:
        return 0
    var ids: Array[String] = []
    for value: Variant in carry.get("item_ids", []):
        ids.append(String(value))
    ids.sort()
    for item_id: String in ids:
        if not _world.has_entity(item_id):
            continue
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity == null:
            continue
        var profile: Dictionary = _profiles.profile(entity.semantic_type)
        if not profile.is_empty() and StringName(profile.get("action_kind", &"")) == action_kind:
            var serial: int = begin_consume(actor_id, item_id)
            if serial > 0:
                return serial
    return 0

func begin_consume(actor_id: String, item_id: String) -> int:
    var actor: String = actor_id.strip_edges()
    var item: String = item_id.strip_edges()
    if not is_ready() or not _condition.has_actor(actor) or not _item_carried_by(actor, item):
        return 0
    if not _world.has_entity(item):
        return 0
    var entity: WorldEntityRecord = _world.entity(item)
    if entity == null:
        return 0
    var profile: Dictionary = _profiles.profile(entity.semantic_type)
    if profile.is_empty() or _item_spoiled(item):
        return 0
    return _kernel.begin_action(
        actor,
        ACTION_CONSUME,
        int(profile.get("duration_ticks", 1)),
        Rules.InterruptionPolicy.COMMITTED,
        [],
        {
            "item_id": item,
            "semantic_type": String(entity.semantic_type),
            "satiety_gain": int(profile.get("satiety_gain", 0)),
            "hydration_gain": int(profile.get("hydration_gain", 0)),
            "engagement_gain": int(profile.get("engagement_gain", 0)),
        }
    )

func begin_tap_drink(actor_id: String) -> int:
    var actor: String = actor_id.strip_edges()
    if not is_ready() or not _condition.has_actor(actor) or not _potable_source_provider.is_valid():
        return 0
    if not bool(_potable_source_provider.call(actor)):
        return 0
    return _kernel.begin_action(
        actor,
        ACTION_TAP_DRINK,
        10,
        Rules.InterruptionPolicy.COMMITTED,
        [],
        {"hydration_gain": 28}
    )

func begin_rest(actor_id: String) -> int:
    var actor: String = actor_id.strip_edges()
    if not is_ready() or not _condition.has_actor(actor):
        return 0
    return _kernel.begin_action(
        actor,
        ACTION_REST,
        _time_profile.ticks_per_hour(),
        Rules.InterruptionPolicy.COMMITTED,
        [],
        {"surface": String(_sleep_surface(actor))}
    )

func begin_sleep(actor_id: String) -> int:
    var actor: String = actor_id.strip_edges()
    if not is_ready() or not _condition.has_actor(actor):
        return 0
    return _kernel.begin_action(
        actor,
        ACTION_SLEEP,
        _time_profile.ticks_per_hour() * 8,
        Rules.InterruptionPolicy.COMMITTED,
        [],
        {"surface": String(_sleep_surface(actor))}
    )

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.status != Rules.ActionStatus.COMPLETED or not _condition.has_actor(action.actor_id):
        return
    match action.action_type:
        ACTION_CONSUME:
            _complete_consume(action)
        ACTION_TAP_DRINK:
            # Revalidate at completion so a destroyed/disabled source cannot grant water.
            if _potable_source_provider.is_valid() and bool(_potable_source_provider.call(action.actor_id)):
                _condition.change_condition(action.actor_id, StateClass.HYDRATION, int(action.payload.get("hydration_gain", 0)), &"potable_water_drunk")
        ACTION_REST:
            _condition.change_condition(action.actor_id, StateClass.REST, 16, &"rested")
            _condition.restore_stamina(action.actor_id, 35, &"rested")
            _apply_surface_comfort(action.actor_id, StringName(action.payload.get("surface", &"ground")), false)
        ACTION_SLEEP:
            _condition.change_condition(action.actor_id, StateClass.REST, 72, &"slept")
            _condition.restore_stamina(action.actor_id, 100, &"slept")
            _apply_surface_comfort(action.actor_id, StringName(action.payload.get("surface", &"ground")), true)

func _complete_consume(action: TimedAction) -> void:
    var item_id: String = String(action.payload.get("item_id", "")).strip_edges()
    if item_id.is_empty() or not _item_carried_by(action.actor_id, item_id) or not _world.has_entity(item_id):
        return
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null or String(entity.semantic_type) != String(action.payload.get("semantic_type", "")) or _item_spoiled(item_id):
        return
    if not _detach_item(action.actor_id, item_id):
        return
    if _freshness_mutations.has_record(item_id):
        _freshness_mutations.remove_item(item_id)
    if not _world_mutations.remove_entity(item_id):
        return
    _condition.change_condition(action.actor_id, StateClass.SATIETY, int(action.payload.get("satiety_gain", 0)), &"food_consumed")
    _condition.change_condition(action.actor_id, StateClass.HYDRATION, int(action.payload.get("hydration_gain", 0)), &"drink_consumed")
    _condition.change_condition(action.actor_id, StateClass.ENGAGEMENT, int(action.payload.get("engagement_gain", 0)), &"meal_enjoyed")

func _detach_item(actor_id: String, item_id: String) -> bool:
    var assignment: Dictionary = _hands.assignment_for_item(item_id)
    if not assignment.is_empty():
        if String(assignment.get("actor_id", "")) != actor_id:
            return false
        if not _hand_mutations.clear_slot(actor_id, int(assignment.get("slot", -1))):
            return false
    if _inventory.is_contained(item_id):
        if not _inventory_mutations.clear_container(item_id):
            return false
    return true

func _item_carried_by(actor_id: String, item_id: String) -> bool:
    if item_id.is_empty() or not _world.has_entity(item_id):
        return false
    var assignment: Dictionary = _hands.assignment_for_item(item_id)
    if not assignment.is_empty():
        return String(assignment.get("actor_id", "")) == actor_id
    var current: String = item_id
    var visited: Dictionary = {}
    while _inventory.is_contained(current) and not visited.has(current):
        visited[current] = true
        current = _inventory.container_of(current)
        if current == actor_id:
            return true
    return false

func _item_spoiled(item_id: String) -> bool:
    var freshness: Dictionary = _freshness_query.query(item_id)
    if int(freshness.get("status", -1)) != ItemFreshnessQuery.Status.KNOWN:
        return false
    return StringName(freshness.get("stage", &"")) == ItemFreshnessQuery.SPOILED

func _sleep_surface(actor_id: String) -> StringName:
    if _sleep_surface_provider.is_valid():
        var value: Variant = _sleep_surface_provider.call(actor_id)
        var surface := StringName(String(value))
        if not String(surface).is_empty():
            return surface
    return &"ground"

func _apply_surface_comfort(actor_id: String, surface: StringName, full_sleep: bool) -> void:
    if surface == &"bed":
        _condition.change_condition(actor_id, StateClass.COMFORT, 15 if full_sleep else 6, &"comfortable_rest")
    else:
        _condition.change_condition(actor_id, StateClass.COMFORT, -10 if full_sleep else -4, &"rough_rest")
