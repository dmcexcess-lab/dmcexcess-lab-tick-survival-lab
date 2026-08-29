extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")
const InfrastructureClass = preload("res://scripts/simulation/utilities/UtilityPowerInfrastructureMaterializer.gd")
const FacilityClass = preload("res://scripts/simulation/utilities/PowerFacilityMaterializer.gd")
const ConditionClass = preload("res://scripts/simulation/utilities/PowerInfrastructureConditionState.gd")
const IslandFixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_physical_causality_and_facilities()
    if _failures.is_empty():
        print("SYSTEM33_POWER_CAUSALITY_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SYSTEM33_POWER_CAUSALITY_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_physical_causality_and_facilities() -> void:
    var plan: GeneratedGlobalWorldPlan = IslandFixtureClass.generate_global_plan()
    _check(plan != null and plan.is_generated(), "procedural global plan generated")
    if plan == null or not plan.is_generated():
        return
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var utilities := UtilityStateClass.new()
    _check(utilities.initialize_from_plan(plan), "System 33 initialized")
    if not utilities.is_ready():
        return

    var infrastructure := InfrastructureClass.new(world, mutations, plan, utilities)
    _check(infrastructure.materialize(), "distribution infrastructure materialized")
    if infrastructure.wire_edges().is_empty():
        return

    var facilities := FacilityClass.new(world, mutations, plan, infrastructure.created_entity_ids())
    _check(facilities.materialize(), "real source/substation facilities materialized")
    if not facilities.materialize():
        return
    var facility_snapshot: Dictionary = facilities.debug_snapshot()
    _check(int(facility_snapshot.get("plant_area", 0)) >= 500, "power plant is a large physical facility")
    _check(int(facility_snapshot.get("plant_machine_count", 0)) >= 6, "power plant has multiple persistent critical machines")
    _check(int(facility_snapshot.get("substation_machine_count", 0)) >= 5, "substation has multiple persistent machines")
    _check(int(facility_snapshot.get("facility_wire_count", 0)) == 2, "plant and substation have physical grid ties")

    var condition := ConditionClass.new(plan, utilities)
    _check(condition.register_distribution_projection(infrastructure.wire_edges()), "distribution supports/spans enrolled in persistent condition")
    _check(condition.register_facility_assets(
        facilities.plant_machine_ids(),
        facilities.substation_machine_ids(),
        facilities.plant_tie_entity_ids(),
        facilities.substation_tie_entity_ids()
    ), "facility equipment enrolled in persistent condition")

    var distribution_snapshot: Dictionary = condition.debug_snapshot()
    var counts: Dictionary = distribution_snapshot.get("counts", {})
    _check(int(counts.get("distribution_support", 0)) > 0, "physical supports have condition truth")
    _check(int(counts.get("distribution_span", 0)) > 0, "physical wire spans have condition truth")
    _check(int(counts.get("plant_machine", 0)) >= 6, "plant machine condition truth exists")
    _check(int(counts.get("substation_machine", 0)) >= 5, "substation machine condition truth exists")

    var total_services: int = utilities.power_service_ids().size()
    var local_asset: String = ""
    var local_affected: Array[String] = []
    for span_id: String in condition.span_asset_ids():
        var affected: Array[String] = condition.affected_service_ids(span_id)
        if affected.size() > 0 and affected.size() < total_services:
            local_asset = span_id
            local_affected = affected
            break
    _check(not local_asset.is_empty(), "generated grid exposes a genuinely downstream distribution span")
    if not local_asset.is_empty():
        var unaffected: String = ""
        for service_id: String in utilities.power_service_ids():
            if not local_affected.has(service_id):
                unaffected = service_id
                break
        _check(condition.apply_damage(local_asset, 1000, &"vehicle"), "physical span can accumulate impact damage")
        for service_id: String in local_affected:
            _check(not utilities.power_service_available(service_id), "broken span blacks out its downstream service")
        _check(unaffected.is_empty() or utilities.power_service_available(unaffected), "unrelated branch remains powered")
        var line_requirements: Dictionary = condition.repair_requirements(local_asset)
        _check(int(line_requirements.get("electrical_skill", 99)) == 2, "distribution repair is low electrical tier")
        var line_repair: Dictionary = condition.repair_asset(local_asset, 2, 1)
        _check(bool(line_repair.get("ok", false)), "distribution span repair consumes its small material requirement")
        for service_id: String in local_affected:
            _check(utilities.power_service_available(service_id), "repair restores downstream service")

    var source_machine: String = facilities.plant_machine_ids()[0]
    var plant_requirements: Dictionary = condition.repair_requirements(source_machine)
    _check(int(plant_requirements.get("electrical_skill", 0)) == 8 and int(plant_requirements.get("material_units", 0)) == 20, "plant repair is high-skill/high-material")
    _check(condition.apply_damage(source_machine, 1000, &"direct"), "plant machine can fail")
    for service_id: String in utilities.power_service_ids():
        _check(not utilities.power_service_available(service_id), "plant failure blacks out entire generated grid")
    _check(not bool(condition.repair_asset(source_machine, 7, 100).get("ok", false)), "plant rejects under-skilled repair")
    _check(bool(condition.repair_asset(source_machine, 8, 20).get("ok", false)), "qualified costly plant repair succeeds")
    for service_id: String in utilities.power_service_ids():
        _check(utilities.power_service_available(service_id), "plant repair restores grid")

    var substation_machine: String = facilities.substation_machine_ids()[0]
    var sub_requirements: Dictionary = condition.repair_requirements(substation_machine)
    _check(int(sub_requirements.get("electrical_skill", 0)) == 5 and int(sub_requirements.get("material_units", 0)) == 8, "substation repair is intermediate specialist tier")
    _check(condition.apply_damage(substation_machine, 1000, &"direct"), "substation machine can fail")
    for service_id: String in utilities.power_service_ids():
        _check(not utilities.power_service_available(service_id), "substation failure interrupts downstream distribution")
    _check(bool(condition.repair_asset(substation_machine, 5, 8).get("ok", false)), "substation repair restores shared distribution")

    var support_id: String = condition.asset_ids(ConditionClass.DISTRIBUTION_SUPPORT)[0]
    var support_before: int = int(condition.asset_record(support_id).get("condition", 0))
    _check(condition.advance_to_day(1), "first day preserves maintenance grace")
    _check(int(condition.asset_record(support_id).get("condition", 0)) == support_before, "distribution has one-day initial grace")
    _check(condition.advance_to_day(2), "second day advances deterministic passive wear")
    _check(int(condition.asset_record(support_id).get("condition", 0)) < support_before, "distribution begins degrading without maintenance after day one")

    var plant_before: int = int(condition.asset_record(source_machine).get("condition", 0))
    _check(condition.advance_to_day(6), "longer maintenance clock advances")
    _check(int(condition.asset_record(source_machine).get("condition", 0)) == plant_before, "plant machinery does not wear on distribution timescale")

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
