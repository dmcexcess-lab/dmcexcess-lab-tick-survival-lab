extends Node
class_name SimpleTurnController

const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const Injury = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")
const ImpactProfiles = preload("res://scripts/simulation/combat/CombatImpactProfileCatalog.gd")
const ReachClass = preload("res://scripts/simulation/interaction/WorldInteractionReachQuery.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const CapacityPolicy = preload("res://scripts/simulation/items/ItemAcquisitionCapacityPolicy.gd")
const QueryResult = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const SoundProfiles = preload("res://scripts/simulation/sound/SoundEmissionProfileCatalog.gd")
const RunImpactRules = preload("res://scripts/simulation/movement/MovementRunImpactDamageService.gd")

signal action_resolved(intent: StringName, success: bool, reason: String, turn_number: int)
signal action_busy_changed(busy: bool)
signal turn_completed(turn_number: int, active_actor_count: int)
signal loot_container_opened(container_id: String)
signal loot_container_changed(container_id: String)

const ACTIVE_RADIUS: int = 24
# Effective striking mass includes the moving hand/forearm and committed body mass,
# not merely the anatomical mass of a fist. Keep player unarmed viable but clearly
# below strong purpose-built/improvised melee weapons.
const PLAYER_UNARMED_EFFECTIVE_MASS_GRAMS: int = 2400
const INFECTED_UNARMED_EFFECTIVE_MASS_GRAMS: int = 1000
const WALK_ACTION: StringName = &"movement.step_forward"
const BACKWARD_ACTION: StringName = &"movement.step_backward"
const RUN_ACTION: StringName = &"movement.run_forward"
const RUN_IMPACT_SOUND_POWER: int = 320

var _world: WorldState
var _collision_catalog: CollisionCatalog
var _collision_overrides: CollisionOverrideState
var _player_id: String
var _health: ActorHealthState
var _hands: ActorHandEquipmentState
var _inventory: InventoryContainmentState
var _physical_catalog: ItemPhysicalPropertyCatalog
var _firearm_profiles: FirearmProfileCatalog
var _firearm_state: FirearmState
var _inventory_mutations: InventoryContainmentMutationService
var _hand_mutations: ActorHandEquipmentMutationService
var _carry_acquisition: ItemAcquisitionCapacityPolicy
var _loot_state: LootState
var _reach: WorldInteractionReachQuery
var _impact_profiles: CombatImpactProfileCatalog = ImpactProfiles.new()
var _infected_ids: Array[String] = []
var _turn_number := 0
var _busy := false
var _individual_actor_actions := 0
var _last_completed_intent: StringName = &""
var _before_local_infected_turns: Callable = Callable()
var _spatial_query: SpatialQueryService = null
var _door_passage: DoorMovementPassageResolver = null
var _spatial_sound: SpatialSoundService = null

func _init(
    world: WorldState = null,
    collision_catalog: CollisionCatalog = null,
    collision_overrides: CollisionOverrideState = null,
    player_id: String = "",
    health: ActorHealthState = null,
    hands: ActorHandEquipmentState = null,
    inventory: InventoryContainmentState = null,
    physical_catalog: ItemPhysicalPropertyCatalog = null,
    firearm_profiles: FirearmProfileCatalog = null,
    firearm_state: FirearmState = null,
    inventory_mutations: InventoryContainmentMutationService = null,
    hand_mutations: ActorHandEquipmentMutationService = null,
    carry_acquisition: ItemAcquisitionCapacityPolicy = null,
    loot_state: LootState = null
) -> void:
    _world = world
    _collision_catalog = collision_catalog
    _collision_overrides = collision_overrides
    _player_id = player_id
    _health = health
    _hands = hands
    _inventory = inventory
    _physical_catalog = physical_catalog
    _firearm_profiles = firearm_profiles
    _firearm_state = firearm_state
    _inventory_mutations = inventory_mutations
    _hand_mutations = hand_mutations
    _carry_acquisition = carry_acquisition
    _loot_state = loot_state
    _reach = ReachClass.new(_world) if _world != null else null

func is_ready() -> bool:
    return _world != null and _collision_catalog != null and _collision_overrides != null \
        and not _player_id.is_empty() and _world.placement(_player_id) != null \
        and _health != null and _health.has_actor(_player_id) \
        and _hands != null and _hands.has_actor(_player_id) \
        and _inventory != null and _physical_catalog != null \
        and _firearm_profiles != null and _firearm_state != null and _firearm_state.is_ready() \
        and _inventory_mutations != null and _inventory_mutations.is_ready() \
        and _hand_mutations != null and _hand_mutations.is_ready() \
        and _carry_acquisition != null and _carry_acquisition.is_ready() \
        and _loot_state != null and _reach != null and _reach.is_ready()

func has_control() -> bool:
    return is_ready() and not _busy and _actor_alive(_player_id)

func turn_number() -> int:
    return _turn_number

func individual_actor_actions() -> int:
    return _individual_actor_actions

func last_completed_intent() -> StringName:
    return _last_completed_intent

func set_before_local_infected_turns(callback: Callable) -> bool:
    if not callback.is_valid():
        return false
    _before_local_infected_turns = callback
    return true

func configure_turn_based_movement(
    spatial_query: SpatialQueryService,
    door_passage: DoorMovementPassageResolver,
    spatial_sound: SpatialSoundService
) -> bool:
    if spatial_query == null or not spatial_query.is_ready()         or door_passage == null or not door_passage.is_ready()         or spatial_sound == null or not spatial_sound.is_ready():
        return false
    _spatial_query = spatial_query
    _door_passage = door_passage
    _spatial_sound = spatial_sound
    return true

func infected_actor_ids() -> Array[String]:
    return _infected_ids.duplicate()

func set_infected_actor_ids(ids: Array[String]) -> void:
    _infected_ids.clear()
    for actor_id in ids:
        if not actor_id.is_empty() and actor_id != _player_id and not _infected_ids.has(actor_id):
            _infected_ids.append(actor_id)
    _infected_ids.sort()

func search_loot_container(container_id: String) -> Dictionary:
    var container := container_id.strip_edges()
    if not _begin_direct_action(&"loot.search"):
        return _direct_failure("player_unavailable")
    if not _valid_reachable_loot_container(container):
        return _reject_direct_action(&"loot.search", "loot_container_unreachable")
    var contents := _inventory.direct_contents(container)
    var result := _complete_direct_action(&"loot.search", "")
    result["container_id"] = container
    result["contents"] = contents
    loot_container_opened.emit(container)
    return result

func take_loot_item(container_id: String, item_id: String) -> Dictionary:
    var container := container_id.strip_edges()
    var item := item_id.strip_edges()
    if not _begin_direct_action(&"loot.take"):
        return _direct_failure("player_unavailable")
    if not _valid_reachable_loot_container(container):
        return _reject_direct_action(&"loot.take", "loot_container_unreachable")
    if item.is_empty() or not _world.has_entity(item) or _inventory.container_of(item) != container:
        return _reject_direct_action(&"loot.take", "item_not_in_container")
    var capacity := _carry_acquisition.evaluate(_player_id, item)
    if int(capacity.get("status", CapacityPolicy.Status.UNKNOWN)) != CapacityPolicy.Status.ALLOWED:
        return _reject_direct_action(&"loot.take", String(capacity.get("reason", "carry_capacity_rejected")))
    if not _inventory_mutations.set_container(item, _player_id):
        return _reject_direct_action(&"loot.take", "containment_mutation_failed")
    var result := _complete_direct_action(&"loot.take", "")
    result["container_id"] = container
    result["item_id"] = item
    loot_container_changed.emit(container)
    return result

func store_loot_item(container_id: String, item_id: String) -> Dictionary:
    var container := container_id.strip_edges()
    var item := item_id.strip_edges()
    if not _begin_direct_action(&"loot.store"):
        return _direct_failure("player_unavailable")
    if not _valid_reachable_loot_container(container):
        return _reject_direct_action(&"loot.store", "loot_container_unreachable")
    var source_container := _inventory.container_of(item)
    if item.is_empty() or not _world.has_entity(item) or source_container.is_empty() \
        or not _personal_container_accessible(source_container):
        return _reject_direct_action(&"loot.store", "item_not_carried")
    if not _inventory_mutations.set_container(item, container):
        return _reject_direct_action(&"loot.store", "containment_mutation_failed")
    var result := _complete_direct_action(&"loot.store", "")
    result["container_id"] = container
    result["item_id"] = item
    loot_container_changed.emit(container)
    return result

func equip_inventory_item(item_id: String, slot: int) -> Dictionary:
    var item := item_id.strip_edges()
    if not _begin_direct_action(&"inventory.equip"):
        return _direct_failure("player_unavailable")
    if not Slots.is_valid(slot) or not _hands.has_actor(_player_id):
        return _reject_direct_action(&"inventory.equip", "invalid_slot")
    if not _hands.item_in_slot(_player_id, slot).is_empty():
        return _reject_direct_action(&"inventory.equip", "hand_occupied")
    var source_container := _inventory.container_of(item)
    if item.is_empty() or not _world.has_entity(item) or source_container.is_empty() \
        or not _personal_container_accessible(source_container):
        return _reject_direct_action(&"inventory.equip", "item_not_carried")
    if not _inventory_mutations.clear_container(item):
        return _reject_direct_action(&"inventory.equip", "source_mutation_failed")
    if not _hand_mutations.set_item(_player_id, slot, item):
        _inventory_mutations.set_container(item, source_container)
        return _reject_direct_action(&"inventory.equip", "equipment_mutation_failed")
    var result := _complete_direct_action(&"inventory.equip", "")
    result["item_id"] = item
    result["slot"] = slot
    return result

func stow_equipped_item(slot: int) -> Dictionary:
    if not _begin_direct_action(&"inventory.stow"):
        return _direct_failure("player_unavailable")
    if not Slots.is_valid(slot) or not _hands.has_actor(_player_id):
        return _reject_direct_action(&"inventory.stow", "invalid_slot")
    var item := _hands.item_in_slot(_player_id, slot)
    if item.is_empty():
        return _reject_direct_action(&"inventory.stow", "hand_empty")
    if not _hand_mutations.clear_slot(_player_id, slot):
        return _reject_direct_action(&"inventory.stow", "source_mutation_failed")
    if not _inventory_mutations.set_container(item, _player_id):
        _hand_mutations.set_item(_player_id, slot, item)
        return _reject_direct_action(&"inventory.stow", "containment_mutation_failed")
    var result := _complete_direct_action(&"inventory.stow", "")
    result["item_id"] = item
    result["slot"] = slot
    return result

func drop_inventory_item(item_id: String) -> Dictionary:
    var item := item_id.strip_edges()
    if not _begin_direct_action(&"inventory.drop"):
        return _direct_failure("player_unavailable")
    var source_container := _inventory.container_of(item)
    if item.is_empty() or not _world.has_entity(item) or source_container.is_empty() \
        or not _personal_container_accessible(source_container):
        return _reject_direct_action(&"inventory.drop", "item_not_carried")
    var actor := _world.placement(_player_id)
    if actor == null:
        return _reject_direct_action(&"inventory.drop", "player_unplaced")
    if not _inventory_mutations.clear_container(item):
        return _reject_direct_action(&"inventory.drop", "source_mutation_failed")
    if not _world.set_placement(item, Layers.Channel.LOOSE_ITEM, actor.anchor, actor.facing, Footprint.single_cell()):
        _inventory_mutations.set_container(item, source_container)
        return _reject_direct_action(&"inventory.drop", "world_placement_failed")
    var result := _complete_direct_action(&"inventory.drop", "")
    result["item_id"] = item
    return result

func drop_equipped_item(slot: int) -> Dictionary:
    if not _begin_direct_action(&"inventory.drop"):
        return _direct_failure("player_unavailable")
    if not Slots.is_valid(slot) or not _hands.has_actor(_player_id):
        return _reject_direct_action(&"inventory.drop", "invalid_slot")
    var item := _hands.item_in_slot(_player_id, slot)
    var actor := _world.placement(_player_id)
    if item.is_empty() or actor == null:
        return _reject_direct_action(&"inventory.drop", "hand_empty")
    if not _hand_mutations.clear_slot(_player_id, slot):
        return _reject_direct_action(&"inventory.drop", "source_mutation_failed")
    if not _world.set_placement(item, Layers.Channel.LOOSE_ITEM, actor.anchor, actor.facing, Footprint.single_cell()):
        _hand_mutations.set_item(_player_id, slot, item)
        return _reject_direct_action(&"inventory.drop", "world_placement_failed")
    var result := _complete_direct_action(&"inventory.drop", "")
    result["item_id"] = item
    result["slot"] = slot
    return result

func pickup_loose_item(item_id: String) -> Dictionary:
    var item := item_id.strip_edges()
    if not _begin_direct_action(&"inventory.pickup"):
        return _direct_failure("player_unavailable")
    var placement := _world.placement(item)
    if item.is_empty() or not _world.has_entity(item) or placement == null \
        or placement.channel != Layers.Channel.LOOSE_ITEM:
        return _reject_direct_action(&"inventory.pickup", "loose_item_missing")
    if not _reach.target_reachable(_player_id, item, ReachClass.CONTACT_FORWARD):
        return _reject_direct_action(&"inventory.pickup", "out_of_reach")
    var capacity := _carry_acquisition.evaluate(_player_id, item)
    if int(capacity.get("status", CapacityPolicy.Status.UNKNOWN)) != CapacityPolicy.Status.ALLOWED:
        return _reject_direct_action(&"inventory.pickup", String(capacity.get("reason", "carry_capacity_rejected")))
    if not _world.unplace_entity(item):
        return _reject_direct_action(&"inventory.pickup", "source_mutation_failed")
    if not _inventory_mutations.set_container(item, _player_id):
        _world.set_placement(item, placement.channel, placement.anchor, placement.facing, placement.footprint, placement.structure_axis)
        return _reject_direct_action(&"inventory.pickup", "containment_mutation_failed")
    var result := _complete_direct_action(&"inventory.pickup", "")
    result["item_id"] = item
    return result

func _valid_reachable_loot_container(container_id: String) -> bool:
    return not container_id.is_empty() and _world.has_entity(container_id) \
        and _loot_state.has_container(container_id) and _inventory.has_container(container_id) \
        and _reach.target_reachable(_player_id, container_id, ReachClass.CONTACT_FORWARD)

func _personal_container_accessible(container_id: String) -> bool:
    var current := container_id.strip_edges()
    var visited: Dictionary = {}
    while not current.is_empty() and not visited.has(current):
        if current == _player_id:
            return true
        visited[current] = true
        current = _inventory.container_of(current)
    return false

func _begin_direct_action(_intent: StringName) -> bool:
    if not has_control():
        return false
    _set_busy(true)
    return true

func _reject_direct_action(intent: StringName, reason: String) -> Dictionary:
    _set_busy(false)
    action_resolved.emit(intent, false, reason, _turn_number)
    return _direct_failure(reason)

func _complete_direct_action(intent: StringName, reason: String) -> Dictionary:
    _turn_number += 1
    _last_completed_intent = intent
    var acted := _run_local_infected_turns()
    turn_completed.emit(_turn_number, acted)
    action_resolved.emit(intent, true, reason, _turn_number)
    _set_busy(false)
    return {
        "success": true,
        "reason": reason,
        "turn_number": _turn_number,
        "active_actor_count": acted,
    }

func _direct_failure(reason: String) -> Dictionary:
    return {
        "success": false,
        "reason": reason,
        "turn_number": _turn_number,
        "active_actor_count": 0,
    }

func submit_intent(intent: StringName) -> void:
    if not has_control():
        return
    if not Intents.is_movement(intent) and intent != Intents.COMBAT_FORWARD:
        action_resolved.emit(intent, false, "not_migrated_to_simple_turns", _turn_number)
        return

    _set_busy(true)
    var player_hp_before := _health.current_hp(_player_id) if _health != null and _health.has_actor(_player_id) else -1
    var result := {"accepted": false, "reason": "unsupported_action"}
    if Intents.is_movement(intent):
        result = _resolve_player_movement(intent)
    else:
        result = _resolve_player_combat()

    if not bool(result.get("accepted", false)):
        _set_busy(false)
        action_resolved.emit(intent, false, String(result.get("reason", "action_rejected")), _turn_number)
        return

    _turn_number += 1
    _last_completed_intent = intent
    var acted := _run_local_infected_turns()
    turn_completed.emit(_turn_number, acted)
    var feedback := String(result.get("reason", ""))
    if intent == Intents.COMBAT_FORWARD:
        feedback = _append_player_damage_feedback(feedback, player_hp_before)
    action_resolved.emit(intent, true, feedback, _turn_number)
    _set_busy(false)

func _resolve_player_movement(intent: StringName) -> Dictionary:
    var current := _world.placement(_player_id)
    if current == null:
        return {"accepted": false, "reason": "player_unplaced"}

    if intent == Intents.TURN_LEFT or intent == Intents.TURN_RIGHT:
        var target_facing := Facing.turn_left(current.facing) if intent == Intents.TURN_LEFT else Facing.turn_right(current.facing)
        return {
            "accepted": _world.move_entity(_player_id, current.anchor, target_facing),
            "reason": "",
        }

    if intent == Intents.RUN_FORWARD:
        return _resolve_run_forward(current)

    var direction := Facing.vector(current.facing)
    if intent == Intents.BACKWARD:
        direction = -direction
    elif intent != Intents.FORWARD:
        return {"accepted": false, "reason": "unsupported_movement"}

    var action_type: StringName = BACKWARD_ACTION if intent == Intents.BACKWARD else WALK_ACTION
    var step := _attempt_movement_step(current, current.anchor + direction, action_type)
    if not bool(step.get("moved", false)):
        return {"accepted": false, "reason": String(step.get("reason", "movement_blocked"))}
    _emit_movement_sound(SoundProfiles.WALK_STEP, current.anchor + direction, "walk.%d" % (_turn_number + 1))
    if bool(step.get("door_opened", false)):
        _emit_movement_sound(SoundProfiles.DOOR_NORMAL, current.anchor + direction, "walk_door.%d" % (_turn_number + 1))
    return {"accepted": true, "reason": ""}

func _resolve_run_forward(current: WorldPlacement) -> Dictionary:
    var direction := Facing.vector(current.facing)
    var position := current.anchor
    var opened_door := false

    for stride_index in range(1, 3):
        var target := position + direction
        var step := _attempt_movement_step(_world.placement(_player_id), target, RUN_ACTION)
        if bool(step.get("moved", false)):
            position = target
            _emit_movement_sound(
                SoundProfiles.RUN_STRIDE,
                position,
                "run.%d.%d" % [_turn_number + 1, stride_index]
            )
            if bool(step.get("door_opened", false)):
                opened_door = true
                _emit_movement_sound(
                    SoundProfiles.DOOR_LOUD,
                    position,
                    "run_door.%d.%d" % [_turn_number + 1, stride_index]
                )
            continue

        if bool(step.get("blocked", false)):
            _apply_run_impact(target, stride_index)
            return {
                "accepted": true,
                "reason": "run_impact",
                "partial_movement": stride_index > 1,
                "door_opened": opened_door,
            }
        return {"accepted": false, "reason": String(step.get("reason", "movement_blocked"))}

    return {"accepted": true, "reason": "", "door_opened": opened_door}

func _attempt_movement_step(
    current: WorldPlacement,
    target_anchor: Vector2i,
    action_type: StringName
) -> Dictionary:
    if current == null or _spatial_query == null:
        return {"moved": false, "blocked": false, "reason": "movement_query_unavailable"}

    var query_result: SpatialQueryResult = _spatial_query.query_entity_footprint(
        _player_id,
        target_anchor,
        current.facing,
        true
    )
    if query_result == null or query_result.status == QueryResult.Status.UNKNOWN:
        return {"moved": false, "blocked": false, "reason": "target_unknown"}

    var door_opened := false
    if query_result.status == QueryResult.Status.BLOCKED         and _door_passage != null         and _door_passage.can_resolve(_player_id, action_type, query_result):
        if not _door_passage.resolve(_player_id, 0, action_type, query_result):
            return {"moved": false, "blocked": true, "reason": "door_passage_failed"}
        door_opened = true
        query_result = _spatial_query.query_entity_footprint(
            _player_id,
            target_anchor,
            current.facing,
            true
        )

    if query_result == null or query_result.status == QueryResult.Status.UNKNOWN:
        return {"moved": false, "blocked": false, "reason": "target_unknown"}
    if query_result.status == QueryResult.Status.BLOCKED:
        return {
            "moved": false,
            "blocked": true,
            "reason": "movement_blocked",
            "blocking_entity_ids": query_result.blocking_entity_ids.duplicate(),
        }
    if query_result.status != QueryResult.Status.CLEAR:
        return {"moved": false, "blocked": false, "reason": "target_unknown"}
    if not _world.move_entity(_player_id, target_anchor, current.facing):
        return {"moved": false, "blocked": false, "reason": "movement_commit_failed"}
    return {"moved": true, "blocked": false, "door_opened": door_opened}

func _apply_run_impact(target_cell: Vector2i, stride_index: int) -> void:
    if _health != null and _health.has_actor(_player_id):
        _health.apply_damage(_player_id, RunImpactRules.IMPACT_DAMAGE_HP)
    _emit_movement_sound(
        SoundProfiles.OPENING_IMPACT,
        target_cell,
        "run_impact.%d.%d" % [_turn_number + 1, stride_index],
        RUN_IMPACT_SOUND_POWER
    )

func _emit_movement_sound(
    profile_id: StringName,
    cell: Vector2i,
    group_key: String,
    power_override: int = -1
) -> void:
    if _spatial_sound == null:
        return
    _spatial_sound.emit_sound(profile_id, cell, _player_id, group_key, power_override)

func _resolve_player_combat() -> Dictionary:
    var firearm_id := _equipped_firearm(_player_id)
    if not firearm_id.is_empty():
        if not _firearm_state.ensure_firearm(firearm_id):
            return {"accepted": false, "reason": "firearm_state_unavailable"}
        if _firearm_state.chamber_round(firearm_id).is_empty():
            return _resolve_reload(_player_id, firearm_id)
        return _resolve_firearm_attack(_player_id, firearm_id)
    return _resolve_melee_attack(_player_id)

func _resolve_melee_attack(attacker_id: String) -> Dictionary:
    if not _actor_alive(attacker_id):
        return {"accepted": false, "reason": "combat_actor_unavailable"}
    var placement := _world.placement(attacker_id)
    if placement == null:
        return {"accepted": false, "reason": "attacker_unplaced"}
    var strike_cell := placement.anchor + Facing.vector(placement.facing)
    var target_id := _living_actor_at(strike_cell, attacker_id)
    if target_id.is_empty():
        return {"accepted": true, "reason": "MISS"}

    var strike := _melee_profile(attacker_id)
    if not bool(strike.get("available", false)):
        return {"accepted": false, "reason": String(strike.get("reason", "strike_unavailable"))}
    var damage := _derived_melee_damage(strike)
    var target_hp_before := _health.current_hp(target_id)
    var target_max_hp := _health.max_hp(target_id)
    var target_label := _combat_target_label(target_id)
    if not _apply_impact(attacker_id, target_id, damage, StringName(strike.get("contact_mode", &"blunt"))):
        return {"accepted": false, "reason": "impact_failed"}
    var applied_damage := mini(damage, maxi(0, target_hp_before))
    var target_hp_after := maxi(0, target_hp_before - applied_damage)
    return {
        "accepted": true,
        "reason": _impact_feedback(String(strike.get("label", "HIT")), target_label, applied_damage, target_hp_after, target_max_hp),
    }

func _resolve_firearm_attack(attacker_id: String, firearm_id: String) -> Dictionary:
    if not _actor_alive(attacker_id):
        return {"accepted": false, "reason": "combat_actor_unavailable"}
    var firearm := _world.entity(firearm_id)
    var placement := _world.placement(attacker_id)
    if firearm == null or placement == null:
        return {"accepted": false, "reason": "firearm_unavailable"}
    var round_id := _firearm_state.chamber_round(firearm_id)
    if round_id.is_empty():
        return {"accepted": false, "reason": "empty_chamber"}

    var direction := Facing.vector(placement.facing)
    var max_range := _firearm_profiles.snap_range_cells(firearm.semantic_type)
    var hit_id := ""
    for distance in range(1, max_range + 1):
        var cell := placement.anchor + direction * distance
        if not _world.has_terrain(cell):
            break
        hit_id = _living_actor_at(cell, attacker_id)
        if not hit_id.is_empty():
            break
        if _cell_blocks_shot(cell, attacker_id):
            break

    var consumed := _firearm_state.release_chambered_round(firearm_id)
    if consumed != round_id or not _world.remove_entity(round_id):
        return {"accepted": false, "reason": "round_consumption_failed"}
    _firearm_state.cycle_next_round(firearm_id)

    if not hit_id.is_empty():
        var damage := _firearm_profiles.impact_damage(firearm.semantic_type)
        var target_hp_before := _health.current_hp(hit_id)
        var target_max_hp := _health.max_hp(hit_id)
        var target_label := _combat_target_label(hit_id)
        if not _health.apply_damage(hit_id, damage):
            return {"accepted": false, "reason": "firearm_damage_failed"}
        if _health.has_actor(hit_id):
            _health.add_injury(hit_id, &"gunshot", Injury.TORSO, Injury.Severity.CRITICAL)
        var applied_damage := mini(damage, maxi(0, target_hp_before))
        var target_hp_after := maxi(0, target_hp_before - applied_damage)
        return {"accepted": true, "reason": _impact_feedback("SHOT", target_label, applied_damage, target_hp_after, target_max_hp)}
    return {"accepted": true, "reason": "SHOT MISSED"}

func _resolve_reload(actor_id: String, firearm_id: String) -> Dictionary:
    if not _actor_alive(actor_id) or not _firearm_state.ensure_firearm(firearm_id):
        return {"accepted": false, "reason": "reload_unavailable"}
    if not _firearm_state.chamber_round(firearm_id).is_empty():
        return {"accepted": false, "reason": "already_chambered"}

    if not _firearm_state.inserted_magazine(firearm_id).is_empty():
        var chambered := _firearm_state.chamber_from_magazine(firearm_id)
        if not chambered.is_empty():
            return {"accepted": true, "reason": "reloaded"}

    var current_mag := _firearm_state.inserted_magazine(firearm_id)
    var candidate := _find_compatible_magazine(actor_id, firearm_id, current_mag)
    if candidate.is_empty():
        return {"accepted": false, "reason": "nothing_to_reload"}
    if not current_mag.is_empty() and not _firearm_state.eject_magazine(firearm_id, actor_id):
        return {"accepted": false, "reason": "reload_eject_failed"}
    if not _firearm_state.insert_magazine(firearm_id, candidate):
        return {"accepted": false, "reason": "reload_insert_failed"}
    if _firearm_state.chamber_from_magazine(firearm_id).is_empty():
        return {"accepted": false, "reason": "reload_chamber_failed"}
    return {"accepted": true, "reason": "reloaded"}

func _run_local_infected_turns() -> int:
    if _before_local_infected_turns.is_valid():
        _before_local_infected_turns.call()
    var player := _world.placement(_player_id)
    if player == null or not _actor_alive(_player_id):
        return 0
    var acted := 0
    for actor_id in _infected_ids:
        if not _actor_alive(_player_id):
            break
        if not _actor_alive(actor_id):
            continue
        var placement := _world.placement(actor_id)
        player = _world.placement(_player_id)
        if placement == null or player == null:
            continue
        var delta := player.anchor - placement.anchor
        if maxi(abs(delta.x), abs(delta.y)) > ACTIVE_RADIUS:
            continue

        if absi(delta.x) + absi(delta.y) == 1:
            if _resolve_infected_attack(actor_id, _player_id):
                acted += 1
                _individual_actor_actions += 1
            continue

        var step := _greedy_step(delta)
        if step == Vector2i.ZERO:
            continue
        var target := placement.anchor + step
        var facing := Facing.from_vector(step)
        if not _can_occupy(actor_id, placement, target, facing):
            continue
        if _world.move_entity(actor_id, target, facing):
            acted += 1
            _individual_actor_actions += 1
    return acted

func _resolve_infected_attack(attacker_id: String, target_id: String) -> bool:
    if not _actor_alive(attacker_id) or not _actor_alive(target_id):
        return false
    var attacker := _world.placement(attacker_id)
    var target := _world.placement(target_id)
    if attacker == null or target == null:
        return false
    var delta := target.anchor - attacker.anchor
    if absi(delta.x) + absi(delta.y) != 1:
        return false
    _world.move_entity(attacker_id, attacker.anchor, Facing.from_vector(delta))
    var profile := _impact_profiles.unarmed_profile()
    var strike := {
        "available": true,
        "weight_grams": INFECTED_UNARMED_EFFECTIVE_MASS_GRAMS,
        "contact_mode": profile.contact_mode,
        "rigidity_bp": profile.rigidity_bp,
        "leverage_bp": profile.leverage_bp,
        "contact_transfer_bp": profile.contact_transfer_bp,
    }
    return _apply_impact(attacker_id, target_id, _derived_melee_damage(strike), profile.contact_mode)

func _apply_impact(attacker_id: String, target_id: String, damage: int, contact_mode: StringName) -> bool:
    if damage <= 0 or not _actor_alive(target_id):
        return false
    if not _health.apply_damage(target_id, damage):
        return false
    _health.add_injury(
        target_id,
        _injury_type(contact_mode),
        _body_region(attacker_id, target_id),
        _severity_for_damage(damage)
    )
    return true

func _melee_profile(actor_id: String) -> Dictionary:
    if not _hands.has_actor(actor_id):
        return {"available": false, "reason": "hand_state_unavailable"}

    var candidates: Array[Dictionary] = []
    var empty_hand := false
    for slot: int in [Slots.Value.PRIMARY_RIGHT, Slots.Value.SECONDARY_LEFT]:
        var item_id := _hands.item_in_slot(actor_id, slot)
        if item_id.is_empty():
            empty_hand = true
            continue
        var entity := _world.entity(item_id)
        if entity == null:
            continue
        var weight := _physical_catalog.weight_grams(entity.semantic_type)
        if weight <= 0:
            continue
        var profile := _impact_profiles.profile_for_item(entity.semantic_type, weight)
        if profile == null or not profile.is_valid():
            continue
        candidates.append({
            "available": true,
            "label": _combat_item_label(entity.semantic_type),
            "weight_grams": weight,
            "contact_mode": profile.contact_mode,
            "rigidity_bp": profile.rigidity_bp,
            "leverage_bp": profile.leverage_bp,
            "contact_transfer_bp": profile.contact_transfer_bp,
        })

    # An empty hand always remains a viable weapon. Do not force the player to hit
    # with a bottle/notebook merely because it happens to occupy the other hand.
    if empty_hand:
        var unarmed := _impact_profiles.unarmed_profile()
        candidates.append({
            "available": true,
            "label": "FIST",
            "weight_grams": PLAYER_UNARMED_EFFECTIVE_MASS_GRAMS,
            "contact_mode": unarmed.contact_mode,
            "rigidity_bp": unarmed.rigidity_bp,
            "leverage_bp": unarmed.leverage_bp,
            "contact_transfer_bp": unarmed.contact_transfer_bp,
        })

    if candidates.is_empty():
        return {"available": false, "reason": "no_striking_hand_available"}
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ad := _derived_melee_damage(a)
        var bd := _derived_melee_damage(b)
        if ad != bd:
            return ad > bd
        return String(a.get("label", "")) < String(b.get("label", ""))
    )
    return candidates[0]

