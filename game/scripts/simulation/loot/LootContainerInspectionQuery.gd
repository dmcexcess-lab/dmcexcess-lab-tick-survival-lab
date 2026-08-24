extends RefCounted
class_name LootContainerInspectionQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

var _world: WorldState = null
var _containment: InventoryContainmentState = null
var _loot_state: LootState = null
var _items: LootItemCatalog = null
var _profiles: LootContainerProfileCatalog = null
var _weight_query: ItemWeightQuery = null
var _carry_query: ActorCarryQuery = null

func _init(
    world_state: WorldState = null,
    containment_state: InventoryContainmentState = null,
    loot_state: LootState = null,
    item_catalog: LootItemCatalog = null,
    profile_catalog: LootContainerProfileCatalog = null,
    weight_query: ItemWeightQuery = null,
    carry_query: ActorCarryQuery = null
) -> void:
    _world = world_state
    _containment = containment_state
    _loot_state = loot_state
    _items = item_catalog
    _profiles = profile_catalog
    _weight_query = weight_query
    _carry_query = carry_query

func is_ready() -> bool:
    return _world != null and _containment != null and _loot_state != null \
        and _items != null and _profiles != null and _weight_query != null and _carry_query != null

func item_definition(semantic_type: StringName) -> Dictionary:
    if not is_ready():
        return {}
    return _items.definition(semantic_type)

func searchable_container_ids_at(cell: Vector2i) -> Array[String]:
    var result: Array[String] = []
    if not is_ready():
        return result
    for entity_id: String in _world.entities_at(cell, Layers.Channel.OBJECT):
        if _loot_state.has_container(entity_id) and _containment.has_container(entity_id):
            result.append(entity_id)
    result.sort()
    return result

func query(actor_id: String, container_id: String) -> Dictionary:
    if not is_ready():
        return _failure("loot_inspection_not_ready")
    var actor: String = actor_id.strip_edges()
    var container: String = container_id.strip_edges()
    if actor.is_empty() or container.is_empty() or not _loot_state.has_container(container):
        return _failure("loot_container_unknown")
    if not _world.has_entity(container) or not _containment.has_container(container):
        return _failure("loot_container_missing")

    var record: Dictionary = _loot_state.container_record(container)
    var profile_id: StringName = StringName(record.get("loot_profile_id", &""))
    var profile: Dictionary = _profiles.profile(profile_id)
    if profile.is_empty():
        return _failure("loot_profile_unknown")
    var entity: WorldEntityRecord = _world.entity(container)
    if entity == null:
        return _failure("loot_container_missing")

    var entries: Array[Dictionary] = []
    for item_id: String in _containment.direct_contents(container):
        entries.append(_item_entry(item_id))

    return {
        "ok": true,
        "reason": "",
        "container_id": container,
        "container_semantic": entity.semantic_type,
        "container_label": _container_label(profile_id, entity.semantic_type),
        "loot_profile_id": profile_id,
        "loot_profile_version": int(record.get("loot_profile_version", 0)),
        "container_version": _containment.container_version(container),
        "search_ticks": int(profile.get("search_ticks", 0)),
        "items": entries,
        "carry": _carry_query.query(actor).duplicate(true),
    }

func _item_entry(item_id: String) -> Dictionary:
    var result: Dictionary = {
        "item_id": item_id,
        "semantic_type": &"",
        "label": "Unknown Item",
        "utility_class": &"",
        "family": &"",
        "tags": [],
        "weight_known": false,
        "weight_grams": 0,
        "valid": false,
    }
    if not _world.has_entity(item_id):
        return result
    var entity: WorldEntityRecord = _world.entity(item_id)
    if entity == null:
        return result
    var semantic: StringName = entity.semantic_type
    result["semantic_type"] = semantic
    var definition: Dictionary = _items.definition(semantic)
    if definition.is_empty():
        result["label"] = _fallback_label(String(semantic))
        return result
    result["label"] = String(definition.get("label", "Unknown Item"))
    result["utility_class"] = definition.get("utility_class", &"")
    result["family"] = definition.get("family", &"")
    result["tags"] = definition.get("tags", []).duplicate()
    var weight: Dictionary = _weight_query.query(item_id)
    if int(weight.get("status", -1)) == ItemWeightQuery.Status.KNOWN:
        result["weight_known"] = true
        result["weight_grams"] = int(weight.get("weight_grams", 0))
    result["valid"] = true
    return result

static func _container_label(profile_id: StringName, semantic_type: StringName) -> String:
    var profile_text: String = String(profile_id)
    var tail: String = profile_text.get_slice(".", profile_text.get_slice_count(".") - 1)
    if tail.is_empty():
        tail = String(semantic_type).trim_prefix("prop.")
    return tail.replace("_", " ").capitalize()

static func _fallback_label(semantic_type: String) -> String:
    var value: String = semantic_type.trim_prefix("item.").replace("_", " ").replace(".", " ")
    return "Unknown Item" if value.is_empty() else value.capitalize()

static func _failure(reason: String) -> Dictionary:
    return {
        "ok": false,
        "reason": reason,
        "container_id": "",
        "container_label": "",
        "items": [],
        "carry": {},
    }
