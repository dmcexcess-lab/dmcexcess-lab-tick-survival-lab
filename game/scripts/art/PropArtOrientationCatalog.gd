extends RefCounted
class_name PropArtOrientationCatalog

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")

## Presentation-only native-facing metadata for prop art.
## WHAT facing remains authoritative world orientation. This catalog only says
## how an authored visual is oriented so the renderer can rotate it.

const SOURCE_FINAL_PROPS: StringName = &"final_props"
const SOURCE_BUILDING_PROPS: StringName = &"building_props"
const SOURCE_CLUTTER: StringName = &"clutter"
const SOURCE_TACTICAL: StringName = &"tactical"
const SOURCE_LARGE_TRAFFIC_BASE: StringName = &"large_traffic_light_base"
const SOURCE_LARGE_TRAFFIC_FOREGROUND: StringName = &"large_traffic_light_foreground"

## Recovered indoor/furniture families and the dedicated large traffic-light art
## are authored with their usable/front direction toward screen SOUTH.
## Outdoor/nondirectional art remains unrotated.
static func native_facing(selection: ArtSelection) -> int:
    if selection == null or not selection.is_found() or selection.source == null:
        return -1

    var source_id: StringName = selection.source.source_id
    if source_id == SOURCE_LARGE_TRAFFIC_BASE or source_id == SOURCE_LARGE_TRAFFIC_FOREGROUND:
        return Facing.Value.SOUTH
    if not selection.is_atlas_region():
        return -1

    var index: int = selection.atlas_index
    if source_id == SOURCE_FINAL_PROPS and index >= 64 and index <= 127:
        return Facing.Value.SOUTH
    if source_id == SOURCE_BUILDING_PROPS and index >= 0 and index <= 19:
        return Facing.Value.SOUTH
    if source_id == SOURCE_CLUTTER and (index >= 0 and index <= 6 or index == 18):
        return Facing.Value.SOUTH
    if source_id == SOURCE_TACTICAL and index >= 37 and index <= 47:
        return Facing.Value.SOUTH
    return -1

static func is_directional(selection: ArtSelection) -> bool:
    return native_facing(selection) >= 0

static func quarter_turns(selection: ArtSelection, world_facing: int) -> int:
    var native: int = native_facing(selection)
    if native < 0 or not Facing.is_valid(world_facing):
        return 0
    return ((world_facing - native) % 4 + 4) % 4
