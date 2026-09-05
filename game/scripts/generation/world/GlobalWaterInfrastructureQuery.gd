extends RefCounted
class_name GlobalWaterInfrastructureQuery

func service_for_settlement(water_services: Array[Dictionary], settlement_id: String) -> Dictionary:
    for service: Dictionary in water_services:
        if String(service.get("settlement_id", "")) == settlement_id:
            return service.duplicate(true)
    return {}

func service_for_cell(water_services: Array[Dictionary], _cell: Vector2i) -> Dictionary:
    var candidates: Array[Dictionary] = []
    for service: Dictionary in water_services:
        if StringName(service.get("service_mode", &"")) == &"island_wide_municipal" \
            and bool(service.get("island_wide", false)):
            candidates.append(service)
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    return {} if candidates.is_empty() else candidates[0].duplicate(true)
