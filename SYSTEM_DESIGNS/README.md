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
| 00F | Streaming / Materialization | **IMPLEMENTED — SLICE 001** | `00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md` |
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
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## System 00D current implementation — Slices 001–006

Current profile: `temperate.rural.region` **v6**.

Pure order:

`geography -> hydrology -> settlements/sites -> major roads -> bridge intents -> regional electrical infrastructure -> potable water infrastructure -> wastewater/septic infrastructure -> broad planning regions`.

Current global fixture:

- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse geography records;
- one Crossroads, one Small-Town and three rural hamlets;
- connected major-road network with real gateways;
- regional river + explicit bridge intent;
- regional electrical topology;
- mixed municipal/decentralized potable water;
- mixed municipal/decentralized wastewater/septic;
- five logical local-area site records;
- all five sites project to real implemented System 20 profiles.

System 00D remains pure planning and owns no WHAT mutation, local morphology, renderer, population/outbreak or streaming behavior.

Exact-head context: `verify/system00d-global-world`.

## System 19 finalized building grammar

Protected library:

- `residential.trailer.singlewide` v2;
- `residential.house.farm_small` v2;
- `residential.house.farm_large` v4;
- `residential.house.compact_laundry` v1;
- `commercial.gas_station.small` v1;
- `commercial.diner.rural_small` v2.

New profiles are ordinary content work unless the frozen grammar contract proves insufficient.

Exact-head context: `verify/system19-local-building`.

## System 20 implemented profiles

### Rural Crossroads Candidate 006

Protected live/local anchor:

- `rural.crossroads` v5 + `temperate.rural` v3;
- inherited regional roads + two local gravel roads;
- gas station + diner + honest commercial vacancy;
- residential/farmstead local-road majority;
- close facade setbacks;
- real primary-door-aligned access;
- generic road-flush building-owned parking rule;
- deterministic open-land dressing.

### Small-Town Center Candidate 001

- `smalltown.center` v1 + `temperate.rural` v3;
- consumes actual System 00D utility/hydrology facts;
- infrastructure reservations + semantic blocks;
- compact internal paved `local_town` network;
- gas station + diner + honest commercial vacancies;
- ten residential opportunities favoring local streets;
- protected Crossroads regression remains exact.

### Rural-Scattered / Hamlet Candidate 001

- `rural.scattered` v1 + `temperate.rural` v3;
- all three current hamlets supported;
- exact inherited road truth + two internal gravel lanes;
- zero commercial, four residential, two farmstead targets;
- >=4/6 occupied properties on local-lane frontage;
- >=72% non-road area unbuilt;
- decentralized groundwater/septic are service intent, not fake facilities;
- Crossroads and Small-Town regressions remain exact.

Exact-head context: `verify/system20-local-area`.

## System 00F Streaming / Materialization — Slice 001

Canonical design: `00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md`.

Implemented rule:

> **Materialization is one-way; activation is reversible.**

Technical stream regions and logical generation/materialization sources are separate identities.

Current source type:

- `system20_area_site:<site_id>` for the five real System 00D area sites.

Implemented owners:

- `StreamingRegionGrid.gd` — replaceable technical region geometry;
- `MaterializationRecord.gd` — immutable-style source provenance;
- `MaterializationRegistry.gd` — successful one-time source registry + schema-v1 snapshot;
- `AreaSiteMaterializationSource.gd` — public 00D -> System 20 source adapter;
- `WorldMaterializationCoordinator.gd` — atomic WHAT + Door State + registry multi-source transaction;
- `WorldStreamingCoordinator.gd` — focus-driven active region bookkeeping + source ensuring.

Default technical configuration is 256×256 stream regions with active radius 1. The current 1792×1792 fixture happens to be 7×7, but region size/lattice is not world identity.

Materialized sources are never regenerated on revisit. Deactivation does not remove terrain/entities, reset doors, advance WHEN, or instruct rendering/AI. A real Crossroads OPEN door survives deactivate/revisit unchanged.

True memory eviction is **not implemented** because no authoritative persistence-backed inactive-region store exists yet. A source-free technical region is valid and creates no fake countryside.

First green integrated code head:

`1841dc99e9f6731388dc9b730bb2959e38d575ba`

Exact-head context:

`verify/system00f-streaming-materialization`

## System 21 / 22 presentation truth

System 21 owns camera behavior only. System 22 owns the bounded DEV critique presentation only.

The live Web demo remains Rural Crossroads Candidate 006. 00F Slice 001 is independently proven and does not switch the presentation path.

## Immediate next path

Current global settlement sites and their one-time streaming/materialization orchestration are now established.

Recommended next bounded design:

**System 20C Rural-Open / Countryside local materialization source** — provide honest detailed world between the five existing settlement sites so 00F can consume it without inventing geography or morphology.

Other separately designable paths:

- a persistence/save owner, required before true 00F memory eviction;
- System 00E population/households/jobs/outbreak/player story;
- richer System 19 settlement content;
- parcel addresses/ownership/zoning.

## Design rule

System 00D owns global coherence; System 20 owns local morphology; System 19 owns building internals; System 00F owns materialization orchestration + technical activation; WHAT owns persistent runtime truth after materialization; System 21 owns camera; System 22 owns DEV presentation. Streaming never defines world truth, and Art remains presentation rather than physics.
