extends RefCounted
class_name BaselineAreaProfileCatalog

const SUBURBAN_NEIGHBORHOOD: StringName = &"suburban.neighborhood"
const URBAN_MIXED: StringName = &"urban.mixed"
const COMMERCIAL_CORRIDOR: StringName = &"commercial.corridor"
const INDUSTRIAL_DISTRICT: StringName = &"industrial.district"
const CIVIC_CAMPUS: StringName = &"civic.campus"

const PROFILE_IDS: Array[StringName] = [
    SUBURBAN_NEIGHBORHOOD,
    URBAN_MIXED,
    COMMERCIAL_CORRIDOR,
    INDUSTRIAL_DISTRICT,
    CIVIC_CAMPUS,
]

func profile_ids() -> Array[StringName]:
    return PROFILE_IDS.duplicate()

func has_profile(profile_id: StringName) -> bool:
    return profile_id in PROFILE_IDS

func profile(profile_id: StringName) -> Dictionary:
    match profile_id:
        SUBURBAN_NEIGHBORHOOD:
            return _suburban_neighborhood()
        URBAN_MIXED:
            return _urban_mixed()
        COMMERCIAL_CORRIDOR:
            return _commercial_corridor()
        INDUSTRIAL_DISTRICT:
            return _industrial_district()
        CIVIC_CAMPUS:
            return _civic_campus()
    return {}

func _grid_base(profile_id: StringName, environment_id: StringName) -> Dictionary:
    return {
        "id": profile_id,
        "version": 1,
        "recommended_environment": environment_id,
        "road_layout": &"smalltown_grid",
        "signalize_first_inherited_intersection": false,
        "land_use_mode": &"baseline_grid",
        "local_frontage_road_class": &"local_town",
        "center_exclusion_radius": 10,
        "edge_margin": 8,
        "parcel_gap": 2,
        "parcel_road_gap": 1,
        "parcel_buildable_margin": 1,
        "primary_parcel_depth": 32,
        "secondary_parcel_depth": 30,
        "local_parcel_depth": 30,
        "frontage_min": 32,
        "frontage_max": 40,
        "local_frontage_min": 32,
        "local_frontage_max": 40,
        "local_frontage_end_margin": 4,
        "commercial_count": 0,
        "residential_count": 0,
        "farmstead_count": 0,
        "civic_count": 0,
        "industrial_count": 0,
        "local_residential_target": 0,
        "local_farmstead_target": 0,
        "local_town_width": 3,
        "town_cross_offset_candidates": [48, 60, 72, 84],
        "town_back_offset_candidates": [40, 52, 64, 76],
        "town_street_extension": 10,
        "town_core_half_extent": 94,
        "town_block_min_span": 12,
        "reservation_road_gap": 2,
        "town_edge_open_distance": 88,
        "residential_setback": 1,
        "farmstead_setback": 4,
        "commercial_setback": 1,
        "civic_setback": 1,
        "industrial_setback": 1,
        "commercial_archetypes": [],
        "residential_archetypes": [],
        "farmstead_archetypes": [],
        "civic_archetypes": [],
        "industrial_archetypes": [],
    }

func _suburban_neighborhood() -> Dictionary:
    var p := _grid_base(SUBURBAN_NEIGHBORHOOD, &"temperate.suburban")
    p["frontage_min"] = 34
    p["frontage_max"] = 42
    p["local_frontage_min"] = 34
    p["local_frontage_max"] = 42
    p["primary_parcel_depth"] = 30
    p["secondary_parcel_depth"] = 28
    p["local_parcel_depth"] = 28
    p["commercial_count"] = 2
    p["residential_count"] = 10
    p["civic_count"] = 1
    p["local_residential_target"] = 7
    p["commercial_archetypes"] = [
        &"commercial.convenience_store.small",
        &"commercial.pharmacy.small",
    ]
    p["residential_archetypes"] = [
        &"residential.house.suburban_small",
        &"residential.house.suburban_family",
        &"residential.townhomes.row3",
    ]
    p["civic_archetypes"] = [&"civic.clinic.small"]
    return p

