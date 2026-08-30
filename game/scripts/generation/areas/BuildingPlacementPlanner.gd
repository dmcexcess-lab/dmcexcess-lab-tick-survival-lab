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
    var civic_index: int = 0
    var industrial_index: int = 0
    var residential_pool: Array = profile.get("residential_archetypes", [])
    var farmstead_pool: Array = profile.get("farmstead_archetypes", [])
    var commercial_pool: Array = profile.get("commercial_archetypes", [])
    var civic_pool: Array = profile.get("civic_archetypes", [])
    var industrial_pool: Array = profile.get("industrial_archetypes", [])
    var residential_offset: int = Seed.choose_index(request.seed, "building_selection:residential", residential_pool.size())
    var farmstead_offset: int = Seed.choose_index(request.seed, "building_selection:farmstead", farmstead_pool.size())
    var civic_offset: int = Seed.choose_index(request.seed, "building_selection:civic", civic_pool.size())
    var industrial_offset: int = Seed.choose_index(request.seed, "building_selection:industrial", industrial_pool.size())
    var land_use_mode: StringName = StringName(profile.get("land_use_mode", &""))
    var use_fit_filtered_baseline: bool = land_use_mode == &"baseline_grid"
    var baseline_cursors: Dictionary = {
        &"commercial_small": 0,
        &"residential": maxi(0, residential_offset),
        &"farmstead": maxi(0, farmstead_offset),
        &"civic": maxi(0, civic_offset),
        &"industrial": maxi(0, industrial_offset),
    }
    var unique_commercial_assignments: Dictionary = {}
    if land_use_mode == &"smalltown_center":
        var matching: Dictionary = _match_unique_fitting_archetypes(profile, parcels, &"commercial_small", commercial_pool)
        unique_commercial_assignments = matching.get("assignments", {})

    for parcel: Dictionary in parcels:
        var land_use: StringName = StringName(parcel.get("land_use", &""))
        var parcel_id: String = String(parcel.get("id", ""))
        var archetype_id: StringName = &""
        if land_use == &"commercial_small" and land_use_mode == &"smalltown_center":
            if not unique_commercial_assignments.has(parcel_id):
                continue
            archetype_id = StringName(unique_commercial_assignments[parcel_id])
        elif use_fit_filtered_baseline:
            var baseline_pool: Array = _pool_for_land_use(
                land_use,
                commercial_pool,
                residential_pool,
                farmstead_pool,
                civic_pool,
                industrial_pool
            )
            if baseline_pool.is_empty():
                continue
            var cursor: int = int(baseline_cursors.get(land_use, 0))
            var selection: Dictionary = _select_fitting_archetype(profile, parcel, baseline_pool, cursor)
            if not bool(selection.get("ok", false)):
                continue
            archetype_id = StringName(selection.get("archetype_id", &""))
            var selected_index: int = int(selection.get("selected_index", -1))
            if selected_index >= 0:
                baseline_cursors[land_use] = (selected_index + 1) % baseline_pool.size()
        else:
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
                &"civic":
                    if not civic_pool.is_empty():
                        archetype_id = StringName(civic_pool[(civic_index + civic_offset) % civic_pool.size()])
                    civic_index += 1
                &"industrial":
                    if not industrial_pool.is_empty():
                        archetype_id = StringName(industrial_pool[(industrial_index + industrial_offset) % industrial_pool.size()])
                    industrial_index += 1
                _:
                    continue

        if archetype_id == &"":
            continue
        if not _archetype_fits_parcel(profile, parcel, archetype_id):
            var fallback_pool: Array = _pool_for_land_use(
                land_use,
                commercial_pool,
                residential_pool,
                farmstead_pool,
                civic_pool,
                industrial_pool
            )
            var fallback_start: int = maxi(0, fallback_pool.find(archetype_id))
            var fallback: Dictionary = _select_fitting_archetype(profile, parcel, fallback_pool, fallback_start)
            if not bool(fallback.get("ok", false)):
                continue
            archetype_id = StringName(fallback.get("archetype_id", &""))

        var placement: Dictionary = _place_one(request, profile, parcel, archetype_id)
        if not bool(placement.get("ok", false)):
            var placement_failure: String = String(placement.get("failure_reason", "building_placement_failed"))
            if placement_failure == "building_does_not_fit_parcel" \
                or placement_failure == "building_frontage_unsupported" \
                or placement_failure == "building_entry_alignment_failed":
                continue
            return {"ok": false, "failure_reason": placement_failure, "building_requests": building_requests}
        var built_request: BuildingGenerationRequest = placement.get("request") as BuildingGenerationRequest
        if built_request == null:
            return {"ok": false, "failure_reason": "building_request_result_invalid", "building_requests": building_requests}
        building_requests.append(built_request)
        parcel["building_archetype_id"] = archetype_id
        parcel["building_envelope"] = built_request.envelope
        parcel["building_orientation"] = built_request.orientation
        parcel["building_frontage"] = built_request.frontage_side
        parcel["building_seed"] = built_request.seed
        parcel["building_instance_id"] = built_request.instance_id
        parcel["building_entry_cell"] = placement.get("entry_cell", Vector2i(-1, -1))
        var paved_frontage: Array = placement.get("paved_frontage", [])
        parcel["road_flush_paved_frontage"] = paved_frontage.duplicate(true)

    return {"ok": true, "failure_reason": "", "building_requests": building_requests}

