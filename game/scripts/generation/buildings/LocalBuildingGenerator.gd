extends RefCounted
class_name LocalBuildingGenerator

const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const RequestClass = preload("res://scripts/generation/buildings/BuildingGenerationRequest.gd")
const DescriptorClass = preload("res://scripts/generation/buildings/BuildingArchetypePlacementDescriptor.gd")
const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")
const FarmhouseClass = preload("res://scripts/generation/buildings/archetypes/FarmhouseBuildingGenerator.gd")
const LargeFarmhouseClass = preload("res://scripts/generation/buildings/archetypes/LargeFarmhouseBuildingGenerator.gd")
const CompactLaundryHouseClass = preload("res://scripts/generation/buildings/archetypes/CompactLaundryHouseBuildingGenerator.gd")
const GasStationClass = preload("res://scripts/generation/buildings/archetypes/GasStationBuildingGenerator.gd")
const RuralDinerClass = preload("res://scripts/generation/buildings/archetypes/RuralDinerBuildingGenerator.gd")
const BaselineProfilesClass = preload("res://scripts/generation/buildings/profiles/OneStoryBaselineProfileCatalog.gd")
const OneStoryGeneratorClass = preload("res://scripts/generation/buildings/grammar/OneStoryProfileBuildingGenerator.gd")
const Phase1EContentDresserClass = preload("res://scripts/generation/buildings/content/Phase1EOneStoryContentDresser.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

var _generators: Dictionary = {}
var _descriptor_cache: Dictionary = {}
var _phase1e_content_dresser: Phase1EOneStoryContentDresser

func _init() -> void:
    _phase1e_content_dresser = Phase1EContentDresserClass.new()
    _generators[TrailerClass.ARCHETYPE_ID] = TrailerClass.new()
    _generators[FarmhouseClass.ARCHETYPE_ID] = FarmhouseClass.new()
    _generators[LargeFarmhouseClass.ARCHETYPE_ID] = LargeFarmhouseClass.new()
    _generators[CompactLaundryHouseClass.ARCHETYPE_ID] = CompactLaundryHouseClass.new()
    _generators[GasStationClass.ARCHETYPE_ID] = GasStationClass.new()
    _generators[RuralDinerClass.ARCHETYPE_ID] = RuralDinerClass.new()

    var baseline_catalog := BaselineProfilesClass.new()
    for profile_id: StringName in baseline_catalog.profile_ids():
        var profile: Dictionary = baseline_catalog.profile(profile_id)
        if profile.is_empty():
            continue
        _generators[profile_id] = OneStoryGeneratorClass.new(profile)

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    if request == null or not request.is_valid():
        var invalid := PlanClass.new()
        invalid.failure_reason = "invalid_building_request"
        return invalid
    if not _generators.has(request.archetype_id):
        var unknown := PlanClass.new()
        unknown.failure_reason = "building_archetype_unknown"
        return unknown
    var plan: GeneratedBuildingPlan = _generators[request.archetype_id].generate(request)
    _phase1e_content_dresser.apply(plan)
    return plan

func supported_archetypes() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _generators.keys():
        result.append(StringName(key))
    result.sort()
    return result

func placement_descriptor(archetype_id: StringName) -> BuildingArchetypePlacementDescriptor:
    if not _generators.has(archetype_id):
        return null
    if not _descriptor_cache.has(archetype_id):
        var built: BuildingArchetypePlacementDescriptor = _build_placement_descriptor(archetype_id)
        if built == null or not built.is_valid():
            return null
        _descriptor_cache[archetype_id] = built
    return _copy_descriptor(_descriptor_cache[archetype_id])

func placement_descriptors() -> Array[BuildingArchetypePlacementDescriptor]:
    var result: Array[BuildingArchetypePlacementDescriptor] = []
    for archetype_id: StringName in supported_archetypes():
        var descriptor: BuildingArchetypePlacementDescriptor = placement_descriptor(archetype_id)
        if descriptor != null:
            result.append(descriptor)
    return result

func _build_placement_descriptor(archetype_id: StringName) -> BuildingArchetypePlacementDescriptor:
    var canonical_size: Vector2i = Vector2i.ZERO
    var canonical_frontage: int = -1
    var archetype_version: int = 0
    var supported: Array[int] = []
    var orientations: Array[int] = [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]
    var frontages: Array[int] = [Facing.Value.NORTH, Facing.Value.EAST, Facing.Value.SOUTH, Facing.Value.WEST]
    var target: Variant = _generators[archetype_id]

    for orientation: int in orientations:
        for frontage: int in frontages:
            var request := RequestClass.new(
                "building.descriptor.probe.%d.%d" % [orientation, frontage],
                archetype_id,
                0,
                Rect2i(0, 0, 512, 512),
                orientation,
                frontage
            )
            var plan: GeneratedBuildingPlan = target.generate(request)
            _phase1e_content_dresser.apply(plan)
            if not plan.is_generated():
                continue
            supported.append(orientation)
            if orientation == Facing.Value.NORTH:
                canonical_size = plan.footprint_rect.size
                canonical_frontage = frontage
                archetype_version = plan.archetype_version
            break

    if canonical_size == Vector2i.ZERO or canonical_frontage < 0 or archetype_version <= 0:
        return null
    return DescriptorClass.new(archetype_id, archetype_version, canonical_size, canonical_frontage, supported)

func _copy_descriptor(source: BuildingArchetypePlacementDescriptor) -> BuildingArchetypePlacementDescriptor:
    return DescriptorClass.new(
        source.archetype_id(),
        source.archetype_version(),
        source.canonical_size(),
        source.canonical_frontage(),
        source.supported_orientations()
    )
