extends RefCounted
class_name WeatherState

const SNAPSHOT_SCHEMA_VERSION: int = 1

var current_profile_id: StringName = &"clear"
var target_profile_id: StringName = &"clear"
var transition_start_tick: int = 0
var transition_end_tick: int = 1
var wetness_anchor: float = 0.0
var wetness_anchor_tick: int = 0
var environment_revision: int = 1
var transition_serial: int = 0
var scheduled_event_serial: int = 0
var quantized_signature: String = ""

func is_valid(minimum_tick: int = 0) -> bool:
    return (
        not String(current_profile_id).is_empty()
        and not String(target_profile_id).is_empty()
        and transition_start_tick >= 0
        and transition_end_tick > transition_start_tick
        and transition_end_tick >= minimum_tick
        and wetness_anchor >= 0.0 and wetness_anchor <= 1.0
        and wetness_anchor_tick >= 0
        and environment_revision >= 1
        and transition_serial >= 0
        and scheduled_event_serial >= 0
    )

func copy() -> WeatherState:
    var value := WeatherState.new()
    value.current_profile_id = current_profile_id
    value.target_profile_id = target_profile_id
    value.transition_start_tick = transition_start_tick
    value.transition_end_tick = transition_end_tick
    value.wetness_anchor = wetness_anchor
    value.wetness_anchor_tick = wetness_anchor_tick
    value.environment_revision = environment_revision
    value.transition_serial = transition_serial
    value.scheduled_event_serial = scheduled_event_serial
    value.quantized_signature = quantized_signature
    return value

func to_snapshot() -> Dictionary:
    return {
        "schema_version": SNAPSHOT_SCHEMA_VERSION,
        "current_profile_id": String(current_profile_id),
        "target_profile_id": String(target_profile_id),
        "transition_start_tick": transition_start_tick,
        "transition_end_tick": transition_end_tick,
        "wetness_anchor": wetness_anchor,
        "wetness_anchor_tick": wetness_anchor_tick,
        "environment_revision": environment_revision,
        "transition_serial": transition_serial,
        "scheduled_event_serial": scheduled_event_serial,
        "quantized_signature": quantized_signature,
    }

static func from_snapshot(data: Dictionary, minimum_tick: int = 0) -> WeatherState:
    if int(data.get("schema_version", -1)) != SNAPSHOT_SCHEMA_VERSION:
        return null
    var value := WeatherState.new()
    value.current_profile_id = StringName(String(data.get("current_profile_id", "")))
    value.target_profile_id = StringName(String(data.get("target_profile_id", "")))
    value.transition_start_tick = int(data.get("transition_start_tick", -1))
    value.transition_end_tick = int(data.get("transition_end_tick", -1))
    value.wetness_anchor = float(data.get("wetness_anchor", -1.0))
    value.wetness_anchor_tick = int(data.get("wetness_anchor_tick", -1))
    value.environment_revision = int(data.get("environment_revision", 0))
    value.transition_serial = int(data.get("transition_serial", -1))
    value.scheduled_event_serial = int(data.get("scheduled_event_serial", -1))
    value.quantized_signature = String(data.get("quantized_signature", ""))
    if not value.is_valid(minimum_tick):
        return null
    return value
