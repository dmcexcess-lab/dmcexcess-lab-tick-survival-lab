extends RefCounted
class_name UtilityRuntimeState

## System 33 authoritative current utility truth. 00D plans supply stable infrastructure
## identity; this owner stores operational state and derives service from bounded chains.

signal power_changed(revision, reason)
signal water_changed(revision, reason)
signal appliances_changed(revision, reason)
signal utility_reset

const SNAPSHOT_SCHEMA_VERSION: int = 1
const OPERATIONAL: StringName = &"OPERATIONAL"
const DISABLED: StringName = &"DISABLED"
const DAMAGED: StringName = &"DAMAGED"
const VALID_STATES: Array[StringName] = [OPERATIONAL, DISABLED, DAMAGED]
const INVALID_CELL := Vector2i(2147483647, 2147483647)

var _initialized: bool = false
var _power_components: Dictionary = {}
var _power_links: Dictionary = {}
var _power_bindings: Dictionary = {}
var _power_service_by_settlement: Dictionary = {}
var _power_parent_link: Dictionary = {}
var _power_branch_by_service: Dictionary = {}
var _water_components: Dictionary = {}
var _water_links: Dictionary = {}
var _water_bindings: Dictionary = {}
var _water_service_by_settlement: Dictionary = {}
var _water_parent_link: Dictionary = {}
var _water_local_by_service: Dictionary = {}
var _appliances: Dictionary = {}
var _power_revision: int = 0
var _water_revision: int = 0
var _appliance_revision: int = 0
var _power_cache: Dictionary = {}
var _water_cache: Dictionary = {}
var _telemetry: Dictionary = {
    "power_derivations": 0,
    "power_cache_hits": 0,
    "water_derivations": 0,
    "water_cache_hits": 0,
    "utility_mutations": 0,
    "power_invalidations": 0,
    "water_invalidations": 0,
    "appliance_invalidations": 0,
}

func is_ready() -> bool:
    return _initialized and not _power_bindings.is_empty() and not _water_bindings.is_empty()

func initialize_from_plan(plan: GeneratedGlobalWorldPlan) -> bool:
    if _initialized or plan == null or not plan.is_generated():
        return false
    _clear_all()
    if not _materialize_power(plan) or not _materialize_water(plan):
        _clear_all()
        return false
    if not _validate_power_topology(_power_components, _power_links, _power_bindings) \
        or not _validate_water_topology(_water_components, _water_links, _water_bindings, _power_bindings):
        _clear_all()
        return false
    _initialized = true
    return true

func power_revision() -> int:
    return _power_revision

func water_revision() -> int:
    return _water_revision

func appliance_revision() -> int:
    return _appliance_revision

func telemetry() -> Dictionary:
    return _telemetry.duplicate(true)

func power_service_ids() -> Array[String]:
    return _sorted_keys(_power_bindings)

func water_service_ids() -> Array[String]:
    return _sorted_keys(_water_bindings)

func power_service_for_settlement(settlement_id: String) -> String:
    return String(_power_service_by_settlement.get(settlement_id.strip_edges(), ""))

func water_service_for_settlement(settlement_id: String) -> String:
    return String(_water_service_by_settlement.get(settlement_id.strip_edges(), ""))

func power_service_for_cell(cell: Vector2i) -> String:
    var best_service: String = ""
    var best_distance: int = 2147483647
    for service_id: String in power_service_ids():
        var binding: Dictionary = _power_bindings[service_id]
        var component: Dictionary = _power_components.get(String(binding.get("terminal_component_id", "")), {})
        var service_cell: Vector2i = component.get("cell", INVALID_CELL)
        if service_cell == INVALID_CELL:
            continue
        var distance: int = absi(cell.x - service_cell.x) + absi(cell.y - service_cell.y)
        if distance < best_distance or (distance == best_distance and (best_service.is_empty() or service_id < best_service)):
            best_service = service_id
            best_distance = distance
    return best_service

func power_source_component_id() -> String:
    for component_id: String in _sorted_keys(_power_components):
        if StringName((_power_components[component_id] as Dictionary).get("role", &"")) == &"source":
            return component_id
    return ""

func power_shared_distribution_component_id() -> String:
    for component_id: String in _sorted_keys(_power_components):
        if StringName((_power_components[component_id] as Dictionary).get("role", &"")) == &"substation":
            return component_id
    return ""

