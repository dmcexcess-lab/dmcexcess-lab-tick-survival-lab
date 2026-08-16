# Tick Survival Lab — System Design Index / Approval Ledger

This directory is the detailed durable memory for individual systems.

A major system moves through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** only through the process in `DESIGN_WORKFLOW.md`. Before using this ledger, read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md`.

## Status meanings

- **NOT DESIGNED** — known future system, no detailed design yet.
- **DRAFT** — being discussed; do not implement.
- **APPROVED** — user approved the design; implementation may begin.
- **IMPLEMENTED** — approved design is present in canonical modular source and tested.
- **SUPERSEDED** — retained for history but replaced by newer direction.
- **RECOVERY SOURCE** — historical behavior worth mining, not current architecture.

## Current canonical architecture

The current foundation is organized around **WHERE / WHAT / WHEN** rather than treating map generation as the engine. Collision and Movement are the first downstream gameplay systems consuming those foundations.

| Order | System | Status | Design source | Notes |
|---|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via child contracts** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` | Umbrella relationship realized by independently tested 00A/00B/00C modules |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` | Global `Vector2i` grid, N/E/S/W facing, whole-cell footprints, structure cells/axis |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` | Stable IDs, semantic terrain/entities, placements, mutations, revision, snapshot/restore |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` | Integer tick, deterministic queue, timed actions/phases, tactical/hard pause |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` | Type collision + sparse overrides; CLEAR/BLOCKED/UNKNOWN hypothetical footprint queries |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` | Forward/back/turn actions bridge WHERE + WHAT + Collision + WHEN with commit-time revalidation |
| 00D | Global World Planning / Generation Contract | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` | Global geography/roads/utilities/parcels/building facts before local materialization |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` | Persistent people/homes/jobs/relationships and scalable causal outbreak simulation |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` | Performance/storage mechanism over one logical world; partitions never define reality |
| old-01 | Semantic tactical map / `RaidMapSpec` | **SUPERSEDED** | `01_RAID_MAP_DATA.md` | Historical design mine; assumed separate raid maps |

## Implemented source owners

### 00A WHERE

- `game/scripts/foundation/spatial/SpatialFacing.gd`
- `game/scripts/foundation/spatial/SpatialFootprint.gd`
- `game/scripts/foundation/spatial/SpatialStructureGeometry.gd`
- `game/scripts/foundation/spatial/SpatialLayer.gd`
- `game/scripts/foundation/spatial/SpatialModel.gd`
- `game/scripts/ci/SpatialModelSmoke.gd`

### 00B WHAT

- `game/scripts/foundation/world/WorldEntityId.gd`
- `game/scripts/foundation/world/WorldEntityRecord.gd`
- `game/scripts/foundation/world/WorldPlacement.gd`
- `game/scripts/foundation/world/TerrainStore.gd`
- `game/scripts/foundation/world/EntityStore.gd`
- `game/scripts/foundation/world/PlacementStore.gd`
- `game/scripts/foundation/world/OccupancyIndex.gd`
- `game/scripts/foundation/world/WorldChange.gd`
- `game/scripts/foundation/world/WorldState.gd`
- `game/scripts/foundation/world/WorldMutationService.gd`
- `game/scripts/ci/WorldStateSmoke.gd`

### 00C WHEN

- `game/scripts/foundation/time/TickRules.gd`
- `game/scripts/foundation/time/ActionPhase.gd`
- `game/scripts/foundation/time/TimedAction.gd`
- `game/scripts/foundation/time/ScheduledEvent.gd`
- `game/scripts/foundation/time/TickEventQueue.gd`
- `game/scripts/foundation/time/TickKernel.gd`
- `game/scripts/ci/TickKernelSmoke.gd`

### 01 Collision / Spatial Query

- `game/scripts/simulation/collision/CollisionProfile.gd`
- `game/scripts/simulation/collision/CollisionCatalog.gd`
- `game/scripts/simulation/collision/CollisionOverrideState.gd`
- `game/scripts/simulation/collision/SpatialQueryResult.gd`
- `game/scripts/simulation/collision/SpatialQueryService.gd`
- `game/scripts/ci/CollisionSpatialQuerySmoke.gd`

### 02 Movement Actions

- `game/scripts/simulation/movement/MovementActionResult.gd`
- `game/scripts/simulation/movement/MovementTraversalPolicy.gd`
- `game/scripts/simulation/movement/MovementActionService.gd`
- `game/scripts/ci/MovementActionsSmoke.gd`
- `.github/workflows/movement.yml`

The canonical modules above are intentionally **not** wired into the frozen `game/scripts/reboot/` playable reference through temporary adapters. Integration waits for real neighboring canonical contracts.

## Current Movement contract in one paragraph

