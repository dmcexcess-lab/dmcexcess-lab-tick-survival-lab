extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)

func _run() -> void:
    var packed := load("res://main.tscn") as PackedScene
    check(packed != null, "Production scene loads")
    if packed == null:
        _finish()
        return
    var main := packed.instantiate() as EnvironmentalPressureGameMain
    check(main != null, "Production root is EnvironmentalPressureGameMain")
    if main == null:
        _finish()
        return
    root.add_child(main)
    await process_frame

    var population := main.population_plan_snapshot()
    var projection := PopulationResidentProjection.new()
    var infected_records := projection.infected_records(population)
    var survivor_records := projection.survivor_records(population)
    check(infected_records.size() == int(population.get("infected_population", -1)), "Projected infected exactly match aggregate count")
    check(survivor_records.size() == int(population.get("survivor_population", -1)), "Projected survivors exactly match aggregate count")
    check(infected_records.size() + survivor_records.size() == int(population.get("resident_population", -1)), "Resident projection is an exact partition")
    var identities: Dictionary = {}
    for record: Dictionary in infected_records:
        identities[String(record.get("resident_id", ""))] = true
    for record: Dictionary in survivor_records:
        check(not identities.has(String(record.get("resident_id", ""))), "No resident is projected both survivor and infected")

    var state := main.survivor_npc_state()
    var survivors := main.survivor_cohort_service()
    var infected := main.infected_cohort_service()
    var infection := main.survivor_infection_service()
    var social := main.survivor_interaction_service()
    check(state != null and state.actor_ids().size() == CombatGameMain.ACTIVE_SURVIVOR_COHORT_SIZE, "Four real survivor NPCs hydrate in production")
    check(survivors != null and survivors.roster_actor_ids().size() == CombatGameMain.ACTIVE_SURVIVOR_COHORT_SIZE, "Survivor cohort owns the four hydrated residents")
    check(infected != null and infected.roster_actor_ids().size() == CombatGameMain.ACTIVE_INFECTED_COHORT_SIZE, "Existing eight infected remain intact")
    check(state.actor_ids_for_role(SurvivorNpcState.NEUTRAL).size() == 2, "Two initially non-hostile survivors exist")
    check(state.actor_ids_for_role(SurvivorNpcState.RAIDER).size() == 2, "Two hostile raiders exist")

    var neutral_ids := state.actor_ids_for_role(SurvivorNpcState.NEUTRAL)
    var target_id := "" if neutral_ids.is_empty() else neutral_ids[0]
    var recruit := social.request_action(GeneratedIslandCritiqueFixture.PLAYER_ID, target_id, SurvivorInteractionOfferProvider.RECRUIT)
    check(bool(recruit.get("success", false)) and state.role(target_id) == SurvivorNpcState.FOLLOWER, "Neutral survivor can become a follower through production social action")
    var talk := social.request_action(GeneratedIslandCritiqueFixture.PLAYER_ID, target_id, SurvivorInteractionOfferProvider.TALK)
    check(bool(talk.get("success", false)) and not String(talk.get("reason", "")).is_empty(), "Follower conversation returns contextual player-facing text")
    var follower_behavior := survivors.behavior_for_actor(target_id)
    if follower_behavior != null:
        follower_behavior._drive(&"prompt_verification")
        check(follower_behavior.current_intention() in [SurvivorNpcBehaviorService.FOLLOW_PLAYER, SurvivorNpcBehaviorService.NPC_IDLE], "Follower resolves through survivor behavior policy")

    var initial_infected_count := infected.roster_actor_ids().size()
    var initial_survivor_count := survivors.roster_actor_ids().size()
    var source_id := infected.roster_actor_ids()[0]
    var target_placement: WorldPlacement = main._world.placement(target_id)
    var contact_cell := Vector2i.ZERO if target_placement == null else target_placement.anchor
    main._combat_actions.impact_resolved.emit(source_id, target_id, 9001, contact_cell, 8, "blunt")
    check(infection.exposure(target_id) > 0, "Successful infected melee impact produces causal exposure")
    main._combat_actions.impact_resolved.emit(source_id, target_id, 9002, contact_cell, 8, "blunt")
    await process_frame
    check(main.infected_state().is_infected(target_id), "Exposed survivor converts on the same resident identity")
    check(not state.has_actor(target_id), "Converted resident leaves survivor role state")
    check(survivors.roster_actor_ids().size() == initial_survivor_count - 1, "Converted resident leaves survivor cohort")
    check(infected.roster_actor_ids().size() == initial_infected_count + 1 and infected.roster_actor_ids().has(target_id), "Converted resident joins active infected cohort without replacement spawn")
    var converted_behavior := infected.behavior_for_actor(target_id)
    if converted_behavior != null:
        check(converted_behavior.opening_pressure_service() == main.opening_pressure_service(), "Newly infected resident receives ordinary environmental opening pressure")

    main.queue_free()
    await process_frame
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("PROMPT_SURVIVOR_OUTBREAK_CLOSURE_SMOKE: PASS")
    quit(0 if failures.is_empty() else 1)
