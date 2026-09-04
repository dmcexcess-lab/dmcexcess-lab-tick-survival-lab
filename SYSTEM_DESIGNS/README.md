# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md`, `PERFORMANCE_NORTH_STAR.md`, `README_SOPS.md`, `ROADMAP.md`, and `README_CONTEXT.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — current procedural island** | `00D_GLOBAL_WORLD_PLANNING.md` + children |
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
| 36 | Vehicles | **APPROVED — implementation next** | `36_VEHICLES.md` |
| PERF | Performance Architecture Gate | **IMPLEMENTED + CI VERIFIED; human accepted** | `PERFORMANCE_ARCHITECTURE.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — Phase 8** | future design |

## Retired infrastructure design

`00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is **RETIRED / historical only**. Wastewater/sewer/septic is not an active dependency.

## Current routing

Phase 1 content foundations, Phase 2 crafting, Phase 3 utilities, Phase 4/5 survivor condition/moodlets, the four-skill foundation, primitive Survival crafting and System 35 outdoor foraging are implemented in the current executable lineage.

**System 36 Vehicles is approved and is the next implementation operation.** Its canonical movement contract is: skateboard = actor-like 2-cell movement with no added Fatigue; bicycle = 3-cell vehicle movement with Fatigue; motorcycle/car/truck = powered 3-cell vehicle movement; true vehicle classes turn through 45-degree heading changes and require a 2-cell braking/stopping path. Motorcycles are easier to steal, use less fuel and have less storage than cars.

After vehicles are implemented and accepted, perform one final comprehensive skills/crafting/items/usable-object closure pass. That pass must include cooking, first aid, fire/ignition, Mechanical repair/modification/deconstruction/reclamation, vehicle maintenance/modification, real usable-object consumers, Awareness/Stealth consumers and the user-approved construction restriction: **no freeform base building; construction is limited to reinforcing existing doors/windows and repairing broken objects.**

## Protected utility truth

- local substations derive from real generated buildings, targeting roughly ten buildings each;
- visible power uses shared roadside feeder trees and short service drops;
- regional source -> local substation remains logical/non-physical;
- one real grid-independent island municipal water plant serves municipal water;
- real rural private wells persist and depend on their local electrical service;
- wastewater/sewer/septic remains retired.

## Verification discipline

Automated green does not replace human generated-world/game-feel acceptance. Exact executable SHA and current terminal workflow state are recorded in `README_CONTEXT.md`.
