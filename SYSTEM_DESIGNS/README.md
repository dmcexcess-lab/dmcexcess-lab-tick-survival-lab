# Tick Survival Lab — System Design Index / Approval Ledger

This directory is the durable detailed memory for individual systems.

Major systems move through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** under `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

## Status meanings

- **NOT DESIGNED** — known future system, no detailed contract yet.
- **DRAFT** — discussion only; do not implement.
- **APPROVED** — user approved; implementation may begin.
- **IMPLEMENTED** — approved design is present in canonical modular source and tested.
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
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` | Environment/player/living-actor + held-item art selection |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` | WHAT terrain -> Art Catalog |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` | Stable-ID OPEN/CLOSED state |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` | Walls/doors/windows + Door State |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` | Visible OBJECT entities |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` | Controlled survivor + NPC survivors + infected |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` | Stable primary/right + secondary/left item assignments |
| 10 | Actor Hand Equipment Presentation | **IMPLEMENTED** | `10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md` | Recovered held art, facing rotation, BACK/body/FRONT seam |
| 11 | Inventory / Containment | **IMPLEMENTED** | `11_INVENTORY_CONTAINMENT.md` | Stable direct containment, explicit containers, nested acyclic graph |
| 12 | Item Transfer / Pickup / Drop / Equip Actions | **IMPLEMENTED** | `12_ITEM_TRANSFER_ACTIONS.md` | Timed floor/hand/personal-containment transitions + derived disposition query |
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
- **09 Actor Hand Equipment:** `game/scripts/simulation/actors/equipment/` + `ActorHandEquipmentSmoke.gd`
- **11 Inventory / Containment:** `game/scripts/simulation/inventory/` + `InventoryContainmentSmoke.gd` + `.github/workflows/inventory-containment.yml`
- **12 Item Transfer Actions:** `game/scripts/simulation/items/transfer/` + `ItemTransferActionsSmoke.gd` + `.github/workflows/item-transfer-actions.yml`

### Presentation

- **04 Art Catalog:** `game/scripts/art/`, protected/recovered art manifests, `ArtCatalogSmoke.gd`
- **05 Ground:** `GroundDrawCommand.gd`, `GroundLayerRenderer.gd`, `GroundLayerRendererSmoke.gd`
- **06 Structure:** `StructureDrawCommand.gd`, `StructureLayerRenderer.gd`, `StructureLayerRendererSmoke.gd`
- **07 Prop / Fixture / Vegetation:** `PropDrawCommand.gd`, `PropLayerRenderer.gd`, `PropLayerRendererSmoke.gd`
- **08 Player / Living Actor:** `actor_atlas.svg`, `ActorDrawCommand.gd`, `ActorLayerRenderer.gd`, `ActorLayerRendererSmoke.gd`
- **10 Actor Hand Equipment Presentation:** `held_item_atlas.svg`, `ActorHandDrawCommand.gd`, `ActorHandEquipmentLayerRenderer.gd`, `ActorHandEquipmentPresentationSmoke.gd`

The canonical modules remain intentionally separate from frozen `game/scripts/reboot/` reference code.

## Current contract summary

**WHERE** owns geometry. **WHAT** owns persistent semantic terrain/entities/placement. **WHEN** owns time/order. **Collision** answers hard occupancy. **Movement** owns discrete movement actions. **Actor Locomotion** owns standing/crouched state and movement capability composition.

**Door State** owns persistent OPEN/CLOSED truth for doors.

**09 Actor Hand Equipment State** owns explicit survivor primary/right and secondary/left stable `item.*` assignments. One physical item cannot occupy multiple 09 hand assignments. 09 owns no containment, rendering, combat, lighting, timing, AI, input, or UI.

**11 Inventory / Containment** owns only direct persistent containment: `item_id -> direct_container_id`. Container capability is explicit typed enrollment. One item has at most one direct parent; nested item-containers are supported; self/ancestry cycles are rejected; direct-content versions plus global revision support stale transfer revalidation. Normal new containment requires an existing unplaced WHAT `item.*`. 11 does not import 09 and does not own pickup/drop/equip timing, capacity/encumbrance, stacking/quantity, item stats, rendering, or UI.

**12 Item Transfer Actions** is the timed coordinator over WHAT + 09 + 11 + WHEN. It adds read-only `ItemDispositionQuery`, explicit action timing policy, floor/hand/personal-container pickup/drop/equip/unequip/transfer requests, exact commit revalidation, no reservations, CANCELABLE pre-commit behavior, and public-API compensation for exceptional second-write failure. V1 rejects arbitrary world cabinets/trunks/corpses/vehicles until a real access/search/open/lock policy exists. A verified reentrant-destination guard rechecks the destination immediately after source removal so permissive low-level APIs cannot overwrite newly changed truth.

