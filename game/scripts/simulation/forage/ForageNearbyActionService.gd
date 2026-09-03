extends RefCounted
class_name ForageNearbyActionService

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const PlacementClass = preload("res://scripts/foundation/world/WorldPlacement.gd")
const PhaseClass = preload("res://scripts/foundation/time/ActionPhase.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const SkyExposureClass = preload("res://scripts/simulation/weather/SkyExposureQuery.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")

## Outdoor primitive-resource recovery. The environment is queried only at request/
## commit boundaries. State stores only finite opportunity depletion, never hidden items.

signal forage_completed(actor_id, action_serial, patch_key, found_item_ids, found_semantics)
signal forage_failed(actor_id, action_serial, patch_key, reason, opportunity_consumed)
signal forage_canceled(actor_id, action_serial, patch_key, reason)

const ACTION_TYPE: StringName = &"survival.forage_nearby"
const COMMIT_PHASE: StringName = &"survival.forage.commit"
const SURVIVAL_DIFFICULTY: int = 2
const BASE_DURATION_TICKS: int = 10
const PATCH_SIZE: int = 8
const EXPOSURE_RADIUS: int = 16
const MAX_PATCH_CAPACITY: int = 4
const STICK: StringName = &"item.outdoors.sturdy_stick"
const STONE: StringName = &"item.outdoors.smooth_stone"

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _kernel: TickKernel = null
var _skill_checks: ActorSkillCheckService = null
var _loot_items: LootItemCatalog = null
var _state: OutdoorForageState = null
var _sky: SkyExposureQuery = null
var _world_seed: int = 0
var _natural_stick_props: Dictionary = {}
var _natural_rock_props: Dictionary = {}
var _outcomes: Dictionary = {}

func _init(
    world_state: WorldState = null,
    world_mutations: WorldMutationService = null,
    tick_kernel: TickKernel = null,
    skill_checks: ActorSkillCheckService = null,
    loot_items: LootItemCatalog = null,
    world_seed: int = 0,
    forage_state: OutdoorForageState = null
) -> void:
    _world = world_state
    _world_mutations = world_mutations
    _kernel = tick_kernel
    _skill_checks = skill_checks
    _loot_items = loot_items
    _world_seed = world_seed
    _state = forage_state if forage_state != null else OutdoorForageState.new()
    _sky = SkyExposureClass.new(_world)
    _build_natural_prop_sets()
    if _kernel != null:
        if not _kernel.action_phase.is_connected(_on_action_phase):
            _kernel.action_phase.connect(_on_action_phase)
        if not _kernel.action_finished.is_connected(_on_action_finished):
            _kernel.action_finished.connect(_on_action_finished)

func is_ready() -> bool:
    return _world != null and _world_mutations != null and _world_mutations.is_ready() \
        and _kernel != null and _skill_checks != null and _skill_checks.is_ready() \
        and _loot_items != null and _loot_items.has_item(STICK) and _loot_items.has_item(STONE) \
        and _state != null and _sky != null and _sky.is_ready() and _world_seed > 0

func state() -> OutdoorForageState:
    return _state

func request_forage(actor_id: String) -> Dictionary:
    var actor: String = actor_id.strip_edges()
    if not is_ready():
        return _rejected("forage_not_ready")
    if actor.is_empty() or not _world.has_entity(actor):
        return _rejected("forage_actor_missing")
    if _kernel.is_hard_paused():
        return _rejected("hard_paused")
    if _kernel.has_active_action(actor):
        return _rejected("actor_busy")
    var actor_entity: WorldEntityRecord = _world.entity(actor)
    var placement: WorldPlacement = _world.placement(actor)
    if actor_entity == null or actor_entity.semantic_type != &"actor.survivor" \
        or placement == null or placement.channel != Layers.Channel.ACTOR:
        return _rejected("invalid_forage_actor")

    var environment: Dictionary = _environment_profile(placement.anchor)
    if not bool(environment.get("ok", false)):
        return _rejected(String(environment.get("reason", "forage_impossible")))
    var patch_key: String = String(environment.get("patch_key", ""))
    if not _state.ensure_patch(
        patch_key,
        int(environment.get("capacity", 0)),
        int(environment.get("stick_weight", 0)),
        int(environment.get("stone_weight", 0))
    ):
        return _rejected("forage_state_rejected")
    if _state.remaining(patch_key) < 1:
        return _rejected("forage_depleted")

    var profile: Dictionary = _skill_checks.action_profile(actor, SkillCatalog.SURVIVAL, BASE_DURATION_TICKS, SURVIVAL_DIFFICULTY)
    if not bool(profile.get("ok", false)):
        return _rejected(String(profile.get("reason", "forage_skill_unavailable")))
    var duration: int = int(profile.get("duration_ticks", 0))
    var opportunity_index: int = _state.next_opportunity_index(patch_key)
    if duration < 1 or opportunity_index < 0:
        return _rejected("forage_contract_invalid")

    var payload: Dictionary = {
        "patch_key": patch_key,
        "opportunity_index": opportunity_index,
        "actor_placement": placement.to_snapshot(),
        "skill_level": int(profile.get("skill_level", -1)),
        "skill_difficulty": SURVIVAL_DIFFICULTY,
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
        return _rejected("forage_timing_rejected")
    return {
        "accepted": true,
        "reason": "",
        "action_serial": serial,
        "duration_ticks": duration,
        "patch_key": patch_key,
        "remaining_before": _state.remaining(patch_key),
        "skill_id": SkillCatalog.SURVIVAL,
        "skill_level": int(profile.get("skill_level", -1)),
        "success_chance_percent": int(profile.get("success_chance_percent", 0)),
    }

func _on_action_phase(action: TimedAction, phase: ActionPhase) -> void:
    if action == null or phase == null or action.action_type != ACTION_TYPE or phase.phase_id != COMMIT_PHASE:
        return
    _commit_forage(action)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != ACTION_TYPE:
        return
    var patch_key: String = String(action.payload.get("patch_key", ""))
    var outcome: Dictionary = _outcomes.get(action.serial, {})
    if action.status == TickRulesClass.ActionStatus.COMPLETED and bool(outcome.get("success", false)):
        forage_completed.emit(
            action.actor_id,
            action.serial,
            patch_key,
            outcome.get("found_item_ids", []).duplicate(),
            outcome.get("found_semantics", []).duplicate()
        )
    elif action.status == TickRulesClass.ActionStatus.CANCELED:
        forage_canceled.emit(action.actor_id, action.serial, patch_key, action.reason if not action.reason.is_empty() else "canceled")
    else:
        forage_failed.emit(
            action.actor_id,
            action.serial,
            patch_key,
            String(outcome.get("reason", action.reason if not action.reason.is_empty() else "forage_failed")),
            bool(outcome.get("opportunity_consumed", false))
        )
    _outcomes.erase(action.serial)

func _commit_forage(action: TimedAction) -> void:
    var patch_key: String = String(action.payload.get("patch_key", ""))
    var opportunity_index: int = int(action.payload.get("opportunity_index", -1))
    var snapshot_value: Variant = action.payload.get("actor_placement", {})
    if patch_key.is_empty() or opportunity_index < 0 or typeof(snapshot_value) != TYPE_DICTIONARY:
        _fail(action, "forage_payload_invalid", false)
        return
    if not _world.has_entity(action.actor_id):
        _fail(action, "forage_actor_missing", false)
        return
    var expected: WorldPlacement = PlacementClass.from_snapshot(snapshot_value)
    var current: WorldPlacement = _world.placement(action.actor_id)
    if expected == null or current == null or not current.equivalent(expected):
        _fail(action, "forage_actor_moved", false)
        return
    var current_environment: Dictionary = _environment_profile(current.anchor)
    if not bool(current_environment.get("ok", false)) or String(current_environment.get("patch_key", "")) != patch_key:
        _fail(action, "forage_environment_changed", false)
        return
    if _state.next_opportunity_index(patch_key) != opportunity_index or _state.remaining(patch_key) < 1:
        _fail(action, "forage_opportunity_stale", false)
        return

    var context := StringName("%s|%s|%d" % [String(ACTION_TYPE), patch_key, opportunity_index])
    var skill_result: Dictionary = _skill_checks.resolve_attempt(
        action.actor_id,
        SkillCatalog.SURVIVAL,
        SURVIVAL_DIFFICULTY,
        action.serial,
        context,
        int(action.payload.get("skill_level", -1))
    )
    if not bool(skill_result.get("ok", false)):
        _fail(action, String(skill_result.get("reason", "forage_skill_unavailable")), false)
        return

    if not _state.consume_expected(patch_key, opportunity_index):
        _fail(action, "forage_depletion_commit_failed", false)
        return
    if not bool(skill_result.get("success", false)):
        if not _skill_checks.award_attempt_xp(action.actor_id, SkillCatalog.SURVIVAL, SURVIVAL_DIFFICULTY, false):
            _state.restore_expected(patch_key, opportunity_index)
            _fail(action, "forage_skill_xp_commit_failed", false)
            return
        _fail(action, "forage_nothing_recovered", true)
        return

    var record: Dictionary = _state.patch_record(patch_key)
    var semantic: StringName = _resource_semantic(record, patch_key, opportunity_index)
    var yield_count: int = 2 if int(skill_result.get("effectiveness_percent", 0)) >= 100 else 1
    var found_ids: Array[String] = []
    var found_semantics: Array[StringName] = []
    for ordinal in range(yield_count):
        var item_id: String = "forage.%d.%s.%03d.%02d" % [_world_seed, patch_key.replace(":", "."), opportunity_index, ordinal]
        if _world.has_entity(item_id) or _world_mutations.create_entity(semantic, item_id) != item_id:
            _rollback_outputs(found_ids)
            _state.restore_expected(patch_key, opportunity_index)
            _fail(action, "forage_output_create_failed", false)
            return
        if not _world_mutations.set_placement(
            item_id,
            Layers.Channel.LOOSE_ITEM,
            current.anchor,
            Facing.Value.SOUTH,
            Footprint.single_cell()
        ):
            _world_mutations.remove_entity(item_id)
            _rollback_outputs(found_ids)
            _state.restore_expected(patch_key, opportunity_index)
            _fail(action, "forage_output_placement_failed", false)
            return
        found_ids.append(item_id)
        found_semantics.append(semantic)

    if not _skill_checks.award_attempt_xp(action.actor_id, SkillCatalog.SURVIVAL, SURVIVAL_DIFFICULTY, true):
        _rollback_outputs(found_ids)
        _state.restore_expected(patch_key, opportunity_index)
        _fail(action, "forage_skill_xp_commit_failed", false)
        return
    _outcomes[action.serial] = {
        "success": true,
        "reason": "",
        "opportunity_consumed": true,
        "found_item_ids": found_ids.duplicate(),
        "found_semantics": found_semantics.duplicate(),
    }

func _environment_profile(anchor: Vector2i) -> Dictionary:
    if not _world.has_terrain(anchor):
        return {"ok": false, "reason": "forage_unmaterialized"}
    var center_terrain: String = String(_world.terrain_at(anchor))
    if center_terrain.begins_with("ground.water"):
        return {"ok": false, "reason": "forage_impossible"}
    var exposure_bounds := Rect2i(
        anchor - Vector2i(EXPOSURE_RADIUS, EXPOSURE_RADIUS),
        Vector2i(EXPOSURE_RADIUS * 2 + 1, EXPOSURE_RADIUS * 2 + 1)
    )
    if not _sky.is_exposed(anchor, exposure_bounds):
        return {"ok": false, "reason": "forage_requires_outdoors"}

    var patch_x: int = floori(float(anchor.x) / float(PATCH_SIZE))
    var patch_y: int = floori(float(anchor.y) / float(PATCH_SIZE))
    var patch_key: String = "%d:%d:%d" % [_world_seed, patch_x, patch_y]
    var patch_rect := Rect2i(Vector2i(patch_x * PATCH_SIZE, patch_y * PATCH_SIZE), Vector2i(PATCH_SIZE, PATCH_SIZE))
    var stick_ground_cells: int = 0
    var stone_ground_cells: int = 0
    var stick_props: int = 0
    var rock_props: int = 0
    for y in range(patch_rect.position.y, patch_rect.position.y + patch_rect.size.y):
        for x in range(patch_rect.position.x, patch_rect.position.x + patch_rect.size.x):
            var cell := Vector2i(x, y)
            if not _world.has_terrain(cell):
                continue
            var terrain: String = String(_world.terrain_at(cell))
            if _supports_sticks(terrain):
                stick_ground_cells += 1
            if _supports_stones(terrain):
                stone_ground_cells += 1
            for entity_id: String in _world.entities_at(cell, Layers.Channel.OBJECT):
                var entity: WorldEntityRecord = _world.entity(entity_id)
                if entity == null:
                    continue
                var semantic_key: String = String(entity.semantic_type)
                if _natural_stick_props.has(semantic_key):
                    stick_props += 1
                elif _natural_rock_props.has(semantic_key):
                    rock_props += 1

    var stick_weight: int = 1 if stick_ground_cells > 0 else 0
    var stone_weight: int = 1 if stone_ground_cells > 0 else 0
    if stick_props > 0:
        stick_weight += mini(4, 1 + stick_props)
    if rock_props > 0:
        stone_weight += mini(4, 1 + rock_props)
    if stick_weight + stone_weight < 1:
        return {"ok": false, "reason": "forage_impossible"}
    var capacity_bonus: int = floori(float(maxi(0, stick_weight + stone_weight - 2)) / 3.0)
    var capacity: int = clampi(1 + capacity_bonus, 1, MAX_PATCH_CAPACITY)
    return {
        "ok": true,
        "reason": "",
        "patch_key": patch_key,
        "capacity": capacity,
        "stick_weight": stick_weight,
        "stone_weight": stone_weight,
    }

func _build_natural_prop_sets() -> void:
    var catalog := EnvironmentProfilesClass.new()
    for profile_id: StringName in catalog.profile_ids():
        var profile: Dictionary = catalog.profile(profile_id)
        for value: Variant in profile.get("tree_semantics", []):
            _natural_stick_props[String(value)] = true
        for value: Variant in profile.get("shrub_semantics", []):
            _natural_stick_props[String(value)] = true
        for value: Variant in profile.get("rock_semantics", []):
            _natural_rock_props[String(value)] = true

static func _supports_sticks(terrain: String) -> bool:
    return terrain.contains("grass") or terrain.contains("forest") or terrain.contains("field") or terrain.contains("marsh")

static func _supports_stones(terrain: String) -> bool:
    if terrain.begins_with("ground.water"):
        return false
    return terrain.contains("gravel") or terrain.contains("sand") or terrain.contains("beach") \
        or terrain.contains("rock") or terrain.contains("road") or terrain.contains("driveway") \
        or terrain.contains("grass") or terrain.contains("forest") or terrain.contains("field") \
        or terrain.contains("marsh")

func _resource_semantic(record: Dictionary, patch_key: String, opportunity_index: int) -> StringName:
    var stick_weight: int = maxi(0, int(record.get("stick_weight", 0)))
    var stone_weight: int = maxi(0, int(record.get("stone_weight", 0)))
    var total: int = stick_weight + stone_weight
    if total <= 0:
        return STONE
    var sample: int = _stable_hash("%d|%s|%d" % [_world_seed, patch_key, opportunity_index]) % total
    return STICK if sample < stick_weight else STONE

static func _stable_hash(text: String) -> int:
    var value: int = 23
    for index in range(text.length()):
        value = int((value * 131 + text.unicode_at(index)) % 2147483647)
    return value

func _rollback_outputs(item_ids: Array[String]) -> void:
    for index in range(item_ids.size() - 1, -1, -1):
        var item_id: String = item_ids[index]
        if _world.has_entity(item_id):
            _world_mutations.remove_entity(item_id)

func _fail(action: TimedAction, reason: String, opportunity_consumed: bool) -> void:
    _outcomes[action.serial] = {
        "success": false,
        "reason": reason,
        "opportunity_consumed": opportunity_consumed,
        "found_item_ids": [],
        "found_semantics": [],
    }
    if not _kernel.fail_action(action.serial, reason):
        push_error("ForageNearbyActionService: failed to mark action failed: %s" % reason)

static func _rejected(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "reason": reason,
        "action_serial": 0,
        "duration_ticks": 0,
        "patch_key": "",
        "remaining_before": 0,
        "skill_id": &"",
        "skill_level": -1,
        "success_chance_percent": 0,
    }
