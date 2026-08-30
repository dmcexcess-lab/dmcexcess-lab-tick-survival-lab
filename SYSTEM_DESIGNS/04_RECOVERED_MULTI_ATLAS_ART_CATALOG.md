# Tick Survival Lab — 04 Recovered Multi-Atlas Art Catalog

Status: **IMPLEMENTED — canonical recovered catalog with additive 08 living-actor recovery and dedicated Godot CI contract present 2026-08-16**

Approval basis: after 03 implementation, the recommended next bounded system was the recovered multi-atlas Art Catalog. The user instructed: **“Yea we spent a lot of time on art already lets recover it if we can. Approved”**. The later approved 08 Player / Living Actor Renderer added a narrowly scoped same-owner living-actor source/resolver without changing existing resolver semantics.

## 1. Goal

Provide the canonical presentation catalog recovered from solved same-owner art systems. It maps semantic art requests to preserved texture sources and atlas regions without owning rendering, physics, generation, world state, input, or simulation.

## 2. Recovery sources

Golden Tick recovery baseline: commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Golden Tick `TacticalTiles.gd` blob: `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`.

The original ten Tick baseline art assets remain byte-identical to their golden blobs and remain CI-protected.

08 additionally recovered living-actor artwork from same-owner First Fire tactical art. First Fire source tactical-atlas blob:

`2caff9a1c2ec84fc7d56e6b2c64bce953c575029`

The extracted actor-only Tick asset is separately pinned as:

`game/assets/actor_atlas.svg` -> `205036fff8ffb24f828a09cf033abcf615ce6fe0`

This new actor source is deliberately **not** represented as one of the original ten golden Tick baseline assets.

## 3. Scope

Recovered/current catalog vocabulary:

- seven atlas source families: tactical, clutter, world, building props, final surfaces, final props, actors;
- four protected directional player full-texture sources;
- ground/wall/door/window/prop semantic mappings;
- living survivor/infected family + facing + variant mappings;
- golden source-precedence rules;
- road/dirt-road/sidewalk visual topology selection;
- 32px, 16-column atlas-region math;
- typed diagnostics for unknown semantic art requests.

CanvasItem drawing and layer renderers remain separate systems.

## 4. Owners

- `game/scripts/art/ArtSource.gd`
- `game/scripts/art/ArtSelection.gd`
- `game/scripts/art/ArtBaselineManifest.gd`
- `game/scripts/art/RoadArtTopology.gd`
- `game/scripts/art/ArtCatalog.gd`
- `game/scripts/ci/ArtCatalogSmoke.gd`
- `.github/workflows/art-catalog.yml`
- separately recovered presentation asset `game/assets/actor_atlas.svg`

## 5. Public contract

`ArtCatalog` returns typed `ArtSelection` descriptors through category-specific semantic lookups:

- `resolve_ground`
- `resolve_wall`
- `resolve_door`
- `resolve_window`
- `resolve_prop`
- `resolve_player`
- `resolve_living_actor`
- `resolve_road`
- `resolve_dirt_road`
- `resolve_sidewalk`

Selections expose source ID/path, atlas index/region, and FOUND/UNKNOWN status. The catalog loads no gameplay state and performs no drawing.

### Living actor resolver

`resolve_living_actor(actor_family, facing, variant)` currently accepts:

- survivor: 8 variants × N/E/S/W -> actor-atlas indices 0–31;
- infected: 8 variants × N/E/S/W -> actor-atlas indices 32–63.

Invalid family, facing or variant returns typed UNKNOWN. The catalog does not decide which stable actor gets which variant; 08 presentation owns its temporary deterministic default until a persistent Actor Appearance domain exists.

The existing controlled-player `resolve_player(facing)` contract remains unchanged and continues to return the four protected independent player textures.

## 6. Recovered precedence

Ground: final exact -> final alias -> world -> tactical.

Wall: final -> world -> tactical.

Prop: final exact -> final alias -> building -> clutter -> tactical.

