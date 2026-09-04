extends CraftingGameMain
class_name UtilityGameMain

const PowerTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd")
const UtilityLightingClass = preload("res://scripts/simulation/utilities/UtilityPoweredLightingSourceAdapter.gd")
const PowerInfrastructureClass = preload("res://scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd")
const PowerNetworkRuntimeClass = preload("res://scripts/simulation/utilities/UtilityPowerNetworkRuntime.gd")
const RefrigerationProviderClass = preload("res://scripts/simulation/utilities/UtilityRefrigerationEnvironmentProvider.gd")
const FlashlightStateClass = preload("res://scripts/simulation/items/lighting/FlashlightItemState.gd")
const FlashlightActionClass = preload("res://scripts/simulation/items/lighting/FlashlightToggleActionService.gd")

const CENTRAL_SETTLEMENT_ID: String = "settlement.rural.crossroads.001"
const INVALID_UTILITY_CELL := Vector2i(2147483647, 2147483647)
const COLD_CONTAINER_TYPES: Array[StringName] = [
    &"prop.refrigerator_white",
    &"prop.walkin_cooler",
    &"prop.chest_freezer",
]

var _utilities: UtilityRuntimeState = null
var _utility_lighting: UtilityPoweredLightingSourceAdapter = null
var _power_infrastructure: UtilityPowerInfrastructureMaterializer = null
var _power_network: UtilityPowerNetworkRuntime = null
var _flashlight_state: FlashlightItemState = null
var _flashlight_actions: FlashlightToggleActionService = null
var _local_power_topology: Dictionary = {}
var _refrigeration_providers: Dictionary = {}
var _central_power_service_id: String = ""
var _central_water_service_id: String = ""
var _central_refrigerator_id: String = ""

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    return _boot_utility_runtime()

func _boot_utility_runtime() -> bool:
    var plan: GeneratedGlobalWorldPlan = GeneratedIslandCritiqueFixture.global_plan()
    _local_power_topology = PowerTopologyPlannerClass.new().plan(plan)
    if not bool(_local_power_topology.get("ok", false)):
        push_error("UtilityGameMain: local power topology failed: %s" % String(_local_power_topology.get("failure_reason", "unknown")))
        return false
    _utilities = UtilityStateClass.new(_local_power_topology)
    if not _utilities.initialize_from_plan(plan):
        return false

    _central_power_service_id = _utilities.power_service_for_settlement(CENTRAL_SETTLEMENT_ID)
    _central_water_service_id = _utilities.water_service_for_settlement(CENTRAL_SETTLEMENT_ID)
    if _central_power_service_id.is_empty() or _central_water_service_id.is_empty():
        return false

    if not _wire_power_infrastructure(plan):
        return false
    if not _wire_flashlight_items():
        return false
    if not _wire_utility_lighting():
        return false
    if not _wire_refrigeration():
        return false

    var power_callable := Callable(self, "_on_utility_power_changed")
    var appliance_callable := Callable(self, "_on_utility_appliances_changed")
    if not _utilities.power_changed.is_connected(power_callable):
        _utilities.power_changed.connect(power_callable)
    if not _utilities.appliances_changed.is_connected(appliance_callable):
        _utilities.appliances_changed.connect(appliance_callable)
    var containment_callable := Callable(self, "_on_utility_item_containment_changed")
    if not _inventory_state.item_containment_changed.is_connected(containment_callable):
        _inventory_state.item_containment_changed.connect(containment_callable)
    var tick_callable := Callable(self, "_on_power_network_tick_advanced")
    if not _kernel.world_tick_advanced.is_connected(tick_callable):
        _kernel.world_tick_advanced.connect(tick_callable)
    return true

func _wire_power_infrastructure(plan: GeneratedGlobalWorldPlan) -> bool:
    if plan == null or _collision_catalog == null or _world_view == null or _world_mutations == null:
        return false
    for semantic_type: StringName in PowerInfrastructureClass.LOCAL_COLLISION_SEMANTICS:
        if not _collision_catalog.register(semantic_type, true):
            return false
    _power_infrastructure = PowerInfrastructureClass.new(
        _world,
        _world_mutations,
        plan,
        _utilities,
        _local_power_topology
    )
    if not _power_infrastructure.materialize():
        return false
    _power_network = PowerNetworkRuntimeClass.new()
    if not _power_network.initialize(_utilities, _power_infrastructure.wire_edges(), Callable(_kernel, "world_tick")):
        return false
    var snapped_callable := Callable(self, "_on_power_line_snapped")
    if not _power_network.line_snapped.is_connected(snapped_callable):
        _power_network.line_snapped.connect(snapped_callable)
    # Presentation receives the same physical local-distribution projection regardless of energized
    # or failed state. The regional source-to-substation relationship is intentionally logical only.
    return _world_view.configure_power_infrastructure(_world, _power_infrastructure.wire_edges())

