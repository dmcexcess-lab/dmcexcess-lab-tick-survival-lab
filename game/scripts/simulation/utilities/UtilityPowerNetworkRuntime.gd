extends RefCounted
class_name UtilityPowerNetworkRuntime

const ConditionStoreClass = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")

## Causal physical distribution state for System 33 without a clocked network simulation.
## Each asset's wear is analytic. A single sorted threshold schedule lets authoritative time
## observe only actual failure crossings; ordinary tick advancement is an O(1) next-due check.

var _utilities: UtilityRuntimeState = null
var _tick_provider: Callable = Callable()
var _condition: UtilityNetworkConditionStore = null
var _assets_by_service: Dictionary = {}
var _services_by_asset: Dictionary = {}
var _owned_blocked_services: Dictionary = {}
var _failure_schedule: Array[Dictionary] = []
var _ready: bool = false

func initialize(
    utilities: UtilityRuntimeState,
    wire_edges: Array[Dictionary],
    tick_provider: Callable
) -> bool:
    if _ready or utilities == null or not utilities.is_ready() or wire_edges.is_empty() or not tick_provider.is_valid():
        return false
    _utilities = utilities
    _tick_provider = tick_provider
    _condition = ConditionStoreClass.new()
    var generated_tick: int = _world_tick()
    if generated_tick < 0:
        return false

    for wire: Dictionary in wire_edges:
        var settlement_ids: Array[String] = _string_array(wire.get("service_settlement_ids", []))
        var service_ids: Array[String] = []
        for settlement_id: String in settlement_ids:
            var service_id: String = _utilities.power_service_for_settlement(settlement_id)
            if not service_id.is_empty() and not service_ids.has(service_id):
                service_ids.append(service_id)
        service_ids.sort()
        if service_ids.is_empty():
            return false

        var span_id: String = String(wire.get("asset_id", "")).strip_edges()
        var segment_id: String = String(wire.get("segment_id", "")).strip_edges()
        if span_id.is_empty() or segment_id.is_empty():
            return false
        if not _register_asset(span_id, ConditionStoreClass.DISTRIBUTION_SPAN, segment_id, "", service_ids, generated_tick):
            return false

        for endpoint_key: String in ["start_id", "end_id"]:
            var support_id: String = String(wire.get(endpoint_key, "")).strip_edges()
            if support_id.is_empty():
                return false
            if not _register_asset(
                support_id,
                ConditionStoreClass.DISTRIBUTION_SUPPORT,
                segment_id,
                support_id,
                service_ids,
                generated_tick
            ):
                return false

    if _services_by_asset.is_empty():
        return false
    _rebuild_failure_schedule()
    _ready = true
    return true

func is_ready() -> bool:
    return _ready and _utilities != null and _utilities.is_ready() and _condition != null and _tick_provider.is_valid()

func asset_ids(kind: StringName = &"") -> Array[String]:
    if _condition == null:
        return []
    return _condition.asset_ids(kind)

func asset_record(asset_id: String) -> Dictionary:
    if not is_ready():
        return {}
    var result: Dictionary = _condition.asset_record(asset_id, _world_tick())
    if result.is_empty():
        return result
    result["affected_services"] = _service_ids_for_asset(asset_id)
    return result

func repair_requirements(asset_id: String) -> Dictionary:
    if _condition == null:
        return {}
    return _condition.repair_requirements(asset_id)

func damage_asset(asset_id: String, damage: int, source_kind: StringName = &"direct") -> bool:
    if not is_ready():
        return false
    var key: String = asset_id.strip_edges()
    var services: Array[String] = _service_ids_for_asset(key)
    if services.is_empty():
        return false
    var result: Dictionary = _condition.apply_damage(key, damage, _world_tick(), source_kind)
    if not bool(result.get("ok", false)):
        return false
    _reschedule_asset(key)
    return _refresh_services(services, &"physical_distribution_damage")

func repair_asset(asset_id: String, electrical_skill: int, available_material_units: int) -> Dictionary:
    if not is_ready():
        return {"ok": false, "material_units_consumed": 0, "reason": &"power_network_unavailable"}
    var key: String = asset_id.strip_edges()
    var services: Array[String] = _service_ids_for_asset(key)
    if services.is_empty():
        return {"ok": false, "material_units_consumed": 0, "reason": &"unknown_asset"}
    var result: Dictionary = _condition.repair_asset(
        key,
        electrical_skill,
        available_material_units,
        _world_tick()
    )
    if not bool(result.get("ok", false)):
        return result
    _reschedule_asset(key)
    if not _refresh_services(services, &"physical_distribution_repair"):
        return {"ok": false, "material_units_consumed": int(result.get("material_units_consumed", 0)), "reason": &"service_sync_failed"}
    return result

func advance_to_tick(world_tick: int) -> bool:
    if not is_ready() or world_tick < 0:
        return false
    while not _failure_schedule.is_empty() and int(_failure_schedule[0].get("tick", ConditionStoreClass.MAX_TICK)) <= world_tick:
        var due: Dictionary = _failure_schedule.pop_front()
        var asset_id: String = String(due.get("asset_id", ""))
        if asset_id.is_empty() or not _condition.has_asset(asset_id):
            continue
        var current_failure_tick: int = _condition.failure_tick(asset_id)
        if current_failure_tick != int(due.get("tick", -1)):
            continue
        if not _condition.is_failed_at(asset_id, world_tick):
            _insert_schedule(asset_id, current_failure_tick)
            continue
        if not _refresh_services(_service_ids_for_asset(asset_id), &"physical_distribution_wear_failure"):
            return false
    return true

