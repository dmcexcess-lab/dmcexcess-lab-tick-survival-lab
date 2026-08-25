extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Footprint = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const LootStateClass = preload("res://scripts/simulation/loot/LootState.gd")
const LootProfilesClass = preload("res://scripts/simulation/loot/LootContainerProfileCatalog.gd")
const ReachClass = preload("res://scripts/simulation/interaction/WorldInteractionReachQuery.gd")
const OfferClass = preload("res://scripts/simulation/interaction/InteractionOffer.gd")
const QueryClass = preload("res://scripts/simulation/interaction/InteractionAffordanceQuery.gd")
const LootProviderClass = preload("res://scripts/simulation/loot/LootSearchInteractionOfferProvider.gd")
const FixedProviderClass = preload("res://scripts/ci/InteractionFixedOfferProvider.gd")
const TestPerceptionClass = preload("res://scripts/ci/InteractionTestPerception.gd")
const RendererClass = preload("res://scripts/render/InteractionHighlightRenderer.gd")
const PerceptionClass = preload("res://scripts/simulation/perception/ObserverPerceptionService.gd")

const ACTOR_ID: String = "actor.interaction.test"
const FRONT_ID: String = "object.search.front"
const BEHIND_ID: String = "object.search.behind"
const DIAGONAL_ID: String = "object.search.diagonal"
const MULTI_ID: String = "object.search.multi"
const DECORATIVE_ID: String = "object.decorative.front"
const PROFILE_ID: StringName = &"retail.grocery"

var failures: Array[String] = []

func _initialize() -> void:
    var fx: Dictionary = _fixture()
    _test_reach_geometry(fx)
    _test_provider_and_knowledge_filtering(fx)
    _test_dedup_and_presentation_zero_ticks(fx)
    _test_facing_change(fx)

    if failures.is_empty():
        print("WORLD_INTERACTION_AFFORDANCE_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("WORLD_INTERACTION_AFFORDANCE_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var containment := InventoryStateClass.new()
    var containment_mutations := InventoryMutationClass.new(containment, world)
    var loot_state := LootStateClass.new()
    var profiles := LootProfilesClass.new()
    var reach := ReachClass.new(world)
    var kernel := TickKernelClass.new(ACTOR_ID)

    _check(mutations.set_terrain_rect(Rect2i(0, 0, 12, 12), &"ground.grass"), "test terrain installed")
    _check(mutations.create_entity(&"actor.survivor", ACTOR_ID) == ACTOR_ID, "actor created")
    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(5, 5), Facing.Value.EAST, Footprint.single_cell()), "actor placed east")

    _create_object(mutations, FRONT_ID, Vector2i(6, 5), Footprint.single_cell())
    _create_object(mutations, BEHIND_ID, Vector2i(4, 5), Footprint.single_cell())
    _create_object(mutations, DIAGONAL_ID, Vector2i(6, 6), Footprint.single_cell())
    _create_object(mutations, MULTI_ID, Vector2i(7, 5), Footprint.new([Vector2i.ZERO, Vector2i(-1, 0)]))
    _create_object(mutations, DECORATIVE_ID, Vector2i(6, 5), Footprint.single_cell(), &"prop.chair")

    var searchable: Array[String] = [FRONT_ID, BEHIND_ID, DIAGONAL_ID, MULTI_ID]
    for container_id: String in searchable:
        _check(containment_mutations.enroll_container(container_id), "container enrolled: %s" % container_id)

    var profile: Dictionary = profiles.profile(PROFILE_ID)
    _check(not profile.is_empty(), "real System-24 profile available")
    var records: Array[Dictionary] = []
    for container_id: String in searchable:
        records.append({
            "container_id": container_id,
            "loot_profile_id": PROFILE_ID,
            "loot_profile_version": int(profile.get("version", 0)),
            "building_instance_id": "building.interaction.test",
        })
    _check(loot_state.initialize_source(
        "source.interaction.test",
        &"dev_area",
        "interaction",
        "interaction-signature",
        profiles.catalog_version(),
        records
    ), "searchable provenance initialized")

    var perception := TestPerceptionClass.new(ACTOR_ID)
    _check(perception.is_ready(), "test perception ready")
    _check(perception.set_states({
        Vector2i(6, 5): PerceptionClass.KnowledgeState.VISIBLE,
        Vector2i(7, 5): PerceptionClass.KnowledgeState.UNSEEN,
        Vector2i(4, 5): PerceptionClass.KnowledgeState.VISIBLE,
        Vector2i(6, 6): PerceptionClass.KnowledgeState.VISIBLE,
    }), "knowledge fixture installed")

    var provider := LootProviderClass.new(world, containment, loot_state, profiles, reach)
    var query := QueryClass.new(world, reach, perception, ACTOR_ID)
    _check(provider.is_ready(), "loot offer provider ready")
    _check(query.is_ready(), "interaction affordance query ready")
    _check(query.register_provider(provider), "loot provider registered")

    return {
        "world": world,
        "mutations": mutations,
        "containment": containment,
        "loot_state": loot_state,
        "profiles": profiles,
        "reach": reach,
        "kernel": kernel,
        "perception": perception,
        "provider": provider,
        "query": query,
    }

