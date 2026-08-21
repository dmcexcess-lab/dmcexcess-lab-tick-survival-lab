extends RefCounted
class_name RuralCrossroadsPlanFixture

const RequestClass = preload("res://scripts/generation/areas/AreaGenerationRequest.gd")
const AreaProfiles = preload("res://scripts/generation/areas/AreaProfileCatalog.gd")
const EnvironmentProfiles = preload("res://scripts/generation/areas/EnvironmentProfileCatalog.gd")

const AREA_ID: String = "area.rural.crossroads.001"
const SEED: int = 20001
const BOUNDS: Rect2i = Rect2i(1000, 2000, 256, 256)
const CENTER: Vector2i = Vector2i(1128, 2128)
const PRIMARY_ROAD_ID: String = "road.region.primary.001"
const SECONDARY_ROAD_ID: String = "road.region.secondary.001"

static func request(seed: int = SEED) -> AreaGenerationRequest:
    var primary := {
        "road_id": PRIMARY_ROAD_ID,
        "road_class": &"primary",
        "start": Vector2i(BOUNDS.position.x, CENTER.y),
        "end": Vector2i(BOUNDS.position.x + BOUNDS.size.x - 1, CENTER.y),
        "width": 5,
        "allowed_boundary_cells": [
            Vector2i(BOUNDS.position.x, CENTER.y),
            Vector2i(BOUNDS.position.x + BOUNDS.size.x - 1, CENTER.y),
        ],
    }
    var secondary := {
        "road_id": SECONDARY_ROAD_ID,
        "road_class": &"secondary",
        "start": Vector2i(CENTER.x, BOUNDS.position.y),
        "end": Vector2i(CENTER.x, BOUNDS.position.y + BOUNDS.size.y - 1),
        "width": 3,
        "allowed_boundary_cells": [
            Vector2i(CENTER.x, BOUNDS.position.y),
            Vector2i(CENTER.x, BOUNDS.position.y + BOUNDS.size.y - 1),
        ],
    }
    var roads: Array[Dictionary] = [primary, secondary]
    return RequestClass.new(
        AREA_ID,
        seed,
        BOUNDS,
        AreaProfiles.RURAL_CROSSROADS,
        EnvironmentProfiles.TEMPERATE_RURAL,
        roads,
        []
    )
