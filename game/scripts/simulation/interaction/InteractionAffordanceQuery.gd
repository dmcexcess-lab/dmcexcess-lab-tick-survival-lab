extends RefCounted
class_name InteractionAffordanceQuery

const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Change = preload("res://scripts/foundation/world/WorldChange.gd")
const PerceptionClass = preload("res://scripts/simulation/perception/ObserverPerceptionService.gd")
const PerformanceTelemetry = preload("res://scripts/foundation/diagnostics/PerformanceTelemetry.gd")

## System-29 composition/query owner. It discovers actor-local reachable loose items,
## OBJECT and STRUCTURE occupancy, asks real mechanic providers for offers, then applies
## current System-23 knowledge before exposing player-facing descriptors.

signal affordances_changed(reason: StringName)

const INTERACTABLE_CHANNELS: Array[int] = [Layers.Channel.LOOSE_ITEM, Layers.Channel.OBJECT, Layers.Channel.STRUCTURE]

var _world: WorldState = null
var _reach: WorldInteractionReachQuery = null
var _perception: ObserverPerceptionService = null
var _actor_id: String = ""
var _providers: Array[InteractionOfferProvider] = []
var _reachable_cell_cache: Dictionary = {}
var _provider_batch_dirty: bool = false
var _query_count: int = 0

func _init(
    world_state: WorldState = null,
    reach_query: WorldInteractionReachQuery = null,
    perception_service: ObserverPerceptionService = null,
    actor_id: String = ""
) -> void:
    _world = world_state
    _reach = reach_query
    _perception = perception_service
    _actor_id = actor_id.strip_edges()
    _connect_sources()
    _rebuild_reachable_cell_cache()

func is_ready() -> bool:
    return _world != null \
        and _reach != null and _reach.is_ready() \
        and _perception != null and _perception.is_ready() \
        and not _actor_id.is_empty() \
        and _perception.observer_id() == _actor_id

func actor_id() -> String:
    return _actor_id

func register_provider(provider: InteractionOfferProvider) -> bool:
    if provider == null or not provider.is_ready() or _providers.has(provider):
        return false
    _providers.append(provider)
    var callback := Callable(self, "_on_provider_availability_changed")
    if not provider.availability_changed.is_connected(callback):
        provider.availability_changed.connect(callback)
    affordances_changed.emit(&"provider_registered")
    return true

func provider_count() -> int:
    return _providers.size()

func reachable_cells() -> Array[Vector2i]:
    if not is_ready():
        return []
    return _reach.reachable_cells(_actor_id, WorldInteractionReachQuery.CONTACT_FORWARD)

func candidate_target_ids() -> Array[String]:
    if not is_ready():
        return []
    return _reach.candidate_interactable_ids(_actor_id, WorldInteractionReachQuery.CONTACT_FORWARD)

func offers() -> Array[InteractionOffer]:
    var started: int = Time.get_ticks_usec()
    var result: Array[InteractionOffer] = []
    if not is_ready():
        _record_query(started)
        return result
    var candidates: Array[String] = candidate_target_ids()
    if candidates.is_empty() or _providers.is_empty():
        _record_query(started)
        return result
    var candidate_set: Dictionary = {}
    for target_id: String in candidates:
        candidate_set[target_id] = true

    for provider: InteractionOfferProvider in _providers:
        if provider == null or not provider.is_ready():
            continue
        var provided: Array[InteractionOffer] = provider.offers_for_actor(_actor_id, candidates)
        for offer: InteractionOffer in provided:
            if _offer_is_current(offer, candidate_set):
                result.append(offer.copy())
    result.sort_custom(_offer_less)
    _record_query(started)
    return result

