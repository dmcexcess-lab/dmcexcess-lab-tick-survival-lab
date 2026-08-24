extends RefCounted
class_name WatercourseSourceCatalog

const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")
const Profiles = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")

const CATALOG_VERSION: int = 1
const SOURCE_KIND: StringName = &"system20_watercourse"

var _hydrology: GlobalHydrologyQuery = HydrologyQueryClass.new()
var _sources: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _plan_signature: String = ""
var _failure_reason: String = ""

func _init(plan: GeneratedGlobalWorldPlan = null) -> void:
    if plan != null:
        configure(plan)

func configure(plan: GeneratedGlobalWorldPlan) -> bool:
    _sources.clear()
    _by_id.clear()
    _plan_signature = ""
    _failure_reason = ""
    if plan == null or not plan.is_generated() or plan.profile_id != Profiles.TEMPERATE_ISLAND_REGION:
        return _fail("invalid_watercourse_catalog_input")

    var ordered: Array[Dictionary] = plan.river_segments.duplicate(true)
    ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ao: int = int(a.get("ordinal", 0))
        var bo: int = int(b.get("ordinal", 0))
        if ao != bo:
            return ao < bo
        return String(a.get("segment_id", "")) < String(b.get("segment_id", ""))
    )
    var claimed: Array[Rect2i] = []
    for river: Dictionary in ordered:
        var segment_id: String = String(river.get("segment_id", ""))
        var corridor: Rect2i = _intersection(_hydrology.segment_corridor_rect(river), plan.bounds)
        if segment_id.is_empty() or corridor.size.x <= 0 or corridor.size.y <= 0:
            return _fail("watercourse_segment_invalid")
        var pieces: Array[Rect2i] = [corridor]
        for prior: Rect2i in claimed:
            pieces = _subtract_all(pieces, prior)
        _sort_rects(pieces)
        for piece: Rect2i in pieces:
            if piece.size.x <= 0 or piece.size.y <= 0:
                continue
            var source_id: String = "watercourse.%s.x%d.y%d.w%d.h%d" % [segment_id, piece.position.x, piece.position.y, piece.size.x, piece.size.y]
            var descriptor: Dictionary = {
                "source_kind": SOURCE_KIND,
                "source_id": source_id,
                "source_key": "%s:%s" % [String(SOURCE_KIND), source_id],
                "catalog_version": CATALOG_VERSION,
                "river_segment_id": segment_id,
                "bounds": piece,
                "source_seed": plan.seed,
            }
            if _by_id.has(source_id):
                return _fail("duplicate_watercourse_source")
            _sources.append(descriptor)
            _by_id[source_id] = descriptor.duplicate(true)
            claimed.append(piece)
    _sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("source_key", "")) < String(b.get("source_key", ""))
    )
    _plan_signature = plan.signature()
    return not _sources.is_empty()

func is_ready() -> bool:
    return _failure_reason.is_empty() and not _plan_signature.is_empty() and not _sources.is_empty()

func failure_reason() -> String:
    return _failure_reason

func sources() -> Array[Dictionary]:
    return _sources.duplicate(true)

func descriptor(source_id: String) -> Dictionary:
    if not _by_id.has(source_id):
        return {}
    return (_by_id[source_id] as Dictionary).duplicate(true)

func source_handle_for_id(source_id: String) -> Dictionary:
    var value: Dictionary = descriptor(source_id)
    if value.is_empty():
        return {}
    return {
        "source_kind": SOURCE_KIND,
        "source_id": source_id,
        "source_key": String(value.get("source_key", "")),
        "bounds": value.get("bounds", Rect2i()),
    }

func source_handles_intersecting(bounds_list: Array[Rect2i]) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not is_ready():
        return result
    for source: Dictionary in _sources:
        var rect: Rect2i = source.get("bounds", Rect2i())
        for query: Rect2i in bounds_list:
            if _overlap(rect, query):
                result.append({
                    "source_kind": SOURCE_KIND,
                    "source_id": String(source.get("source_id", "")),
                    "source_key": String(source.get("source_key", "")),
                    "bounds": rect,
                })
                break
    return result

