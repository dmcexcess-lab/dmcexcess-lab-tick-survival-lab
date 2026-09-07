extends RefCounted
class_name CorpseState

signal corpse_recorded(actor_id, corpse_id)

var _corpse_by_actor: Dictionary = {}
var _actor_by_corpse: Dictionary = {}

func has_corpse_for_actor(actor_id: String) -> bool:
    return _corpse_by_actor.has(actor_id)

func corpse_for_actor(actor_id: String) -> String:
    return "" if not _corpse_by_actor.has(actor_id) else String(_corpse_by_actor[actor_id])

func source_actor(corpse_id: String) -> String:
    return "" if not _actor_by_corpse.has(corpse_id) else String(_actor_by_corpse[corpse_id])

func record(actor_id: String, corpse_id: String) -> bool:
    if actor_id.is_empty() or corpse_id.is_empty() or _corpse_by_actor.has(actor_id) or _actor_by_corpse.has(corpse_id): return false
    _corpse_by_actor[actor_id] = corpse_id
    _actor_by_corpse[corpse_id] = actor_id
    corpse_recorded.emit(actor_id, corpse_id)
    return true

func snapshot() -> Dictionary:
    return {"corpse_by_actor": _corpse_by_actor.duplicate(true)}