func damage_power_infrastructure(asset_id: String, damage: int, source_kind: StringName = &"direct") -> bool:
    return _power_network != null and _power_network.damage_asset(asset_id, damage, source_kind)

## Low-level owner seam. Player-facing repair must supply real tools/materials and WHEN before
## invoking this mutation; the only canonical competence vocabulary here is Mechanical.
func repair_power_infrastructure(asset_id: String, mechanical_skill: int, available_material_units: int) -> Dictionary:
    if _power_network == null:
        return {"ok": false, "material_units_consumed": 0, "reason": &"power_network_unavailable"}
    return _power_network.repair_asset(asset_id, mechanical_skill, available_material_units)

func power_infrastructure_repair_requirements(asset_id: String) -> Dictionary:
    if _power_network == null:
        return {}
    return _power_network.repair_requirements(asset_id)

func power_infrastructure_asset_ids(kind: StringName = &"") -> Array[String]:
    if _power_network == null:
        return []
    return _power_network.asset_ids(kind)

func damage_water_infrastructure(asset_id: String, damage: int, reason: StringName = &"physical_water_asset_damage") -> bool:
    return _utilities is NeighborhoodUtilityRuntimeState \
        and (_utilities as NeighborhoodUtilityRuntimeState).damage_water_asset(asset_id, damage, reason)

func repair_water_infrastructure(asset_id: String, available_material_units: int) -> Dictionary:
    if not (_utilities is NeighborhoodUtilityRuntimeState):
        return {"ok": false, "material_units_consumed": 0, "reason": &"water_network_unavailable"}
    return (_utilities as NeighborhoodUtilityRuntimeState).repair_water_asset(asset_id, available_material_units)

func water_infrastructure_asset_ids(kind: StringName = &"") -> Array[String]:
    if not (_utilities is NeighborhoodUtilityRuntimeState):
        return []
    return (_utilities as NeighborhoodUtilityRuntimeState).water_asset_ids(kind)

func power_infrastructure_debug_snapshot() -> Dictionary:
    return {
        "topology": {
            "building_count": int(_local_power_topology.get("building_count", 0)),
            "substation_count": (_local_power_topology.get("substations", []) as Array).size(),
            "target_buildings_per_substation": int(_local_power_topology.get("target_buildings_per_substation", 0)),
            "rural_home_count": int(_local_power_topology.get("rural_home_count", 0)),
            "well_count": (_local_power_topology.get("wells", []) as Array).size(),
        },
        "distribution": {} if _power_infrastructure == null else _power_infrastructure.debug_snapshot(),
        "network": {} if _power_network == null else _power_network.debug_snapshot(),
    }

func _on_power_network_tick_advanced(_previous_tick: int, new_tick: int) -> void:
    if _power_network != null:
        _power_network.advance_to_tick(new_tick)

func _on_power_line_snapped(_asset_id: String, cell: Vector2i) -> void:
    if _spatial_sound == null or cell == INVALID_UTILITY_CELL or not _world.has_terrain(cell):
        return
    _spatial_sound.emit_sound(
        SoundProfilesClass.POWER_LINE_SNAP,
        cell,
        "",
        "utility.power_line_snap"
    )

func _wire_flashlight_items() -> bool:
    if _world == null or _hand_state == null or _kernel == null or _shell == null:
        return false
    _flashlight_state = FlashlightStateClass.new()
    _flashlight_actions = FlashlightActionClass.new(_world, _hand_state, _flashlight_state, _kernel)
    if not _flashlight_actions.is_ready():
        return false
    if not _shell.has_method("configure_flashlight_actions"):
        return false
    return bool(_shell.call("configure_flashlight_actions", _flashlight_actions))

