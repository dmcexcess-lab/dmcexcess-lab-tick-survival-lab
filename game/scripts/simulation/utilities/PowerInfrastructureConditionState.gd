extends RefCounted
class_name PowerInfrastructureConditionState

## Persistent System-33 condition truth for the physical electrical network.
## No per-asset timers/nodes: wear is advanced only when authoritative world time crosses a day.
## Physical failures project into the existing utility service graph; presentation never owns outages.

signal condition_changed(revision, reason)

const OPERATIONAL: StringName = &"OPERATIONAL"
const DAMAGED: StringName = &"DAMAGED"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const TICKS_PER_DAY: int = 86400
const FAILURE_THRESHOLD: int = 250

const DISTRIBUTION_SUPPORT: StringName = &"distribution_support"
const DISTRIBUTION_SPAN: StringName = &"distribution_span"
const PLANT_MACHINE: StringName = &"plant_machine"
const SUBSTATION_MACHINE: StringName = &"substation_machine"
const PLANT_TIE: StringName = &"plant_tie"
const SUBSTATION_TIE: StringName = &"substation_tie"

var _plan: GeneratedGlobalWorldPlan = null
var _utilities: UtilityRuntimeState = null
var _assets: Dictionary = {}
var _services_by_segment: Dictionary = {}
var _span_ids: Array[String] = []
var _last_processed_day: int = 0
var _revision: int = 0
var _owned_blocked_services: Dictionary = {}
var _owns_source_block: bool = false
var _owns_substation_block: bool = false

func _init(global_plan: GeneratedGlobalWorldPlan = null, utilities: UtilityRuntimeState = null) -> void:
    _plan = global_plan
    _utilities = utilities
    if is_ready():
        _build_segment_service_map()

func is_ready() -> bool:
    return _plan != null and _plan.is_generated() and _utilities != null and _utilities.is_ready()

func revision() -> int:
    return _revision

func last_processed_day() -> int:
    return _last_processed_day

func asset_ids(kind: StringName = &"") -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _assets.keys():
        var asset_id: String = String(key)
        var record: Dictionary = _assets[asset_id]
        if String(kind).is_empty() or StringName(record.get("kind", &"")) == kind:
            result.append(asset_id)
    result.sort()
    return result

func span_asset_ids() -> Array[String]:
    return _span_ids.duplicate()

func failed_asset_ids() -> Array[String]:
    var result: Array[String] = []
    for asset_id: String in asset_ids():
        if _is_failed(_assets[asset_id]):
            result.append(asset_id)
    return result

func asset_record(asset_id: String) -> Dictionary:
    var key: String = asset_id.strip_edges()
    if not _assets.has(key):
        return {}
    return (_assets[key] as Dictionary).duplicate(true)

func has_asset(asset_id: String) -> bool:
    return _assets.has(asset_id.strip_edges())

func register_distribution_projection(wire_edges: Array[Dictionary]) -> bool:
    if not is_ready() or wire_edges.is_empty():
        return false
    var ordinal_by_segment: Dictionary = {}
    for edge: Dictionary in wire_edges:
        var segment_id: String = String(edge.get("segment_id", "")).strip_edges()
        if segment_id.is_empty():
            continue
        for endpoint_key: String in ["start_id", "end_id"]:
            var entity_id: String = String(edge.get(endpoint_key, "")).strip_edges()
            if not entity_id.is_empty() and not _assets.has(entity_id):
                _register_asset(entity_id, DISTRIBUTION_SUPPORT, segment_id, entity_id)
        var ordinal: int = int(ordinal_by_segment.get(segment_id, 0))
        ordinal_by_segment[segment_id] = ordinal + 1
        var span_id: String = "power.asset.span.%s.%03d" % [_stable_token(segment_id), ordinal]
        if not _assets.has(span_id):
            _register_asset(span_id, DISTRIBUTION_SPAN, segment_id, "")
            _span_ids.append(span_id)
    _span_ids.sort()
    return not _assets.is_empty()

