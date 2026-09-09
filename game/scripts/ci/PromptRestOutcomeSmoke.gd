extends SceneTree

# Affordance discovery is outside this test; exercise the production request/resolution path.
class ReadyController extends WorldInteractionPlayerController:
    func is_ready() -> bool:
        return true

var failures: Array[String] = []
var received: Dictionary = {}
var target_available: bool = true
func _initialize() -> void:
    call_deferred("_run")
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)
func _surface(_actor: String, target: String) -> StringName:
    if not target_available:
        return &""
    return &"bed" if target == "bed" else &"chair"
func _run() -> void:
    var world := WorldState.new()
    var mutations := WorldMutationService.new(world)
    var actor := mutations.create_entity(&"actor.survivor", "actor.test")
    var kernel := TickKernel.new()
    var time := WorldTimeProfile.new()
    var state := ActorConditionState.new(world)
    var health := ActorHealthState.new(world)
    check(state.enroll_actor(actor, 0) and health.enroll_actor(actor), "Actor setup")
    var condition := ActorConditionService.new(state, health, kernel, time, ActorConditionModifierQuery.new(state, time, kernel))
    var hands := ActorHandEquipmentState.new()
    var hand_mutations := ActorHandEquipmentMutationService.new(hands, world)
    var inventory := InventoryContainmentState.new()
    var inventory_mutations := InventoryContainmentMutationService.new(inventory, world)
    check(hand_mutations.enroll_actor(actor) and inventory_mutations.enroll_container(actor), "Inventory setup")
    var freshness_state := ItemFreshnessState.new()
    var freshness_profiles := ItemFreshnessProfileCatalog.new()
    var actions := SurvivorSustainmentActionService.new(world, mutations, hands, hand_mutations, inventory, inventory_mutations, ItemFreshnessQuery.new(world, freshness_state, freshness_profiles, kernel), ItemFreshnessMutationService.new(world, freshness_state, freshness_profiles), ActorCarryQuery.new(), kernel, time, condition, SurvivorSustainmentProfileCatalog.new())
    check(actions.is_ready(), "Service ready")
    actions.set_rest_target_provider(_surface)
    var main := VehicleGameMain.new()
    main._sustainment_actions = actions
    var controller := ReadyController.new()
    controller._kernel = kernel
    controller._actor_id = actor
    controller.action_finished.connect(func(_target: String, _action: StringName, success: bool, reason: String) -> void:
        received = {"success": success, "reason": reason}
    )
    for action_id: StringName in [SustainmentInteractionOfferProvider.REST_ON_FURNITURE, SustainmentInteractionOfferProvider.SLEEP_IN_BED]:
        controller.register_handler(action_id, main._request_target_sustainment)
        var target := "bed" if action_id == SustainmentInteractionOfferProvider.SLEEP_IN_BED else "chair"
        target_available = true
        condition.set_condition(actor, ActorConditionState.REST, 10)
        controller._on_action_requested(target, action_id)
        check(received.get("success", false), "Valid furniture recovery reports success")
        check(condition.value(actor, ActorConditionState.REST) > 10, "Actual rest recovery committed")
        target_available = true
        condition.set_condition(actor, ActorConditionState.REST, 10)
        kernel.action_started.connect(func(_action: TimedAction) -> void: target_available = false, CONNECT_ONE_SHOT)
        controller._on_action_requested(target, action_id)
        check(not received.get("success", true) and received.get("reason") == "rest_target_no_longer_available", "Lost furniture must report failure, not timer completion")
        check(condition.value(actor, ActorConditionState.REST) <= 10, "Lost furniture grants no recovery")
    target_available = true
    var serial := actions.begin_sleep_in(actor, "bed")
    check(serial > 0 and kernel.cancel_action(serial, "test_cancel"), "Sleep cancellation")
    var outcome := actions.rest_outcome(serial)
    check(not outcome.get("committed", true) and outcome.get("reason") == "test_cancel", "Canceled sleep outcome")
    outcome["committed"] = true
    check(not actions.rest_outcome(serial).get("committed", true), "Rest outcome copy protection")
    main.free()
    if failures.is_empty():
        print("PROMPT_REST_OUTCOME_SMOKE: PASS")
    quit(0 if failures.is_empty() else 1)
