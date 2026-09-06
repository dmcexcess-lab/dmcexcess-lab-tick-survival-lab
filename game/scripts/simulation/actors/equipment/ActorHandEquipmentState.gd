extends RefCounted
class_name ActorHandEquipmentState

const RecordClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentRecord.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

## Authoritative persistent hand, back and worn-equipment assignments.
## Normal writes go through ActorHandEquipmentMutationService.

signal actor_enrolled(actor_id, version)
signal actor_removed(actor_id, primary_item_id, secondary_item_id, version)
signal hand_assignment_changed(actor_id, slot, previous_item_id, new_item_id, version)
signal equipment_assignment_changed(actor_id, slot, previous_item_id, new_item_id, version)
signal hand_equipment_reset

const SNAPSHOT_SCHEMA_VERSION: int = 2

var _records: Dictionary = {}
var _assignments: Dictionary = {}
var _revision: int = 0

func revision() -> int: return _revision
func has_actor(actor_id: String) -> bool: return _records.has(actor_id)

func actor_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _records.keys(): result.append(String(key))
    result.sort()
    return result

func record(actor_id: String) -> ActorHandEquipmentRecord:
    if not _records.has(actor_id): return null
    var value: ActorHandEquipmentRecord = _records[actor_id]
    return value.copy()

func version(actor_id: String) -> int:
    if not _records.has(actor_id): return 0
    var value: ActorHandEquipmentRecord = _records[actor_id]
    return value.version

func item_in_slot(actor_id: String, slot: int) -> String:
    if not _records.has(actor_id) or not Slots.is_valid(slot): return ""
    var value: ActorHandEquipmentRecord = _records[actor_id]
    return value.item_in_slot(slot)

func primary_item(actor_id: String) -> String: return item_in_slot(actor_id, Slots.Value.PRIMARY_RIGHT)
func secondary_item(actor_id: String) -> String: return item_in_slot(actor_id, Slots.Value.SECONDARY_LEFT)
func back_item(actor_id: String) -> String: return item_in_slot(actor_id, Slots.Value.BACK)

func equipped_items(actor_id: String) -> Array[String]:
    var result: Array[String] = []
    for slot: int in Slots.ALL:
        var item_id := item_in_slot(actor_id, slot)
        if not item_id.is_empty(): result.append(item_id)
    return result

func assignment_for_item(item_id: String) -> Dictionary:
    if not _assignments.has(item_id): return {}
    var assignment: Dictionary = _assignments[item_id]
    return assignment.duplicate(true)

func snapshot() -> Dictionary:
    var entries: Array = []
    for actor_id: String in actor_ids():
        var value: ActorHandEquipmentRecord = _records[actor_id]
        entries.append(value.to_snapshot())
    return {"schema_version": SNAPSHOT_SCHEMA_VERSION, "revision": _revision, "records": entries}

func load_snapshot(data: Dictionary) -> bool:
    var schema := int(data.get("schema_version", -1))
    if schema != 1 and schema != SNAPSHOT_SCHEMA_VERSION: return false
    var restored_revision := int(data.get("revision", -1))
    if restored_revision < 0: return false
    var records_value: Variant = data.get("records", [])
    if typeof(records_value) != TYPE_ARRAY: return false
    var restored_records: Dictionary = {}
    var restored_assignments: Dictionary = {}
    for value: Variant in records_value:
        if typeof(value) != TYPE_DICTIONARY: return false
        var restored_record: ActorHandEquipmentRecord = RecordClass.from_snapshot(value)
        if restored_record == null or restored_records.has(restored_record.actor_id) or restored_record.version > restored_revision: return false
        for slot: int in Slots.ALL:
            if not _add_snapshot_assignment(restored_assignments, restored_record.actor_id, slot, restored_record.item_in_slot(slot)): return false
        restored_records[restored_record.actor_id] = restored_record
    if not restored_records.is_empty() and restored_revision < 1: return false
    _records = restored_records
    _assignments = restored_assignments
    _revision = restored_revision
    hand_equipment_reset.emit()
    return true

func _insert_record(value: ActorHandEquipmentRecord) -> bool:
    if value == null or not value.is_valid() or _records.has(value.actor_id): return false
    for slot: int in Slots.ALL:
        if not _assignment_is_free(value.item_in_slot(slot)): return false
    var stored := value.copy()
    _records[stored.actor_id] = stored
    for slot: int in Slots.ALL: _index_assignment(stored.actor_id, slot, stored.item_in_slot(slot))
    _revision += 1
    actor_enrolled.emit(stored.actor_id, stored.version)
    return true

func _remove_record(actor_id: String) -> ActorHandEquipmentRecord:
    if not _records.has(actor_id): return null
    var previous: ActorHandEquipmentRecord = _records[actor_id]
    for slot: int in Slots.ALL: _erase_assignment(previous.item_in_slot(slot))
    _records.erase(actor_id)
    _revision += 1
    actor_removed.emit(previous.actor_id, previous.primary_item_id, previous.secondary_item_id, previous.version)
    return previous.copy()

func _set_item_record(actor_id: String, slot: int, item_id: String) -> bool:
    if not _records.has(actor_id) or not Slots.is_valid(slot): return false
    var previous: ActorHandEquipmentRecord = _records[actor_id]
    var previous_item_id := previous.item_in_slot(slot)
    if previous_item_id == item_id: return true
    if not item_id.is_empty() and _assignments.has(item_id): return false
    var updated := previous.with_item(slot, item_id)
    if updated == null or not updated.is_valid(): return false
    _erase_assignment(previous_item_id)
    _records[actor_id] = updated
    _index_assignment(actor_id, slot, item_id)
    _revision += 1
    hand_assignment_changed.emit(actor_id, slot, previous_item_id, item_id, updated.version)
    equipment_assignment_changed.emit(actor_id, slot, previous_item_id, item_id, updated.version)
    return true

func _assignment_is_free(item_id: String) -> bool: return item_id.is_empty() or not _assignments.has(item_id)
func _index_assignment(actor_id: String, slot: int, item_id: String) -> void:
    if not item_id.is_empty(): _assignments[item_id] = {"actor_id": actor_id, "slot": slot}
func _erase_assignment(item_id: String) -> void:
    if not item_id.is_empty(): _assignments.erase(item_id)

static func _add_snapshot_assignment(assignments: Dictionary, actor_id: String, slot: int, item_id: String) -> bool:
    if item_id.is_empty(): return true
    if assignments.has(item_id): return false
    assignments[item_id] = {"actor_id": actor_id, "slot": slot}
    return true
