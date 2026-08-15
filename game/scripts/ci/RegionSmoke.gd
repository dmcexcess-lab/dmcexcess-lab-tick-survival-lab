extends SceneTree

const RegionGen = preload("res://scripts/ProceduralRegionGenerator.gd")

func _init() -> void:
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
