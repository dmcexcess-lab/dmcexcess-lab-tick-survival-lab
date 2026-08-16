extends SceneTree

const Art = preload("res://scripts/reboot/RebootArt.gd")
const Generator = preload("res://scripts/reboot/RebootSiteGenerator.gd")
const Library = preload("res://scripts/reboot/RebootPrefabLibrary.gd")

const TEST_SEEDS: Array[int] = [105832, 209771, 314159, 420691, 531117, 684209, 771331, 902417]

func _init() -> void:
    var prefab := _ci_cabin()
    var check: Dictionary = Library.validate(prefab)
    if not bool(check.get("ok", false)):
        push_error("REBOOT_PREFAB_INVALID_SOURCE %s" % str(check.get("failures", [])))
        quit(1)
        return

    var normalized: Dictionary = Library.normalize_for_save(prefab)
    if int(normalized.get("width", 0)) != 7 or int(normalized.get("height", 0)) != 7:
        push_error("REBOOT_PREFAB_TRIM_FAILED size=%dx%d" % [int(normalized.get("width", 0)), int(normalized.get("height", 0))])
        quit(1)
        return

    var record: Dictionary = Library.to_storage_record(normalized)
    var restored: Dictionary = Library.from_storage_record(record)
    var restored_check: Dictionary = Library.validate(restored)
    if not bool(restored_check.get("ok", false)):
        push_error("REBOOT_PREFAB_ROUNDTRIP_INVALID %s" % str(restored_check.get("failures", [])))
        quit(1)
        return
    if restored.get("ground", {}) != normalized.get("ground", {}) or restored.get("walls", {}) != normalized.get("walls", {}) or restored.get("doors", {}) != normalized.get("doors", {}) or restored.get("door_axes", {}) != normalized.get("door_axes", {}) or restored.get("windows", {}) != normalized.get("windows", {}) or restored.get("props", {}) != normalized.get("props", {}) or restored.get("prop_blocks", {}) != normalized.get("prop_blocks", {}):
        push_error("REBOOT_PREFAB_ROUNDTRIP_CHANGED_DATA")
        quit(1)
        return

    var broken: Dictionary = normalized.duplicate(true)
    broken["walls"].erase(Vector2i(2, 6))
    var broken_check: Dictionary = Library.validate(broken)
    if bool(broken_check.get("ok", false)):
        push_error("REBOOT_PREFAB_ACCEPTED_BROKEN_DOOR")
        quit(1)
        return

    var stamped_count := 0
    for seed in TEST_SEEDS:
        var a: Dictionary = Generator.generate("rural_road", seed)
        var b: Dictionary = Generator.generate("rural_road", seed)
        var stamp_a: Dictionary = Library.try_stamp_random(a, [normalized], seed)
        var stamp_b: Dictionary = Library.try_stamp_random(b, [normalized], seed)
        if bool(stamp_a.get("stamped", false)) != bool(stamp_b.get("stamped", false)):
            push_error("REBOOT_PREFAB_NONDETERMINISTIC_DECISION seed=%d" % seed)
            quit(1)
            return
        if not bool(stamp_a.get("stamped", false)):
            continue
        stamped_count += 1
        if stamp_a.get("origin") != stamp_b.get("origin"):
            push_error("REBOOT_PREFAB_NONDETERMINISTIC_ORIGIN seed=%d" % seed)
            quit(1)
            return
        if a.get("ground") != b.get("ground") or a.get("walls") != b.get("walls") or a.get("doors") != b.get("doors") or a.get("door_axes") != b.get("door_axes") or a.get("windows") != b.get("windows") or a.get("props") != b.get("props") or a.get("blocked") != b.get("blocked") or a.get("user_prefabs_used") != b.get("user_prefabs_used"):
            push_error("REBOOT_PREFAB_NONDETERMINISTIC_STAMP seed=%d" % seed)
            quit(1)
            return
        var generated_check: Dictionary = Generator.validate(a)
        if not bool(generated_check.get("ok", false)):
            push_error("REBOOT_PREFAB_BROKE_RURAL_VALIDATION seed=%d %s" % [seed, str(generated_check.get("failures", []))])
            quit(1)
            return
        var used: Array = a.get("user_prefabs_used", [])
        if used.size() != 1 or str(used[0].get("name", "")) != "CI Cabin":
            push_error("REBOOT_PREFAB_USAGE_METADATA seed=%d" % seed)
            quit(1)
            return
        var origin: Vector2i = stamp_a.get("origin", Vector2i(-1, -1))
        var world_door := origin + Vector2i(3, 6)
        if str(a.get("door_axes", {}).get(world_door, "")) != "h":
            push_error("REBOOT_PREFAB_DOOR_AXIS_LOST seed=%d" % seed)
            quit(1)
            return

    if stamped_count < 1:
        push_error("REBOOT_PREFAB_NEVER_FOUND_SAFE_FOOTPRINT")
        quit(1)
        return

    print("REBOOT_PREFAB_SMOKE_OK stamped=%d" % stamped_count)
    quit(0)

func _ci_cabin() -> Dictionary:
    var prefab: Dictionary = Library.empty_prefab("CI Cabin")
    for y in range(7):
        for x in range(7):
            prefab["ground"][Vector2i(x, y)] = Art.G_WOOD
    for x in range(7):
        prefab["walls"][Vector2i(x, 0)] = Art.S_WALL_HOUSE
        prefab["walls"][Vector2i(x, 6)] = Art.S_WALL_HOUSE
    for y in range(7):
        prefab["walls"][Vector2i(0, y)] = Art.S_WALL_HOUSE
        prefab["walls"][Vector2i(6, y)] = Art.S_WALL_HOUSE

    var window := Vector2i(3, 0)
    prefab["walls"].erase(window)
    prefab["windows"][window] = Art.S_WINDOW

    var door := Vector2i(3, 6)
    prefab["walls"].erase(door)
    prefab["doors"][door] = Art.S_DOOR_CLOSED
    prefab["door_axes"][door] = "h"

    var sofa := Vector2i(2, 3)
    prefab["props"][sofa] = Art.P_SOFA
    prefab["prop_blocks"][sofa] = true
    return prefab
