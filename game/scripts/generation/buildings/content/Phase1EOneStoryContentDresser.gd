extends RefCounted
class_name Phase1EOneStoryContentDresser

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const BaselineProfilesClass = preload("res://scripts/generation/buildings/profiles/OneStoryBaselineProfileCatalog.gd")

const CONTENT_VERSION: int = 2
const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _baseline_profiles := BaselineProfilesClass.new()

func apply(plan: GeneratedBuildingPlan) -> void:
    if plan == null or not plan.is_generated():
        return
    if not _baseline_profiles.has_profile(plan.archetype_id):
        return

    var occupied: Dictionary = {}
    var door_approaches: Dictionary = {}
    for structure: Dictionary in plan.structures:
        var cell: Vector2i = structure.get("cell", Vector2i.ZERO)
        occupied[cell] = true
        if String(structure.get("kind", "")) == "door":
            for offset: Vector2i in CARDINALS:
                door_approaches[cell + offset] = true
    for prop: Dictionary in plan.props:
        occupied[prop.get("cell", Vector2i.ZERO)] = true

    for room_index: int in range(plan.rooms.size()):
        var room: Dictionary = plan.rooms[room_index]
        var semantic: StringName = _semantic_for_room(plan.archetype_id, String(room.get("purpose", "")))
        if semantic == &"":
            continue
        var room_cells: Array = room.get("cells", [])
        var chosen_value: Variant = _choose_wall_cell(room_cells, occupied, door_approaches, plan.seed, room_index)
        if chosen_value == null:
            continue
        var chosen: Vector2i = chosen_value
        plan.props.append({
            "role": "prop.phase1e.%02d" % room_index,
            "cell": chosen,
            "semantic": semantic,
            "facing": _wall_facing(chosen, room_cells),
            "blocking": true,
        })
        occupied[chosen] = true

    # Baseline one-story profile content changed deterministically in Phase 1E.
    plan.archetype_version = maxi(plan.archetype_version, CONTENT_VERSION)

func _semantic_for_room(archetype_id: StringName, purpose_value: String) -> StringName:
    var purpose: String = purpose_value.to_lower()
    var archetype: String = String(archetype_id)
    if purpose.contains("corridor") or purpose.contains("hall") or purpose.contains("sanctuary") or purpose.contains("meeting"):
        return &""
    if purpose.contains("bath") or purpose.contains("restroom"):
        return &"prop.bathroom_vanity"
    if purpose.contains("bed") or purpose.contains("sleep") or purpose.contains("closet") or purpose.contains("bunk") or purpose.contains("motel"):
        return &"prop.dresser_wide"
    if purpose.contains("kitchen") or purpose.contains("break"):
        return &"prop.pantry"
    if purpose.contains("sales") or purpose.contains("retail"):
        return &"prop.retail_endcap"
    if purpose.contains("pharmacy") or purpose.contains("exam") or purpose.contains("treatment") or purpose.contains("medical"):
        return &"prop.medicine_cabinet"
    if purpose.contains("workshop") or purpose.contains("shop") or purpose.contains("tool") or purpose.contains("apparatus") or purpose.contains("utility"):
        return &"prop.tool_cabinet"
    if purpose.contains("stock") or purpose.contains("storage") or purpose.contains("feed") or purpose.contains("parts") or purpose.contains("secure") or purpose.contains("evidence") or purpose.contains("warehouse") or purpose.contains("barn") or purpose.contains("tack"):
        return &"prop.warehouse_rack"
    if purpose.contains("office") or purpose.contains("reception") or purpose.contains("classroom") or purpose.contains("administration"):
        return &"prop.file_cabinet_tall"
    if archetype == "civic.police_station.small" and purpose.contains("locker"):
        return &"prop.file_cabinet_tall"
    return &""

func _choose_wall_cell(
    room_cells: Array,
    occupied: Dictionary,
    door_approaches: Dictionary,
    seed: int,
    room_index: int
) -> Variant:
    if room_cells.size() < 6:
        return null
    var room_set: Dictionary = {}
    for value: Variant in room_cells:
        room_set[value] = true

    var candidates: Array[Vector2i] = []
    for value: Variant in room_cells:
        var cell: Vector2i = value
        if occupied.has(cell) or door_approaches.has(cell):
            continue
        var room_neighbors: int = 0
        var touches_edge: bool = false
        for offset: Vector2i in CARDINALS:
            if room_set.has(cell + offset):
                room_neighbors += 1
            else:
                touches_edge = true
        # Keep accents wall-hugging while leaving enough room-side adjacency that
        # a single blocking fixture does not become a deliberate choke point.
        if touches_edge and room_neighbors >= 2:
            candidates.append(cell)
    if candidates.is_empty():
        return null
    candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return a.y < b.y or (a.y == b.y and a.x < b.x)
    )
    var index: int = posmod(seed + room_index * 17, candidates.size())
    return candidates[index]

func _wall_facing(cell: Vector2i, room_cells: Array) -> int:
    var room_set: Dictionary = {}
    for value: Variant in room_cells:
        room_set[value] = true
    if not room_set.has(cell + Vector2i.UP):
        return Facing.Value.SOUTH
    if not room_set.has(cell + Vector2i.RIGHT):
        return Facing.Value.WEST
    if not room_set.has(cell + Vector2i.DOWN):
        return Facing.Value.NORTH
    if not room_set.has(cell + Vector2i.LEFT):
        return Facing.Value.EAST
    return Facing.Value.SOUTH
