extends RefCounted
class_name FirearmState

signal firearm_enrolled(firearm_id)
signal magazine_changed(firearm_id, previous_magazine_id, magazine_id)
signal chamber_changed(firearm_id, previous_round_id, round_id)

var _world: WorldState = null
var _inventory: InventoryContainmentState = null
var _inventory_mutations: InventoryContainmentMutationService = null
var _profiles: FirearmProfileCatalog = null
var _records: Dictionary = {}

func _init(world: WorldState = null, inventory: InventoryContainmentState = null, inventory_mutations: InventoryContainmentMutationService = null, profiles: FirearmProfileCatalog = null) -> void:
    _world = world
    _inventory = inventory
    _inventory_mutations = inventory_mutations
    _profiles = profiles

func is_ready() -> bool:
    return _world != null and _inventory != null and _inventory_mutations != null and _profiles != null

func has_firearm(firearm_id: String) -> bool:
    return _records.has(firearm_id)

func ensure_firearm(firearm_id: String) -> bool:
    if not is_ready() or not _world.has_entity(firearm_id): return false
    var entity: WorldEntityRecord = _world.entity(firearm_id)
    if entity == null or not _profiles.has_firearm(entity.semantic_type): return false
    if not _inventory.has_container(firearm_id) and not _inventory_mutations.enroll_container(firearm_id): return false
    if not _records.has(firearm_id):
        _records[firearm_id] = {"magazine_id": "", "chamber_round_id": "", "version": 1}
        firearm_enrolled.emit(firearm_id)
    return true

func ensure_magazine(magazine_id: String) -> bool:
    if not is_ready() or not _world.has_entity(magazine_id): return false
    var entity: WorldEntityRecord = _world.entity(magazine_id)
    if entity == null or String(entity.semantic_type) != String(FirearmProfileCatalog.SERVICE_MAGAZINE): return false
    return _inventory.has_container(magazine_id) or _inventory_mutations.enroll_container(magazine_id)

func inserted_magazine(firearm_id: String) -> String:
    return "" if not _records.has(firearm_id) else String(Dictionary(_records[firearm_id]).get("magazine_id", ""))

func chamber_round(firearm_id: String) -> String:
    return "" if not _records.has(firearm_id) else String(Dictionary(_records[firearm_id]).get("chamber_round_id", ""))

func magazine_rounds(firearm_id: String) -> Array[String]:
    var magazine_id := inserted_magazine(firearm_id)
    if magazine_id.is_empty(): return []
    return _compatible_rounds(magazine_id, firearm_id)

func insert_magazine(firearm_id: String, magazine_id: String) -> bool:
    if not ensure_firearm(firearm_id) or not ensure_magazine(magazine_id): return false
    if not inserted_magazine(firearm_id).is_empty(): return false
    if not _magazine_compatible(firearm_id, magazine_id): return false
    if not _inventory_mutations.set_container(magazine_id, firearm_id): return false
    var previous := inserted_magazine(firearm_id)
    var record: Dictionary = Dictionary(_records[firearm_id])
    record["magazine_id"] = magazine_id
    record["version"] = int(record.get("version", 0)) + 1
    _records[firearm_id] = record
    magazine_changed.emit(firearm_id, previous, magazine_id)
    return true

func eject_magazine(firearm_id: String, destination_container_id: String) -> bool:
    if not ensure_firearm(firearm_id): return false
    var magazine_id := inserted_magazine(firearm_id)
    if magazine_id.is_empty() or not _inventory.has_container(destination_container_id): return false
    if not _inventory_mutations.set_container(magazine_id, destination_container_id): return false
    var record: Dictionary = Dictionary(_records[firearm_id])
    record["magazine_id"] = ""
    record["version"] = int(record.get("version", 0)) + 1
    _records[firearm_id] = record
    magazine_changed.emit(firearm_id, magazine_id, "")
    return true

func chamber_from_magazine(firearm_id: String) -> String:
    if not ensure_firearm(firearm_id) or not chamber_round(firearm_id).is_empty(): return ""
    var rounds := magazine_rounds(firearm_id)
    if rounds.is_empty(): return ""
    var round_id := rounds[0]
    if not _inventory_mutations.set_container(round_id, firearm_id): return ""
    _set_chamber(firearm_id, round_id)
    return round_id

func release_chambered_round(firearm_id: String) -> String:
    if not ensure_firearm(firearm_id): return ""
    var round_id := chamber_round(firearm_id)
    if round_id.is_empty(): return ""
    if _inventory.is_contained(round_id) and not _inventory_mutations.clear_container(round_id): return ""
    _set_chamber(firearm_id, "")
    return round_id

func cycle_next_round(firearm_id: String) -> String:
    return chamber_from_magazine(firearm_id)

func snapshot() -> Dictionary:
    return {"records": _records.duplicate(true)}

func _set_chamber(firearm_id: String, round_id: String) -> void:
    var record: Dictionary = Dictionary(_records[firearm_id])
    var previous := String(record.get("chamber_round_id", ""))
    record["chamber_round_id"] = round_id
    record["version"] = int(record.get("version", 0)) + 1
    _records[firearm_id] = record
    chamber_changed.emit(firearm_id, previous, round_id)

func _magazine_compatible(firearm_id: String, magazine_id: String) -> bool:
    var firearm := _world.entity(firearm_id)
    var magazine := _world.entity(magazine_id)
    return firearm != null and magazine != null and _profiles.magazine_type(firearm.semantic_type) == magazine.semantic_type

func _compatible_rounds(container_id: String, firearm_id: String) -> Array[String]:
    var result: Array[String] = []
    var firearm := _world.entity(firearm_id)
    if firearm == null: return result
    var ammo_type := _profiles.ammo_type(firearm.semantic_type)
    for item_id: String in _inventory.direct_contents(container_id):
        var item := _world.entity(item_id)
        if item != null and item.semantic_type == ammo_type: result.append(item_id)
    result.sort()
    return result
