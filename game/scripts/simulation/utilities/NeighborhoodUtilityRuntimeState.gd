extends UtilityRuntimeState
class_name NeighborhoodUtilityRuntimeState

const WATER_ASSET_FAILURE_THRESHOLD: int = 250
const WATER_ASSET_INITIAL_CONDITION: int = 1000
const WATER_ASSET_REPAIRED_CONDITION: int = 900
const WATER_ASSET_SCHEMA_VERSION: int = 1

var _local_power_topology: Dictionary = {}
var _well_service_by_building: Dictionary = {}
var _water_asset_conditions: Dictionary = {}
var _water_asset_components: Dictionary = {}
var _water_asset_kinds: Dictionary = {}
var _water_asset_power_services: Dictionary = {}

func _init(topology: Dictionary = {}) -> void:
    _local_power_topology = topology.duplicate(true)

func local_power_topology() -> Dictionary:
    return _local_power_topology.duplicate(true)

func power_service_for_building(building_id: String) -> String:
    if not bool(_local_power_topology.get("ok", false)):
        return ""
    var mapping: Dictionary = _local_power_topology.get("building_service", {})
    return String(mapping.get(building_id.strip_edges(), ""))

func power_substation_component_ids() -> Array[String]:
    var result: Array[String] = []
    for component_id: String in _sorted_keys(_power_components):
        if StringName((_power_components[component_id] as Dictionary).get("role", &"")) == &"substation":
            result.append(component_id)
    return result

func power_service_for_settlement(settlement_id: String) -> String:
    var key: String = settlement_id.strip_edges()
    var direct: String = super.power_service_for_settlement(key)
    if not direct.is_empty():
        return direct
    for service_id: String in _sorted_keys(_power_bindings):
        var binding: Dictionary = _power_bindings[service_id]
        for value: Variant in binding.get("settlement_ids", []):
            if String(value) == key:
                return service_id
    return ""

func power_service_for_cell(cell: Vector2i) -> String:
    for service_id: String in _sorted_keys(_power_bindings):
        var binding: Dictionary = _power_bindings[service_id]
        for value: Variant in binding.get("building_rects", []):
            var rect: Rect2i = value
            if rect.has_point(cell):
                return service_id

    var best_service: String = ""
    var best_distance: int = 2147483647
    for service_id: String in _sorted_keys(_power_bindings):
        var binding: Dictionary = _power_bindings[service_id]
        var substation_component_id: String = String(binding.get("substation_component_id", ""))
        var component: Dictionary = _power_components.get(substation_component_id, {})
        var service_cell: Vector2i = component.get("cell", INVALID_CELL)
        if service_cell == INVALID_CELL:
            continue
        var distance: int = absi(cell.x - service_cell.x) + absi(cell.y - service_cell.y)
        if distance < best_distance or (distance == best_distance and (best_service.is_empty() or service_id < best_service)):
            best_service = service_id
            best_distance = distance
    return best_service

