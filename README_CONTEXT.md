# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture/global direction, but newer North Star/decision entries win where older assumptions conflict.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction:

- one persistent logically continuous open world;
- no raid/extraction/staging loop;
- player-built/secured bases anywhere ordinary world rules permit;
- causal outbreak/population simulation goal;
- customizable player story embedded in the pre-collapse world;
- authoritative invisible tactical grid;
- variable-duration turn-based tick/actions with mandatory real-life hard pause;
- mood driven later by recovered graphics, vision, lighting, weather, silent spatial sound and persistent consequences.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Canonical identity: `PROJECT_NORTH_STAR.md`.

## 2. Current architectural phase

The project is in staged modular replacement of the deprecated playable runtime.

The live `game/scripts/reboot/` runtime is **frozen/deprecated reference code**. Do not extend it as the target architecture and do not add temporary adapters merely to make canonical modules visibly affect the old build.

Golden recovery commit for mature pre-clean-rewrite behavior/art:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Canonical modular progress:

- **00A WHERE / Spatial Model — IMPLEMENTED and CI-gated** under `game/scripts/foundation/spatial/`.
- **00B WHAT / Persistent World State — IMPLEMENTED and CI-gated** under `game/scripts/foundation/world/`.
- **00C WHEN / Tick Action Pause — IMPLEMENTED and CI-gated** under `game/scripts/foundation/time/`.
- **01 Collision / Spatial Query — IMPLEMENTED and CI-gated** under `game/scripts/simulation/collision/`.
- **02 Movement Actions — IMPLEMENTED and CI-gated** under `game/scripts/simulation/movement/`.
- **03 Actor Locomotion State & Movement Capability — IMPLEMENTED and CI-gated** under `game/scripts/simulation/actors/locomotion/`.
- **04 Recovered Multi-Atlas Art Catalog — IMPLEMENTED and CI-gated** under `game/scripts/art/`.

The canonical modules are intentionally tested beside the frozen playable reference until enough neighboring canonical presentation/input/world-composition systems exist for clean replacement rather than compatibility glue.

## 3. Foundation architecture

Canonical umbrella: `SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md`.

The peer truths are:

- **WHERE:** global grid/facing/footprint/structure geometry.
- **WHAT:** persistent terrain/entities/placements and durable foundation mutations.
- **WHEN:** deterministic integer simulation clock, action/event scheduling and pause semantics.

Generation creates initial WHAT using WHERE. Gameplay systems bridge WHERE/WHAT with WHEN. Rendering only presents state.

### 00A WHERE — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md`.

Locked: global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit axis, no sub-cell baseline.

### 00B WHAT — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00B_PERSISTENT_WORLD_STATE.md`.

Locked: one current persistent world, opaque stable IDs, semantic terrain/entities, WHERE placements, derived occupancy, validated `WorldMutationService` writes, safe reads, revisions/change events, deterministic atomic snapshot/restore, no generic mechanic metadata bag.

### 00C WHEN — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00C_TICK_ACTION_PAUSE.md`.

Locked: non-negative integer world tick, deterministic scheduled work, variable-duration concurrent actor actions, semantic phases, COMMITTED/RESUMABLE/CANCELABLE interruption, tactical decision pause, separate hard application pause, same-tick batch drain, deterministic snapshot/restore.

## 4. Downstream canonical simulation

### 01 Collision / Spatial Query — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/01_COLLISION_SPATIAL_QUERY.md`.

Hard occupancy physics is explicit type-level collision plus sparse per-entity overrides. Required missing classification or missing terrain is UNKNOWN/fail-closed. Collision supports hypothetical rotated footprints/self-ignore and deliberately does not own actor-specific terrain traversal.

### 02 Movement Actions — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md`.

Locked movement rules:

- forward/back/turn-left/turn-right only;
- no diagonal/strafe/run yet;
- validate -> spend WHEN duration -> revalidate `movement.commit` -> mutate WHAT;
- no destination reservation;
- stale origin cannot overwrite newer placement;
- backward preserves facing;
- turns query the rotated footprint;
- typed `MovementPolicyDecision` distinguishes terrain failures from actor/capability failures;
- policy is reevaluated at commit; newly blocked capability fails, newly slower-but-allowed capability affects the next action instead of stretching the current schedule.

### 03 Actor Locomotion State & Movement Capability — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md`.

Locked rules:

- explicit locomotion enrollment keyed by stable WHAT actor ID; missing record fails closed;
- persistent stance is semantic `standing` / `crouched` only;
- no persistent RUN flag and no run action until real consequences exist;
- crouch does not alter WHAT footprint/anchor;
- standing step 1.0x, crouched step 1.4x, turns 1.0x initial tuning;
- voluntary crouch/stand is a 4-tick base COMMITTED action with final `actor.stance.commit`;
- per-actor locomotion version prevents stale stance actions overwriting newer state;
- deterministic atomic locomotion snapshot/restore;
- future health/needs/inventory/equipment/skills influence mobility only through sorted read-only `ActorMobilityModifierProvider` contracts;
- capability provider BLOCKED outranks UNKNOWN, allowed BP adjustments combine deterministically;
- actor-aware Movement policy composes base terrain timing + actor capability without importing condition domains into Movement or WHEN.

