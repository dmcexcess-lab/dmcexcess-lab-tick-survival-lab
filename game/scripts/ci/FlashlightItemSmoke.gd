extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandSlots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const FlashlightStateClass = preload("res://scripts/simulation/items/lighting/FlashlightItemState.gd")
const FlashlightActionClass = preload("res://scripts/simulation/items/lighting/FlashlightToggleActionService.gd")

const PLAYER_ID: String = "actor.player.flashlight"
const FLASHLIGHT_ID: String = "item.flashlight.real"
const OTHER_ITEM_ID: String = "item.other.real"

var _failures: Array[String] = []

func _initialize() -> void:
    var world := WorldStateClass.new()
    _check(world.load_snapshot({
        "schema_version": 1,
        "next_entity_serial": 1,
        "revision": 1,
        "terrain": [],
        "entities": [
            {"id": PLAYER_ID, "semantic_type": "actor.survivor"},
            {"id": FLASHLIGHT_ID, "semantic_type": "item.tool.flashlight"},
            {"id": OTHER_ITEM_ID, "semantic_type": "item.tool.hammer"},
        ],
        "placements": [],
    }), "WHAT state loads exact player and item identities")

    var hands := HandStateClass.new()
    _check(hands.load_snapshot({
        "schema_version": 1,
        "revision": 1,
        "records": [{
            "actor_id": PLAYER_ID,
            "primary_item_id": "",
            "secondary_item_id": "",
            "version": 1,
        }],
    }), "hand state loads")

    var kernel := TickKernelClass.new(PLAYER_ID)
    var state := FlashlightStateClass.new()
    var actions := FlashlightActionClass.new(world, hands, state, kernel)
    _check(actions.is_ready(), "flashlight switch action owner is ready")
    _check(not state.is_switched_on(FLASHLIGHT_ID), "real flashlight defaults OFF")

    var stowed_offer: Dictionary = actions.toggle_offer(PLAYER_ID, FLASHLIGHT_ID)
    _check(bool(stowed_offer.get("applicable", false)) and not bool(stowed_offer.get("available", false)), "stowed flashlight is recognized but switch is not remotely operable")
    _check(String(stowed_offer.get("reason", "")) == "item_not_equipped", "stowed switch refusal names physical prerequisite")
    _check(actions.begin_toggle(PLAYER_ID, FLASHLIGHT_ID) == 0, "stowed flashlight cannot start switch action")

    _check(hands._set_item_record(PLAYER_ID, HandSlots.Value.PRIMARY_RIGHT, FLASHLIGHT_ID), "exact flashlight equips to right hand")
    var off_offer: Dictionary = actions.toggle_offer(PLAYER_ID, FLASHLIGHT_ID)
    _check(bool(off_offer.get("available", false)) and String(off_offer.get("label", "")) == "TURN ON", "equipped OFF flashlight exposes TURN ON")
    var on_serial: int = actions.begin_toggle(PLAYER_ID, FLASHLIGHT_ID)
    _check(on_serial > 0, "TURN ON starts a real WHEN action")
    kernel.run_until_stop()
    var on_outcome: Dictionary = actions.toggle_outcome(on_serial)
    _check(bool(on_outcome.get("committed", false)) and bool(on_outcome.get("switched_on", false)), "TURN ON commits exact item switch truth")
    _check(kernel.world_tick() == 1, "flashlight switch spends one real WHEN tick")
    _check(state.is_switched_on(FLASHLIGHT_ID), "exact item remains ON after action")

    var snapshot: Dictionary = state.snapshot()
    var restored := FlashlightStateClass.new()
    _check(restored.load_snapshot(snapshot), "flashlight switch state snapshot roundtrips")
    _check(restored.is_switched_on(FLASHLIGHT_ID), "snapshot preserves exact flashlight ON state")

    _check(hands._set_item_record(PLAYER_ID, HandSlots.Value.PRIMARY_RIGHT, ""), "flashlight stows")
    _check(state.is_switched_on(FLASHLIGHT_ID), "stowing does not erase ON state")
    _check(hands._set_item_record(PLAYER_ID, HandSlots.Value.SECONDARY_LEFT, FLASHLIGHT_ID), "same flashlight re-equips to left hand")
    var on_offer: Dictionary = actions.toggle_offer(PLAYER_ID, FLASHLIGHT_ID)
    _check(bool(on_offer.get("available", false)) and String(on_offer.get("label", "")) == "TURN OFF", "re-equipped still-ON flashlight exposes TURN OFF")
    var off_serial: int = actions.begin_toggle(PLAYER_ID, FLASHLIGHT_ID)
    _check(off_serial > 0, "TURN OFF starts a real WHEN action")
    kernel.run_until_stop()
    var off_outcome: Dictionary = actions.toggle_outcome(off_serial)
    _check(bool(off_outcome.get("committed", false)) and not bool(off_outcome.get("switched_on", true)), "TURN OFF commits exact item switch truth")
    _check(kernel.world_tick() == 2 and not state.is_switched_on(FLASHLIGHT_ID), "TURN OFF spends one more tick and leaves exact item OFF")

    var wrong_offer: Dictionary = actions.toggle_offer(PLAYER_ID, OTHER_ITEM_ID)
    _check(not bool(wrong_offer.get("applicable", true)), "non-flashlight item never receives fake switch affordance")

    if _failures.is_empty():
        print("FLASHLIGHT_ITEM_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("FLASHLIGHT_ITEM_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
