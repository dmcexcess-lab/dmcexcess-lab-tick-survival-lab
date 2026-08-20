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
| 20 | Local Area / Parcel Generation | **DRAFT** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 00D | Global World Planning / Generation | **NOT DESIGNED** | future design; listed path is not yet present |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |
| 00F | Streaming / Materialization | **NOT DESIGNED** | future design |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## Current generation stack

### System 19 — implemented building/property archetypes

Current registry:

- `residential.trailer.singlewide` v2 — accepted protected baseline;
- `residential.house.farm_small` v2 — accepted protected baseline;
- `residential.house.farm_large` v4 — preserved Candidate 004;
- `residential.house.compact_laundry` v1 — accepted protected baseline;
- `commercial.gas_station.small` v1 — current live critique candidate.

System 19 receives an already-chosen stable instance ID, archetype, seed, envelope, orientation and frontage. It does not choose roads/parcels/towns.

### System 20 — current design discussion

`20_LOCAL_AREA_PARCEL_GENERATION.md` is **DRAFT**.

Draft direction:

- globally coordinated local-area planning, not streaming-chunk generation;
- higher-level world planning supplies major cross-boundary road constraints;
- System 20 may create minor roads, parcels, legal access, land-use/property zones and exact System 19 building requests;
- settlement/area morphology profile is separate from environment/ecology profile;
- first profile target is `rural.crossroads` with a `temperate.rural` environment candidate;
- Candidate 001 proposes a 256×256 planning area with substantial wilderness/agricultural land, sparse houses/farmsteads, a tiny denser crossroads center, gas station and exactly one signalized intersection;
- missing barns/small stores are not faked; parcels may remain vacant until real System 19 archetypes exist;
- no implementation is allowed until the draft is explicitly approved.

## Prop art orientation truth

System 07A consumes the N/E/S/W facing preserved in WHAT placement. Recovered directional props are rotated by presentation rules only; generator/world facing remains semantic truth and art remains separate from physics.

## Door interaction truth

- Walk through eligible CLOSED door -> opens at Walk commit.
- damage-canceled Walk -> door stays CLOSED.
- Run through eligible CLOSED door -> opens during stride, emits LOUD semantic passage, no normal door-impact HP damage.
- tap/click eligible OPEN adjacent door while facing it -> 3-tick CANCELABLE close.

## Immediate next path

1. Review/revise `20_LOCAL_AREA_PARCEL_GENERATION.md`.
2. Keep System 20 status DRAFT until explicit approval.
3. Preserve all accepted/preserved System 19 archetypes while area planning is designed.
4. After approval, implement the first bounded System 20 planning slice before adding unrelated camera/streaming/population work.

## Design rule

Every major system keeps a focused owner/public contract. Global planning owns cross-region coherence; System 20 refines caller-constrained local areas; System 19 owns building/property internals; WHAT owns runtime persistence after materialization. If implementation requires a forbidden boundary, return the design to review instead of cascading a patch.
