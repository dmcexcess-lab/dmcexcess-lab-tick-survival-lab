extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const CatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const OverrideClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const QueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const TickRules = preload("res://scripts/foundation/time/TickRules.gd")
const BasePolicyClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/MovementActionService.gd")
const MovementResult = preload("res://scripts/simulation/movement/MovementActionResult.gd")
const StanceRules = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const CapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const CapabilityDecision = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityDecision.gd")
const ActorPolicyClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const StanceActionClass = preload("res://scripts/simulation/actors/locomotion/ActorStanceActionService.gd")
const StanceResult = preload("res://scripts/simulation/actors/locomotion/ActorStanceActionResult.gd")
const ProviderClass = preload("res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd")
const TestProviderClass = preload("res://scripts/ci/ActorLocomotionTestProvider.gd")

var _failures: Array[String] = []

func _initialize() -> void:
    _test_state_and_snapshot()
    _test_capability_composition()
    _test_timed_stance_actions()
    _test_stance_failure_edges()
    _test_actor_aware_movement()
    _test_commit_time_capability_revalidation()

    if _failures.is_empty():
        print("ACTOR_LOCOMOTION_SMOKE_OK")
        quit(0)
        return

    for failure: String in _failures:
        push_error("ACTOR_LOCOMOTION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    var overrides := OverrideClass.new()
    var query := QueryClass.new(world, catalog, overrides)
    var kernel := TickKernelClass.new()

    var locomotion := LocomotionStateClass.new()
    var locomotion_mutations := LocomotionMutationClass.new(locomotion)
    var capability := CapabilityClass.new(locomotion)

    var base_policy := BasePolicyClass.new(3)
    var actor_policy := ActorPolicyClass.new(base_policy, capability)
    var movement := MovementClass.new(world, world_mutations, query, kernel, actor_policy)
    var stance_actions := StanceActionClass.new(
        world,
        locomotion,
        locomotion_mutations,
        kernel,
        capability
    )

    _check(catalog.register(&"actor.person", true), "fixture actor collision profile")
    _check(catalog.register(&"structure.wall", true), "fixture wall collision profile")
    _check(base_policy.register_terrain(&"ground.test", true, 10), "fixture terrain policy")
    _check(base_policy.register_terrain(&"ground.water", false), "fixture blocked terrain policy")

    for y: int in range(0, 20):
        for x: int in range(0, 24):
            _check(world_mutations.set_terrain(Vector2i(x, y), &"ground.test"), "fixture terrain setup")

    _check(actor_policy.is_ready(), "actor-aware movement policy ready")
    _check(movement.is_ready(), "movement composes actor-aware policy")
    _check(stance_actions.is_ready(), "stance action service ready")

    return {
        "world": world,
        "world_mutations": world_mutations,
        "catalog": catalog,
        "query": query,
        "kernel": kernel,
        "locomotion": locomotion,
        "locomotion_mutations": locomotion_mutations,
        "capability": capability,
        "base_policy": base_policy,
        "actor_policy": actor_policy,
        "movement": movement,
        "stance_actions": stance_actions,
    }

func _place_actor(
    fixture: Dictionary,
    actor_id: String,
    anchor: Vector2i,
    facing: int = Facing.Value.EAST,
    enroll: bool = true
) -> void:
    var mutations: WorldMutationService = fixture["world_mutations"]
    _check(mutations.create_entity(&"actor.person", actor_id) == actor_id, "create %s" % actor_id)
    _check(
        mutations.set_placement(
            actor_id,
            Layers.Channel.ACTOR,
            anchor,
            facing,
            Footprint.single_cell()
        ),
        "place %s" % actor_id
    )
    if enroll:
        var locomotion_mutations: ActorLocomotionMutationService = fixture["locomotion_mutations"]
        _check(locomotion_mutations.enroll(actor_id), "enroll %s locomotion" % actor_id)

func _test_state_and_snapshot() -> void:
    var state := LocomotionStateClass.new()
    var mutations := LocomotionMutationClass.new(state)

    _check(mutations.enroll("actor_state"), "explicit locomotion enrollment succeeds")
    _check(not mutations.enroll("actor_state"), "duplicate enrollment rejected")
    _check(state.revision() == 1, "enrollment advances locomotion revision")
    _check(state.stance("actor_state") == StanceRules.STANDING, "explicit enrollment defaults standing")
    _check(state.version("actor_state") == 1, "new locomotion record starts version one")

    _check(mutations.set_stance("actor_state", StanceRules.CROUCHED), "stance mutation succeeds")
    _check(state.stance("actor_state") == StanceRules.CROUCHED, "stance mutation stored")
    _check(state.version("actor_state") == 2, "stance mutation advances per-actor version")
    _check(state.revision() == 2, "stance mutation advances store revision")

    var snapshot: Dictionary = state.snapshot()
    _check(mutations.set_stance("actor_state", StanceRules.STANDING), "post-snapshot mutation succeeds")
    _check(state.load_snapshot(snapshot), "valid locomotion snapshot restores")
    _check(state.stance("actor_state") == StanceRules.CROUCHED, "snapshot restores semantic stance")
    _check(state.version("actor_state") == 2 and state.revision() == 2, "snapshot restores versions/revision")

    var before_bad: Dictionary = state.snapshot()
    var malformed: Dictionary = snapshot.duplicate(true)
    var malformed_records: Array = malformed["records"]
    var malformed_record: Dictionary = malformed_records[0]
    malformed_record["stance"] = "flying"
    malformed_records[0] = malformed_record
    _check(not state.load_snapshot(malformed), "malformed locomotion snapshot rejected")
    _check(state.snapshot() == before_bad, "malformed restore is atomic")

    _check(mutations.remove("actor_state"), "locomotion cleanup explicit")
    _check(not state.has_actor("actor_state"), "removed locomotion record absent")

func _test_capability_composition() -> void:
    var state := LocomotionStateClass.new()
    var mutations := LocomotionMutationClass.new(state)
    var capability := CapabilityClass.new(state)
    _check(mutations.enroll("actor_cap"), "capability actor enrolled")

    var stand_walk: ActorMovementCapabilityDecision = capability.evaluate(
        "actor_cap",
        &"movement.step_forward",
        10
    )
    _check(stand_walk.is_allowed() and stand_walk.duration_ticks == 10, "standing walk preserves base duration")

    _check(mutations.set_stance("actor_cap", StanceRules.CROUCHED), "capability actor crouches")
    var crouch_walk: ActorMovementCapabilityDecision = capability.evaluate(
        "actor_cap",
        &"movement.step_forward",
        10
    )
    _check(crouch_walk.is_allowed() and crouch_walk.duration_ticks == 14, "crouch walk uses deterministic 1.4x scale")

    var crouch_turn: ActorMovementCapabilityDecision = capability.evaluate(
        "actor_cap",
        &"movement.turn_left",
        3
    )
    _check(crouch_turn.is_allowed() and crouch_turn.duration_ticks == 3, "crouched turn remains normal speed")

    var crouch_run: ActorMovementCapabilityDecision = capability.evaluate(
        "actor_cap",
        &"movement.run_forward",
        6
    )
    _check(
        crouch_run.status == CapabilityDecision.Status.CAPABILITY_BLOCKED,
        "crouched future run capability is blocked"
    )

    var unclassified: ActorMovementCapabilityDecision = capability.evaluate(
        "missing_actor",
        &"movement.step_forward",
        10
    )
    _check(
        unclassified.status == CapabilityDecision.Status.ACTOR_UNCLASSIFIED,
        "missing locomotion record fails closed"
    )

    _check(mutations.set_stance("actor_cap", StanceRules.STANDING), "capability actor returns standing")
    var provider_z := TestProviderClass.new("z_provider", ProviderClass.Status.ALLOWED, 2000)
    var provider_a := TestProviderClass.new("a_provider", ProviderClass.Status.ALLOWED, 1000)
    _check(capability.register_provider(provider_z), "provider z registered")
    _check(capability.register_provider(provider_a), "provider a registered")
    _check(not capability.register_provider(TestProviderClass.new("a_provider")), "duplicate provider id rejected")
    _check(capability.provider_ids() == ["a_provider", "z_provider"], "providers expose deterministic sorted IDs")

    var adjusted: ActorMovementCapabilityDecision = capability.evaluate(
        "actor_cap",
        &"movement.step_forward",
        10
    )
    _check(adjusted.is_allowed() and adjusted.duration_ticks == 13, "provider adjustments add deterministically")

    var unknown_provider := TestProviderClass.new(
        "unknown_provider",
        ProviderClass.Status.UNKNOWN,
        0,
        "needs_unknown"
    )
    _check(capability.register_provider(unknown_provider), "unknown provider registered")
    var unknown: ActorMovementCapabilityDecision = capability.evaluate(
        "actor_cap",
        &"movement.step_forward",
        10
    )
    _check(
        unknown.status == CapabilityDecision.Status.CAPABILITY_UNKNOWN and unknown.reason == "needs_unknown",
        "unknown provider fails capability closed"
    )

    var blocker := TestProviderClass.new(
        "block_provider",
        ProviderClass.Status.BLOCKED,
        0,
        "leg_cannot_move"
    )
    _check(capability.register_provider(blocker), "blocking provider registered")
    var blocked: ActorMovementCapabilityDecision = capability.evaluate(
        "actor_cap",
        &"movement.step_forward",
        10
    )
    _check(
        blocked.status == CapabilityDecision.Status.CAPABILITY_BLOCKED and blocked.reason == "leg_cannot_move",
        "explicit block outranks unknown provider"
    )

    var invalid_capability := CapabilityClass.new(state)
    var cancel_scale := TestProviderClass.new(
        "cancel_scale",
        ProviderClass.Status.ALLOWED,
        -10000
    )
    _check(invalid_capability.register_provider(cancel_scale), "negative scale provider registered")
    var invalid: ActorMovementCapabilityDecision = invalid_capability.evaluate(
        "actor_cap",
        &"movement.step_forward",
        10
    )
    _check(invalid.status == CapabilityDecision.Status.INVALID_DURATION, "non-positive combined scale rejected")

func _test_timed_stance_actions() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var state: ActorLocomotionState = fixture["locomotion"]
    var kernel: TickKernel = fixture["kernel"]
    var stance_actions: ActorStanceActionService = fixture["stance_actions"]
    _place_actor(fixture, "actor_stance", Vector2i(3, 3))

    var original_anchor: Vector2i = world.placement("actor_stance").anchor
    var crouch: ActorStanceActionResult = stance_actions.request_crouch("actor_stance")
    _check(crouch.is_accepted() and crouch.duration_ticks == 4, "crouch is a four-tick committed action")
    _check(state.stance("actor_stance") == StanceRules.STANDING, "crouch does not mutate state at request time")

    _check(kernel.schedule_event(2, "actor_locomotion_smoke", &"test.stance_mid") > 0, "stance midpoint scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "stance reaches midpoint")
    _check(kernel.world_tick() == 2, "stance midpoint advances two ticks")
    _check(state.stance("actor_stance") == StanceRules.STANDING, "stance remains standing before commit")

    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "crouch action drains")
    _check(kernel.world_tick() == 4, "crouch commits at final tick")
    _check(state.stance("actor_stance") == StanceRules.CROUCHED, "crouch commits locomotion state")
    _check(state.version("actor_stance") == 2, "crouch commit advances actor locomotion version")
    _check(world.placement("actor_stance").anchor == original_anchor, "crouch never changes WHAT footprint/anchor")

    var no_change: ActorStanceActionResult = stance_actions.request_crouch("actor_stance")
    _check(no_change.status == StanceResult.Status.NO_CHANGE, "same stance request is explicit no-change")
    _check(kernel.world_tick() == 4 and not kernel.has_active_action("actor_stance"), "no-change consumes zero ticks")

    var stand: ActorStanceActionResult = stance_actions.request_stand("actor_stance")
    _check(stand.is_accepted(), "stand request accepted")
    kernel.set_hard_paused(true)
    _check(kernel.run_until_stop() == TickRules.RunStopReason.HARD_PAUSED, "hard pause freezes stance action")
    _check(kernel.world_tick() == 4 and state.stance("actor_stance") == StanceRules.CROUCHED, "hard pause advances zero stance time")
    kernel.set_hard_paused(false)
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "stance resumes after hard pause")
    _check(kernel.world_tick() == 8 and state.stance("actor_stance") == StanceRules.STANDING, "stand commits after resume")

    var stale_failures: Array[String] = []
    stance_actions.stance_failed.connect(
        func(_actor_id, _serial, _target, reason): stale_failures.append(String(reason))
    )
    var stale: ActorStanceActionResult = stance_actions.request_crouch("actor_stance")
    _check(stale.is_accepted(), "stale stance test action accepted")
    _check(kernel.schedule_event(10, "actor_locomotion_smoke", &"test.stance_stale") > 0, "stale midpoint scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "stale stance reaches midpoint")
    var locomotion_mutations: ActorLocomotionMutationService = fixture["locomotion_mutations"]
    _check(
        locomotion_mutations.set_stance("actor_stance", StanceRules.CROUCHED),
        "external approved-domain mutation changes stance during pending action"
    )
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "stale stance action resolves")
    _check(state.stance("actor_stance") == StanceRules.CROUCHED, "stale action never overwrites newer stance")
    _check("locomotion_state_changed" in stale_failures, "stale stance action reports version mismatch")

