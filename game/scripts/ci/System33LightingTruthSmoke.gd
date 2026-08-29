extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const GlobalFixture = preload("res://scripts/demo/GlobalWorldPlanFixture.gd")
const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandSlots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const UtilityStateClass = preload("res://scripts/simulation/utilities/UtilityRuntimeState.gd")
const LightingSourceClass = preload("res://scripts/simulation/utilities/UtilityPoweredLightingSourceAdapter.gd")
const LegacyLightingClass = preload("res://scripts/demo/DemoLightingSourceAdapter.gd")

const PLAYER_ID: String = "actor.player.lighting_truth"
const FIXTURE_ID: String = "fixture.traffic_light.lighting_truth"
const ROOM_LIGHT_ID: String = "fixture.room_light.lighting_truth"
const FLASHLIGHT_ID: String = "item.flashlight.lighting_truth"
const FIXTURE_CELL := Vector2i(420, 1500)
const ROOM_LIGHT_CELL := Vector2i(421, 1500)
const PLAYER_CELL := Vector2i(418, 1500)

var _failures: Array[String] = []

func _initialize() -> void:
    _test_truthful_source_ownership()
    if _failures.is_empty():
        print("SYSTEM33_LIGHTING_TRUTH_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("SYSTEM33_LIGHTING_TRUTH_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_truthful_source_ownership() -> void:
    var world: WorldState = _lighting_world()
    var hands: ActorHandEquipmentState = _hand_state()
    var utilities: UtilityRuntimeState = _utility_state()
    if world == null or hands == null or utilities == null:
        return

    _check(world.entity_ids_of_type(&"prop.traffic_light").has(FIXTURE_ID), "WHAT semantic index finds the real traffic-light entity")
    _check(world.entity_ids_of_type(&"fixture.room_light").has(ROOM_LIGHT_ID), "WHAT semantic index finds the persistent room-light fixture")

    var legacy := LegacyLightingClass.new(world, PLAYER_ID)
    _check(legacy.is_ready(), "legacy bootstrap shim remains constructible")
    _check(legacy.emitters().is_empty(), "legacy bootstrap emits no fake flashlight or guessed fixture light")

    var sources := LightingSourceClass.new(world, hands, PLAYER_ID, utilities)
    _check(sources.is_ready(), "truthful utility lighting source provider is ready")

    var fixed_emitter_id: String = "utility.light:%s" % FIXTURE_ID
    var room_emitter_id: String = "utility.light:%s" % ROOM_LIGHT_ID
    var flashlight_emitter_id: String = "equipment.flashlight:%s" % FLASHLIGHT_ID
    var initial: Array[LightEmitter] = sources.emitters()
    var fixed: LightEmitter = _find_emitter(initial, fixed_emitter_id)
    var room: LightEmitter = _find_emitter(initial, room_emitter_id)
    _check(fixed != null, "real traffic-light entity creates a fixed emitter")
    if fixed != null:
        _check(fixed.origin_cell == FIXTURE_CELL, "fixed emitter uses the fixture's actual WHAT placement")
        _check(fixed.facing == Facing.Value.SOUTH, "fixed emitter uses the fixture's actual facing")
    _check(room != null, "persistent room-light fixture creates a fixed emitter")
    if room != null:
        _check(room.origin_cell == ROOM_LIGHT_CELL, "room emitter uses the room fixture's actual WHAT placement")
        _check(room.profile.profile_id == &"light.room_ambient.candidate001", "room fixture uses the room ambient physical-light profile")
        _check(is_zero_approx(room.profile.presentation_glow_scale), "room ambient profile explicitly suppresses presentation bloom")
    _check(_find_emitter(initial, flashlight_emitter_id) == null, "player has no flashlight beam while no flashlight is equipped")

    var appliance: Dictionary = utilities.appliance_record(fixed_emitter_id)
    _check(String(appliance.get("owner_entity_id", "")) == FIXTURE_ID, "fixed-light appliance is bound to the real fixture entity")
    var service_id: String = String(appliance.get("power_service_id", ""))
    _check(not service_id.is_empty(), "real fixture resolves a local power service")
    var room_appliance: Dictionary = utilities.appliance_record(room_emitter_id)
    _check(String(room_appliance.get("owner_entity_id", "")) == ROOM_LIGHT_ID, "room-light appliance is bound to the real room fixture entity")
    _check(String(room_appliance.get("power_service_id", "")) == service_id, "nearby room fixture resolves the same local power service")

    _check(hands._set_item_record(PLAYER_ID, HandSlots.Value.PRIMARY_RIGHT, FLASHLIGHT_ID), "test equips the real flashlight item")
    var equipped: Array[LightEmitter] = sources.emitters()
    var flashlight: LightEmitter = _find_emitter(equipped, flashlight_emitter_id)
    _check(flashlight != null, "equipping item.tool.flashlight creates the player beam")
    if flashlight != null:
        _check(flashlight.origin_cell == PLAYER_CELL, "flashlight beam originates at the controlled actor")
        _check(flashlight.facing == Facing.Value.EAST, "flashlight beam follows actor facing")

    var branch_id: String = utilities.power_branch_component_id(service_id)
    _check(not branch_id.is_empty(), "fixture service exposes a local branch")
    if not branch_id.is_empty():
        _check(utilities.set_power_component_state(branch_id, UtilityRuntimeState.DAMAGED, &"lighting_truth_outage"), "local power outage mutates canonical utility truth")
        var dark: Array[LightEmitter] = sources.emitters()
        _check(_find_emitter(dark, fixed_emitter_id) == null, "local power loss removes the real fixed emitter")
        _check(_find_emitter(dark, room_emitter_id) == null, "local power loss removes the room ambient emitter")
        _check(_find_emitter(dark, flashlight_emitter_id) != null, "grid outage does not fake-disable equipped portable flashlight")
        _check(utilities.set_power_component_state(branch_id, UtilityRuntimeState.OPERATIONAL, &"lighting_truth_restore"), "local power restores")
        var restored: Array[LightEmitter] = sources.emitters()
        _check(_find_emitter(restored, fixed_emitter_id) != null, "restored service restores the real fixed emitter")
        _check(_find_emitter(restored, room_emitter_id) != null, "restored service restores the room ambient emitter")

    _check(hands._set_item_record(PLAYER_ID, HandSlots.Value.PRIMARY_RIGHT, ""), "test unequips flashlight")
    _check(_find_emitter(sources.emitters(), flashlight_emitter_id) == null, "unequipping flashlight removes the beam")

func _lighting_world() -> WorldState:
    var world := WorldStateClass.new()
    var snapshot := {
        "schema_version": 1,
        "next_entity_serial": 1,
        "revision": 1,
        "terrain": [],
        "entities": [
            {"id": PLAYER_ID, "semantic_type": "actor.survivor"},
            {"id": FIXTURE_ID, "semantic_type": "prop.traffic_light"},
            {"id": ROOM_LIGHT_ID, "semantic_type": "fixture.room_light"},
            {"id": FLASHLIGHT_ID, "semantic_type": "item.tool.flashlight"},
        ],
        "placements": [
            {
                "entity_id": PLAYER_ID,
                "channel": Layers.Channel.ACTOR,
                "anchor": [PLAYER_CELL.x, PLAYER_CELL.y],
                "facing": Facing.Value.EAST,
                "footprint": [[0, 0]],
                "structure_axis": -1,
            },
            {
                "entity_id": FIXTURE_ID,
                "channel": Layers.Channel.OBJECT,
                "anchor": [FIXTURE_CELL.x, FIXTURE_CELL.y],
                "facing": Facing.Value.SOUTH,
                "footprint": [[0, 0]],
                "structure_axis": -1,
            },
            {
                "entity_id": ROOM_LIGHT_ID,
                "channel": Layers.Channel.EFFECT,
                "anchor": [ROOM_LIGHT_CELL.x, ROOM_LIGHT_CELL.y],
                "facing": Facing.Value.NORTH,
                "footprint": [[0, 0]],
                "structure_axis": -1,
            },
        ],
    }
    _check(world.load_snapshot(snapshot), "lighting test WHAT snapshot loads")
    return world

func _hand_state() -> ActorHandEquipmentState:
    var hands := HandStateClass.new()
    var snapshot := {
        "schema_version": 1,
        "revision": 1,
        "records": [
            {
                "actor_id": PLAYER_ID,
                "primary_item_id": "",
                "secondary_item_id": "",
                "version": 1,
            },
        ],
    }
    _check(hands.load_snapshot(snapshot), "lighting test hand state loads")
    return hands

func _utility_state() -> UtilityRuntimeState:
    var plan: GeneratedGlobalWorldPlan = Fixture.generate_global_plan(GlobalFixture.SEED)
    _check(plan != null and plan.is_generated(), "canonical island plan generates for lighting test")
    if plan == null or not plan.is_generated():
        return null
    var utilities := UtilityStateClass.new()
    _check(utilities.initialize_from_plan(plan), "utility state initializes for lighting test")
    return utilities

func _find_emitter(values: Array[LightEmitter], emitter_id: String) -> LightEmitter:
    for emitter: LightEmitter in values:
        if emitter != null and emitter.emitter_id == emitter_id:
            return emitter
    return null

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
