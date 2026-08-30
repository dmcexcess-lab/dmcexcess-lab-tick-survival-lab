extends UtilityRuntimeState
class_name NeighborhoodUtilityRuntimeState

var _local_power_topology: Dictionary = {}

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

        # This is deliberately causal but not physicalized. The regional source powers each
        # local substation without inventing a cross-island overhead feeder presentation.
        _insert_power_link(
            "power.link.regional_to.%s" % service_key,
            ingress_id,
            substation_component_id,
            service_key
        )
        _insert_power_link(
            "power.link.substation_to.%s" % service_key,
            substation_component_id,
            feeder_component_id,
            service_key
        )
        _insert_power_link(
            "power.link.feeder_to.%s" % service_key,
            feeder_component_id,
            terminal_component_id,
            service_key
        )

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
