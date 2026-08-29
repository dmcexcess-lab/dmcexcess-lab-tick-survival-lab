extends RefCounted
class_name UtilityPoweredLightingSourceAdapter

## Thin System-33 -> System-27 bridge. The temporary DEV source adapter still owns
## fixture geometry; utility truth now decides whether each fixed source is active.
## The player flashlight remains independent until portable battery/equipment truth exists.

signal emitters_changed(emitters)

const FLASHLIGHT_ID: String = "dev.light.player_flashlight"

var _source: DemoLightingSourceAdapter = null
var _utilities: UtilityRuntimeState = null
var _service_id: String = ""
var _fixed_ids: Array[String] = []
var _signature: String = ""

func _init(
    source: DemoLightingSourceAdapter = null,
    utilities: UtilityRuntimeState = null,
    power_service_id: String = ""
) -> void:
    _source = source
    _utilities = utilities
    _service_id = power_service_id.strip_edges()
    if _source != null and _utilities != null and not _service_id.is_empty():
        _bind_known_fixed_emitters()
        var source_callable := Callable(self, "_on_source_emitters_changed")
        var power_callable := Callable(self, "_on_power_changed")
        var appliance_callable := Callable(self, "_on_appliances_changed")
        if not _source.emitters_changed.is_connected(source_callable):
            _source.emitters_changed.connect(source_callable)
        if not _utilities.power_changed.is_connected(power_callable):
            _utilities.power_changed.connect(power_callable)
        if not _utilities.appliances_changed.is_connected(appliance_callable):
            _utilities.appliances_changed.connect(appliance_callable)
        _signature = _current_signature()

func is_ready() -> bool:
    return _source != null and _source.is_ready() \
        and _utilities != null and _utilities.is_ready() \
        and not _service_id.is_empty()

func emitters() -> Array[LightEmitter]:
    var result: Array[LightEmitter] = []
    if not is_ready():
        return result
    _bind_known_fixed_emitters()
    for emitter: LightEmitter in _source.emitters():
        if emitter == null or not emitter.is_valid():
            continue
        if emitter.emitter_id == FLASHLIGHT_ID or _utilities.appliance_powered(emitter.emitter_id):
            result.append(emitter.copy())
    return result

func fixed_emitter_ids() -> Array[String]:
    return _fixed_ids.duplicate()

func _bind_known_fixed_emitters() -> void:
    if _source == null or _utilities == null or not _utilities.is_ready():
        return
    for emitter: LightEmitter in _source.emitters():
        if emitter == null or emitter.emitter_id == FLASHLIGHT_ID:
            continue
        if not _utilities.bind_appliance(emitter.emitter_id, &"fixed_light", _service_id, "", true):
            continue
        if not _fixed_ids.has(emitter.emitter_id):
            _fixed_ids.append(emitter.emitter_id)
    _fixed_ids.sort()

func _on_source_emitters_changed(_values: Array) -> void:
    _bind_known_fixed_emitters()
    _emit_if_changed()

func _on_power_changed(_revision: int, _reason: StringName) -> void:
    _emit_if_changed()

func _on_appliances_changed(_revision: int, _reason: StringName) -> void:
    _emit_if_changed()

func _emit_if_changed() -> void:
    if not is_ready():
        return
    var next_signature: String = _current_signature()
    if next_signature == _signature:
        return
    _signature = next_signature
    emitters_changed.emit(emitters())

func _current_signature() -> String:
    var parts: PackedStringArray = []
    if not is_ready():
        return "not_ready"
    for emitter: LightEmitter in emitters():
        parts.append(emitter.signature())
    return "|".join(parts)