func register_facility_assets(
    plant_machine_ids: Array[String],
    substation_machine_ids: Array[String],
    plant_tie_entity_ids: Array[String] = [],
    substation_tie_entity_ids: Array[String] = []
) -> bool:
    if not is_ready():
        return false
    for entity_id: String in plant_machine_ids:
        _register_asset(entity_id, PLANT_MACHINE, "", entity_id)
    for entity_id: String in substation_machine_ids:
        _register_asset(entity_id, SUBSTATION_MACHINE, "", entity_id)
    for entity_id: String in plant_tie_entity_ids:
        _register_asset(entity_id, PLANT_TIE, "", entity_id)
    for entity_id: String in substation_tie_entity_ids:
        _register_asset(entity_id, SUBSTATION_TIE, "", entity_id)
    return not plant_machine_ids.is_empty() and not substation_machine_ids.is_empty()

func affected_service_ids(asset_id: String) -> Array[String]:
    var record: Dictionary = _assets.get(asset_id.strip_edges(), {})
    var result: Array[String] = []
    if record.is_empty():
        return result
    var kind: StringName = StringName(record.get("kind", &""))
    if kind == PLANT_MACHINE or kind == PLANT_TIE or kind == SUBSTATION_MACHINE or kind == SUBSTATION_TIE:
        return _utilities.power_service_ids()
    var segment_id: String = String(record.get("segment_id", ""))
    for value: Variant in _services_by_segment.get(segment_id, []):
        result.append(String(value))
    result.sort()
    return result

func apply_damage(
    asset_id: String,
    base_damage: int,
    source_kind: StringName = &"direct"
) -> bool:
    var key: String = asset_id.strip_edges()
    if not is_ready() or base_damage <= 0 or not _assets.has(key):
        return false
    var record: Dictionary = _assets[key]
    var effective_damage: int = _scaled_impact_damage(record, base_damage, source_kind)
    if effective_damage <= 0:
        return true
    var before_failed: bool = _is_failed(record)
    record["condition"] = clampi(int(record.get("condition", 1000)) - effective_damage, 0, 1000)
    record["last_damage_source"] = source_kind
    _assets[key] = record
    var after_failed: bool = _is_failed(record)
    _revision += 1
    if before_failed != after_failed:
        _sync_power_truth()
    condition_changed.emit(_revision, &"physical_power_asset_damaged")
    return true

func advance_to_tick(world_tick: int) -> bool:
    if world_tick < 0:
        return false
    return advance_to_day(world_tick / TICKS_PER_DAY)

func advance_to_day(day_index: int) -> bool:
    if not is_ready() or day_index < _last_processed_day:
        return false
    if day_index == _last_processed_day:
        return true
    var any_change: bool = false
    var failure_transition: bool = false
    for day: int in range(_last_processed_day + 1, day_index + 1):
        for asset_id: String in asset_ids():
            var record: Dictionary = _assets[asset_id]
            var wear: int = _passive_wear_for_day(record, day)
            if wear <= 0:
                continue
            var before_failed: bool = _is_failed(record)
            record["condition"] = clampi(int(record.get("condition", 1000)) - wear, 0, 1000)
            record["last_wear_day"] = day
            record["last_damage_source"] = &"passive_wear"
            _assets[asset_id] = record
            any_change = true
            if before_failed != _is_failed(record):
                failure_transition = true
    _last_processed_day = day_index
    if any_change:
        _revision += 1
        if failure_transition:
            _sync_power_truth()
        condition_changed.emit(_revision, &"physical_power_daily_wear")
    return true

func repair_requirements(asset_id: String) -> Dictionary:
    var record: Dictionary = _assets.get(asset_id.strip_edges(), {})
    if record.is_empty():
        return {}
    var kind: StringName = StringName(record.get("kind", &""))
    match kind:
        DISTRIBUTION_SUPPORT:
            return {"electrical_skill": 2, "material_units": 2, "restored_condition": 850}
        DISTRIBUTION_SPAN:
            return {"electrical_skill": 2, "material_units": 1, "restored_condition": 900}
        SUBSTATION_TIE:
            return {"electrical_skill": 4, "material_units": 4, "restored_condition": 900}
        SUBSTATION_MACHINE:
            return {"electrical_skill": 5, "material_units": 8, "restored_condition": 900}
        PLANT_TIE:
            return {"electrical_skill": 6, "material_units": 8, "restored_condition": 920}
        PLANT_MACHINE:
            return {"electrical_skill": 8, "material_units": 20, "restored_condition": 950}
    return {}

