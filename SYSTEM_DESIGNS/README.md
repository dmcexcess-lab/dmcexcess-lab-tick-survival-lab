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
| 19 | Local Building Generation / Building Grammar | **IMPLEMENTED — FINALIZED** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
| 20 | Local Area / Parcel Generation + Initial Materialization | **IMPLEMENTED — CANDIDATE 001** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 00D | Global World Planning / Generation | **NOT DESIGNED** | future design |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |
| 00F | Streaming / Save Materialization Strategy | **NOT DESIGNED** | future design |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## System 19 finalized building grammar

Protected current library:

- `residential.trailer.singlewide` v2;
- `residential.house.farm_small` v2;
- `residential.house.farm_large` v4;
- `residential.house.compact_laundry` v1;
- `commercial.gas_station.small` v1;
- `commercial.diner.rural_small` v2.

New building profiles are ordinary content work by default. System 20 consumes only System 19 public placement/generation/materialization contracts.

## System 20 Candidate 001

`rural.crossroads + temperate.rural` remains the first test profile over a 256×256 global planning domain:

- two inherited crossing roads;
- exactly one traffic-light crossroads;
- 3 commercial opportunities (gas station + diner + one honest vacancy);
- 6 residential parcels;
- 4 farmsteads;
- open agricultural/vacant/wilderness frontage;
- >=60% non-road land unbuilt;
- only existing System 19 building content.

The pure planner remains independently tested. `AreaMaterializationCoordinator.gd` now performs the separate transactional **initial** write into WHAT + Door State and relinquishes generation ownership afterward.

## System 21 camera truth

Camera presentation remains independent from simulation:

- player-follow default;
- five discrete zoom presets: Very Close / Close / Normal / Far / Area;
- detached inspection;
- CENTER/recenter;
- cell/actor focus;
- scripted presentation + restore seam for future cutscenes.

Safari explicit camera controls use direct touch-release activation with synthetic-mouse suppression. CENTER reports `FOLLOW`/`INSPECT` state and reliably returns to player follow.

## System 22 live critique truth

The canonical live demo now materializes and displays the **real System 20 rural crossroads**, rather than the old isolated diner fixture.

- player starts outside the generated diner primary entrance;
- all 12 existing-library buildings exist in one WHAT world;
- existing movement/collision/System 18 doors remain active;
- logical area remains 256×256;
- renderer draws an 80×96 moving presentation window at 24 px/cell;
- render-window shifts preserve global world-cell placement;
- System 21 owns follow/pan/zoom/recenter.

No new buildings, fake stores/barns, actors, loot, vehicles or outbreak content were added for this test.

## Immediate next path

1. **User visually/playably critiques Candidate 001**: road scale, parcel spacing, density gradient, farms, driveways, commercial center and overall rural feel.
2. Correct System 20 profile/planning rules exposed by that critique without changing accepted System 19 buildings merely to hide area defects.
3. Once the rural profile is accepted, add new System 19 building profiles freely as content and/or test another settlement/environment profile.
4. Design long-term streaming/save materialization only when the continuous world needs regions beyond this bounded critique runtime.

## Design rule

Global planning owns cross-region coherence; System 20 refines caller-constrained local areas and may transactionally create their initial WHAT; System 19 owns buildings; System 21 owns camera presentation; System 22 only composes the DEV large-area critique. WHAT owns runtime truth after materialization. Art remains presentation truth, not physics.
