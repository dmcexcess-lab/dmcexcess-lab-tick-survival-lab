extends RefCounted
class_name CorpseState

const SNAPSHOT_SCHEMA_VERSION: int = 1

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
    return {"schema_version": SNAPSHOT_SCHEMA_VERSION, "corpse_by_actor": _corpse_by_actor.duplicate(true)}

func load_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return false
    var rows: Variant = data.get("corpse_by_actor", {})
    if typeof(rows) != TYPE_DICTIONARY:
        return false
    var by_actor: Dictionary = {}
    var by_corpse: Dictionary = {}
    for key: Variant in rows.keys():
        var actor_id: String = String(key).strip_edges()
        var corpse_id: String = String(rows[key]).strip_edges()
        if actor_id.is_empty() or corpse_id.is_empty() or by_actor.has(actor_id) or by_corpse.has(corpse_id):
            return false
        by_actor[actor_id] = corpse_id
        by_corpse[corpse_id] = actor_id
    _corpse_by_actor = by_actor
    _actor_by_corpse = by_corpse
    return true
