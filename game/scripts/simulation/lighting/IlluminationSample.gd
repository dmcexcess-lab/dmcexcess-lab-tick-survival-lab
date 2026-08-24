extends RefCounted
class_name IlluminationSample

## Headless physical-light result for one global tactical cell.

var cell: Vector2i = Vector2i.ZERO
var sky_diffuse: float = 0.0
var direct_celestial: float = 0.0
var portal: float = 0.0
var local_artificial: float = 0.0
var useful_luminance: float = 0.0
var tint: Color = Color.BLACK
var dominant_direction: Vector2i = Vector2i.ZERO
var glare: float = 0.0
var scatter: float = 0.0
var world_tick: int = 0
var world_revision: int = 0
var door_revision: int = 0
var lighting_revision: int = 0

func _init(cell_value: Vector2i = Vector2i.ZERO) -> void:
    cell = cell_value

func copy() -> IlluminationSample:
    var result := IlluminationSample.new(cell)
    result.sky_diffuse = sky_diffuse
    result.direct_celestial = direct_celestial
    result.portal = portal
    result.local_artificial = local_artificial
    result.useful_luminance = useful_luminance
    result.tint = tint
    result.dominant_direction = dominant_direction
    result.glare = glare
    result.scatter = scatter
    result.world_tick = world_tick
    result.world_revision = world_revision
    result.door_revision = door_revision
    result.lighting_revision = lighting_revision
    return result

func to_dictionary() -> Dictionary:
    return {
        "cell": [cell.x, cell.y],
        "sky_diffuse": sky_diffuse,
        "direct_celestial": direct_celestial,
        "portal": portal,
        "local_artificial": local_artificial,
        "useful_luminance": useful_luminance,
        "tint": [tint.r, tint.g, tint.b, tint.a],
        "dominant_direction": [dominant_direction.x, dominant_direction.y],
        "glare": glare,
        "scatter": scatter,
        "world_tick": world_tick,
        "world_revision": world_revision,
        "door_revision": door_revision,
        "lighting_revision": lighting_revision,
    }
