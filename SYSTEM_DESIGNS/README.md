# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md`, `PERFORMANCE_NORTH_STAR.md`, `README_SOPS.md`, `ROADMAP.md`, and `README_CONTEXT.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — rural v6 + complete island v3 lineage** | `00D_GLOBAL_WORLD_PLANNING.md` + infrastructure children |
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
| 13A | Actor Health / Injury | **IMPLEMENTED scaffold; Phase 4 expansion ahead** | `13A_ACTOR_HEALTH_INJURY.md` |
| 13B | Actor Needs / Rest | **IMPLEMENTED scaffold; Phase 4 expansion ahead** | `13B_ACTOR_NEEDS_REST.md` |
| 13C | Actor Skills | **IMPLEMENTED scaffold; final catalog Phase 6** | `13C_ACTOR_SKILLS.md` |
| 13D | Item Physical Properties | **IMPLEMENTED** | `13D_ITEM_PHYSICAL_PROPERTIES.md` |
| 13E | Actor Carry / Encumbrance | **IMPLEMENTED** | `13E_ACTOR_CARRY_ENCUMBRANCE.md` |
| 13F | Actor Moodlets / Status Derivation | **IMPLEMENTED scaffold; Phase 5 expansion ahead** | `13F_ACTOR_MOODLETS.md` |
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
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED; truthful System-33 source seam verified** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED + human accepted** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **IMPLEMENTED — Phase 1A** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 30 | Item Freshness / Spoilage | **IMPLEMENTED + CI VERIFIED — Phase 1B** | `30_ITEM_FRESHNESS_SPOILAGE.md` |
| 31 | Semantic UI Icons | **IMPLEMENTED + CI VERIFIED — Phase 1C** | `31_SEMANTIC_UI_ICONS.md` |
| 32 | Crafting / Material Transformation | **IMPLEMENTED + CI VERIFIED — Phase 2 complete** | `32_CRAFTING_MATERIAL_TRANSFORMATION.md` |
| 33 | Power / Water Utility Runtime | **IMPLEMENTED + AUTOMATED VERIFIED — Candidate 001; HUMAN RETEST PENDING** | `33_POWER_WATER_UTILITIES.md` |
| PERF | Performance Architecture Gate | **IMPLEMENTED + CI VERIFIED; human accepted** | `PERFORMANCE_ARCHITECTURE.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — scheduled inside Phase 8** | future design |

## Cross-system roadmap designs

| Phase | Status | Canonical design |
|---|---|---|
| 1E — Content Expansion + Integration | **IMPLEMENTED + CI VERIFIED** | `PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md` |
| 2 — Crafting | **IMPLEMENTED + CI VERIFIED** | `32_CRAFTING_MATERIAL_TRANSFORMATION.md` |
| 3 — Power + Water | **IMPLEMENTED + AUTOMATED VERIFIED; HUMAN RETEST PENDING** | `33_POWER_WATER_UTILITIES.md` |

---

## Roadmap routing

Phase 1 is implementation-complete through 1E.

Phase 2 / System 32 is implementation-complete and CI-verified on executable:

`8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`

The current island/performance recovery is human-play accepted.

System 33 Candidate 001 is implemented and exact-head verified after the truthful-lighting repair on executable:

`ec7be83146d62055a5d2d4b1233eb7cc50cea630`

The active gameplay lifecycle gate is **human browser verification of repaired System 33**, not Phase-4 implementation yet.

Then: **physical survival/health -> Moodlets -> final skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.**

---

## Current System 32 truth

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Candidate 001 implements exact stable ingredient/tool selection from real personal possession, real non-consumed tools, heavy-workbench capability, physical recipes, positive-duration CANCELABLE WHEN crafting, final-commit revalidation, deterministic persistent outputs, System-11 containment, System-13D/13E weight/carry integration and the canonical CRAFT interaction/UI path.

Candidate 001 intentionally excludes cooking/perishables, consuming item-containers, durability/repair, construction, Power/Water, nutrition/Health, Skills/XP/quality, Vehicles, combat/ammo and AI.

---

## Current System 33 truth

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

Candidate 001 implements:

- persistent three-tier power service state consuming 00D4 planning truth;
- persistent three-tier potable-water service consuming 00D5 planning truth;
- rural decentralized well service where planned;
- electrically driven water-pump dependency on real power service;
- real refrigerator cold-storage availability for System 30;
- typed appliance/switch/operational state and utility damage/disabled mutation seams;
- event/revision-driven cached service derivation with no frame polling or per-component timers;
- truthful DEV controls over canonical state;
- real fixed-light integration into System 27.

### Truthful fixed/equipped light source boundary

The initial visible lighting integration was rejected in human play because it still used legacy demo fixture coordinates and an unconditional fake player flashlight.

That seam is now retired:

- fixed light discovery uses real WHAT semantic fixture entities;
- fixed emitter position/facing uses each fixture's real `WorldPlacement`;
- local System-33 service powers/unpowers the emitter;
- player flashlight emission requires a real `item.tool.flashlight` entity assigned by System 09 hand equipment;
- no flashlight is silently granted at spawn;
- portable battery/toggle depletion remains deferred rather than simulated falsely;
- `DemoLightingSourceAdapter` remains only an inert compatibility/bootstrap class with zero emitters;
- a facing-only turn with no equipped moving light must not rebuild physical lighting.

Dedicated exact-head context: `verify/system33-lighting-truth`.

**Human retest remains required before Candidate 001 / Phase 3 is marked HUMAN ACCEPTED.**

---

## Required executable-head stack

Current System-33 executable verification preserves, at minimum:

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system23-perception`
- `verify/system25-world-time-light`
- `verify/system27-physical-lighting`
- `verify/system29-interaction-affordance`
- `verify/system30-item-freshness`
- `verify/system32-crafting`
- `verify/system33-power-water`
- `verify/system33-lighting-truth`
- `verify/performance-architecture`
- canonical startup/player responsiveness/visibility coverage;
- `verify/pages-deploy`.

Verified executable: `ec7be83146d62055a5d2d4b1233eb7cc50cea630`.

**Current lifecycle gate: human browser verification of repaired System 33 Candidate 001.**
