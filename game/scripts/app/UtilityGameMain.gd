extends CraftingGameMain
class_name UtilityGameMain

const UtilityStateClass = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")
const UtilityLightingClass = preload("res://scripts/simulation/utilities/UtilityPoweredLightingSourceAdapter.gd")
const PowerInfrastructureClass = preload("res://scripts/simulation/utilities/UtilityPowerInfrastructureMaterializer.gd")
const PowerFacilityClass = preload("res://scripts/simulation/utilities/PowerFacilityMaterializer.gd")
const PowerConditionClass = preload("res://scripts/simulation/utilities/PowerInfrastructureConditionState.gd")
const RefrigerationProviderClass = preload("res://scripts/simulation/utilities/UtilityRefrigerationEnvironmentProvider.gd")
const UtilityControlsClass = preload("res://scripts/ui/UtilityDevControls.gd")

const CENTRAL_SETTLEMENT_ID: String = "settlement.rural.crossroads.001"
const COLD_CONTAINER_TYPES: Array[StringName] = [
    &"prop.refrigerator_white",
    &"prop.walkin_cooler",
    &"prop.chest_freezer",
]

var _utilities: UtilityRuntimeState = null
var _utility_lighting: UtilityPoweredLightingSourceAdapter = null
var _power_infrastructure: UtilityPowerInfrastructureMaterializer = null
var _power_facilities: PowerFacilityMaterializer = null
var _power_condition: PowerInfrastructureConditionState = null
var _refrigeration_providers: Dictionary = {}
var _utility_controls: UtilityDevControls = null
var _central_power_service_id: String = ""
var _central_water_service_id: String = ""
var _central_refrigerator_id: String = ""

func _boot_canonical_demo() -> bool:
    if not super._boot_canonical_demo():
        return false
    return _boot_utility_runtime()

func _boot_utility_runtime() -> bool:
    # GeneratedIslandCritiqueFixture is the legacy composition name; global_plan() is the live
    # procedurally generated 00D world for this new game, not a canned electrical fixture.
    var plan: GeneratedGlobalWorldPlan = GeneratedIslandCritiqueFixture.global_plan()
    _utilities = UtilityStateClass.new()
    if not _utilities.initialize_from_plan(plan):
        return false

    _central_power_service_id = _utilities.power_service_for_settlement(CENTRAL_SETTLEMENT_ID)
    _central_water_service_id = _utilities.water_service_for_settlement(CENTRAL_SETTLEMENT_ID)
    if _central_power_service_id.is_empty() or _central_water_service_id.is_empty():
        return false

    if not _wire_power_infrastructure(plan):
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
    var tick_callable := Callable(self, "_on_power_infrastructure_tick_advanced")
    if not _kernel.world_tick_advanced.is_connected(tick_callable):
        _kernel.world_tick_advanced.connect(tick_callable)
    if not _power_condition.advance_to_tick(_kernel.world_tick()):
        return false

    _utility_controls = UtilityControlsClass.new()
    add_child(_utility_controls)
    if not _utility_controls.configure(
        _utilities,
        _central_power_service_id,
        _central_water_service_id,
        _central_refrigerator_id
    ):
        return false
    return true

func _wire_power_infrastructure(plan: GeneratedGlobalWorldPlan) -> bool:
    if plan == null or _collision_catalog == null or _world_view == null or _world_mutations == null:
        return false
    for semantic_type: StringName in PowerInfrastructureClass.COLLISION_SEMANTICS:
        if not _collision_catalog.register(semantic_type, true):
            return false
    if not _collision_catalog.register(&"prop.chainlink_fence", true):
        return false

    _power_infrastructure = PowerInfrastructureClass.new(
        _world,
        _world_mutations,
        plan,
        _utilities
    )
    if not _power_infrastructure.materialize():
        return false

    _power_facilities = PowerFacilityClass.new(
        _world,
        _world_mutations,
        plan,
        _power_infrastructure.created_entity_ids()
    )
    if not _power_facilities.materialize():
        return false

    _power_condition = PowerConditionClass.new(plan, _utilities)
    if not _power_condition.is_ready() \
        or not _power_condition.register_distribution_projection(_power_infrastructure.wire_edges()) \
        or not _power_condition.register_facility_assets(
            _power_facilities.plant_machine_ids(),
            _power_facilities.substation_machine_ids(),
            _power_facilities.plant_tie_entity_ids(),
            _power_facilities.substation_tie_entity_ids()
        ):
        return false

    var all_wires: Array[Dictionary] = _power_infrastructure.wire_edges()
    for facility_wire: Dictionary in _power_facilities.wire_edges():
        all_wires.append(facility_wire)
    return _world_view.configure_power_infrastructure(_world, all_wires)

## Canonical seam for future vehicle/zombie/destruction systems. Physical WHAT entity ids are
## also condition asset ids for poles and facility machinery; distribution span ids are exposed
## by power_infrastructure_span_asset_ids().
func damage_power_infrastructure(asset_id: String, damage: int, source_kind: StringName = &"direct") -> bool:
    return _power_condition != null and _power_condition.apply_damage(asset_id, damage, source_kind)

func repair_power_infrastructure(asset_id: String, electrical_skill: int, available_material_units: int) -> Dictionary:
    if _power_condition == null:
        return {"ok": false, "material_units_consumed": 0, "reason": &"power_condition_unavailable"}
    return _power_condition.repair_asset(asset_id, electrical_skill, available_material_units)

func power_infrastructure_repair_requirements(asset_id: String) -> Dictionary:
    if _power_condition == null:
        return {}
    return _power_condition.repair_requirements(asset_id)

func power_infrastructure_span_asset_ids() -> Array[String]:
    if _power_condition == null:
        return []
    return _power_condition.span_asset_ids()

func power_infrastructure_debug_snapshot() -> Dictionary:
    return {
        "distribution": {} if _power_infrastructure == null else _power_infrastructure.debug_snapshot(),
        "facilities": {} if _power_facilities == null else _power_facilities.debug_snapshot(),
        "condition": {} if _power_condition == null else _power_condition.debug_snapshot(),
    }

func _on_power_infrastructure_tick_advanced(_previous_tick: int, new_tick: int) -> void:
    if _power_condition != null:
        _power_condition.advance_to_tick(new_tick)

func _wire_utility_lighting() -> bool:
    if _physical_lighting == null or _hand_state == null:
        return false
    var inherited_callable := Callable(self, "_on_demo_lighting_emitters_changed")
    if _demo_lighting_sources != null and _demo_lighting_sources.emitters_changed.is_connected(inherited_callable):
        _demo_lighting_sources.emitters_changed.disconnect(inherited_callable)
    _utility_lighting = UtilityLightingClass.new(
        _world,
        _hand_state,
        FixtureClass.PLAYER_ID,
        _utilities,
        _kernel
    )
    if not _utility_lighting.is_ready():
        return false
    if not _physical_lighting.set_emitters(_utility_lighting.emitters()):
        return false
    if not _utility_lighting.emitters_changed.is_connected(inherited_callable):
        _utility_lighting.emitters_changed.connect(inherited_callable)
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
