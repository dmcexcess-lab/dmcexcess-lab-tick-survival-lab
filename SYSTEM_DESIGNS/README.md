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
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` | Environment/player/living-actor + additive held-item art selection |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` | WHAT terrain -> Art Catalog |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` | Stable-ID OPEN/CLOSED state |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` | Walls/doors/windows + Door State |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` | Visible OBJECT entities |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` | Controlled survivor + NPC survivors + infected |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` | Stable physical primary/right + secondary/left item assignments |
| 10 | Actor Hand Equipment Presentation | **IMPLEMENTED** | `10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md` | Recovered held art, facing rotation, BACK/body/FRONT occlusion seam |
| 11 | Inventory / Containment | **DRAFT** | `11_INVENTORY_CONTAINMENT.md` | Stable physical contained-item graph; awaiting explicit approval |
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
- **10 Actor Hand Equipment Presentation:** `game/assets/held_item_atlas.svg`, `ActorHandDrawCommand.gd`, `ActorHandEquipmentLayerRenderer.gd`, `ActorHandEquipmentPresentationSmoke.gd`

The canonical modules remain intentionally separate from frozen `game/scripts/reboot/` reference code.

## Current contract summary

**WHERE** owns geometry. **WHAT** owns persistent semantic terrain/entities/placement. **WHEN** owns time/order. **Collision** answers hard occupancy. **Movement** owns discrete movement actions. **Actor Locomotion** owns standing/crouched state and movement capability composition.

**Door State** owns persistent OPEN/CLOSED truth for doors.

**09 Actor Hand Equipment State** owns explicit survivor primary/right and secondary/left hand assignments using stable WHAT `item.*` IDs. One physical item cannot occupy multiple hands/actors. Missing enrollment differs from explicit empty hands. 09 does not own Inventory, drawing, combat, lighting, timing, AI, input, or UI.

**04 Art Catalog** owns semantic-to-art selection only. It now includes the separately recovered `actor_atlas.svg` and `held_item_atlas.svg` alongside the protected environmental/player baseline. The held-item mapping is presentation metadata only and defines no gameplay item stats.

**05 Ground**, **06 Structure**, **07 Prop**, and **08 Living Actor** renderers independently present focused WHAT layers.

**10 Actor Hand Equipment Presentation** reads WHAT + 09 + 04 and draws stable held items through explicit `BACK` and `FRONT` passes. It preserves anatomical primary/right and secondary/left roles, EAST-native recovered art rotation, historical proportional hand offsets, and E/W far-hand occlusion. It does not modify 08 or 09.

**11 Inventory / Containment is DRAFT only.** Proposed containment truth is a stable `item_id -> direct_container_id` relationship with explicit container enrollment, one parent per item, nested item-containers, cycle rejection, deterministic versioned snapshot state, and normal validation that newly contained items are tactically unplaced. It deliberately does not import 09 or own cross-domain pickup/drop/equip actions, weight/capacity, stacking/quantity, UI, or item gameplay stats.

## Immediate dependency path from the requested canonical demo

The user wants the eventual visible canonical demo to include real held equipment, Safari/iPhone navigation buttons, `Looking at:`, real concise stats, detailed Stats/Inventory inspection, and a hard-pause Menu with Resume/Leave Game.

Completed prerequisites:

1. **09 Actor Hand Equipment State — IMPLEMENTED.**
2. **10 Actor Hand Equipment Presentation — IMPLEMENTED.**

Current design gate:

3. **11 Inventory / Containment — DRAFT, awaiting explicit approval.** It is the real persistent holdings prerequisite. Implementation is prohibited until approved.

After 11 is implemented, likely bounded follow-ups include an explicit **Item Transfer / Pickup / Drop / Equip Actions** coordinator using WHAT + 09 + 11 + WHEN, then the remaining honest-demo prerequisites below.

| System | Status | Notes |
|---|---|---|
| Actor stat domains required for inspector | NOT DESIGNED | Use only canonical real state; do not fabricate HP/stamina/etc. |
| Authored visual test area | NOT DESIGNED | Real canonical WHAT fixture |
| Tactical renderer/orchestration | NOT DESIGNED | Composes focused layers including 10 BACK -> 08 Actor -> 10 FRONT |
| Tactical camera + zoom | NOT DESIGNED | Supplies visible window/scale |
| Touch/keyboard/Safari input | NOT DESIGNED | Semantic movement/stance intents + lifecycle hard pause |
| Tactical controls UI | NOT DESIGNED | Real touch Button/Control nodes |
| HUD / Facing Inspection | NOT DESIGNED | Recover `Looking at:` as canonical WHAT query |
| Stats / Inventory Inspector UI | NOT DESIGNED | Real data only; opening pauses safely |
| Pause / Menu UI | NOT DESIGNED | Resume + Leave Game; Web best-effort history return with safe fallback |

Later slices may combine only when their explicit contracts prove they are truly one coherent owner. None should be hidden inside a monolithic demo scene.

## Other later modular systems

| System | Status | Notes |
|---|---|---|
| Item Transfer / Pickup / Drop / Equip Actions | NOT DESIGNED | Future cross-domain physical transition coordinator over WHAT + 09 + 11 + WHEN |
| Corpse / Decay / Contamination | NOT DESIGNED | Approved persistent corpse/contamination direction only |
| Door interaction / physical transition | NOT DESIGNED | WHEN + Door State + Collision coordination |
| Actor Appearance / character creator integration | NOT DESIGNED | Persistent visual identity |
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
| Health/body/first aid | NOT DESIGNED | Mini-Zomboid injury/treatment; future capability provider |
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

When canonical composition reaches UI, it must include:

- Safari/iPhone touch navigation, not keyboard-only controls;
- desktop keyboard equivalents;
- recovered-style `Looking at:` HUD line;
- concise real actor stats only;
- `STATS`, `INVENTORY`, and `MENU` buttons;
- Stats/Inventory/Menu paths that hard-pause safely;
- Menu with Resume and Leave Game;
- no fake HP/stamina/carry/inventory values before their owning systems exist.

First Fire tactical visuals/art are valid same-owner recovery sources for held-item art. Golden Tick `MapPreview.gd` remains a recovery source for `Looking at:` and pause-menu behavior. First Fire `FFInspector.gd` remains a recovery source for touch-friendly scrollable inspection patterns. Do not restore those runtime architectures.

## Design rule

Every major system design must define status, goal, non-goals, owners, public contract, data ownership, dependencies, forbidden dependencies, behavior, edge cases, performance/mobile requirements, tests, recovery sources, future seams, North-star fit, and approved decisions.

If an approved implementation unexpectedly requires crossing a forbidden boundary, stop and return it to DRAFT instead of cascading changes.
