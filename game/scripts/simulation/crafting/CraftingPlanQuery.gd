extends RefCounted
class_name CraftingPlanQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

## System 32 bounded read/query owner. It selects exact personally possessed item IDs
## deterministically and never scans WHAT globally or auto-pulls from nearby storage.
## Optional workstation availability is supplied by the owning runtime (for example,
## System 33 power truth for an electric stove) and is rechecked by validate_exact().

enum Status { READY, BLOCKED, UNKNOWN }

var _world: WorldState = null
var _hands: ActorHandEquipmentState = null
var _containment: InventoryContainmentState = null
var _carry: ActorCarryQuery = null
var _physical: ItemPhysicalPropertyCatalog = null
var _recipes: CraftingRecipeCatalog = null
var _crafted_items: CraftingItemCatalog = null
var _workstations: CraftingWorkstationCatalog = null
var _freshness: ItemFreshnessProfileCatalog = null
var _reach: WorldInteractionReachQuery = null
var _workstation_availability_provider: Callable = Callable()

func _init(
    world_state: WorldState = null,
    hand_state: ActorHandEquipmentState = null,
    containment_state: InventoryContainmentState = null,
    carry_query: ActorCarryQuery = null,
    physical_catalog: ItemPhysicalPropertyCatalog = null,
    recipe_catalog: CraftingRecipeCatalog = null,
    crafted_item_catalog: CraftingItemCatalog = null,
    workstation_catalog: CraftingWorkstationCatalog = null,
    freshness_catalog: ItemFreshnessProfileCatalog = null,
    reach_query: WorldInteractionReachQuery = null
) -> void:
    _world = world_state
    _hands = hand_state
    _containment = containment_state
    _carry = carry_query
    _physical = physical_catalog
    _recipes = recipe_catalog
    _crafted_items = crafted_item_catalog
    _workstations = workstation_catalog
    _freshness = freshness_catalog
    _reach = reach_query

func set_workstation_availability_provider(provider: Callable) -> bool:
    if not provider.is_valid(): return false
    _workstation_availability_provider = provider
    return true

func is_ready() -> bool:
    return _world != null and _hands != null and _containment != null and _carry != null \
        and _physical != null and _recipes != null and _crafted_items != null and _workstations != null \
        and _freshness != null and _reach != null and _reach.is_ready()

func recipe_ids() -> Array[StringName]:
    return [] if _recipes == null else _recipes.recipe_ids()

func recipe(recipe_id: StringName) -> CraftingRecipe:
    return null if _recipes == null else _recipes.recipe(recipe_id)

func query(actor_id: String, recipe_id: StringName, workstation_id: String = "") -> Dictionary:
    if not is_ready(): return _result(Status.UNKNOWN, actor_id, recipe_id, "crafting_plan_not_ready")
    var actor: String = actor_id.strip_edges()
    var recipe_value: CraftingRecipe = _recipes.recipe(recipe_id)
    if recipe_value == null: return _result(Status.UNKNOWN, actor, recipe_id, "recipe_unknown")
    var common: Dictionary = _validate_common(actor, recipe_value, workstation_id)
    if int(common.get("status", Status.UNKNOWN)) != Status.READY: return common

    var carry_result: Dictionary = common.get("carry", {})
    var by_semantic: Dictionary = _semantic_index(carry_result.get("item_ids", []))
    var used: Dictionary = {}
    var selected_inputs: Dictionary = _select_requirements(recipe_value.consumed_inputs, by_semantic, used, true)
    if not bool(selected_inputs.get("ok", false)):
        return _result(Status.BLOCKED, actor, recipe_id, String(selected_inputs.get("reason", "missing_input")))
    var consumed_ids: Array = selected_inputs.get("item_ids", [])
    for item_id: Variant in consumed_ids: used[String(item_id)] = true
    var selected_tools: Dictionary = _select_requirements(recipe_value.required_tools, by_semantic, used, false)
    if not bool(selected_tools.get("ok", false)):
        return _result(Status.BLOCKED, actor, recipe_id, String(selected_tools.get("reason", "missing_tool")))
    return _finalize_ready(actor, recipe_value, workstation_id.strip_edges(), consumed_ids, selected_tools.get("item_ids", []), carry_result)

