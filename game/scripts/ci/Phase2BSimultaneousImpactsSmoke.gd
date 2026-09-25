extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2B_SIMULTANEOUS_IMPACTS: " + message)
    quit(1)

func _run() -> void:
    var gameplay: PackedScene = load("res://gameplay.tscn")
    if gameplay == null:
        _fail("production gameplay scene missing")
        return
    var game: Node = gameplay.instantiate()
    get_root().add_child(game)
    await process_frame

    var combat: CombatActionService = game.get("_combat_actions")
    var health: ActorHealthState = game.get("_health_state")
    var deaths: ActorDeathTransitionService = game.get("_death_transitions")
    var corpses: CorpseState = game.get("_corpse_state")
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var hands: ActorHandEquipmentMutationService = game.get("_hand_mutations")
    var kernel: TickKernel = game.get("_kernel")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()
    if combat == null or health == null or deaths == null or corpses == null or world == null         or mutations == null or hands == null or kernel == null or cohort == null:
        _fail("production combat consequence owners are incomplete")
        return

    var infected_ids: Array[String] = cohort.roster_actor_ids()
    if infected_ids.size() < 3:
        _fail("need three production infected for focused simultaneous-impact scenarios")
        return
    for infected_id: String in infected_ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(infected_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")

    if not hands.clear_slot(Fixture.PLAYER_ID, Slots.Value.PRIMARY_RIGHT)         or not hands.clear_slot(Fixture.PLAYER_ID, Slots.Value.SECONDARY_LEFT):
        _fail("could not expose player empty hands")
        return

    var event_log: Array[Dictionary] = []
    combat.impact_resolved.connect(func(attacker_id: String, target_id: String, serial: int, _cell: Vector2i, damage: int, _mode: StringName) -> void:
        event_log.append({
            "kind": "impact",
            "attacker": attacker_id,
            "target": target_id,
            "serial": serial,
            "damage": damage,
            "tick": kernel.world_tick(),
        })
    )
    deaths.actor_died.connect(func(actor_id: String, corpse_id: String) -> void:
        event_log.append({
            "kind": "death",
            "actor": actor_id,
            "corpse": corpse_id,
            "tick": kernel.world_tick(),
        })
    )

    # Scenario 1: two attackers contact the same 1-HP target on one tick.
    # Both contacts must publish before the target's death/corpse transition.
    var shared_target: String = infected_ids[0]
    var other_attacker: String = infected_ids[1]
    var base: Vector2i = world.placement(Fixture.PLAYER_ID).anchor
    if not _place_actor(mutations, world, Fixture.PLAYER_ID, base, Facing.Value.EAST)         or not _place_actor(mutations, world, shared_target, base + Vector2i(1, 0), Facing.Value.NORTH)         or not _place_actor(mutations, world, other_attacker, base + Vector2i(2, 0), Facing.Value.WEST):
        _fail("could not arrange shared-target contact geometry")
        return
    if not health.set_hp(shared_target, 1):
        _fail("could not prime shared target HP")
        return

    var first_player: Dictionary = combat.request_action(Fixture.PLAYER_ID, shared_target, CombatActionService.STRIKE_UNARMED)
    var first_other: Dictionary = combat.request_action(other_attacker, shared_target, CombatActionService.STRIKE_UNARMED)
    if not bool(first_player.get("accepted", false)) or not bool(first_other.get("accepted", false)):
        _fail("shared-target strikes were not both accepted")
        return
    _run_to_player_pause(kernel)

    var shared_impacts: Array[Dictionary] = []
    var shared_death_index: int = -1
    for index: int in range(event_log.size()):
        var entry: Dictionary = event_log[index]
        if String(entry.get("kind", "")) == "impact" and String(entry.get("target", "")) == shared_target:
            shared_impacts.append(entry)
        if String(entry.get("kind", "")) == "death" and String(entry.get("actor", "")) == shared_target:
            shared_death_index = index
    if shared_impacts.size() != 2:
        _fail("shared target did not receive both same-tick impacts")
        return
    if int(shared_impacts[0].get("tick", -1)) != int(shared_impacts[1].get("tick", -2)):
        _fail("shared-target impacts did not resolve on one tick")
        return
    if shared_death_index < 0:
        _fail("shared target did not transition to a corpse")
        return
    for entry: Dictionary in shared_impacts:
        var idx: int = event_log.find(entry)
        if idx < 0 or idx >= shared_death_index:
            _fail("death published before all shared-target impacts")
            return
    if health.current_hp(shared_target) != 0 or health.injuries(shared_target).size() < 2         or not corpses.has_corpse_for_actor(shared_target):
        _fail("shared-target final health/injury/corpse truth is incomplete")
        return

    # Scenario 2: mutual lethal contact. Both actors are alive in the pre-tick
    # snapshot, both attacks contact on the same tick, both hits land, both die.
    event_log.clear()
    var opponent: String = infected_ids[2]
    var mutual_base := base + Vector2i(0, 4)
    if not _place_actor(mutations, world, Fixture.PLAYER_ID, mutual_base, Facing.Value.EAST)         or not _place_actor(mutations, world, opponent, mutual_base + Vector2i(1, 0), Facing.Value.WEST):
        _fail("could not arrange mutual-lethal contact geometry")
        return
    if not health.set_hp(Fixture.PLAYER_ID, 1) or not health.set_hp(opponent, 1):
        _fail("could not prime mutual-lethal HP")
        return

    var mutual_player: Dictionary = combat.request_action(Fixture.PLAYER_ID, opponent, CombatActionService.STRIKE_UNARMED)
    var mutual_zombie: Dictionary = combat.request_action(opponent, Fixture.PLAYER_ID, CombatActionService.STRIKE_UNARMED)
    if not bool(mutual_player.get("accepted", false)) or not bool(mutual_zombie.get("accepted", false)):
        _fail("mutual-lethal strikes were not both accepted")
        return
    _run_to_player_pause(kernel)

    var mutual_impacts: Array[Dictionary] = []
    var first_death_index: int = 2147483647
    for index: int in range(event_log.size()):
        var entry: Dictionary = event_log[index]
        if String(entry.get("kind", "")) == "impact":
            mutual_impacts.append(entry)
        elif String(entry.get("kind", "")) == "death":
            first_death_index = mini(first_death_index, index)
    if mutual_impacts.size() != 2:
        _fail("mutual lethal tick did not publish both impacts")
        return
    if int(mutual_impacts[0].get("tick", -1)) != int(mutual_impacts[1].get("tick", -2)):
        _fail("mutual lethal impacts were not simultaneous")
        return
    if first_death_index == 2147483647:
        _fail("mutual lethal tick published no deaths")
        return
    for impact: Dictionary in mutual_impacts:
        var idx: int = event_log.find(impact)
        if idx < 0 or idx >= first_death_index:
            _fail("a death/corpse transition published before both mutual hits")
            return
    if health.current_hp(Fixture.PLAYER_ID) != 0 or health.current_hp(opponent) != 0:
        _fail("mutual lethal HP truth did not kill both actors")
        return
    if not corpses.has_corpse_for_actor(Fixture.PLAYER_ID) or not corpses.has_corpse_for_actor(opponent):
        _fail("mutual lethal contact did not create both corpses")
        return

    print(
        "PHASE2B_SIMULTANEOUS_IMPACTS_OK shared_tick=%d mutual_tick=%d impacts_before_death=true" % [
            int(shared_impacts[0].get("tick", -1)),
            int(mutual_impacts[0].get("tick", -1)),
        ]
    )
    quit(0)

func _place_actor(mutations: WorldMutationService, world: WorldState, actor_id: String, cell: Vector2i, facing: int) -> bool:
    var placement: WorldPlacement = world.placement(actor_id)
    if placement == null:
        return false
    return mutations.set_placement(actor_id, placement.channel, cell, facing, placement.footprint, placement.structure_axis)

func _run_to_player_pause(kernel: TickKernel) -> void:
    for _batch: int in range(128):
        if kernel.is_decision_paused():
            return
        kernel.run_next_batch()
