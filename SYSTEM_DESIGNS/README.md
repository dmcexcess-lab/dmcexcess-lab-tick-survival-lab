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
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED; truthful powered fixed/equipped/room source seam verified** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED + human accepted** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **IMPLEMENTED — Phase 1A** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 30 | Item Freshness / Spoilage | **IMPLEMENTED + CI VERIFIED — Phase 1B** | `30_ITEM_FRESHNESS_SPOILAGE.md` |
| 31 | Semantic UI Icons | **IMPLEMENTED + CI VERIFIED — Phase 1C** | `31_SEMANTIC_UI_ICONS.md` |
| 32 | Crafting / Material Transformation | **IMPLEMENTED + CI VERIFIED — Phase 2 complete** | `32_CRAFTING_MATERIAL_TRANSFORMATION.md` |
| 33 | Power / Water Utility Runtime | **IMPLEMENTED + EXACT-HEAD VERIFIED — Candidate 001 + Stage B physical network; HUMAN PLAYTEST PENDING** | `33_POWER_WATER_UTILITIES.md` + `33B_POWER_PHYSICAL_NETWORK_CONDITION.md` |
| PERF | Performance Architecture Gate | **IMPLEMENTED + CI VERIFIED; human accepted** | `PERFORMANCE_ARCHITECTURE.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — scheduled inside Phase 8** | future design |

## Cross-system roadmap designs

| Phase | Status | Canonical design |
|---|---|---|
| 1E — Content Expansion + Integration | **IMPLEMENTED + CI VERIFIED** | `PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md` |
| 2 — Crafting | **IMPLEMENTED + CI VERIFIED** | `32_CRAFTING_MATERIAL_TRANSFORMATION.md` |
| 3 — Power + Water | **IMPLEMENTED + EXACT-HEAD VERIFIED; HUMAN PLAYTEST PENDING** | `33_POWER_WATER_UTILITIES.md` + `33B_POWER_PHYSICAL_NETWORK_CONDITION.md` |

---

## Roadmap routing

Phase 1 is implementation-complete through 1E. Phase 2 / System 32 is implementation-complete and CI-verified on `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.

The current island/performance recovery is human-play accepted.

System 33 Candidate 001, truthful powered lighting, utility support placement, and Stage B physical power-network condition/damage are exact-head verified on executable:

`7ddee8df0e638cbe14897d83632b62513d5fc574`

The active gameplay lifecycle gate is **human browser verification of Stage B plus the existing System-33 utility behavior**, not Phase-4 implementation by default.

Then: **physical survival/health -> Moodlets -> final skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.**

---

## Current System 32 truth

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Candidate 001 implements exact stable ingredient/tool selection from real personal possession, real non-consumed tools, heavy-workbench capability, physical recipes, positive-duration CANCELABLE WHEN crafting, final-commit revalidation, deterministic persistent outputs, System-11 containment, System-13D/13E weight/carry integration and the canonical CRAFT interaction/UI path.

---

## Current System 33 truth

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

Candidate 001 implements persistent three-tier power/potable-water service state, rural wells where planned, electrical pump-power dependency, powered refrigerator cold storage for System 30, typed appliance and utility damage state, revision-driven cached service derivation, canonical DEV controls and real System-27 powered-light integration.

### Stage B physical power network

Canonical extension: `33B_POWER_PHYSICAL_NETWORK_CONDITION.md`.

- 00D4 feeder segments now carry deterministic `service_settlement_ids`, so physical downstream causality is planned once rather than rediscovered after damage.
- Visible wire spans receive stable `power.asset.span.*` condition identity and supports reuse their real persistent WHAT IDs.
- `UtilityNetworkConditionStore` provides shared data-only analytic utility-asset condition with no per-asset timer/Node/scheduled event.
- `UtilityPowerNetworkRuntime` maps assets to System-33 services, applies direct damage/repair, predicts threshold failures analytically, and keeps one sorted next-failure schedule.
- Ordinary time advancement checks only the earliest due threshold; it does not scan every asset or iterate simulated days.
- A failed physical span/support damages only the existing System-33 distribution links for mapped downstream services; unrelated branches remain powered where topology allows.
- Repair restores only outage state owned by the physical-network failure.
- Dead cables remain visible because presentation topology is independent from energized service truth.
- Fake regional-ingress/substation transformer clusters were removed; final source/substation tactical facilities remain a future generation responsibility.
- `PowerLinePresentationRenderer` now ignores unrelated world changes through an endpoint-ID lookup rather than repeatedly searching all wire endpoints.

### Truthful fixed/equipped source boundary

- fixed light discovery uses real WHAT fixture entities and their real `WorldPlacement`;
- local System-33 service powers/unpowers fixed emitters;
- player flashlight emission requires real `item.tool.flashlight` equipment;
- no flashlight is silently granted at spawn;
- portable battery/toggle depletion remains deferred rather than faked;
- `DemoLightingSourceAdapter` is inert with zero emitters;
- facing-only turns without an equipped moving source do not rebuild physical lighting.

### Powered non-bloom rooms

- every generated System-19 room materializes one invisible persistent `fixture.room_light` WHAT entity on the EFFECT channel;
- each room fixture binds to the real power service for its cell;
- `light.room_ambient.candidate001` raises physical System-27 luminance while `presentation_glow_scale = 0.0` suppresses additive source bloom/glare;
- ordinary visible lights retain glow;
- local utility outages remove/restore affected room emitters through canonical System-33 mutation;
- dedicated `RoomLightingPowerSmoke.gd` proves luminance-on/no-bloom behavior.

Dedicated exact-head contexts include `verify/system33-power-water` and `verify/system33-lighting-truth`; `System33PowerPhysicalNetworkSmoke.gd` runs inside the System-33 power/water gate.

**Human playtest remains required before Phase 3 / Stage B is marked HUMAN ACCEPTED.**

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

Verified executable: `7ddee8df0e638cbe14897d83632b62513d5fc574`.

All published exact-head contexts for that executable are green.

**Current lifecycle gate: human browser verification of Stage B physical power-network behavior plus the current System-33 lighting/water/refrigeration behavior.**
