extends SceneTree

const GlobalFixtureClass = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const GlobalPlannerClass = preload("res://scripts/generation/world/GlobalWorldPlanner.gd")
const ProjectorClass = preload("res://scripts/generation/integration/System20AreaRequestProjector.gd")
const AreaRequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")

const SMALLTOWN_SITE_ID: String = "area.smalltown.center.001"

var failures: Array[String] = []

func _initialize() -> void:
    var global_plan: GeneratedGlobalWorldPlan = GlobalPlannerClass.new().generate(GlobalFixtureClass.request())
    _check(global_plan.is_generated(), "canonical rural plan generates before small-town projection")
    if not global_plan.is_generated():
        push_error("SMALLTOWN_GLOBAL_FAILURE: %s" % global_plan.failure_reason)
        _finish()
        return

    var projected: Dictionary = ProjectorClass.new().project_site(global_plan, SMALLTOWN_SITE_ID)
    _check(bool(projected.get("ok", false)), "smalltown.center projects from global facts")
    var request: AreaGenerationRequest = projected.get("request") as AreaGenerationRequest
    _check(request != null and request.is_valid(), "small-town request is valid")
    if request == null or not request.is_valid():
        _finish()
        return

    _check(request.area_profile_id == &"smalltown.center", "projected area profile is smalltown.center")
    _check(_constraint_count(request, &"potable_water", &"facility") == 0, "small town invents no local water plant")
    _check(_constraint_count(request, &"wastewater", &"facility") == 0, "small town carries no retired wastewater facility")

    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    var plan: GeneratedAreaPlan = generator.generate(request)
    _check(plan.is_generated(), "small-town center v3 generates")
    if not plan.is_generated():
        push_error("SMALLTOWN_PLAN_FAILURE: %s" % plan.failure_reason)
        _finish()
        return

    _check(bool(validator.validate(request, plan).get("ok", false)), "small town passes generic area validation")
    _check(plan.area_profile_version == 3, "smalltown.center v3 is recorded")
    _check(_count_land_use(plan, &"commercial_small") == 7, "small town has seven main-street civic/commercial lots")
    _check(_count_land_use(plan, &"residential") == 12, "small town has twelve clustered residential lots")
    _check(plan.building_requests.size() == 19, "all targeted small-town lots contain real generated buildings")
    for required: StringName in [
        &"commercial.gas_station.small",
        &"commercial.diner.rural_small",
        &"commercial.convenience_store.small",
        &"commercial.grocery.neighborhood",
        &"commercial.hardware_store.small",
        &"civic.post_office.small",
        &"civic.police_station.small",
    ]:
        _check(_count_building_archetype(plan, required) == 1, "small town contains %s" % String(required))
    _check(_count_residential_buildings(plan) == 12, "all twelve residential lots contain real homes")
    _check(_count_land_use_on_road_class(plan, &"residential", &"local_town") >= 7, "clustered homes use local-town neighborhood streets")

    var replay: GeneratedAreaPlan = generator.generate(_copy_request_with_seed(request, request.seed))
    _check(replay.is_generated() and replay.signature() == plan.signature(), "same small-town seed replays exactly")
    var changed: bool = false
    for offset: int in range(1, 5):
        var alternate: GeneratedAreaPlan = generator.generate(_copy_request_with_seed(request, request.seed + offset))
        _check(alternate.is_generated(), "alternate small-town seed %d generates" % (request.seed + offset))
        if alternate.is_generated() and alternate.signature() != plan.signature():
            changed = true
    _check(changed, "small-town morphology/content varies deterministically across seeds")
    _finish()

func _copy_request_with_seed(request: AreaGenerationRequest, seed: int) -> AreaGenerationRequest:
    return AreaRequestClass.new(
        request.area_id,
        seed,
        request.bounds,
        request.area_profile_id,
        request.environment_profile_id,
        request.inherited_roads,
        request.forbidden_regions,
        request.inherited_planning_constraints
    )

func _constraint_count(request: AreaGenerationRequest, domain: StringName, role: StringName) -> int:
    var count: int = 0
    for constraint: Dictionary in request.inherited_planning_constraints:
        if StringName(constraint.get("domain", &"")) == domain and StringName(constraint.get("reservation_role", &"")) == role:
            count += 1
    return count

func _count_land_use(plan: GeneratedAreaPlan, land_use: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == land_use:
            count += 1
    return count

func _count_land_use_on_road_class(plan: GeneratedAreaPlan, land_use: StringName, road_class: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == land_use and StringName(parcel.get("frontage_road_class", &"")) == road_class:
            count += 1
    return count

func _count_building_archetype(plan: GeneratedAreaPlan, archetype: StringName) -> int:
    var count: int = 0
    for request: BuildingGenerationRequest in plan.building_requests:
        if request.archetype_id == archetype:
            count += 1
    return count

func _count_residential_buildings(plan: GeneratedAreaPlan) -> int:
    var count: int = 0
    for request: BuildingGenerationRequest in plan.building_requests:
        if String(request.archetype_id).begins_with("residential."):
            count += 1
    return count

func _check(condition: bool, message: String) -> void:
    if condition:
        return
    failures.append(message)
    push_error("SMALLTOWN_CENTER_GENERATION_SMOKE_FAIL: %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("SMALLTOWN_CENTER_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("SMALLTOWN_CENTER_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)
