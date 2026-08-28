# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md`, `PERFORMANCE_NORTH_STAR.md`, `README_SOPS.md`, `ROADMAP.md`, and `README_CONTEXT.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — rural v6 + complete island v2** | `00D_GLOBAL_WORLD_PLANNING.md` + infrastructure children |
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
| 07B | Large / Multi-cell Object Visual Geometry | **IMPLEMENTED + CI VERIFIED; Roadmap Phase 1D complete** | `07B_LARGE_MULTI_CELL_VISUAL_GEOMETRY.md` |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` |
| 10 | Actor Hand Equipment Presentation | **IMPLEMENTED** | `10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md` |
| 11 | Inventory / Containment | **IMPLEMENTED** | `11_INVENTORY_CONTAINMENT.md` |
| 12 | Item Transfer / Pickup / Drop / Equip | **IMPLEMENTED — personal + policy-aware external access** | `12_ITEM_TRANSFER_ACTIONS.md` |
| 13 | Actor Stats / Status Architecture | **IMPLEMENTED via children; roadmap expansion ahead** | `13_ACTOR_STATS_STATUS_ARCHITECTURE.md` |
| 13A | Actor Health / Injury | **IMPLEMENTED scaffold; expanded Phase 4 gameplay ahead** | `13A_ACTOR_HEALTH_INJURY.md` |
| 13B | Actor Needs / Rest | **IMPLEMENTED scaffold; Phase 4 fatigue/sleep expansion ahead** | `13B_ACTOR_NEEDS_REST.md` |
| 13C | Actor Skills | **IMPLEMENTED scaffold; final catalog replaced in Phase 6** | `13C_ACTOR_SKILLS.md` |
| 13D | Item Physical Properties | **IMPLEMENTED** | `13D_ITEM_PHYSICAL_PROPERTIES.md` |
| 13E | Actor Carry / Encumbrance | **IMPLEMENTED** | `13E_ACTOR_CARRY_ENCUMBRANCE.md` |
| 13F | Actor Moodlets / Status Derivation | **IMPLEMENTED scaffold; expanded Phase 5 gameplay ahead** | `13F_ACTOR_MOODLETS.md` |
| 14 | Canonical Playable Demo Integration | **IMPLEMENTED** | `14_CANONICAL_PLAYABLE_DEMO.md` |
| 15 | Canonical HUD / Facing Inspection | **IMPLEMENTED** | `15_CANONICAL_HUD_FACING_INSPECTION.md` |
| 16 | Canonical Player Shell / Inspectors / Stance | **IMPLEMENTED** | `16_CANONICAL_PLAYER_SHELL.md` |
| 17 | Run / Damage-Interruptible Walking | **IMPLEMENTED** | `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` |
| 17A | Movement Exertion / Encumbrance / Run Impact | **IMPLEMENTED** | `17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md` |
| 17A.1 | Overweight Walk Fatigue / Carry Ceiling | **IMPLEMENTED** | `17A1_OVERWEIGHT_WALK_FATIGUE_HARD_CARRY_LIMIT.md` |
| 18 | Door Interaction / Automatic Passage | **IMPLEMENTED** | `18_DOOR_INTERACTION_PASSAGE.md` |
| 19 | Local Building Generation / Grammar | **IMPLEMENTED — FINALIZED, 24 archetypes** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
| 20 | Local Area Generation | **IMPLEMENTED — ten area / seven environment profiles + live river/bridge physicalization + shared island ecology seam** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 23 | Perception / LOS / Fog Memory | **IMPLEMENTED — geometry + light/atmosphere-aware acquisition + memory/audio presentation** | `23_PERCEPTION_LOS_FOG_MEMORY.md` |
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Candidate 001; System-29 reach; System-30 freshness enrollment seam** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 25 | World Time / Ambient Daylight | **IMPLEMENTED — Candidate 001** | `25_WORLD_TIME_AMBIENT_DAYLIGHT.md` |
| 26 | Spatial Sound / Hearing | **IMPLEMENTED — Candidate 001 + weather environment seam** | `26_SPATIAL_SOUND_HEARING.md` |
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED — A+B+C + bounded-query optimization + Weather/lightning + 07B-era soft bloom presentation** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED — A+B+C + optimized presentation; human accepted** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **IMPLEMENTED — Candidate 001; Roadmap Phase 1A** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 30 | Item Freshness / Spoilage | **IMPLEMENTED + CI VERIFIED — Candidate 001; Roadmap Phase 1B** | `30_ITEM_FRESHNESS_SPOILAGE.md` |
| 31 | Semantic UI Icons | **IMPLEMENTED + CI VERIFIED — Candidate 001; Roadmap Phase 1C** | `31_SEMANTIC_UI_ICONS.md` |
| PERF | Performance Architecture Gate | **IMPLEMENTED + CI VERIFIED — P0/P1/P2; human accepted** | `PERFORMANCE_ARCHITECTURE.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — scheduled inside Roadmap Phase 8** | future design |