func _derived_melee_damage(strike: Dictionary) -> int:
    var mass := maxi(1, int(strike.get("weight_grams", PLAYER_UNARMED_EFFECTIVE_MASS_GRAMS)))
    var value := maxi(1, ceili(float(mass) / 180.0))
    value = maxi(1, int(round(float(value * int(strike.get("rigidity_bp", 10000))) / 10000.0)))
    value = maxi(1, int(round(float(value * int(strike.get("leverage_bp", 10000))) / 10000.0)))
    value = maxi(1, int(round(float(value * int(strike.get("contact_transfer_bp", 10000))) / 10000.0)))
    var contact_mode := StringName(strike.get("contact_mode", &"blunt"))
    if contact_mode == &"edge":
        value = maxi(1, int(round(float(value) * 2.0)))
    elif contact_mode == &"point":
        value = maxi(1, int(round(float(value) * 2.5)))
    return clampi(value, 1, 25)

func _impact_feedback(source_label: String, target_label: String, damage: int, hp_after: int, max_hp: int) -> String:
    if hp_after <= 0:
        return "%s %d DMG · %s DOWN" % [source_label, damage, target_label]
    return "%s %d DMG · %s %d/%d HP" % [source_label, damage, target_label, hp_after, max_hp]

func _combat_target_label(target_id: String) -> String:
    return "ZOMBIE" if _infected_ids.has(target_id) else "TARGET"

