extends RefCounted
class_name WorldInteractionPlayerController

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")

signal action_started(target_id, action_id, action_serial)
signal action_finished(target_id, action_id, success, reason)

var _world: WorldState = null
var _affordances: InteractionAffordanceQuery = null
var _kernel: TickKernel = null
var _panel: WorldInteractionPanel = null
var _actor_id: String = ""
var _handlers: Dictionary = {}

func _init(
    world: WorldState = null,
    affordances: InteractionAffordanceQuery = null,
    kernel: TickKernel = null,
    panel: WorldInteractionPanel = null,
    actor_id: String = ""
) -> void:
    _world = world
    _affordances = affordances
    _kernel = kernel
    _panel = panel
    _actor_id = actor_id.strip_edges()
    if _panel != null:
        var callback := Callable(self, "_on_action_requested")
        if not _panel.action_requested.is_connected(callback):
            _panel.action_requested.connect(callback)

func is_ready() -> bool:
    return _world != null and _affordances != null and _affordances.is_ready() \
        and _kernel != null and _panel != null and not _actor_id.is_empty()

func register_handler(action_id: StringName, handler: Callable) -> bool:
    var key: String = String(action_id)
    if key.is_empty() or not handler.is_valid(): return false
    if _handlers.has(key): return _handlers[key] == handler
    _handlers[key] = handler
    return true

func submit_world_cell(cell: Vector2i) -> void:
    if not is_ready() or _kernel.is_hard_paused() or _kernel.has_active_action(_actor_id): return
    var target_ids: Dictionary = {}
    for channel: int in [Layers.Channel.OBJECT, Layers.Channel.STRUCTURE]:
        for entity_id: String in _world.entities_at(cell, channel): target_ids[entity_id] = true
    if target_ids.is_empty():
        _panel.close_panel()
        return
    var all_offers: Array[InteractionOffer] = _affordances.offers()
    for target_id: String in _ordered_targets(target_ids, all_offers):
        var target_offers: Array[InteractionOffer] = []
        var delegated_elsewhere: bool = false
        for offer: InteractionOffer in all_offers:
            if offer.target_entity_id != target_id or not offer.target_cells.has(cell): continue
            if offer.category == &"loot" or offer.category == &"crafting":
                delegated_elsewhere = true
                continue
            if _handlers.has(String(offer.action_id)):
                target_offers.append(offer.copy())
        if delegated_elsewhere:
            continue
        if not target_offers.is_empty():
            target_offers.sort_custom(func(a: InteractionOffer, b: InteractionOffer) -> bool:
                if a.presentation_priority != b.presentation_priority: return a.presentation_priority > b.presentation_priority
                return String(a.action_id) < String(b.action_id)
            )
            _panel.open_for_target(target_id, _target_label(target_id), target_offers)
            return
    _panel.close_panel()

func _on_action_requested(target_id: String, action_id: StringName) -> void:
    if not is_ready() or not _handlers.has(String(action_id)): return
    var handler: Callable = _handlers[String(action_id)]
    var value: Variant = handler.call(_actor_id, target_id, action_id)
    var accepted: bool = false
    var serial: int = 0
    var reason: String = "interaction_rejected"
    if typeof(value) == TYPE_DICTIONARY:
        var result: Dictionary = value
        accepted = bool(result.get("accepted", false))
        serial = int(result.get("action_serial", 0))
        reason = String(result.get("reason", reason))
    elif typeof(value) == TYPE_INT:
        serial = int(value)
        accepted = serial > 0
        reason = "" if accepted else reason
    if not accepted or serial <= 0:
        action_finished.emit(target_id, action_id, false, reason)
        return
    action_started.emit(target_id, action_id, serial)
    _kernel.run_until_stop()
    var success: bool = not _kernel.has_active_action(_actor_id)
    action_finished.emit(target_id, action_id, success, "completed" if success else "action_incomplete")

func _ordered_targets(target_ids: Dictionary, offers: Array[InteractionOffer]) -> Array[String]:
    var priority: Dictionary = {}
    for offer: InteractionOffer in offers:
        if target_ids.has(offer.target_entity_id):
            priority[offer.target_entity_id] = maxi(int(priority.get(offer.target_entity_id, -9999)), offer.presentation_priority)
    var result: Array[String] = []
    for key: Variant in target_ids.keys(): result.append(String(key))
    result.sort_custom(func(a: String, b: String) -> bool:
        var ap: int = int(priority.get(a, -9999))
        var bp: int = int(priority.get(b, -9999))
        if ap != bp: return ap > bp
        return a < b
    )
    return result

func _target_label(target_id: String) -> String:
    var entity: WorldEntityRecord = _world.entity(target_id)
    if entity == null: return "INTERACT"
    var label: String = String(entity.semantic_type)
    for prefix: String in ["prop.", "door.", "window."]:
        if label.begins_with(prefix): label = label.trim_prefix(prefix)
    return label.replace("_", " ").to_upper()
