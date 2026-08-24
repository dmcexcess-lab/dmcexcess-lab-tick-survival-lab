# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md` and `README_SOPS.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — v6** | `00D_GLOBAL_WORLD_PLANNING.md` + current infrastructure children |
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
| 12 | Item Transfer / Pickup / Drop / Equip | **IMPLEMENTED — personal + policy-aware external access** | `12_ITEM_TRANSFER_ACTIONS.md` |
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
| 19 | Local Building Generation / Grammar | **IMPLEMENTED — FINALIZED, 24 archetypes** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
| 20 | Local Area Generation | **IMPLEMENTED — ten area / seven environment profiles** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 23 | Perception / LOS / Fog Memory | **IMPLEMENTED — Candidate 001** | `23_PERCEPTION_LOS_FOG_MEMORY.md` |
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Candidate 001** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |

## Current System 19 truth

System 19 exposes 24 callable building archetypes: six protected rural/small-town references plus 18 reusable one-story baseline profiles.

Baseline city-density rule: more rooms/units and realistic circulation, not fake upper floors. Door approaches remain reserved from blocking props.

`GeneratedBuildingPlan.entity_id_for_role(role)` is the public stable role -> materialized entity-ID seam used by the materializer and downstream physical-world consumers such as System 24.

Exact-head context: `verify/system19-local-building`.

## Current System 20 truth

Environment profiles:

- `temperate.rural` v3;
- suburban, urban, industrial, woodland, coastal and marsh v1.

Area profiles:

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

Baseline settlement morphologies use deterministic parcel-fit archetype selection and real access for occupied residential/farmstead/commercial/civic/industrial parcels. Environment palettes remain local vocabulary, not global geography authority.

Exact-head context: `verify/system20-local-area`.

## Current System 00F truth

> **Materialization is one-way; activation is reversible.**

Current source kinds are settlement sites and catalog-v1 dry countryside fragments. Technical stream regions remain independent from logical source identity; inactive materialized truth remains authoritative WHAT.

System 24 does not embed loot state in 00F. Loot initialization is a separately idempotent post-materialization seam for a physically ready source.

Exact-head context: `verify/system00f-streaming-materialization`.

## Current System 23 truth

`UNSEEN` is true black, `REMEMBERED` is dark stale observed world state, and `VISIBLE` uses current live truth. Candidate 001 uses deterministic four-way facing LOS with a 12-cell 120-degree cone plus radius-1 near awareness.

Remembered static furniture/clutter stores stable ID, semantic, anchor and facing. Hidden moves/removals remain stale until re-observed. Loose items, vehicles and vegetation remain separate extensions.

Perception-memory snapshots are schema v2.

Exact-head context: `verify/system23-perception`.

## Current System 24 truth

> **Loot exists before you search for it.**

Candidate 001:

- explicit searchable physical furniture -> System 11 containers;
- deterministic stable unplaced `item.*` entities created once during source loot initialization;
- System 24 source/container provenance, System 11 current contents;
- no automatic repopulation after looting;
- exact rollback across WHAT + System 11 + System 24 after partial initialization failure;
- mandatory `USABLE` / `JUNK` utility class plus primary domain family and optional tags;
- context-aware fridge/pantry/dresser/vanity/retail/medical/office/tool/warehouse/farm profiles;
- timed `scavenge.search_container` action reading current contents at completion;
- System 12 `ItemContainerAccessPolicy` extension for physically reachable world containers;
- timed TAKE/STORE via System 12, with external acquisition checked against the System 13E hard carry ceiling;
- live Rural Crossroads scavenging UI with phone-friendly TAKE/STORE controls.

First fully green executable head: `411099a3c39b7abeeb189e8a176491cb7e410b6d`.

Exact-head context: `verify/system24-loot`.

## Current presentation

The live Web build remains the Rural Crossroads critique world, now with canonical System 23 perception and System 24 scavenging integrated. Its generated buildings initialize persistent loot in the current DEV composition; this does not turn the DEV fixture into a new 00F source model.

## Required protected stack

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/pages-deploy`
