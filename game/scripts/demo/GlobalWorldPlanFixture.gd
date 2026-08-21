extends RefCounted
class_name GlobalWorldPlanFixture

const RequestClass = preload("res://scripts/generation/world/GlobalWorldGenerationRequest.gd")
const Profiles = preload("res://scripts/generation/world/GlobalWorldProfileCatalog.gd")

const WORLD_ID: String = "world.region.temperate.001"
const SEED: int = 20001
const BOUNDS: Rect2i = Rect2i(232, 1232, 1792, 1792)
const CENTER: Vector2i = Vector2i(1128, 2128)
const CENTRAL_SITE_ID: String = "area.rural.crossroads.001"

static func request(seed: int = SEED) -> GlobalWorldGenerationRequest:
    return RequestClass.new(
        WORLD_ID,
        seed,
        BOUNDS,
        Profiles.TEMPERATE_RURAL_REGION
    )
