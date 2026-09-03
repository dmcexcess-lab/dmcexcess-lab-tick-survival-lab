extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const SkillCatalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")

var failures: Array[String] = []
var world := WorldState.new()
var world_mut := WorldMutationService.new(world)
var hands := ActorHandEquipmentState.new()
var hand_mut := ActorHandEquipmentMutationService.new(hands, world)
var inventory := InventoryContainmentState.new()
var inventory_mut := InventoryContainmentMutationService.new(inventory, world)
var physical := ItemPhysicalPropertyCatalog.new()
var loot_items := LootItemCatalog.new()
var crafted_items := CraftingItemCatalog.new()
var carry_state := ActorCarryState.new(world)
var weight_query := ItemWeightQuery.new(world, physical)
var carry_query := ActorCarryQuery.new(world, hands, inventory, weight_query, carry_state)
var recipes := CraftingRecipeCatalog.new()
var workstations := CraftingWorkstationCatalog.new()
var time_profile := WorldTimeProfile.new()
var freshness := ItemFreshnessProfileCatalog.new(time_profile)
var reach := WorldInteractionReachQuery.new(world)
var kernel := TickKernel.new("actor.crafter")
var skills: ActorSkillState
var skill_checks: ActorSkillCheckService
var plans: CraftingPlanQuery
var crafting: CraftingActionService

const ACTOR: String = "actor.crafter"
const WORKBENCH: String = "fixture.crafting.workbench"
const SCISSORS: String = "item.tool.scissors.test"

