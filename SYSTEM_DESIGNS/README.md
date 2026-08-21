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
| 20 | Local Area / Parcel Generation | **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 005** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 00D | Global World Planning / Generation | **NOT DESIGNED** | future design |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |
| 00F | Streaming / Materialization | **NOT DESIGNED** | future design |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## System 19 finalized building grammar

Protected/preserved examples used to extract and validate the grammar:

- `residential.trailer.singlewide` v2 — accepted;
- `residential.house.farm_small` v2 — accepted;
- `residential.house.farm_large` v4 — preserved compact/no-hall reference;
- `residential.house.compact_laundry` v1 — accepted;
- `commercial.gas_station.small` v1 — accepted;
- `commercial.diner.rural_small` v2 — accepted after the table-density revision.

Final reusable System 19 seams:

- read-only placement descriptor for higher-level planners;
- `BuildingGrammarProfile` content contract;
- reusable topology/dressing/quality owners;
- deterministic profile-declared variation;
- multi-seed/four-rotation regression tests.

New building profiles are ordinary content work and do not reopen System 19 architecture unless its frozen public contract proves insufficient.

## System 20 Rural Crossroads Candidate 005

Candidate 005 preserves Candidate 004 morphology and corrects only property-approach alignment.

Current morphology/environment truth:

- `rural.crossroads` v4 + `temperate.rural` v3;
- inherited regional roads remain exact and keep the single signalized crossroads;
- two internal 3-cell bent gravel `local_rural` roads provide interior frontage through ordinary uncontrolled junctions and no boundary exits;
- at least 6 of the 10 homes/farmsteads use local-road frontage, including >=3 residential + >=3 farmstead;
- 3 commercial opportunities remain near center: gas station + diner + one honest vacancy;
- ordinary residential/small-commercial facades remain close to frontage; farms remain modestly farther back;
- Candidate 005 still generates zero fake parking cells;
- Candidate 003 mixed-coordinate 2D tree/shrub/rock noise remains unchanged;
- **every occupied property approach is now aligned directly to its actual generated System 19 primary exterior door**;
- System 20 keeps the Candidate 004 building envelope, reads the public primary-entry fact, and shifts the property road/parcel access anchors only along frontage until they share the door axis;
- final approaches therefore run straight and frontage-normal with no last-second lateral hook;
- no System 19 room/wall/door/archetype source changes.

System 20 still owns no camera/render/art behavior. Generated ground/access/prop semantics are materialized as physical world facts.

## System 21 camera truth

Normal gameplay camera defaults to player-follow and has five discrete zoom presets: Very Close, Close, Normal, Far and Area.

The public camera seam also supports detached inspection, recenter, cell focus, actor focus, scripted presentation transitions and one-level restore for future cutscenes/reveals. Camera state never moves actors or advances simulation.

Touch uses explicit `ZOOM - / CENTER / ZOOM +` buttons plus two-finger pan/pinch; desktop uses wheel, middle-drag and Home recenter. Right-click remains reserved for future interaction UI.

`DoorPointerInputAdapter` maps through the active canvas/camera transform and cancels touch selection on drag/multitouch so camera gestures do not become door actions.

## System 22 critique runtime truth

The live Web demo materializes the current System 20 Rural Crossroads candidate into real WHAT, places the player outside the generated diner and renders an 80×96-cell moving presentation window over the 256×256 logical area. System 21 owns camera behavior; System 22 only shifts presentation windows and composes the DEV critique runtime.

## Immediate next path

1. Playtest/visually critique Candidate 005 straight property-door approaches.
2. Fix any remaining System 20 rural morphology/environment rules while preserving System 19 baselines.
3. Once rural morphology is accepted, add new System 19 profiles freely as content or test another settlement/environment combination.
4. Design Global World Planning / long-term streaming-save architecture only when the next world-scale requirement demands it.

## Design rule

Every major system keeps a focused owner/public contract. Global planning owns cross-region coherence; System 20 refines caller-constrained local areas and may add profile-authorized local roads with local parcel frontage; System 19 owns building internals; System 21 owns camera presentation; System 22 owns DEV large-area presentation composition; WHAT owns runtime persistence after materialization. Art remains presentation truth, not physics. If implementation requires a forbidden boundary, return the design to review instead of cascading a patch.