func _pool_for_land_use(
    land_use: StringName,
    commercial_pool: Array,
    residential_pool: Array,
    farmstead_pool: Array,
    civic_pool: Array,
    industrial_pool: Array
) -> Array:
    match land_use:
        &"commercial_small":
            return commercial_pool
        &"residential":
            return residential_pool
        &"farmstead":
            return farmstead_pool
        &"civic":
            return civic_pool
        &"industrial":
            return industrial_pool
    return []

func _match_unique_fitting_archetypes(
    profile: Dictionary,
    parcels: Array[Dictionary],
    land_use: StringName,
    pool: Array
) -> Dictionary:
    var candidates: Array[Dictionary] = []
    for parcel: Dictionary in parcels:
        if StringName(parcel.get("land_use", &"")) == land_use:
            candidates.append(parcel)

    var matched_archetype_by_parcel: Array[int] = []
    matched_archetype_by_parcel.resize(candidates.size())
    matched_archetype_by_parcel.fill(-1)
    for archetype_index in range(pool.size()):
        var visited_parcels: Dictionary = {}
        _try_match_archetype(
            profile,
            candidates,
            pool,
            archetype_index,
            visited_parcels,
            matched_archetype_by_parcel
        )

    var assignments: Dictionary = {}
    for parcel_index in range(candidates.size()):
        var archetype_index: int = matched_archetype_by_parcel[parcel_index]
        if archetype_index < 0:
            continue
        var parcel_id: String = String(candidates[parcel_index].get("id", ""))
        if parcel_id.is_empty():
            continue
        assignments[parcel_id] = StringName(pool[archetype_index])
    return {"ok": true, "assignments": assignments}

func _try_match_archetype(
    profile: Dictionary,
    candidates: Array[Dictionary],
    pool: Array,
    archetype_index: int,
    visited_parcels: Dictionary,
    matched_archetype_by_parcel: Array[int]
) -> bool:
    var archetype_id: StringName = StringName(pool[archetype_index])
    for parcel_index in range(candidates.size()):
        if visited_parcels.has(parcel_index):
            continue
        var parcel: Dictionary = candidates[parcel_index]
        if not _archetype_fits_parcel(profile, parcel, archetype_id):
            continue
        visited_parcels[parcel_index] = true
        var occupying_archetype: int = matched_archetype_by_parcel[parcel_index]
        if occupying_archetype < 0 or _try_match_archetype(
            profile,
            candidates,
            pool,
            occupying_archetype,
            visited_parcels,
            matched_archetype_by_parcel
        ):
            matched_archetype_by_parcel[parcel_index] = archetype_index
            return true
    return false

func _select_fitting_archetype(
    profile: Dictionary,
    parcel: Dictionary,
    pool: Array,
    start_index: int
) -> Dictionary:
    if pool.is_empty():
        return {"ok": true, "archetype_id": &"", "selected_index": -1}
    var normalized_start: int = posmod(start_index, pool.size())
    for step in range(pool.size()):
        var index: int = (normalized_start + step) % pool.size()
        var archetype_id: StringName = StringName(pool[index])
        if _archetype_fits_parcel(profile, parcel, archetype_id):
            return {"ok": true, "archetype_id": archetype_id, "selected_index": index}
    return {"ok": false, "archetype_id": &"", "selected_index": -1}

func _archetype_fits_parcel(profile: Dictionary, parcel: Dictionary, archetype_id: StringName) -> bool:
    var descriptor: BuildingArchetypePlacementDescriptor = _building_generator.placement_descriptor(archetype_id)
    if descriptor == null or not descriptor.is_valid():
        return false
    var frontage: int = int(parcel.get("frontage_side", -1))
    var orientation: int = _orientation_for_frontage(descriptor, frontage)
    if orientation < 0:
        return false
    var size: Vector2i = descriptor.required_size(orientation)
    var buildable: Rect2i = parcel.get("buildable_rect", Rect2i())
    var setback: int = _setback_for_land_use(profile, StringName(parcel.get("land_use", &"")))
    var parcel_access: Vector2i = parcel.get("parcel_access_cell", Vector2i(-1, -1))
    var envelope: Rect2i = _envelope_for_access(buildable, size, frontage, parcel_access, setback)
    return _rect_inside(buildable, envelope)

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
    var parcel_access: Vector2i = parcel.get("parcel_access_cell", Vector2i(-1, -1))
    var envelope: Rect2i = _envelope_for_access(buildable, size, frontage, parcel_access, setback)
    if not _rect_inside(buildable, envelope):
        return {"ok": false, "failure_reason": "building_does_not_fit_parcel"}

    var instance_id: String = "%s.building.primary" % String(parcel.get("id", "parcel"))
    var building_seed: int = Seed.derive(area_request.seed, "building:%s" % String(parcel.get("id", "")))
    var building_request: BuildingGenerationRequest = RequestClass.new(instance_id, archetype_id, building_seed, envelope, orientation, frontage)
    var plan: GeneratedBuildingPlan = _building_generator.generate(building_request)
    if not plan.is_generated():
        return {"ok": false, "failure_reason": "system19_generation_failed"}
    var validation: Dictionary = _building_validator.validate(plan)
    if not bool(validation.get("ok", false)):
        return {"ok": false, "failure_reason": "system19_validation_failed"}
    var entry_cell: Vector2i = _primary_entry_cell(plan)
    if entry_cell.x < 0:
        return {"ok": false, "failure_reason": "system19_primary_entry_missing"}
    if not _align_parcel_access_to_entry(parcel, entry_cell, frontage):
        return {"ok": false, "failure_reason": "building_entry_alignment_failed"}
    return {
        "ok": true,
        "failure_reason": "",
        "request": building_request,
        "entry_cell": entry_cell,
        "paved_frontage": _road_facing_parking_edge(plan, frontage),
    }

