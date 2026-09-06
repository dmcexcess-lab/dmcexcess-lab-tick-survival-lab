extends SceneTree

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const GeneratorClass = preload("res://scripts/generation/buildings/LocalBuildingGenerator.gd")
const BaselineProfilesClass = preload("res://scripts/generation/buildings/profiles/OneStoryBaselineProfileCatalog.gd")
const LootItemsClass = preload("res://scripts/simulation/loot/LootItemCatalog.gd")
const LootProfilesClass = preload("res://scripts/simulation/loot/LootContainerProfileCatalog.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const TimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const FreshCatalogClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessProfileCatalog.gd")
const IconCatalogClass = preload("res://scripts/ui/icons/CraftingSemanticUiIconCatalog.gd")
const VisualGeometryClass = preload("res://scripts/art/PropVisualGeometryCatalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_building_content()
    _test_loot_freshness_icons()
    _test_large_visual_integration()
    if failures.is_empty():
        print("PHASE1E_CONTENT_INTEGRATION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("PHASE1E_CONTENT_INTEGRATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_building_content() -> void:
    var generator := GeneratorClass.new()
    var baseline := BaselineProfilesClass.new()
    _check(baseline.profile_ids().size() == 18, "eighteen baseline one-story profiles remain registered")
    _check(generator.supported_archetypes().size() == 25, "all twenty-five System 19 archetypes remain callable")

    var representative: Dictionary = {
        &"residential.house.suburban_family": false,
        &"commercial.grocery.neighborhood": false,
        &"civic.school.elementary_small": false,
        &"industrial.workshop.small": false,
        &"agricultural.barn.medium": false,
    }

    for profile_id: StringName in baseline.profile_ids():
        var descriptor: BuildingArchetypePlacementDescriptor = generator.placement_descriptor(profile_id)
        _check(descriptor != null and descriptor.is_valid(), "baseline descriptor remains valid: %s" % String(profile_id))
        if descriptor == null or not descriptor.is_valid():
            continue
        _check(descriptor.archetype_version() == 2, "Phase 1E final building content version is two: %s" % String(profile_id))
        var size: Vector2i = descriptor.required_size(Facing.Value.NORTH)
        var frontage: int = descriptor.frontage_for_orientation(Facing.Value.NORTH)
        var request := RequestClass.new(
            "building.phase1e.%s" % String(profile_id).replace(".", "_"),
            profile_id,
            4101,
            Rect2i(Vector2i(100, 100), size),
            Facing.Value.NORTH,
            frontage
        )
        var plan: GeneratedBuildingPlan = generator.generate(request)
        _check(plan.is_generated(), "Phase 1E baseline plan generates: %s" % String(profile_id))
        if not plan.is_generated():
            continue
        _check(plan.archetype_version == 2, "generated Phase 1E baseline provenance is version two: %s" % String(profile_id))
        var accents: int = 0
        for prop: Dictionary in plan.props:
            if String(prop.get("role", "")).begins_with("prop.phase1e."):
                accents += 1
        _check(accents <= 2, "Phase 1E accents remain bounded to two: %s" % String(profile_id))
        if representative.has(profile_id) and accents > 0:
            representative[profile_id] = true

    for profile_id: Variant in representative.keys():
        _check(bool(representative[profile_id]), "representative location gains real Phase 1E identity content: %s" % String(profile_id))

    for protected_id: StringName in [
        &"residential.trailer.singlewide",
        &"residential.house.farm_small",
        &"residential.house.farm_large",
        &"residential.house.compact_laundry",
        &"commercial.gas_station.small",
        &"commercial.diner.rural_small",
        &"civic.post_office.small",
    ]:
        _check(not baseline.has_profile(protected_id), "protected dedicated archetype stays outside Phase 1E baseline dresser: %s" % String(protected_id))
        _check(generator.placement_descriptor(protected_id) != null, "protected dedicated archetype remains callable: %s" % String(protected_id))

func _test_loot_freshness_icons() -> void:
    var items := LootItemsClass.new()
    var profiles := LootProfilesClass.new()
    var physical := PhysicalCatalogClass.new()
    var time_profile := TimeProfileClass.new()
    var freshness := FreshCatalogClass.new(time_profile)
    var icons := IconCatalogClass.new()

    _check(items.catalog_version() == 5, "current loot catalog version is five")
    _check(items.semantic_types().size() == 108, "current world loot exposes one hundred eight physical semantics")
    _check(items.register_physical_profiles(physical), "every current loot semantic registers real physical weight")
    _check(profiles.catalog_version() == 3 and profiles.validate_items(items), "current location-aware loot tables validate against item truth")
    for profile_id: StringName in [&"civic.school.supplies", &"civic.church.supplies", &"civic.police.supplies", &"civic.fire.supplies"]:
        _check(not profiles.profile(profile_id).is_empty(), "Phase 1E civic loot profile still exists: %s" % String(profile_id))

    _check(profiles.classify(&"civic.school.elementary_small", "prop.phase1e.01", &"prop.file_cabinet_tall") == &"civic.school.supplies", "school file storage gets school supplies")
    _check(profiles.classify(&"civic.fire_station.small", "prop.phase1e.01", &"prop.tool_cabinet") == &"civic.fire.supplies", "fire-station tool storage gets station supplies")
    _check(profiles.classify(&"commercial.grocery.neighborhood", "prop.phase1e.01", &"prop.retail_endcap") == &"retail.grocery", "grocery endcap gets grocery stock")

    _check(freshness.catalog_version() == 2, "Phase 1E freshness catalog version is two")
    _check(freshness.semantic_types().size() == 10, "Phase 1E registers ten explicit perishables")
    for semantic: StringName in freshness.semantic_types():
        _check(items.has_item(semantic), "every perishable is a real loot semantic: %s" % String(semantic))
    _check(not freshness.has_profile(&"item.food.rice_bag"), "dry rice remains shelf stable")

    _check(icons.is_ready(), "current System 31 icon catalog remains ready")
    _check(icons.known_semantics().size() == 120, "current icon vocabulary includes Phase 1E plus primitive/crafting/apparel semantics")
    for semantic: StringName in items.semantic_types():
        _check(icons.has_icon(semantic), "every current loot semantic has an explicit UI icon: %s" % String(semantic))

func _test_large_visual_integration() -> void:
    _check(VisualGeometryClass.TREE_SEMANTIC == &"prop.deciduous_large", "07B tree descriptor binds the real generated prop semantic")
    _check(VisualGeometryClass.TRAFFIC_LIGHT_SEMANTIC == &"prop.traffic_light", "07B traffic-light descriptor binds the real generated prop semantic")
    var tree: PropVisualGeometryDescriptor = VisualGeometryClass.descriptor_for(&"prop.deciduous_large")
    var traffic_visual: PropVisualGeometryDescriptor = VisualGeometryClass.descriptor_for(&"prop.traffic_light")
    _check(tree.draw_span_cells == Vector2i(2, 2) and tree.has_foreground(), "ordinary generated large tree consumes 2x2 07B geometry")
    _check(traffic_visual.draw_span_cells == Vector2i(2, 2) and traffic_visual.has_foreground(), "ordinary generated traffic light consumes 2x2 07B geometry")
    _check(VisualGeometryClass.maximum_discovery_halo_cells() == 2, "large-object discovery remains bounded to two cells")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
