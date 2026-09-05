extends UtilityRuntimeState
class_name NeighborhoodUtilityRuntimeState

const WATER_ASSET_FAILURE_THRESHOLD: int = 250
const WATER_ASSET_INITIAL_CONDITION: int = 1000
const WATER_ASSET_REPAIRED_CONDITION: int = 900
const WATER_ASSET_SCHEMA_VERSION: int = 2

var _local_power_topology: Dictionary = {}
var _water_asset_conditions: Dictionary = {}
var _water_asset_components: Dictionary = {}
var _water_asset_kinds: Dictionary = {}

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

func water_service_for_settlement(settlement_id: String) -> String:
    var direct: String = super.water_service_for_settlement(settlement_id)
    if not direct.is_empty():
        return direct
    return _island_water_service_id()

func water_service_for_cell(_cell: Vector2i) -> String:
    return _island_water_service_id()

func well_service_for_building(_building_id: String) -> String:
    return ""

func water_service_for_building(building_id: String) -> String:
    var key: String = building_id.strip_edges()
    if key.is_empty():
        return ""
    for value: Variant in _local_power_topology.get("buildings", []):
        if typeof(value) == TYPE_DICTIONARY and String((value as Dictionary).get("building_id", "")) == key:
            return _island_water_service_id()
    return ""

func water_facility_building_id() -> String:
    var service_id: String = _island_water_service_id()
    if service_id.is_empty():
        return ""
    return String((_water_bindings.get(service_id, {}) as Dictionary).get("owner_entity_id", ""))

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
        "required_power_service_id": "",
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
    var required_materials: int = 3
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
    if int(data.get("neighborhood_water_asset_schema_version", -1)) != WATER_ASSET_SCHEMA_VERSION \
        or int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
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
        restored_conditions[asset_id] = clampi(int(record.get("condition", 0)), 0, 1000)
    if restored_conditions.size() != _water_asset_conditions.size():
        return false

    var pc: Dictionary = _records_from_snapshot(data.get("power_components", []), "component_id")
    var pl: Dictionary = _records_from_snapshot(data.get("power_links", []), "link_id")
    var pb: Dictionary = _records_from_snapshot(data.get("power_bindings", []), "service_id")
    var wc: Dictionary = _records_from_snapshot(data.get("water_components", []), "component_id")
    var wl: Dictionary = _records_from_snapshot(data.get("water_links", []), "link_id", true)
    var wb: Dictionary = _records_from_snapshot(data.get("water_bindings", []), "service_id")
    var appliances: Dictionary = _records_from_snapshot(data.get("appliances", []), "appliance_id", true)
    if pc.is_empty() or pl.is_empty() or pb.is_empty() or wc.is_empty() or wb.is_empty() or not wl.is_empty():
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
    _water_asset_conditions = restored_conditions
    utility_reset.emit()
    power_changed.emit(_power_revision, &"utility_restore")
    water_changed.emit(_water_revision, &"utility_restore")
    appliances_changed.emit(_appliance_revision, &"utility_restore")
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
    _water_asset_conditions.clear()
    _water_asset_components.clear()
    _water_asset_kinds.clear()
    if plan.water_services.is_empty() or not plan.water_nodes.is_empty() or not plan.water_segments.is_empty():
        return false
    var first_service: Dictionary = plan.water_services[0]
    var building: Dictionary = _resolve_facility_building(plan, first_service)
    if building.is_empty():
        return false
    var building_id: String = String(building.get("building_id", "")).strip_edges()
    var cell: Vector2i = building.get("cell", INVALID_CELL)
    var facility_id: String = String(first_service.get("facility_id", "")).strip_edges()
    if building_id.is_empty() or cell == INVALID_CELL or facility_id.is_empty():
        return false
    var component_id: String = "water.component.facility.%s" % building_id
    _water_components[component_id] = {
        "component_id": component_id,
        "role": &"source",
        "operational_state": OPERATIONAL,
        "required_power_service_id": "",
        "planning_id": facility_id,
        "plant_id": building_id,
        "settlement_id": String(first_service.get("host_settlement_id", "")),
        "cell": cell,
        "owner_entity_id": building_id,
    }
    for service: Dictionary in plan.water_services:
        var service_id: String = String(service.get("id", "")).strip_edges()
        var settlement_id: String = String(service.get("settlement_id", "")).strip_edges()
        if service_id.is_empty() or settlement_id.is_empty() or _water_bindings.has(service_id) \
            or String(service.get("facility_id", "")) != facility_id \
            or StringName(service.get("service_mode", &"")) != &"island_wide_municipal" \
            or not bool(service.get("island_wide", false)):
            return false
        _water_bindings[service_id] = {
            "service_id": service_id,
            "service_kind": &"municipal",
            "terminal_component_id": component_id,
            "treatment_component_id": component_id,
            "owner_entity_id": building_id,
            "settlement_id": settlement_id,
            "service_cell": cell,
            "plant_id": building_id,
            "network_id": "",
            "critical_asset_id": building_id,
            "required_power_service_id": "",
            "island_wide": true,
        }
        _water_service_by_settlement[settlement_id] = service_id
        _water_local_by_service[service_id] = component_id
    return _register_water_asset(building_id, &"municipal_plant", component_id)

