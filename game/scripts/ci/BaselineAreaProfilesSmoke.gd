extends SceneTree

const RequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/areas/LocalAreaGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/areas/GeneratedAreaValidator.gd")
const AreaProfilesClass = preload("res://scripts/generation/areas/BaselineAreaProfileCatalog.gd")
const EnvironmentProfilesClass = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")
const BuildingGeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BuildingValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")

const BOUNDS := Rect2i(1000, 2000, 384, 384)

var failures: Array[String] = []

func _initialize() -> void:
    _test_environment_library()
    _test_area_library()
    if failures.is_empty():
        print("BASELINE_AREA_PROFILES_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("BASELINE_AREA_PROFILES_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_environment_library() -> void:
    var environments := EnvironmentProfilesClass.new()
    var art := ArtCatalogClass.new()
    var ids: Array[StringName] = environments.profile_ids()
    _check(ids.size() == 7, "environment library exposes seven baseline palettes")
    for environment_id: StringName in ids:
        var profile: Dictionary = environments.profile(environment_id)
        _check(not profile.is_empty(), "%s environment profile resolves" % String(environment_id))
        _check(int(profile.get("version", 0)) > 0, "%s environment profile is versioned" % String(environment_id))
        for key: String in ["base_ground", "road_ground", "road_surface_ground", "road_centerline_horizontal", "road_centerline_vertical", "local_road_ground", "driveway_ground", "field_ground"]:
            _check(art.resolve_ground(StringName(profile.get(key, &""))).is_found(), "%s %s ground semantic resolves" % [String(environment_id), key])
        for key: String in ["tree_semantics", "shrub_semantics", "rock_semantics"]:
            for prop_value: Variant in profile.get(key, []):
                _check(art.resolve_prop(StringName(prop_value)).is_found(), "%s %s prop semantic resolves" % [String(environment_id), String(prop_value)])
        for key: String in ["fence_semantic", "mailbox_semantic", "traffic_signal_semantic"]:
            _check(art.resolve_prop(StringName(profile.get(key, &""))).is_found(), "%s %s prop semantic resolves" % [String(environment_id), key])

func _test_area_library() -> void:
    var profiles := AreaProfilesClass.new()
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    var building_generator := BuildingGeneratorClass.new()
    var building_validator := BuildingValidatorClass.new()
    var profile_ids: Array[StringName] = profiles.profile_ids()
    _check(profile_ids.size() == 5, "baseline area library exposes five settlement morphologies")

    for profile_id: StringName in profile_ids:
        var profile: Dictionary = profiles.profile(profile_id)
        var environment_id: StringName = StringName(profile.get("recommended_environment", &""))
        var request: AreaGenerationRequest = _request_for(profile_id, environment_id, 64001)
        _check(request.is_valid(), "%s synthetic baseline request is valid" % String(profile_id))
        if not request.is_valid():
            continue
        var plan: GeneratedAreaPlan = generator.generate(request)
        _check(plan.is_generated(), "%s baseline area generates" % String(profile_id))
        if not plan.is_generated():
            push_error("BASELINE_AREA_PROFILE_GENERATION_FAILURE %s: %s" % [String(profile_id), plan.failure_reason])
            continue
        _check(bool(validator.validate(request, plan).get("ok", false)), "%s baseline area passes System 20 validation" % String(profile_id))
        _check(plan.area_profile_version == 1, "%s area profile records version 1" % String(profile_id))
        _check(plan.environment_profile_id == environment_id, "%s records its recommended environment" % String(profile_id))
        _check(_count_road_class(plan, &"local_town") == 4, "%s uses the shared four-street grid morphology" % String(profile_id))
        _check(plan.blocks.size() >= 2, "%s produces semantic blocks" % String(profile_id))
        _check(_count_land_use(plan, &"commercial_small") == int(profile.get("commercial_count", 0)), "%s hits commercial target" % String(profile_id))
        _check(_count_land_use(plan, &"residential") == int(profile.get("residential_count", 0)), "%s hits residential target" % String(profile_id))
        _check(_count_land_use(plan, &"civic") == int(profile.get("civic_count", 0)), "%s hits civic target" % String(profile_id))
        _check(_count_land_use(plan, &"industrial") == int(profile.get("industrial_count", 0)), "%s hits industrial target" % String(profile_id))
        var occupied_target: int = int(profile.get("commercial_count", 0)) + int(profile.get("residential_count", 0)) + int(profile.get("civic_count", 0)) + int(profile.get("industrial_count", 0))
        _check(plan.building_requests.size() == occupied_target, "%s occupies every baseline target with an actual building profile" % String(profile_id))
        _check(_all_buildings_validate(plan, building_generator, building_validator), "%s generated building requests all pass System 19" % String(profile_id))

        var replay: GeneratedAreaPlan = generator.generate(_request_for(profile_id, environment_id, 64001))
        _check(replay.is_generated() and replay.signature() == plan.signature(), "%s same-seed replay is deterministic" % String(profile_id))

func _request_for(profile_id: StringName, environment_id: StringName, seed: int) -> AreaGenerationRequest:
    var center_y: int = BOUNDS.position.y + BOUNDS.size.y / 2
    var start := Vector2i(BOUNDS.position.x, center_y)
    var finish := Vector2i(BOUNDS.position.x + BOUNDS.size.x - 1, center_y)
    var inherited_roads: Array[Dictionary] = [{
        "road_id": "road.baseline.primary",
        "road_class": &"primary",
        "start": start,
        "end": finish,
        "width": 5,
        "allowed_boundary_cells": [start, finish],
    }]
    return RequestClass.new(
        "area.baseline.%s" % String(profile_id).replace(".", "_"),
        seed,
        BOUNDS,
        profile_id,
        environment_id,
        inherited_roads
    )

func _all_buildings_validate(
    plan: GeneratedAreaPlan,
    building_generator: LocalBuildingGenerator,
    building_validator: GeneratedBuildingValidator
) -> bool:
    for building_request: BuildingGenerationRequest in plan.building_requests:
        var building_plan: GeneratedBuildingPlan = building_generator.generate(building_request)
        if not building_plan.is_generated() or not bool(building_validator.validate(building_plan).get("ok", false)):
            return false
    return true

func _count_road_class(plan: GeneratedAreaPlan, road_class: StringName) -> int:
    var count: int = 0
    for road: Dictionary in plan.roads:
        if StringName(road.get("road_class", &"")) == road_class:
            count += 1
    return count

func _count_land_use(plan: GeneratedAreaPlan, land_use: StringName) -> int:
    var count: int = 0
    for parcel: Dictionary in plan.parcels:
        if StringName(parcel.get("land_use", &"")) == land_use:
            count += 1
    return count

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
