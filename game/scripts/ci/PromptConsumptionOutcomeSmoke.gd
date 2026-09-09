extends SceneTree

# Only modal presentation is suppressed; consumption, clock and mechanic state are real.
class TestShell extends CanonicalPlayerShell:
    func close_modal() -> void:
        pass
    func open_inventory() -> void:
        pass

var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)
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
    var shell := TestShell.new()
    shell._kernel = kernel
    shell._actor_id = actor
    shell._inventory_actions = actions
    for semantic: StringName in [&"item.food.canned_beans", &"item.drink.water_bottle"]:
        var item := mutations.create_entity(semantic)
        check(inventory_mutations.set_container(item, actor), "Carry consumable")
        condition.set_condition(actor, ActorConditionState.SATIETY, 30)
        condition.set_condition(actor, ActorConditionState.HYDRATION, 30)
        shell._selected_inventory_item_id = item
        shell._consume_selected_inventory_item()
        check(shell._inventory_status.ends_with("complete."), "Committed consumption reports success")
        check(not world.has_entity(item) and not inventory.is_contained(item), "Consumed item removed")
        var channel: StringName = ActorConditionState.SATIETY if semantic == &"item.food.canned_beans" else ActorConditionState.HYDRATION
        check(condition.value(actor, channel) > 50, "Real condition gain applied")
    var lost := mutations.create_entity(&"item.food.canned_beans")
    check(inventory_mutations.set_container(lost, actor), "Carry lost food")
    var remove_during_action := func(_action: TimedAction) -> void:
        inventory_mutations.clear_container(lost)
        mutations.remove_entity(lost)
    kernel.action_started.connect(remove_during_action, CONNECT_ONE_SHOT)
    condition.set_condition(actor, ActorConditionState.SATIETY, 30)
    shell._selected_inventory_item_id = lost
    shell._consume_selected_inventory_item()
    check(shell._inventory_status == "Eat failed: item no longer carried.", "Disappearance must not falsely report successful eating")
    check(condition.value(actor, ActorConditionState.SATIETY) <= 30, "Failed consumption grants no nutrition")
    var canceled := mutations.create_entity(&"item.drink.water_bottle")
    inventory_mutations.set_container(canceled, actor)
    var serial := actions.begin_consume(actor, canceled)
    check(serial > 0 and kernel.cancel_action(serial, "test_cancel"), "Cancel consumption")
    var outcome := actions.consumption_outcome(serial)
    check(not outcome.get("committed", true) and outcome.get("reason") == "test_cancel", "Cancellation outcome")
    outcome["committed"] = true
    check(not actions.consumption_outcome(serial).get("committed", true), "Outcome is read-only copy")
    check(world.has_entity(canceled), "Canceled drink retained")
    shell.free()
    if failures.is_empty():
        print("PROMPT_CONSUMPTION_OUTCOME_SMOKE: PASS")
    quit(0 if failures.is_empty() else 1)