func _test_stance_failure_edges() -> void:
    var fixture: Dictionary = _fixture()
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var locomotion_mutations: ActorLocomotionMutationService = fixture["locomotion_mutations"]
    var state: ActorLocomotionState = fixture["locomotion"]
    var kernel: TickKernel = fixture["kernel"]
    var stance_actions: ActorStanceActionService = fixture["stance_actions"]

    _place_actor(fixture, "actor_unclassified", Vector2i(5, 5), Facing.Value.EAST, false)
    var unclassified: ActorStanceActionResult = stance_actions.request_crouch("actor_unclassified")
    _check(unclassified.status == StanceResult.Status.ACTOR_UNCLASSIFIED, "stance action requires explicit locomotion record")

    _check(locomotion_mutations.enroll("actor_unclassified"), "late locomotion enrollment succeeds")
    _check(world_mutations.unplace_entity("actor_unclassified"), "actor unplaced while locomotion persists")
    _check(state.has_actor("actor_unclassified"), "locomotion record persists while unplaced")
    var unplaced: ActorStanceActionResult = stance_actions.request_crouch("actor_unclassified")
    _check(unplaced.status == StanceResult.Status.ACTOR_UNPLACED, "tactical stance action rejects unplaced actor")

    _place_actor(fixture, "actor_removed", Vector2i(7, 5))
    var failures: Array[String] = []
    stance_actions.stance_failed.connect(
        func(actor_id, _serial, _target, reason):
            if String(actor_id) == "actor_removed":
                failures.append(String(reason))
    )
    var pending: ActorStanceActionResult = stance_actions.request_crouch("actor_removed")
    _check(pending.is_accepted(), "removed-during-stance action starts")
    _check(kernel.schedule_event(2, "actor_locomotion_smoke", &"test.remove_actor") > 0, "actor-removal midpoint scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "actor-removal reaches midpoint")
    _check(world_mutations.remove_entity("actor_removed"), "WHAT actor removed during stance action")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "removed actor stance action resolves")
    _check("actor_missing" in failures, "removed actor fails stance commit")
    _check(state.has_actor("actor_removed"), "actor-domain cleanup remains explicit after WHAT removal")

