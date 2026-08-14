extends Node
class_name SafariInputGuard

# Mobile Safari can synthesize a mouse click around the same physical touch.
# MapPreview already suppresses post-touch mouse events, but the first synthetic
# mouse event can arrive before the first ScreenTouch. On touch-capable Web
# devices, swallow mouse-button events globally before _unhandled_input sees
# them. Real ScreenTouch events remain authoritative.

var web_touch_device := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if OS.has_feature("web"):
        var result = JavaScriptBridge.eval("(navigator.maxTouchPoints || 0) > 0", true)
        web_touch_device = bool(result)

func _input(event: InputEvent) -> void:
    if not web_touch_device:
        return
    if event is InputEventMouseButton:
        get_viewport().set_input_as_handled()
