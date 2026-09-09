extends ActiveInfectedCohortService
class_name DynamicInfectedCohortService

## Small mutation seam for causal local outbreak transitions. It does not create
## actors; it only admits/removes already-real resident actors from the existing
## streaming-managed infected cohort.

func add_member(member: Dictionary) -> bool:
    if not is_configured() or not is_ready():
        return false
    var actor_id := String(member.get("actor_id", "")).strip_edges()
    if actor_id.is_empty() or _roster_set.has(actor_id) or not _valid_living_infected(actor_id):
        return false
    _roster.append(actor_id)
    _roster.sort()
    _roster_set[actor_id] = true
    if not _sync_actor(actor_id):
        _roster.erase(actor_id)
        _roster_set.erase(actor_id)
        return false
    active_members_changed.emit(active_actor_ids())
    return true

func remove_member(actor_id: String, reason: StringName = &"cohort_removed") -> bool:
    var key := actor_id.strip_edges()
    if not _roster_set.has(key):
        return false
    if _active.has(key):
        _deactivate(key, reason)
    var perception: StreamingObserverPerceptionService = _perceptions.get(key, null) as StreamingObserverPerceptionService
    if perception != null:
        perception.set_stream_active(false)
    _behaviors.erase(key)
    _perceptions.erase(key)
    _active.erase(key)
    _roster.erase(key)
    _roster_set.erase(key)
    active_members_changed.emit(active_actor_ids())
    return true