func highlight_descriptors() -> Array[Dictionary]:
    var by_target: Dictionary = {}
    if not is_ready():
        return []
    for offer: InteractionOffer in offers():
        var placement: WorldPlacement = _world.placement(offer.target_entity_id)
        if placement == null or placement.channel not in INTERACTABLE_CHANNELS:
            continue
        var visible_cells: Array[Vector2i] = []
        for cell: Vector2i in placement.world_cells():
            if _perception.knowledge_state(cell) == PerceptionClass.KnowledgeState.VISIBLE:
                visible_cells.append(cell)
        if visible_cells.is_empty():
            continue
        visible_cells.sort_custom(_cell_less)
        if not by_target.has(offer.target_entity_id):
            by_target[offer.target_entity_id] = {
                "target_entity_id": offer.target_entity_id,
                "category": offer.category,
                "presentation_priority": offer.presentation_priority,
                "target_anchor": placement.anchor,
                "visible_cells": visible_cells,
                "action_ids": [String(offer.action_id)],
                "labels": [offer.label],
            }
            continue
        var descriptor: Dictionary = by_target[offer.target_entity_id]
        descriptor["presentation_priority"] = maxi(int(descriptor.get("presentation_priority", 0)), offer.presentation_priority)
        var action_ids: Array = descriptor.get("action_ids", [])
        var action_string: String = String(offer.action_id)
        if not action_ids.has(action_string):
            action_ids.append(action_string)
            action_ids.sort()
            descriptor["action_ids"] = action_ids
        var labels: Array = descriptor.get("labels", [])
        if not labels.has(offer.label):
            labels.append(offer.label)
            labels.sort()
            descriptor["labels"] = labels
        by_target[offer.target_entity_id] = descriptor

    var result: Array[Dictionary] = []
    for value: Variant in by_target.values():
        result.append((value as Dictionary).duplicate(true))
    result.sort_custom(_descriptor_less)
    return result

func _record_query(started_usec: int) -> void:
    _query_count += 1
    PerformanceTelemetry.record_timing(&"interaction_query", Time.get_ticks_usec() - started_usec)
    PerformanceTelemetry.record_value(&"interaction_queries", _query_count)

func _offer_is_current(offer: InteractionOffer, candidate_set: Dictionary) -> bool:
    if offer == null or not offer.is_valid() or not offer.available:
        return false
    if offer.actor_id != _actor_id or not candidate_set.has(offer.target_entity_id):
        return false
    if not _reach.supports_profile(offer.reach_profile_id) \
        or not _reach.target_reachable(_actor_id, offer.target_entity_id, offer.reach_profile_id):
        return false
    var placement: WorldPlacement = _world.placement(offer.target_entity_id)
    if placement == null or placement.channel not in INTERACTABLE_CHANNELS:
        return false
    return _same_cell_set(offer.target_cells, placement.world_cells())

