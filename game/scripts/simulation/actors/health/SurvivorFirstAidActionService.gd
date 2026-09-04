extends RefCounted
class_name SurvivorFirstAidActionService

const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const Injury = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")

## Exact-item first aid over authoritative Health/Injury, WHAT, containment, hands,
## broad Survival competence and WHEN. No medical effect exists only in UI.

const ACTION_TYPE: StringName = &"health.first_aid"
const OUTCOME_LIMIT: int = 64

var _world: WorldState = null
var _world_mutations: WorldMutationService = null
var _hands: ActorHandEquipmentState = null
var _hand_mutations: ActorHandEquipmentMutationService = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _carry_query: ActorCarryQuery = null
var _kernel: TickKernel = null
var _health: ActorHealthState = null
var _skill_checks: ActorSkillCheckService = null
var _outcomes: Dictionary = {}
var _outcome_order: Array[int] = []

func _init(
    world_state: WorldState = null,
    world_mutations: WorldMutationService = null,
    hand_state: ActorHandEquipmentState = null,
    hand_mutations: ActorHandEquipmentMutationService = null,
    inventory_state: InventoryContainmentState = null,
    inventory_mutations: InventoryContainmentMutationService = null,
    carry_query: ActorCarryQuery = null,
    kernel: TickKernel = null,
    health_state: ActorHealthState = null,
    skill_checks: ActorSkillCheckService = null
) -> void:
    _world = world_state
    _world_mutations = world_mutations
    _hands = hand_state
    _hand_mutations = hand_mutations
    _inventory = inventory_state
    _inventory_mutations = inventory_mutations
    _carry_query = carry_query
    _kernel = kernel
    _health = health_state
    _skill_checks = skill_checks
    if _kernel != null:
        var finished := Callable(self, "_on_action_finished")
        if not _kernel.action_finished.is_connected(finished):
            _kernel.action_finished.connect(finished)

func is_ready() -> bool:
    return _world != null and _world_mutations != null and _world_mutations.is_ready() \
        and _hands != null and _hand_mutations != null and _hand_mutations.is_ready() \
        and _inventory != null and _inventory_mutations != null and _inventory_mutations.is_ready() \
        and _carry_query != null and _kernel != null and _health != null \
        and _skill_checks != null and _skill_checks.is_ready()

func treatment_offers(actor_id: String, selected_item_id: String) -> Array[Dictionary]:
    var offers: Array[Dictionary] = []
    var actor: String = actor_id.strip_edges()
    var item_id: String = selected_item_id.strip_edges()
    if not is_ready() or not _health.has_actor(actor) or not _item_carried_by(actor, item_id):
        return offers
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return offers
    var profile: Dictionary = _profile(entity.semantic_type)
    if profile.is_empty():
        return offers

    var resource_ids: Array[String] = [item_id]
    var resource_semantics: Array[StringName] = [entity.semantic_type]
    if bool(profile.get("requires_partner", false)):
        var partner: Dictionary = _partner_for(actor, entity.semantic_type, item_id)
        if partner.is_empty():
            return offers
        resource_ids.append(String(partner.get("item_id", "")))
        resource_semantics.append(StringName(partner.get("semantic_type", &"")))

    for wound: ActorInjuryRecord in _health.injuries(actor):
        if wound.stabilized and wound.treated:
            continue
        var difficulty: int = clampi(wound.severity + int(profile.get("difficulty_add", 0)), 1, 10)
        var skill: Dictionary = _skill_checks.action_profile(
            actor,
            SkillCatalog.SURVIVAL,
            int(profile.get("base_duration_ticks", 20)),
            difficulty
        )
        if not bool(skill.get("ok", false)):
            continue
        offers.append({
            "available": true,
            "item_id": item_id,
            "injury_id": wound.injury_id,
            "label": "%s %s %s — %s" % [
                String(profile.get("verb", "TREAT")),
                _severity_label(wound.severity),
                _humanize(String(wound.injury_type)),
                _humanize(String(wound.body_region)),
            ],
            "mode": String(profile.get("mode", "dress")),
            "resource_item_ids": resource_ids.duplicate(),
            "resource_semantics": resource_semantics.duplicate(),
            "duration_ticks": int(skill.get("duration_ticks", 1)),
            "skill_level": int(skill.get("skill_level", -1)),
            "skill_difficulty": difficulty,
            "success_chance_percent": int(skill.get("success_chance_percent", 0)),
        })
    return offers

