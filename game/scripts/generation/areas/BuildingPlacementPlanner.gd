extends RefCounted
class_name BuildingPlacementPlanner

const Seed = preload("res://scripts/generation/areas/AreaSeed.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const BuildingGeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BuildingValidatorClass = preload("res://scripts/generation/buildings/GeneratedBuildingValidator.gd")

var _building_generator: LocalBuildingGenerator
var _building_validator: GeneratedBuildingValidator

func _init() -> void:
    _building_generator = BuildingGeneratorClass.new()
    _building_validator = BuildingValidatorClass.new()

func place(request: AreaGenerationRequest, profile: Dictionary, parcels: Array[Dictionary]) -> Dictionary:
    var building_requests: Array[BuildingGenerationRequest] = []
    if request == null or profile.is_empty():
        return {"ok": false, "failure_reason": "invalid_building_placement_input", "building_requests": building_requests}

    var commercial_index: int = 0
    var residential_index: int = 0
    var farmstead_index: int = 0
    var residential_pool: Array = profile.get("residential_archetypes", [])
    var farmstead_pool: Array = profile.get("farmstead_archetypes", [])
    var commercial_pool: Array = profile.get("commercial_archetypes", [])
    var residential_offset: int = Seed.choose_index(request.seed, "building_selection:residential", residential_pool.size())
    var farmstead_offset: int = Seed.choose_index(request.seed, "building_selection:farmstead", farmstead_pool.size())

    for parcel: Dictionary in parcels:
        var land_use: StringName = parcel.get("land_use", &"")
        var archetype_id: StringName = &""
        match land_use:
            &"commercial_small":
                if commercial_index < commercial_pool.size():
                    archetype_id = StringName(commercial_pool[commercial_index])
                commercial_index += 1
            &"residential":
                if not residential_pool.is_empty():
                    archetype_id = StringName(residential_pool[(residential_index + residential_offset) % residential_pool.size()])
                residential_index += 1
            &"farmstead":
                if not farmstead_pool.is_empty():
                    archetype_id = StringName(farmstead_pool[(farmstead_index + farmstead_offset) % farmstead_pool.size()])
                farmstead_index += 1
            _:
                continue

        if archetype_id == &"":
            continue
        var placement: Dictionary = _place_one(request, profile, parcel, archetype_id)
        if not bool(placement.get("ok", false)):
            return {"ok": false, "failure_reason": String(placement.get("failure_reason", "building_placement_failed")), "building_requests": building_requests}
        var built_request: BuildingGenerationRequest = placement.get("request")
        building_requests.append(built_request)
        parcel["building_archetype_id"] = archetype_id
        parcel["building_envelope"] = built_request.envelope
        parcel["building_orientation"] = built_request.orientation
        parcel["building_frontage"] = built_request.frontage_side
        parcel["building_seed"] = built_request.seed
        parcel["building_instance_id"] = built_request.instance_id
        parcel["building_entry_cell"] = placement.get("entry_cell", Vector2i(-1, -1))

    return {"ok": true, "failure_reason": "", "building_requests": building_requests}

func _place_one(
    area_request: AreaGenerationRequest,
    profile: Dictionary,
    parcel: Dictionary,
    archetype_id: StringName
) -> Dictionary:
    var descriptor: BuildingArchetypePlacementDescriptor = _building_generator.placement_descriptor(archetype_id)
    if descriptor == null or not descriptor.is_valid():
        return {"ok": false, "failure_reason": "building_descriptor_missing"}
    var frontage: int = int(parcel.get("frontage_side", -1))
    var orientation: int = _orientation_for_frontage(descriptor, frontage)
    if orientation < 0:
        return {"ok": false, "failure_reason": "building_frontage_unsupported"}
    var size: Vector2i = descriptor.required_size(orientation)
    var buildable: Rect2i = parcel.get("buildable_rect", Rect2i())
    var setback: int = _setback_for_land_use(profile, StringName(parcel.get("land_use", &"")))
    var envelope: Rect2i = _envelope_for_access(buildable, size, frontage, parcel.get("parcel_access_cell", Vector2i(-1, -1)), setback)
    if not _rect_inside(buildable, envelope):
        return {"ok": false, "failure_reason": "building_does_not_fit_parcel"}

    var instance_id: String = "%s.building.primary" % String(parcel.get("id", "parcel"))
    var building_seed: int = Seed.derive(area_request.seed, "building:%s" % String(parcel.get("id", "")))
    var building_request := RequestClass.new(instance_id, archetype_id, building_seed, envelope, orientation, frontage)
    var plan: GeneratedBuildingPlan = _building_generator.generate(building_request)
    if not plan.is_generated():
        return {"ok": false, "failure_reason": "system19_generation_failed"}
    var validation: Dictionary = _building_validator.validate(plan)
    if not bool(validation.get("ok", false)):
        return {"ok": false, "failure_reason": "system19_validation_failed"}
    var entry_cell: Vector2i = _primary_entry_cell(plan)
    if entry_cell.x < 0:
        return {"ok": false, "failure_reason": "system19_primary_entry_missing"}
    return {"ok": true, "failure_reason": "", "request": building_request, "entry_cell": entry_cell}

func _orientation_for_frontage(descriptor: BuildingArchetypePlacementDescriptor, frontage: int) -> int:
    for orientation: int in descriptor.supported_orientations():
        if descriptor.frontage_for_orientation(orientation) == frontage:
            return orientation
    return -1

func _setback_for_land_use(profile: Dictionary, land_use: StringName) -> int:
    match land_use:
        &"commercial_small":
            return int(profile.get("commercial_setback", 1))
        &"farmstead":
            return int(profile.get("farmstead_setback", 8))
        _:
            return int(profile.get("residential_setback", 3))

func _envelope_for_access(
    buildable: Rect2i,
    size: Vector2i,
    frontage: int,
    access: Vector2i,
    setback: int
) -> Rect2i:
    if size.x <= 0 or size.y <= 0 or access.x < 0:
        return Rect2i()
    var x: int = access.x - size.x / 2
    var y: int = access.y - size.y / 2
    match frontage:
        Facing.Value.NORTH:
            y = buildable.position.y + setback
            x = _clamp_origin(access.x - size.x / 2, buildable.position.x, buildable.position.x + buildable.size.x - size.x)
        Facing.Value.SOUTH:
            y = buildable.position.y + buildable.size.y - size.y - setback
            x = _clamp_origin(access.x - size.x / 2, buildable.position.x, buildable.position.x + buildable.size.x - size.x)
        Facing.Value.WEST:
            x = buildable.position.x + setback
            y = _clamp_origin(access.y - size.y / 2, buildable.position.y, buildable.position.y + buildable.size.y - size.y)
        Facing.Value.EAST:
            x = buildable.position.x + buildable.size.x - size.x - setback
            y = _clamp_origin(access.y - size.y / 2, buildable.position.y, buildable.position.y + buildable.size.y - size.y)
    return Rect2i(Vector2i(x, y), size)

func _clamp_origin(value: int, minimum: int, maximum: int) -> int:
    if maximum < minimum:
        return minimum - 1
    return clampi(value, minimum, maximum)

func _primary_entry_cell(plan: GeneratedBuildingPlan) -> Vector2i:
    for structure: Dictionary in plan.structures:
        if String(structure.get("role", "")) == "door.exterior.primary":
            return structure.get("cell", Vector2i(-1, -1))
    return Vector2i(-1, -1)

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_max := Vector2i(inner.position.x + inner.size.x - 1, inner.position.y + inner.size.y - 1)
    return outer.has_point(inner.position) and outer.has_point(inner_max)