func repair_asset(asset_id: String, electrical_skill: int, available_material_units: int) -> Dictionary:
    var key: String = asset_id.strip_edges()
    var requirements: Dictionary = repair_requirements(key)
    if requirements.is_empty() or not _assets.has(key):
        return {"ok": false, "material_units_consumed": 0, "reason": &"unknown_asset"}
    var required_skill: int = int(requirements.get("electrical_skill", 0))
    var required_materials: int = int(requirements.get("material_units", 0))
    if electrical_skill < required_skill:
        return {"ok": false, "material_units_consumed": 0, "reason": &"insufficient_electrical_skill"}
    if available_material_units < required_materials:
        return {"ok": false, "material_units_consumed": 0, "reason": &"insufficient_materials"}
    var record: Dictionary = _assets[key]
    var was_failed: bool = _is_failed(record)
    record["condition"] = int(requirements.get("restored_condition", 900))
    record["last_damage_source"] = &"repair"
    _assets[key] = record
    _revision += 1
    if was_failed:
        _sync_power_truth()
    condition_changed.emit(_revision, &"physical_power_asset_repaired")
    return {"ok": true, "material_units_consumed": required_materials, "reason": &"repaired"}

func snapshot() -> Dictionary:
    var records: Array = []
    for asset_id: String in asset_ids():
        records.append((_assets[asset_id] as Dictionary).duplicate(true))
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "last_processed_day": _last_processed_day,
        "revision": _revision,
        "assets": records,
    }

func restore_snapshot(data: Dictionary) -> bool:
    if not is_ready() or int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var assets_value: Variant = data.get("assets", [])
    if typeof(assets_value) != TYPE_ARRAY:
        return false
    var restored: Dictionary = {}
    for value: Variant in assets_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var record: Dictionary = (value as Dictionary).duplicate(true)
        var asset_id: String = String(record.get("asset_id", "")).strip_edges()
        if asset_id.is_empty() or not _valid_kind(StringName(record.get("kind", &""))):
            return false
        restored[asset_id] = record
    _assets = restored
    _span_ids.clear()
    for asset_id: String in asset_ids(DISTRIBUTION_SPAN):
        _span_ids.append(asset_id)
    _last_processed_day = maxi(0, int(data.get("last_processed_day", 0)))
    _revision = maxi(0, int(data.get("revision", 0)))
    _owned_blocked_services.clear()
    _owns_source_block = false
    _owns_substation_block = false
    _sync_power_truth()
    condition_changed.emit(_revision, &"physical_power_condition_restored")
    return true

func debug_snapshot() -> Dictionary:
    var counts: Dictionary = {}
    var failed_counts: Dictionary = {}
    for asset_id: String in asset_ids():
        var record: Dictionary = _assets[asset_id]
        var key: String = String(record.get("kind", &""))
        counts[key] = int(counts.get(key, 0)) + 1
        if _is_failed(record):
            failed_counts[key] = int(failed_counts.get(key, 0)) + 1
    return {
        "ready": is_ready(),
        "revision": _revision,
        "last_processed_day": _last_processed_day,
        "asset_count": _assets.size(),
        "counts": counts,
        "failed_counts": failed_counts,
        "mapped_segment_count": _services_by_segment.size(),
    }

func _register_asset(asset_id: String, kind: StringName, segment_id: String, entity_id: String) -> void:
    var key: String = asset_id.strip_edges()
    if key.is_empty() or _assets.has(key) or not _valid_kind(kind):
        return
    _assets[key] = {
        "asset_id": key,
        "entity_id": entity_id.strip_edges(),
        "kind": kind,
        "segment_id": segment_id.strip_edges(),
        "condition": _initial_condition(key, kind),
        "last_wear_day": 0,
        "last_damage_source": &"generated_initial_condition",
    }

