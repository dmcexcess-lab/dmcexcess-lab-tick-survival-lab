extends RefCounted
class_name InteractionOfferProvider

## Neutral read-only provider seam. Mechanic owners subclass this and publish only
## actions they really own; System 29 never infers gameplay from art or names.

signal availability_changed(reason: StringName)

func is_ready() -> bool:
    return false

func offers_for_actor(_actor_id: String, _candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    return []
