extends Control
class_name StartupMenu

const GAMEPLAY_SCENE_PATH: String = "res://gameplay.tscn"
const PRELOAD_PROGRESS_START: float = 8.0
const PRELOAD_PROGRESS_SPAN: float = 57.0
const STATUS_DOT_INTERVAL_SECONDS: float = 0.32
const STATUS_DOT_FRAMES := [".", "..", "..."]

@onready var _new_game_button: Button = $Center/MenuPanel/Menu/NewGameButton
@onready var _continue_button: Button = $Center/MenuPanel/Menu/ContinueButton
@onready var _status_label: Label = $Center/MenuPanel/Menu/StatusLabel
@onready var _progress_bar: ProgressBar = $Center/MenuPanel/Menu/LoadProgress

var _gameplay_scene: PackedScene = null
var _preload_requested: bool = false
var _preload_failed: bool = false
var _launching: bool = false
var _status_base_text: String = ""
var _status_dots_animated: bool = false
var _status_dot_elapsed: float = 0.0
var _status_dot_index: int = 0

func _ready() -> void:
    _new_game_button.pressed.connect(_on_new_game_pressed)
    _continue_button.tooltip_text = "Persistent save/continue is not implemented yet."
    _progress_bar.value = PRELOAD_PROGRESS_START
    _set_status("Menu ready. Loading game systems", true)
    call_deferred("_begin_gameplay_preload")

func _begin_gameplay_preload() -> void:
    # Let the lightweight menu paint before any heavy gameplay resources are requested.
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
    if _launching:
        return
    if not _preload_requested or _gameplay_scene != null or _preload_failed:
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
    if _launching:
        return
    _launching = true
    _new_game_button.disabled = true
    _continue_button.disabled = true
    _set_status("Finishing gameplay load", true)
    _progress_bar.value = maxf(_progress_bar.value, 68.0)

    # Paint the loading state before any synchronous fallback or world generation.
    await get_tree().process_frame
    var packed_scene: PackedScene = await _obtain_gameplay_scene()
    if packed_scene == null:
        _launching = false
        _new_game_button.disabled = false
        _set_status("Unable to load the gameplay scene.")
        _progress_bar.value = 0.0
        return

    _set_status("Generating island and activating the starting region", true)
    _progress_bar.value = 78.0
    await get_tree().process_frame

    # add_child() runs the gameplay root's existing synchronous boot. Keeping this
    # menu alive until that call returns means the player sees a truthful loading
    # surface instead of a long Godot splash/black frame while worldgen runs.
    # The dot animation intentionally uses ordinary process frames; if this legacy
    # synchronous boot blocks the main thread, the dots pause rather than lying
    # about responsiveness. Startup phase 2 remains the proper fix for that stall.
    var game: Node = packed_scene.instantiate()
    if game == null:
        _launching = false
        _new_game_button.disabled = false
        _set_status("Unable to create the gameplay scene.")
        return
    get_tree().root.add_child(game)
    get_tree().current_scene = game
    _progress_bar.value = 100.0
    queue_free()

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

func gameplay_resource_ready() -> bool:
    return _gameplay_scene != null

func is_launching_game() -> bool:
    return _launching
