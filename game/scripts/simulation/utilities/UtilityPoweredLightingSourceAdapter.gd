extends "res://scripts/simulation/utilities/UtilityPoweredLightingSourceAdapterBase.gd"

# Streetlights follow the same canonical System-25 interpretation already used
# by GameMain: default WorldTimeProfile + DaylightProfile over the authoritative
# shared TickKernel. This is derived state only; no private clock or timer exists.
var _streetlight_time: WorldTimeService = null
var _streetlight_daylight: OutdoorAmbientLightService = null

func _init(
    world_state: WorldState = null,
    hand_state: ActorHandEquipmentState = null,
    controlled_actor_id: String = "",
    utilities: UtilityRuntimeState = null,
    tick_kernel: TickKernel = null,
    flashlight_state: FlashlightItemState = null,
    support_power_services: Dictionary = {}
) -> void:
    if tick_kernel != null:
        _streetlight_time = WorldTimeService.new(tick_kernel, WorldTimeProfile.new())
        _streetlight_daylight = OutdoorAmbientLightService.new(_streetlight_time, DaylightProfile.new())
    super._init(
        world_state,
        hand_state,
        controlled_actor_id,
        utilities,
        tick_kernel,
        flashlight_state,
        support_power_services
    )

func emitters() -> Array[LightEmitter]:
    var result: Array[LightEmitter] = []
    var base_emitters: Array[LightEmitter] = super.emitters()
    var streetlights_on: bool = _streetlights_should_emit()
    for emitter: LightEmitter in base_emitters:
        if streetlights_on or not _is_streetlight_emitter(emitter):
            result.append(emitter)
    return result

func _streetlights_should_emit() -> bool:
    if _streetlight_daylight == null or not _streetlight_daylight.is_ready():
        return false
    return _streetlight_daylight.current_phase() == OutdoorAmbientLightService.PHASE_NIGHT

func _is_streetlight_emitter(emitter: LightEmitter) -> bool:
    if emitter == null or not emitter.emitter_id.begins_with("utility.light:"):
        return false
    var entity_id: String = emitter.emitter_id.trim_prefix("utility.light:")
    if _world == null or not _world.has_entity(entity_id):
        return false
    var record: WorldEntityRecord = _world.entity(entity_id)
    return record != null and record.semantic_type == &"prop.streetlight"

func _streetlight_phase_for_tick(world_tick: int) -> StringName:
    if _streetlight_time == null or _streetlight_daylight == null:
        return &""
    var snapshot: Dictionary = _streetlight_time.time_for_tick(world_tick)
    return _streetlight_daylight.phase_for_second_of_day(int(snapshot.get("second_of_day", -1)))

func _on_world_tick_advanced(previous_tick: int, new_tick: int) -> void:
    var previous_phase: StringName = _streetlight_phase_for_tick(previous_tick)
    var next_phase: StringName = _streetlight_phase_for_tick(new_tick)
    super._on_world_tick_advanced(previous_tick, new_tick)
    if previous_phase != next_phase:
        _emit_if_changed()

func _on_timing_state_reset() -> void:
    super._on_timing_state_reset()
    _emit_if_changed()