**04 Art Catalog** owns semantic-to-art selection only. **05 Ground**, **06 Structure**, **07 Prop**, and **08 Living Actor** independently present focused WHAT layers.

**10 Actor Hand Equipment Presentation** reads WHAT + 09 + 04 and renders held items through explicit BACK and FRONT passes around the actor body.

## Immediate dependency path toward the requested canonical demo

Completed prerequisites:

1. **09 Actor Hand Equipment State — IMPLEMENTED.**
2. **10 Actor Hand Equipment Presentation — IMPLEMENTED.**
3. **11 Inventory / Containment — IMPLEMENTED.**
4. **12 Item Transfer / Pickup / Drop / Equip Actions — IMPLEMENTED.**

Remaining honest-demo prerequisites:

| System | Status | Notes |
|---|---|---|
| Actor stat domains required for inspector | NOT DESIGNED | Use only canonical real state; no fake HP/stamina/etc. |
| Authored Visual Test Area | NOT DESIGNED | Real canonical WHAT fixture |
| Tactical Renderer / Orchestration | NOT DESIGNED | Ground/Structure/Prop/10-BACK/08/10-FRONT composition |
| Tactical Camera + Zoom | NOT DESIGNED | Supplies visible window/scale |
| Touch / Keyboard / Safari Input | NOT DESIGNED | Semantic intents + lifecycle hard pause |
| Tactical Controls UI | NOT DESIGNED | Real touch Button/Control nodes |
| HUD / Facing Inspection | NOT DESIGNED | Canonical `Looking at:` query |
| Stats / Inventory Inspector UI | NOT DESIGNED | Real data only; safe pause |
| Pause / Menu UI | NOT DESIGNED | Resume + Leave Game |

Recommended next design for the requested honest demo is **Actor stat domains required for inspector**, unless the user explicitly chooses to prioritize visual composition first. Existing locomotion/equipment/inventory facts should be reused; Health/Needs should only be designed to the extent real displayed stats require them.

## Other later modular systems

| System | Status | Notes |
|---|---|---|
| Container Access / Search / Open / Lock | NOT DESIGNED | Extends 12 beyond personal containers to real world storage access |
| Corpse / Decay / Contamination | NOT DESIGNED | Approved persistent corpse/contamination direction only |
| Door interaction / physical transition | NOT DESIGNED | WHEN + Door State + Collision coordination |
| Actor Appearance / character creator integration | NOT DESIGNED | Persistent visual identity |
| Loose-item renderer | NOT DESIGNED | Separate LOOSE_ITEM presentation |
| Item definitions / quantity / condition | NOT DESIGNED | Physical item properties and divisible-resource semantics |
| Capacity / weight / bulk / encumbrance | NOT DESIGNED | Transfer policy + locomotion capability seam |
| Road network/topology | NOT DESIGNED | Global coherent road truth |
| Property/parcel planner | NOT DESIGNED | Parcels/frontage/access/site mix |
| Building/prefab placement | NOT DESIGNED | Semantic placement respecting global facts |
| Procedural room/layout | NOT DESIGNED | Room graph/circulation/doors |
| Furniture/fixture/clutter dressing | NOT DESIGNED | Purpose-aware local detail |
| Vegetation/utilities/civic dressing | NOT DESIGNED | Local detail respecting global networks |
| World/generator validation | NOT DESIGNED | Independent coherence/quality gates |
| Prefab authoring tools | NOT DESIGNED | Separate DEV tooling |
| Construction/destruction | DEFERRED | Persistent WHAT mutation; bases anywhere legal |
| Base/community summary | NOT DESIGNED | Thin summary over physical world facts |
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

The eventual canonical demo must include Safari/iPhone touch navigation, desktop keyboard equivalents, recovered-style `Looking at:`, concise real actor stats, `STATS`, `INVENTORY`, and `MENU` buttons, safe pause during inspection/menu, Resume + Leave Game, and no fabricated values before their owning systems exist.

## Design rule

Every major system design must define status, goal, non-goals, owners, public contract, data ownership, dependencies, forbidden dependencies, behavior, edge cases, performance/mobile requirements, tests, recovery sources, future seams, North-star fit, and approved decisions.

If an approved implementation unexpectedly requires crossing a forbidden boundary, stop and return the design to DRAFT instead of cascading changes.
