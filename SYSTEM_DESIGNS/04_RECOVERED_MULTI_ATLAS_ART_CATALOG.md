# Tick Survival Lab — 04 Recovered Multi-Atlas Art Catalog

Status: **IMPLEMENTED — canonical recovered catalog and dedicated Godot CI contract present 2026-08-16**

Approval basis: after 03 implementation, the recommended next bounded system was the recovered multi-atlas Art Catalog. The user instructed: **“Yea we spent a lot of time on art already lets recover it if we can. Approved”**.

## 1. Goal

Provide the canonical presentation catalog recovered from the golden multi-atlas art system. It maps semantic art requests to preserved texture sources and atlas regions without owning rendering, physics, generation, world state, input, or simulation.

## 2. Recovery source

Golden recovery baseline: commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Golden `TacticalTiles.gd` blob: `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`.

Baseline art assets remain byte-identical to the golden blobs and are CI-protected in this system.

## 3. Scope

Recovered:

- six atlas source families;
- four directional player sprites;
- ground/wall/door/window/prop semantic mappings;
- golden source-precedence rules;
- road/dirt-road/sidewalk visual topology selection;
- 32px, 16-column atlas-region math;
- explicit diagnostics for unknown semantic art requests.

CanvasItem drawing and layer renderers remain separate later systems.

## 4. Owners

- `game/scripts/art/ArtSource.gd`
- `game/scripts/art/ArtSelection.gd`
- `game/scripts/art/ArtBaselineManifest.gd`
- `game/scripts/art/RoadArtTopology.gd`
- `game/scripts/art/ArtCatalog.gd`
- `game/scripts/ci/ArtCatalogSmoke.gd`
- `.github/workflows/art-catalog.yml`

## 5. Public contract

`ArtCatalog` returns typed `ArtSelection` descriptors through category-specific semantic lookups:

- `resolve_ground`
- `resolve_wall`
- `resolve_door`
- `resolve_window`
- `resolve_prop`
- `resolve_player`
- `resolve_road`
- `resolve_dirt_road`
- `resolve_sidewalk`

Selections expose source ID/path, atlas index/region, and FOUND/UNKNOWN status. The catalog loads no gameplay state and performs no drawing.

## 6. Recovered precedence

Ground: final exact -> final alias -> world -> tactical.

Wall: final -> world -> tactical.

Prop: final exact -> final alias -> building -> clutter -> tactical.

Known themed doors/windows use golden world-art mappings. Empty/default door/window theme uses the tactical fallback art.

## 7. Intentional failure improvement

Golden code silently substituted asphalt/alley/crate-style fallback art for unknown ground/wall/prop keys. Canonical Art Catalog returns typed UNKNOWN instead. Known golden mappings are unchanged; only missing-content failure becomes visible/diagnosable.

## 8. Road topology

Recovered N/E/S/W bitmask values `1/2/4/8`, straight/corner/T/cross/end/plain world-art road indices, golden arterial plain-road special cases, dirt-road orientation selection, and sidewalk curb selection.

The catalog receives precomputed connectivity masks. It never inspects generator dictionaries or WHAT.

## 9. Player facing

Canonical WHERE facing maps to exact preserved sprites: north/east/south/west. Invalid facing returns UNKNOWN.

## 10. Dependencies and forbidden boundaries

Allowed: canonical WHERE facing vocabulary only.

Forbidden: WHAT, WHEN, collision, movement, actor capability, generator, renderer Nodes, input/UI, reboot runtime, lighting/perception/weather/sound.

The catalog mutates no simulation state.

## 11. Verified acceptance

Dedicated Godot 4.7.1 CI proves:

- all ten baseline art Git blob hashes remain exact;
- all ten texture paths load;
- atlas region math is correct;
- representative/boundary mappings across all six atlases match golden behavior;
- all 128 final-prop entries, all 32 building props, and all 24 clutter props remain represented;
- ground/wall/prop precedence matches golden `TacticalTiles.gd`;
- themed/default door and window behavior matches the approved contract;
- road/dirt-road/sidewalk topology and arterial special cases are preserved;
- N/E/S/W player source paths are exact;
- unknown semantic requests fail visibly as UNKNOWN;
- production `game/scripts/art/` imports none of the forbidden neighboring systems.

Implementation commit `9ebb382e658168c7d76b3b7c3deb596154b65f27` passed the dedicated `Recovered Art Catalog contract` with no production repair required.

## 12. Future seams

Ground, Structure, Prop/Fixture/Vegetation, and Player/Actor renderers consume this catalog later. Prefab preview and alternative art packs may also consume it without moving atlas indices into world/generator data.

## 13. North-star fit

This recovers prior visual work and the Ultima-like readable art vocabulary while making art replaceable and keeping art strictly separate from physics and persistent world truth.

## 14. Approved decisions

Approved 2026-08-16:

- recover the pinned golden multi-atlas semantics rather than create new art;
- preserve baseline assets byte-for-byte;
- catalog selects descriptors but does not draw;
- recover road/sidewalk topology as pure art logic;
- keep generator/WHAT/physics free of atlas paths/indices;
- unknown semantic art IDs fail visibly;
- do not wire the catalog into deprecated reboot code.
