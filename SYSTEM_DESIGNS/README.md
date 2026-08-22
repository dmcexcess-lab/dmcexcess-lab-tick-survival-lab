# Tick Survival Lab — System Design Index / Approval Ledger

Major systems move through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** under `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

## Current canonical architecture

| Order | System | Status | Design source |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — SLICES 001–005** | `00D_GLOBAL_WORLD_PLANNING.md`, `00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md`, `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`, `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md` |
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
| 20 | Local Area / Parcel Generation | **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 006** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |
| 00F | Streaming / Materialization | **NOT DESIGNED** | future design |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## System 00D current implementation — Slices 001–005

Current profile: `temperate.rural.region` **v5**.

The pure global planner establishes, in order:

`geography -> hydrology -> settlements/sites -> major roads -> bridge intents -> regional electrical infrastructure -> potable water infrastructure -> broad planning regions`.

Current global fixture:

- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse 128-cell geography records with lowland/rolling/upland/ridge classes;
- one central rural crossroads, one smalltown and three rural hamlets;
- geography/hydrology-constrained settlement sites;
- globally connected primary/secondary road network with real boundary gateways;
- protected central straight cross with 640-cell half-span;
- one deterministic boundary-to-boundary primary regional river outside that protected corridor;
- major roads pay a high river-crossing cost and cannot run collinearly along a river centerline;
- every actual perpendicular route/river/cell crossing has exactly one explicit bridge intent;
- one deterministic regional electrical ingress on a real road boundary gateway;
- one small-town substation and one electrical service node per settlement;
- one connected road-following regional feeder network with source-road provenance and independent validation;
- five potable-water service records: small-town municipal groundwater plus decentralized groundwater-source intent for the crossroads and three hamlets;
- one small-town municipal backbone with `groundwater_source`, `treatment_storage`, and `settlement_service` planning anchors plus two road-contained trunk segments;
- `System20AreaRequestProjector.hydrology_constraints_for_bounds()` exposes river + bridge facts read-only;
- `System20AreaRequestProjector.power_constraints_for_bounds()` exposes feeder + power-node facts read-only;
- `System20AreaRequestProjector.water_constraints_for_bounds()` exposes water service/municipal-anchor/trunk facts read-only;
- central `project_site()` still produces the accepted System 20 road request and exact Candidate 006 semantic output;
- unsupported future local profiles still fail honestly;
- exact-head context `verify/system00d-global-world`.

System 00D remains pure planning. It owns no tactical bridge implementation, utility poles/wires, energized electrical state, literal wells/towers/pipes, building plumbing, pressure/flow/water inventory, wastewater/septic behavior, WHAT mutation, renderer, camera, population, outbreak or streaming behavior.

## System 19 finalized building grammar

Protected library:

- `residential.trailer.singlewide` v2;
- `residential.house.farm_small` v2;
- `residential.house.farm_large` v4;
- `residential.house.compact_laundry` v1;
- `commercial.gas_station.small` v1;
- `commercial.diner.rural_small` v2.

New building profiles are ordinary content work unless the frozen System 19 public grammar contract proves insufficient.

## System 20 Rural Crossroads Candidate 006

Current local integration truth:

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

Exact-head context: `verify/system20-local-area`.

## System 21 / 22 presentation truth

System 21 owns camera follow/pan/zoom/focus/recenter only and never mutates simulation.

System 22 owns the bounded moving-window DEV presentation for the accepted 256×256 Candidate 006 local area. The live Web demo remains Candidate 006; System 00D rivers/bridge intents/power/water infrastructure remain headless global planning facts until downstream materialization systems are explicitly designed.

## Immediate next path

Keep Slices 001–005 and Candidate 006 protected. The next major step must be separately designed. The clean North-Star choices are **wastewater/septic infrastructure** or the real System 20 profiles needed to refine planned `smalltown.center` / `rural.scattered` sites. Streaming remains later, after logical world geography/places/infrastructure are stable enough that partitions are purely technical.

## Design rule

Every major system keeps a focused owner/public contract. System 00D owns global geography/hydrology/settlement/major-road/infrastructure coherence; System 20 owns local refinement; System 19 owns building internals; System 21 owns camera presentation; System 22 owns DEV large-area presentation; WHAT owns persistent runtime truth after materialization. Streaming consumes logical world truth and never defines it. Art remains presentation truth, not physics.