func next_failure_tick() -> int:
    if _failure_schedule.is_empty():
        return ConditionStoreClass.MAX_TICK
    return int(_failure_schedule[0].get("tick", ConditionStoreClass.MAX_TICK))

func snapshot() -> Dictionary:
    if not is_ready():
        return {}
    return {"schema_version": 1, "condition": _condition.snapshot()}

func restore_snapshot(data: Dictionary) -> bool:
    if not is_ready() or int(data.get("schema_version", -1)) != 1:
        return false
    var value: Variant = data.get("condition", {})
    if typeof(value) != TYPE_DICTIONARY or not _condition.restore_snapshot(value):
        return false
    _owned_blocked_services.clear()
    _rebuild_failure_schedule()
    return _refresh_services(_all_mapped_services(), &"physical_distribution_restore")

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "mapped_asset_count": _services_by_asset.size(),
        "mapped_service_count": _assets_by_service.size(),
        "owned_blocked_service_count": _owned_blocked_services.size(),
        "next_failure_tick": next_failure_tick(),
        "condition": {} if _condition == null else _condition.debug_snapshot(_world_tick()),
    }

func _register_asset(
    asset_id: String,
    kind: StringName,
    section_id: String,
    entity_id: String,
    service_ids: Array[String],
    generated_tick: int
) -> bool:
    if not _condition.has_asset(asset_id):
        if not _condition.register_asset(asset_id, kind, section_id, entity_id, generated_tick):
            return false
    var mapped_services: Array[String] = _service_ids_for_asset(asset_id)
    for service_id: String in service_ids:
        if not mapped_services.has(service_id):
            mapped_services.append(service_id)
        var assets: Array[String] = _asset_ids_for_service(service_id)
        if not assets.has(asset_id):
            assets.append(asset_id)
            assets.sort()
            _assets_by_service[service_id] = assets
    mapped_services.sort()
    _services_by_asset[asset_id] = mapped_services
    return true

func _refresh_services(service_ids: Array[String], reason: StringName) -> bool:
    var tick: int = _world_tick()
    for service_id: String in service_ids:
        var failed: bool = false
        for asset_id: String in _asset_ids_for_service(service_id):
            if _condition.is_failed_at(asset_id, tick):
                failed = true
                break
        var link_id: String = _distribution_link_id(service_id)
        if link_id.is_empty():
            return false
        if failed:
            if not _owned_blocked_services.has(service_id):
                if not _utilities.set_power_link_state(link_id, UtilityRuntimeState.DAMAGED, reason):
                    return false
                _owned_blocked_services[service_id] = true
        elif _owned_blocked_services.has(service_id):
            if not _utilities.set_power_link_state(link_id, UtilityRuntimeState.OPERATIONAL, reason):
                return false
            _owned_blocked_services.erase(service_id)
    return true

func _distribution_link_id(service_id: String) -> String:
    const PREFIX: String = "power.service."
    if not service_id.begins_with(PREFIX):
        return ""
    var settlement_id: String = service_id.substr(PREFIX.length())
    if settlement_id.is_empty():
        return ""
    return "power.link.substation_to.%s" % settlement_id

func _rebuild_failure_schedule() -> void:
    _failure_schedule.clear()
    if _condition == null:
        return
    for asset_id: String in _condition.asset_ids():
        _insert_schedule(asset_id, _condition.failure_tick(asset_id))

func _reschedule_asset(asset_id: String) -> void:
    for index: int in range(_failure_schedule.size() - 1, -1, -1):
        if String(_failure_schedule[index].get("asset_id", "")) == asset_id:
            _failure_schedule.remove_at(index)
    _insert_schedule(asset_id, _condition.failure_tick(asset_id))

func _insert_schedule(asset_id: String, failure_tick: int) -> void:
    if failure_tick >= ConditionStoreClass.MAX_TICK:
        return
    var record: Dictionary = {"asset_id": asset_id, "tick": failure_tick}
    var insert_at: int = _failure_schedule.size()
    for index: int in range(_failure_schedule.size()):
        var existing: Dictionary = _failure_schedule[index]
        var existing_tick: int = int(existing.get("tick", ConditionStoreClass.MAX_TICK))
        if failure_tick < existing_tick or (failure_tick == existing_tick and asset_id < String(existing.get("asset_id", ""))):
            insert_at = index
            break
    _failure_schedule.insert(insert_at, record)

func _service_ids_for_asset(asset_id: String) -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _services_by_asset.get(asset_id.strip_edges(), []):
        result.append(String(value))
    return result

func _asset_ids_for_service(service_id: String) -> Array[String]:
    var result: Array[String] = []
    for value: Variant in _assets_by_service.get(service_id.strip_edges(), []):
        result.append(String(value))
    return result

func _all_mapped_services() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _assets_by_service.keys():
        result.append(String(key))
    result.sort()
    return result

func _world_tick() -> int:
    if not _tick_provider.is_valid():
        return -1
    return int(_tick_provider.call())

static func _string_array(value: Variant) -> Array[String]:
    var result: Array[String] = []
    if typeof(value) != TYPE_ARRAY:
        return result
    for item: Variant in value:
        var text: String = String(item).strip_edges()
        if not text.is_empty() and not result.has(text):
            result.append(text)
    result.sort()
    return result
