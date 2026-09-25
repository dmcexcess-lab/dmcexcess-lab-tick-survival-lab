extends SceneTree

const Fixture = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const QueryRules = preload("res://scripts/simulation/collision/SpatialQueryResult.gd")
const ConditionState = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const PerceptionFear = preload("res://scripts/simulation/actors/condition/ConditionPerceptionFearAdapter.gd")
const HeardFear = preload("res://scripts/simulation/actors/condition/ConditionHeardFearAdapter.gd")
const CombatActions = preload("res://scripts/simulation/combat/CombatActionService.gd")

func _initialize() -> void:
    var watchdog := create_timer(30.0)
    watchdog.timeout.connect(func() -> void:
        push_error("PHASE2_FEAR: verifier watchdog expired")
        quit(1)
    )
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("PHASE2_FEAR: " + message)
    quit(1)

func _run() -> void:
    var gameplay: PackedScene = load("res://gameplay.tscn")
    if gameplay == null:
        _fail("production gameplay scene missing")
        return
    var game: Node = gameplay.instantiate()
    get_root().add_child(game)
    await process_frame

    var player: String = Fixture.PLAYER_ID
    var kernel: TickKernel = game.get("_kernel")
    var world: WorldState = game.get("_world")
    var mutations: WorldMutationService = game.get("_world_mutations")
    var query: SpatialQueryService = game.get("_spatial_query")
    var movement: MovementActionService = game.get("_movement")
    var combat: CombatActionService = game.get("_combat_actions")
    var health: ActorHealthState = game.get("_health_state")
    var condition: ActorConditionService = game.get("_condition_service")
    var modifiers: ActorConditionModifierQuery = game.get("_condition_modifiers")
    var moodlets: ActorConditionMoodletQuery = game.get("_condition_moodlets")
    var fear: ActorFearPressureService = game.get("_fear_pressure")
    var perception_adapter: ConditionPerceptionFearAdapter = game.get("_condition_fear")
    var heard_adapter: ConditionHeardFearAdapter = game.get("_condition_heard_fear")
    var injury_adapter: ConditionInjuryFearAdapter = game.get("_condition_injury_fear")
    var physical_adapter: ConditionPhysicalPressureFearAdapter = game.get("_condition_physical_pressure_fear")
    var first_aid: SurvivorFirstAidActionService = game.get("_first_aid_actions")
    var crafting: CraftingActionService = game.get("_crafting_actions")
    var firearm: FirearmActionService = game.get("_firearm_actions")
    var time_profile: WorldTimeProfile = game.get("_world_time_profile")
    var cohort: ActiveInfectedCohortService = game.infected_cohort_service()

    if kernel == null or world == null or mutations == null or query == null         or movement == null or combat == null or health == null or condition == null         or modifiers == null or moodlets == null or fear == null or time_profile == null         or cohort == null:
        _fail("production fear owners are incomplete")
        return
    if not fear.is_ready() or perception_adapter == null or not perception_adapter.is_ready()         or heard_adapter == null or not heard_adapter.is_ready()         or injury_adapter == null or not injury_adapter.is_ready()         or physical_adapter == null or not physical_adapter.is_ready():
        _fail("production fear adapters are not ready")
        return

    var infected_ids: Array[String] = cohort.roster_actor_ids()
    if infected_ids.is_empty():
        _fail("need one production infected")
        return
    for actor_id: String in infected_ids:
        var behavior: CohortInfectedBehaviorService = cohort.behavior_for_actor(actor_id)
        if behavior != null:
            behavior.deactivate(&"focused_verifier")
    kernel.set_decision_actor("")

    # Flush any boot-time observation pressure, then establish a clean Calm baseline.
    for _i: int in range(4):
        if fear.pending_pressure(player) <= 0:
            break
        kernel.run_next_batch()
    if not condition.set_condition(player, ConditionState.CALM, 60, &"fear_verifier_baseline"):
        _fail("could not establish calm baseline")
        return

    print("PHASE2_FEAR_STAGE aggregate")\n\n    # 1) Same-tick fear inputs aggregate exactly once and cap at 20 Calm.
    var resolved: Array[Dictionary] = []
    fear.fear_resolved.connect(func(actor_id: String, pressure: int, before: int, after: int, _tb: StringName, _ta: StringName, sources: Array, tick: int) -> void:
        resolved.append({
            "actor": actor_id, "pressure": pressure, "before": before,
            "after": after, "sources": sources.duplicate(), "tick": tick,
        })
    )
    if not fear.queue_pressure(player, 8, &"visual_test")         or not fear.queue_pressure(player, 9, &"injury_test")         or not fear.queue_pressure(player, 9, &"pressure_test"):
        _fail("could not queue same-tick fear pressure")
        return
    if fear.pending_pressure(player) != 26:
        _fail("fear pressure did not aggregate before resolution")
        return
    kernel.run_next_batch()
    if condition.value(player, ConditionState.CALM) != 40:
        _fail("same-tick fear cap did not apply exactly once")
        return
    if resolved.size() != 1 or int(resolved[0].get("pressure", 0)) != 20:
        _fail("fear resolution did not publish one capped consequence")
        return
    var cap_sources: Array = resolved[0].get("sources", [])
    if not cap_sources.has("visual_test") or not cap_sources.has("injury_test") or not cap_sources.has("pressure_test"):
        _fail("fear aggregation lost source categories")
        return

    print("PHASE2_FEAR_STAGE explicit_effects")\n\n    # 2) Calm is no longer a hidden generic body-stat penalty.
    if not condition.set_condition(player, ConditionState.CALM, 60, &"composed"):
        _fail("could not set composed calm")
        return
    var composed: Dictionary = modifiers.modifier_snapshot(player)
    var composed_hold: int = movement.physical_contest_score(player, &"physical.hold")
    if not condition.set_condition(player, ConditionState.CALM, 10, &"terrified"):
        _fail("could not set terrified calm")
        return
    var terrified: Dictionary = modifiers.modifier_snapshot(player)
    var terrified_hold: int = movement.physical_contest_score(player, &"physical.hold")
    for key: String in ["health_multiplier_bp", "speed_multiplier_bp", "carry_multiplier_bp", "melee_damage_multiplier_bp"]:
        if int(composed.get(key, -1)) != int(terrified.get(key, -2)):
            _fail("fear still leaks into generic body modifier: " + key)
            return
    if modifiers.deliberate_action_duration_multiplier_bp(player) != 13000         or modifiers.fear_fatigue_gain_multiplier_bp(player) != 12000         or modifiers.hold_resistance_multiplier_bp(player) != 9000:
        _fail("terrified explicit modifiers are incorrect")
        return
    if terrified_hold <= 0 or composed_hold <= 0         or abs(terrified_hold * 10000 - composed_hold * 9000) > composed_hold * 100:
        _fail("terrified bracing did not apply approximately -10 percent")
        return

    var moodlet_result: Dictionary = moodlets.moodlets_for(player)
    if not bool(moodlet_result.get("ok", false)) or not _has_label(moodlet_result.get("moodlets", []), "Terrified"):
        _fail("Terrified player feedback is missing")
        return

    print("PHASE2_FEAR_STAGE timing")\n\n    # 3) Fear slows a deliberate melee strike but not locomotion or shove escape.
    var line: Array[Vector2i] = _find_clear_horizontal_run(query, world.placement(player).anchor, 4)
    if line.size() != 4:
        _fail("could not find fear timing fixture")
        return
    var infected: String = infected_ids[0]
    if not _place_actor(mutations, world, player, line[1], Facing.Value.EAST)         or not _place_actor(mutations, world, infected, line[2], Facing.Value.WEST):
        _fail("could not arrange fear timing actors")
        return

    if not condition.set_condition(player, ConditionState.CALM, 60, &"composed_timing"):
        _fail("could not reset composed timing")
        return
    var base_move: MovementActionResult = movement.request_step_backward(player)
    if base_move == null or not base_move.is_accepted():
        _fail("composed movement timing request failed")
        return
    var composed_move_ticks: int = base_move.duration_ticks
    kernel.interrupt_action(base_move.action_serial, "verifier")

    var base_strike: Dictionary = combat.request_action(player, infected, CombatActions.STRIKE_UNARMED)
    if not bool(base_strike.get("accepted", false)):
        _fail("composed strike timing request failed")
        return
    var composed_strike_ticks: int = int(base_strike.get("duration_ticks", 0))
    kernel.interrupt_action(int(base_strike.get("action_serial", 0)), "verifier")

    if not condition.set_condition(player, ConditionState.CALM, 10, &"terrified_timing"):
        _fail("could not set terrified timing")
        return
    var fear_move: MovementActionResult = movement.request_step_backward(player)
    if fear_move == null or not fear_move.is_accepted():
        _fail("terrified movement timing request failed")
        return
    var terrified_move_ticks: int = fear_move.duration_ticks
    kernel.interrupt_action(fear_move.action_serial, "verifier")

    var fear_strike: Dictionary = combat.request_action(player, infected, CombatActions.STRIKE_UNARMED)
    if not bool(fear_strike.get("accepted", false)):
        _fail("terrified strike timing request failed")
        return
    var terrified_strike_ticks: int = int(fear_strike.get("duration_ticks", 0))
    kernel.interrupt_action(int(fear_strike.get("action_serial", 0)), "verifier")

    var shove: Dictionary = combat.request_action(player, infected, CombatActions.SHOVE)
    if not bool(shove.get("accepted", false)) or int(shove.get("duration_ticks", 0)) != 6:
        _fail("terrified shove escape timing changed")
        return
    # Shove is committed; resolve it rather than trying to cancel it.
    _run_until_action_finishes(kernel, int(shove.get("action_serial", 0)))

    if composed_move_ticks != terrified_move_ticks:
        _fail("fear incorrectly slowed locomotion")
        return
    if terrified_strike_ticks <= composed_strike_ticks:
        _fail("fear did not slow deliberate melee")
        return

    if first_aid == null or crafting == null or firearm == null         or first_aid.get("_condition_modifiers") != modifiers         or crafting.get("_condition_modifiers") != modifiers         or firearm.get("_condition_modifiers") != modifiers:
        _fail("deliberate-action fear timing is not wired across production services")
        return

    print("PHASE2_FEAR_STAGE sources")\n\n    # 4) Injury shock and physical crowd pressure feed the same aggregate owner.
    resolved.clear()
    if not condition.set_condition(player, ConditionState.CALM, 60, &"injury_pressure_test"):
        _fail("could not reset injury fear fixture")
        return
    var max_hp: int = health.max_hp(player)
    if not health.set_hp(player, max_hp):
        _fail("could not reset player hp")
        return
    if not health.apply_damage(player, 2):
        _fail("could not apply injury fear fixture damage")
        return
    if fear.pending_pressure(player) < 3:
        _fail("injury did not queue fear pressure")
        return
    kernel.run_next_batch()
    if not _resolved_has_source(resolved, "injury_shock"):
        _fail("injury fear did not resolve through aggregate owner")
        return
    health.set_hp(player, max_hp)

    resolved.clear()
    condition.set_condition(player, ConditionState.CALM, 60, &"physical_pressure_test")
    if not _place_actor(mutations, world, infected, line[0], Facing.Value.EAST)         or not _place_actor(mutations, world, player, line[1], Facing.Value.EAST):
        _fail("could not arrange physical-pressure fear fixture")
        return
    var hold_score: int = movement.physical_contest_score(player, &"physical.hold")
    if hold_score <= 0 or not movement.queue_forced_displacement(
        infected, player, 990001, Vector2i.RIGHT, 1, hold_score
    ):
        _fail("could not queue resisted physical pressure")
        return
    kernel.run_next_batch()
    if fear.pending_pressure(player) > 0:
        kernel.run_next_batch()
    if not _resolved_has_source(resolved, "physical_crowd_pressure"):
        _fail("resolved body pressure did not create fear pressure")
        return

    print("PHASE2_FEAR_STAGE classification")\n\n    # 5) Existing visual/sound adapters use explicit bounded observations.
    if PerceptionFear._band_for_distance(1) != PerceptionFear.BAND_CONTACT         or PerceptionFear._band_for_distance(4) != PerceptionFear.BAND_NEAR         or PerceptionFear._band_for_distance(7) != PerceptionFear.BAND_FAR:
        _fail("visual fear bands are incorrect")
        return
    if HeardFear.fear_pressure(&"threat", 0.90) != 5         or HeardFear.fear_pressure(&"movement", 1.0) != 0:
        _fail("heard fear classification is incorrect")
        return

    print("PHASE2_FEAR_STAGE recovery")\n\n    # 6) Fear recovers analytically toward neutral on game time, with no fear loop.
    condition.set_condition(player, ConditionState.CALM, 0, &"recovery_test")
    var future_tick: int = kernel.world_tick() + time_profile.ticks_per_hour()
    var future_raw: Dictionary = modifiers.raw_values_at(player, future_tick)
    var calm_after_hour: int = int(future_raw.get("calm", -1)) / ConditionState.VALUE_SCALE
    if calm_after_hour < 20 or calm_after_hour > 30:
        _fail("Calm recovery is not in the intended hours-scale window")
        return

    print("PHASE2_FEAR_OK aggregate_cap=true explicit_effects=true escape_responsive=true injury=true pressure=true recovery=true")
    quit(0)

