# Tick Survival Lab — System Design Index / Approval Ledger

Major systems move through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** under `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

## Current canonical architecture

| Order | System | Status | Design source |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — SLICES 001–006** | `00D_GLOBAL_WORLD_PLANNING.md`, `00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md`, `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`, `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`, `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` |
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
| 20 | Local Area / Parcel Generation | **IMPLEMENTED — CROSSROADS 006 + SMALL-TOWN 001 + RURAL-SCATTERED 001** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 20A | Small-Town Center Candidate 001 | **IMPLEMENTED** | `20A_SMALLTOWN_CENTER_CANDIDATE_001.md` |
| 20B | Rural-Scattered / Hamlet Candidate 001 | **IMPLEMENTED** | `20B_RURAL_SCATTERED_CANDIDATE_001.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |
| 00F | Streaming / Materialization Orchestration | **DRAFT** | `00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md` |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## System 00D current implementation — Slices 001–006

Current profile: `temperate.rural.region` **v6**.

The pure global planner establishes, in order:

`geography -> hydrology -> settlements/sites -> major roads -> bridge intents -> regional electrical infrastructure -> potable water infrastructure -> wastewater/septic infrastructure -> broad planning regions`.

Current global fixture:

- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse 128-cell geography records with lowland/rolling/upland/ridge classes;
- one central rural crossroads, one smalltown and three rural hamlets;
- geography/hydrology-constrained settlement sites;
- globally connected primary/secondary road network with real boundary gateways;
- protected central straight cross with 640-cell half-span;
- one deterministic boundary-to-boundary primary regional river outside that protected corridor;
- one explicit bridge intent for every actual perpendicular road/river crossing;
- one regional electrical ingress, one small-town substation, one electrical service node per settlement, and one connected road-following feeder network;
- five potable-water services: small-town municipal groundwater plus four decentralized groundwater-source intents;
- three small-town municipal water anchors and two road-contained water trunk segments;
- five wastewater services: small-town municipal treatment plus four decentralized septic intents;
- all rural septic records carry `potable_source_clearance_required`;
- two small-town wastewater anchors and one road-contained collection trunk, selected away from the potable-water source/trunk corridor;
- read-only hydrology, power, water and wastewater projection seams;
- central `project_site()` produces the accepted Candidate 006 request and exact semantic output;
- small-town `project_site()` produces the implemented `smalltown.center` v1 request with normalized infrastructure planning constraints;
- all three rural hamlet sites now project to implemented `rural.scattered` v1 and generate successfully while preserving decentralized water/septic intent and exact inherited road truth;
- road projection ignores pure boundary-tangent regional segments rather than treating them as entering inherited roads;
- exact-head context `verify/system00d-global-world`.

System 00D remains pure planning. It owns no tactical bridge implementation, utility poles/wires, energized electrical state, literal wells/towers/pipes, building plumbing, pressure/flow/water inventory, literal sewer/septic/treatment geometry, runtime sanitation, WHAT mutation, renderer, camera, population, outbreak or streaming behavior.

## System 19 finalized building grammar

Protected library:

- `residential.trailer.singlewide` v2;
- `residential.house.farm_small` v2;
- `residential.house.farm_large` v4;
- `residential.house.compact_laundry` v1;
- `commercial.gas_station.small` v1;
- `commercial.diner.rural_small` v2.

New building profiles are ordinary content work unless the frozen System 19 public grammar contract proves insufficient.

## System 20 implemented profiles

### Rural Crossroads Candidate 006

Protected live/local integration truth:

- `rural.crossroads` v5 + `temperate.rural` v3;
- exact inherited regional road constraints from System 00D;
- two bent local gravel roads with real local frontage;
- majority of houses/farms off the inherited highway;
- compact meaningful setbacks;
- straight primary-door-aligned property approaches;
- deterministic two-dimensional vegetation;
- one real gas-station parking/forecourt frontage extended flush to the road because the System 19 plan exposes `ground.parking*` at its road-facing edge;
- no parking invented for buildings without a real parking edge;
- initial materialization remains transactional and relinquishes ownership to WHAT afterward.

### Small-Town Center Candidate 001

Implemented pure/integration truth:

- `smalltown.center` v1 + `temperate.rural` v3;
- consumes the real System 00D v6 small-town road, power, water, wastewater and hydrology planning facts;
- `InfrastructureReservationPlanner.gd` converts upstream facility/corridor facts into reusable protected local land;
- `TownBlockPlanner.gd` records semantic blocks without treating them as chunks;
- a connected internal paved `local_town` network creates denser residential frontage while preserving inherited regional roads;
- four commercial opportunities use gas station + diner + honest vacancies because the System 19 library remains intentionally limited;
- ten residential opportunities favor local-town frontage;
- inherited-road parcel frontage is clipped to actual inherited segment extent;
- all occupied approaches preserve the real System 19 primary-door alignment rule;
- Rural Crossroads Candidate 006 request and semantic signature remain exact.

### Rural-Scattered / Hamlet Candidate 001

Implemented pure/integration truth:

- `rural.scattered` v1 + `temperate.rural` v3;
- covers `area.rural.scattered.001`, `.002`, and `.003` from the real System 00D v6 plan;
- preserves exact inherited regional road IDs/geometry while ignoring boundary-only road tangencies;
- consumes regional power plus decentralized groundwater and onsite-septic service intent through the existing planning-constraint seam;
- creates no rural utility facility reservation because the global plan does not provide literal local well/septic/substation footprints;
- preserves `potable_source_clearance_required` for future parcel-scale well/septic placement;
- creates exactly two internal 3-cell gravel `local_rural` lanes from a selected horizontal or vertical inherited spine;
- creates exactly four residential + two farmstead opportunities with at least four of six occupied properties on local-lane frontage;
- creates zero commercial opportunities and no semantic town blocks;
- keeps at least 72% of non-road area physically unbuilt;
- uses only finalized System 19 residential/farmhouse archetypes and real primary-door approach alignment;
- dedicated smoke covers all three canonical hamlets plus synthetic horizontal/vertical spine cases;
- Rural Crossroads 006 and Small-Town 001 remain exact protected regressions.

Exact-head context: `verify/system20-local-area`.

## System 21 / 22 presentation truth

System 21 owns camera follow/pan/zoom/focus/recenter only and never mutates simulation.

System 22 owns the bounded moving-window DEV presentation for the accepted 256×256 Rural Crossroads Candidate 006 local area. The live Web demo remains Candidate 006; Small-Town Candidate 001 and Rural-Scattered Candidate 001 remain tested pure/integration profiles until a separate presentation decision is made.

## Immediate next path

Keep System 00D Slices 001–006 and all three System 20 profiles protected. System 00F Streaming / Materialization Orchestration is now **DRAFT** in `00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md`. Its proposed first slice separates logical materialization sources from technical active regions, materializes current area sites once into persistent WHAT, and does not fake memory eviction or arbitrary countryside.

Other valid separately designed next slices include richer System 19 settlement content, parcel addresses/ownership/zoning, and System 00E population/household/outbreak/player-story work.

## Design rule

Every major system keeps a focused owner/public contract. System 00D owns global geography/hydrology/settlement/major-road/infrastructure coherence; System 20 owns local refinement; System 19 owns building internals; System 21 owns camera presentation; System 22 owns DEV large-area presentation; WHAT owns persistent runtime truth after materialization. Streaming consumes logical world truth and never defines it. Art remains presentation truth, not physics.