func validate_source_bounds(plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if not is_ready() or plan == null or not plan.is_generated() or plan.signature() != _plan_signature:
        return {"ok": false, "failure_reason": "watercourse_catalog_plan_mismatch"}
    for first_index in range(_sources.size()):
        var first: Rect2i = _sources[first_index].get("bounds", Rect2i())
        if not _rect_inside(plan.bounds, first) or not _rect_covered_by_rivers(first, plan.river_segments):
            return {"ok": false, "failure_reason": "watercourse_source_not_river"}
        for site: Dictionary in plan.area_sites:
            if _overlap(first, site.get("bounds", Rect2i())):
                return {"ok": false, "failure_reason": "watercourse_source_overlaps_site"}
        for second_index in range(first_index + 1, _sources.size()):
            if _overlap(first, _sources[second_index].get("bounds", Rect2i())):
                return {"ok": false, "failure_reason": "watercourse_sources_overlap"}
    return {"ok": true, "failure_reason": ""}

func _rect_covered_by_rivers(rect: Rect2i, rivers: Array[Dictionary]) -> bool:
    for y in range(rect.position.y, rect.position.y + rect.size.y):
        for x in range(rect.position.x, rect.position.x + rect.size.x):
            var cell := Vector2i(x, y)
            var covered: bool = false
            for river: Dictionary in rivers:
                if _hydrology.segment_corridor_rect(river).has_point(cell):
                    covered = true
                    break
            if not covered:
                return false
    return true

func _subtract_all(pieces: Array[Rect2i], exclusion: Rect2i) -> Array[Rect2i]:
    var result: Array[Rect2i] = []
    for piece: Rect2i in pieces:
        result.append_array(_subtract(piece, exclusion))
    return result

func _subtract(source: Rect2i, exclusion: Rect2i) -> Array[Rect2i]:
    var overlap_rect: Rect2i = _intersection(source, exclusion)
    if overlap_rect.size.x <= 0 or overlap_rect.size.y <= 0:
        return [source]
    var result: Array[Rect2i] = []
    var source_end: Vector2i = source.position + source.size
    var overlap_end: Vector2i = overlap_rect.position + overlap_rect.size
    if overlap_rect.position.y > source.position.y:
        result.append(Rect2i(source.position, Vector2i(source.size.x, overlap_rect.position.y - source.position.y)))
    if overlap_end.y < source_end.y:
        result.append(Rect2i(Vector2i(source.position.x, overlap_end.y), Vector2i(source.size.x, source_end.y - overlap_end.y)))
    if overlap_rect.position.x > source.position.x:
        result.append(Rect2i(Vector2i(source.position.x, overlap_rect.position.y), Vector2i(overlap_rect.position.x - source.position.x, overlap_rect.size.y)))
    if overlap_end.x < source_end.x:
        result.append(Rect2i(Vector2i(overlap_end.x, overlap_rect.position.y), Vector2i(source_end.x - overlap_end.x, overlap_rect.size.y)))
    return result

func _sort_rects(rects: Array[Rect2i]) -> void:
    rects.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
        if a.position.y != b.position.y:
            return a.position.y < b.position.y
        if a.position.x != b.position.x:
            return a.position.x < b.position.x
        if a.size.y != b.size.y:
            return a.size.y < b.size.y
        return a.size.x < b.size.x
    )

func _intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start := Vector2i(maxi(a.position.x, b.position.x), maxi(a.position.y, b.position.y))
    var finish := Vector2i(mini(a.position.x + a.size.x, b.position.x + b.size.x), mini(a.position.y + a.size.y, b.position.y + b.size.y))
    if finish.x <= start.x or finish.y <= start.y:
        return Rect2i()
    return Rect2i(start, finish - start)

func _overlap(a: Rect2i, b: Rect2i) -> bool:
    var r: Rect2i = _intersection(a, b)
    return r.size.x > 0 and r.size.y > 0

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if inner.size.x <= 0 or inner.size.y <= 0:
        return false
    return outer.has_point(inner.position) and outer.has_point(inner.position + inner.size - Vector2i.ONE)

func _fail(reason: String) -> bool:
    _failure_reason = reason
    return false