## Cross-system roadmap designs

| Phase | Status | Canonical design |
|---|---|---|
| 1E — Content Expansion + Integration | **DESCRIBED — awaiting approval; not a new runtime system** | `PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md` |

---

## Roadmap routing

### Phase 1

1A. Interaction affordance + reach — **COMPLETE**: System 29 Candidate 001.

Performance gate — **COMPLETE + HUMAN ACCEPTED**.

1B. Item freshness/spoilage — **COMPLETE**: System 30 Candidate 001.

1C. Semantic inventory/menu icons — **COMPLETE**: System 31 Candidate 001.

1D. Large/multi-cell object visual geometry — **COMPLETE + CI VERIFIED**: System 07B Candidate 001. Verified executable/workflow head `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`.

1E. Content expansion/integration — **DESCRIBED, AWAITING APPROVAL**: enrich existing owner vocabularies and integrate them across generated locations; no System 32.

Then: Crafting -> Power + Water -> physical survival/health -> Moodlets -> final skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.

---

## Current System 07B truth

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

Candidate 001 is implemented and CI verified.

- presentation-only Node-free span/pivot descriptors;
- one stable entity -> one shared cached logical visual plan;
- exact historical 1x1 fallback for unmapped props;
- System 07A remains orientation owner;
- z20 base + optional z35 foreground above actors and below physical lighting;
- bounded two-cell discovery halo for just-offscreen visual overhang;
- dedicated large-tree and traffic-light proof art;
- broader soft System-27 presentation bloom derived only from real emitter truth;
- no collision, reach, LOS, WHEN, save, streaming or per-object runtime-object ownership.

Exact-head context: `verify/system07b-large-visual-geometry`.

All **18 current required contexts** are green on `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`.

Human visual acceptance of the new 07B art/glow remains separate from automated verification.

---

## Current Phase 1E draft truth

> **Content extends the system that already owns its truth. Integration does not create a second owner.**

Phase 1E is a cross-system integration phase, not System 32.

Candidate implementation order after approval:

1. `1E-1` world clutter + location identity through existing Systems 19/20/04/07B;
2. `1E-2` mundane loot + perishable breadth through Systems 24/13D/30/31;
3. `1E-3` integration/readability/performance/human acceptance using existing 29/27 presentation truth.

The draft forbids fake Crafting, Power/Refrigeration, nutrition/Health, Skills, Vehicles, combat or AI behavior.

Canonical draft: `PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`.

The next lifecycle gate is **APPROVE or revise Phase 1E**.

---

## Current complete-island continuity truth

Verified executable: `d33c69d6bd05f4c8fdbba62c6bd51bb16aad26ad`.

- island v2 no longer reuses the historical standalone central-site seed identity;
- island-only settlement spacing is compact while protected regional rural-v6 behavior remains unchanged;
- island surface and settlement natural dressing share world-seed + absolute-cell `NaturalEcologyField` identity;
- logical 256x256 area rectangles cannot restart ecology patches;
- 00F source ownership, 128x128 technical streaming, WHAT/WHEN, roads/hydrology/bridges and System-19 building ownership remain unchanged;
- user visually accepted the corrected deployed island.

---

## Current semantic item/readability truth

System 24: **Loot exists before you search for it.** Search/transfer acts on persistent real contents.

System 29: **A highlight explains an already-valid interaction. It never creates interaction truth.**

System 30: **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

System 31: **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

Phase 1E must extend those existing vocabularies together: added items need weight + explicit UI icon, added perishables need freshness, and new searchable furniture needs real System-24 capability rather than art-based inference.

---

## Required executable-head stack

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/system25-world-time-light`
- `verify/system26-spatial-sound`
- `verify/system27-physical-lighting`
- `verify/system28-weather`
- `verify/system29-interaction-affordance`
- `verify/system30-item-freshness`
- `verify/system31-semantic-ui-icons`
- `verify/system07b-large-visual-geometry`
- `verify/performance-architecture`
- `verify/pages-deploy`

All **18 required contexts** are green on current verified executable/workflow head `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`.

If Phase 1E is approved and implemented, proposed `verify/phase1e-content-integration` becomes the nineteenth required context for that implementation.