func _test_actor_aware_movement() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var state: ActorLocomotionState = fixture["locomotion"]
    var locomotion_mutations: ActorLocomotionMutationService = fixture["locomotion_mutations"]
    var kernel: TickKernel = fixture["kernel"]
    var movement: MovementActionService = fixture["movement"]

    _place_actor(fixture, "actor_move_unknown", Vector2i(2, 10), Facing.Value.EAST, false)
    var unknown: MovementActionResult = movement.request_step_forward("actor_move_unknown")
    _check(
        unknown.status == MovementResult.Status.ACTOR_UNCLASSIFIED,
        "actor-aware movement distinguishes missing locomotion state from terrain"
    )

    _check(locomotion_mutations.enroll("actor_move_unknown"), "movement actor locomotion enrolled")
    var standing_step: MovementActionResult = movement.request_step_forward("actor_move_unknown")
    _check(standing_step.is_accepted() and standing_step.duration_ticks == 10, "standing actor uses base terrain duration")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "standing movement drains")
    _check(world.placement("actor_move_unknown").anchor == Vector2i(3, 10), "standing movement commits")

    _check(
        locomotion_mutations.set_stance("actor_move_unknown", StanceRules.CROUCHED),
        "movement actor crouched directly between actions"
    )
    var crouched_step: MovementActionResult = movement.request_step_forward("actor_move_unknown")
    _check(crouched_step.is_accepted() and crouched_step.duration_ticks == 14, "crouched movement is 1.4x base terrain duration")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "crouched movement drains")
    _check(world.placement("actor_move_unknown").anchor == Vector2i(4, 10), "crouched movement commits")

    var crouched_turn: MovementActionResult = movement.request_turn_left("actor_move_unknown")
    _check(crouched_turn.is_accepted() and crouched_turn.duration_ticks == 3, "crouched turn keeps normal base turn duration")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "crouched turn drains")
    _check(world.placement("actor_move_unknown").facing == Facing.Value.NORTH, "crouched turn commits facing")
    _check(state.stance("actor_move_unknown") == StanceRules.CROUCHED, "movement never owns stance state")

