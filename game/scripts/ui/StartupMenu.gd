extends Control
class_name StartupMenu

const GAMEPLAY_SCENE_PATH: String = "res://gameplay.tscn"
const DurableSessionStoreClass = preload("res://scripts/persistence/DurableSessionStore.gd")
const WorldBootstrapClass = preload("res://scripts/generation/integration/ProductionWorldBootstrap.gd")
const PRELOAD_PROGRESS_START: float = 8.0
const PRELOAD_PROGRESS_SPAN: float = 57.0
const STATUS_DOT_INTERVAL_SECONDS: float = 0.32
const STATUS_DOT_FRAMES := [".", "..", "..."]
const NEW_GAME_BOOT_ATTEMPTS: int = 6

@onready var _new_game_button: Button = $Center/MenuPanel/Menu/NewGameButton
@onready var _continue_button: Button = $Center/MenuPanel/Menu/ContinueButton
@onready var _status_label: Label = $Center/MenuPanel/Menu/StatusLabel
@onready var _progress_bar: ProgressBar = $Center/MenuPanel/Menu/LoadProgress
@onready var _hint: Label = $Center/MenuPanel/Menu/Hint

var _gameplay_scene: PackedScene = null
var _preload_requested: bool = false
var _preload_failed: bool = false
var _launching: bool = false
var _status_base_text: String = ""
var _status_dots_animated: bool = false
var _status_dot_elapsed: float = 0.0
var _status_dot_index: int = 0
var _session_store: DurableSessionStore = null
var _continue_session: Dictionary = {}

func _ready() -> void:
    _new_game_button.pressed.connect(_on_new_game_pressed, CONNECT_DEFERRED)
    _continue_button.pressed.connect(_on_continue_pressed, CONNECT_DEFERRED)
    _session_store = DurableSessionStoreClass.new()
    _refresh_continue_state()
    _progress_bar.value = PRELOAD_PROGRESS_START
    _set_status("Menu ready. Loading game systems", true)
    call_deferred("_begin_gameplay_preload")

func _begin_gameplay_preload() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if _launching or _gameplay_scene != null or _preload_requested:
        return
    var error: Error = ResourceLoader.load_threaded_request(GAMEPLAY_SCENE_PATH, "PackedScene", false)
    if error != OK:
        _preload_failed = true
        _set_status("Game preload unavailable. NEW GAME will load it directly.")
        _progress_bar.value = PRELOAD_PROGRESS_START
        return
    _preload_requested = true
    set_process(true)

func _process(delta: float) -> void:
    _advance_loading_indicator(delta)
    if _launching or not _preload_requested or _gameplay_scene != null or _preload_failed:
        return
    var progress: Array = []
    var status: int = ResourceLoader.load_threaded_get_status(GAMEPLAY_SCENE_PATH, progress)
    if not progress.is_empty():
        var ratio: float = clampf(float(progress[0]), 0.0, 1.0)
        _progress_bar.value = PRELOAD_PROGRESS_START + PRELOAD_PROGRESS_SPAN * ratio
    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            if _status_base_text != "Loading gameplay systems":
                _set_status("Loading gameplay systems", true)
        ResourceLoader.THREAD_LOAD_LOADED:
            var resource: Resource = ResourceLoader.load_threaded_get(GAMEPLAY_SCENE_PATH)
            _gameplay_scene = resource as PackedScene
            if _gameplay_scene == null:
                _preload_failed = true
                _set_status("Preload finished without a playable scene. NEW GAME will retry.")
                return
            _progress_bar.value = PRELOAD_PROGRESS_START + PRELOAD_PROGRESS_SPAN
            _set_status("Game systems ready. World generation starts with NEW GAME.")
            set_process(false)
        ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            _preload_failed = true
            _set_status("Game preload failed. NEW GAME will retry directly.")
            set_process(false)

func _on_new_game_pressed() -> void:
    await _launch_game({})

func _on_continue_pressed() -> void:
    if _launching:
        return
    var loaded: Dictionary = _session_store.load_best()
    if not bool(loaded.get("ok", false)):
        _refresh_continue_state()
        _set_status("No valid compatible save is available.")
        return
    await _launch_game(loaded.get("session", {}))