func _wire_utility_lighting() -> bool:
    if _physical_lighting == null or _hand_state == null or _flashlight_state == null:
        return false
    _utility_lighting = UtilityLightingClass.new(
        _world,
        _hand_state,
        FixtureClass.PLAYER_ID,
        _utilities,
        _kernel,
        _flashlight_state
    )
    if not _utility_lighting.is_ready():
        return false
    if not _physical_lighting.set_emitters(_utility_lighting.emitters()):
        return false
    var lighting_callable := Callable(self, "_on_lighting_emitters_changed")
    if not _utility_lighting.emitters_changed.is_connected(lighting_callable):
        _utility_lighting.emitters_changed.connect(lighting_callable)
    return true

func _wire_refrigeration() -> bool:
    if _freshness_mutations == null or _freshness_query == null or _inventory_state == null:
        return false
    for container_id: String in _inventory_state.container_ids():
        if not _world.has_entity(container_id):
            continue
        var entity: WorldEntityRecord = _world.entity(container_id)
        if entity == null or not COLD_CONTAINER_TYPES.has(entity.semantic_type):
            continue
        var placement: WorldPlacement = _world.placement(container_id)
        if placement == null:
            continue
        var power_service_id: String = _utilities.power_service_for_cell(placement.anchor)
        if power_service_id.is_empty():
            continue
        if not _utilities.bind_appliance(container_id, &"refrigeration", power_service_id, container_id, true):
            return false
        var provider: UtilityRefrigerationEnvironmentProvider = RefrigerationProviderClass.new(
            _utilities,
            container_id,
            _kernel.world_tick()
        )
        if not provider.is_valid() \
            or not _freshness_mutations.register_provider(provider) \
            or not _freshness_query.register_provider(provider):
            return false
        _refrigeration_providers[container_id] = provider
        var appliance: Dictionary = _utilities.appliance_record(container_id)
        if _central_refrigerator_id.is_empty() \
            and String(appliance.get("power_service_id", "")) == _central_power_service_id:
            _central_refrigerator_id = container_id

    for refrigerator_id: String in _sorted_refrigerator_ids():
        var context_id: StringName = (_refrigeration_providers[refrigerator_id] as UtilityRefrigerationEnvironmentProvider).context_id()
        for item_id: String in _inventory_state.direct_contents(refrigerator_id):
            _reanchor_containment_subtree(item_id, context_id, {})
    return true

func _on_utility_power_changed(_revision: int, _reason: StringName) -> void:
    _sync_refrigeration_clocks()

func _on_utility_appliances_changed(_revision: int, _reason: StringName) -> void:
    _sync_refrigeration_clocks()

func _sync_refrigeration_clocks() -> void:
    var world_tick: int = _kernel.world_tick()
    for refrigerator_id: String in _sorted_refrigerator_ids():
        var provider: UtilityRefrigerationEnvironmentProvider = _refrigeration_providers[refrigerator_id]
        provider.sync_at_tick(world_tick)

func _on_utility_item_containment_changed(item_id: String, _previous_container_id: String, new_container_id: String) -> void:
    var context_id: StringName = _freshness_context_for_container(new_container_id)
    _reanchor_containment_subtree(item_id, context_id, {})

func _freshness_context_for_container(container_id: String) -> StringName:
    var current: String = container_id.strip_edges()
    var visited: Dictionary = {}
    while not current.is_empty() and not visited.has(current):
        visited[current] = true
        if _refrigeration_providers.has(current):
            return (_refrigeration_providers[current] as UtilityRefrigerationEnvironmentProvider).context_id()
        if not _inventory_state.is_contained(current):
            break
        current = _inventory_state.container_of(current)
    return &"ambient"

func _reanchor_containment_subtree(item_id: String, context_id: StringName, visited: Dictionary) -> void:
    var key: String = item_id.strip_edges()
    if key.is_empty() or visited.has(key):
        return
    visited[key] = true
    if _freshness_mutations.has_record(key):
        _freshness_mutations.reanchor(key, context_id, _kernel.world_tick())
    if not _inventory_state.has_container(key):
        return
    for child_id: String in _inventory_state.direct_contents(key):
        _reanchor_containment_subtree(child_id, context_id, visited)

func _sorted_refrigerator_ids() -> Array[String]:
    var result: Array[String] = []
    for key: Variant in _refrigeration_providers.keys():
        result.append(String(key))
    result.sort()
    return result
