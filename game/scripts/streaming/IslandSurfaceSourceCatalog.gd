extends RefCounted
class_name IslandSurfaceSourceCatalog

const HydrologyQueryClass = preload("res://scripts/generation/world/GlobalHydrologyQuery.gd")
const Profiles = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")

const CATALOG_VERSION: int = 1
const SOURCE_KIND: StringName = &"system20_island_surface"

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
        return _fail("invalid_island_surface_catalog_input")

    var exclusions: Array[Rect2i] = []
    for site: Dictionary in plan.area_sites:
        exclusions.append(site.get("bounds", Rect2i()))
    for river: Dictionary in plan.river_segments:
        var corridor: Rect2i = _intersection(_hydrology.segment_corridor_rect(river), plan.bounds)
        if corridor.size.x > 0 and corridor.size.y > 0:
            exclusions.append(corridor)

    for geography: Dictionary in plan.geography_cells:
        var parent: Rect2i = geography.get("rect", Rect2i())
        var grid: Vector2i = geography.get("grid", Vector2i.ZERO)
        var parent_id: String = String(geography.get("id", ""))
        if parent.size.x <= 0 or parent.size.y <= 0 or parent_id.is_empty():
            return _fail("island_surface_geography_invalid")
        var pieces: Array[Rect2i] = [parent]
        for exclusion: Rect2i in exclusions:
            pieces = _subtract_all(pieces, exclusion)
        _sort_rects(pieces)
        for piece: Rect2i in pieces:
            if piece.size.x <= 0 or piece.size.y <= 0:
                continue
            var source_id: String = "island.surface.g%d.%d.x%d.y%d.w%d.h%d" % [grid.x, grid.y, piece.position.x, piece.position.y, piece.size.x, piece.size.y]
            var descriptor: Dictionary = {
                "source_kind": SOURCE_KIND,
                "source_id": source_id,
                "source_key": "%s:%s" % [String(SOURCE_KIND), source_id],
                "catalog_version": CATALOG_VERSION,
                "parent_geography_id": parent_id,
                "bounds": piece,
                "source_seed": plan.seed,
            }
            if _by_id.has(source_id):
                return _fail("duplicate_island_surface_source")
            _sources.append(descriptor)
            _by_id[source_id] = descriptor.duplicate(true)
    _sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("source_key", "")) < String(b.get("source_key", ""))
    )
    _plan_signature = plan.signature()
    return not _sources.is_empty()

func is_ready() -> bool:
    return _failure_reason.is_empty() and not _plan_signature.is_empty() and not _sources.is_empty()

func failure_reason() -> String:
    return _failure_reason

func catalog_version() -> int:
    return CATALOG_VERSION

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
        return {"ok": false, "failure_reason": "island_surface_catalog_plan_mismatch"}
    for first_index in range(_sources.size()):
        var first: Rect2i = _sources[first_index].get("bounds", Rect2i())
        if not _rect_inside(plan.bounds, first):
            return {"ok": false, "failure_reason": "island_surface_source_out_of_bounds"}
        for site: Dictionary in plan.area_sites:
            if _overlap(first, site.get("bounds", Rect2i())):
                return {"ok": false, "failure_reason": "island_surface_source_overlaps_site"}
        for river: Dictionary in plan.river_segments:
            if _overlap(first, _intersection(_hydrology.segment_corridor_rect(river), plan.bounds)):
                return {"ok": false, "failure_reason": "island_surface_source_overlaps_river"}
        for second_index in range(first_index + 1, _sources.size()):
            if _overlap(first, _sources[second_index].get("bounds", Rect2i())):
                return {"ok": false, "failure_reason": "island_surface_sources_overlap"}
    return {"ok": true, "failure_reason": ""}

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
    var middle_top: int = overlap_rect.position.y
    var middle_height: int = overlap_rect.size.y
    if overlap_rect.position.x > source.position.x:
        result.append(Rect2i(Vector2i(source.position.x, middle_top), Vector2i(overlap_rect.position.x - source.position.x, middle_height)))
    if overlap_end.x < source_end.x:
        result.append(Rect2i(Vector2i(overlap_end.x, middle_top), Vector2i(source_end.x - overlap_end.x, middle_height)))
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