func power_branch_component_id(service_id: String) -> String:
    return String(_power_branch_by_service.get(service_id.strip_edges(), ""))

func water_local_component_id(service_id: String) -> String:
    return String(_water_local_by_service.get(service_id.strip_edges(), ""))

func water_source_component_id(service_id: String) -> String:
    var binding: Dictionary = _water_bindings.get(service_id.strip_edges(), {})
    var current: String = String(binding.get("terminal_component_id", ""))
    var visited: Dictionary = {}
    while not current.is_empty() and not visited.has(current):
        visited[current] = true
        var component: Dictionary = _water_components.get(current, {})
        var role: StringName = StringName(component.get("role", &""))
        if role == &"source" or role == &"well":
            return current
        if not _water_parent_link.has(current):
            break
        var link: Dictionary = _water_links.get(String(_water_parent_link[current]), {})
        current = String(link.get("upstream_component_id", ""))
    return ""

func power_service_available(service_id: String) -> bool:
    var key: String = service_id.strip_edges()
    if not is_ready() or not _power_bindings.has(key):
        return false
    var cached: Dictionary = _power_cache.get(key, {})
    if int(cached.get("revision", -1)) == _power_revision:
        _telemetry["power_cache_hits"] = int(_telemetry["power_cache_hits"]) + 1
        return bool(cached.get("available", false))
    _telemetry["power_derivations"] = int(_telemetry["power_derivations"]) + 1
    var terminal: String = String((_power_bindings[key] as Dictionary).get("terminal_component_id", ""))
    var available: bool = _derive_power_component(terminal, {})
    _power_cache[key] = {"revision": _power_revision, "available": available}
    return available

func water_service_available(service_id: String) -> bool:
    var key: String = service_id.strip_edges()
    if not is_ready() or not _water_bindings.has(key):
        return false
    var cached: Dictionary = _water_cache.get(key, {})
    if int(cached.get("water_revision", -1)) == _water_revision \
        and int(cached.get("power_revision", -1)) == _power_revision:
        _telemetry["water_cache_hits"] = int(_telemetry["water_cache_hits"]) + 1
        return bool(cached.get("available", false))
    _telemetry["water_derivations"] = int(_telemetry["water_derivations"]) + 1
    var terminal: String = String((_water_bindings[key] as Dictionary).get("terminal_component_id", ""))
    var available: bool = _derive_water_component(terminal, {})
    _water_cache[key] = {
        "water_revision": _water_revision,
        "power_revision": _power_revision,
        "available": available,
    }
    return available

func bind_appliance(
    appliance_id: String,
    kind: StringName,
    power_service_id: String,
    owner_entity_id: String = "",
    switched_on: bool = true
) -> bool:
    var key: String = appliance_id.strip_edges()
    var service: String = power_service_id.strip_edges()
    if not is_ready() or key.is_empty() or String(kind).is_empty() or not _power_bindings.has(service):
        return false
    if _appliances.has(key):
        var existing: Dictionary = _appliances[key]
        return String(existing.get("power_service_id", "")) == service \
            and StringName(existing.get("kind", &"")) == kind
    _appliances[key] = {
        "appliance_id": key,
        "kind": kind,
        "power_service_id": service,
        "owner_entity_id": owner_entity_id.strip_edges(),
        "operational_state": OPERATIONAL,
        "switched_on": switched_on,
    }
    _mark_appliance_changed(&"appliance_bound")
    return true

func appliance_ids(kind: StringName = &"") -> Array[String]:
    var result: Array[String] = []
    for key: String in _sorted_keys(_appliances):
        if String(kind).is_empty() or StringName((_appliances[key] as Dictionary).get("kind", &"")) == kind:
            result.append(key)
    return result

func appliance_record(appliance_id: String) -> Dictionary:
    if not _appliances.has(appliance_id):
        return {}
    return (_appliances[appliance_id] as Dictionary).duplicate(true)

func appliance_powered(appliance_id: String) -> bool:
    var record: Dictionary = _appliances.get(appliance_id.strip_edges(), {})
    if record.is_empty() or StringName(record.get("operational_state", &"")) != OPERATIONAL \
        or not bool(record.get("switched_on", false)):
        return false
    return power_service_available(String(record.get("power_service_id", "")))

func cold_storage_available(appliance_id: String) -> bool:
    var record: Dictionary = _appliances.get(appliance_id.strip_edges(), {})
    return not record.is_empty() \
        and StringName(record.get("kind", &"")) == &"refrigeration" \
        and appliance_powered(appliance_id)

