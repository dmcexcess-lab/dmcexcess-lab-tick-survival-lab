# Tick Survival Lab — System Design Index / Approval Ledger

This directory is the durable detailed memory for individual systems.

A major system moves through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** only through `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

## Status meanings

- **NOT DESIGNED** — known future system, no detailed design yet.
- **DRAFT** — under discussion; do not implement.
- **APPROVED** — user approved; implementation may begin.
- **IMPLEMENTED** — approved design exists in canonical modular source and is tested.
- **SUPERSEDED** — historical design replaced by newer direction.
- **RECOVERY SOURCE** — historical behavior worth mining, not current architecture.

## Current canonical architecture

The canonical simulation stack is **WHERE / WHAT / WHEN**, followed by focused downstream physics/action/actor systems. Generation is not the engine.

| Order | System | Status | Design source | Notes |
|---|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via child contracts** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` | Umbrella relationship realized by 00A/00B/00C |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` | Global grid/facing/whole-cell footprints/structure axis |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` | Stable IDs, semantic world facts, placement, mutation, snapshot |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` | Integer ticks, deterministic actions/events, tactical + hard pause |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` | Explicit type collision + sparse overrides; CLEAR/BLOCKED/UNKNOWN queries |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` | Forward/back/turn bridge; typed movement policy; commit-time revalidation |
| 03 | Actor Locomotion State & Movement Capability | **IMPLEMENTED** | `03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md` | Standing/crouched state, timed stance, capability providers, actor-aware Movement policy |
| 00D | Global World Planning / Generation Contract | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` | Global geography/roads/utilities/parcels before local detail |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` | Persistent people/homes/jobs/relationships and causal outbreak |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` | Performance/storage over one logical world |
| old-01 | Semantic tactical map / `RaidMapSpec` | **SUPERSEDED** | `01_RAID_MAP_DATA.md` | Historical mine; assumed disconnected raid maps |

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

- `game/scripts/simulation/movement/MovementPolicyDecision.gd`
- `game/scripts/simulation/movement/MovementActionResult.gd`
- `game/scripts/simulation/movement/MovementTraversalPolicy.gd`
- `game/scripts/simulation/movement/MovementActionService.gd`
- `game/scripts/ci/MovementActionsSmoke.gd`
- `.github/workflows/movement.yml`

### 03 Actor Locomotion State & Movement Capability

- `game/scripts/simulation/actors/locomotion/ActorStance.gd`
- `game/scripts/simulation/actors/locomotion/ActorLocomotionRecord.gd`
- `game/scripts/simulation/actors/locomotion/ActorLocomotionState.gd`
- `game/scripts/simulation/actors/locomotion/ActorLocomotionMutationService.gd`
- `game/scripts/simulation/actors/locomotion/ActorMovementCapabilityDecision.gd`
- `game/scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd`
- `game/scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd`
- `game/scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd`
- `game/scripts/simulation/actors/locomotion/ActorStanceActionResult.gd`
- `game/scripts/simulation/actors/locomotion/ActorStanceActionService.gd`
- `game/scripts/ci/ActorLocomotionSmoke.gd`
- `.github/workflows/actor-locomotion.yml`

The canonical modules above remain intentionally separate from frozen `game/scripts/reboot/` reference code. Do not add compatibility adapters simply to make them visible in the old playable build.

## Current downstream contract summary

**Collision** answers hard occupancy. **Movement** owns discrete target/commit semantics and consumes a typed replaceable movement policy. **Actor Locomotion** owns standing/crouched state and actor-specific capability composition. **WHEN** owns the committed schedule but knows none of these mechanic meanings. **WHAT** owns physical placement but not movement legality or stance.

Movement destinations are not reserved. Actor capability is checked at request and commit. A newly blocked condition can fail the physical commit after elapsed time; a newly slower-but-still-allowed condition affects the next action instead of stretching an already scheduled one.

## Why generation is not the foundation

Generation is one producer of initial WHAT using WHERE. Construction/destruction/gameplay later mutate the same persistent world. Replacing generation must not require replacing spatial, timing, collision, movement, actor capability, rendering, controls or save semantics.

## Later modular systems

Exact order is refined one approved design at a time.

| System | Status | Notes |
|---|---|---|
| Recovered multi-atlas Art Catalog | NOT DESIGNED | **Recommended next discussion**; recover exact golden `TacticalTiles.gd` semantic selection |
| Ground renderer | NOT DESIGNED | Reads canonical world/spatial data + Art Catalog |
| Structure renderer | NOT DESIGNED | Walls/doors/windows using WHERE structure-cell/axis contract |
| Prop/fixture/vegetation renderer | NOT DESIGNED | Whole-cell semantic props/orientation |
| Player/actor renderer | NOT DESIGNED | Four directional sprites initially; consumes WHAT + stance/facing facts |
| Authored visual test area | NOT DESIGNED | Proves recovered graphics without procedural generation |
| Tactical camera + zoom | NOT DESIGNED | One canonical zoom owner |
| Touch/keyboard/Safari input | NOT DESIGNED | Emits semantic movement/stance intents; lifecycle hard-pause integration |
| Tactical controls UI | NOT DESIGNED | Presentation/hit regions only |
| Road network/topology | NOT DESIGNED | Global coherent network |
| Property/parcel planner | NOT DESIGNED | Parcels/frontage/access/site mix |
| Building/prefab placement | NOT DESIGNED | Semantic placement respecting global facts |
| Procedural room/layout | NOT DESIGNED | Room graph/circulation/doors |
| Furniture/fixture/clutter dressing | NOT DESIGNED | Purpose-aware local detail |
| Vegetation/utilities/civic dressing | NOT DESIGNED | Local detail respecting global networks |
| World/generator validation | NOT DESIGNED | Independent coherence/quality gates |
| Prefab authoring tools | NOT DESIGNED | Canonical semantic data/art renderer with separate DEV tooling |
| Construction/destruction | DEFERRED | Persistent WHAT mutation; bases anywhere legal |
| Base/community summary | NOT DESIGNED | Thin summary over physical world facts |
| Health/body/first aid | NOT DESIGNED | Mini-Zomboid injury/treatment; future mobility provider |
| Needs/fatigue/temperature | NOT DESIGNED | Coarse consequential states; future mobility provider |
| Vision/perception | DEFERRED | Major mood/gameplay system; mine golden work |
| Lighting | DEFERRED | Major mood/gameplay system; mine golden work |
| Weather | DEFERRED | WHEN-scheduled state + separate VFX |
| Silent spatial sound | DEFERRED | Spatial events; no default audible playback |
| Infected AI | DEFERRED | Emits shared actions via actor/perception/world contracts |
| Loot/inventory/search | DEFERRED | Stable-ID physical state; timed actions through WHEN; future encumbrance provider |
| Combat | DEFERRED | Timed actions + health consequences |
| Vehicles | DEFERRED | Persistent multi-cell entities; timed movement/travel |
| Old raid/extraction/session architecture | **SUPERSEDED** | No required raid/extraction/staging loop |

## Design template

Every major system design should contain: status, goal, non-goals, owners, public contract, data ownership, dependencies, forbidden dependencies, behavior/rules, edge cases, performance/mobile requirements, tests, recovery sources, future extension seams, North-star fit and approved decisions.

If implementation reveals an APPROVED design cannot work without crossing a forbidden boundary, return it to DRAFT and obtain approval for the smallest contract change rather than patching around the boundary.