func _same_cell_set(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
    if a.size() != b.size():
        return false
    var seen: Dictionary = {}
    for cell: Vector2i in a:
        seen[cell] = true
    for cell: Vector2i in b:
        if not seen.has(cell):
            return false
    return true

func _connect_sources() -> void:
    if _world != null:
        var changed := Callable(self, "_on_world_changed")
        var batch_changed := Callable(self, "_on_world_batch_changed")
        var reset := Callable(self, "_on_world_reset")
        if not _world.changed.is_connected(changed): _world.changed.connect(changed)
        if not _world.batch_changed.is_connected(batch_changed): _world.batch_changed.connect(batch_changed)
        if not _world.world_reset.is_connected(reset): _world.world_reset.connect(reset)
    if _perception != null:
        var changed := Callable(self, "_on_perception_changed")
        if not _perception.perception_changed.is_connected(changed): _perception.perception_changed.connect(changed)

func _rebuild_reachable_cell_cache() -> void:
    _reachable_cell_cache.clear()
    if _reach == null or not _reach.is_ready() or _actor_id.is_empty():
        return
    for cell: Vector2i in _reach.reachable_cells(_actor_id, WorldInteractionReachQuery.CONTACT_FORWARD):
        _reachable_cell_cache[cell] = true

func _change_intersects_cached_reach(change: WorldChange) -> bool:
    if _reachable_cell_cache.is_empty(): return false
    for cell: Vector2i in change.before_cells:
        if _reachable_cell_cache.has(cell): return true
    for cell: Vector2i in change.after_cells:
        if _reachable_cell_cache.has(cell): return true
    return false

func _dirty_rect_intersects_cached_reach(rect: Rect2i) -> bool:
    if rect.size.x <= 0 or rect.size.y <= 0 or _reachable_cell_cache.is_empty(): return false
    for value: Variant in _reachable_cell_cache.keys():
        if rect.has_point(value): return true
    return false

func _on_world_changed(change: WorldChange) -> void:
    if change == null or _world.is_change_batch_active(): return
    if change.entity_id == _actor_id:
        _rebuild_reachable_cell_cache()
        affordances_changed.emit(&"actor_changed")
        return
    if change.kind not in [Change.Kind.PLACEMENT_SET, Change.Kind.PLACEMENT_REMOVED, Change.Kind.ENTITY_REMOVED]:
        return
    if not _change_intersects_cached_reach(change):
        return
    if change.affects_channel(Layers.Channel.LOOSE_ITEM):
        affordances_changed.emit(&"reachable_loose_item_changed")
    elif change.affects_channel(Layers.Channel.OBJECT):
        affordances_changed.emit(&"reachable_object_changed")
    elif change.affects_channel(Layers.Channel.STRUCTURE):
        affordances_changed.emit(&"reachable_structure_changed")

func _on_world_batch_changed(batch: WorldChangeBatch) -> void:
    if batch == null: return
    var actor: WorldPlacement = _world.placement(_actor_id)
    var actor_dirty: bool = false
    if batch.channel_changed(Layers.Channel.ACTOR):
        var actor_rect: Rect2i = batch.dirty_rect_for_channel(Layers.Channel.ACTOR)
        actor_dirty = actor != null and actor_rect.has_point(actor.anchor)
        if not actor_dirty: actor_dirty = _dirty_rect_intersects_cached_reach(actor_rect)
    if actor_dirty:
        _rebuild_reachable_cell_cache()
        affordances_changed.emit(&"actor_batch_changed")
        _provider_batch_dirty = false
        return
    var interactable_dirty: bool = false
    for channel: int in INTERACTABLE_CHANNELS:
        if batch.channel_changed(channel) and _dirty_rect_intersects_cached_reach(batch.dirty_rect_for_channel(channel)):
            interactable_dirty = true
            break
    if interactable_dirty or _provider_batch_dirty:
        _provider_batch_dirty = false
        affordances_changed.emit(&"world_batch_changed")

func _on_world_reset() -> void:
    _provider_batch_dirty = false
    _reachable_cell_cache.clear()
    affordances_changed.emit(&"world_reset")

func _on_perception_changed(_reason: StringName) -> void:
    affordances_changed.emit(&"perception_changed")

func _on_provider_availability_changed(_reason: StringName) -> void:
    if _world != null and _world.is_change_batch_active():
        _provider_batch_dirty = true
        return
    affordances_changed.emit(&"provider_availability_changed")

func _offer_less(a: InteractionOffer, b: InteractionOffer) -> bool:
    if a.presentation_priority != b.presentation_priority: return a.presentation_priority > b.presentation_priority
    var a_distance: int = _target_anchor_distance(a.target_entity_id)
    var b_distance: int = _target_anchor_distance(b.target_entity_id)
    if a_distance != b_distance: return a_distance < b_distance
    if a.target_entity_id != b.target_entity_id: return a.target_entity_id < b.target_entity_id
    return String(a.action_id) < String(b.action_id)

func _descriptor_less(a: Dictionary, b: Dictionary) -> bool:
    var ap: int = int(a.get("presentation_priority", 0))
    var bp: int = int(b.get("presentation_priority", 0))
    if ap != bp: return ap > bp
    var actor: WorldPlacement = _world.placement(_actor_id)
    var origin: Vector2i = Vector2i.ZERO if actor == null else actor.anchor
    var aa: Vector2i = a.get("target_anchor", Vector2i.ZERO)
    var ba: Vector2i = b.get("target_anchor", Vector2i.ZERO)
    var ad: int = maxi(abs(aa.x - origin.x), abs(aa.y - origin.y))
    var bd: int = maxi(abs(ba.x - origin.x), abs(ba.y - origin.y))
    if ad != bd: return ad < bd
    return String(a.get("target_entity_id", "")) < String(b.get("target_entity_id", ""))

func _target_anchor_distance(target_entity_id: String) -> int:
    var actor: WorldPlacement = _world.placement(_actor_id)
    var target: WorldPlacement = _world.placement(target_entity_id)
    if actor == null or target == null: return 2147483647
    var delta: Vector2i = target.anchor - actor.anchor
    return maxi(abs(delta.x), abs(delta.y))

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
    if a.y == b.y: return a.x < b.x
    return a.y < b.y