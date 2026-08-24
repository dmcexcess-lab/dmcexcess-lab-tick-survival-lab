extends RefCounted
class_name WeatherState

const SNAPSHOT_SCHEMA_VERSION: int = 2
const LIGHTNING_KIND_START: StringName = &"start"
const LIGHTNING_KIND_END: StringName = &"end"

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

var lightning_serial: int = 0
var lightning_event_serial: int = 0
var lightning_event_kind: StringName = &""
var active_lightning_id: String = ""
var active_lightning_start_tick: int = -1
var active_lightning_end_tick: int = -1
var active_lightning_intensity: float = 0.0
var active_lightning_seed: int = 0

func is_valid(minimum_tick: int = 0) -> bool:
    if (
        String(current_profile_id).is_empty()
        or String(target_profile_id).is_empty()
        or transition_start_tick < 0
        or transition_end_tick <= transition_start_tick
        or transition_end_tick < minimum_tick
        or wetness_anchor < 0.0 or wetness_anchor > 1.0
        or wetness_anchor_tick < 0
        or environment_revision < 1
        or transition_serial < 0
        or scheduled_event_serial < 0
        or lightning_serial < 0
        or lightning_event_serial < 0
    ):
        return false

    var kind_valid: bool = (
        String(lightning_event_kind).is_empty()
        or lightning_event_kind == LIGHTNING_KIND_START
        or lightning_event_kind == LIGHTNING_KIND_END
    )
    if not kind_valid:
        return false
    if lightning_event_serial == 0 and not String(lightning_event_kind).is_empty():
        return false
    if lightning_event_serial > 0 and String(lightning_event_kind).is_empty():
        return false

    if active_lightning_id.is_empty():
        return (
            active_lightning_start_tick == -1
            and active_lightning_end_tick == -1
            and is_zero_approx(active_lightning_intensity)
            and active_lightning_seed == 0
        )

    return (
        active_lightning_start_tick >= 0
        and active_lightning_end_tick > active_lightning_start_tick
        and active_lightning_intensity > 0.0 and active_lightning_intensity <= 1.0
        and active_lightning_seed >= 0
        and lightning_event_serial > 0
        and lightning_event_kind == LIGHTNING_KIND_END
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
    value.lightning_serial = lightning_serial
    value.lightning_event_serial = lightning_event_serial
    value.lightning_event_kind = lightning_event_kind
    value.active_lightning_id = active_lightning_id
    value.active_lightning_start_tick = active_lightning_start_tick
    value.active_lightning_end_tick = active_lightning_end_tick
    value.active_lightning_intensity = active_lightning_intensity
    value.active_lightning_seed = active_lightning_seed
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
        "lightning_serial": lightning_serial,
        "lightning_event_serial": lightning_event_serial,
        "lightning_event_kind": String(lightning_event_kind),
        "active_lightning_id": active_lightning_id,
        "active_lightning_start_tick": active_lightning_start_tick,
        "active_lightning_end_tick": active_lightning_end_tick,
        "active_lightning_intensity": active_lightning_intensity,
        "active_lightning_seed": active_lightning_seed,
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
    value.lightning_serial = int(data.get("lightning_serial", -1))
    value.lightning_event_serial = int(data.get("lightning_event_serial", -1))
    value.lightning_event_kind = StringName(String(data.get("lightning_event_kind", "")))
    value.active_lightning_id = String(data.get("active_lightning_id", ""))
    value.active_lightning_start_tick = int(data.get("active_lightning_start_tick", -2))
    value.active_lightning_end_tick = int(data.get("active_lightning_end_tick", -2))
    value.active_lightning_intensity = float(data.get("active_lightning_intensity", -1.0))
    value.active_lightning_seed = int(data.get("active_lightning_seed", -1))
    if not value.is_valid(minimum_tick):
        return null
    return value