func begin_treatment(actor_id: String, selected_item_id: String, injury_id: String) -> int:
    var actor: String = actor_id.strip_edges()
    var target_injury: String = injury_id.strip_edges()
    if not is_ready() or _kernel.has_active_action(actor):
        return 0
    var chosen: Dictionary = {}
    for offer: Dictionary in treatment_offers(actor, selected_item_id):
        if String(offer.get("injury_id", "")) == target_injury:
            chosen = offer
            break
    var wound: ActorInjuryRecord = _health.injury(actor, target_injury)
    if chosen.is_empty() or wound == null:
        return 0
    return _kernel.begin_action(actor, ACTION_TYPE, int(chosen.get("duration_ticks", 1)), TickRules.InterruptionPolicy.COMMITTED, [], {
        "injury_id": target_injury,
        "mode": String(chosen.get("mode", "dress")),
        "resource_item_ids": chosen.get("resource_item_ids", []).duplicate(),
        "resource_semantics": chosen.get("resource_semantics", []).duplicate(),
        "skill_level": int(chosen.get("skill_level", -1)),
        "skill_difficulty": int(chosen.get("skill_difficulty", 1)),
        "original_severity": wound.severity,
        "original_stabilized": wound.stabilized,
        "original_treated": wound.treated,
    })

func treatment_outcome(action_serial: int) -> Dictionary:
    return (_outcomes.get(action_serial, {}) as Dictionary).duplicate(true)

func _on_action_finished(action: TimedAction) -> void:
    if action == null or action.action_type != ACTION_TYPE:
        return
    if action.status != TickRules.ActionStatus.COMPLETED:
        _record_outcome(action.serial, {"committed": false, "reason": action.reason})
        return
    _complete_treatment(action)

func _complete_treatment(action: TimedAction) -> void:
    var injury_id: String = String(action.payload.get("injury_id", ""))
    var wound: ActorInjuryRecord = _health.injury(action.actor_id, injury_id)
    if wound == null or wound.severity != int(action.payload.get("original_severity", -1)) \
        or wound.stabilized != bool(action.payload.get("original_stabilized", false)) \
        or wound.treated != bool(action.payload.get("original_treated", false)):
        _record_outcome(action.serial, {"committed": false, "reason": "injury_changed"})
        return

    var item_values: Array = action.payload.get("resource_item_ids", [])
    var semantic_values: Array = action.payload.get("resource_semantics", [])
    if item_values.is_empty() or item_values.size() != semantic_values.size():
        _record_outcome(action.serial, {"committed": false, "reason": "treatment_resources_invalid"})
        return
    var captures: Array[Dictionary] = []
    for index in range(item_values.size()):
        var captured: Dictionary = _capture_carried_item(
            action.actor_id,
            String(item_values[index]),
            StringName(String(semantic_values[index]))
        )
        if captured.is_empty():
            _record_outcome(action.serial, {"committed": false, "reason": "treatment_resource_changed"})
            return
        captures.append(captured)

    var difficulty: int = int(action.payload.get("skill_difficulty", 1))
    var skill: Dictionary = _skill_checks.resolve_attempt(
        action.actor_id,
        SkillCatalog.SURVIVAL,
        difficulty,
        action.serial,
        &"health.first_aid",
        int(action.payload.get("skill_level", -1))
    )
    if not bool(skill.get("ok", false)):
        _record_outcome(action.serial, {"committed": false, "reason": "skill_check_unavailable"})
        return
    if not _consume_items(captures):
        _record_outcome(action.serial, {"committed": false, "reason": "treatment_resource_commit_failed"})
        return

    var skill_success: bool = bool(skill.get("success", false))
    var next_severity: int = wound.severity
    if skill_success and String(action.payload.get("mode", "")) == "kit":
        next_severity = maxi(Injury.Severity.MINOR, wound.severity - 1)
    var next_treated: bool = wound.treated or skill_success
    if not _health.set_injury_state(action.actor_id, injury_id, next_severity, true, next_treated):
        _restore_items(captures)
        _record_outcome(action.serial, {"committed": false, "reason": "injury_commit_failed"})
        return
    if not _skill_checks.award_attempt_xp(action.actor_id, SkillCatalog.SURVIVAL, difficulty, skill_success):
        _health.set_injury_state(action.actor_id, injury_id, wound.severity, wound.stabilized, wound.treated)
        _restore_items(captures)
        _record_outcome(action.serial, {"committed": false, "reason": "skill_xp_commit_failed"})
        return
    _record_outcome(action.serial, {
        "committed": true,
        "reason": "",
        "skill_success": skill_success,
        "injury_id": injury_id,
        "stabilized": true,
        "treated": next_treated,
        "severity": next_severity,
        "consumed_item_ids": item_values.duplicate(),
    })

