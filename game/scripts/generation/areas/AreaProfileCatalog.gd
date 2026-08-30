extends RefCounted
class_name AreaProfileCatalog

const BaselineProfilesClass = preload("res://scripts/generation/areas/BaselineAreaProfileCatalog.gd")

const RURAL_CROSSROADS: StringName = &"rural.crossroads"
const SMALLTOWN_CENTER: StringName = &"smalltown.center"
const RURAL_SCATTERED: StringName = &"rural.scattered"
const RURAL_OPEN: StringName = &"rural.open"
const RURAL_WATERCOURSE: StringName = &"rural.watercourse"

var _baseline_profiles := BaselineProfilesClass.new()

func has_profile(profile_id: StringName) -> bool:
    return profile_id == RURAL_CROSSROADS \
        or profile_id == SMALLTOWN_CENTER \
        or profile_id == RURAL_SCATTERED \
        or profile_id == RURAL_OPEN \
        or profile_id == RURAL_WATERCOURSE \
        or _baseline_profiles.has_profile(profile_id)

func profile(profile_id: StringName) -> Dictionary:
    if profile_id == RURAL_CROSSROADS:
        return {
            "id": RURAL_CROSSROADS,
            "version": 5,
            "road_layout": &"rural_spurs",
            "signalize_first_inherited_intersection": true,
            "land_use_mode": &"rural_crossroads",
            "local_frontage_road_class": &"local_rural",
            "center_exclusion_radius": 20,
            "edge_margin": 8,
            "parcel_gap": 3,
            "parcel_road_gap": 1,
            "parcel_buildable_margin": 1,
            "primary_parcel_depth": 24,
            "secondary_parcel_depth": 24,
            "local_parcel_depth": 22,
            "frontage_min": 28,
            "frontage_max": 36,
            "local_frontage_min": 23,
            "local_frontage_max": 28,
            "local_frontage_end_margin": 4,
            "commercial_count": 3,
            "residential_count": 6,
            "farmstead_count": 4,
            "local_residential_target": 3,
            "local_farmstead_target": 3,
            "local_road_spurs": 0,
            "local_spur_width": 3,
            "local_spur_branch_offset": 64,
            "local_spur_first_leg": 44,
            "local_spur_lateral_leg": 54,
            "local_spur_second_leg": 54,
            "local_spur_tail_leg": 34,
            "residential_setback": 1,
            "farmstead_setback": 4,
            "commercial_setback": 1,
            "commercial_archetypes": [
                &"commercial.gas_station.small",
                &"commercial.diner.rural_small",
            ],
            "residential_archetypes": [
                &"residential.trailer.singlewide",
                &"residential.house.farm_small",
                &"residential.house.farm_large",
                &"residential.house.compact_laundry",
            ],
            "farmstead_archetypes": [
                &"residential.house.farm_small",
                &"residential.house.farm_large",
            ],
        }
    if profile_id == SMALLTOWN_CENTER:
        return {
            "id": SMALLTOWN_CENTER,
            "version": 3,
            "road_layout": &"smalltown_grid",
            "signalize_first_inherited_intersection": false,
            "land_use_mode": &"smalltown_center",
            "local_frontage_road_class": &"local_town",
            "center_exclusion_radius": 12,
            "edge_margin": 10,
            "parcel_gap": 2,
            "parcel_road_gap": 1,
            "parcel_buildable_margin": 1,
            "primary_parcel_depth": 26,
            "secondary_parcel_depth": 22,
            "local_parcel_depth": 22,
            "frontage_min": 30,
            "frontage_max": 36,
            "local_frontage_min": 23,
            "local_frontage_max": 28,
            "local_frontage_end_margin": 5,
            "commercial_count": 7,
            "residential_count": 12,
            "farmstead_count": 0,
            "local_residential_target": 7,
            "local_farmstead_target": 0,
            "local_town_width": 3,
            "town_cross_offset_candidates": [48, 60, 72, 84],
            "town_back_offset_candidates": [40, 52, 64, 76],
            "town_street_extension": 10,
            "town_core_half_extent": 92,
            "town_block_min_span": 12,
            "reservation_road_gap": 2,
            "reservation_substation_size": Vector2i(14, 12),
            "reservation_groundwater_source_size": Vector2i(12, 12),
            "reservation_water_treatment_size": Vector2i(16, 16),
            "reservation_wastewater_treatment_size": Vector2i(20, 16),
            "town_edge_open_distance": 82,
            "residential_setback": 1,
            "farmstead_setback": 4,
            "commercial_setback": 1,
            "commercial_archetypes": [
                &"commercial.gas_station.small",
                &"commercial.diner.rural_small",
                &"commercial.convenience_store.small",
                &"commercial.grocery.neighborhood",
                &"commercial.hardware_store.small",
                &"civic.post_office.small",
                &"civic.police_station.small",
            ],
            "residential_archetypes": [
                &"residential.house.suburban_small",
                &"residential.house.suburban_family",
                &"residential.house.compact_laundry",
                &"residential.trailer.singlewide",
                &"residential.house.farm_small",
                &"residential.house.farm_large",
            ],
            "farmstead_archetypes": [],
        }
    if profile_id == RURAL_SCATTERED:
        return {
            "id": RURAL_SCATTERED,
            "version": 1,
            "road_layout": &"rural_scattered_lanes",
            "signalize_first_inherited_intersection": false,
            "land_use_mode": &"rural_scattered",
            "local_frontage_road_class": &"local_rural",
            "center_exclusion_radius": 8,
            "edge_margin": 12,
            "parcel_gap": 5,
            "parcel_road_gap": 1,
            "parcel_buildable_margin": 1,
            "primary_parcel_depth": 24,
            "secondary_parcel_depth": 24,
            "local_parcel_depth": 22,
            "frontage_min": 30,
            "frontage_max": 38,
            "local_frontage_min": 24,
            "local_frontage_max": 30,
            "local_frontage_end_margin": 5,
            "commercial_count": 0,
            "residential_count": 4,
            "farmstead_count": 2,
            "local_residential_target": 3,
            "local_farmstead_target": 1,
            "rural_scattered_lane_count": 2,
            "rural_scattered_lane_width": 3,
            "rural_scattered_branch_margin": 24,
            "rural_scattered_branch_separation": 44,
            "rural_scattered_first_leg": 72,
            "rural_scattered_tail_leg": 24,
            "rural_scattered_edge_open_distance": 72,
            "residential_setback": 1,
            "farmstead_setback": 4,
            "commercial_setback": 1,
            "commercial_archetypes": [],
            "residential_archetypes": [
                &"residential.trailer.singlewide",
                &"residential.house.farm_small",
                &"residential.house.farm_large",
                &"residential.house.compact_laundry",
            ],
            "farmstead_archetypes": [
                &"residential.house.farm_small",
                &"residential.house.farm_large",
            ],
        }
    if profile_id == RURAL_OPEN:
        return {
            "id": RURAL_OPEN,
            "version": 1,
            "road_layout": &"inherit_only",
            "signalize_first_inherited_intersection": false,
            "land_use_mode": &"rural_open",
            "inherited_roads_required": false,
            "local_road_spurs": 0,
            "commercial_count": 0,
            "residential_count": 0,
            "farmstead_count": 0,
            "local_residential_target": 0,
            "local_farmstead_target": 0,
            "commercial_archetypes": [],
            "residential_archetypes": [],
            "farmstead_archetypes": [],
            "rural_open_field_scale": 72,
            "rural_open_field_threshold_lowland": 0.48,
            "rural_open_field_threshold_rolling": 0.68,
            "rural_open_road_clearance": 2,
            "rural_open_power_clearance": 1,
            "rural_open_natural_density_lowland": 0.010,
            "rural_open_natural_density_rolling": 0.014,
            "rural_open_natural_density_upland": 0.020,
            "rural_open_natural_density_ridge": 0.024,
        }
    if profile_id == RURAL_WATERCOURSE:
        return {
            "id": RURAL_WATERCOURSE,
            "version": 1,
            "road_layout": &"inherit_only",
            "signalize_first_inherited_intersection": false,
            "land_use_mode": &"rural_watercourse",
            "inherited_roads_required": false,
            "local_road_spurs": 0,
            "commercial_count": 0,
            "residential_count": 0,
            "farmstead_count": 0,
            "local_residential_target": 0,
            "local_farmstead_target": 0,
            "commercial_archetypes": [],
            "residential_archetypes": [],
            "farmstead_archetypes": [],
            "river_ground_semantic": &"ground.water_river",
        }
    return _baseline_profiles.profile(profile_id)