func set_power_component_state(component_id: String, state: StringName, reason: StringName = &"power_component_mutated") -> bool:
    var key: String = component_id.strip_edges()
    if not is_ready() or not _valid_state(state) or not _power_components.has(key):
        return false
    var record: Dictionary = _power_components[key]
    if StringName(record.get("operational_state", &"")) == state:
        return true
    record["operational_state"] = state
    _power_components[key] = record
    _mark_power_changed(reason)
    return true

func set_power_link_state(link_id: String, state: StringName, reason: StringName = &"power_link_mutated") -> bool:
    var key: String = link_id.strip_edges()
    if not is_ready() or not _valid_state(state) or not _power_links.has(key):
        return false
    var record: Dictionary = _power_links[key]
    if StringName(record.get("operational_state", &"")) == state:
        return true
    record["operational_state"] = state
    _power_links[key] = record
    _mark_power_changed(reason)
    return true

func set_water_component_state(component_id: String, state: StringName, reason: StringName = &"water_component_mutated") -> bool:
    var key: String = component_id.strip_edges()
    if not is_ready() or not _valid_state(state) or not _water_components.has(key):
        return false
    var record: Dictionary = _water_components[key]
    if StringName(record.get("operational_state", &"")) == state:
        return true
    record["operational_state"] = state
    _water_components[key] = record
    _mark_water_changed(reason)
    return true

func set_water_link_state(link_id: String, state: StringName, reason: StringName = &"water_link_mutated") -> bool:
    var key: String = link_id.strip_edges()
    if not is_ready() or not _valid_state(state) or not _water_links.has(key):
        return false
    var record: Dictionary = _water_links[key]
    if StringName(record.get("operational_state", &"")) == state:
        return true
    record["operational_state"] = state
    _water_links[key] = record
    _mark_water_changed(reason)
    return true

func set_appliance_operational_state(appliance_id: String, state: StringName, reason: StringName = &"appliance_state_mutated") -> bool:
    var key: String = appliance_id.strip_edges()
    if not is_ready() or not _valid_state(state) or not _appliances.has(key):
        return false
    var record: Dictionary = _appliances[key]
    if StringName(record.get("operational_state", &"")) == state:
        return true
    record["operational_state"] = state
    _appliances[key] = record
    _mark_appliance_changed(reason)
    return true

func set_appliance_switched(appliance_id: String, switched_on: bool, reason: StringName = &"appliance_switch_mutated") -> bool:
    var key: String = appliance_id.strip_edges()
    if not is_ready() or not _appliances.has(key):
        return false
    var record: Dictionary = _appliances[key]
    if bool(record.get("switched_on", false)) == switched_on:
        return true
    record["switched_on"] = switched_on
    _appliances[key] = record
    _mark_appliance_changed(reason)
    return true

func snapshot() -> Dictionary:
    if not is_ready():
        return {}
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "power_revision": _power_revision,
        "water_revision": _water_revision,
        "appliance_revision": _appliance_revision,
        "power_components": _records_snapshot(_power_components),
        "power_links": _records_snapshot(_power_links),
        "power_bindings": _records_snapshot(_power_bindings),
        "water_components": _records_snapshot(_water_components),
        "water_links": _records_snapshot(_water_links),
        "water_bindings": _records_snapshot(_water_bindings),
        "appliances": _records_snapshot(_appliances),
    }

