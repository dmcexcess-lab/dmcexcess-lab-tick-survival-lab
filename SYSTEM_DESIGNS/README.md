# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md` and `README_SOPS.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — v6** | `00D_GLOBAL_WORLD_PLANNING.md` + current infrastructure child contracts |
| 00F | Streaming / Materialization | **IMPLEMENTED — settlement + dry countryside** | `00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md` |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` |
| 03 | Actor Locomotion / Capability | **IMPLEMENTED** | `03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md` |
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` |
| 07A | Prop Art Orientation | **IMPLEMENTED** | `07A_PROP_ART_ORIENTATION.md` |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` |
| 10 | Actor Hand Equipment Presentation | **IMPLEMENTED** | `10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md` |
| 11 | Inventory / Containment | **IMPLEMENTED** | `11_INVENTORY_CONTAINMENT.md` |
| 12 | Item Transfer / Pickup / Drop / Equip | **IMPLEMENTED** | `12_ITEM_TRANSFER_ACTIONS.md` |
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
| 17A | Movement Exertion / Encumbrance / Run Impact | **IMPLEMENTED** | `17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md` |
| 17A.1 | Overweight Walk Fatigue / Carry Ceiling | **IMPLEMENTED** | `17A1_OVERWEIGHT_WALK_FATIGUE_HARD_CARRY_LIMIT.md` |
| 18 | Door Interaction / Automatic Passage | **IMPLEMENTED** | `18_DOOR_INTERACTION_PASSAGE.md` |
| 19 | Local Building Generation / Grammar | **IMPLEMENTED — FINALIZED, 24-archetype library** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
| 20 | Local Area Generation | **IMPLEMENTED — ten area / seven environment profiles** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 23 | Perception / LOS / Fog Memory | **IMPLEMENTED — Candidate 001** | `23_PERCEPTION_LOS_FOG_MEMORY.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |

## Current System 00D truth

`temperate.rural.region` v6: deterministic geography, five settlement sites, connected major roads, regional river + bridge intents, regional electrical planning, municipal/decentralized potable-water planning, and municipal/decentralized wastewater/septic planning.

Exact-head context: `verify/system00d-global-world`.

## Current System 19 truth

Protected reference library:

- Trailer v2;
- Small Farmhouse v2;
- Large Farmhouse v4;
- Compact Laundry House v1;
- Small Gas Station v1;
- Rural Diner v2.

Baseline library adds 18 one-story profiles for suburban houses, horizontal townhomes/multi-unit housing, roadside motel lodging, commercial stores/offices, civic buildings, warehouse/workshop and barn content. Total callable registry: **24 archetypes**.

Baseline city-density rule: **more rooms/units and realistic circulation, not fake upper floors**. Multi-unit housing/motel rooms use independent exterior access while one designated primary exterior door remains the System 20 placement anchor. Blocking props never materialize on door-approach circulation cells.

Exact-head context: `verify/system19-local-building`.

## Current System 20 truth

Environment profiles:

- `temperate.rural` v3;
- `temperate.suburban` v1;
- `temperate.urban` v1;
- `temperate.industrial` v1;
- `temperate.woodland` v1;
- `temperate.coastal` v1;
- `temperate.marsh` v1.

Area profiles owned by the single System 20 contract:

- `rural.crossroads` v5;
- `smalltown.center` v1;
- `rural.scattered` v1;
- `rural.open` v1;
- `rural.watercourse` v1;
- `suburban.neighborhood` v1;
- `urban.mixed` v1;
- `commercial.corridor` v1;
- `industrial.district` v1;
- `civic.campus` v1.

The five baseline settlement morphologies use deterministic parcel-fit archetype selection and real finalized access for occupied residential, farmstead, commercial, civic and industrial parcels. Environment palettes are local vocabulary only; woodland/coastal/marsh palettes do not grant permission to invent corresponding 00D geography.

Candidate numbers are implementation history, not peer-system identity. Their final rules live in `20_LOCAL_AREA_PARCEL_GENERATION.md`; detailed historical drafts remain available in Git history/changelog.

Exact-head context: `verify/system20-local-area`.

First exact executable head with the 24-archetype System 19 library, five new System 20 morphologies, seven environment palettes and the full protected stack green: `2e7a6e0da27a02f8058a3a79538cd9cb55a48cef`.

## Current System 00F truth

> **Materialization is one-way; activation is reversible.**

Current source kinds:

- `system20_area_site` — five settlement sites;
- `system20_rural_open` — catalog-v1 dry countryside fragments.

Source providers share one coordinator-facing contract; adding another source kind must not add another hardcoded coordinator field/branch.

Technical stream regions remain independent from logical source identity. Inactive materialized facts remain authoritative WHAT; true memory eviction waits for a persistence-backed storage design.

Physical river/bridge terrain exists in System 20, but river cells intentionally have no 00F logical source provider yet.

Exact-head context: `verify/system00f-streaming-materialization`.

## Current presentation

System 21 owns camera only. System 22 owns the bounded DEV critique runtime only. The live Web build still presents the Rural Crossroads critique world, now with canonical System 23 perception/fog integrated into the demo stack.

The expanded baseline profile libraries are generator content and do not silently replace the current live critique fixture.

## Current System 23 truth

**System 23 Perception / LOS / Fog Memory — IMPLEMENTED Candidate 001.**

Canonical player-facing knowledge model:

- `UNSEEN` = completely black visual world information;
- `REMEMBERED` = darkened stale last-observed terrain/structural memory;
- `VISIBLE` = current live world truth;
- auditory indicators may render over any of the three states, including true black unexplored fog, without revealing/exploring terrain;
- last-seen living-actor markers are stale observations, not hidden tracking.

Candidate 001 uses deterministic four-way facing LOS with a 12-cell range, 120-degree forward cone and radius-1 near awareness. Walls and closed doors block; open doors and windows transmit; malformed/unknown structure opacity fails closed. Memory is keyed by stable observer actor ID and hidden live changes never update stale visual memory.

Existing live renderers remain current-truth renderers. `PerceptionOverlayRenderer` masks all non-visible live truth with black and redraws only stored remembered snapshots above that mask.

Exact-head context: `verify/system23-perception`.

First fully green executable implementation head after final LOS fixture correction: `87fb517265ba1defc395068d09ccb7059e16d114`.

Seven protected exact-head gates remain System 00D, 00F, 19, 20, 21, 22 and Pages.