func _append_player_damage_feedback(feedback: String, hp_before: int) -> String:
    if hp_before < 0 or _health == null or not _health.has_actor(_player_id):
        return feedback
    var hp_after := _health.current_hp(_player_id)
    if hp_after >= hp_before:
        return feedback
    var incoming := hp_before - hp_after
    var suffix := "YOU -%d · %d/%d HP" % [incoming, hp_after, _health.max_hp(_player_id)]
    return suffix if feedback.is_empty() else "%s · %s" % [feedback, suffix]

static func _combat_item_label(semantic_type: StringName) -> String:
    var parts: PackedStringArray = String(semantic_type).split(".", false)
    if parts.is_empty():
        return "HIT"
    return String(parts[parts.size() - 1]).replace("_", " ").to_upper()

func _equipped_firearm(actor_id: String) -> String:
    if not _hands.has_actor(actor_id):
        return ""
    for item_id: String in [_hands.primary_item(actor_id), _hands.secondary_item(actor_id)]:
        if item_id.is_empty():
            continue
        var entity := _world.entity(item_id)
        if entity != null and _firearm_profiles.has_firearm(entity.semantic_type):
            return item_id
    return ""

func _find_compatible_magazine(actor_id: String, firearm_id: String, excluded: String) -> String:
    var firearm := _world.entity(firearm_id)
    if firearm == null:
        return ""
    var required := _firearm_profiles.magazine_type(firearm.semantic_type)
    for item_id: String in _inventory.direct_contents(actor_id):
        if item_id == excluded:
            continue
        var item := _world.entity(item_id)
        if item != null and item.semantic_type == required and _firearm_state.ensure_magazine(item_id) \
            and not _inventory.direct_contents(item_id).is_empty():
            return item_id
    return ""

