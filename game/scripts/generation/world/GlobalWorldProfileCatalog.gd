extends RefCounted
class_name GlobalWorldProfileCatalog

const TEMPERATE_RURAL_REGION: StringName = &"temperate.rural.region"

func has_profile(profile_id: StringName) -> bool:
    return profile_id == TEMPERATE_RURAL_REGION

func profile(profile_id: StringName) -> Dictionary:
    if profile_id != TEMPERATE_RURAL_REGION:
        return {}
    return {
        "id": TEMPERATE_RURAL_REGION,
        "version": 5,
        "minimum_world_size": Vector2i(1536, 1536),
        "local_site_size": Vector2i(256, 256),
        "primary_width": 5,
        "secondary_width": 3,

        "geography_cell_size": 128,
        "geography_noise_scale_cells": 4,
        "geography_peak_boost": 46,
        "lowland_elevation_max": 35,
        "rolling_elevation_max": 58,
        "upland_elevation_max": 75,
        "protected_cross_half_span": 640,
        "protected_cross_half_thickness": 192,
        "settlement_geography_search_radius_cells": 4,
        "road_cost_lowland": 10,
        "road_cost_rolling": 14,
        "road_cost_upland": 32,

        "primary_river_width": 5,
        "hydrology_protected_margin": 0,
        "river_uphill_penalty": 5,
        "river_meander_cost": 7,
        "road_cost_river_crossing": 120,
        "settlement_river_clearance": 16,

        "power_cost_primary": 10,
        "power_cost_secondary": 12,

        "water_treatment_anchor_offset": 24,
        "water_source_anchor_offset": 48,

        "smalltown_distance_min": 520,
        "smalltown_distance_max": 620,
        "north_hamlet_distance_min": 500,
        "north_hamlet_distance_max": 610,
        "southwest_x_distance_min": 440,
        "southwest_x_distance_max": 560,
        "southwest_y_distance_min": 500,
        "southwest_y_distance_max": 620,
        "northeast_x_distance_min": 450,
        "northeast_x_distance_max": 570,
        "northeast_y_distance_min": 460,
        "northeast_y_distance_max": 580,
        "crossroads_influence_radius": 160,
        "smalltown_influence_radius": 256,
        "hamlet_influence_radius": 192,
    }