func restore_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var pc: Dictionary = _records_from_snapshot(data.get("power_components", []), "component_id")
    var pl: Dictionary = _records_from_snapshot(data.get("power_links", []), "link_id")
    var pb: Dictionary = _records_from_snapshot(data.get("power_bindings", []), "service_id")
    var wc: Dictionary = _records_from_snapshot(data.get("water_components", []), "component_id")
    var wl: Dictionary = _records_from_snapshot(data.get("water_links", []), "link_id")
    var wb: Dictionary = _records_from_snapshot(data.get("water_bindings", []), "service_id")
    var appliances: Dictionary = _records_from_snapshot(data.get("appliances", []), "appliance_id", true)
    if pc.is_empty() or pl.is_empty() or pb.is_empty() or wc.is_empty() or wl.is_empty() or wb.is_empty():
        return false
    if not _validate_power_topology(pc, pl, pb) or not _validate_water_topology(wc, wl, wb, pb):
        return false
    for value: Variant in appliances.values():
        var appliance: Dictionary = value
        if not _valid_state(StringName(appliance.get("operational_state", &""))) \
            or not pb.has(String(appliance.get("power_service_id", ""))):
            return false
    _power_components = pc
    _power_links = pl
    _power_bindings = pb
    _water_components = wc
    _water_links = wl
    _water_bindings = wb
    _appliances = appliances
    _power_revision = maxi(0, int(data.get("power_revision", 0)))
    _water_revision = maxi(0, int(data.get("water_revision", 0)))
    _appliance_revision = maxi(0, int(data.get("appliance_revision", 0)))
    _power_cache.clear()
    _water_cache.clear()
    _initialized = true
    _rebuild_indices()
    utility_reset.emit()
    power_changed.emit(_power_revision, &"utility_restore")
    water_changed.emit(_water_revision, &"utility_restore")
    appliances_changed.emit(_appliance_revision, &"utility_restore")
    return true

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "power_revision": _power_revision,
        "water_revision": _water_revision,
        "appliance_revision": _appliance_revision,
        "power_services": power_service_ids(),
        "water_services": water_service_ids(),
        "appliances": appliance_ids(),
        "telemetry": telemetry(),
    }

func _materialize_power(plan: GeneratedGlobalWorldPlan) -> bool:
    var ingress_id: String = ""
    var substation_id: String = ""
    var planned_services: Array[Dictionary] = []
    for node: Dictionary in plan.power_nodes:
        var planned_id: String = String(node.get("id", ""))
        var kind: StringName = StringName(node.get("kind", &""))
        if planned_id.is_empty():
            return false
        var component_id: String = "power.component.%s" % planned_id
        var role: StringName = &"structure_service"
        if kind == &"regional_ingress":
            role = &"source"
            ingress_id = component_id
        elif kind == &"substation":
            role = &"substation"
            substation_id = component_id
        elif kind == &"settlement_service":
            planned_services.append(node)
        _power_components[component_id] = {
            "component_id": component_id,
            "role": role,
            "operational_state": OPERATIONAL,
            "planning_id": planned_id,
            "settlement_id": String(node.get("settlement_id", "")),
            "cell": node.get("cell", INVALID_CELL),
        }
    if ingress_id.is_empty() or substation_id.is_empty() or planned_services.is_empty():
        return false
    _insert_power_link("power.link.regional_to_substation", ingress_id, substation_id, "")
    for node: Dictionary in planned_services:
        var settlement_id: String = String(node.get("settlement_id", ""))
        var terminal: String = "power.component.%s" % String(node.get("id", ""))
        if settlement_id.is_empty() or not _power_components.has(terminal):
            return false
        var feeder: String = "power.component.feeder.%s" % settlement_id
        _power_components[feeder] = {
            "component_id": feeder,
            "role": &"feeder",
            "operational_state": OPERATIONAL,
            "planning_id": "derived:%s" % settlement_id,
            "settlement_id": settlement_id,
            "cell": node.get("cell", INVALID_CELL),
        }
        _insert_power_link("power.link.substation_to.%s" % settlement_id, substation_id, feeder, settlement_id)
        _insert_power_link("power.link.feeder_to.%s" % settlement_id, feeder, terminal, settlement_id)
        var service_id: String = "power.service.%s" % settlement_id
        _power_bindings[service_id] = {
            "service_id": service_id,
            "terminal_component_id": terminal,
            "owner_entity_id": "",
            "settlement_id": settlement_id,
        }
        _power_service_by_settlement[settlement_id] = service_id
        _power_branch_by_service[service_id] = feeder
    _rebuild_power_parent_index()
    return true