func _align_parcel_access_to_entry(parcel: Dictionary, entry: Vector2i, frontage: int) -> bool:
    var parcel_access: Vector2i = parcel.get("parcel_access_cell", Vector2i(-1, -1))
    var road_access: Vector2i = parcel.get("access_cell", Vector2i(-1, -1))
    if parcel_access.x < 0 or road_access.x < 0 or entry.x < 0 or not Facing.is_valid(frontage):
        return false
    if frontage == Facing.Value.NORTH or frontage == Facing.Value.SOUTH:
        var shift_x: int = entry.x - parcel_access.x
        parcel_access.x = entry.x
        road_access.x += shift_x
    else:
        var shift_y: int = entry.y - parcel_access.y
        parcel_access.y = entry.y
        road_access.y += shift_y
    var parcel_rect: Rect2i = parcel.get("rect", Rect2i())
    if not parcel_rect.has_point(parcel_access):
        return false
    parcel["parcel_access_cell"] = parcel_access
    parcel["access_cell"] = road_access
    return true

func _road_facing_parking_edge(plan: GeneratedBuildingPlan, frontage: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if plan == null or not plan.is_generated() or not Facing.is_valid(frontage):
        return result
    var footprint: Rect2i = plan.footprint_rect
    if footprint.size.x <= 0 or footprint.size.y <= 0:
        return result
    for ground: Dictionary in plan.ground_entries:
        var semantic: StringName = StringName(ground.get("semantic", &""))
        if not String(semantic).begins_with("ground.parking"):
            continue
        var cell: Vector2i = ground.get("cell", Vector2i(-999999, -999999))
        if not _cell_on_frontage_edge(cell, footprint, frontage):
            continue
        result.append({"cell": cell, "semantic": semantic})
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var a_cell: Vector2i = a.get("cell", Vector2i.ZERO)
        var b_cell: Vector2i = b.get("cell", Vector2i.ZERO)
        return a_cell.y < b_cell.y or (a_cell.y == b_cell.y and a_cell.x < b_cell.x)
    )
    return result

func _cell_on_frontage_edge(cell: Vector2i, footprint: Rect2i, frontage: int) -> bool:
    var max_x: int = footprint.position.x + footprint.size.x - 1
    var max_y: int = footprint.position.y + footprint.size.y - 1
    match frontage:
        Facing.Value.NORTH:
            return cell.y == footprint.position.y
        Facing.Value.EAST:
            return cell.x == max_x
        Facing.Value.SOUTH:
            return cell.y == max_y
        Facing.Value.WEST:
            return cell.x == footprint.position.x
    return false

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
        &"civic":
            return int(profile.get("civic_setback", 1))
        &"industrial":
            return int(profile.get("industrial_setback", 1))
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
    var half_width: int = size.x / 2
    var half_height: int = size.y / 2
    var x: int = access.x - half_width
    var y: int = access.y - half_height
    match frontage:
        Facing.Value.NORTH:
            y = buildable.position.y + setback
            x = _clamp_origin(access.x - half_width, buildable.position.x, buildable.position.x + buildable.size.x - size.x)
        Facing.Value.SOUTH:
            y = buildable.position.y + buildable.size.y - size.y - setback
            x = _clamp_origin(access.x - half_width, buildable.position.x, buildable.position.x + buildable.size.x - size.x)
        Facing.Value.WEST:
            x = buildable.position.x + setback
            y = _clamp_origin(access.y - half_height, buildable.position.y, buildable.position.y + buildable.size.y - size.y)
        Facing.Value.EAST:
            x = buildable.position.x + buildable.size.x - size.x - setback
            y = _clamp_origin(access.y - half_height, buildable.position.y, buildable.position.y + buildable.size.y - size.y)
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
