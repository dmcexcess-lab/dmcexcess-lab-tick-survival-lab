extends RefCounted
class_name InventoryContainmentState

const EntityIdRules = preload("res://scripts/foundation/world/WorldEntityId.gd")
const RecordClass = preload("res://scripts/simulation/inventory/InventoryContainerRecord.gd")

## Authoritative persistent direct-containment state.
## Normal writes go through InventoryContainmentMutationService.

signal container_enrolled(container_id, version)
signal container_removed(container_id, previous_version)
signal item_containment_changed(item_id, previous_container_id, new_container_id)
signal container_contents_changed(container_id, version)
signal containment_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1

var _records: Dictionary = {}
var _parent_by_item: Dictionary = {}
var _contents_by_container: Dictionary = {}
var _revision: int = 0

func revision() -> int:
    return _revision

func has_container(container_id: String) -> bool:
    return _records.has(container_id)

func container_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys():
        result.append(String(key))
    result.sort()
    return result

func container(container_id: String) -> InventoryContainerRecord:
    if not _records.has(container_id):
        return null
    var value: InventoryContainerRecord = _records[container_id]
    return value.copy()

func container_version(container_id: String) -> int:
    if not _records.has(container_id):
        return 0
    var value: InventoryContainerRecord = _records[container_id]
    return value.version

func is_contained(item_id: String) -> bool:
    return _parent_by_item.has(item_id)

func container_of(item_id: String) -> String:
    if not _parent_by_item.has(item_id):
        return ""
    return String(_parent_by_item[item_id])

func direct_contents(container_id: String) -> Array[String]:
    var result: Array[String] = []
    if not _contents_by_container.has(container_id):
        return result
    var children: Dictionary = _contents_by_container[container_id]
    for key: Variant in children.keys():
        result.append(String(key))
    result.sort()
    return result

func contains_directly(container_id: String, item_id: String) -> bool:
    return container_of(item_id) == container_id and not container_id.is_empty()

func snapshot() -> Dictionary:
    var containers: Array = []
    for container_id: String in container_ids():
        var value: InventoryContainerRecord = _records[container_id]
        containers.append(value.to_snapshot())

    var relations: Array = []
    var item_ids: Array[String] = []
    for key: Variant in _parent_by_item.keys():
        item_ids.append(String(key))
    item_ids.sort()
    for item_id: String in item_ids:
        relations.append({
            "item_id": item_id,
            "container_id": String(_parent_by_item[item_id]),
        })

    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "revision": _revision,
        "containers": containers,
        "relations": relations,
    }

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var restored_revision: int = int(data.get("revision", -1))
    if restored_revision < 0:
        return false

    var containers_value: Variant = data.get("containers", [])
    var relations_value: Variant = data.get("relations", [])
    if typeof(containers_value) != TYPE_ARRAY or typeof(relations_value) != TYPE_ARRAY:
        return false

    var restored_records: Dictionary = {}
    for value: Variant in containers_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var restored_record: InventoryContainerRecord = RecordClass.from_snapshot(value)
        if restored_record == null or restored_records.has(restored_record.container_id):
            return false
        if restored_record.version > restored_revision:
            return false
        restored_records[restored_record.container_id] = restored_record

    if not restored_records.is_empty() and restored_revision < 1:
        return false

    var restored_parents: Dictionary = {}
    for value: Variant in relations_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var relation: Dictionary = value
        var item_id: String = String(relation.get("item_id", ""))
        var container_id: String = String(relation.get("container_id", ""))
        if not EntityIdRules.is_valid(item_id) or not EntityIdRules.is_valid(container_id):
            return false
        if item_id == container_id or restored_parents.has(item_id):
            return false
        if not restored_records.has(container_id):
            return false
        restored_parents[item_id] = container_id

    if not _relations_are_acyclic(restored_parents):
        return false

    var restored_contents: Dictionary = _build_contents_index(restored_records, restored_parents)
    _records = restored_records
    _parent_by_item = restored_parents
    _contents_by_container = restored_contents
    _revision = restored_revision
    containment_reset.emit()
    return true

