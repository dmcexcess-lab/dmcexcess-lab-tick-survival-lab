extends RefCounted
class_name CountrysideSourceCatalog


const CATALOG_VERSION: int = 1
const SOURCE_KIND: StringName = &"system20_rural_open"
const RURAL_OPEN_REGION_KIND: StringName = &"rural_open"
const RURAL_OPEN_PROFILE: StringName = &"rural.open"

var _plan_signature: String = ""
var _context_bounds: Rect2i = Rect2i()
var _sources: Array[Dictionary] = []
var _sources_by_id: Dictionary = {}
var _parent_rects_by_id: Dictionary = {}
var _settlement_exclusions: Array[Rect2i] = []
var _failure_reason: String = ""

func _init(global_plan: GeneratedGlobalWorldPlan = null) -> void:
    if global_plan != null:
        configure(global_plan)

func configure(global_plan: GeneratedGlobalWorldPlan) -> bool:
    _reset()
    if global_plan == null or not global_plan.is_generated():
        return _fail("invalid_countryside_catalog_input")

    var context_result: Dictionary = _resolve_rural_open_context(global_plan)
    if not bool(context_result.get("ok", false)):
        return _fail(String(context_result.get("failure_reason", "rural_open_context_missing")))
    _context_bounds = context_result.get("bounds", Rect2i())

    var parent_result: Dictionary = _ordered_parent_geography(global_plan)
    if not bool(parent_result.get("ok", false)):
        return _fail(String(parent_result.get("failure_reason", "countryside_geography_invalid")))
    var parents: Array[Dictionary] = []
    for value: Variant in parent_result.get("parents", []):
        if typeof(value) != TYPE_DICTIONARY:
            return _fail("countryside_parent_geography_invalid")
        parents.append(value)

    var settlement_result: Dictionary = _ordered_settlement_exclusions(global_plan)
    if not bool(settlement_result.get("ok", false)):
        return _fail(String(settlement_result.get("failure_reason", "countryside_settlement_exclusion_invalid")))
    _settlement_exclusions = settlement_result.get("rects", [])


    for parent: Dictionary in parents:
        var parent_id: String = String(parent.get("id", ""))
        var grid: Vector2i = parent.get("grid", Vector2i(-999999, -999999))
        var parent_rect: Rect2i = parent.get("rect", Rect2i())
        var pieces: Array[Rect2i] = _dry_pieces(parent_rect)
        for piece: Rect2i in pieces:
            var source_id: String = _source_id(parent_id, grid, piece)
            var source_key: String = "%s:%s" % [String(SOURCE_KIND), source_id]
            if _sources_by_id.has(source_id):
                return _fail("duplicate_countryside_source_id:%s" % source_id)
            var descriptor: Dictionary = {
                "source_kind": SOURCE_KIND,
                "source_id": source_id,
                "source_key": source_key,
                "catalog_version": CATALOG_VERSION,
                "parent_geography_id": parent_id,
                "parent_geography_grid": grid,
                "bounds": piece,
                "source_seed": global_plan.seed,
            }
            _sources.append(descriptor)
            _sources_by_id[source_id] = descriptor.duplicate(true)

    _sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("source_key", "")) < String(b.get("source_key", ""))
    )
    _plan_signature = global_plan.signature()

    var validation: Dictionary = validate_source_bounds(global_plan)
    if not bool(validation.get("ok", false)):
        return _fail(String(validation.get("failure_reason", "countryside_catalog_validation_failed")))
    return true

func is_ready() -> bool:
    return _failure_reason.is_empty() \
        and not _plan_signature.is_empty() \
        and _context_bounds.size.x > 0 and _context_bounds.size.y > 0 \
        and not _sources.is_empty()

func failure_reason() -> String:
    return _failure_reason

func catalog_version() -> int:
    return CATALOG_VERSION

func plan_signature() -> String:
    return _plan_signature

func context_bounds() -> Rect2i:
    return _context_bounds

func sources() -> Array[Dictionary]:
    return _sources.duplicate(true)

func source_ids() -> Array[String]:
    var result: Array[String] = []
    for source: Dictionary in _sources:
        result.append(String(source.get("source_id", "")))
    return result

func source_keys() -> Array[String]:
    var result: Array[String] = []
    for source: Dictionary in _sources:
        result.append(String(source.get("source_key", "")))
    return result

