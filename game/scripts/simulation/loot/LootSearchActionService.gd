extends RefCounted
class_name LootSearchActionService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const ReachClass = preload("res://scripts/simulation/interaction/WorldInteractionReachQuery.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

signal search_completed(actor_id, action_serial, container_id, contents, container_version)
signal search_failed(actor_id, action_serial, container_id, reason)
signal search_canceled(actor_id, action_serial, container_id, reason)

const ACTION_TYPE: StringName = &"scavenge.search_container"
const COMMIT_PHASE: StringName = &"scavenge.search.commit"
const SEARCH_DIFFICULTY: int = 2

var _world: WorldState = null
var _containment: InventoryContainmentState = null
var _loot_state: LootState = null
var _profiles: LootContainerProfileCatalog = null
var _kernel: TickKernel = null
var _reach: WorldInteractionReachQuery = null
var _skill_checks: ActorSkillCheckService = null

func _init(
    world_state: WorldState = null,
    containment_state: InventoryContainmentState = null,
    loot_state: LootState = null,
    profile_catalog: LootContainerProfileCatalog = null,
    tick_kernel: TickKernel = null,
    reach_query: WorldInteractionReachQuery = null
) -> void:
    _world = world_state
    _containment = containment_state
    _loot_state = loot_state
    _profiles = profile_catalog
    _kernel = tick_kernel
    _reach = reach_query if reach_query != null else ReachClass.new(_world)
    if _kernel != null:
        if not _kernel.action_phase.is_connected(_on_action_phase):
            _kernel.action_phase.connect(_on_action_phase)
        if not _kernel.action_finished.is_connected(_on_action_finished):
            _kernel.action_finished.connect(_on_action_finished)

func configure_skill_checks(skill_check_service: ActorSkillCheckService) -> bool:
    if skill_check_service == null or not skill_check_service.is_ready():
        return false
    _skill_checks = skill_check_service
    return true

func is_ready() -> bool:
    return _world != null and _containment != null and _loot_state != null and _profiles != null \
        and _kernel != null and _reach != null and _reach.is_ready()

func request_search(actor_id: String, container_id: String) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    var container: String = container_id.strip_edges()
    if not is_ready():
        return _rejected("search_not_ready")
    if actor.is_empty() or container.is_empty():
        return _rejected("invalid_search_target")
    if _kernel.is_hard_paused():
        return _rejected("hard_paused")
    if _kernel.has_active_action(actor):
        return _rejected("actor_busy")
    if not _world.has_entity(actor) or not _world.has_entity(container):
        return _rejected("search_entity_missing")
    var actor_entity: WorldEntityRecord = _world.entity(actor)
    var actor_placement: WorldPlacement = _world.placement(actor)
    var container_placement: WorldPlacement = _world.placement(container)
    if actor_entity == null or String(actor_entity.semantic_type) != "actor.survivor" \
        or actor_placement == null or actor_placement.channel != Layers.Channel.ACTOR:
        return _rejected("invalid_search_actor")
    if container_placement == null or container_placement.channel != Layers.Channel.OBJECT:
        return _rejected("invalid_search_container")
    if not _loot_state.has_container(container) or not _containment.has_container(container):
        return _rejected("loot_container_not_initialized")
    if not _reach.target_reachable(actor, container, ReachClass.CONTACT_FORWARD):
        return _rejected("out_of_reach")

    var record: Dictionary = _loot_state.container_record(container)
    var profile_id: StringName = StringName(record.get("loot_profile_id", &""))
    var profile: Dictionary = _profiles.profile(profile_id)
    if profile.is_empty() or int(profile.get("version", 0)) != int(record.get("loot_profile_version", -1)):
        return _rejected("loot_profile_unavailable")
    var base_duration: int = int(profile.get("search_ticks", 0))
    if base_duration < 1:
        return _rejected("search_duration_invalid")
    var duration: int = base_duration
    var skill_level: int = -1
    if _skill_checks != null:
        var skill_profile: Dictionary = _skill_checks.action_profile(actor, SkillCatalog.SURVIVAL, base_duration, SEARCH_DIFFICULTY)
        if not bool(skill_profile.get("ok", false)):
            return _rejected(String(skill_profile.get("reason", "search_skill_unavailable")))
        duration = int(skill_profile.get("duration_ticks", 0))
        skill_level = int(skill_profile.get("skill_level", -1))
        if duration < 1:
            return _rejected("search_skill_duration_invalid")

    var payload: Dictionary = {
        "container_id": container,
        "loot_profile_id": String(profile_id),
        "loot_profile_version": int(profile.get("version", 0)),
        "actor_placement": actor_placement.to_snapshot(),
        "container_placement": container_placement.to_snapshot(),
        "skill_id": String(SkillCatalog.SURVIVAL) if _skill_checks != null else "",
        "skill_level": skill_level,
        "skill_difficulty": SEARCH_DIFFICULTY if _skill_checks != null else 0,
    }
    var phases: Array[ActionPhase] = [PhaseClass.new(COMMIT_PHASE, duration)]
    var serial: int = _kernel.begin_action(
        actor,
        ACTION_TYPE,
        duration,
        TickRulesClass.InterruptionPolicy.CANCELABLE,
        phases,
        payload
    )
    if serial <= 0:
        return _rejected("search_timing_rejected")
    return {
        "accepted": true,
        "reason": "",
        "action_serial": serial,
        "duration_ticks": duration,
        "container_id": container,
        "skill_id": SkillCatalog.SURVIVAL if _skill_checks != null else &"",
        "skill_level": skill_level,
    }

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or action.action_type != ACTION_TYPE or phase.phase_id != COMMIT_PHASE:
        return
    _commit_search(action)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != ACTION_TYPE:
        return
    var container_id: String = String(action.payload.get("container_id", ""))
    if action.status == TickRulesClass.ActionStatus.CANCELED:
        search_canceled.emit(action.actor_id, action.serial, container_id, action.reason)
    elif action.status == TickRulesClass.ActionStatus.FAILED:
        search_failed.emit(action.actor_id, action.serial, container_id, action.reason)

func _commit_search(action: TimedAction) -> void:
    var payload: Dictionary = action.payload
    var container_id: String = String(payload.get("container_id", ""))
    if container_id.is_empty() or not _world.has_entity(action.actor_id) or not _world.has_entity(container_id):
        _fail(action, "search_entity_missing")
        return
    var actor_snapshot: Variant = payload.get("actor_placement", {})
    var container_snapshot: Variant = payload.get("container_placement", {})
    if typeof(actor_snapshot) != TYPE_DICTIONARY or typeof(container_snapshot) != TYPE_DICTIONARY:
        _fail(action, "search_payload_invalid")
        return
    var expected_actor: WorldPlacement = PlacementClass.from_snapshot(actor_snapshot)
    var expected_container: WorldPlacement = PlacementClass.from_snapshot(container_snapshot)
    var current_actor: WorldPlacement = _world.placement(action.actor_id)
    var current_container: WorldPlacement = _world.placement(container_id)
    if expected_actor == null or expected_container == null or current_actor == null or current_container == null:
        _fail(action, "search_placement_missing")
        return
    if not current_actor.equivalent(expected_actor):
        _fail(action, "actor_placement_changed")
        return
    if not current_container.equivalent(expected_container):
        _fail(action, "container_placement_changed")
        return
    if current_actor.channel != Layers.Channel.ACTOR or current_container.channel != Layers.Channel.OBJECT:
        _fail(action, "search_placement_invalid")
        return
    if not _loot_state.has_container(container_id) or not _containment.has_container(container_id):
        _fail(action, "loot_container_not_initialized")
        return
    var record: Dictionary = _loot_state.container_record(container_id)
    if String(record.get("loot_profile_id", "")) != String(payload.get("loot_profile_id", "")) \
        or int(record.get("loot_profile_version", -1)) != int(payload.get("loot_profile_version", -2)):
        _fail(action, "loot_container_profile_changed")
        return
    if not _reach.target_reachable(action.actor_id, container_id, ReachClass.CONTACT_FORWARD):
        _fail(action, "out_of_reach")
        return

    # Contents remain persistent container truth. Survival changes search efficiency and
    # progression; it never rerolls, deletes, or hides already-materialized loot truth.
    if _skill_checks != null:
        var skill_result: Dictionary = _skill_checks.resolve_attempt(
            action.actor_id,
            SkillCatalog.SURVIVAL,
            SEARCH_DIFFICULTY,
            action.serial,
            ACTION_TYPE,
            int(payload.get("skill_level", -1))
        )
        if not bool(skill_result.get("ok", false)):
            _fail(action, String(skill_result.get("reason", "search_skill_unavailable")))
            return
        if not _skill_checks.award_attempt_xp(
            action.actor_id,
            SkillCatalog.SURVIVAL,
            SEARCH_DIFFICULTY,
            bool(skill_result.get("success", false))
        ):
            _fail(action, "search_skill_xp_commit_failed")
            return

    # Contents are intentionally read NOW, after elapsed search time. No request-time
    # container-version equality is required because another actor may have changed
    # the real contents while the search was underway.
    search_completed.emit(
        action.actor_id,
        action.serial,
        container_id,
        _containment.direct_contents(container_id),
        _containment.container_version(container_id)
    )

func _fail(action: TimedAction, reason: String) -> void:
    if not _kernel.fail_action(action.serial, reason):
        push_error("LootSearchActionService: failed to mark action failed: %s" % reason)

static func _rejected(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "reason": reason,
        "action_serial": 0,
        "duration_ticks": 0,
        "container_id": "",
        "skill_id": &"",
        "skill_level": -1,
    }
