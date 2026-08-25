extends InteractionOfferProvider
class_name InteractionFixedOfferProvider

## CI-only deterministic provider used to prove System-29 multi-provider/dedup rules.

var _offers: Array[InteractionOffer] = []

func _init(offers: Array[InteractionOffer] = []) -> void:
    for offer: InteractionOffer in offers:
        if offer != null:
            _offers.append(offer.copy())

func is_ready() -> bool:
    return true

func offers_for_actor(actor_id: String, candidate_target_ids: Array[String]) -> Array[InteractionOffer]:
    var result: Array[InteractionOffer] = []
    var candidates: Dictionary = {}
    for target_id: String in candidate_target_ids:
        candidates[target_id] = true
    for offer: InteractionOffer in _offers:
        if offer.actor_id == actor_id and candidates.has(offer.target_entity_id):
            result.append(offer.copy())
    return result