func _test_reach_geometry(fx: Dictionary) -> void:
    var reach: WorldInteractionReachQuery = fx["reach"]
    var cells: Array[Vector2i] = reach.reachable_cells(ACTOR_ID)
    _check(cells.size() == 2, "single-cell actor CONTACT_FORWARD inspects exactly two cells")
    _check(cells.has(Vector2i(5, 5)) and cells.has(Vector2i(6, 5)), "actor cell plus forward fringe retained")
    _check(reach.target_reachable(ACTOR_ID, FRONT_ID), "forward target reachable")
    _check(not reach.target_reachable(ACTOR_ID, BEHIND_ID), "behind target not reachable")
    _check(not reach.target_reachable(ACTOR_ID, DIAGONAL_ID), "diagonal target not reachable")
    _check(reach.target_reachable(ACTOR_ID, MULTI_ID), "multi-cell target reachable by footprint intersection")

    var candidates: Array[String] = reach.candidate_object_ids(ACTOR_ID)
    _check(candidates.size() == 3, "bounded occupancy returns only three forward/local objects")
    _check(candidates.has(FRONT_ID) and candidates.has(MULTI_ID) and candidates.has(DECORATIVE_ID), "forward occupancy includes real local objects")
    _check(not candidates.has(BEHIND_ID) and not candidates.has(DIAGONAL_ID), "bounded discovery excludes behind/diagonal objects")

func _test_provider_and_knowledge_filtering(fx: Dictionary) -> void:
    var query: InteractionAffordanceQuery = fx["query"]
    var perception: InteractionTestPerception = fx["perception"]

    var offers: Array[InteractionOffer] = query.offers()
    _check(offers.size() == 2, "only two real searchable reachable targets offer SEARCH")
    _check(_offer_targets(offers) == [FRONT_ID, MULTI_ID], "decorative reachable prop publishes no fake offer")

    var highlights: Array[Dictionary] = query.highlight_descriptors()
    _check(highlights.size() == 2, "two currently visible searchable targets highlight")
    var multi: Dictionary = _descriptor_for(highlights, MULTI_ID)
    var multi_cells: Array = multi.get("visible_cells", [])
    _check(multi_cells.size() == 1 and multi_cells.has(Vector2i(6, 5)), "partial multi-cell visibility exposes only VISIBLE footprint cell")
    _check(not multi_cells.has(Vector2i(7, 5)), "UNSEEN multi-cell portion never leaks")

    _check(perception.set_knowledge_state(Vector2i(6, 5), PerceptionClass.KnowledgeState.REMEMBERED), "front cell set REMEMBERED")
    _check(query.highlight_descriptors().is_empty(), "REMEMBERED reachable targets do not highlight")
    _check(perception.set_knowledge_state(Vector2i(6, 5), PerceptionClass.KnowledgeState.UNSEEN), "front cell set UNSEEN")
    _check(query.highlight_descriptors().is_empty(), "UNSEEN reachable targets do not highlight")
    _check(perception.set_knowledge_state(Vector2i(6, 5), PerceptionClass.KnowledgeState.VISIBLE), "front cell restored VISIBLE")
    _check(query.highlight_descriptors().size() == 2, "VISIBLE target knowledge restores highlights")

