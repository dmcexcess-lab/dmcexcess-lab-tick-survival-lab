extends RefCounted
class_name ItemContainerAccessPolicy

## Neutral optional extension seam for System 12 container accessibility.
## The canonical personal-container rules remain inside ItemTransferActionService;
## policy-aware coordinators may additionally admit physically reachable external containers.

func is_ready() -> bool:
    return false

func can_access(_actor_id: String, _container_id: String) -> bool:
    return false