# --- Inventory-containment-internal mutation surface. External systems use the mutation service. ---

func _insert_container(value: InventoryContainerRecord) -> bool:
    if value == null or not value.is_valid() or _records.has(value.container_id):
        return false
    var stored: InventoryContainerRecord = value.copy()
    _records[stored.container_id] = stored
    _contents_by_container[stored.container_id] = {}
    _revision += 1
    container_enrolled.emit(stored.container_id, stored.version)
    return true

func _remove_container(container_id: String) -> InventoryContainerRecord:
    if not _records.has(container_id):
        return null
    if not direct_contents(container_id).is_empty():
        return null
    var previous: InventoryContainerRecord = _records[container_id]
    _records.erase(container_id)
    _contents_by_container.erase(container_id)
    _revision += 1
    container_removed.emit(container_id, previous.version)
    return previous.copy()

func _set_container_relation(item_id: String, new_container_id: String) -> bool:
    if not EntityIdRules.is_valid(item_id):
        return false
    if not new_container_id.is_empty():
        if not EntityIdRules.is_valid(new_container_id) or not _records.has(new_container_id):
            return false
        if item_id == new_container_id or _would_create_cycle(item_id, new_container_id):
            return false

    var previous_container_id: String = container_of(item_id)
    if previous_container_id == new_container_id:
        return true
    if previous_container_id.is_empty() and new_container_id.is_empty():
        return false

    if not previous_container_id.is_empty():
        _erase_child(previous_container_id, item_id)
    if new_container_id.is_empty():
        _parent_by_item.erase(item_id)
    else:
        _parent_by_item[item_id] = new_container_id
        _index_child(new_container_id, item_id)

    _revision += 1
    var previous_version: int = 0
    var new_version: int = 0
    if not previous_container_id.is_empty():
        previous_version = _increment_container_version(previous_container_id)
    if not new_container_id.is_empty():
        new_version = _increment_container_version(new_container_id)

    item_containment_changed.emit(item_id, previous_container_id, new_container_id)
    if not previous_container_id.is_empty():
        container_contents_changed.emit(previous_container_id, previous_version)
    if not new_container_id.is_empty():
        container_contents_changed.emit(new_container_id, new_version)
    return true

func _would_create_cycle(item_id: String, proposed_container_id: String) -> bool:
    if item_id == proposed_container_id:
        return true
    var current: String = proposed_container_id
    var visited: Dictionary = {}
    while not current.is_empty():
        if current == item_id:
            return true
        if visited.has(current):
            return true
        visited[current] = true
        if not _parent_by_item.has(current):
            return false
        current = String(_parent_by_item[current])
    return false

func _increment_container_version(container_id: String) -> int:
    if not _records.has(container_id):
        return 0
    var previous: InventoryContainerRecord = _records[container_id]
    var updated := RecordClass.new(container_id, previous.version + 1)
    _records[container_id] = updated
    return updated.version

func _index_child(container_id: String, item_id: String) -> void:
    if not _contents_by_container.has(container_id):
        _contents_by_container[container_id] = {}
    var children: Dictionary = _contents_by_container[container_id]
    children[item_id] = true
    _contents_by_container[container_id] = children

func _erase_child(container_id: String, item_id: String) -> void:
    if not _contents_by_container.has(container_id):
        return
    var children: Dictionary = _contents_by_container[container_id]
    children.erase(item_id)
    _contents_by_container[container_id] = children

static func _build_contents_index(records: Dictionary, parents: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for key: Variant in records.keys():
        result[String(key)] = {}
    for item_key: Variant in parents.keys():
        var item_id: String = String(item_key)
        var container_id: String = String(parents[item_key])
        var children: Dictionary = result[container_id]
        children[item_id] = true
        result[container_id] = children
    return result

static func _relations_are_acyclic(parents: Dictionary) -> bool:
    for start_key: Variant in parents.keys():
        var current: String = String(start_key)
        var visited: Dictionary = {}
        while parents.has(current):
            if visited.has(current):
                return false
            visited[current] = true
            current = String(parents[current])
    return true
