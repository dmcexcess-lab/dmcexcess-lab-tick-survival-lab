# Tick Survival Lab — System Design Index / Approval Ledger

This directory is the durable detailed memory for individual systems.

A major system moves through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** through `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

## Status meanings

- **NOT DESIGNED** — known future system, no detailed design yet.
- **DRAFT** — under discussion; do not implement.
- **APPROVED** — user approved; implementation may begin.
- **IMPLEMENTED** — approved design exists in canonical modular source and is tested.
- **SUPERSEDED** — historical design replaced by newer direction.
- **RECOVERY SOURCE** — historical behavior worth mining, not current architecture.

## Current canonical architecture

The canonical simulation stack is **WHERE / WHAT / WHEN**, followed by focused physics/action/actor/mechanic systems and independently replaceable presentation systems. Generation is not the engine.

| Order | System | Status | Design source | Notes |
|---|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via child contracts** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` | Umbrella realized by 00A/00B/00C |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` | Global grid/facing/whole-cell footprints/structure axis |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` | Stable IDs, semantic world facts, placement, mutation, snapshot |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` | Integer ticks, deterministic actions/events, tactical + hard pause |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` | Explicit collision + sparse overrides; CLEAR/BLOCKED/UNKNOWN |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` | Forward/back/turn; typed policy; commit revalidation |
| 03 | Actor Locomotion State & Movement Capability | **IMPLEMENTED** | `03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md` | Standing/crouched, timed stance, capability providers |
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` | Golden semantic art descriptors/topology/asset gate |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` | WHAT terrain -> Art Catalog -> visible-window ground drawing |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` | Explicit stable-ID OPEN/CLOSED state, UNKNOWN on missing, versioned persistence |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` | Visible walls/doors/windows; H/V axis; Door State-driven open/closed art |
| 07 | Prop / Fixture / Vegetation Renderer | **DRAFT** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` | OBJECT-only visible rendering; recovered prop art; one draw per entity anchor |
| 00D | Global World Planning / Generation Contract | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` | Global geography/roads/utilities/parcels before local detail |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` | Persistent people/homes/jobs/relationships and causal outbreak |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` | Performance/storage over one logical world |
| old-01 | Semantic tactical map / `RaidMapSpec` | **SUPERSEDED** | `01_RAID_MAP_DATA.md` | Historical mine; assumed disconnected raid maps |

## Implemented source owners

### Foundation and simulation

- **00A WHERE:** `game/scripts/foundation/spatial/` + `SpatialModelSmoke.gd`
- **00B WHAT:** `game/scripts/foundation/world/` + `WorldStateSmoke.gd`
- **00C WHEN:** `game/scripts/foundation/time/` + `TickKernelSmoke.gd`
- **01 Collision:** `game/scripts/simulation/collision/` + `CollisionSpatialQuerySmoke.gd`
- **02 Movement:** `game/scripts/simulation/movement/` + `MovementActionsSmoke.gd` + `.github/workflows/movement.yml`
- **03 Actor Locomotion:** `game/scripts/simulation/actors/locomotion/` + `ActorLocomotionSmoke.gd` + `.github/workflows/actor-locomotion.yml`
- **06A Door State:**
  - `game/scripts/simulation/doors/DoorStateValue.gd`
  - `DoorStateRecord.gd`
  - `DoorStateStore.gd`
  - `DoorStateMutationService.gd`
  - `game/scripts/ci/DoorStateSmoke.gd`
  - `.github/workflows/door-state.yml`

### Presentation

**04 Art Catalog**

- `game/scripts/art/ArtSource.gd`
- `game/scripts/art/ArtSelection.gd`
- `game/scripts/art/ArtBaselineManifest.gd`
- `game/scripts/art/RoadArtTopology.gd`
- `game/scripts/art/ArtCatalog.gd`
- `game/scripts/ci/ArtCatalogSmoke.gd`
- `.github/workflows/art-catalog.yml`

**05 Ground Layer Renderer**

- `game/scripts/render/GroundDrawCommand.gd`
- `game/scripts/render/GroundLayerRenderer.gd`
- `game/scripts/ci/GroundLayerRendererSmoke.gd`
- `.github/workflows/ground-renderer.yml`

**06 Structure Layer Renderer**

- `game/scripts/render/StructureDrawCommand.gd`
- `game/scripts/render/StructureLayerRenderer.gd`
- `game/scripts/ci/StructureLayerRendererSmoke.gd`
- `.github/workflows/structure-renderer.yml`

The canonical modules remain intentionally separate from frozen `game/scripts/reboot/` reference code. Do not add compatibility adapters merely to make them visible in the old playable build.

## Current contract summary

**WHERE** owns geometry. **WHAT** owns persistent semantic terrain/entities/placement. **WHEN** owns time/order. **Collision** answers hard occupancy. **Movement** owns discrete target/commit semantics. **Actor Locomotion** owns standing/crouched state and movement capability composition.

**Door State** owns the persistent OPEN/CLOSED fact for canonical `door.<theme>` entities. Missing state is UNKNOWN, initial state must be explicit, records are stable-ID keyed/versioned/snapshot-safe, and Door State does not mutate Collision or WHEN.

**Art Catalog** owns semantic-to-art selection only. World/generator data contains no atlas indices/texture paths.

**Ground Renderer** reads WHAT terrain, uses Art Catalog selections, draws only a supplied visible global-cell window, derives generic local road/dirt-road/sidewalk presentation topology, and reacts only to topology-relevant terrain/view/reset invalidation.

**Structure Renderer** reads visible WHAT STRUCTURE occupancy, Art Catalog, and Door State. It renders `wall.<theme>`, `door.<theme>`, and `window.<theme>`, requires canonical H/V structure axis, uses distinct OPEN/CLOSED door art, and treats missing Door State/invalid content as diagnostics rather than plausible fallback.

**07 Prop / Fixture / Vegetation Renderer is DRAFT.** Proposed contract: read only visible WHAT `OBJECT` occupancy; recognize `prop.*`, `fixture.*`, and `vegetation.*`; resolve all through recovered `ArtCatalog.resolve_prop()`; deduplicate multi-cell occupancy to one command per stable entity; preserve facing/footprint facts without inventing current rotation or multi-cell art; draw the recovered one-cell sprite at the entity anchor; and keep collision, state, generation, inventory, camera/input, and other render layers out.

## Why generation is not the foundation

Generation is one producer of initial WHAT using WHERE. Construction/destruction/gameplay later mutate the same persistent world. Replacing generation must not require replacing spatial, timing, collision, movement, actor capability, door state, art, rendering, controls, or save semantics.

## Later modular systems

Exact order is refined one approved design at a time.

| System | Status | Notes |
|---|---|---|
| Door interaction / physical transition | NOT DESIGNED | Future WHEN action coordinating Door State + Collision at commit |
| Player/actor renderer | NOT DESIGNED | Four directional sprites initially; consumes WHAT/facing/stance + Art Catalog |
| Authored visual test area | NOT DESIGNED | Proves recovered graphics without procedural generation |
| Tactical renderer/orchestration | NOT DESIGNED | Composes focused render layers only; no layer internals |
| Tactical camera + zoom | NOT DESIGNED | Supplies visible cell window/scale; one zoom owner |
| Touch/keyboard/Safari input | NOT DESIGNED | Emits semantic movement/stance intents; lifecycle hard-pause integration |
| Tactical controls UI | NOT DESIGNED | Presentation/hit regions only |
| Road network/topology | NOT DESIGNED | Global coherent road truth; future road-class metadata seam |
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
| Loot/inventory/search | DEFERRED | Stable-ID physical state; timed actions; future encumbrance provider |
| Combat | DEFERRED | Timed actions + health consequences |
| Vehicles | DEFERRED | Persistent multi-cell entities; timed movement/travel |
| Old raid/extraction/session architecture | **SUPERSEDED** | No required raid/extraction/staging loop |

## Design template

Every major system design should contain: status, goal, non-goals, owners, public contract, data ownership, dependencies, forbidden dependencies, behavior/rules, edge cases, performance/mobile requirements, tests, recovery sources, future extension seams, North-star fit and approved decisions.

If implementation reveals an APPROVED design cannot work without crossing a forbidden boundary, return it to DRAFT and obtain approval for the smallest contract change rather than patching around the boundary.
