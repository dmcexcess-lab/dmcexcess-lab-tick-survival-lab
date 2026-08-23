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
| 20 | Local Area / Parcel Generation | **IMPLEMENTED — CROSSROADS 006 + SMALL-TOWN 001 + RURAL-SCATTERED 001 + RURAL-OPEN 001** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 20A | Small-Town Center Candidate 001 | **IMPLEMENTED** | `20A_SMALLTOWN_CENTER_CANDIDATE_001.md` |
| 20B | Rural-Scattered / Hamlet Candidate 001 | **IMPLEMENTED** | `20B_RURAL_SCATTERED_CANDIDATE_001.md` |
| 20C | Rural-Open / Countryside Candidate 001 | **IMPLEMENTED** | `20C_RURAL_OPEN_COUNTRYSIDE_CANDIDATE_001.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## System 00D current implementation

Current profile: `temperate.rural.region` **v6**.

Global fixture:

- `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse geography records;
- one Crossroads, one Small-Town and three hamlets;
- connected major roads + gateways;
- one regional river + explicit bridge intents;
- regional power, potable-water and wastewater/septic planning truth;
- five settlement area sites;
- one broad `rural_open` planning context covering ordinary countryside.

System 00D remains pure planning. Exact-head context: `verify/system00d-global-world`.

## System 19 final truth

Protected library:

- Trailer v2;
- Small Farmhouse v2;
- Large Farmhouse v4;
- Compact Laundry House v1;
- Small Gas Station v1;
- Rural Diner v2.

New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

Exact-head context: `verify/system19-local-building`.

## System 20 current profiles

### Rural Crossroads Candidate 006

`rural.crossroads` v5 + `temperate.rural` v3. Protected live anchor with inherited crossroads, two gravel local roads, gas station+diner+vacancy, homes/farms, real primary-door access, real parking frontage and >=60% non-road unbuilt area.

### Small-Town Center Candidate 001

`smalltown.center` v1 + `temperate.rural` v3. Infrastructure-aware town reservations/blocks, connected paved local streets, gas station+diner+honest vacancies, ten residential opportunities and protected inherited regional truth.

### Rural-Scattered / Hamlet Candidate 001

`rural.scattered` v1 + `temperate.rural` v3. Covers all three hamlets with two internal gravel lanes, zero commercial center, 4 residential + 2 farmstead occupied targets, local-lane majority and decentralized utility service intent only.

### Rural-Open / Countryside Candidate 001

`rural.open` v1 + `temperate.rural` v3.

- accepts caller-assigned dry countryside bounds inside the global rural-open context;
- allows zero or more inherited regional roads;
- consumes clipped global geography and infrastructure corridors;
- creates no local roads/parcels/blocks/buildings;
- creates globally coherent lowland/rolling field cover and sparse tree/shrub/rock dressing;
- derives natural-prop identity from global cell coordinates;
- fails honestly on real river/bridge intersections until local hydrology is implemented;
- split and combined dry windows produce identical cell-level landscape truth.

Exact-head context: `verify/system20-local-area`.

## System 00F Slice 001

Canonical rule:

> **Materialization is one-way; activation is reversible.**

Technical stream regions are not logical source identities.

Current 00F source type remains only:

`system20_area_site:<site_id>`

for the five settlement sites. 00F therefore does **not yet** automatically materialize the new rural-open plans.

Deactivation never deletes persistent WHAT. True memory eviction remains deferred until a persistence-backed store exists.

Exact-head context: `verify/system00f-streaming-materialization`.

## System 21 / 22

System 21 owns camera only. System 22 owns the bounded DEV critique presentation only.

The live Web build remains Rural Crossroads Candidate 006.

## Immediate next path

The logical countryside generator now exists, but 00F does not yet have a stable logical countryside-source catalog.

Recommended next bounded design:

**System 00F Slice 002 — countryside logical source catalog/materialization.**

Its key requirement is that countryside source IDs/bounds remain independent from technical stream-region coordinates while consuming `project_rural_open_bounds()`.

Other separate future paths:

- local physical river/bridge materialization;
- persistence/save owner before true memory eviction;
- later sparse rural properties after source ownership is safe;
- System 00E population/households/jobs/outbreak/player story;
- richer System 19 settlement/agricultural content;
- parcel addresses/ownership/zoning.

## Design rule

System 00D owns global coherence; System 20 owns local physical generation; System 19 owns building internals; System 00F owns logical materialization orchestration + technical activation; WHAT owns subsequent persistent truth; System 21 owns camera; System 22 owns DEV presentation.

**Streaming never defines world geography or countryside morphology.**