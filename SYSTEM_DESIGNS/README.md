# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md`, `PERFORMANCE_NORTH_STAR.md`, `README_SOPS.md`, `ROADMAP.md`, and `README_CONTEXT.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — current procedural island** | `00D_GLOBAL_WORLD_PLANNING.md` + active children |
| 00D3 | Global Hydrology / Bridge Intent | **RETIRED / historical only** | `00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md` |
| 00D4 | Global Electrical Infrastructure | **IMPLEMENTED** | `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md` |
| 00D5 | Global Potable Water Infrastructure | **IMPLEMENTED — single-facility service model** | `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md` |
| 00D6 | Global Wastewater / Septic Infrastructure | **RETIRED / historical only** | `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` |
| 00F | Streaming / Materialization | **IMPLEMENTED** | `00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md` |
| 01–12 | Spatial, movement, rendering, equipment, inventory, transfer | **IMPLEMENTED** | numbered designs |
| 13 | Actor Stats / Status Architecture | **IMPLEMENTED via children** | `13_ACTOR_STATS_STATUS_ARCHITECTURE.md` |
| 13A | Actor Health / Injury | **IMPLEMENTED** | `13A_ACTOR_HEALTH_INJURY.md` |
| 13B | Actor Needs / Rest | **LEGACY scaffold; System 34 owns live condition/Fatigue** | `13B_ACTOR_NEEDS_REST.md` |
| 13C | Actor Skills | **IMPLEMENTED — Awareness / Stealth / Mechanical / Survival** | `13C_ACTOR_SKILLS.md` |
| 13D | Item Physical Properties | **IMPLEMENTED** | `13D_ITEM_PHYSICAL_PROPERTIES.md` |
| 13E | Actor Carry / Encumbrance | **IMPLEMENTED** | `13E_ACTOR_CARRY_ENCUMBRANCE.md` |
| 13F | Actor Moodlets / Status Derivation | **IMPLEMENTED** | `13F_ACTOR_MOODLETS.md` |
| 14–23 | Canonical play/HUD/shell, run/exertion, doors, local generation, camera, critique, perception | **IMPLEMENTED** | numbered designs |
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Survival-aware search** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 25 | World Time / Ambient Daylight | **IMPLEMENTED** | `25_WORLD_TIME_AMBIENT_DAYLIGHT.md` |
| 26 | Spatial Sound / Hearing | **IMPLEMENTED** | `26_SPATIAL_SOUND_HEARING.md` |
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED + human accepted** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **IMPLEMENTED** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 30 | Item Freshness / Spoilage | **IMPLEMENTED** | `30_ITEM_FRESHNESS_SPOILAGE.md` |
| 31 | Semantic UI Icons | **IMPLEMENTED** | `31_SEMANTIC_UI_ICONS.md` |
| 32 | Crafting / Material Transformation | **IMPLEMENTED — skill-aware + primitive Survival recipes** | `32_CRAFTING_MATERIAL_TRANSFORMATION.md` |
| 33 | Power / Water Utility Runtime | **IMPLEMENTED + automated verified; HUMAN PLAYTEST PENDING** | `33_POWER_WATER_UTILITIES.md` + `33B_POWER_PHYSICAL_NETWORK_CONDITION.md` |
| 34 | Survivor Condition / Health / Fatigue / Moodlets | **IMPLEMENTED + automated verified; HUMAN PLAYTEST PENDING** | `34_SURVIVOR_CONDITION_HEALTH_STAMINA_MOODLETS.md` |
| 35 | Outdoor Foraging | **IMPLEMENTED + EXACT-HEAD VERIFIED; HUMAN PLAYTEST PENDING** | `35_OUTDOOR_FORAGING.md` |
| 36 | Vehicles | **IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING** | `36_VEHICLES.md` |
| 37–39 | Combat, resident infected, environmental opening pressure | **IMPLEMENTED** | numbered designs + implementation changelog |
| 40 / 00E | Resident Survivors / Social Roles / Causal Local Outbreak | **IMPLEMENTED — core Phase 8 closure** | `40_SURVIVOR_SOCIAL_OUTBREAK.md` |
| PERF | Performance Architecture Gate | **IMPLEMENTED + CI VERIFIED; human accepted baseline** | `PERFORMANCE_ARCHITECTURE.md` |

## Retired infrastructure designs

`00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md` and `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` are **RETIRED / historical only**. Generated rivers/watercourses, river-only bridge intents and wastewater/sewer/septic are not active dependencies. Coastline, shore and ocean generation remain active procedural-island truth.

## Current routing

The executable now contains the core gameplay chain the old roadmap was still describing as future work: persistent procedural island/streaming, rendering and mobile-capable HUD/input, loot/inventory/equipment, food/drink/medicine, rest/sleep, crafting/cooking, first aid, utilities, lights/switches/generators, doors/windows/boarding/deconstruction/repair, four broad skills with concrete consumers, foraging, vehicles, melee/firearms, resident-backed infected, environmental opening pressure, and System 40 resident survivors/followers/raiders with causal same-identity local infection.

System 40 does not add another population authority. `PopulationResidentProjection` partitions the existing generated household residents into infected and survivors; active human NPCs use ordinary actor Health/inventory/skills/condition/movement/combat/perception/WHEN owners. The production start keeps eight resident-backed infected and adds four survivor NPC exemplars (two neutral, two raiders). Recruitment changes a neutral survivor into a follower; damaging infected contact can causally convert the same resident identity into the existing infected cohort.

System 36 remains intentionally exact-cell rather than pretending arbitrary-angle physics exists. Dedicated battery/wheel replacement, arbitrary-angle collision polygons, partial-fluid fuel, broader modifications and island-wide streaming vehicle population remain optional fidelity expansion, not missing core runtime.

## Protected utility truth

- local substations derive from real generated buildings, targeting roughly ten buildings each;
- visible power uses shared roadside feeder trees and short service drops;
- regional source -> local substation remains logical/non-physical;
- one real grid-independent island municipal water facility serves municipal water island-wide through lightweight service aliases;
- deterministic private wells cover 10–20% of generated rural buildings and have no external-grid dependency;
- municipal pipe/node/segment topology is retired;
- wastewater/sewer/septic remains retired.

## Verification discipline

Automated green does not replace human generated-world/game-feel acceptance. The core feature roadmap may be closed while defect-driven browser/mobile acceptance, balance, art/content tuning and optional fidelity expansion continue. Exact executable SHA and current terminal workflow state are recorded in `README_CONTEXT.md`.
