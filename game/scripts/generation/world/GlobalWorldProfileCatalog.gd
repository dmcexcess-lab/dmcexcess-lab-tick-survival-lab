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
        result["version"] = 4
        result["island_enabled"] = true
        # Island generation keeps the proven content owners but no longer carries the
        # old regional stress-fixture geometry into the playable world.
        result["reuse_world_seed_for_central_site"] = false
        # The central crossroads only needs a local protected cross. The old 640-cell
        # half-span flattened/routed a 1280-cell test skeleton through every island and
        # visually preserved the legacy-map belt even after surface dressing changed.
        result["protected_cross_half_span"] = 160
        result["protected_cross_half_thickness"] = 96
        # 256x256 settlement envelopes now sit close enough to read as one continuous
        # generated island. Geography snapping still provides seed-dependent placement.
        result["smalltown_distance_min"] = 280
        result["smalltown_distance_max"] = 336
        result["north_hamlet_distance_min"] = 280
        result["north_hamlet_distance_max"] = 336
        result["southwest_x_distance_min"] = 280
        result["southwest_x_distance_max"] = 336
        result["southwest_y_distance_min"] = 280
        result["southwest_y_distance_max"] = 336
        result["northeast_x_distance_min"] = 280
        result["northeast_x_distance_max"] = 336
        result["northeast_y_distance_min"] = 280
        result["northeast_y_distance_max"] = 336
        result["island_ocean_margin"] = 24
        result["island_shore_width"] = 8
        result["island_coast_wobble"] = 8
        result["island_coast_scale"] = 96
        return result
    return {}

func _rural_profile() -> Dictionary:
    return {
        "id": TEMPERATE_RURAL_REGION,
        "version": 7,
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

        # Potable water is one island-wide municipal treatment facility. Its small
        # physical plant is kept near the shore; long-distance pipe/flow simulation is
        # intentionally absent. Rural private wells are selected later from real homes.
        "water_plant_shore_offset_cells": 48,
        "water_plant_internal_spacing_cells": 3,
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
