# Tick Survival Lab — System Design Index / Approval Ledger

Major systems move through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** under `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

## Current canonical architecture

| Order | System | Status | Design source |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` |
| 03 | Actor Locomotion / Movement Capability | **IMPLEMENTED** | `03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md` |
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` |
| 07A | Prop Art Orientation / Facing-Aware Rotation | **IMPLEMENTED** | `07A_PROP_ART_ORIENTATION.md` |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` |
| 10 | Actor Hand Equipment Presentation | **IMPLEMENTED** | `10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md` |
| 11 | Inventory / Containment | **IMPLEMENTED** | `11_INVENTORY_CONTAINMENT.md` |
| 12 | Item Transfer / Pickup / Drop / Equip Actions | **IMPLEMENTED** | `12_ITEM_TRANSFER_ACTIONS.md` |
| 13 | Actor Stats / Status Architecture | **IMPLEMENTED via children** | `13_ACTOR_STATS_STATUS_ARCHITECTURE.md` |
| 13A | Actor Health / Injury | **IMPLEMENTED** | `13A_ACTOR_HEALTH_INJURY.md` |
| 13B | Actor Needs / Rest | **IMPLEMENTED** | `13B_ACTOR_NEEDS_REST.md` |
| 13C | Actor Skills | **IMPLEMENTED** | `13C_ACTOR_SKILLS.md` |
| 13D | Item Physical Properties | **IMPLEMENTED** | `13D_ITEM_PHYSICAL_PROPERTIES.md` |
| 13E | Actor Carry / Encumbrance | **IMPLEMENTED** | `13E_ACTOR_CARRY_ENCUMBRANCE.md` |
| 13F | Actor Moodlets / Status Derivation | **IMPLEMENTED** | `13F_ACTOR_MOODLETS.md` |
| 14 | Canonical Playable Demo Integration | **IMPLEMENTED** | `14_CANONICAL_PLAYABLE_DEMO.md` |
| 15 | Canonical HUD / Facing Inspection | **IMPLEMENTED** | `15_CANONICAL_HUD_FACING_INSPECTION.md` |
| 16 | Canonical Player Shell / Inspectors / Stance | **IMPLEMENTED** | `16_CANONICAL_PLAYER_SHELL.md` |
| 17 | Run / Damage-Interruptible Walking | **IMPLEMENTED** | `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` |
| 17A | Movement Exertion / Encumbrance / Run Impact Revision | **IMPLEMENTED** | `17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md` |
| 17A.1 | Overweight Walk Fatigue / Absolute Carry Ceiling Correction | **IMPLEMENTED** | `17A1_OVERWEIGHT_WALK_FATIGUE_HARD_CARRY_LIMIT.md` |
| 18 | Door Interaction / Automatic Passage | **IMPLEMENTED** | `18_DOOR_INTERACTION_PASSAGE.md` |
| 19 | Local Building Generation / Archetype Critique Lab | **IMPLEMENTED** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
| 00D | Global World Planning / Generation | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## Prop art orientation truth

System 07A now consumes the N/E/S/W facing already preserved in WHAT object placement.

- recovered indoor/furniture/retail/industrial prop art has presentation-only native-facing metadata;
- current recovered directional groups are authored native SOUTH/down;
- Prop Renderer rotates those sprites in 90-degree increments around the cell center to match WHAT facing;
- sinks, shelves, beds, sofas, counters, appliances and similar furniture therefore face their semantic placement direction;
- nondirectional art such as vegetation remains unrotated;
- generator/world/collision truth is unchanged.

## System 19 current archetype library

### Accepted saved baseline

`residential.trailer.singlewide` **v2** — Trailer Candidate 002.

- 5×12 shell / 3-cell usable width;
- light plaster exterior;
- 3×4 living/kitchen, 3×2 bathroom, 3×2 bedroom;
- four windows / three doors;
- accepted by the user on 2026-08-17 and preserved by CI.

### Current live critique candidate

`residential.house.farm_small` **v1** — Farmhouse Candidate 001.

- 13×13 shell;
- exact 5×5 living room;
- exact 3×3 kitchen, two bedrooms and bathroom;
- open middle circulation/dining band;
- light plaster exterior;
- five doors / seven windows;
- restrained domestic furniture;
- deterministic rotation and validated circulation.

The live caller is a fixed **15×15 one-screen** lot at **32 px/cell**. Camera remains deferred.

## Door interaction truth

- Walk through eligible CLOSED door -> opens at Walk commit.
- damage-canceled Walk -> door stays CLOSED.
- Run through eligible CLOSED door -> opens during stride, emits LOUD semantic passage, no door-impact HP damage.
- tap/click eligible OPEN adjacent door while **facing it** -> 3-tick CANCELABLE close.
- wrong-facing close costs zero and requires normal turn actions first.
- future long-tap/right-click interaction menu remains reserved.

## Immediate next path

1. User critiques Farmhouse Candidate 001, now with facing-aware furniture presentation.
2. Convert useful critique into farmhouse archetype rules.
3. Keep accepted Trailer v2 unchanged.
4. Add further building archetypes under System 19.
5. Add camera/larger local play space only when multiple simultaneous properties exceed the one-screen critique lab.

## Verification

Farmhouse Candidate 001 first green code candidate:

- SHA `65a951bc1d38c055c17cbcfcd496a59cb30727c9`;
- Local Building Generation run `32007785922`: SUCCESS.

System 07A first green code candidate:

- SHA `6a41dd24a2fa0a594c14ef83ea2ba1015b333124`;
- Prop Fixture Vegetation Renderer run `32008973352`: SUCCESS.

Exact documentation-promotion SHA must pass the dedicated Prop/07A contract, System 19 contract and Pages before completion is claimed.

## Design rule

Every major system keeps a focused owner/public contract. System 19 shared validation is structural/generic; archetype-specific room programs belong to focused archetype owners/tests. Art-native orientation metadata is presentation truth only; generator/world facing remains semantic world truth. If implementation unexpectedly requires crossing a forbidden boundary, return the design to review rather than cascading a patch.
