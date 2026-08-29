extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const CollisionOverridesClass = preload("res://scripts/simulation/collision/CollisionOverrideState.gd")
const SpatialQueryClass = preload("res://scripts/simulation/collision/SpatialQueryService.gd")
const BaseTraversalClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const MovementClass = preload("res://scripts/simulation/movement/MovementActionService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const LocomotionStateClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionState.gd")
const LocomotionMutationClass = preload("res://scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd")
const CapabilityClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd")
const ActorTraversalClass = preload("res://scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd")
const StanceActionClass = preload("res://scripts/simulation/actors/locomotion/ActorStanceActionService.gd")
const Stance = preload("res://scripts/simulation/actors/locomotion/ActorStance.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const NeedsClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const SkillsClass = preload("res://scripts/simulation/actors/skills/ActorSkillState.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const MoodletClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodletService.gd")
const StatusSummaryClass = preload("res://scripts/ui/ActorStatusSummaryQuery.gd")
const StatsQueryClass = preload("res://scripts/ui/ActorStatsInspectorQuery.gd")
const InventoryQueryClass = preload("res://scripts/ui/ActorInventoryInspectorQuery.gd")
const ShellClass = preload("res://scripts/ui/CanonicalPlayerShell.gd")
const ControlsClass = preload("res://scripts/ui/PlayerMovementControls.gd")
const KeyboardClass = preload("res://scripts/input/KeyboardInputAdapter.gd")
const ControllerClass = preload("res://scripts/player/PlayerActionController.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")
const FixtureClass = preload("res://scripts/demo/CanonicalDemoFixture.gd")

var failures: Array[String] = []
var resolved_events: Array[Dictionary] = []
var touch_intents: Array[StringName] = []
var blocked_events: Array[bool] = []
var _keyboard: KeyboardInputAdapter = null
var _controls: PlayerMovementControls = null

func _initialize() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var collision_overrides := CollisionOverridesClass.new()
    var base_traversal := BaseTraversalClass.new()
    _check(FixtureClass.build(world, mutations, collision_catalog, base_traversal), "canonical fixture builds")

    var locomotion := LocomotionStateClass.new()
    var locomotion_mutations := LocomotionMutationClass.new(locomotion)
    _check(locomotion_mutations.enroll(FixtureClass.PLAYER_ID), "player locomotion enrollment succeeds")
    var capability := CapabilityClass.new(locomotion)
    var actor_traversal := ActorTraversalClass.new(base_traversal, capability)
    var spatial_query := SpatialQueryClass.new(world, collision_catalog, collision_overrides)
    var kernel := TickKernelClass.new(FixtureClass.PLAYER_ID)
    var movement := MovementClass.new(world, mutations, spatial_query, kernel, actor_traversal)
    var stance_actions := StanceActionClass.new(world, locomotion, locomotion_mutations, kernel, capability)
    _check(movement.is_ready(), "movement remains ready")
    _check(stance_actions.is_ready(), "existing stance action service ready")

    _controls = ControlsClass.new()
    get_root().add_child(_controls)
    _check(_controls.configure_stance(locomotion, FixtureClass.PLAYER_ID), "touch controls observe canonical stance")
    _controls.action_intent.connect(_on_touch_intent)
    _check(_controls.stance_button_text() == "CROUCH", "standing actor presents CROUCH touch label")
    _press_button_named(_controls, "CROUCH")
    _check(touch_intents == [Intents.STANCE_TOGGLE], "one touch stance press emits exactly one semantic toggle")

    _keyboard = KeyboardClass.new()
    get_root().add_child(_keyboard)
    var c_event := InputEventKey.new()
    c_event.keycode = KEY_C
    _check(KeyboardClass._intent_for_key(c_event) == Intents.STANCE_TOGGLE, "C key maps to stance toggle")

    var controller := ControllerClass.new(movement, kernel, FixtureClass.PLAYER_ID, stance_actions, locomotion)
    controller.action_resolved.connect(_on_action_resolved)
    _check(controller.is_ready() and controller.stance_ready(), "player controller coordinates movement and stance owners")

    controller.submit_intent(Intents.STANCE_TOGGLE)
    _check(locomotion.stance(FixtureClass.PLAYER_ID) == Stance.CROUCHED, "stance toggle commits real crouched state")
    _check(kernel.world_tick() == 4, "standing to crouched spends existing 4 stance ticks")
    _check(_controls.stance_button_text() == "STAND", "touch label observes committed crouched state")
    _check(_last_resolution_success(), "crouch action resolves success")

    controller.submit_intent(Intents.FORWARD)
    var after_crouched_walk: WorldPlacement = world.placement(FixtureClass.PLAYER_ID)
    _check(after_crouched_walk != null and after_crouched_walk.anchor == Vector2i(6, 9), "crouched forward movement commits through Movement")
    _check(kernel.world_tick() == 18, "crouched forward step uses existing 14-tick duration")

    controller.submit_intent(Intents.STANCE_TOGGLE)
    _check(locomotion.stance(FixtureClass.PLAYER_ID) == Stance.STANDING, "second stance toggle commits real standing state")
    _check(kernel.world_tick() == 22, "crouched to standing spends existing 4 stance ticks")
    _check(_controls.stance_button_text() == "CROUCH", "touch label returns to CROUCH from real state")

    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    _check(hand_mutations.enroll_actor(FixtureClass.PLAYER_ID), "hands enroll")
    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    _check(inventory_mutations.enroll_container(FixtureClass.PLAYER_ID), "root inventory enrolls")
    var health := HealthClass.new(world)
    _check(health.enroll_actor(FixtureClass.PLAYER_ID), "health enrolls")
    var needs := NeedsClass.new(world)
    _check(needs.enroll_actor(FixtureClass.PLAYER_ID), "needs enroll")
    var skills := SkillsClass.new(world)
    _check(skills.enroll_actor(FixtureClass.PLAYER_ID), "skills enroll")
    var physical_catalog := PhysicalCatalogClass.new()
    var weight_query := WeightQueryClass.new(world, physical_catalog)
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(FixtureClass.PLAYER_ID), "carry enrolls")
    var carry_query := CarryQueryClass.new(world, hands, inventory, weight_query, carry_state)
    var moodlets := MoodletClass.new(health, needs, carry_query)
    var summary := StatusSummaryClass.new(health, needs, carry_query, moodlets)
    var stats_query := StatsQueryClass.new(summary, health, skills, locomotion)
    var inventory_query := InventoryQueryClass.new(world, hands, inventory, weight_query, carry_query)

    _check_stats_query(stats_query)
    _check_inventory_query(inventory_query)
    _check_shell(kernel, stats_query, inventory_query)
    _check_nested_inventory(world, mutations, inventory, inventory_mutations, inventory_query)

    _controls.queue_free()
    _keyboard.queue_free()

    if failures.is_empty():
        print("CANONICAL_PLAYER_SHELL_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("CANONICAL_PLAYER_SHELL_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check_stats_query(stats_query: ActorStatsInspectorQuery) -> void:
    var result: Dictionary = stats_query.query(FixtureClass.PLAYER_ID)
    _check(bool(result.get("ok", false)), "stats query returns known real state")
    _check(String(result.get("stance_label", "")) == "Standing", "stats reads standing stance")
    var status: Dictionary = result.get("status", {})
    _check(int(status.get("current_hp", -1)) == 100 and int(status.get("max_hp", -1)) == 100, "stats reads real 100/100 HP")
    _check(int(status.get("fatigue", -1)) == 0, "stats reads real fatigue")
    _check(int(status.get("hunger", -1)) == 0, "stats reads real hunger")
    _check(int(status.get("thirst", -1)) == 0, "stats reads real thirst")
    _check(int(status.get("sleep_pressure", -1)) == 0, "stats reads real sleep pressure")
    _check(int(status.get("carry_weight_grams", -1)) == 0 and int(status.get("carry_capacity_grams", -1)) == 18000, "stats reads real derived carry")
    _check((result.get("injuries", []) as Array).is_empty(), "stats reports no real injuries as empty")
    var skills: Array = result.get("skills", [])
    _check(skills.size() == 6, "stats dynamically enumerates all six canonical skills")
    for skill_value: Variant in skills:
        var skill: Dictionary = skill_value
        _check(int(skill.get("level", -1)) == 0 and int(skill.get("xp", -1)) == 0, "demo skill defaults are honest level-0 XP-0 records")

func _check_inventory_query(inventory_query: ActorInventoryInspectorQuery) -> void:
    var result: Dictionary = inventory_query.query(FixtureClass.PLAYER_ID)
    _check(bool(result.get("ok", false)), "inventory query returns known real state")
    _check(bool((result.get("primary_hand", {}) as Dictionary).get("empty", false)), "right hand is honestly empty")
    _check(bool((result.get("secondary_hand", {}) as Dictionary).get("empty", false)), "left hand is honestly empty")
    _check((result.get("inventory", []) as Array).is_empty(), "root inventory is honestly empty")
    var carry: Dictionary = result.get("carry", {})
    _check(String(carry.get("reason", "x")).is_empty(), "empty inventory carry result is known")
    _check(int(carry.get("weight_grams", -1)) == 0 and int(carry.get("capacity_grams", -1)) == 18000, "inventory reports real 0/18 kg carry")

func _check_shell(kernel: TickKernel, stats_query: ActorStatsInspectorQuery, inventory_query: ActorInventoryInspectorQuery) -> void:
    var shell := ShellClass.new()
    get_root().add_child(shell)
    _check(shell.configure(kernel, stats_query, inventory_query, FixtureClass.PLAYER_ID), "player shell configures")
    shell.interaction_blocked_changed.connect(_on_shell_blocked)

    shell.open_stats()
    _check(kernel.is_hard_paused(), "Stats acquires hard pause")
    _check(shell.active_modal() == ShellClass.MODAL_STATS, "Stats modal becomes active")
    _check(not _keyboard.is_enabled() and not _controls.is_enabled(), "modal blocks keyboard and touch gameplay input")
    var stats_snapshot: Dictionary = shell.presentation_snapshot()
    _check(_lines_contain(stats_snapshot, "Combat — Level 0"), "Stats presentation includes real skill level/XP")
    _check(not _lines_contain(stats_snapshot, "Stress"), "Stats does not fabricate stress")
    _check(not _lines_contain(stats_snapshot, "Traits"), "Stats does not fabricate traits")

    shell.open_inventory()
    _check(kernel.is_hard_paused(), "switching modal retains hard pause")
    _check(blocked_events == [true], "switching modal does not recapture input block state")
    var inventory_snapshot: Dictionary = shell.presentation_snapshot()
    _check(_lines_contain(inventory_snapshot, "Right Hand: Empty"), "Inventory presentation shows empty right hand")
    _check(_lines_contain(inventory_snapshot, "Left Hand: Empty"), "Inventory presentation shows empty left hand")
    _check(_lines_contain(inventory_snapshot, "Empty"), "Inventory presentation says Empty instead of inventing gear")

    shell.close_modal()
    _check(not kernel.is_hard_paused(), "closing shell restores previously unpaused state")
    _check(_keyboard.is_enabled() and _controls.is_enabled(), "closing shell restores gameplay input")
    _check(blocked_events == [true, false], "shell emits one block and one unblock for modal lifetime")

    kernel.set_hard_paused(true)
    shell.open_menu()
    _check(kernel.is_hard_paused(), "Menu remains hard paused")
    _check(_tree_has_button(shell, "RESUME"), "Menu exposes Resume")
    _check(_tree_has_button(shell, "LEAVE GAME"), "Menu exposes Leave Game")
    shell.close_modal()
    _check(kernel.is_hard_paused(), "closing Menu restores pre-existing hard pause")
    kernel.set_hard_paused(false)
    shell.queue_free()

func _check_nested_inventory(
    world: WorldState,
    mutations: WorldMutationService,
    inventory: InventoryContainmentState,
    inventory_mutations: InventoryContainmentMutationService,
    inventory_query: ActorInventoryInspectorQuery
) -> void:
    var bag_id: String = mutations.create_entity(&"item.test_bag", "test_bag")
    var tool_id: String = mutations.create_entity(&"item.mystery_tool", "mystery_tool")
    _check(not bag_id.is_empty() and not tool_id.is_empty(), "synthetic stable test items created")
    _check(inventory_mutations.enroll_container(bag_id), "synthetic bag enrolled as container")
    _check(inventory_mutations.set_container(bag_id, FixtureClass.PLAYER_ID), "bag enters actor-root containment")
    _check(inventory_mutations.set_container(tool_id, bag_id), "tool enters nested bag containment")
    _check(inventory.contains_directly(FixtureClass.PLAYER_ID, bag_id), "root relation remains canonical")
    _check(inventory.contains_directly(bag_id, tool_id), "nested relation remains canonical")

    var result: Dictionary = inventory_query.query(FixtureClass.PLAYER_ID)
    var roots: Array = result.get("inventory", [])
    _check(roots.size() == 1, "inventory query preserves one stable root item")
    if roots.size() == 1:
        var bag: Dictionary = roots[0]
        _check(String(bag.get("item_id", "")) == bag_id, "root item stable ID preserved")
        _check(not bool(bag.get("weight_known", true)), "unclassified bag weight is explicit unknown")
        var children: Array = bag.get("children", [])
        _check(children.size() == 1, "nested containment is recursively exposed")
        if children.size() == 1:
            var tool: Dictionary = children[0]
            _check(String(tool.get("item_id", "")) == tool_id, "nested item stable ID preserved")
            _check(not bool(tool.get("weight_known", true)), "nested missing weight remains explicit unknown")

func _press_button_named(root: Node, text_value: String) -> void:
    for child: Node in root.get_children():
        var button := child as Button
        if button != null and button.text == text_value:
            button.pressed.emit()
            return

func _tree_has_button(root: Node, text_value: String) -> bool:
    var button := root as Button
    if button != null and button.text == text_value:
        return true
    for child: Node in root.get_children():
        if _tree_has_button(child, text_value):
            return true
    return false

func _lines_contain(snapshot: Dictionary, needle: String) -> bool:
    for value: Variant in snapshot.get("lines", []):
        if String(value).contains(needle):
            return true
    return false

func _on_action_resolved(intent: StringName, success: bool, reason: String, world_tick: int) -> void:
    resolved_events.append({
        "intent": intent,
        "success": success,
        "reason": reason,
        "world_tick": world_tick,
    })

func _last_resolution_success() -> bool:
    if resolved_events.is_empty():
        return false
    return bool(resolved_events[-1].get("success", false))

func _on_touch_intent(intent: StringName) -> void:
    touch_intents.append(intent)

func _on_shell_blocked(blocked: bool) -> void:
    blocked_events.append(blocked)
    _keyboard.set_enabled(not blocked)
    _controls.set_enabled(not blocked)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
