extends SceneTree

func _init() -> void:
    var scene_text := FileAccess.get_file_as_string("res://gameplay.tscn")
    assert(not scene_text.is_empty())
    assert(scene_text.contains("res://scripts/app/UtilitySimpleGameMain.gd"))

    var route_text := FileAccess.get_file_as_string("res://scripts/app/UtilitySimpleGameMain.gd")
    assert(not route_text.is_empty())
    assert(route_text.contains("extends FortificationGameMain"))
    assert(route_text.contains("GeneratorActions.ACTION_IDS"))
    assert(route_text.contains("UtilityRepairActions.ACTION_ID"))
    assert(route_text.contains("_simple_turns._begin_direct_action"))
    assert(route_text.contains("_simple_turns._complete_direct_action"))
    assert(route_text.contains("_portable_generators.snapshot()"))
    assert(route_text.contains("_power_network.snapshot()"))
    assert(not route_text.contains("TickKernel"))
    assert(not route_text.contains("TimedAction"))
    assert(not route_text.contains("ScheduledEvent"))
    print("SLICE9_UTILITIES_OK")
    quit(0)