func descriptor(source_id: String) -> Dictionary:
    var clean: String = source_id.strip_edges()
    if clean.is_empty() or not _sources_by_id.has(clean):
        return {}
    return (_sources_by_id[clean] as Dictionary).duplicate(true)

func source_handle_for_id(source_id: String) -> Dictionary:
    var value: Dictionary = descriptor(source_id)
    if value.is_empty():
        return {}
    return {
        "source_kind": SOURCE_KIND,
        "source_id": String(value.get("source_id", "")),
        "source_key": String(value.get("source_key", "")),
        "bounds": value.get("bounds", Rect2i()),
    }

func source_handles_intersecting(bounds_list: Array[Rect2i]) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not is_ready() or bounds_list.is_empty():
        return result
    for source: Dictionary in _sources:
        var source_bounds: Rect2i = source.get("bounds", Rect2i())
        var intersects: bool = false
        for query_bounds: Rect2i in bounds_list:
            if _rects_overlap_positive(source_bounds, query_bounds):
                intersects = true
                break
        if intersects:
            result.append({
                "source_kind": SOURCE_KIND,
                "source_id": String(source.get("source_id", "")),
                "source_key": String(source.get("source_key", "")),
                "bounds": source_bounds,
            })
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("source_key", "")) < String(b.get("source_key", ""))
    )
    return result

func descriptor_for_cell(cell: Vector2i) -> Dictionary:
    if not is_ready() or not _context_bounds.has_point(cell):
        return {}
    for source: Dictionary in _sources:
        var bounds: Rect2i = source.get("bounds", Rect2i())
        if bounds.has_point(cell):
            return source.duplicate(true)
    return {}

func settlement_exclusion_rects() -> Array[Rect2i]:
    return _settlement_exclusions.duplicate()