Movement accepts semantic forward/back/turn requests, uses Collision to validate the actor's target footprint, uses a replaceable traversal policy for terrain capability/base duration, submits a COMMITTED timed action through WHEN, and mutates WHAT only at `movement.commit` after rechecking the destination and expected origin. Destinations are not reserved: simultaneous actors may both begin toward a cell, but deterministic WHEN ordering plus commit-time revalidation allows only a still-legal action to occupy it. Backward movement preserves facing and turns validate the fully rotated footprint.

## Why generation is not the foundation

Generation is one producer of initial world state. It must use the same spatial/entity contracts as every other system. Construction/destruction/gameplay later mutate the same WHAT, and replacing the generator must not require replacing WHERE, WHEN, movement, rendering, controls or saved-world semantics.

## Later modular systems

Exact order is refined one approved design at a time.

| System | Status | Notes |
|---|---|---|
| Actor state / stance / movement capability | NOT DESIGNED | Recommended next discussion: durable/shared actor facts and movement-policy modifiers without putting them in WHAT/WHEN |
| Recovered multi-atlas Art Catalog | NOT DESIGNED | Recover exact golden `TacticalTiles.gd` semantics |
| Ground renderer | NOT DESIGNED | Reads canonical world/spatial data + ArtCatalog |
| Structure renderer | NOT DESIGNED | Walls/doors/windows; consumes WHERE structure-cell/axis contract |
| Prop/fixture/vegetation renderer | NOT DESIGNED | Whole-cell footprints/orientation; world props only |
| Player/actor renderer | NOT DESIGNED | Four directional sprites initially; shared actor semantics |
| Authored visual test area | NOT DESIGNED | Proves recovered graphics independently of procedural generation |
| Tactical camera + zoom | NOT DESIGNED | One canonical zoom owner |
| Touch/keyboard/Safari input | NOT DESIGNED | Emits semantic intents; hard-pause lifecycle requirements |
| Tactical controls UI | NOT DESIGNED | Presentation/hit regions only |
| Road network/topology | NOT DESIGNED | Global coherent network rather than independent chunk exits |
| Property/parcel planner | NOT DESIGNED | Parcels/frontage/access/site mix |
| Building/prefab placement | NOT DESIGNED | Semantic placement/transforms respecting global facts |
| Procedural room/layout | NOT DESIGNED | Room graph, circulation, doors |
| Furniture/fixture/clutter dressing | NOT DESIGNED | Purpose-aware planners, directional art semantics |
| Vegetation/utilities/civic dressing | NOT DESIGNED | Local detail respecting global utility/network facts |
| World/generator validation | NOT DESIGNED | Independent coherence/quality gates; consumes canonical diagnostics/contracts |
| Prefab authoring tools | NOT DESIGNED | Shared semantic data/art renderer; separate controller/view/storage/validation |
| Construction/destruction | DEFERRED | Persistent WHAT mutation using WHERE; bases anywhere legal |
| Base/community summary layer | NOT DESIGNED | Thin summary over physical world facts; no special base reality |
| Health/body/first aid | NOT DESIGNED | Mini-Zomboid severity/treatment model; affects capability via explicit seams |
| Needs/fatigue/temperature | NOT DESIGNED | Coarse meaningful states with real consequences |
| Vision/perception | DEFERRED | Major mood/gameplay system; consumes WHERE + WHAT; mine golden work |
| Lighting | DEFERRED | Major mood/gameplay system; mine golden work |
| Weather | DEFERRED | State/system scheduled through WHEN + separate VFX |
| Silent spatial sound | DEFERRED | Spatial events using WHERE + WHAT + WHEN; no default audible playback |
| Infected AI | DEFERRED | Emits actions using shared actor/action/perception/world contracts |
| Loot/inventory/search | DEFERRED | Persistent containers/items keyed by WHAT IDs; timed actions through WHEN |
| Combat | DEFERRED | Generic action timing + health consequences; no combat rules inside WHEN |
| Vehicles | DEFERRED | Persistent multi-cell entities using WHERE/WHAT; timed actions through WHEN |
| Old raid/extraction/session architecture | **SUPERSEDED** | No required raid/extraction/staging loop |

## Design template

Every major system design should contain:

1. status;
2. goal;
3. non-goals;
4. owner(s);
5. public contract/API;
6. data ownership;
7. allowed dependencies;
8. forbidden dependencies;
9. detailed behavior/rules;
10. edge/failure cases;
11. performance requirements;
12. Safari/mobile requirements where relevant;
13. tests/acceptance criteria;
14. recovery sources where relevant;
15. future extension seams;
16. North-star fit;
17. approved decisions with rationale.

If implementation reveals an APPROVED design cannot work without crossing a forbidden module boundary, return the design to DRAFT and obtain approval for the smallest contract change rather than patching around the boundary.
