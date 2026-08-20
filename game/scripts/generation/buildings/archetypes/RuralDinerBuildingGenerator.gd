extends RefCounted
class_name RuralDinerBuildingGenerator

const ProfileClass = preload("res://scripts/generation/buildings/profiles/RuralDinerBuildingProfile.gd")
const GrammarClass = preload("res://scripts/generation/buildings/grammar/BuildingGrammarGenerator.gd")

const ARCHETYPE_ID: StringName = ProfileClass.ARCHETYPE_ID
const ARCHETYPE_VERSION: int = ProfileClass.ARCHETYPE_VERSION

func generate(request: BuildingGenerationRequest) -> GeneratedBuildingPlan:
    return GrammarClass.new().generate(ProfileClass.build(), request)