func power_scope_for_cell(cell: Vector2i) -> String:
    for value: Variant in _local_power_topology.get("buildings", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var building: Dictionary = value
        var rect: Rect2i = building.get("rect", Rect2i())
        if rect.has_point(cell):
            return String(building.get("building_id", ""))
    return super.power_scope_for_cell(cell)

func water_service_for_cell(cell: Vector2i) -> String:
    var best_service: String = ""
    var best_distance: int = 2147483647
    for service_id: String in _sorted_keys(_water_bindings):
        var binding: Dictionary = _water_bindings[service_id]
        if StringName(binding.get("service_kind", &"")) != &"municipal" or not bool(binding.get("island_wide", false)):
            continue
        var service_cell: Vector2i = binding.get("service_cell", INVALID_CELL)
        if service_cell == INVALID_CELL:
            continue
        var distance: int = absi(cell.x - service_cell.x) + absi(cell.y - service_cell.y)
        if distance < best_distance or (distance == best_distance and (best_service.is_empty() or service_id < best_service)):
            best_service = service_id
            best_distance = distance
    return best_service

func well_service_for_building(building_id: String) -> String:
    return String(_well_service_by_building.get(building_id.strip_edges(), ""))

func water_service_for_building(building_id: String) -> String:
    var key: String = building_id.strip_edges()
    var well_service: String = well_service_for_building(key)
    if not well_service.is_empty() and water_service_available(well_service):
        return well_service
    for value: Variant in _local_power_topology.get("buildings", []):
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var building: Dictionary = value
        if String(building.get("building_id", "")) != key:
            continue
        return water_service_for_settlement(String(building.get("settlement_id", "")))
    return ""

func water_asset_ids(kind: StringName = &"") -> Array[String]:
    var result: Array[String] = []
    for asset_id: String in _sorted_keys(_water_asset_conditions):
        if String(kind).is_empty() or StringName(_water_asset_kinds.get(asset_id, &"")) == kind:
            result.append(asset_id)
    return result

func water_asset_record(asset_id: String) -> Dictionary:
    var key: String = asset_id.strip_edges()
    if not _water_asset_conditions.has(key):
        return {}
    var component_id: String = String(_water_asset_components.get(key, ""))
    var component: Dictionary = _water_components.get(component_id, {})
    return {
        "asset_id": key,
        "entity_id": key,
        "kind": StringName(_water_asset_kinds.get(key, &"")),
        "condition": int(_water_asset_conditions.get(key, 0)),
        "failure_threshold": WATER_ASSET_FAILURE_THRESHOLD,
        "component_id": component_id,
        "operational_state": StringName(component.get("operational_state", &"")),
        "required_power_service_id": String(_water_asset_power_services.get(key, "")),
    }

func damage_water_asset(asset_id: String, damage: int, reason: StringName = &"physical_water_asset_damage") -> bool:
    var key: String = asset_id.strip_edges()
    if not is_ready() or damage <= 0 or not _water_asset_conditions.has(key):
        return false
    var before: int = int(_water_asset_conditions[key])
    var after: int = clampi(before - damage, 0, 1000)
    if before == after:
        return true
    _water_asset_conditions[key] = after
    var component_id: String = String(_water_asset_components.get(key, ""))
    if component_id.is_empty():
        return false
    if after <= WATER_ASSET_FAILURE_THRESHOLD:
        return set_water_component_state(component_id, DAMAGED, reason)
    _mark_water_changed(reason)
    return true

func repair_water_asset(asset_id: String, available_material_units: int) -> Dictionary:
    var key: String = asset_id.strip_edges()
    if not is_ready() or not _water_asset_conditions.has(key):
        return {"ok": false, "material_units_consumed": 0, "reason": &"unknown_asset"}
    var kind: StringName = StringName(_water_asset_kinds.get(key, &""))
    var required_materials: int = 3 if kind == &"municipal_plant" else 1
    if available_material_units < required_materials:
        return {"ok": false, "material_units_consumed": 0, "reason": &"insufficient_materials"}
    _water_asset_conditions[key] = WATER_ASSET_REPAIRED_CONDITION
    var component_id: String = String(_water_asset_components.get(key, ""))
    if component_id.is_empty() or not set_water_component_state(component_id, OPERATIONAL, &"physical_water_asset_repair"):
        return {"ok": false, "material_units_consumed": 0, "reason": &"service_sync_failed"}
    return {
        "ok": true,
        "material_units_consumed": required_materials,
        "reason": &"repaired",
        "condition": WATER_ASSET_REPAIRED_CONDITION,
    }

func snapshot() -> Dictionary:
    var data: Dictionary = super.snapshot()
    if data.is_empty():
        return data
    var water_assets: Array = []
    for asset_id: String in water_asset_ids():
        water_assets.append(water_asset_record(asset_id))
    data["neighborhood_water_asset_schema_version"] = WATER_ASSET_SCHEMA_VERSION
    data["water_assets"] = water_assets
    return data

func restore_snapshot(data: Dictionary) -> bool:
    if int(data.get("neighborhood_water_asset_schema_version", -1)) != WATER_ASSET_SCHEMA_VERSION:
        return false
    var assets_value: Variant = data.get("water_assets", [])
    if typeof(assets_value) != TYPE_ARRAY:
        return false
    var restored_conditions: Dictionary = {}
    for value: Variant in assets_value:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var record: Dictionary = value
        var asset_id: String = String(record.get("asset_id", "")).strip_edges()
        if asset_id.is_empty() or not _water_asset_conditions.has(asset_id) or restored_conditions.has(asset_id):
            return false
        if StringName(record.get("kind", &"")) != StringName(_water_asset_kinds.get(asset_id, &"")):
            return false
        restored_conditions[asset_id] = clampi(int(record.get("condition", 0)), 0, 1000)
    if restored_conditions.size() != _water_asset_conditions.size():
        return false
    if not super.restore_snapshot(data):
        return false
    _water_asset_conditions = restored_conditions
    return true

func _materialize_power(plan: GeneratedGlobalWorldPlan) -> bool:
    if not bool(_local_power_topology.get("ok", false)):
        return false
    var substations_value: Variant = _local_power_topology.get("substations", [])
    if typeof(substations_value) != TYPE_ARRAY or (substations_value as Array).is_empty():
        return false

    var ingress_id: String = ""
    for node: Dictionary in plan.power_nodes:
        if StringName(node.get("kind", &"")) != &"regional_ingress":
            continue
        var planned_id: String = String(node.get("id", "")).strip_edges()
        if planned_id.is_empty() or not ingress_id.is_empty():
            return false
        ingress_id = "power.component.%s" % planned_id
        _power_components[ingress_id] = {
            "component_id": ingress_id,
            "role": &"source",
            "operational_state": OPERATIONAL,
            "planning_id": planned_id,
            "settlement_id": "",
            "cell": node.get("cell", INVALID_CELL),
        }
    if ingress_id.is_empty():
        return false

    var substations: Array = substations_value
    for value: Variant in substations:
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var substation: Dictionary = value
        var planning_id: String = String(substation.get("id", "")).strip_edges()
        var service_key: String = String(substation.get("service_key", "")).strip_edges()
        var service_id: String = String(substation.get("service_id", "")).strip_edges()
        var cell: Vector2i = substation.get("cell", INVALID_CELL)
        if planning_id.is_empty() or service_key.is_empty() or service_id.is_empty() or cell == INVALID_CELL \
            or _power_bindings.has(service_id):
            return false

        var substation_component_id: String = "power.component.%s" % planning_id
        var feeder_component_id: String = "power.component.feeder.%s" % service_key
        var terminal_component_id: String = "power.component.service.%s" % service_key
        _power_components[substation_component_id] = {
            "component_id": substation_component_id,
            "role": &"substation",
            "operational_state": OPERATIONAL,
            "planning_id": planning_id,
            "settlement_id": service_key,
            "cell": cell,
        }
        _power_components[feeder_component_id] = {
            "component_id": feeder_component_id,
            "role": &"feeder",
            "operational_state": OPERATIONAL,
            "planning_id": "derived:%s" % service_key,
            "settlement_id": service_key,
            "cell": cell,
        }
        _power_components[terminal_component_id] = {
            "component_id": terminal_component_id,
            "role": &"structure_service",
            "operational_state": OPERATIONAL,
            "planning_id": "derived:%s" % service_key,
            "settlement_id": service_key,
            "cell": cell,
        }
        _insert_power_link("power.link.regional_to.%s" % service_key, ingress_id, substation_component_id, service_key)
        _insert_power_link("power.link.substation_to.%s" % service_key, substation_component_id, feeder_component_id, service_key)
        _insert_power_link("power.link.feeder_to.%s" % service_key, feeder_component_id, terminal_component_id, service_key)

        var settlement_ids: Array = (substation.get("settlement_ids", []) as Array).duplicate()
        var building_ids: Array = (substation.get("building_ids", []) as Array).duplicate()
        var building_rects: Array = (substation.get("building_rects", []) as Array).duplicate()
        if building_ids.is_empty() or building_ids.size() != building_rects.size():
            return false
        _power_bindings[service_id] = {
            "service_id": service_id,
            "terminal_component_id": terminal_component_id,
            "substation_component_id": substation_component_id,
            "owner_entity_id": "",
            "settlement_id": service_key,
            "settlement_ids": settlement_ids,
            "building_ids": building_ids,
            "building_rects": building_rects,
        }
        _power_service_by_settlement[service_key] = service_id
        for settlement_value: Variant in settlement_ids:
            var settlement_id: String = String(settlement_value).strip_edges()
            if not settlement_id.is_empty() and not _power_service_by_settlement.has(settlement_id):
                _power_service_by_settlement[settlement_id] = service_id
        _power_branch_by_service[service_id] = feeder_component_id

    _rebuild_power_parent_index()
    return not _power_bindings.is_empty()

func _materialize_water(plan: GeneratedGlobalWorldPlan) -> bool:
    _well_service_by_building.clear()
    _water_asset_conditions.clear()
    _water_asset_components.clear()
    _water_asset_kinds.clear()
    _water_asset_power_services.clear()

    var planned_components: Dictionary = {}
    var source_component: String = ""
    var treatment_component: String = ""
    var anchor_component: String = ""
    var plant_id: String = ""
    var critical_asset_id: String = ""

    for node: Dictionary in plan.water_nodes:
        var planned_id: String = String(node.get("id", "")).strip_edges()
        var kind: StringName = StringName(node.get("kind", &""))
        if planned_id.is_empty() or planned_components.has(planned_id):
            return false
        var role: StringName = &""
        if kind == &"raw_water_source":
            role = &"source"
        elif kind == &"treatment_plant":
            role = &"treatment_storage"
        elif kind == &"island_service_anchor":
            role = &"distribution_header"
        else:
            return false
        var component_id: String = "water.component.%s" % planned_id
        var node_plant_id: String = String(node.get("plant_id", "")).strip_edges()
        if node_plant_id.is_empty():
            return false
        if plant_id.is_empty():
            plant_id = node_plant_id
        elif plant_id != node_plant_id:
            return false
        _water_components[component_id] = {
            "component_id": component_id,
            "role": role,
            "operational_state": OPERATIONAL,
            "required_power_service_id": "",
            "planning_id": planned_id,
            "plant_id": node_plant_id,
            "settlement_id": "",
            "cell": node.get("cell", INVALID_CELL),
        }
        planned_components[planned_id] = component_id
        if kind == &"raw_water_source":
            source_component = component_id
        elif kind == &"treatment_plant":
            treatment_component = component_id
            critical_asset_id = String(node.get("critical_asset_id", "")).strip_edges()
        else:
            anchor_component = component_id

    if source_component.is_empty() or treatment_component.is_empty() or anchor_component.is_empty() or critical_asset_id.is_empty():
        return false
    _insert_water_link("water.link.%s.source_to_treatment" % plant_id, source_component, treatment_component, "")
    _insert_water_link("water.link.%s.treatment_to_header" % plant_id, treatment_component, anchor_component, "")
    if not _register_water_asset(critical_asset_id, &"municipal_plant", treatment_component, ""):
        return false

    for service: Dictionary in plan.water_services:
        var service_id: String = String(service.get("id", "")).strip_edges()
        var settlement_id: String = String(service.get("settlement_id", "")).strip_edges()
        var service_cell: Vector2i = _settlement_center(plan.settlements, settlement_id)
        if service_id.is_empty() or settlement_id.is_empty() or service_cell == INVALID_CELL or _water_bindings.has(service_id):
            return false
        if StringName(service.get("service_mode", &"")) != &"island_wide_municipal" \
            or String(service.get("plant_id", "")) != plant_id \
            or String(service.get("critical_asset_id", "")) != critical_asset_id:
            return false
        _water_bindings[service_id] = {
            "service_id": service_id,
            "service_kind": &"municipal",
            "terminal_component_id": anchor_component,
            "treatment_component_id": treatment_component,
            "owner_entity_id": critical_asset_id,
            "settlement_id": settlement_id,
            "service_cell": service_cell,
            "plant_id": plant_id,
            "network_id": String(service.get("network_id", "")),
            "critical_asset_id": critical_asset_id,
            "required_power_service_id": "",
            "island_wide": true,
        }
        _water_service_by_settlement[settlement_id] = service_id
        _water_local_by_service[service_id] = anchor_component

    for value: Variant in _local_power_topology.get("wells", []):
        if typeof(value) != TYPE_DICTIONARY:
            return false
        var well: Dictionary = value
        var asset_id: String = String(well.get("asset_id", "")).strip_edges()
        var component_id: String = String(well.get("component_id", "")).strip_edges()
        var service_id: String = String(well.get("service_id", "")).strip_edges()
        var building_id: String = String(well.get("building_id", "")).strip_edges()
        var settlement_id: String = String(well.get("settlement_id", "")).strip_edges()
        var power_service_id: String = String(well.get("power_service_id", "")).strip_edges()
        if asset_id.is_empty() or component_id.is_empty() or service_id.is_empty() or building_id.is_empty() \
            or power_service_id.is_empty() or not _power_bindings.has(power_service_id) \
            or _water_components.has(component_id) or _water_bindings.has(service_id) \
            or _well_service_by_building.has(building_id):
            return false
        _water_components[component_id] = {
            "component_id": component_id,
            "role": &"source",
            "operational_state": OPERATIONAL,
            "required_power_service_id": power_service_id,
            "planning_id": "derived:%s" % building_id,
            "plant_id": "",
            "settlement_id": settlement_id,
            "cell": well.get("cell", INVALID_CELL),
        }
        _water_bindings[service_id] = {
            "service_id": service_id,
            "service_kind": &"well",
            "terminal_component_id": component_id,
            "treatment_component_id": component_id,
            "owner_entity_id": asset_id,
            "settlement_id": settlement_id,
            "building_id": building_id,
            "plant_id": "",
            "network_id": "water.network.private_well",
            "critical_asset_id": asset_id,
            "required_power_service_id": power_service_id,
            "island_wide": false,
        }
        _well_service_by_building[building_id] = service_id
        _water_local_by_service[service_id] = component_id
        if not _register_water_asset(asset_id, &"well", component_id, power_service_id):
            return false

    _rebuild_water_parent_index()
    return not _water_service_by_settlement.is_empty() and _water_asset_conditions.has(critical_asset_id)

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
        var binding: Dictionary = value
        var terminal: String = String(binding.get("terminal_component_id", ""))
        var service_kind: StringName = StringName(binding.get("service_kind", &""))
        if terminal.is_empty() or not components.has(terminal) \
            or not [&"municipal", &"well"].has(service_kind) \
            or not _chain_reaches_role(terminal, components, links, parents, [&"source"]):
            return false
        if service_kind == &"municipal":
            if not bool(binding.get("island_wide", false)) \
                or binding.get("service_cell", INVALID_CELL) == INVALID_CELL \
                or not String(binding.get("required_power_service_id", "")).is_empty():
                return false
        else:
            if String(binding.get("building_id", "")).is_empty() or String(binding.get("required_power_service_id", "")).is_empty():
                return false
    return true

func _settlement_center(settlements: Array[Dictionary], settlement_id: String) -> Vector2i:
    for settlement: Dictionary in settlements:
        if String(settlement.get("id", "")) == settlement_id:
            return settlement.get("center", INVALID_CELL)
    return INVALID_CELL

func _register_water_asset(asset_id: String, kind: StringName, component_id: String, power_service_id: String) -> bool:
    var key: String = asset_id.strip_edges()
    if key.is_empty() or _water_asset_conditions.has(key) or not _water_components.has(component_id):
        return false
    _water_asset_conditions[key] = WATER_ASSET_INITIAL_CONDITION
    _water_asset_components[key] = component_id
    _water_asset_kinds[key] = kind
    _water_asset_power_services[key] = power_service_id.strip_edges()
    return true
