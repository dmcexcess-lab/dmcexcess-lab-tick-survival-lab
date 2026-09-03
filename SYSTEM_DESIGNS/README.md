# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md`, `PERFORMANCE_NORTH_STAR.md`, `README_SOPS.md`, `ROADMAP.md`, and `README_CONTEXT.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — rural v7 + complete island v4** | `00D_GLOBAL_WORLD_PLANNING.md` + infrastructure children |
| 00F | Streaming / Materialization | **IMPLEMENTED — settlement + countryside + island surface + river/watercourse** | `00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md` |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` |
| 03 | Actor Locomotion / Capability | **IMPLEMENTED** | `03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md` |
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` |
| 07A | Prop Art Orientation | **IMPLEMENTED** | `07A_PROP_ART_ORIENTATION.md` |
| 07B | Large / Multi-cell Object Visual Geometry | **IMPLEMENTED + CI VERIFIED; Phase 1D complete** | `07B_LARGE_MULTI_CELL_VISUAL_GEOMETRY.md` |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` |
| 10 | Actor Hand Equipment Presentation | **IMPLEMENTED** | `10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md` |
| 11 | Inventory / Containment | **IMPLEMENTED** | `11_INVENTORY_CONTAINMENT.md` |
| 12 | Item Transfer / Pickup / Drop / Equip | **IMPLEMENTED — personal + policy-aware external access** | `12_ITEM_TRANSFER_ACTIONS.md` |
| 13 | Actor Stats / Status Architecture | **IMPLEMENTED via children; roadmap expansion ahead** | `13_ACTOR_STATS_STATUS_ARCHITECTURE.md` |
| 13A | Actor Health / Injury | **IMPLEMENTED; System 34 consequences integrated** | `13A_ACTOR_HEALTH_INJURY.md` |
| 13B | Actor Needs / Rest | **LEGACY scaffold retained; System 34 owns live condition/Fatigue** | `13B_ACTOR_NEEDS_REST.md` |
| 13C | Actor Skills | **IMPLEMENTED six-skill scaffold; four-skill redesign ahead** | `13C_ACTOR_SKILLS.md` |
| 13D | Item Physical Properties | **IMPLEMENTED** | `13D_ITEM_PHYSICAL_PROPERTIES.md` |
| 13E | Actor Carry / Encumbrance | **IMPLEMENTED** | `13E_ACTOR_CARRY_ENCUMBRANCE.md` |
| 13F | Actor Moodlets / Status Derivation | **IMPLEMENTED; live System 34 composition** | `13F_ACTOR_MOODLETS.md` |
| 14 | Canonical Playable Demo Integration | **IMPLEMENTED** | `14_CANONICAL_PLAYABLE_DEMO.md` |
| 15 | Canonical HUD / Facing Inspection | **IMPLEMENTED** | `15_CANONICAL_HUD_FACING_INSPECTION.md` |
| 16 | Canonical Player Shell / Inspectors / Stance | **IMPLEMENTED** | `16_CANONICAL_PLAYER_SHELL.md` |
| 17 | Run / Damage-Interruptible Walking | **IMPLEMENTED** | `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` |
| 17A | Movement Exertion / Encumbrance / Run Impact | **IMPLEMENTED** | `17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md` |
| 17A.1 | Overweight Walk Fatigue / Carry Ceiling | **IMPLEMENTED** | `17A1_OVERWEIGHT_WALK_FATIGUE_HARD_CARRY_LIMIT.md` |
| 18 | Door Interaction / Automatic Passage | **IMPLEMENTED** | `18_DOOR_INTERACTION_PASSAGE.md` |
| 19 | Local Building Generation / Grammar | **IMPLEMENTED — FINALIZED, 24 archetypes + Phase-1E dressing** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
| 20 | Local Area Generation | **IMPLEMENTED — ten area / seven environment profiles + island continuity** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 23 | Perception / LOS / Fog Memory | **IMPLEMENTED** | `23_PERCEPTION_LOS_FOG_MEMORY.md` |
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Phase-1E expanded** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 25 | World Time / Ambient Daylight | **IMPLEMENTED** | `25_WORLD_TIME_AMBIENT_DAYLIGHT.md` |
| 26 | Spatial Sound / Hearing | **IMPLEMENTED** | `26_SPATIAL_SOUND_HEARING.md` |
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED; truthful powered fixed/equipped/room source seam verified** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED + human accepted** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **IMPLEMENTED — Phase 1A** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 30 | Item Freshness / Spoilage | **IMPLEMENTED + CI VERIFIED — Phase 1B** | `30_ITEM_FRESHNESS_SPOILAGE.md` |
| 31 | Semantic UI Icons | **IMPLEMENTED + CI VERIFIED — Phase 1C** | `31_SEMANTIC_UI_ICONS.md` |
| 32 | Crafting / Material Transformation | **IMPLEMENTED + CI VERIFIED — Phase 2 complete** | `32_CRAFTING_MATERIAL_TRANSFORMATION.md` |
| 33 | Power / Water Utility Runtime | **IMPLEMENTED + EXACT-HEAD VERIFIED — local substations, physical distribution, island-wide water, real wells, daily span snaps; HUMAN PLAYTEST PENDING** | `33_POWER_WATER_UTILITIES.md` + `33B_POWER_PHYSICAL_NETWORK_CONDITION.md` |
| 34 | Survivor Condition / Health / Fatigue / Moodlets | **IMPLEMENTED + EXACT-HEAD VERIFIED; human playtest pending** | `34_SURVIVOR_CONDITION_HEALTH_STAMINA_MOODLETS.md` |
| PERF | Performance Architecture Gate | **IMPLEMENTED + CI VERIFIED; human accepted** | `PERFORMANCE_ARCHITECTURE.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — scheduled inside Phase 8** | future design |