func validate_exact(
    actor_id: String,
    recipe_id: StringName,
    expected_catalog_version: int,
    consumed_item_ids: Array,
    tool_item_ids: Array,
    workstation_id: String = ""
) -> Dictionary:
    if not is_ready(): return _result(Status.UNKNOWN, actor_id, recipe_id, "crafting_plan_not_ready")
    var actor: String = actor_id.strip_edges()
    if expected_catalog_version != _recipes.catalog_version(): return _result(Status.BLOCKED, actor, recipe_id, "recipe_catalog_version_stale")
    var recipe_value: CraftingRecipe = _recipes.recipe(recipe_id)
    if recipe_value == null: return _result(Status.UNKNOWN, actor, recipe_id, "recipe_unknown")
    var common: Dictionary = _validate_common(actor, recipe_value, workstation_id)
    if int(common.get("status", Status.UNKNOWN)) != Status.READY: return common
    var carry_result: Dictionary = common.get("carry", {})
    var personal_set: Dictionary = {}
    for item_value: Variant in carry_result.get("item_ids", []): personal_set[String(item_value)] = true

    var consumed_ids: Array = _normalized_unique_ids(consumed_item_ids)
    var tool_ids: Array = _normalized_unique_ids(tool_item_ids)
    if consumed_ids.size() != consumed_item_ids.size() or tool_ids.size() != tool_item_ids.size():
        return _result(Status.BLOCKED, actor, recipe_id, "duplicate_or_invalid_item_id")
    if consumed_ids.size() != recipe_value.consumed_entity_count(): return _result(Status.BLOCKED, actor, recipe_id, "consumed_item_count_stale")
    if tool_ids.size() != recipe_value.tool_entity_count(): return _result(Status.BLOCKED, actor, recipe_id, "tool_item_count_stale")

    var consumed_set: Dictionary = {}
    for item_value: Variant in consumed_ids:
        var item_id: String = String(item_value)
        if not personal_set.has(item_id): return _result(Status.BLOCKED, actor, recipe_id, "input_no_longer_personal:%s" % item_id)
        if _containment.has_container(item_id): return _result(Status.BLOCKED, actor, recipe_id, "container_item_cannot_be_consumed:%s" % item_id)
        consumed_set[item_id] = true
    for item_value: Variant in tool_ids:
        var item_id: String = String(item_value)
        if consumed_set.has(item_id): return _result(Status.BLOCKED, actor, recipe_id, "tool_overlaps_consumed_input")
        if not personal_set.has(item_id): return _result(Status.BLOCKED, actor, recipe_id, "tool_no_longer_personal:%s" % item_id)
    if not _ids_match_requirements(consumed_ids, recipe_value.consumed_inputs): return _result(Status.BLOCKED, actor, recipe_id, "consumed_item_semantics_stale")
    if not _ids_match_requirements(tool_ids, recipe_value.required_tools): return _result(Status.BLOCKED, actor, recipe_id, "tool_item_semantics_stale")
    return _finalize_ready(actor, recipe_value, workstation_id.strip_edges(), consumed_ids, tool_ids, carry_result)

func _validate_common(actor: String, recipe_value: CraftingRecipe, workstation_id: String) -> Dictionary:
    if actor.is_empty() or not _world.has_entity(actor): return _result(Status.BLOCKED, actor, recipe_value.recipe_id, "actor_missing")
    var actor_entity: WorldEntityRecord = _world.entity(actor)
    if actor_entity == null or String(actor_entity.semantic_type) != "actor.survivor": return _result(Status.BLOCKED, actor, recipe_value.recipe_id, "not_survivor")
    if not _hands.has_actor(actor) or not _containment.has_container(actor): return _result(Status.UNKNOWN, actor, recipe_value.recipe_id, "personal_possession_unclassified")
    if not _recipe_semantics_safe(recipe_value): return _result(Status.UNKNOWN, actor, recipe_value.recipe_id, "recipe_semantic_contract_invalid")
    var workstation_reason: String = _workstation_reason(actor, recipe_value, workstation_id.strip_edges())
    if not workstation_reason.is_empty(): return _result(Status.BLOCKED, actor, recipe_value.recipe_id, workstation_reason)
    var carry_result: Dictionary = _carry.query(actor)
    if int(carry_result.get("status", ActorCarryQuery.Status.UNKNOWN)) != ActorCarryQuery.Status.KNOWN:
        return _result(Status.UNKNOWN, actor, recipe_value.recipe_id, String(carry_result.get("reason", "carry_unknown")))
    var ready: Dictionary = _result(Status.READY, actor, recipe_value.recipe_id, "")
    ready["carry"] = carry_result.duplicate(true)
    return ready