func _test_dedup_and_presentation_zero_ticks(fx: Dictionary) -> void:
    var query: InteractionAffordanceQuery = fx["query"]
    var world: WorldState = fx["world"]
    var placement: WorldPlacement = world.placement(FRONT_ID)
    var duplicate_offer := OfferClass.new(
        ACTOR_ID,
        FRONT_ID,
        &"test.inspect",
        "INSPECT",
        ReachClass.CONTACT_FORWARD,
        placement.world_cells(),
        50,
        &"container",
        true
    )
    var fixed_provider := FixedProviderClass.new([duplicate_offer])
    _check(query.register_provider(fixed_provider), "second provider registered")
    _check(query.offers().size() == 3, "multiple real offers are preserved")
    var highlights: Array[Dictionary] = query.highlight_descriptors()
    _check(highlights.size() == 2, "multiple offers deduplicate to one highlight per stable target")
    var front: Dictionary = _descriptor_for(highlights, FRONT_ID)
    var action_ids: Array = front.get("action_ids", [])
    _check(action_ids.size() == 2 and action_ids.has("scavenge.search_container") and action_ids.has("test.inspect"), "deduplicated highlight retains both action identities")

    var kernel: TickKernel = fx["kernel"]
    var tick_before: int = kernel.world_tick()
    var renderer := RendererClass.new()
    _check(renderer.configure(query), "highlight renderer configures from query")
    _check(renderer.set_visible_window(Vector2i(0, 0), Vector2i(12, 12), 24.0), "highlight renderer accepts tactical window")
    _check(renderer.highlight_count() == 2, "renderer receives two deduplicated targets")
    _check(kernel.world_tick() == tick_before, "affordance query and presentation spend zero WHEN ticks")

func _test_facing_change(fx: Dictionary) -> void:
    var mutations: WorldMutationService = fx["mutations"]
    var reach: WorldInteractionReachQuery = fx["reach"]
    var query: InteractionAffordanceQuery = fx["query"]
    _check(mutations.set_placement(ACTOR_ID, Layers.Channel.ACTOR, Vector2i(5, 5), Facing.Value.WEST, Footprint.single_cell()), "actor turns west")
    _check(reach.target_reachable(ACTOR_ID, BEHIND_ID), "former behind target becomes forward after turn")
    _check(not reach.target_reachable(ACTOR_ID, FRONT_ID), "former front target becomes unreachable after turn")
    _check(not reach.target_reachable(ACTOR_ID, MULTI_ID), "multi target no longer intersects west reach")
    var targets: Array[String] = _descriptor_targets(query.highlight_descriptors())
    _check(targets == [BEHIND_ID], "highlight follows the exact real reach/facing change")

func _create_object(
    mutations: WorldMutationService,
    entity_id: String,
    anchor: Vector2i,
    footprint: SpatialFootprint,
    semantic: StringName = &"prop.retail_shelf"
) -> void:
    _check(mutations.create_entity(semantic, entity_id) == entity_id, "object created: %s" % entity_id)
    _check(mutations.set_placement(entity_id, Layers.Channel.OBJECT, anchor, Facing.Value.NORTH, footprint), "object placed: %s" % entity_id)

func _offer_targets(offers: Array[InteractionOffer]) -> Array[String]:
    var result: Array[String] = []
    for offer: InteractionOffer in offers:
        result.append(offer.target_entity_id)
    result.sort()
    return result

func _descriptor_targets(descriptors: Array[Dictionary]) -> Array[String]:
    var result: Array[String] = []
    for descriptor: Dictionary in descriptors:
        result.append(String(descriptor.get("target_entity_id", "")))
    result.sort()
    return result

func _descriptor_for(descriptors: Array[Dictionary], target_id: String) -> Dictionary:
    for descriptor: Dictionary in descriptors:
        if String(descriptor.get("target_entity_id", "")) == target_id:
            return descriptor
    return {}

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