func _run_until_action_finishes(kernel: TickKernel, serial: int) -> void:
    for _i: int in range(64):
        if kernel.action_by_serial(serial) == null:
            return
        kernel.run_next_batch()

func _place_actor(mutations: WorldMutationService, world: WorldState, actor_id: String, cell: Vector2i, facing: int) -> bool:
    var placement: WorldPlacement = world.placement(actor_id)
    if placement == null or placement.channel != Layers.Channel.ACTOR:
        return false
    return mutations.set_placement(actor_id, placement.channel, cell, facing, placement.footprint, placement.structure_axis)

func _find_clear_horizontal_run(query: SpatialQueryService, center: Vector2i, count: int) -> Array[Vector2i]:
    for radius: int in range(1, 28):
        for dy: int in range(-radius, radius + 1):
            for dx: int in range(-radius, radius - count + 2):
                var start := center + Vector2i(dx, dy)
                var result: Array[Vector2i] = []
                var clear: bool = true
                for offset: int in range(count):
                    var cell := start + Vector2i(offset, 0)
                    var q: SpatialQueryResult = query.query_cell(cell, "", true)
                    if q == null or q.status != QueryRules.Status.CLEAR:
                        clear = false
                        break
                    result.append(cell)
                if clear:
                    return result
    return []

static func _has_label(entries: Array, label: String) -> bool:
    for entry: Variant in entries:
        if typeof(entry) == TYPE_DICTIONARY and String((entry as Dictionary).get("label", "")) == label:
            return true
    return false

static func _resolved_has_source(entries: Array[Dictionary], source: String) -> bool:
    for entry: Dictionary in entries:
        var sources: Array = entry.get("sources", [])
        if sources.has(source):
            return true
    return false
