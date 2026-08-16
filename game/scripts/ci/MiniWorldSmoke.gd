extends SceneTree

const MiniWorldStateClass = preload("res://scripts/MiniWorldState.gd")
const MiniRegionGen = preload("res://scripts/MiniRegionGenerator.gd")

func _init() -> void:
    var world_a = MiniWorldStateClass.new()
    var world_b = MiniWorldStateClass.new()
    world_a.reset(424242)
    world_b.reset(424242)

    if world_a.regions != world_b.regions:
        push_error("MINI_WORLD_SMOKE_NONDETERMINISTIC_WORLD")
        quit(1)
        return
    if world_a.regions.size() != MiniWorldStateClass.WORLD_W * MiniWorldStateClass.WORLD_H:
        push_error("MINI_WORLD_SMOKE_WRONG_REGION_COUNT")
        quit(1)
        return

    var kinds: Dictionary = {}
    for entry_value in world_a.regions.values():
        var entry: Dictionary = entry_value
        kinds[str(entry.get("kind", ""))] = true
    for required_kind in MiniWorldStateClass.REGION_KINDS:
        if not kinds.has(required_kind):
            push_error("MINI_WORLD_SMOKE_MISSING_REGION_KIND %s" % required_kind)
            quit(1)
            return

    world_a.current_region = Vector2i.ZERO
    if world_a.can_move(Vector2i.LEFT) or world_a.can_move(Vector2i.UP):
        push_error("MINI_WORLD_SMOKE_WORLD_EDGE_OPEN")
        quit(1)
        return
    if not world_a.can_move(Vector2i.RIGHT) or not world_a.can_move(Vector2i.DOWN):
        push_error("MINI_WORLD_SMOKE_VALID_NEIGHBOR_BLOCKED")
        quit(1)
        return

    var saw_special: Dictionary = {}
    for focus in MiniWorldStateClass.REGION_KINDS:
        var coord := _first_region_of_kind(world_b, focus)
        var seed_value := world_b.seed_at(coord)
        var spec: Dictionary = MiniRegionGen.generate(seed_value, MiniRegionGen.REGION_W, MiniRegionGen.REGION_H, focus)
        if int(spec.get("generator_version", 0)) != MiniRegionGen.GENERATOR_VERSION:
            push_error("MINI_WORLD_SMOKE_GENERATOR_VERSION_MISSING focus=%s" % focus)
            quit(1)
            return
        var result: Dictionary = MiniRegionGen.validate(spec)
        if not bool(result.get("ok", false)):
            push_error("MINI_WORLD_SMOKE_REGION_INVALID focus=%s failures=%s" % [focus, str(result.get("failures", []))])
            quit(1)
            return

        var again: Dictionary = MiniRegionGen.generate(seed_value, MiniRegionGen.REGION_W, MiniRegionGen.REGION_H, focus)
        if (
            spec.get("walls") != again.get("walls")
            or spec.get("doors") != again.get("doors")
            or spec.get("props") != again.get("props")
            or spec.get("building_rects") != again.get("building_rects")
            or spec.get("parking_lots") != again.get("parking_lots")
        ):
            push_error("MINI_WORLD_SMOKE_NONDETERMINISTIC_REGION focus=%s" % focus)
            quit(1)
            return

        if not _has_prop(spec, "traffic_light") or not _has_prop(spec, "stop_sign"):
            push_error("MINI_WORLD_SMOKE_TRAFFIC_CONTROL_MISSING focus=%s" % focus)
            quit(1)
            return

        for building_value in spec.get("building_rects", []):
            var building: Array = building_value
            if building.size() > 5:
                saw_special[str(building[5])] = true

    for required_family in ["trailer", "mansion", "duplex", "strip_mall_2"]:
        if required_family == "strip_mall_2":
            if not saw_special.has("strip_mall_2") and not saw_special.has("strip_mall_3"):
                push_error("MINI_WORLD_SMOKE_MISSING_STRIP_MALL")
                quit(1)
                return
        elif not saw_special.has(required_family):
            push_error("MINI_WORLD_SMOKE_MISSING_BUILDING_FAMILY %s" % required_family)
            quit(1)
            return

    print("TICK_SURVIVAL_MINI_WORLD_SMOKE_OK")
    quit(0)

func _first_region_of_kind(world, kind: String) -> Vector2i:
    for coord_value in world.regions.keys():
        var coord: Vector2i = coord_value
        if world.kind_at(coord) == kind:
            return coord
    return MiniWorldStateClass.CENTER

func _has_prop(spec: Dictionary, kind: String) -> bool:
    for prop_value in spec.get("props", []):
        var entry: Array = prop_value
        if str(entry[1]) == kind:
            return true
    return false
