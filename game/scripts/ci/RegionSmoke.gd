extends SceneTree

const RegionGen = preload("res://scripts/ProceduralRegionGenerator.gd")
const Tiles = preload("res://scripts/TacticalTiles.gd")

func _init() -> void:
    _validate_final_art_vocabulary()
    for seed_value in [1, 7, 42, 1337, 9001]:
        var spec: Dictionary = RegionGen.generate(seed_value)
        if int(spec.get("width", 0)) != RegionGen.REGION_W or int(spec.get("height", 0)) != RegionGen.REGION_H:
            push_error("REGION_SMOKE_DIMENSIONS_CHANGED")
            quit(1)
            return
        if int(spec.get("generator_version", 0)) != RegionGen.GENERATOR_VERSION:
            push_error("REGION_SMOKE_GENERATOR_VERSION_MISSING")
            quit(1)
            return
        var result: Dictionary = RegionGen.validate(spec)
        if not bool(result.get("ok", false)):
            push_error("REGION_SMOKE_VALIDATION_FAILED seed=%d failures=%s" % [seed_value, str(result.get("failures", []))])
            quit(1)
            return
        var again: Dictionary = RegionGen.generate(seed_value)
        if spec.get("player_spawn") != again.get("player_spawn") or spec.get("biome_cells") != again.get("biome_cells") or spec.get("walls") != again.get("walls") or spec.get("road_cells") != again.get("road_cells") or spec.get("road_links") != again.get("road_links") or spec.get("road_surface_cells") != again.get("road_surface_cells") or spec.get("props") != again.get("props"):
            push_error("REGION_SMOKE_NONDETERMINISTIC seed=%d" % seed_value)
            quit(1)
            return
        var counts: Dictionary = result.get("biome_counts", {})
        for biome in RegionGen.BIOMES:
            if int(counts.get(biome, 0)) < 24:
                push_error("REGION_SMOKE_MISSING_BIOME seed=%d biome=%s" % [seed_value, biome])
                quit(1)
                return
        if spec.get("exit_cells", []).size() != 4 or spec.get("road_ports", {}).size() != 4:
            push_error("REGION_SMOKE_ROAD_PORTS_MISSING seed=%d" % seed_value)
            quit(1)
            return
        if not spec.get("road_cells", {}).has(spec.get("player_spawn")):
            push_error("REGION_SMOKE_SPAWN_NOT_ON_ROAD seed=%d" % seed_value)
            quit(1)
            return
        if spec.get("road_links", {}).size() != spec.get("road_cells", {}).size():
            push_error("REGION_SMOKE_ROAD_LINKS_INCOMPLETE seed=%d" % seed_value)
            quit(1)
            return
        var has_horizontal := false
        var has_vertical := false
        for mask_value in spec.get("road_links", {}).values():
            var mask := int(mask_value)
            if (mask & (RegionGen.ROAD_E | RegionGen.ROAD_W)) != 0:
                has_horizontal = true
            if (mask & (RegionGen.ROAD_N | RegionGen.ROAD_S)) != 0:
                has_vertical = true
        if not has_horizontal or not has_vertical:
            push_error("REGION_SMOKE_ROAD_DIRECTIONS_MISSING seed=%d" % seed_value)
            quit(1)
            return
        var ground_kinds: Dictionary = {}
        for entry_value in spec.get("ground_rects", []):
            var entry: Array = entry_value
            ground_kinds[str(entry[4])] = true
        if not ground_kinds.has("road_h") or not ground_kinds.has("road_v"):
            push_error("REGION_SMOKE_DIRECTIONAL_ROAD_ART_MISSING seed=%d" % seed_value)
            quit(1)
            return
        if spec.get("props", []).size() < 12:
            push_error("REGION_SMOKE_CLUTTER_TOO_SPARSE seed=%d" % seed_value)
            quit(1)
            return
        if spec.get("wall_themes", {}).is_empty():
            push_error("REGION_SMOKE_WALL_THEMES_MISSING seed=%d" % seed_value)
            quit(1)
            return
        if spec.get("door_themes", {}).is_empty() or spec.get("window_themes", {}).is_empty():
            push_error("REGION_SMOKE_OPENING_THEMES_MISSING seed=%d" % seed_value)
            quit(1)
            return
    print("TICK_SURVIVAL_REGION_SMOKE_OK")
    quit(0)

func _validate_final_art_vocabulary() -> void:
    if Tiles.FINAL_PROP.size() != Tiles.FINAL_PROP_COUNT or Tiles.FINAL_PROP_COUNT < 128:
        push_error("REGION_SMOKE_FINAL_PROP_VOCABULARY_INCOMPLETE")
        quit(1)
        return
    if Tiles.FINAL_GROUND.size() < 48 or Tiles.FINAL_SURFACE_COUNT < 64:
        push_error("REGION_SMOKE_FINAL_SURFACE_VOCABULARY_INCOMPLETE")
        quit(1)
        return
    for required_prop in [
        "deciduous_large", "pine_tree", "yield_sign", "street_name_sign",
        "refrigerator_stainless", "kitchen_sink", "tv_flat", "bed_double",
        "toilet_modern", "bathroom_vanity", "washer_front", "retail_shelf",
        "office_desk", "server_rack", "industrial_machine"
    ]:
        if not Tiles.FINAL_PROP.has(required_prop):
            push_error("REGION_SMOKE_FINAL_PROP_MISSING %s" % required_prop)
            quit(1)
            return
    for required_ground in [
        "grass_lush", "forest_floor", "mud", "beach_sand", "pothole",
        "patio_pavers", "laminate_light", "tile_mosaic", "garage_floor"
    ]:
        if not Tiles.FINAL_GROUND.has(required_ground):
            push_error("REGION_SMOKE_FINAL_GROUND_MISSING %s" % required_ground)
            quit(1)
            return
    for resource_path in [Tiles.FINAL_PROPS_PATH, Tiles.FINAL_SURFACES_PATH]:
        if not ResourceLoader.exists(resource_path):
            push_error("REGION_SMOKE_FINAL_ART_RESOURCE_MISSING %s" % resource_path)
            quit(1)
            return
