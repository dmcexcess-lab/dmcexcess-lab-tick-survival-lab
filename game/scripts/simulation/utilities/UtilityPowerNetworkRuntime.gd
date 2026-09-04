extends RefCounted
class_name UtilityPowerNetworkRuntime

const ConditionStoreClass = preload("res://scripts/simulation/utilities/UtilityNetworkConditionStore.gd")

## Causal physical distribution state for System 33. Physical condition changes only from
## explicit damage/repair events or the once-per-authoritative-day deterministic span snap pass.
## There are no per-asset Nodes/timers and no continuous analytic wear scheduler.

signal line_snapped(asset_id, cell)

const CHANCE_DENOMINATOR: int = 1000000
const BASE_DAILY_SNAP_CHANCE: int = 100 # 0.01% per eligible span.
const QUIET_DAY_SNAP_INCREMENT: int = 100 # +0.01% per no-snap day.
const MAX_DAILY_SNAP_CHANCE: int = 10000 # 1.00% per eligible span cap.
const INVALID_CELL := Vector2i(2147483647, 2147483647)

var _utilities: UtilityRuntimeState = null
var _tick_provider: Callable = Callable()
var _condition: UtilityNetworkConditionStore = null
var _assets_by_service: Dictionary = {}
var _services_by_asset: Dictionary = {}
var _owned_blocked_services: Dictionary = {}
var _span_cells: Dictionary = {}
var _last_processed_day: int = 0
var _quiet_days: int = 0
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
    _last_processed_day = int(generated_tick / ConditionStoreClass.TICKS_PER_DAY)
    _quiet_days = 0

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
        var snap_cell: Vector2i = wire.get("snap_cell", INVALID_CELL)
        if snap_cell == INVALID_CELL:
            snap_cell = _wire_endpoint_cell(wire)
        _span_cells[span_id] = snap_cell

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

    if _services_by_asset.is_empty() or _condition.asset_ids(ConditionStoreClass.DISTRIBUTION_SPAN).is_empty():
        return false
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
    if StringName(result.get("kind", &"")) == ConditionStoreClass.DISTRIBUTION_SPAN:
        result["snap_cell"] = _span_cells.get(asset_id.strip_edges(), INVALID_CELL)
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
    return _refresh_services(services, &"physical_distribution_damage")

func repair_asset(asset_id: String, mechanical_skill: int, available_material_units: int) -> Dictionary:
    if not is_ready():
        return {"ok": false, "material_units_consumed": 0, "reason": &"power_network_unavailable"}
    var key: String = asset_id.strip_edges()
    var services: Array[String] = _service_ids_for_asset(key)
    if services.is_empty():
        return {"ok": false, "material_units_consumed": 0, "reason": &"unknown_asset"}
    var result: Dictionary = _condition.repair_asset(
        key,
        mechanical_skill,
        available_material_units,
        _world_tick()
    )
    if not bool(result.get("ok", false)):
        return result
    if not _refresh_services(services, &"physical_distribution_repair"):
        return {"ok": false, "material_units_consumed": int(result.get("material_units_consumed", 0)), "reason": &"service_sync_failed"}
    return result

func advance_to_tick(world_tick: int) -> bool:
    if not is_ready() or world_tick < 0:
        return false
    var target_day: int = int(world_tick / ConditionStoreClass.TICKS_PER_DAY)
    while _last_processed_day < target_day:
        _last_processed_day += 1
        if not _process_daily_snap(_last_processed_day):
            return false
    return true

## Compatibility/query seam: now returns the next daily test boundary, not a predicted wear failure.
func next_failure_tick() -> int:
    if not is_ready():
        return ConditionStoreClass.MAX_TICK
    return (_last_processed_day + 1) * ConditionStoreClass.TICKS_PER_DAY

func current_daily_snap_chance() -> int:
    return mini(BASE_DAILY_SNAP_CHANCE + _quiet_days * QUIET_DAY_SNAP_INCREMENT, MAX_DAILY_SNAP_CHANCE)

func snapshot() -> Dictionary:
    if not is_ready():
        return {}
    return {
        "schema_version": 2,
        "condition": _condition.snapshot(),
        "last_processed_day": _last_processed_day,
        "quiet_days": _quiet_days,
    }

func restore_snapshot(data: Dictionary) -> bool:
    if not is_ready() or int(data.get("schema_version", -1)) != 2:
        return false
    var value: Variant = data.get("condition", {})
    var restored_day: int = int(data.get("last_processed_day", -1))
    var restored_quiet_days: int = int(data.get("quiet_days", -1))
    if typeof(value) != TYPE_DICTIONARY or restored_day < 0 or restored_quiet_days < 0 \
        or not _condition.restore_snapshot(value):
        return false
    _last_processed_day = restored_day
    _quiet_days = restored_quiet_days
    _owned_blocked_services.clear()
    return _refresh_services(_all_mapped_services(), &"physical_distribution_restore")

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "mapped_asset_count": _services_by_asset.size(),
        "mapped_service_count": _assets_by_service.size(),
        "owned_blocked_service_count": _owned_blocked_services.size(),
        "next_failure_tick": next_failure_tick(),
        "last_processed_day": _last_processed_day,
        "quiet_days": _quiet_days,
        "daily_snap_chance_numerator": current_daily_snap_chance(),
        "daily_snap_chance_denominator": CHANCE_DENOMINATOR,
        "condition": {} if _condition == null else _condition.debug_snapshot(_world_tick()),
    }

func _process_daily_snap(day_index: int) -> bool:
    var chance: int = current_daily_snap_chance()
    var eligible_count: int = 0
    for span_id: String in _condition.asset_ids(ConditionStoreClass.DISTRIBUTION_SPAN):
        if _condition.is_failed_at(span_id, _world_tick()):
            continue
        eligible_count += 1
        var roll: int = _stable_hash("daily_snap|%d|%s" % [day_index, span_id]) % CHANCE_DENOMINATOR
        if roll >= chance:
            continue
        var current_condition: int = _condition.condition_at(span_id, _world_tick())
        var damage: int = maxi(1, current_condition - ConditionStoreClass.FAILURE_THRESHOLD + 1)
        var result: Dictionary = _condition.apply_damage(span_id, damage, _world_tick(), &"daily_line_snap")
        if not bool(result.get("ok", false)) or not bool(result.get("failed", false)):
            return false
        if not _refresh_services(_service_ids_for_asset(span_id), &"physical_distribution_daily_snap"):
            return false
        _quiet_days = 0
        var cell: Vector2i = _span_cells.get(span_id, INVALID_CELL)
        line_snapped.emit(span_id, cell)
        return true
    if eligible_count > 0:
        _quiet_days += 1
    return true

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

func _wire_endpoint_cell(wire: Dictionary) -> Vector2i:
    # Legacy/base physical projections may not carry a snap-cell hint. Returning INVALID here
    # preserves the physical failure even when no presentation origin was supplied.
    return INVALID_CELL

static func _stable_hash(value: String) -> int:
    var result: int = 2166136261
    for index: int in range(value.length()):
        result = int((result ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
    return result

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
