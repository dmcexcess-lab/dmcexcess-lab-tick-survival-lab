extends RefCounted
class_name GlobalWorldProfileCatalog

const TEMPERATE_RURAL_REGION: StringName = &"temperate.rural.region"
const TEMPERATE_ISLAND_REGION: StringName = &"temperate.island.region"

func has_profile(profile_id: StringName) -> bool:
    return profile_id == TEMPERATE_RURAL_REGION or profile_id == TEMPERATE_ISLAND_REGION

func profile(profile_id: StringName) -> Dictionary:
    if profile_id == TEMPERATE_RURAL_REGION:
        return _rural_profile()
    if profile_id == TEMPERATE_ISLAND_REGION:
        var result: Dictionary = _rural_profile()
        result["id"] = TEMPERATE_ISLAND_REGION
        result["version"] = 2
        result["island_enabled"] = true
        # Island v2 keeps the proven settlement kinds and road/hydrology contract,
        # but no longer reproduces the historical 256x256 crossroads critique
        # candidate as the center of the playable world.
        result["reuse_world_seed_for_central_site"] = false
        # Keep settlements meaningfully separated without the several-hundred-cell
        # empty belts inherited from the regional planning stress fixture.
        result["smalltown_distance_min"] = 360
        result["smalltown_distance_max"] = 440
        result["north_hamlet_distance_min"] = 360
        result["north_hamlet_distance_max"] = 440
        result["southwest_x_distance_min"] = 320
        result["southwest_x_distance_max"] = 400
        result["southwest_y_distance_min"] = 320
        result["southwest_y_distance_max"] = 400
        result["northeast_x_distance_min"] = 320
        result["northeast_x_distance_max"] = 400
        result["northeast_y_distance_min"] = 320
        result["northeast_y_distance_max"] = 400
        # The 256x256 site envelopes can sit near the second 128-cell geography
        # column/row. Keep enough visible ocean and coastline without clipping
        # legal settlement sites.
        result["island_ocean_margin"] = 24
        result["island_shore_width"] = 8
        result["island_coast_wobble"] = 8
        result["island_coast_scale"] = 96
        return result
    return {}

func _rural_profile() -> Dictionary:
    return {
        "id": TEMPERATE_RURAL_REGION,
        "version": 6,
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
        "wastewater_treatment_anchor_offset": 64,

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