func _materialize_water(plan: GeneratedGlobalWorldPlan) -> bool:
    var municipal_source: String = ""
    var municipal_treatment: String = ""
    var municipal_terminal: String = ""
    for node: Dictionary in plan.water_nodes:
        var planned_id: String = String(node.get("id", ""))
        var kind: StringName = StringName(node.get("kind", &""))
        if planned_id.is_empty():
            return false
        var component_id: String = "water.component.%s" % planned_id
        var role: StringName = &"local_service"
        if kind == &"groundwater_source":
            role = &"source"
            municipal_source = component_id
        elif kind == &"treatment_storage":
            role = &"treatment_storage"
            municipal_treatment = component_id
        elif kind == &"settlement_service":
            municipal_terminal = component_id
        _water_components[component_id] = {
            "component_id": component_id,
            "role": role,
            "operational_state": OPERATIONAL,
            "required_power_service_id": "",
            "planning_id": planned_id,
            "settlement_id": String(node.get("settlement_id", "")),
            "cell": node.get("cell", INVALID_CELL),
        }
    for service: Dictionary in plan.water_services:
        var service_id: String = String(service.get("id", ""))
        var settlement_id: String = String(service.get("settlement_id", ""))
        var mode: StringName = StringName(service.get("service_mode", &""))
        if service_id.is_empty() or settlement_id.is_empty():
            return false
        var power_service: String = power_service_for_settlement(settlement_id)
        if power_service.is_empty():
            return false
        var terminal: String = ""
        if mode == &"municipal":
            if municipal_source.is_empty() or municipal_treatment.is_empty() or municipal_terminal.is_empty():
                return false
            var pump: String = "water.component.pump.%s" % settlement_id
            _water_components[pump] = _water_component(
                pump, &"pump_distribution", settlement_id,
                (_water_components[municipal_terminal] as Dictionary).get("cell", INVALID_CELL), power_service
            )
            _insert_water_link("water.link.source_to_treatment", municipal_source, municipal_treatment, settlement_id)
            _insert_water_link("water.link.treatment_to_pump", municipal_treatment, pump, settlement_id)
            _insert_water_link("water.link.pump_to_service.%s" % settlement_id, pump, municipal_terminal, settlement_id)
            terminal = municipal_terminal
        else:
            var well: String = "water.component.well.%s" % settlement_id
            var pump: String = "water.component.well_pump.%s" % settlement_id
            terminal = "water.component.property_service.%s" % settlement_id
            var service_cell: Vector2i = _power_service_cell(power_service)
            _water_components[well] = _water_component(well, &"well", settlement_id, service_cell, "")
            _water_components[pump] = _water_component(pump, &"pump_distribution", settlement_id, service_cell, power_service)
            _water_components[terminal] = _water_component(terminal, &"local_service", settlement_id, service_cell, "")
            _insert_water_link("water.link.well_to_pump.%s" % settlement_id, well, pump, settlement_id)
            _insert_water_link("water.link.pump_to_property.%s" % settlement_id, pump, terminal, settlement_id)
        _water_bindings[service_id] = {
            "service_id": service_id,
            "terminal_component_id": terminal,
            "owner_entity_id": "",
            "settlement_id": settlement_id,
        }
        _water_service_by_settlement[settlement_id] = service_id
        _water_local_by_service[service_id] = terminal
    _rebuild_water_parent_index()
    return not _water_bindings.is_empty()

func _water_component(id: String, role: StringName, settlement_id: String, cell: Vector2i, required_power: String) -> Dictionary:
    return {
        "component_id": id,
        "role": role,
        "operational_state": OPERATIONAL,
        "required_power_service_id": required_power,
        "planning_id": "derived:%s" % settlement_id,
        "settlement_id": settlement_id,
        "cell": cell,
    }

func _insert_power_link(id: String, upstream: String, downstream: String, settlement_id: String) -> void:
    _power_links[id] = {
        "link_id": id,
        "upstream_component_id": upstream,
        "downstream_component_id": downstream,
        "operational_state": OPERATIONAL,
        "planning_id": "derived:%s" % settlement_id,
    }

func _insert_water_link(id: String, upstream: String, downstream: String, settlement_id: String) -> void:
    if _water_links.has(id):
        return
    _water_links[id] = {
        "link_id": id,
        "upstream_component_id": upstream,
        "downstream_component_id": downstream,
        "operational_state": OPERATIONAL,
        "planning_id": "derived:%s" % settlement_id,
    }

func _derive_power_component(component_id: String, visited: Dictionary) -> bool:
    if component_id.is_empty() or visited.has(component_id) or not _power_components.has(component_id):
        return false
    visited[component_id] = true
    var component: Dictionary = _power_components[component_id]
    if StringName(component.get("operational_state", &"")) != OPERATIONAL:
        return false
    if StringName(component.get("role", &"")) == &"source":
        return true
    if not _power_parent_link.has(component_id):
        return false
    var link: Dictionary = _power_links.get(String(_power_parent_link[component_id]), {})
    if link.is_empty() or StringName(link.get("operational_state", &"")) != OPERATIONAL:
        return false
    return _derive_power_component(String(link.get("upstream_component_id", "")), visited)

