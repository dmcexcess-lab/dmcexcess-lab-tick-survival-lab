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

| Order | System | Status | Design source | Notes |
|---|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via child contracts** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` | Umbrella realized by 00A/00B/00C |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` | Global grid/facing/whole-cell footprints/structure axis |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` | Stable IDs, semantic world facts, placement, mutation, snapshot |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` | Integer ticks, deterministic actions/events, tactical + hard pause |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` | Explicit collision + sparse overrides |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` | Forward/back/turn; commit revalidation |
| 03 | Actor Locomotion State & Movement Capability | **IMPLEMENTED** | `03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md` | Standing/crouched, timed stance, capability providers |
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` | Environment/player/living-actor art selection |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` | WHAT terrain -> Art Catalog |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` | Stable-ID OPEN/CLOSED state |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` | Walls/doors/windows + Door State |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` | Visible OBJECT entities |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` | Controlled survivor + NPC survivors + infected |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` | Stable physical primary/right + secondary/left item assignments |
| 00D | Global World Planning / Generation Contract | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` | Global geography/roads/utilities/parcels before local detail |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` | Persistent people/homes/jobs/relationships and causal outbreak |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` | Performance/storage over one logical world |
| old-01 | Semantic tactical map / `RaidMapSpec` | **SUPERSEDED** | `01_RAID_MAP_DATA.md` | Historical mine; assumed disconnected raid maps |

## Implemented source owners

### Foundation / simulation / mechanic state

- **00A WHERE:** `game/scripts/foundation/spatial/` + `SpatialModelSmoke.gd`
- **00B WHAT:** `game/scripts/foundation/world/` + `WorldStateSmoke.gd`
- **00C WHEN:** `game/scripts/foundation/time/` + `TickKernelSmoke.gd`
- **01 Collision:** `game/scripts/simulation/collision/` + `CollisionSpatialQuerySmoke.gd`
- **02 Movement:** `game/scripts/simulation/movement/` + `MovementActionsSmoke.gd`
- **03 Actor Locomotion:** `game/scripts/simulation/actors/locomotion/` + `ActorLocomotionSmoke.gd`
- **06A Door State:** `game/scripts/simulation/doors/` + `DoorStateSmoke.gd`
- **09 Actor Hand Equipment:** `game/scripts/simulation/actors/equipment/` + `ActorHandEquipmentSmoke.gd` + `.github/workflows/actor-hand-equipment.yml`

### Presentation

- **04 Art Catalog:** `game/scripts/art/`, protected/recovered art manifests, `ArtCatalogSmoke.gd`
- **05 Ground:** `GroundDrawCommand.gd`, `GroundLayerRenderer.gd`, `GroundLayerRendererSmoke.gd`
- **06 Structure:** `StructureDrawCommand.gd`, `StructureLayerRenderer.gd`, `StructureLayerRendererSmoke.gd`
- **07 Prop / Fixture / Vegetation:** `PropDrawCommand.gd`, `PropLayerRenderer.gd`, `PropLayerRendererSmoke.gd`
- **08 Player / Living Actor:** `game/assets/actor_atlas.svg`, `ActorDrawCommand.gd`, `ActorLayerRenderer.gd`, `ActorLayerRendererSmoke.gd`

The canonical modules remain intentionally separate from frozen `game/scripts/reboot/` reference code.

## Current contract summary

**WHERE** owns geometry. **WHAT** owns persistent semantic terrain/entities/placement. **WHEN** owns time/order. **Collision** answers hard occupancy. **Movement** owns discrete movement actions. **Actor Locomotion** owns standing/crouched state and movement capability composition.

**Door State** owns persistent OPEN/CLOSED truth for doors.

**09 Actor Hand Equipment State** owns only explicit survivor primary/right and secondary/left hand assignments. It references stable WHAT `item.*` entities, keeps held items physically unique across all hand assignments, distinguishes missing enrollment from explicit empty hands, and provides versioned deterministic snapshot state. It does not own Inventory, drawing, combat, lighting, timing, AI, input, or UI.

**Art Catalog** owns semantic-to-art selection only. **Ground**, **Structure**, **Prop**, and **Living Actor** renderers independently present their focused WHAT layers.

## Recommended next design

**Actor Hand Equipment Presentation — NOT DESIGNED.**

Requested target:

- recover real First Fire weapon silhouettes + secondary utility icons;
- render both held objects beside survivor actors;
- rotate held art with N/E/S/W facing;
- primary remains anatomical right, secondary anatomical left;
- north/south show both clearly;
- EAST draws secondary/left behind body and primary/right in front;
- WEST draws primary/right behind body and secondary/left in front;
- presentation reads 09 + WHAT and never mutates equipment truth.

## Later modular systems / dependency path

| System | Status | Notes |
|---|---|---|
| Actor Hand Equipment Presentation | **NOT DESIGNED — NEXT** | Held art, rotation, back-hand/body/front-hand occlusion |
| Inventory / Containment | DEFERRED / NOT DESIGNED | Real physical holdings and equip coordination |
| Authored visual test area | NOT DESIGNED | Canonical WHAT fixture |
| Tactical renderer/orchestration | NOT DESIGNED | Composes focused layers and hand passes |
| Tactical camera + zoom | NOT DESIGNED | Supplies visible window/scale |
| Touch/keyboard/Safari input | NOT DESIGNED | Semantic action intents + lifecycle hard pause |
| Tactical controls UI | NOT DESIGNED | Real touch Button/Control nodes |
| HUD / Facing Inspection | NOT DESIGNED | Recover `Looking at:` from canonical WHAT query |
| Stats / Inventory Inspector UI | NOT DESIGNED | Real data only; inspection pauses safely |
| Pause / Menu UI | NOT DESIGNED | Resume + Leave Game |
| Corpse / Decay / Contamination | NOT DESIGNED | Approved direction only |
| Door interaction / physical transition | NOT DESIGNED | WHEN + Door State + Collision coordination |
| Actor Appearance / character creator integration | NOT DESIGNED | Persistent visual identity |
| Loose-item renderer | NOT DESIGNED | Separate LOOSE_ITEM presentation |
| Health/body/first aid | NOT DESIGNED | Mini-Zomboid injury/treatment |
| Needs/fatigue/temperature | NOT DESIGNED | Coarse consequential states |
| Vision/perception | DEFERRED | Major mood/gameplay system |
| Lighting | DEFERRED | Major mood/gameplay system |
| Weather | DEFERRED | WHEN state + VFX |
| Silent spatial sound | DEFERRED | Spatial information events |
| Infected AI | DEFERRED | Canonical actor actions |
| Combat | DEFERRED | Timed actions + health consequences |
| Vehicles | DEFERRED | Persistent multi-cell entities |
| Old raid/extraction/session architecture | **SUPERSEDED** | No required raid/extraction/staging loop |

## Requested future demo UI target

When canonical composition reaches UI, it must include Safari/iPhone touch navigation, desktop keyboard equivalents, recovered `Looking at:` text, concise real stats, `STATS`, `INVENTORY`, and `MENU` buttons, safe pause during inspection/menu, and no fabricated values before their owning systems exist.

## Design rule

Every major system design must define status, goal, non-goals, owners, public contract, data ownership, dependencies, forbidden dependencies, behavior, edge cases, performance/mobile requirements, tests, recovery sources, future seams, North-star fit, and approved decisions.

If an approved implementation unexpectedly requires crossing a forbidden boundary, stop and return the design to DRAFT instead of cascading changes.