func _living_actor_at(cell: Vector2i, excluded_id: String) -> String:
    var candidates := _world.entities_at(cell, Layers.Channel.ACTOR)
    candidates.sort()
    for actor_id: String in candidates:
        if actor_id != excluded_id and _actor_alive(actor_id):
            return actor_id
    return ""

func _actor_alive(actor_id: String) -> bool:
    return not actor_id.is_empty() and _health != null and _health.has_actor(actor_id) \
        and _health.current_hp(actor_id) > 0 and _world.placement(actor_id) != null

func _can_occupy(entity_id: String, current: WorldPlacement, target_anchor: Vector2i, target_facing: int) -> bool:
    if current == null or current.footprint == null:
        return false
    for cell: Vector2i in current.footprint.world_cells(target_anchor, target_facing):
        if not _world.has_terrain(cell):
            return false
        for occupant_id: String in _world.entities_at(cell):
            if occupant_id == entity_id:
                continue
            if _collision_overrides.has_override(occupant_id):
                if _collision_overrides.blocks_movement(occupant_id):
                    return false
                continue
            var record := _world.entity(occupant_id)
            var placement := _world.placement(occupant_id)
            if record == null or placement == null:
                return false
            var profile := _collision_catalog.profile_for(record.semantic_type)
            if profile != null:
                if profile.blocks_movement:
                    return false
                continue
            if placement.channel == Layers.Channel.STRUCTURE or placement.channel == Layers.Channel.OBJECT or placement.channel == Layers.Channel.ACTOR:
                return false
    return true