func _recipe_semantics_safe(recipe_value: CraftingRecipe) -> bool:
    if recipe_value == null or not recipe_value.is_valid(): return false
    for requirement: Dictionary in recipe_value.consumed_inputs:
        var semantic := StringName(requirement.get("semantic_type", &""))
        if _freshness.has_profile(semantic) or not _physical.has_profile(semantic): return false
    for requirement: Dictionary in recipe_value.required_tools:
        var semantic := StringName(requirement.get("semantic_type", &""))
        if _freshness.has_profile(semantic) or not _physical.has_profile(semantic): return false
    for requirement: Dictionary in recipe_value.outputs:
        var semantic := StringName(requirement.get("semantic_type", &""))
        if _freshness.has_profile(semantic) or not _crafted_items.has_item(semantic) or not _physical.has_profile(semantic): return false
    return true

func _workstation_reason(actor: String, recipe_value: CraftingRecipe, workstation_id: String) -> String:
    if String(recipe_value.workstation_capability).is_empty(): return ""
    if workstation_id.is_empty() or not _world.has_entity(workstation_id): return "workstation_required"
    var entity: WorldEntityRecord = _world.entity(workstation_id)
    var placement: WorldPlacement = _world.placement(workstation_id)
    if entity == null or placement == null or placement.channel != Layers.Channel.OBJECT: return "workstation_unavailable"
    if not _workstations.supports(entity.semantic_type, recipe_value.workstation_capability): return "workstation_capability_mismatch"
    if not _reach.target_reachable(actor, workstation_id, WorldInteractionReachQuery.CONTACT_FORWARD): return "workstation_out_of_reach"
    if _workstation_availability_provider.is_valid():
        var availability: Variant = _workstation_availability_provider.call(actor, workstation_id, recipe_value.workstation_capability)
        if typeof(availability) != TYPE_BOOL: return "workstation_availability_unknown"
        if not bool(availability): return "workstation_unavailable_now"
    elif recipe_value.workstation_capability == CraftingWorkstationCatalog.COOKING_STOVE:
        return "workstation_power_unclassified"
    return ""

func _semantic_index(personal_ids: Array) -> Dictionary:
    var result: Dictionary = {}
    for item_value: Variant in personal_ids:
        var item_id: String = String(item_value).strip_edges()
        if item_id.is_empty() or not _world.has_entity(item_id): continue
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity == null or not String(entity.semantic_type).begins_with("item."): continue
        var key: String = String(entity.semantic_type)
        if not result.has(key): result[key] = []
        var values: Array = result[key]
        values.append(item_id)
        values.sort()
        result[key] = values
    return result

func _select_requirements(requirements: Array[Dictionary], by_semantic: Dictionary, used: Dictionary, reject_containers: bool) -> Dictionary:
    var selected: Array = []
    for requirement: Dictionary in requirements:
        var semantic: String = String(requirement.get("semantic_type", ""))
        var needed: int = int(requirement.get("count", 0))
        var candidates: Array = by_semantic.get(semantic, [])
        var chosen: int = 0
        for item_value: Variant in candidates:
            var item_id: String = String(item_value)
            if used.has(item_id): continue
            if reject_containers and _containment.has_container(item_id): continue
            selected.append(item_id)
            chosen += 1
            if chosen >= needed: break
        if chosen < needed:
            var kind: String = "input" if reject_containers else "tool"
            return {"ok": false, "item_ids": [], "reason": "missing_%s:%s" % [kind, semantic]}
    selected.sort()
    return {"ok": true, "item_ids": selected, "reason": ""}

