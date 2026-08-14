extends SceneTree

const RegionGen = preload("res://scripts/ProceduralRegionGenerator.gd")

func _init() -> void:
    for seed_value in [1, 7, 42, 1337, 9001]:
        var spec: Dictionary = RegionGen.generate(seed_value)
        if int(spec.get("width", 0)) != RegionGen.REGION_W or int(spec.get("height", 0)) != RegionGen.REGION_H:
            push_error("REGION_SMOKE_DIMENSIONS_CHANGED")
            quit(1)
            return
        var result: Dictionary = RegionGen.validate(spec)
        if not bool(result.get("ok", false)):
            push_error("REGION_SMOKE_VALIDATION_FAILED seed=%d failures=%s" % [seed_value, str(result.get("failures", []))])
            quit(1)
            return
        var again: Dictionary = RegionGen.generate(seed_value)
        if spec.get("player_spawn") != again.get("player_spawn") or spec.get("biome_cells") != again.get("biome_cells") or spec.get("walls") != again.get("walls"):
            push_error("REGION_SMOKE_NONDETERMINISTIC seed=%d" % seed_value)
            quit(1)
            return
        var counts: Dictionary = result.get("biome_counts", {})
        for biome in RegionGen.BIOMES:
            if int(counts.get(biome, 0)) < 24:
                push_error("REGION_SMOKE_MISSING_BIOME seed=%d biome=%s" % [seed_value, biome])
                quit(1)
                return
    print("TICK_SURVIVAL_REGION_SMOKE_OK")
    quit(0)