func _initial_condition(asset_id: String, kind: StringName) -> int:
    var value: int = _stable_hash("initial:%s" % asset_id)
    match kind:
        DISTRIBUTION_SUPPORT, DISTRIBUTION_SPAN:
            # Existing civilian grid: broad deterministic age/maintenance spread. A small tail is
            # already close enough to failure that neglected lines begin dropping after day 1-2.
            return 252 + (value % 749)
        PLANT_TIE, SUBSTATION_TIE:
            return 720 + (value % 281)
        SUBSTATION_MACHINE:
            return 880 + (value % 121)
        PLANT_MACHINE:
            return 920 + (value % 81)
    return 1000

func _passive_wear_for_day(record: Dictionary, day: int) -> int:
    var kind: StringName = StringName(record.get("kind", &""))
    var asset_id: String = String(record.get("asset_id", ""))
    var variation: int = _stable_hash("wear:%s:%d" % [asset_id, day])
    match kind:
        DISTRIBUTION_SUPPORT, DISTRIBUTION_SPAN:
            if day < 2:
                return 0
            return 6 + (variation % 19)
        PLANT_TIE, SUBSTATION_TIE:
            if day < 3:
                return 0
            return 2 + (variation % 5)
        SUBSTATION_MACHINE:
            if day < 7:
                return 0
            return 1 + (variation % 4)
        PLANT_MACHINE:
            if day < 30 or day % 7 != 0:
                return 0
            return 1 + (variation % 3)
    return 0

func _scaled_impact_damage(record: Dictionary, base_damage: int, source_kind: StringName) -> int:
    var kind: StringName = StringName(record.get("kind", &""))
    var percent: int = 100
    if source_kind == &"zombie":
        if kind == SUBSTATION_MACHINE:
            percent = 25
        elif kind == PLANT_MACHINE:
            percent = 5
    elif source_kind == &"vehicle":
        if kind == SUBSTATION_MACHINE:
            percent = 35
        elif kind == PLANT_MACHINE:
            percent = 8
    return maxi(1, base_damage * percent / 100)

func _is_failed(record: Dictionary) -> bool:
    return int(record.get("condition", 0)) <= FAILURE_THRESHOLD

func _sync_power_truth() -> void:
    if not is_ready():
        return
    var plant_failed: bool = false
    var substation_failed: bool = false
    var blocked_services: Dictionary = {}
    for asset_id: String in failed_asset_ids():
        var record: Dictionary = _assets[asset_id]
        var kind: StringName = StringName(record.get("kind", &""))
        if kind == PLANT_MACHINE or kind == PLANT_TIE:
            plant_failed = true
        elif kind == SUBSTATION_MACHINE or kind == SUBSTATION_TIE:
            substation_failed = true
        elif kind == DISTRIBUTION_SUPPORT or kind == DISTRIBUTION_SPAN:
            var segment_id: String = String(record.get("segment_id", ""))
            for service_value: Variant in _services_by_segment.get(segment_id, []):
                blocked_services[String(service_value)] = true

    var source_id: String = _utilities.power_source_component_id()
    if plant_failed and not _owns_source_block:
        if _utilities.set_power_component_state(source_id, DAMAGED, &"physical_power_plant_failure"):
            _owns_source_block = true
    elif not plant_failed and _owns_source_block:
        if _utilities.set_power_component_state(source_id, OPERATIONAL, &"physical_power_plant_repaired"):
            _owns_source_block = false

    var substation_id: String = _utilities.power_shared_distribution_component_id()
    if substation_failed and not _owns_substation_block:
        if _utilities.set_power_component_state(substation_id, DAMAGED, &"physical_substation_failure"):
            _owns_substation_block = true
    elif not substation_failed and _owns_substation_block:
        if _utilities.set_power_component_state(substation_id, OPERATIONAL, &"physical_substation_repaired"):
            _owns_substation_block = false

    for service_id: String in _utilities.power_service_ids():
        var should_block: bool = blocked_services.has(service_id)
        var owns_block: bool = _owned_blocked_services.has(service_id)
        var branch_id: String = _utilities.power_branch_component_id(service_id)
        if should_block and not owns_block:
            if _utilities.set_power_component_state(branch_id, DAMAGED, &"physical_distribution_failure"):
                _owned_blocked_services[service_id] = true
        elif not should_block and owns_block:
            if _utilities.set_power_component_state(branch_id, OPERATIONAL, &"physical_distribution_repaired"):
                _owned_blocked_services.erase(service_id)

