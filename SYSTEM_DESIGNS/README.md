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
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` | Golden environmental semantics + protected player art + recovered living-actor source |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` | WHAT terrain -> Art Catalog -> visible-window ground drawing |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` | Explicit stable-ID OPEN/CLOSED state |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` | Visible walls/doors/windows; H/V axis; Door State art |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` | Visible OBJECT entities; recovered prop art |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` | Controlled survivor + NPC survivors + infected; living ACTOR only |
| 09 | Actor Hand Equipment State | **DRAFT** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` | Primary/right + secondary/left stable physical item assignments |
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
- **02 Movement:** `game/scripts/simulation/movement/` + `MovementActionsSmoke.gd`
- **03 Actor Locomotion:** `game/scripts/simulation/actors/locomotion/` + `ActorLocomotionSmoke.gd`
- **06A Door State:** `game/scripts/simulation/doors/` + `DoorStateSmoke.gd`

### Presentation

- **04 Art Catalog:** `game/scripts/art/`, protected/recovered art manifests, `ArtCatalogSmoke.gd`
- **05 Ground:** `GroundDrawCommand.gd`, `GroundLayerRenderer.gd`, `GroundLayerRendererSmoke.gd`
- **06 Structure:** `StructureDrawCommand.gd`, `StructureLayerRenderer.gd`, `StructureLayerRendererSmoke.gd`
- **07 Prop / Fixture / Vegetation:** `PropDrawCommand.gd`, `PropLayerRenderer.gd`, `PropLayerRendererSmoke.gd`
- **08 Player / Living Actor:** `game/assets/actor_atlas.svg`, `ActorDrawCommand.gd`, `ActorLayerRenderer.gd`, `ActorLayerRendererSmoke.gd`

The canonical modules remain intentionally separate from frozen `game/scripts/reboot/` reference code. Do not add compatibility adapters merely to make them visible in the old playable build.

## Current contract summary

**WHERE** owns geometry. **WHAT** owns persistent semantic terrain/entities/placement. **WHEN** owns time/order. **Collision** answers hard occupancy. **Movement** owns discrete target/commit semantics. **Actor Locomotion** owns standing/crouched state and movement capability composition.

**Door State** owns persistent OPEN/CLOSED truth for `door.<theme>` entities. Missing state is UNKNOWN; Door State does not mutate Collision or WHEN.

**Art Catalog** owns semantic-to-art selection only. World/generator data contains no atlas indices or texture paths. It exposes recovered living survivor/infected art in addition to the original environmental/player catalog without changing simulation identity.

**Ground Renderer** draws visible WHAT terrain through Art Catalog.

**Structure Renderer** draws visible WHAT STRUCTURE entities through Art Catalog + Door State.

**Prop Renderer** draws visible WHAT OBJECT entities for `prop.*`, `fixture.*`, or `vegetation.*`, one draw per stable entity, deterministic overlap, no collision ownership.

**Player / Living Actor Renderer** draws visible WHAT ACTOR entities for exact `actor.survivor` and `actor.infected`. Controlled role is stable-ID presentation state; NPC variants are deterministic; no AI/Health/Inventory/Corpse ownership.

## Active DRAFT — 09 Actor Hand Equipment State

The user requested real visible objects in survivor primary/right and secondary/left hands. 09 is the prerequisite mechanic truth before held-item presentation.

Proposed contract:

- explicit survivor enrollment;
- `PRIMARY_RIGHT` and `SECONDARY_LEFT` semantic hand slots;
- stable WHAT `item.*` IDs, not item-name strings;
- held items normally tactically unplaced;
- one physical item cannot be assigned to multiple hands/actors;
- missing record is distinct from enrolled empty hands;
- versioned deterministic snapshot/change state;
- no Art/Render/Inventory/Combat/Health/WHEN/AI/Input/UI ownership.

**DRAFT means no production implementation yet.**

## Later modular systems / updated order

The latest user request changes the immediate presentation path. Exact order is still refined one approved design at a time.

| System | Status | Notes |
|---|---|---|
| Actor Hand Equipment Presentation | NOT DESIGNED | Next after 09; recovered held-item silhouettes/icons, facing rotation, E/W back-hand/body/front-hand occlusion |
| Inventory / Containment | DEFERRED / NOT DESIGNED | Real stable physical holdings; required before honest inventory UI/equip coordination |
| Authored visual test area | NOT DESIGNED | Real canonical WHAT fixture; now follows hand/equipment prerequisite work |
| Tactical renderer/orchestration | NOT DESIGNED | Composes focused layers; must support back-hand -> actor -> front-hand ordering |
| Tactical camera + zoom | NOT DESIGNED | Supplies visible cell window/scale; one zoom owner |
| Touch/keyboard/Safari input | NOT DESIGNED | Emits semantic movement/stance intents; lifecycle hard-pause integration |
| Tactical controls UI | NOT DESIGNED | Real touch Button/Control nodes; Safari must not be keyboard-only |
| HUD / Facing Inspection | NOT DESIGNED | Recover `Looking at:` as canonical WHAT query; concise real stats only |
| Stats / Inventory Inspector UI | NOT DESIGNED | Buttons/modal inspection over implemented data; opening safely pauses simulation |
| Pause / Menu UI | NOT DESIGNED | Resume + Leave Game; Web prefers history return with safe fallback |
| Corpse / Decay / Contamination | NOT DESIGNED | Approved direction only; exact contract still needed |
| Door interaction / physical transition | NOT DESIGNED | Future WHEN action coordinating Door State + Collision |
| Actor Appearance / character creator integration | NOT DESIGNED | Persistent visual identity can replace deterministic NPC default |
| Loose-item renderer | NOT DESIGNED | Separate LOOSE_ITEM presentation |
| Road network/topology | NOT DESIGNED | Global coherent road truth |
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
| Infected AI | DEFERRED | Emits shared actions through canonical contracts |
| Combat | DEFERRED | Timed actions + health consequences |
| Vehicles | DEFERRED | Persistent multi-cell entities; separate vehicle rendering/behavior |
| Old raid/extraction/session architecture | **SUPERSEDED** | No required raid/extraction/staging loop |

## Requested future demo UI target

When the canonical demo reaches UI composition, it must include:

- Safari/iPhone touch navigation buttons, not keyboard-only controls;
- recovered-style `Looking at:` HUD line;
- concise real actor stats;
- `STATS`, `INVENTORY`, and `MENU` buttons;
- detailed Stats/Inventory inspection that hard-pauses safely;
- menu with Resume and Leave Game;
- no fake HP/stamina/carry/inventory values before owning systems exist.

First Fire `FFTacticalVisuals.gd` / tactical atlas are valid same-owner recovery sources for held-item art. Golden Tick `MapPreview.gd` is a recovery source for the `Looking at:` concept and pause-menu behavior. First Fire `FFInspector.gd` is a recovery source for mobile-friendly scrollable inspection patterns. Do not restore those old runtime architectures.

## Why generation is not the foundation

Generation is one producer of initial WHAT using WHERE. Construction/destruction/gameplay later mutate the same persistent world. Replacing generation must not require replacing spatial, timing, collision, movement, actor capability, door state, art, rendering, controls, or save semantics.

## Design template

Every major system design should contain: status, goal, non-goals, owners, public contract, data ownership, dependencies, forbidden dependencies, behavior/rules, edge cases, performance/mobile requirements, tests, recovery sources, future extension seams, North-star fit and approved decisions.

If implementation reveals an APPROVED design cannot work without crossing a forbidden boundary, return it to DRAFT and obtain approval for the smallest contract change rather than patching around the boundary.
