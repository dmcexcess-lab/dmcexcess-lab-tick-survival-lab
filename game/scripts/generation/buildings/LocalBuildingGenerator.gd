extends RefCounted
class_name LocalBuildingGenerator

const TrailerClass = preload("res://scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd")
const PlanClass = preload("res://scripts/generation/buildings/GeneratedBuildingPlan.gd")

var _generators: Dictionary = {}

func _init() -> void:
    var trailer := TrailerClass.new()
    _generators[TrailerClass.ARCHETYPE_ID] = trailer

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    if request == null or not request.is_valid():
        var invalid := PlanClass.new()
        invalid.failure_reason = "invalid_building_request"
        return invalid
    if not _generators.has(request.archetype_id):
        var unknown := PlanClass.new()
        unknown.failure_reason = "building_archetype_unknown"
        return unknown
    return _generators[request.archetype_id].generate(request)

func supported_archetypes() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _generators.keys():
        result.append(StringName(key))
    result.sort()
    return result