func _launch_game(session: Dictionary) -> void:
    if _launching:
        return
    _launching = true
    _new_game_button.disabled = true
    _continue_button.disabled = true
    _set_status("Finishing gameplay load", true)
    _progress_bar.value = maxf(_progress_bar.value, 68.0)
    await get_tree().process_frame
    var packed_scene: PackedScene = await _obtain_gameplay_scene()
    if packed_scene == null:
        _launching = false
        _new_game_button.disabled = false
        _refresh_continue_state()
        _set_status("Unable to load the gameplay scene.")
        _progress_bar.value = 0.0
        return
    _set_status("Restoring persistent world" if not session.is_empty() else "Generating island and activating the starting region", true)
    _progress_bar.value = 78.0
    await get_tree().process_frame

    var game: Node = null
    var boot_error: String = "gameplay_boot_failed"
    var attempt_limit: int = 1 if not session.is_empty() else NEW_GAME_BOOT_ATTEMPTS
    for attempt in range(attempt_limit):
        game = packed_scene.instantiate()
        if game == null:
            boot_error = "scene_instantiation_failed"
            break
        if not session.is_empty():
            if not game.has_method("configure_continue_session") or not bool(game.call("configure_continue_session", session)):
                game.queue_free()
                game = null
                boot_error = "incompatible_save"
                break
        get_tree().root.add_child(game)
        var boot_ok := false
        if game.has_method("session_boot_ok"):
            boot_ok = bool(game.call("session_boot_ok"))
        elif game.has_method("canonical_boot_ok"):
            boot_ok = bool(game.call("canonical_boot_ok"))
        if boot_ok:
            break
        if game.has_method("session_boot_error"):
            boot_error = String(game.call("session_boot_error"))
        elif not WorldBootstrapClass.last_failure().is_empty():
            boot_error = WorldBootstrapClass.last_failure()
        game.queue_free()
        game = null
        await get_tree().process_frame
        if not session.is_empty() or not _retryable_generation_failure(boot_error) or attempt + 1 >= attempt_limit:
            break
        _set_status("Generated island was invalid. Trying another procedural seed", true)
        await get_tree().process_frame

    if game == null:
        _launching = false
        _new_game_button.disabled = false
        _refresh_continue_state()
        if session.is_empty():
            _set_status("NEW GAME failed: %s" % boot_error)
        elif boot_error == "incompatible_save":
            _set_status("Saved game is incompatible. The previous save was preserved.")
        else:
            _set_status("Continue failed safely: %s. Saved files were preserved." % boot_error)
        _progress_bar.value = PRELOAD_PROGRESS_START + PRELOAD_PROGRESS_SPAN
        return
    get_tree().current_scene = game
    _progress_bar.value = 100.0
    queue_free()

func _retryable_generation_failure(reason: String) -> bool:
    return reason.begins_with("global_generation:") \
        or reason == "no_generated_area_sites" \
        or reason.begins_with("spawn_projection_failed:") \
        or reason.begins_with("spawn_request_invalid:") \
        or reason.begins_with("spawn_area_generation_failed:") \
        or reason.begins_with("spawn_cell_unavailable:") \
        or reason == "no_spawnable_area"

func _refresh_continue_state() -> void:
    if _session_store == null:
        return
    var loaded: Dictionary = _session_store.load_best()
    _continue_session = loaded.get("session", {}) if bool(loaded.get("ok", false)) else {}
    _continue_button.disabled = _continue_session.is_empty()
    if _continue_session.is_empty():
        _continue_button.text = "CONTINUE — NO SAVE"
        _continue_button.tooltip_text = "No valid compatible durable save is available."
    elif String(loaded.get("source", "")) == "backup":
        _continue_button.text = "CONTINUE — RECOVERED SAVE"
        _continue_button.tooltip_text = "The primary save was invalid; Continue will use the last valid backup."
    else:
        _continue_button.text = "CONTINUE"
        _continue_button.tooltip_text = "Resume the persistent game."
    var storage: Dictionary = _session_store.storage_status()
    if not bool(storage.get("writable", false)):
        _hint.text = "Saving is unavailable in this browser/device. Progress will not survive closing the game."
    elif not bool(storage.get("persistent", true)):
        _hint.text = "Browser storage is temporary here. Saves may not survive closing this tab/browser."
    else:
        _hint.text = "NEW GAME creates a fresh world. CONTINUE resumes the saved persistent world."

func _obtain_gameplay_scene() -> PackedScene:
    if _gameplay_scene != null:
        return _gameplay_scene
    if _preload_requested and not _preload_failed:
        while _gameplay_scene == null and not _preload_failed:
            var progress: Array = []
            var status: int = ResourceLoader.load_threaded_get_status(GAMEPLAY_SCENE_PATH, progress)
            if status == ResourceLoader.THREAD_LOAD_LOADED:
                var resource: Resource = ResourceLoader.load_threaded_get(GAMEPLAY_SCENE_PATH)
                _gameplay_scene = resource as PackedScene
                break
            if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
                _preload_failed = true
                break
            if not progress.is_empty():
                var ratio: float = clampf(float(progress[0]), 0.0, 1.0)
                _progress_bar.value = PRELOAD_PROGRESS_START + PRELOAD_PROGRESS_SPAN * ratio
            await get_tree().process_frame
    if _gameplay_scene == null:
        _set_status("Loading gameplay systems", true)
        await get_tree().process_frame
        _gameplay_scene = load(GAMEPLAY_SCENE_PATH) as PackedScene
    return _gameplay_scene

func _set_status(text_value: String, animate_dots: bool = false) -> void:
    _status_base_text = text_value
    _status_dots_animated = animate_dots
    _status_dot_elapsed = 0.0
    _status_dot_index = 0
    if _status_label == null:
        return
    _status_label.text = text_value + STATUS_DOT_FRAMES[0] if animate_dots else text_value
    if animate_dots:
        set_process(true)

func _advance_loading_indicator(delta: float) -> void:
    if not _status_dots_animated or _status_label == null:
        return
    _status_dot_elapsed += maxf(0.0, delta)
    while _status_dot_elapsed >= STATUS_DOT_INTERVAL_SECONDS:
        _status_dot_elapsed -= STATUS_DOT_INTERVAL_SECONDS
        _status_dot_index = (_status_dot_index + 1) % STATUS_DOT_FRAMES.size()
    _status_label.text = _status_base_text + String(STATUS_DOT_FRAMES[_status_dot_index])
