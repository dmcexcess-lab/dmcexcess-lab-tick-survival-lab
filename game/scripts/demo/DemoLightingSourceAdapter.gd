extends RefCounted
class_name DemoLightingSourceAdapter

## Legacy bootstrap shim retained only so GameMain can construct System 27 before
## UtilityGameMain installs truthful System-33/equipment-owned sources. The old
## critique-world flashlight/lamp/neon/streetlight coordinates were fake and are retired.

signal emitters_changed(emitters)

var _world: WorldState = null
var _player_id: String = ""

func _init(world_state: WorldState = null, controlled_actor_id: String = "") -> void:
    _world = world_state
    _player_id = controlled_actor_id.strip_edges()

func is_ready() -> bool:
    return _world != null and not _player_id.is_empty() and _world.placement(_player_id) != null

func emitters() -> Array[LightEmitter]:
    return []

func debug_snapshot() -> Dictionary:
    return {
        "ready": is_ready(),
        "emitter_count": 0,
        "fake_sources_retired": true,
    }