func _derive_water_component(component_id: String, visited: Dictionary) -> bool:
    if component_id.is_empty() or visited.has(component_id) or not _water_components.has(component_id):
        return false
    visited[component_id] = true
    var component: Dictionary = _water_components[component_id]
    if StringName(component.get("operational_state", &"")) != OPERATIONAL:
        return false
    var required_power: String = String(component.get("required_power_service_id", ""))
    if not required_power.is_empty() and not power_service_available(required_power):
        return false
    var role: StringName = StringName(component.get("role", &""))
    if role == &"source" or role == &"well":
        return true
    if not _water_parent_link.has(component_id):
        return false
    var link: Dictionary = _water_links.get(String(_water_parent_link[component_id]), {})
    if link.is_empty() or StringName(link.get("operational_state", &"")) != OPERATIONAL:
        return false
    return _derive_water_component(String(link.get("upstream_component_id", "")), visited)

func _mark_power_changed(reason: StringName) -> void:
    _power_revision += 1
    _telemetry["utility_mutations"] = int(_telemetry["utility_mutations"]) + 1
    _telemetry["power_invalidations"] = int(_telemetry["power_invalidations"]) + 1
    _power_cache.clear()
    _water_cache.clear()
    power_changed.emit(_power_revision, reason)

func _mark_water_changed(reason: StringName) -> void:
    _water_revision += 1
    _telemetry["utility_mutations"] = int(_telemetry["utility_mutations"]) + 1
    _telemetry["water_invalidations"] = int(_telemetry["water_invalidations"]) + 1
    _water_cache.clear()
    water_changed.emit(_water_revision, reason)

func _mark_appliance_changed(reason: StringName) -> void:
    _appliance_revision += 1
    _telemetry["utility_mutations"] = int(_telemetry["utility_mutations"]) + 1
    _telemetry["appliance_invalidations"] = int(_telemetry["appliance_invalidations"]) + 1
    appliances_changed.emit(_appliance_revision, reason)

func _power_service_cell(service_id: String) -> Vector2i:
    var binding: Dictionary = _power_bindings.get(service_id, {})
    var component: Dictionary = _power_components.get(String(binding.get("terminal_component_id", "")), {})
    return component.get("cell", INVALID_CELL)

func _rebuild_indices() -> void:
    _rebuild_power_parent_index()
    _rebuild_water_parent_index()
    _power_service_by_settlement.clear()
    _power_branch_by_service.clear()
    for service_id: String in _sorted_keys(_power_bindings):
        var binding: Dictionary = _power_bindings[service_id]
        var settlement: String = String(binding.get("settlement_id", ""))
        if not settlement.is_empty():
            _power_service_by_settlement[settlement] = service_id
        var terminal: String = String(binding.get("terminal_component_id", ""))
        if _power_parent_link.has(terminal):
            var terminal_link: Dictionary = _power_links.get(String(_power_parent_link[terminal]), {})
            _power_branch_by_service[service_id] = String(terminal_link.get("upstream_component_id", ""))
    _water_service_by_settlement.clear()
    _water_local_by_service.clear()
    for service_id: String in _sorted_keys(_water_bindings):
        var binding: Dictionary = _water_bindings[service_id]
        var settlement: String = String(binding.get("settlement_id", ""))
        if not settlement.is_empty():
            _water_service_by_settlement[settlement] = service_id
        _water_local_by_service[service_id] = String(binding.get("terminal_component_id", ""))

func _rebuild_power_parent_index() -> void:
    _power_parent_link.clear()
    for link_id: String in _sorted_keys(_power_links):
        var link: Dictionary = _power_links[link_id]
        var downstream: String = String(link.get("downstream_component_id", ""))
        if not downstream.is_empty():
            _power_parent_link[downstream] = link_id

func _rebuild_water_parent_index() -> void:
    _water_parent_link.clear()
    for link_id: String in _sorted_keys(_water_links):
        var link: Dictionary = _water_links[link_id]
        var downstream: String = String(link.get("downstream_component_id", ""))
        if not downstream.is_empty():
            _water_parent_link[downstream] = link_id

