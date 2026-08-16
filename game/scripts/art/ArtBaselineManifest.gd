extends RefCounted
class_name ArtBaselineManifest

## Code-visible provenance for the preserved golden visual baseline.
## CI verifies the Git blob identities; runtime renderers consume only paths.

const GOLDEN_COMMIT := "1763958f44eb7f855fd49944c00d1ffe608c0abe"
const GOLDEN_TACTICAL_TILES_BLOB := "3d8a0a70ac983408bb48f58fc659dfb07e216ed3"

const ASSET_BLOB_SHA_BY_PATH := {
    "game/assets/tactical_atlas.svg": "a031ac456a7d92b7fbf2d6e4d625c3a30e749a4f",
    "game/assets/clutter_atlas.svg": "966c9de04ad84d05d6203cc4e078f2fad07c03d4",
    "game/assets/world_art_atlas.svg": "995e52973e14db0ef60f3562c1cfa5ae342d62d2",
    "game/assets/building_props_atlas.svg": "856be2fc90d009d1b4bcc565990b9428323bb4d6",
    "game/assets/final_environment_surfaces_atlas.svg": "a42607858bae04f25fb1c6621a6d9262e81550b1",
    "game/assets/final_environment_props_atlas.svg": "7714d8c95833e20ebca20cfa1374f23eaa5509f1",
    "game/assets/player_north.svg": "dfeb5be1c9cc0b66aec842d969b60b485d3a4f99",
    "game/assets/player_east.svg": "76c3e7e1a3b07712c65b385f1d80e131b45d90b3",
    "game/assets/player_south.svg": "a2e358fd8fe15d497bf9559ae89835af0331d10f",
    "game/assets/player_west.svg": "c2cc192efed4c4a81905eb0d8100cd4776d4731b",
}

static func expected_asset_blob_shas() -> Dictionary:
    return ASSET_BLOB_SHA_BY_PATH.duplicate(true)

static func res_path(repository_path: String) -> String:
    const PREFIX := "game/"
    if repository_path.begins_with(PREFIX):
        return "res://" + repository_path.substr(PREFIX.length())
    return repository_path