func validate_source_bounds(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    if global_plan == null or not global_plan.is_generated() or _plan_signature.is_empty():
        return _validation_failure("invalid_countryside_catalog_validation_input")
    if global_plan.signature() != _plan_signature:
        return _validation_failure("countryside_catalog_plan_mismatch")

    var source_keys_seen: Dictionary = {}
    for index in range(_sources.size()):
        var source: Dictionary = _sources[index]
        var source_id: String = String(source.get("source_id", "")).strip_edges()
        var source_key: String = String(source.get("source_key", "")).strip_edges()
        var parent_id: String = String(source.get("parent_geography_id", "")).strip_edges()
        var bounds: Rect2i = source.get("bounds", Rect2i())
        if source_id.is_empty() or source_key.is_empty() or source_keys_seen.has(source_key):
            return _validation_failure("countryside_source_identity_invalid:%s" % source_id)
        source_keys_seen[source_key] = true
        if StringName(source.get("source_kind", &"")) != SOURCE_KIND \
            or int(source.get("catalog_version", 0)) != CATALOG_VERSION \
            or int(source.get("source_seed", global_plan.seed - 1)) != global_plan.seed:
            return _validation_failure("countryside_source_provenance_invalid:%s" % source_id)
        if not _parent_rects_by_id.has(parent_id):
            return _validation_failure("countryside_parent_missing:%s" % source_id)
        var parent_rect: Rect2i = _parent_rects_by_id[parent_id]
        if not _rect_inside(parent_rect, bounds):
            return _validation_failure("countryside_source_outside_parent:%s" % source_id)
        for site_rect: Rect2i in _settlement_exclusions:
            if _rects_overlap_positive(bounds, site_rect):
                return _validation_failure("countryside_source_overlaps_settlement:%s" % source_id)
        for other_index in range(index + 1, _sources.size()):
            var other_bounds: Rect2i = _sources[other_index].get("bounds", Rect2i())
            if _rects_overlap_positive(bounds, other_bounds):
                return _validation_failure("countryside_sources_overlap:%s:%s" % [source_id, String(_sources[other_index].get("source_id", ""))])

    for parent_id_value: Variant in _parent_rects_by_id.keys():
        var parent_id: String = String(parent_id_value)
        var expected: Array[Rect2i] = _dry_pieces(_parent_rects_by_id[parent_id])
        var actual: Array[Rect2i] = []
        for source: Dictionary in _sources:
            if String(source.get("parent_geography_id", "")) == parent_id:
                actual.append(source.get("bounds", Rect2i()))
        _sort_rects(expected)
        _sort_rects(actual)
        if expected != actual:
            return _validation_failure("countryside_parent_coverage_mismatch:%s" % parent_id)

    return {"ok": true, "failure_reason": ""}

func _resolve_rural_open_context(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var matches: Array[Rect2i] = []
    for region: Dictionary in global_plan.regions:
        if StringName(region.get("kind", &"")) != RURAL_OPEN_REGION_KIND:
            continue
        if StringName(region.get("area_profile_hint", &"")) != RURAL_OPEN_PROFILE:
            continue
        var bounds: Rect2i = region.get("rect", Rect2i())
        if bounds.size.x <= 0 or bounds.size.y <= 0 or not _rect_inside(global_plan.bounds, bounds):
            return {"ok": false, "failure_reason": "rural_open_context_invalid", "bounds": Rect2i()}
        matches.append(bounds)
    if matches.size() != 1:
        return {"ok": false, "failure_reason": "rural_open_context_count_invalid", "bounds": Rect2i()}
    return {"ok": true, "failure_reason": "", "bounds": matches[0]}

func _ordered_parent_geography(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var parents: Array[Dictionary] = []
    var seen_ids: Dictionary = {}
    var seen_grids: Dictionary = {}
    for geography: Dictionary in global_plan.geography_cells:
        var source_id: String = String(geography.get("id", "")).strip_edges()
        var grid: Vector2i = geography.get("grid", Vector2i(-999999, -999999))
        var source_rect: Rect2i = geography.get("rect", Rect2i())
        var clipped: Rect2i = _rect_intersection(source_rect, _context_bounds)
        if clipped.size.x <= 0 or clipped.size.y <= 0:
            continue
        var grid_key: String = "%d,%d" % [grid.x, grid.y]
        if source_id.is_empty() or seen_ids.has(source_id) or seen_grids.has(grid_key):
            return {"ok": false, "failure_reason": "countryside_geography_identity_invalid", "parents": []}
        if source_rect.size.x <= 0 or source_rect.size.y <= 0 or not _rect_inside(global_plan.bounds, source_rect):
            return {"ok": false, "failure_reason": "countryside_geography_bounds_invalid:%s" % source_id, "parents": []}
        seen_ids[source_id] = true
        seen_grids[grid_key] = true
        parents.append({"id": source_id, "grid": grid, "rect": clipped})
        _parent_rects_by_id[source_id] = clipped

    parents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ag: Vector2i = a.get("grid", Vector2i.ZERO)
        var bg: Vector2i = b.get("grid", Vector2i.ZERO)
        if ag.y != bg.y:
            return ag.y < bg.y
        if ag.x != bg.x:
            return ag.x < bg.x
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    if parents.is_empty():
        return {"ok": false, "failure_reason": "countryside_geography_missing", "parents": []}

    var total_area: int = 0
    for index in range(parents.size()):
        var rect: Rect2i = parents[index].get("rect", Rect2i())
        total_area += rect.size.x * rect.size.y
        for other_index in range(index + 1, parents.size()):
            var other_rect: Rect2i = parents[other_index].get("rect", Rect2i())
            if _rects_overlap_positive(rect, other_rect):
                return {"ok": false, "failure_reason": "countryside_geography_overlap", "parents": []}
    if total_area != _context_bounds.size.x * _context_bounds.size.y:
        return {"ok": false, "failure_reason": "countryside_geography_coverage_invalid", "parents": []}
    return {"ok": true, "failure_reason": "", "parents": parents}

func _ordered_settlement_exclusions(global_plan: GeneratedGlobalWorldPlan) -> Dictionary:
    var entries: Array[Dictionary] = []
    for site: Dictionary in global_plan.area_sites:
        var site_id: String = String(site.get("id", "")).strip_edges()
        var site_bounds: Rect2i = site.get("bounds", Rect2i())
        if site_id.is_empty() or site_bounds.size.x <= 0 or site_bounds.size.y <= 0 or not _rect_inside(global_plan.bounds, site_bounds):
            return {"ok": false, "failure_reason": "countryside_settlement_site_invalid:%s" % site_id, "rects": []}
        var clipped: Rect2i = _rect_intersection(site_bounds, _context_bounds)
        if clipped.size.x > 0 and clipped.size.y > 0:
            entries.append({"id": site_id, "rect": clipped})
    entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.get("id", "")) < String(b.get("id", ""))
    )
    var rects: Array[Rect2i] = []
    for entry: Dictionary in entries:
        rects.append(entry.get("rect", Rect2i()))
    return {"ok": true, "failure_reason": "", "rects": rects}


func _dry_pieces(parent_rect: Rect2i) -> Array[Rect2i]:
    var pieces: Array[Rect2i] = [parent_rect]
    for exclusion: Rect2i in _settlement_exclusions:
        pieces = _subtract_from_pieces(pieces, exclusion)
    _sort_rects(pieces)
    return pieces

func _subtract_from_pieces(pieces: Array[Rect2i], exclusion: Rect2i) -> Array[Rect2i]:
    var result: Array[Rect2i] = []
    for piece: Rect2i in pieces:
        var split: Array[Rect2i] = _subtract_rect(piece, exclusion)
        for value: Rect2i in split:
            if value.size.x > 0 and value.size.y > 0:
                result.append(value)
    return result

func _subtract_rect(base: Rect2i, cut: Rect2i) -> Array[Rect2i]:
    var overlap: Rect2i = _rect_intersection(base, cut)
    if overlap.size.x <= 0 or overlap.size.y <= 0:
        return [base]

    var result: Array[Rect2i] = []
    var base_end: Vector2i = base.position + base.size
    var overlap_end: Vector2i = overlap.position + overlap.size

    if overlap.position.y > base.position.y:
        result.append(Rect2i(base.position, Vector2i(base.size.x, overlap.position.y - base.position.y)))
    if overlap_end.y < base_end.y:
        result.append(Rect2i(Vector2i(base.position.x, overlap_end.y), Vector2i(base.size.x, base_end.y - overlap_end.y)))
    if overlap.position.x > base.position.x:
        result.append(Rect2i(Vector2i(base.position.x, overlap.position.y), Vector2i(overlap.position.x - base.position.x, overlap.size.y)))
    if overlap_end.x < base_end.x:
        result.append(Rect2i(Vector2i(overlap_end.x, overlap.position.y), Vector2i(base_end.x - overlap_end.x, overlap.size.y)))
    return result

func _source_id(parent_id: String, grid: Vector2i, bounds: Rect2i) -> String:
    return "rural.open.v%d.%s.g%d.%d.x%d.y%d.w%d.h%d" % [
        CATALOG_VERSION,
        parent_id,
        grid.x,
        grid.y,
        bounds.position.x,
        bounds.position.y,
        bounds.size.x,
        bounds.size.y,
    ]

func _sort_rects(values: Array[Rect2i]) -> void:
    values.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
        if a.position.y != b.position.y:
            return a.position.y < b.position.y
        if a.position.x != b.position.x:
            return a.position.x < b.position.x
        if a.size.y != b.size.y:
            return a.size.y < b.size.y
        return a.size.x < b.size.x
    )