func _cell_blocks_shot(cell: Vector2i, shooter_id: String) -> bool:
    for occupant_id: String in _world.entities_at(cell):
        if occupant_id == shooter_id:
            continue
        if _collision_overrides.has_override(occupant_id):
            if _collision_overrides.blocks_movement(occupant_id):
                return true
            continue
        var record := _world.entity(occupant_id)
        var placement := _world.placement(occupant_id)
        if record == null or placement == null:
            return true
        var profile := _collision_catalog.profile_for(record.semantic_type)
        if profile != null:
            if profile.blocks_movement:
                return true
            continue
        if placement.channel == Layers.Channel.STRUCTURE or placement.channel == Layers.Channel.OBJECT:
            return true
    return false

func _greedy_step(delta: Vector2i) -> Vector2i:
    if delta == Vector2i.ZERO:
        return Vector2i.ZERO
    if abs(delta.x) >= abs(delta.y) and delta.x != 0:
        return Vector2i(signi(delta.x), 0)
    if delta.y != 0:
        return Vector2i(0, signi(delta.y))
    return Vector2i.ZERO

func _set_busy(value: bool) -> void:
    if value == _busy:
        return
    _busy = value
    action_busy_changed.emit(value)

static func _severity_for_damage(damage: int) -> int:
    if damage >= 10:
        return Injury.Severity.CRITICAL
    if damage >= 5:
        return Injury.Severity.SERIOUS
    return Injury.Severity.MINOR

static func _injury_type(contact_mode: StringName) -> StringName:
    if contact_mode == &"point":
        return &"puncture"
    if contact_mode == &"edge":
        return &"laceration"
    return &"blunt_trauma"

func _body_region(attacker_id: String, target_id: String) -> StringName:
    var regions: Array[StringName] = Injury.regions()
    var key := "%s|%s|%d" % [attacker_id, target_id, _turn_number + 1]
    return regions[absi(hash(key)) % regions.size()]