func _initialize() -> void:
    _setup()
    _test_catalog_contract()
    _test_personal_possession_and_determinism()
    _test_timed_transform_and_tool_preservation()
    _test_cancellation_and_compensation()
    _test_workstation_and_multistage_chain()
    if failures.is_empty():
        print("CRAFTING_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("CRAFTING_SMOKE_FAIL: %s" % failure)
    quit(1)

func _setup() -> void:
    _check(loot_items.register_physical_profiles(physical), "loot weights register before crafting")
    _check(crafted_items.register_physical_profiles(physical), "crafted output weights register through System 13D")
    _check(world_mut.create_entity(&"actor.survivor", ACTOR) == ACTOR, "crafter WHAT entity created")
    _check(world_mut.set_placement(ACTOR, Layers.Channel.ACTOR, Vector2i(5, 5), Facing.Value.NORTH, Footprint.single_cell()), "crafter placed")
    _check(hand_mut.enroll_actor(ACTOR), "crafter hand state enrolled")
    _check(inventory_mut.enroll_container(ACTOR), "crafter root inventory enrolled")
    _check(carry_state.enroll_actor(ACTOR), "crafter carry state enrolled")
    skills = ActorSkillState.new(world)
    _check(skills.enroll_actor(ACTOR), "crafter skill state enrolled")
    _check(skills.set_skill(ACTOR, SkillCatalog.SURVIVAL, 10, 0), "crafting fixture has expert Survival")
    _check(skills.set_skill(ACTOR, SkillCatalog.MECHANICAL, 10, 0), "crafting fixture has expert Mechanical")
    skill_checks = ActorSkillCheckService.new(skills)
    plans = CraftingPlanQuery.new(world, hands, inventory, carry_query, physical, recipes, crafted_items, workstations, freshness, reach)
    crafting = CraftingActionService.new(world, world_mut, hands, hand_mut, inventory, inventory_mut, kernel, recipes, plans, skill_checks)
    _check(skill_checks.is_ready() and plans.is_ready() and crafting.is_ready(), "skill-aware crafting planner and action service are ready")

func _test_catalog_contract() -> void:
    _check(recipes.catalog_version() == 2 and recipes.recipe_ids().size() == 5, "Candidate 001 v2 exposes five bounded skill-aware recipes")
    _check(crafted_items.semantic_types().size() == 5, "five crafting-owned output semantics exist")
    for semantic: StringName in crafted_items.semantic_types():
        _check(physical.has_profile(semantic) and physical.weight_grams(semantic) > 0, "crafted item has real positive weight: %s" % String(semantic))
        _check(not freshness.has_profile(semantic), "crafted Candidate-001 output is not silently perishable: %s" % String(semantic))
    for recipe_id: StringName in recipes.recipe_ids():
        var recipe_value: CraftingRecipe = recipes.recipe(recipe_id)
        _check(recipe_value != null and recipe_value.is_valid(), "recipe validates: %s" % String(recipe_id))
        _check(SkillCatalog.is_valid(recipe_value.skill_id) and SkillCatalog.is_valid_difficulty(recipe_value.skill_difficulty), "recipe names one canonical skill check: %s" % String(recipe_id))
        _check(not recipe_value.required_tools.is_empty(), "recipe requires at least one concrete physical tool: %s" % String(recipe_id))
        for requirement: Dictionary in recipe_value.consumed_inputs:
            _check(not freshness.has_profile(StringName(requirement.get("semantic_type", &""))), "recipe does not consume perishable input: %s" % String(recipe_id))

func _test_personal_possession_and_determinism() -> void:
    _add_carried(&"item.junk.stale_newspaper", "item.paper.news.b")
    _add_carried(&"item.junk.stale_newspaper", "item.paper.news.a")
    _add_loose(&"item.junk.worn_cardboard", "item.paper.cardboard", Vector2i(5, 5))
    var blocked: Dictionary = plans.query(ACTOR, &"crafting.paper_bundle")
    _check(not bool(blocked.get("ready", false)) and String(blocked.get("reason", "")).begins_with("missing_input"), "floor ingredient is not auto-pulled into crafting")
    _check(world_mut.unplace_entity("item.paper.cardboard") and inventory_mut.set_container("item.paper.cardboard", ACTOR), "test cardboard explicitly becomes personal possession")
    var missing_tool: Dictionary = plans.query(ACTOR, &"crafting.paper_bundle")
    _check(not bool(missing_tool.get("ready", false)) and String(missing_tool.get("reason", "")).begins_with("missing_tool"), "skill never substitutes for missing physical scissors")
    _add_carried(&"item.office.scissors", SCISSORS)
    var ready: Dictionary = plans.query(ACTOR, &"crafting.paper_bundle")
    _check(bool(ready.get("ready", false)), "Survival recipe becomes ready only with personal materials and tool")
    var consumed: Array = ready.get("consumed_item_ids", [])
    _check(consumed.has("item.paper.news.a") and not consumed.has("item.paper.news.b"), "exact ingredient selection is stable-ID deterministic")
    _check(ready.get("tool_item_ids", []).has(SCISSORS), "exact scissors identity is carried into the physical plan")

func _test_timed_transform_and_tool_preservation() -> void:
    var expected_profile: Dictionary = skill_checks.action_profile(ACTOR, SkillCatalog.SURVIVAL, recipes.recipe(&"crafting.paper_bundle").duration_ticks, 1)
    var paper_request: Dictionary = crafting.request_craft(ACTOR, &"crafting.paper_bundle")
    _check(bool(paper_request.get("accepted", false)), "paper craft request accepted")
    _check(int(paper_request.get("duration_ticks", 0)) == int(expected_profile.get("duration_ticks", -1)), "craft request exposes skill-adjusted WHEN duration")
    var paper_start: int = kernel.world_tick()
    kernel.run_until_stop()
    _check(kernel.world_tick() - paper_start == int(expected_profile.get("duration_ticks", -1)), "paper craft spends skill-adjusted WHEN duration")
    _check(_find_carried_semantic(&"item.crafting.paper_bundle") != "", "paper craft creates a real persistent output")
    _check(not world.has_entity("item.paper.news.a") and world.has_entity("item.paper.news.b"), "only the exact selected newspaper entity is consumed")
    _check(world.has_entity(SCISSORS) and inventory.container_of(SCISSORS) == ACTOR, "required scissors remain physical and unconsumed")

    _add_carried(&"item.junk.scrap_wire", "item.wire.scrap")
    _add_carried(&"item.junk.cracked_phone_charger", "item.wire.charger")
    var missing_tool: Dictionary = plans.query(ACTOR, &"crafting.wire_salvage_bundle")
    _check(not bool(missing_tool.get("ready", false)) and String(missing_tool.get("reason", "")).begins_with("missing_tool"), "tool requirement blocks without a real possessed tool")
    _add_carried(&"item.tool.pliers", "item.tool.pliers.test")
    var wire_plan: Dictionary = plans.query(ACTOR, &"crafting.wire_salvage_bundle")
    _check(bool(wire_plan.get("ready", false)) and wire_plan.get("tool_item_ids", []).has("item.tool.pliers.test"), "real pliers satisfy tool requirement")
    var wire_request: Dictionary = crafting.request_craft(ACTOR, &"crafting.wire_salvage_bundle")
    _check(bool(wire_request.get("accepted", false)) and wire_request.get("skill_id", &"") == SkillCatalog.MECHANICAL, "wire craft uses Mechanical competence")
    kernel.run_until_stop()
    _check(world.has_entity("item.tool.pliers.test") and inventory.container_of("item.tool.pliers.test") == ACTOR, "required tool remains physical and unconsumed")
    _check(_find_carried_semantic(&"item.crafting.wire_salvage_bundle") != "", "wire craft output enters ordinary actor-root containment")

func _test_cancellation_and_compensation() -> void:
    _add_carried(&"item.material.rag_bundle", "item.patch.rags")
    _add_carried(&"item.material.duct_tape", "item.patch.tape")
    var cancel_request: Dictionary = crafting.request_craft(ACTOR, &"crafting.patch_component_kit")
    _check(bool(cancel_request.get("accepted", false)), "cancel test craft accepted")
    _check(kernel.cancel_action(int(cancel_request.get("action_serial", 0)), "ci_cancel"), "craft is cancelable before commit")
    _check(world.has_entity("item.patch.rags") and world.has_entity("item.patch.tape"), "cancel before commit consumes nothing")
    _check(_count_carried_semantic(&"item.crafting.patch_component_kit") == 0, "cancel before commit creates no output")

    _add_carried(&"item.junk.rusted_fasteners", "item.metal.fasteners")
    _add_carried(&"item.junk.broken_screwdriver", "item.metal.broken_driver")
    _add_carried(&"item.tool.hammer", "item.tool.hammer.test")
    crafting.set_dev_failure_after_removed_inputs(1)
    var failure_request: Dictionary = crafting.request_craft(ACTOR, &"crafting.metal_scrap_bundle")
    _check(bool(failure_request.get("accepted", false)), "compensation test craft accepted")
    kernel.run_until_stop()
    _check(world.has_entity("item.metal.fasteners") and inventory.container_of("item.metal.fasteners") == ACTOR, "injected mid-commit failure restores removed input identity and containment")
    _check(world.has_entity("item.metal.broken_driver") and inventory.container_of("item.metal.broken_driver") == ACTOR, "untouched later input remains unchanged after compensation")
    _check(_count_carried_semantic(&"item.crafting.metal_scrap_bundle") == 0, "failed compensated craft leaves no output")
    var diagnostics: Array[Dictionary] = crafting.recent_diagnostics()
    _check(not diagnostics.is_empty() and String(diagnostics[-1].get("reason", "")) == "dev_injected_commit_failure", "compensated failure is explicit and noncritical")

func _test_workstation_and_multistage_chain() -> void:
    _add_carried(&"item.crafting.metal_scrap_bundle", "item.chain.metal")
    _add_carried(&"item.crafting.patch_component_kit", "item.chain.patch")
    _add_carried(&"item.material.screws_box", "item.chain.screws")
    _add_carried(&"item.tool.screwdriver", "item.tool.screwdriver.good")
    _check(world_mut.create_entity(&"prop.workbench_heavy", WORKBENCH) == WORKBENCH, "explicit workbench WHAT entity created")
    _check(world_mut.set_placement(WORKBENCH, Layers.Channel.OBJECT, Vector2i(5, 4), Facing.Value.SOUTH, Footprint.single_cell()), "workbench placed in CONTACT_FORWARD")

    var no_station: Dictionary = plans.query(ACTOR, &"crafting.improvised_toolkit")
    _check(not bool(no_station.get("ready", false)) and String(no_station.get("reason", "")) == "workstation_required", "workbench recipe does not silently use nearby station without explicit target")
    var station_plan: Dictionary = plans.query(ACTOR, &"crafting.improvised_toolkit", WORKBENCH)
    _check(bool(station_plan.get("ready", false)), "multi-stage components plus real tools and reachable workbench satisfy Mechanical toolkit recipe")

    var provider := CraftingInteractionOfferProvider.new(world, workstations, reach)
    var offers: Array[InteractionOffer] = provider.offers_for_actor(ACTOR, [WORKBENCH])
    _check(offers.size() == 1 and offers[0].action_id == CraftingInteractionOfferProvider.ACTION_ID, "explicit workbench publishes real CRAFT offer")

    _check(world_mut.set_placement(WORKBENCH, Layers.Channel.OBJECT, Vector2i(5, 6), Facing.Value.SOUTH, Footprint.single_cell()), "workbench moved behind actor")
    var out_of_reach: Dictionary = plans.query(ACTOR, &"crafting.improvised_toolkit", WORKBENCH)
    _check(not bool(out_of_reach.get("ready", false)) and String(out_of_reach.get("reason", "")) == "workstation_out_of_reach", "workstation reach is re-used from System 29")

func _add_carried(semantic_type: StringName, item_id: String) -> void:
    _check(world_mut.create_entity(semantic_type, item_id) == item_id, "created carried fixture: %s" % item_id)
    _check(inventory_mut.set_container(item_id, ACTOR), "contained carried fixture: %s" % item_id)

func _add_loose(semantic_type: StringName, item_id: String, cell: Vector2i) -> void:
    _check(world_mut.create_entity(semantic_type, item_id) == item_id, "created loose fixture: %s" % item_id)
    _check(world_mut.set_placement(item_id, Layers.Channel.LOOSE_ITEM, cell, Facing.Value.NORTH, Footprint.single_cell()), "placed loose fixture: %s" % item_id)

func _find_carried_semantic(semantic_type: StringName) -> String:
    for item_id: String in inventory.direct_contents(ACTOR):
        if not world.has_entity(item_id):
            continue
        var entity: WorldEntityRecord = world.entity(item_id)
        if entity != null and entity.semantic_type == semantic_type:
            return item_id
    return ""

func _count_carried_semantic(semantic_type: StringName) -> int:
    var count: int = 0
    for item_id: String in inventory.direct_contents(ACTOR):
        if not world.has_entity(item_id):
            continue
        var entity: WorldEntityRecord = world.entity(item_id)
        if entity != null and entity.semantic_type == semantic_type:
            count += 1
    return count

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