func _validate_power_topology(components: Dictionary, links: Dictionary, bindings: Dictionary) -> bool:
    if components.is_empty() or links.is_empty() or bindings.is_empty():
        return false
    var parents: Dictionary = {}
    for value: Variant in components.values():
        var component: Dictionary = value
        if not _valid_state(StringName(component.get("operational_state", &""))):
            return false
    for value: Variant in links.values():
        var link: Dictionary = value
        var up: String = String(link.get("upstream_component_id", ""))
        var down: String = String(link.get("downstream_component_id", ""))
        if up.is_empty() or down.is_empty() or up == down or not components.has(up) or not components.has(down) \
            or parents.has(down) or not _valid_state(StringName(link.get("operational_state", &""))):
            return false
        parents[down] = String(link.get("link_id", ""))
    for value: Variant in bindings.values():
        var terminal: String = String((value as Dictionary).get("terminal_component_id", ""))
        if terminal.is_empty() or not components.has(terminal) \
            or not _chain_reaches_role(terminal, components, links, parents, [&"source"]):
            return false
    return true

func _validate_water_topology(
    components: Dictionary,
    links: Dictionary,
    bindings: Dictionary,
    power_bindings: Dictionary
) -> bool:
    if components.is_empty() or links.is_empty() or bindings.is_empty() or power_bindings.is_empty():
        return false
    var parents: Dictionary = {}
    for value: Variant in components.values():
        var component: Dictionary = value
        if not _valid_state(StringName(component.get("operational_state", &""))):
            return false
        var required_power: String = String(component.get("required_power_service_id", ""))
        if not required_power.is_empty() and not power_bindings.has(required_power):
            return false
    for value: Variant in links.values():
        var link: Dictionary = value
        var up: String = String(link.get("upstream_component_id", ""))
        var down: String = String(link.get("downstream_component_id", ""))
        if up.is_empty() or down.is_empty() or up == down or not components.has(up) or not components.has(down) \
            or parents.has(down) or not _valid_state(StringName(link.get("operational_state", &""))):
            return false
        parents[down] = String(link.get("link_id", ""))
    for value: Variant in bindings.values():
        var terminal: String = String((value as Dictionary).get("terminal_component_id", ""))
        if terminal.is_empty() or not components.has(terminal) \
            or not _chain_reaches_role(terminal, components, links, parents, [&"source", &"well"]):
            return false
    return true

func _chain_reaches_role(
    start: String,
    components: Dictionary,
    links: Dictionary,
    parents: Dictionary,
    source_roles: Array
) -> bool:
    var current: String = start
    var visited: Dictionary = {}
    while not current.is_empty():
        if visited.has(current) or not components.has(current):
            return false
        visited[current] = true
        var role: StringName = StringName((components[current] as Dictionary).get("role", &""))
        if source_roles.has(role):
            return true
        if not parents.has(current):
            return false
        var link: Dictionary = links.get(String(parents[current]), {})
        current = String(link.get("upstream_component_id", ""))
    return false

func _records_snapshot(records: Dictionary) -> Array:
    var result: Array = []
    for key: String in _sorted_keys(records):
        result.append((records[key] as Dictionary).duplicate(true))
    return result

func _records_from_snapshot(value: Variant, id_field: String, allow_empty: bool = false) -> Dictionary:
    var result: Dictionary = {}
    if typeof(value) != TYPE_ARRAY:
        return result
    for entry_value: Variant in value:
        if typeof(entry_value) != TYPE_DICTIONARY:
            return {}
        var entry: Dictionary = (entry_value as Dictionary).duplicate(true)
        var id: String = String(entry.get(id_field, ""))
        if id.is_empty() or result.has(id):
            return {}
        result[id] = entry
    if result.is_empty() and not allow_empty and not (value as Array).is_empty():
        return {}
    return result

func _valid_state(state: StringName) -> bool:
    return VALID_STATES.has(state)

func _sorted_keys(records: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for key: Variant in records.keys():
        result.append(String(key))
    result.sort()
    return result

func _clear_all() -> void:
    _initialized = false
    _power_components.clear()
    _power_links.clear()
    _power_bindings.clear()
    _power_service_by_settlement.clear()
    _power_parent_link.clear()
    _power_branch_by_service.clear()
    _water_components.clear()
    _water_links.clear()
    _water_bindings.clear()
    _water_service_by_settlement.clear()
    _water_parent_link.clear()
    _water_local_by_service.clear()
    _appliances.clear()
    _power_cache.clear()
    _water_cache.clear()
