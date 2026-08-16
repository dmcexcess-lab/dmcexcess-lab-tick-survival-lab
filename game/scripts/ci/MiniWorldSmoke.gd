extends SceneTree

const MiniWorldStateClass = preload("res://scripts/MiniWorldState.gd")
const MiniRegionGen = preload("res://scripts/MiniRegionGenerator.gd")
const ExtractionRaidStateClass = preload("res://scripts/ExtractionRaidState.gd")

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

    if world_a.inside(Vector2i(-1, 0)) or world_a.inside(Vector2i(0, -1)):
        push_error("MINI_WORLD_SMOKE_NEGATIVE_COORD_ACCEPTED")
        quit(1)
        return
    if world_a.inside(Vector2i(MiniWorldStateClass.WORLD_W, 0)) or world_a.inside(Vector2i(0, MiniWorldStateClass.WORLD_H)):
        push_error("MINI_WORLD_SMOKE_OUTSIDE_COORD_ACCEPTED")
        quit(1)
        return

    var saw_special: Dictionary = {}
    var validated_focus: Dictionary = {}
    for coord_value in world_b.regions.keys():
        var coord: Vector2i = coord_value
        var focus := world_b.kind_at(coord)
        var seed_value := world_b.seed_at(coord)
        var spec: Dictionary = MiniRegionGen.generate(seed_value, MiniRegionGen.REGION_W, MiniRegionGen.REGION_H, focus)
        if int(spec.get("generator_version", 0)) != MiniRegionGen.GENERATOR_VERSION:
            push_error("MINI_WORLD_SMOKE_GENERATOR_VERSION_MISSING coord=%s" % str(coord))
            quit(1)
            return
        var result: Dictionary = MiniRegionGen.validate(spec)
        if not bool(result.get("ok", false)):
            push_error("MINI_WORLD_SMOKE_REGION_INVALID coord=%s focus=%s failures=%s" % [str(coord), focus, str(result.get("failures", []))])
            quit(1)
            return

        if not validated_focus.has(focus):
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
            validated_focus[focus] = true

        if not _has_prop(spec, "traffic_light") or not _has_prop(spec, "stop_sign"):
            push_error("MINI_WORLD_SMOKE_TRAFFIC_CONTROL_MISSING coord=%s focus=%s" % [str(coord), focus])
            quit(1)
            return

        for building_value in spec.get("building_rects", []):
            var building: Array = building_value
            if building.size() > 5:
                saw_special[str(building[5])] = true

    for required_family in ["trailer", "mansion", "duplex"]:
        if not saw_special.has(required_family):
            push_error("MINI_WORLD_SMOKE_MISSING_BUILDING_FAMILY %s" % required_family)
            quit(1)
            return
    if not saw_special.has("strip_mall_2") and not saw_special.has("strip_mall_3"):
        push_error("MINI_WORLD_SMOKE_MISSING_STRIP_MALL")
        quit(1)
        return

    var target: Vector2i = _first_region_of_kind(world_a, "commercial")
    var raid_a = ExtractionRaidStateClass.new()
    var raid_b = ExtractionRaidStateClass.new()
    raid_a.reset()
    raid_b.reset()
    if not raid_a.at_base() or raid_a.raid_active():
        push_error("MINI_WORLD_SMOKE_RAID_NOT_BASE_AFTER_RESET")
        quit(1)
        return

    var first_a: int = raid_a.begin_raid(world_a.world_seed, target, world_a.seed_at(target))
    var first_b: int = raid_b.begin_raid(world_b.world_seed, target, world_b.seed_at(target))
    if first_a <= 0 or first_a != first_b or not raid_a.raid_active():
        push_error("MINI_WORLD_SMOKE_RAID_FIRST_SEED_INVALID")
        quit(1)
        return
    if raid_a.begin_raid(world_a.world_seed, target, world_a.seed_at(target)) != 0:
        push_error("MINI_WORLD_SMOKE_REDEPLOY_ALLOWED_DURING_ACTIVE_RAID")
        quit(1)
        return
    if not raid_a.extract_to_base() or not raid_b.extract_to_base():
        push_error("MINI_WORLD_SMOKE_EXTRACTION_FAILED")
        quit(1)
        return
    if not raid_a.at_base() or raid_a.extracts_completed != 1:
        push_error("MINI_WORLD_SMOKE_EXTRACTION_DID_NOT_RETURN_BASE")
        quit(1)
        return

    var second_a: int = raid_a.begin_raid(world_a.world_seed, target, world_a.seed_at(target))
    var second_b: int = raid_b.begin_raid(world_b.world_seed, target, world_b.seed_at(target))
    if second_a <= 0 or second_a == first_a:
        push_error("MINI_WORLD_SMOKE_REPEAT_RAID_DID_NOT_REROLL")
        quit(1)
        return
    if second_a != second_b or raid_a.deployment_count(target) != 2:
        push_error("MINI_WORLD_SMOKE_RAID_SEQUENCE_NONDETERMINISTIC")
        quit(1)
        return

    var raid_spec: Dictionary = MiniRegionGen.generate(second_a, MiniRegionGen.REGION_W, MiniRegionGen.REGION_H, world_a.kind_at(target))
    if raid_spec.get("exit_cells", []).size() != 4:
        push_error("MINI_WORLD_SMOKE_RAID_EXTRACTIONS_MISSING")
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