Known themed doors/windows use golden world-art mappings. Empty/default door/window theme uses tactical fallback art.

Living actor selection is explicit family + facing + variant; it does not fall through to player or prop art.

## 7. Intentional failure improvement

Golden code silently substituted asphalt/alley/crate-style fallback art for unknown ground/wall/prop keys. Canonical Art Catalog returns typed UNKNOWN instead. Known recovered mappings are unchanged; only missing-content failure is visible/diagnosable.

Living actor recovery follows the same rule: unknown future animal/actor families never silently become survivor/infected art.

## 8. Road topology

Recovered N/E/S/W bitmask values `1/2/4/8`, straight/corner/T/cross/end/plain world-art road indices, golden arterial plain-road special cases, dirt-road orientation selection, and sidewalk curb selection.

The catalog receives precomputed connectivity masks. It never inspects generator dictionaries or WHAT.

## 9. Actor/player facing

Canonical WHERE facing maps to exact preserved player sprites for the controlled survivor and to explicit actor-atlas facing cells for non-player survivors/infected. Invalid facing returns UNKNOWN.

## 10. Dependencies and forbidden boundaries

Allowed: canonical WHERE facing vocabulary only.

Forbidden: WHAT, WHEN, collision, movement, actor capability, generator, renderer Nodes, input/UI, reboot runtime, lighting/perception/weather/sound.

The catalog mutates no simulation state.

## 11. Verified acceptance

Dedicated Godot 4.7.1 CI proves:

- all ten original golden Tick art Git blob hashes remain exact;
- the separately recovered actor asset hash remains exact;
- all source texture paths load;
- atlas region math is correct;
- representative/boundary mappings across the environmental atlases match golden behavior;
- all 128 final props, all 32 building props, and all 24 clutter props remain represented;
- ground/wall/prop precedence matches golden `TacticalTiles.gd`;
- themed/default door and window behavior matches the approved contract;
- road/dirt-road/sidewalk topology and arterial special cases are preserved;
- N/E/S/W player source paths are exact;
- all 8 survivor and all 8 infected variants resolve for all four facings — 64 living-NPC cells total;
- invalid actor family/variant/facing fail visibly as UNKNOWN;
- production `game/scripts/art/` imports none of the forbidden neighboring systems.

Original catalog implementation commit `9ebb382e658168c7d76b3b7c3deb596154b65f27` passed the dedicated `Recovered Art Catalog contract` with no production repair required.

08 actor extension implementation began at `77f2a86e964bef9128fd2b52a0799d46c146601e`. A CI-only hash-literal correction produced `c37be260e273e70a2bb2f5a91261d99a8a5cb898`; dedicated Art Catalog run `31985099764` passed there with the actor extension and all earlier catalog regressions.

## 12. Future seams

Ground, Structure, Prop/Fixture/Vegetation, and Player/Living Actor renderers consume this catalog. Corpse and carried-equipment art may be recovered into explicit later presentation contracts without making 04 own corpse/inventory semantics. Prefab preview and alternative art packs may also consume catalog descriptors without moving atlas indices into world/generator data.

## 13. North-star fit

This recovers prior visual work and the persistent-world-like readable art vocabulary while making art replaceable and keeping art strictly separate from physics and persistent world truth. The actor extension recovers real survivors/infected rather than fake markers while keeping actor identity/behavior outside the art system.

## 14. Approved decisions

Approved 2026-08-16:

- recover the pinned golden Tick multi-atlas semantics rather than create replacement environment art;
- preserve the original ten Tick baseline assets byte-for-byte;
- catalog selects descriptors but does not draw;
- recover road/sidewalk topology as pure art logic;
- keep generator/WHAT/physics free of atlas paths/indices;
- unknown semantic art IDs fail visibly;
- do not wire the catalog into deprecated reboot code;
- for approved 08, recover same-owner survivor/infected artwork into a **separate** actor-only source with separately pinned provenance;
- keep `resolve_player` intact while adding typed `resolve_living_actor` as an additive contract.
