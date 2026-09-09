extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)

func _run() -> void:
    var packed := load("res://main.tscn") as PackedScene
    _check(packed != null, "Production scene loads")
    if packed == null:
        _finish()
        return
    var main := packed.instantiate()
    _check(main != null, "Production scene instantiates")
    if main == null:
        _finish()
        return
    root.add_child(main)
    await process_frame
    await process_frame
    _check(root.get_child_count() > 0, "Production root remains alive after startup frames")
    main.queue_free()
    await process_frame
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_NATIVE_PLAY_ACCEPTANCE_SMOKE: PASS")
    quit(0 if failures.is_empty() else 1)