## Retired infrastructure design

`00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is **RETIRED / historical only**. Wastewater/sewer/septic is not an active global-planning, local-generation or System-33 dependency.

## Cross-system roadmap designs

| Phase | Status | Canonical design |
|---|---|---|
| 1E — Content Expansion + Integration | **IMPLEMENTED + CI VERIFIED** | `PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md` |
| 2 — Crafting | **IMPLEMENTED + CI VERIFIED** | `32_CRAFTING_MATERIAL_TRANSFORMATION.md` |
| 3 — Power + Water | **IMPLEMENTED + EXACT-HEAD VERIFIED; HUMAN PLAYTEST PENDING** | `33_POWER_WATER_UTILITIES.md` + `33B_POWER_PHYSICAL_NETWORK_CONDITION.md` |

## Current routing

Phase 1 is implementation-complete through 1E. Phase 2 / System 32 is implementation-complete and CI verified.

The current island/performance recovery is human-play accepted.

System 33's current implementation is exact-head automated-green on executable:

`a0299a14d21fb907bdd363ddadb00cc3403b48f1`

The active gameplay lifecycle gate is **human browser verification of the current local power topology, physical line-failure behavior, municipal water plant/private wells, lighting and refrigeration consequences**. Do not begin Phase 4 by default solely because CI is green.

Then: **physical survival/health -> Moodlets -> final skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.**

## Current System 33 truth

> **Real generated buildings determine local utility topology; System 33 owns whether real infrastructure currently provides service. Consumers never infer utility truth from art, distance or UI.**

Current power truth:

- generated buildings are grouped at a target of ~10 buildings per local substation;
- substations are small fenced transformer/utility-box compounds;
- regional source -> local substation is logical/non-physical for presentation;
- local visible spans run from substations to customer poles near the served buildings;
- physical spans/supports carry stable condition IDs and causal service mappings;
- once per authoritative game day, eligible spans receive the deterministic snap pass defined in `33B_POWER_PHYSICAL_NETWORK_CONDITION.md`;
- direct damage/repair and daily snaps mutate the same canonical System-33 service truth;
- snapped lines emit a spatial `*SNAP*` event through System 26.

Current water truth:

- one compact real municipal treatment facility near the shore serves all settlements;
- municipal water has no service radius and no simulated long-distance pipe network;
- municipal plant operation does not depend on external grid power;
- failure of the plant critical asset removes island-wide municipal service;
- a deterministic 10–20% of real generated rural homes receive persistent private wells (15% target);
- private wells depend on their real local electrical service and have persistent condition/repair state;
- there is no active wastewater/sewer/septic system.

Existing truthful lighting, room-light and refrigeration integrations remain part of System 33 and continue to consume canonical service state.

## Required executable verification

At minimum the current executable must preserve:

- `verify/system33-power-water`;
- global-world-planning v7 / complete-island / System-20 projection coverage;
- System 27 physical lighting;
- System 30 item freshness;
- performance architecture;
- player input responsiveness;
- canonical startup;
- Pages build/export/deploy.

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`.

**Human browser verification remains required before Phase 3 is marked HUMAN ACCEPTED.**
