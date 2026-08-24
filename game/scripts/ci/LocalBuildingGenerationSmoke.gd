extends SceneTree

const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const ValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")
const BaselineProfilesClass = preload("res://scripts/generation/buildings/profiles/OneStoryBaselineProfileCatalog.gd")
const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")
const SmallFarmhouseClass = preload("res://scripts/generation/buildings/archetypes/FarmhouseBuildingGenerator.gd")
const LargeFarmhouseClass = preload("res://scripts/generation/buildings/archetypes/LargeFarmhouseBuildingGenerator.gd")
const CompactLaundryHouseClass = preload("res://scripts/generation/buildings/archetypes/CompactLaundryHouseBuildingGenerator.gd")
const GasStationClass = preload("res://scripts/generation/buildings/archetypes/GasStationBuildingGenerator.gd")
const DinerClass = preload("res://scripts/generation/buildings/archetypes/RuralDinerBuildingGenerator.gd")
const ArtCatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var generator := GeneratorClass.new()
    var validator := ValidatorClass.new()
    _test_protected_reference_library(generator, validator)
    _test_baseline_one_story_library(generator, validator)
    _test_multiunit_access_model(generator, validator)
    if failures.is_empty():
        print("LOCAL_BUILDING_GENERATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("LOCAL_BUILDING_GENERATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_protected_reference_library(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var expected: Array = [
        [TrailerClass.ARCHETYPE_ID, Vector2i(5, 12), Facing.Value.EAST, 2],
        [SmallFarmhouseClass.ARCHETYPE_ID, Vector2i(13, 9), Facing.Value.NORTH, 2],
        [LargeFarmhouseClass.ARCHETYPE_ID, Vector2i(21, 9), Facing.Value.NORTH, 4],
        [CompactLaundryHouseClass.ARCHETYPE_ID, Vector2i(17, 13), Facing.Value.SOUTH, 1],
        [GasStationClass.ARCHETYPE_ID, Vector2i(19, 15), Facing.Value.SOUTH, 1],
        [DinerClass.ARCHETYPE_ID, Vector2i(17, 11), Facing.Value.SOUTH, 2],
    ]
    _check(generator.supported_archetypes().size() == 24, "registry exposes six protected references plus eighteen baseline profiles")
    _check(generator.placement_descriptors().size() == 24, "every registered building exposes a placement descriptor")
    for row: Array in expected:
        var archetype_id: StringName = row[0]
        var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(archetype_id)
        _check(descriptor != null and descriptor.is_valid(), "%s protected descriptor remains valid" % String(archetype_id))
        if descriptor == null:
            continue
        _check(descriptor.canonical_size() == row[1], "%s canonical size is preserved" % String(archetype_id))
        _check(descriptor.canonical_frontage() == int(row[2]), "%s canonical frontage is preserved" % String(archetype_id))
        _check(descriptor.archetype_version() == int(row[3]), "%s version is preserved" % String(archetype_id))
        _check(descriptor.supported_orientations().size() == 4, "%s still supports all cardinal rotations" % String(archetype_id))
        for orientation: int in [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]:
            var size: Vector2i = descriptor.required_size(orientation)
            var frontage: int = descriptor.frontage_for_orientation(orientation)
            var request := RequestClass.new(
                "building.smoke.protected.%s.%d" % [String(archetype_id).replace(".", "_"), orientation],
                archetype_id,
                77100 + orientation,
                Rect2i(Vector2i(100, 100), size),
                orientation,
                frontage
            )
            var plan: GeneratedBuildingPlan = generator.generate(request)
            _check(plan.is_generated(), "%s rotation %d still generates" % [String(archetype_id), orientation])
            if plan.is_generated():
                var validation: Dictionary = validator.validate(plan)
                _check(bool(validation.get("ok", false)), "%s rotation %d still validates%s" % [String(archetype_id), orientation, _validation_suffix(validation)])

func _test_baseline_one_story_library(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var catalog := BaselineProfilesClass.new()
    var art := ArtCatalogClass.new()
    var profile_ids: Array[StringName] = catalog.profile_ids()
    _check(profile_ids.size() == 18, "baseline building library contains eighteen one-story profiles")
    for profile_id: StringName in profile_ids:
        var profile: Dictionary = catalog.profile(profile_id)
        _check(not profile.is_empty(), "%s profile resolves" % String(profile_id))
        _check(int(profile.get("story_count", 0)) == 1, "%s is explicitly one story" % String(profile_id))
        _check(int(profile.get("version", 0)) == 1, "%s starts at profile version 1" % String(profile_id))
        var rooms: Array = profile.get("rooms", [])
        _check(rooms.size() >= 3, "%s has a real multi-room floor plan" % String(profile_id))
        for room_value: Variant in rooms:
            var room: Dictionary = room_value
            var purpose: String = String(room.get("purpose", "")).to_lower()
            _check(not purpose.contains("stair") and not purpose.contains("elevator"), "%s contains no fake multi-story circulation" % String(profile_id))

        var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(profile_id)
        _check(descriptor != null and descriptor.is_valid(), "%s exposes a valid placement descriptor" % String(profile_id))
        if descriptor == null:
            continue
        _check(descriptor.archetype_version() == 1, "%s descriptor reports version 1" % String(profile_id))
        _check(descriptor.supported_orientations().size() == 4, "%s supports all four rotations" % String(profile_id))

        var north_size: Vector2i = descriptor.required_size(Facing.Value.NORTH)
        var north_frontage: int = descriptor.frontage_for_orientation(Facing.Value.NORTH)
        var replay_request := RequestClass.new(
            "building.smoke.baseline.replay.%s" % String(profile_id).replace(".", "_"),
            profile_id,
            88001,
            Rect2i(Vector2i(200, 220), north_size),
            Facing.Value.NORTH,
            north_frontage
        )
        var plan_a: GeneratedBuildingPlan = generator.generate(replay_request)
        var plan_b: GeneratedBuildingPlan = generator.generate(replay_request)
        _check(plan_a.is_generated() and plan_a.signature() == plan_b.signature(), "%s deterministic replay is stable" % String(profile_id))

        for orientation: int in [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]:
            var size: Vector2i = descriptor.required_size(orientation)
            var frontage: int = descriptor.frontage_for_orientation(orientation)
            var request := RequestClass.new(
                "building.smoke.baseline.%s.%d" % [String(profile_id).replace(".", "_"), orientation],
                profile_id,
                88020 + orientation,
                Rect2i(Vector2i(300, 340), size),
                orientation,
                frontage
            )
            var plan: GeneratedBuildingPlan = generator.generate(request)
            _check(plan.is_generated(), "%s rotation %d generates" % [String(profile_id), orientation])
            if not plan.is_generated():
                continue
            var validation: Dictionary = validator.validate(plan)
            _check(bool(validation.get("ok", false)), "%s rotation %d validates%s" % [String(profile_id), orientation, _validation_suffix(validation)])
            _check(_plan_art_resolves(plan, art), "%s rotation %d uses only registered art semantics" % [String(profile_id), orientation])

func _test_multiunit_access_model(generator: LocalBuildingGenerator, validator: GeneratedBuildingValidator) -> void:
    var expectations := {
        BaselineProfilesClass.TOWNHOMES_ROW3: 3,
        BaselineProfilesClass.MULTIUNIT_ROW4: 4,
        BaselineProfilesClass.ROADSIDE_MOTEL: 4,
    }
    for profile_id: Variant in expectations.keys():
        var typed_id: StringName = StringName(profile_id)
        var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(typed_id)
        _check(descriptor != null, "%s descriptor exists for independent-access test" % String(typed_id))
        if descriptor == null:
            continue
        var request := RequestClass.new(
            "building.smoke.multiunit.%s" % String(typed_id).replace(".", "_"),
            typed_id,
            99001,
            Rect2i(Vector2i(20, 20), descriptor.required_size(Facing.Value.NORTH)),
            Facing.Value.NORTH,
            descriptor.frontage_for_orientation(Facing.Value.NORTH)
        )
        var plan: GeneratedBuildingPlan = generator.generate(request)
        var validation: Dictionary = validator.validate(plan) if plan.is_generated() else {"ok": false, "failures": [plan.failure_reason]}
        _check(plan.is_generated() and bool(validation.get("ok", false)), "%s validates with independent exterior unit access%s" % [String(typed_id), _validation_suffix(validation)])
        _check(_exterior_door_count(plan) == int(expectations[profile_id]), "%s has the intended number of exterior unit entrances" % String(typed_id))
    _check(not generator.supported_archetypes().has(&"lodging.hotel"), "baseline uses roadside motel representation rather than a fake multi-story hotel")

func _validation_suffix(validation: Dictionary) -> String:
    if bool(validation.get("ok", false)):
        return ""
    return " failures=%s" % str(validation.get("failures", []))

func _plan_art_resolves(plan: GeneratedBuildingPlan, art: ArtCatalog) -> bool:
    for ground: Dictionary in plan.ground_entries:
        if not art.resolve_ground(StringName(ground.get("semantic", &""))).is_found():
            return false
    for structure: Dictionary in plan.structures:
        var semantic: StringName = StringName(structure.get("semantic", &""))
        match String(structure.get("kind", "")):
            "wall":
                if not art.resolve_wall(semantic).is_found():
                    return false
            "door":
                if not art.resolve_door(semantic, false).is_found():
                    return false
            "window":
                if not art.resolve_window(semantic).is_found():
                    return false
            _:
                return false
    for prop: Dictionary in plan.props:
        if not art.resolve_prop(StringName(prop.get("semantic", &""))).is_found():
            return false
    return true

func _exterior_door_count(plan: GeneratedBuildingPlan) -> int:
    var count: int = 0
    for structure: Dictionary in plan.structures:
        if String(structure.get("kind", "")) == "door" and String(structure.get("role", "")).begins_with("door.exterior."):
            count += 1
    return count

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
