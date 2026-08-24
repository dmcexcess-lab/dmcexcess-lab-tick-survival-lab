extends RefCounted
class_name DemoAmbientLightCycle

## DEV presentation-only daylight cycle.
##
## This deliberately does NOT define the game's canonical calendar or teach WHEN
## how ticks map to minutes/hours. It only turns the current world_tick into a
## repeatable normalized ambient-light sample for the playable critique build.
## A future World Time / Lighting owner can replace this provider without changing
## System 23 perception memory or fog rendering contracts.

const CYCLE_TICKS: int = 2400
const START_PHASE: float = 0.375
const DAWN_START: float = 0.20
const DAWN_END: float = 0.30
const DUSK_START: float = 0.70
const DUSK_END: float = 0.80

static func cycle_phase_for_tick(world_tick: int) -> float:
    var tick_in_cycle: int = maxi(0, world_tick) % CYCLE_TICKS
    return fposmod(START_PHASE + float(tick_in_cycle) / float(CYCLE_TICKS), 1.0)

static func ambient_light_for_tick(world_tick: int) -> float:
    return ambient_light_for_phase(cycle_phase_for_tick(world_tick))

static func ambient_light_for_phase(phase: float) -> float:
    var normalized: float = fposmod(phase, 1.0)
    if normalized < DAWN_START or normalized >= DUSK_END:
        return 0.0
    if normalized < DAWN_END:
        return _smoothstep(DAWN_START, DAWN_END, normalized)
    if normalized < DUSK_START:
        return 1.0
    return 1.0 - _smoothstep(DUSK_START, DUSK_END, normalized)

static func _smoothstep(edge0: float, edge1: float, value: float) -> float:
    if edge1 <= edge0:
        return 0.0
    var t: float = clampf((value - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