func _ids_match_requirements(item_ids: Array, requirements: Array[Dictionary]) -> bool:
    var expected: Dictionary = {}
    for requirement: Dictionary in requirements: expected[String(requirement.get("semantic_type", ""))] = int(requirement.get("count", 0))
    var actual: Dictionary = {}
    for item_value: Variant in item_ids:
        var item_id: String = String(item_value)
        if not _world.has_entity(item_id): return false
        var entity: WorldEntityRecord = _world.entity(item_id)
        if entity == null: return false
        var semantic: String = String(entity.semantic_type)
        actual[semantic] = int(actual.get(semantic, 0)) + 1
    return actual == expected

func _finalize_ready(actor: String, recipe_value: CraftingRecipe, workstation_id: String, consumed_ids: Array, tool_ids: Array, carry_result: Dictionary) -> Dictionary:
    var consumed_weight: int = 0
    for item_value: Variant in consumed_ids:
        var item_id: String = String(item_value)
        if not _world.has_entity(item_id): return _result(Status.BLOCKED, actor, recipe_value.recipe_id, "input_missing:%s" % item_id)
        var entity: WorldEntityRecord = _world.entity(item_id)
        var weight: int = -1 if entity == null else _physical.weight_grams(entity.semantic_type)
        if weight <= 0: return _result(Status.UNKNOWN, actor, recipe_value.recipe_id, "input_weight_unknown:%s" % item_id)
        consumed_weight += weight
    var output_semantics: Array = []
    var output_weight: int = 0
    for requirement: Dictionary in recipe_value.outputs:
        var semantic := StringName(requirement.get("semantic_type", &""))
        var count: int = int(requirement.get("count", 0))
        var weight: int = _physical.weight_grams(semantic)
        if weight <= 0: return _result(Status.UNKNOWN, actor, recipe_value.recipe_id, "output_weight_unknown:%s" % String(semantic))
        for _index in range(count): output_semantics.append(semantic); output_weight += weight
    if output_weight > consumed_weight: return _result(Status.UNKNOWN, actor, recipe_value.recipe_id, "recipe_creates_mass")
    var current_weight: int = int(carry_result.get("weight_grams", -1))
    var hard_limit: int = int(carry_result.get("hard_limit_grams", -1))
    if current_weight < 0 or hard_limit <= 0: return _result(Status.UNKNOWN, actor, recipe_value.recipe_id, "carry_projection_unknown")
    var projected: int = current_weight - consumed_weight + output_weight
    if projected > hard_limit: return _result(Status.BLOCKED, actor, recipe_value.recipe_id, "absolute_carry_limit_exceeded")
    var result: Dictionary = _result(Status.READY, actor, recipe_value.recipe_id, "")
    result["recipe_label"] = recipe_value.label
    result["recipe_catalog_version"] = _recipes.catalog_version()
    result["duration_ticks"] = recipe_value.duration_ticks
    result["consumed_item_ids"] = consumed_ids.duplicate()
    result["tool_item_ids"] = tool_ids.duplicate()
    result["workstation_id"] = workstation_id
    result["workstation_capability"] = recipe_value.workstation_capability
    result["output_semantics"] = output_semantics.duplicate()
    result["consumed_weight_grams"] = consumed_weight
    result["output_weight_grams"] = output_weight
    result["current_carry_grams"] = current_weight
    result["projected_carry_grams"] = projected
    result["hard_limit_grams"] = hard_limit
    return result

func _normalized_unique_ids(values: Array) -> Array:
    var result: Array = []
    var seen: Dictionary = {}
    for value: Variant in values:
        var item_id: String = String(value).strip_edges()
        if item_id.is_empty() or seen.has(item_id): continue
        seen[item_id] = true
        result.append(item_id)
    result.sort()
    return result

static func _result(status_value: int, actor_id: String, recipe_id: StringName, reason: String) -> Dictionary:
    return {
        "status": status_value, "ready": status_value == Status.READY, "actor_id": actor_id.strip_edges(), "recipe_id": recipe_id,
        "reason": reason, "recipe_label": "", "recipe_catalog_version": -1, "duration_ticks": 0,
        "consumed_item_ids": [], "tool_item_ids": [], "workstation_id": "", "workstation_capability": &"", "output_semantics": [],
        "consumed_weight_grams": 0, "output_weight_grams": 0, "current_carry_grams": 0, "projected_carry_grams": 0, "hard_limit_grams": 0,
    }