func _capture_carried_item(actor_id: String, item_id: String, semantic: StringName) -> Dictionary:
    if not _item_carried_by(actor_id, item_id):
        return {}
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null or entity.semantic_type != semantic:
        return {}
    var assignment: Dictionary = _hands.assignment_for_item(item_id)
    if not assignment.is_empty():
        return {
            "item_id": item_id,
            "semantic_type": semantic,
            "kind": "hand",
            "actor_id": actor_id,
            "slot": int(assignment.get("slot", -1)),
        }
    if _inventory.is_contained(item_id):
        return {
            "item_id": item_id,
            "semantic_type": semantic,
            "kind": "container",
            "container_id": _inventory.container_of(item_id),
        }
    return {}

func _consume_items(captures: Array[Dictionary]) -> bool:
    var removed: Array[Dictionary] = []
    for entry: Dictionary in captures:
        var item_id: String = String(entry.get("item_id", ""))
        if not _detach(entry) or not _world_mutations.remove_entity(item_id):
            if _world.has_entity(item_id):
                _restore_disposition(entry)
            _restore_items(removed)
            return false
        removed.append(entry)
    return true

func _detach(entry: Dictionary) -> bool:
    if String(entry.get("kind", "")) == "hand":
        return _hand_mutations.clear_slot(String(entry.get("actor_id", "")), int(entry.get("slot", -1)))
    return _inventory_mutations.clear_container(String(entry.get("item_id", "")))

func _restore_items(captures: Array[Dictionary]) -> bool:
    var restored: bool = true
    for entry: Dictionary in captures:
        var item_id: String = String(entry.get("item_id", ""))
        if not _world.has_entity(item_id):
            restored = (_world_mutations.create_entity(StringName(entry.get("semantic_type", &"")), item_id) == item_id) and restored
        restored = _restore_disposition(entry) and restored
    return restored

func _restore_disposition(entry: Dictionary) -> bool:
    var item_id: String = String(entry.get("item_id", ""))
    if String(entry.get("kind", "")) == "hand":
        return _hand_mutations.set_item(String(entry.get("actor_id", "")), int(entry.get("slot", -1)), item_id)
    return _inventory_mutations.set_container(item_id, String(entry.get("container_id", "")))

func _partner_for(actor_id: String, selected_semantic: StringName, selected_item_id: String) -> Dictionary:
    var wanted: Array[StringName] = [&"item.material.rag_bundle"]
    if selected_semantic == &"item.material.rag_bundle":
        wanted = [&"item.medical.disinfectant", &"item.medical.alcohol_wipes"]
    var carry: Dictionary = _carry_query.query(actor_id)
    var ids: Array[String] = []
    for value: Variant in carry.get("item_ids", []):
        ids.append(String(value))
    ids.sort()
    for item_id: String in ids:
        if item_id == selected_item_id or not _world.has_entity(item_id):
            continue
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity != null and entity.semantic_type in wanted:
            return {"item_id": item_id, "semantic_type": entity.semantic_type}
    return {}

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

func _profile(semantic: StringName) -> Dictionary:
    if semantic in [&"item.medical.bandage_roll", &"item.medical.gauze_pack", &"item.medical.medical_tape"]:
        return {"mode": "dress", "verb": "BANDAGE", "base_duration_ticks": 24, "difficulty_add": 0}
    if semantic == &"item.medical.first_aid_kit":
        return {"mode": "kit", "verb": "TREAT", "base_duration_ticks": 36, "difficulty_add": 0}
    if semantic in [&"item.material.rag_bundle", &"item.medical.disinfectant", &"item.medical.alcohol_wipes"]:
        return {"mode": "improvised", "verb": "IMPROVISE BANDAGE", "base_duration_ticks": 32, "difficulty_add": 1, "requires_partner": true}
    return {}

func _record_outcome(serial: int, value: Dictionary) -> void:
    _outcomes[serial] = value.duplicate(true)
    _outcome_order.append(serial)
    while _outcome_order.size() > OUTCOME_LIMIT:
        _outcomes.erase(_outcome_order.pop_front())

static func _severity_label(value: int) -> String:
    match value:
        Injury.Severity.MINOR: return "Minor"
        Injury.Severity.SERIOUS: return "Serious"
        Injury.Severity.CRITICAL: return "Critical"
    return "Unknown"

static func _humanize(value: String) -> String:
    return value.strip_edges().replace("_", " ").replace(".", " ").capitalize()