func _test_commit_time_capability_revalidation() -> void:
    var fixture: Dictionary = _fixture()
    var world: WorldState = fixture["world"]
    var kernel: TickKernel = fixture["kernel"]
    var capability: ActorMovementCapabilityService = fixture["capability"]
    var movement: MovementActionService = fixture["movement"]
    _place_actor(fixture, "actor_revalidate", Vector2i(10, 10), Facing.Value.EAST)

    var mutable_provider := TestProviderClass.new("mutable_condition", ProviderClass.Status.ALLOWED, 0)
    _check(capability.register_provider(mutable_provider), "mutable condition provider registered")

    var failures: Array[String] = []
    movement.movement_failed.connect(
        func(actor_id, _serial, _type, reason):
            if String(actor_id) == "actor_revalidate":
                failures.append(String(reason))
    )

    var blocked_later: MovementActionResult = movement.request_step_forward("actor_revalidate")
    _check(blocked_later.is_accepted() and blocked_later.duration_ticks == 10, "movement accepted while capability allows")
    _check(kernel.schedule_event(5, "actor_locomotion_smoke", &"test.capability_block") > 0, "capability midpoint scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "capability test reaches midpoint")
    mutable_provider.set_result(ProviderClass.Status.BLOCKED, 0, "leg_failure")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "blocked-at-commit movement resolves")
    _check(kernel.world_tick() == 10, "capability failure still spends committed movement duration")
    _check(world.placement("actor_revalidate").anchor == Vector2i(10, 10), "capability block prevents WHAT movement commit")
    _check("leg_failure" in failures, "commit-time capability block reports provider reason")

    mutable_provider.set_result(ProviderClass.Status.ALLOWED, 0)
    var duration_fixed: MovementActionResult = movement.request_step_forward("actor_revalidate")
    _check(duration_fixed.is_accepted() and duration_fixed.duration_ticks == 10, "second movement starts at original duration")
    _check(kernel.schedule_event(15, "actor_locomotion_smoke", &"test.capability_slow") > 0, "slowdown midpoint scheduled")
    _check(kernel.run_next_batch() == TickRules.RunStopReason.BATCH_COMPLETE, "slowdown test reaches midpoint")
    mutable_provider.set_result(ProviderClass.Status.ALLOWED, 5000)
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "mid-action slowdown still allows current commit")
    _check(kernel.world_tick() == 20, "already scheduled action is not stretched mid-flight")
    _check(world.placement("actor_revalidate").anchor == Vector2i(11, 10), "allowed slowdown does not cancel current action")

    var next_move: MovementActionResult = movement.request_step_forward("actor_revalidate")
    _check(next_move.is_accepted() and next_move.duration_ticks == 15, "new slowdown applies to next movement action")
    _check(kernel.run_until_stop() == TickRules.RunStopReason.IDLE, "slowed next action drains")
    _check(kernel.world_tick() == 35, "next action uses updated 1.5x capability duration")

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
