extends RefCounted
class_name WorldInteractionPlayerController

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const TickRulesClass = preload("res://scripts/foundation/time/TickRules.gd")

signal action_started(target_id, action_id, action_serial)
signal action_finished(target_id, action_id, success, reason)

var _world: WorldState = null
var _affordances: InteractionAffordanceQuery = null
var _kernel: TickKernel = null
var _panel: WorldInteractionPanel = null
var _actor_id: String = ""
var _handlers: Dictionary = {}
var _delegated_handlers: Dictionary = {}

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
    if key.is_empty() or not handler.is_valid() or _delegated_handlers.has(key): return false
    if _handlers.has(key): return _handlers[key] == handler
    _handlers[key] = handler
    return true

## Delegated handlers own their own timing/UI lifecycle. They are used only when the
## unified target chooser needs to hand an offered action back to another canonical
## owner such as Crafting or Loot. No fake action serial is created here.
func register_delegated_handler(action_id: StringName, handler: Callable) -> bool:
    var key: String = String(action_id)
    if key.is_empty() or not handler.is_valid() or _handlers.has(key): return false
    if _delegated_handlers.has(key): return _delegated_handlers[key] == handler
    _delegated_handlers[key] = handler
    return true

func submit_world_cell(cell: Vector2i) -> void:
    if not is_ready() or _kernel.is_hard_paused() or _kernel.has_active_action(_actor_id): return
    var target_ids: Dictionary = {}
    for channel: int in [Layers.Channel.LOOSE_ITEM, Layers.Channel.OBJECT, Layers.Channel.STRUCTURE]:
        for entity_id: String in _world.entities_at(cell, channel): target_ids[entity_id] = true
    if target_ids.is_empty():
        _panel.close_panel()
        return
    var all_offers: Array[InteractionOffer] = _affordances.offers()
    for target_id: String in _ordered_targets(target_ids, all_offers):
        var target_offers: Array[InteractionOffer] = []
        for offer: InteractionOffer in all_offers:
            if offer.target_entity_id != target_id or not offer.target_cells.has(cell): continue
            var key: String = String(offer.action_id)
            if _handlers.has(key) or _delegated_handlers.has(key):
                target_offers.append(offer.copy())
        if not target_offers.is_empty():
            target_offers.sort_custom(func(a: InteractionOffer, b: InteractionOffer) -> bool:
                if a.presentation_priority != b.presentation_priority: return a.presentation_priority > b.presentation_priority
                return String(a.action_id) < String(b.action_id)
            )
            _panel.open_for_target(target_id, _target_label(target_id), target_offers)
            return
    _panel.close_panel()

func _on_action_requested(target_id: String, action_id: StringName) -> void:
    if not is_ready(): return
    var key: String = String(action_id)
    if _delegated_handlers.has(key):
        _run_delegated(target_id, action_id, _delegated_handlers[key])
        return
    if not _handlers.has(key): return
    var handler: Callable = _handlers[key]
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

    # Track the exact WHEN result. Merely observing that the actor is no longer busy is
    # insufficient: a failed Mechanical/commit action also leaves no active action.
    var resolved: Dictionary = {}
    var finished_callback := func(action: TimedAction) -> void:
        if action != null and action.serial == serial:
            resolved["status"] = action.status
            resolved["reason"] = action.reason
    _kernel.action_finished.connect(finished_callback)
    _kernel.run_until_stop()
    if _kernel.action_finished.is_connected(finished_callback):
        _kernel.action_finished.disconnect(finished_callback)

    var status: int = int(resolved.get("status", -1))
    var success: bool = status == TickRulesClass.ActionStatus.COMPLETED
    var final_reason: String = String(resolved.get("reason", ""))
    if success and final_reason.is_empty():
        final_reason = "completed"
    elif not success and final_reason.is_empty():
        final_reason = "action_incomplete"
    action_finished.emit(target_id, action_id, success, final_reason)

func _run_delegated(target_id: String, action_id: StringName, handler: Callable) -> void:
    var value: Variant = handler.call(_actor_id, target_id, action_id)
    var success: bool = false
    var reason: String = "delegated_interaction_failed"
    if typeof(value) == TYPE_DICTIONARY:
        var result: Dictionary = value
        success = bool(result.get("success", result.get("accepted", false)))
        reason = String(result.get("reason", "" if success else reason))
    elif typeof(value) == TYPE_BOOL:
        success = bool(value)
        reason = "" if success else reason
    action_finished.emit(target_id, action_id, success, reason)

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
    for prefix: String in ["prop.", "door.", "window.", "item."]:
        if label.begins_with(prefix): label = label.trim_prefix(prefix)
    return label.replace("_", " ").to_upper()