func _build_segment_service_map() -> void:
    _services_by_segment.clear()
    var source_cell: Vector2i = Vector2i(2147483647, 2147483647)
    var service_nodes: Array[Dictionary] = []
    for node: Dictionary in _plan.power_nodes:
        var kind: StringName = StringName(node.get("kind", &""))
        if kind == &"regional_ingress":
            source_cell = node.get("cell", source_cell)
        elif kind == &"settlement_service":
            service_nodes.append(node)
    if source_cell.x == 2147483647:
        return

    var adjacency: Dictionary = {}
    for segment: Dictionary in _plan.power_segments:
        var segment_id: String = String(segment.get("id", "")).strip_edges()
        var start: Vector2i = segment.get("start", Vector2i.ZERO)
        var finish: Vector2i = segment.get("end", Vector2i.ZERO)
        if segment_id.is_empty() or start == finish:
            continue
        if not adjacency.has(start): adjacency[start] = []
        if not adjacency.has(finish): adjacency[finish] = []
        (adjacency[start] as Array).append({"to": finish, "segment_id": segment_id})
        (adjacency[finish] as Array).append({"to": start, "segment_id": segment_id})

    for node: Dictionary in service_nodes:
        var settlement_id: String = String(node.get("settlement_id", ""))
        var service_id: String = _utilities.power_service_for_settlement(settlement_id)
        if service_id.is_empty():
            continue
        var target: Vector2i = node.get("cell", Vector2i.ZERO)
        for segment_id: String in _path_segment_ids(source_cell, target, adjacency):
            if not _services_by_segment.has(segment_id):
                _services_by_segment[segment_id] = []
            var services: Array = _services_by_segment[segment_id]
            if not services.has(service_id):
                services.append(service_id)
                services.sort()
            _services_by_segment[segment_id] = services

func _path_segment_ids(start: Vector2i, target: Vector2i, adjacency: Dictionary) -> Array[String]:
    var result: Array[String] = []
    if start == target:
        return result
    if not adjacency.has(start) or not adjacency.has(target):
        return result
    var queue: Array[Vector2i] = [start]
    var head: int = 0
    var visited: Dictionary = {start: true}
    var came_from: Dictionary = {}
    while head < queue.size():
        var current: Vector2i = queue[head]
        head += 1
        var neighbors: Array = (adjacency.get(current, []) as Array).duplicate(true)
        neighbors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
            var a_id: String = String(a.get("segment_id", ""))
            var b_id: String = String(b.get("segment_id", ""))
            if a_id != b_id: return a_id < b_id
            var a_cell: Vector2i = a.get("to", Vector2i.ZERO)
            var b_cell: Vector2i = b.get("to", Vector2i.ZERO)
            return a_cell.x < b_cell.x or (a_cell.x == b_cell.x and a_cell.y < b_cell.y)
        )
        for neighbor: Dictionary in neighbors:
            var next: Vector2i = neighbor.get("to", Vector2i.ZERO)
            if visited.has(next):
                continue
            visited[next] = true
            came_from[next] = {"prior": current, "segment_id": String(neighbor.get("segment_id", ""))}
            if next == target:
                var cursor: Vector2i = target
                while cursor != start:
                    var step: Dictionary = came_from.get(cursor, {})
                    if step.is_empty():
                        return []
                    result.append(String(step.get("segment_id", "")))
                    cursor = step.get("prior", start)
                result.reverse()
                return result
            queue.append(next)
    return []

static func _valid_kind(kind: StringName) -> bool:
    return kind in [DISTRIBUTION_SUPPORT, DISTRIBUTION_SPAN, PLANT_MACHINE, SUBSTATION_MACHINE, PLANT_TIE, SUBSTATION_TIE]

static func _stable_hash(value: String) -> int:
    var total: int = 17
    for index: int in range(value.length()):
        total = ((total * 31) + value.unicode_at(index) * (index + 1)) & 0x7fffffff
    return total

static func _stable_token(value: String) -> String:
    var normalized: String = value.strip_edges().to_lower()
    for character: String in [" ", "/", "\\", ":", "|", ">", "<"]:
        normalized = normalized.replace(character, ".")
    return normalized