func _urban_mixed() -> Dictionary:
    var p := _grid_base(URBAN_MIXED, &"temperate.urban")
    p["frontage_min"] = 36
    p["frontage_max"] = 44
    p["local_frontage_min"] = 36
    p["local_frontage_max"] = 44
    p["primary_parcel_depth"] = 30
    p["secondary_parcel_depth"] = 28
    p["local_parcel_depth"] = 28
    p["commercial_count"] = 5
    p["residential_count"] = 8
    p["civic_count"] = 2
    p["local_residential_target"] = 6
    p["commercial_archetypes"] = [
        &"commercial.convenience_store.small",
        &"commercial.grocery.neighborhood",
        &"commercial.pharmacy.small",
        &"commercial.hardware_store.small",
        &"commercial.office.small",
    ]
    p["residential_archetypes"] = [
        &"residential.townhomes.row3",
        &"residential.multiunit.row4",
    ]
    p["civic_archetypes"] = [
        &"civic.clinic.small",
        &"civic.police_station.small",
    ]
    return p

func _commercial_corridor() -> Dictionary:
    var p := _grid_base(COMMERCIAL_CORRIDOR, &"temperate.suburban")
    p["frontage_min"] = 44
    p["frontage_max"] = 50
    p["local_frontage_min"] = 34
    p["local_frontage_max"] = 42
    p["primary_parcel_depth"] = 34
    p["secondary_parcel_depth"] = 30
    p["local_parcel_depth"] = 30
    p["commercial_count"] = 6
    p["residential_count"] = 2
    p["civic_count"] = 1
    p["industrial_count"] = 1
    p["local_residential_target"] = 2
    p["commercial_archetypes"] = [
        &"lodging.motel.roadside",
        &"commercial.grocery.neighborhood",
        &"commercial.hardware_store.small",
        &"commercial.pharmacy.small",
        &"commercial.convenience_store.small",
        &"commercial.office.small",
    ]
    p["residential_archetypes"] = [
        &"residential.house.suburban_family",
        &"residential.townhomes.row3",
    ]
    p["civic_archetypes"] = [&"civic.clinic.small"]
    p["industrial_archetypes"] = [&"industrial.workshop.small"]
    return p

func _industrial_district() -> Dictionary:
    var p := _grid_base(INDUSTRIAL_DISTRICT, &"temperate.industrial")
    p["frontage_min"] = 32
    p["frontage_max"] = 42
    p["local_frontage_min"] = 32
    p["local_frontage_max"] = 42
    p["primary_parcel_depth"] = 34
    p["secondary_parcel_depth"] = 32
    p["local_parcel_depth"] = 32
    p["commercial_count"] = 2
    p["industrial_count"] = 6
    p["commercial_archetypes"] = [
        &"commercial.hardware_store.small",
        &"commercial.convenience_store.small",
    ]
    p["industrial_archetypes"] = [
        &"industrial.warehouse.small",
        &"industrial.workshop.small",
    ]
    return p

func _civic_campus() -> Dictionary:
    var p := _grid_base(CIVIC_CAMPUS, &"temperate.suburban")
    p["frontage_min"] = 34
    p["frontage_max"] = 42
    p["local_frontage_min"] = 34
    p["local_frontage_max"] = 42
    p["primary_parcel_depth"] = 34
    p["secondary_parcel_depth"] = 32
    p["local_parcel_depth"] = 32
    p["commercial_count"] = 1
    p["residential_count"] = 2
    p["civic_count"] = 5
    p["local_residential_target"] = 2
    p["commercial_archetypes"] = [&"commercial.convenience_store.small"]
    p["residential_archetypes"] = [
        &"residential.house.suburban_family",
        &"residential.townhomes.row3",
    ]
    p["civic_archetypes"] = [
        &"civic.school.elementary_small",
        &"civic.fire_station.small",
        &"civic.police_station.small",
        &"civic.clinic.small",
        &"civic.church.small",
    ]
    return p