## 5. Canonical presentation recovery

### 04 Recovered Multi-Atlas Art Catalog — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md`.

The exact semantic-selection vocabulary from golden `TacticalTiles.gd` has been recovered into pure descriptor-based owners under `game/scripts/art/`.

Locked/recovered facts:

- six preserved atlas families plus four directional player sprites;
- all baseline art files remain byte-identical to the pinned golden blobs and are protected by dedicated CI;
- 32x32 atlas cells, 16 columns;
- golden ground precedence: final exact -> final alias -> world -> tactical;
- golden wall precedence: final -> world -> tactical;
- golden prop precedence: final exact -> final alias -> building -> clutter -> tactical;
- complete final-prop vocabulary through index 127 is retained;
- themed/default door and window art mappings are retained;
- road straight/corner/T/cross/end/plain selection, arterial special cases, dirt-road orientation and sidewalk-curb selection are recovered as pure topology-to-art logic;
- canonical N/E/S/W facing maps to the exact four preserved player SVGs;
- missing semantic art IDs now return typed UNKNOWN rather than silently becoming asphalt/alley-wall/crate fallback art;
- Art Catalog performs no CanvasItem drawing and reads no WHAT/generator/physics state.

Implemented owners:

- `ArtSource.gd`
- `ArtSelection.gd`
- `ArtBaselineManifest.gd`
- `RoadArtTopology.gd`
- `ArtCatalog.gd`
- `game/scripts/ci/ArtCatalogSmoke.gd`
- `.github/workflows/art-catalog.yml`

## 6. Open-world / generation direction

Generation is not the engine and streaming partitions never define logical reality.

Long-term planning order:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Roads, utilities, rivers, parcels and other cross-region structures are planned globally before local materialization. Once facts exist, persistent WHAT owns later changes.

## 7. Outbreak / player story / bases

Long-term world state supports pre-collapse persistent people, households, homes, jobs/workplaces, schedules, vehicles and relationships, then causal outbreak/collapse simulation. Distant populations may use coarser deterministic resolution while preserving causal state.

The playable survivor eventually inhabits a real generated-world person with identity, occupation/workplace, home/property, family/household, relationships, pets, vehicle/resources and starting circumstances where applicable.

A base is an ordinary physical world location, not a special map/mode. Multiple bases, relocation, abandonment and nomadic play remain valid.

## 8. Graphics recovery truth

The richer pre-rewrite artwork remains intact. Mature semantic art selection came from golden `TacticalTiles.gd` combining six atlases plus four directional player sprites.

Golden semantic source blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

**The selection/catalog half of that recovery is now complete in 04.** The next visual work must use the canonical Art Catalog to build focused layer renderers rather than copy draw behavior back into a monolith or extend `RebootArt.gd`.

Visible recovery is not yet claimed: the frozen Web reference still renders through deprecated reboot presentation. Ground, Structure, Prop, and Actor renderers plus a later authored visual integration area remain separate systems.

## 9. Development invariants

Canonical process:

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Global rules:

1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. One major system per implementation slice by default.
4. No fake/placeholder systems presented as complete.
5. Generator is an input to world state, not persistent reality owner.
6. Rendering never owns simulation truth.
7. Input emits semantic intent; it does not implement mechanics.
8. Art is not physics.
9. Phone/Safari is first-class.
10. Durable decisions do not live only in chat.
11. Do not wire canonical modules into deprecated reboot through temporary adapters.
12. Persistent mechanic state uses typed stable-ID domain stores rather than expanding `WorldEntityRecord` into a metadata bag.
13. Gameplay systems use WHEN for duration/order; WHEN never learns mechanic meanings.
14. Movement consumes canonical Collision and typed policy decisions rather than duplicating occupancy/condition rules.
15. Actor condition domains affect mobility through narrow provider contracts instead of being imported into locomotion/Movement.
16. Renderers consume semantic world facts through Art Catalog selections; world/generator data never stores atlas indices or texture paths.

## 10. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository state;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context index;
8. IMPLEMENTED/APPROVED active `SYSTEM_DESIGNS/*.md`;
9. current DRAFT designs;
10. compatible `MODULAR_REBUILD_MASTER_DESIGN.md` material;
11. golden history for recovered behavior.

## 11. Recommended next bounded design

**Ground Layer Renderer** is the recommended next discussion target, not authorization to implement it automatically.

Why next: it is the smallest visible consumer of the recovered Art Catalog and can prove real atlas loading/region drawing against canonical WHAT terrain without mixing walls/openings, props, actors, generation, controls, camera, lighting, or weather into the same slice.

After Ground Renderer, keep Structure Renderer, Prop/Fixture/Vegetation Renderer, Player/Actor Renderer, and an Authored Visual Test Area as separately approved systems. Do not jump directly into procedural generation or full playable-runtime replacement.