func _validate_water_topology(
    components: Dictionary,
    links: Dictionary,
    bindings: Dictionary,
    _power_bindings_arg: Dictionary
) -> bool:
    if components.size() != 1 or not links.is_empty() or bindings.is_empty():
        return false
    var component: Dictionary = components.values()[0]
    var component_id: String = String(component.get("component_id", ""))
    if component_id.is_empty() or StringName(component.get("role", &"")) != &"source" \
        or not _valid_state(StringName(component.get("operational_state", &""))):
        return false
    var owner_id: String = ""
    for value: Variant in bindings.values():
        var binding: Dictionary = value
        var candidate_owner: String = String(binding.get("owner_entity_id", ""))
        if not bool(binding.get("island_wide", false)) \
            or StringName(binding.get("service_kind", &"")) != &"municipal" \
            or String(binding.get("terminal_component_id", "")) != component_id \
            or String(binding.get("treatment_component_id", "")) != component_id \
            or candidate_owner.is_empty() \
            or not String(binding.get("required_power_service_id", "")).is_empty():
            return false
        if owner_id.is_empty():
            owner_id = candidate_owner
        elif owner_id != candidate_owner:
            return false
    return true

func _resolve_facility_building(plan: GeneratedGlobalWorldPlan, service: Dictionary) -> Dictionary:
    var buildings_value: Variant = plan.local_area_manifest.get("buildings", [])
    if typeof(buildings_value) != TYPE_ARRAY:
        return {}
    var host_site_id: String = String(service.get("host_site_id", "")).strip_edges()
    var preferred: StringName = StringName(service.get("preferred_archetype_id", &""))
    var fallback: Dictionary = {}
    for value: Variant in buildings_value:
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var building: Dictionary = value
        if String(building.get("site_id", "")) != host_site_id:
            continue
        if fallback.is_empty():
            fallback = building
        if StringName(building.get("archetype_id", &"")) == preferred:
            return building
    return fallback

func _register_water_asset(asset_id: String, kind: StringName, component_id: String) -> bool:
    var key: String = asset_id.strip_edges()
    if key.is_empty() or _water_asset_conditions.has(key) or not _water_components.has(component_id):
        return false
    _water_asset_conditions[key] = WATER_ASSET_INITIAL_CONDITION
    _water_asset_components[key] = component_id
    _water_asset_kinds[key] = kind
    return true

func _island_water_service_id() -> String:
    for service_id: String in _sorted_keys(_water_bindings):
        if bool((_water_bindings[service_id] as Dictionary).get("island_wide", false)):
            return service_id
    return ""