func _rect_intersection(a: Rect2i, b: Rect2i) -> Rect2i:
    var start := Vector2i(maxi(a.position.x, b.position.x), maxi(a.position.y, b.position.y))
    var finish := Vector2i(
        mini(a.position.x + a.size.x, b.position.x + b.size.x),
        mini(a.position.y + a.size.y, b.position.y + b.size.y)
    )
    if finish.x <= start.x or finish.y <= start.y:
        return Rect2i()
    return Rect2i(start, finish - start)

func _rect_inside(outer: Rect2i, inner: Rect2i) -> bool:
    if outer.size.x <= 0 or outer.size.y <= 0 or inner.size.x <= 0 or inner.size.y <= 0:
        return false
    var inner_last: Vector2i = inner.position + inner.size - Vector2i.ONE
    return outer.has_point(inner.position) and outer.has_point(inner_last)

func _rects_overlap_positive(a: Rect2i, b: Rect2i) -> bool:
    if a.size.x <= 0 or a.size.y <= 0 or b.size.x <= 0 or b.size.y <= 0:
        return false
    var a_end: Vector2i = a.position + a.size
    var b_end: Vector2i = b.position + b.size
    return a.position.x < b_end.x and a_end.x > b.position.x \
        and a.position.y < b_end.y and a_end.y > b.position.y

func _validation_failure(reason: String) -> Dictionary:
    return {"ok": false, "failure_reason": reason}

func _fail(reason: String) -> bool:
    _failure_reason = reason
    _plan_signature = ""
    _sources.clear()
    _sources_by_id.clear()
    _parent_rects_by_id.clear()
    return false

func _reset() -> void:
    _plan_signature = ""
    _context_bounds = Rect2i()
    _sources.clear()
    _sources_by_id.clear()
    _parent_rects_by_id.clear()
    _settlement_exclusions.clear()
    _failure_reason = ""
