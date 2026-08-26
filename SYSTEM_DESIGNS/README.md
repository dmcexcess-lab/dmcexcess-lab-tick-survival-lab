# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, `ROADMAP.md`, and `README_CONTEXT.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — rural v6 + complete island v1** | `00D_GLOBAL_WORLD_PLANNING.md` + infrastructure children |
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
| 20 | Local Area Generation | **IMPLEMENTED — ten area / seven environment profiles + live river/bridge physicalization** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 23 | Perception / LOS / Fog Memory | **IMPLEMENTED — geometry + light/atmosphere-aware acquisition + memory/audio presentation** | `23_PERCEPTION_LOS_FOG_MEMORY.md` |
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Candidate 001; System-29 reach; System-30 freshness enrollment seam** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 25 | World Time / Ambient Daylight | **IMPLEMENTED — Candidate 001** | `25_WORLD_TIME_AMBIENT_DAYLIGHT.md` |
| 26 | Spatial Sound / Hearing | **IMPLEMENTED — Candidate 001 + weather environment seam** | `26_SPATIAL_SOUND_HEARING.md` |
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED — A+B+C + bounded-query optimization + weather optics/lightning** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED — A+B+C + optimized presentation; human accepted** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **IMPLEMENTED — Candidate 001; Roadmap Phase 1A** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 30 | Item Freshness / Spoilage | **IMPLEMENTED + CI VERIFIED — Candidate 001; Roadmap Phase 1B** | `30_ITEM_FRESHNESS_SPOILAGE.md` |
| 31 | Semantic UI Icons | **DRAFT — Roadmap Phase 1C DESCRIBE complete; awaiting APPROVE** | `31_SEMANTIC_UI_ICONS.md` |
| PERF | Performance Architecture Gate | **IMPLEMENTED + CI VERIFIED — P0/P1/P2; human accepted** | `PERFORMANCE_ARCHITECTURE.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — scheduled inside Roadmap Phase 8** | future design |

---

## Roadmap routing

`ROADMAP.md` is the canonical ordering through Beta.

### Phase 1

1A. **Interaction affordance + reach** — COMPLETE: System 29 Candidate 001.

Performance gate — COMPLETE + HUMAN ACCEPTED. First P0/P1/P2 executable `0398a2a49d84e6067f7610727aecacf4c05fe41f`; Weather P3D human-accepted executable `6016fe5098804e3e6aba6c9f5f9658282036a697`.

1B. **Item freshness/spoilage** — COMPLETE: System 30 Candidate 001. First fully green executable `39716f27b7f91b7007645ceae02dedc47601bf87`; all 16 required exact-head contexts green.

1C. **Semantic inventory/menu icons** — **DESCRIBE COMPLETE; awaiting APPROVE**: System 31 draft provides a presentation-only low-resolution semantic icon atlas/catalog with explicit coverage of current item semantics and icon+text shell controls. Implementation is not authorized yet.

1D. **Large/multi-cell object visual geometry** — presentation-owned span/pivot/overhang independent from physical footprint.

1E. **Content expansion/integration** — broaden perishables and ordinary props/fixtures/vegetation using the new foundations.

Then: Crafting -> Power + Water -> physical survival/health -> Moodlets -> final skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.

---

## Current System 31 draft

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

Candidate 001 is design-only and awaits user approval.

- one dedicated low-resolution `ui_icon_atlas.svg`;
- 16×16 logical icon cells normally drawn at exact 2× / 32×32;
- one shared Node-free/cached `SemanticUiIconCatalog`;
- explicit mapping for all current 71 `LootItemCatalog` semantic types; intentional glyph sharing is allowed, automatic family fallback is not;
- unknown future semantics use an explicit unknown glyph + diagnostic while text remains usable;
- `STATS`, `INVENTORY`, `MENU` use icon + text;
- Inventory hands/carried rows and scavenging `CONTENTS` / `YOUR PACK` use the same item icon vocabulary;
- TAKE/STORE, movement and DEV controls remain text-only in Candidate 001;
- existing item labels, IDs, weight, utility/family and System-30 freshness remain real data beside icons;
- no persistent state, save schema, simulation-tick work, per-item runtime object or world scan;
- selected System-10 silhouettes may be visually repacked with provenance, without runtime dependency on System 10.

Proposed future exact-head context after approved implementation: `verify/system31-semantic-ui-icons`. It is **not** part of the required stack while System 31 remains design-only.

---

## Current System 30 truth

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Candidate 001 is implemented.

- Only explicit semantic freshness profiles are perishable.
- Perishable items receive sparse typed records; shelf-stable items receive none.
- FRESH / AGING / STALE / SPOILED are derived analytically from authoritative time/exposure.
- There is no per-item `_process`, timer, Node or scheduled spoilage event.
- Virgin world perishables use logical scenario origin tick 0 even when technically materialized later.
- System 24 enrolls perishables transactionally and includes freshness in rollback; production loot probabilities and action timing are unchanged.
- Existing inventory/container inspection surfaces expose coarse freshness labels read-only.
- Candidate 001 has ambient exposure only. Phase 3 may later supply real refrigerated exposure through the neutral reanchor/provider seam; System 30 does not import Power.
- Phase 4 later consumes freshness for food/drink consequences; System 30 does not own nutrition/Health.

Exact-head context: `verify/system30-item-freshness`.

---

## Current System 29 truth

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

System-29 `CONTACT_FORWARD` owns neutral reach; System 24 consumes it for search/TAKE/STORE. Real mechanic providers publish read-only offers. System 23 `VISIBLE` knowledge gates highlights. Candidate discovery is bounded to tiny reachable OBJECT occupancy sets, not world scans. Presentation adds no action truth and spends zero WHEN ticks.

Exact-head context: `verify/system29-interaction-affordance`.

---

## Current performance architecture truth

> **A world mutation may update truth many times; expensive consumers wake only for the domains and completed batches they actually depend on.**

WHAT supplies cache-oriented terrain/per-channel revisions and compact bulk summaries while retaining the authoritative global revision. Streaming owns materialization batch boundaries. Lighting/sky exposure ignore irrelevant actor/object churn; perception/interaction/loot wakeups coalesce bulk work. DEV telemetry remains observation-only.

Predictive/amortized streaming remains measured follow-up only if future evidence justifies it.

Exact-head context: `verify/performance-architecture`.

---

## Current world / sensory truth

- System 00D complete-island planning preserves the proven rural-v6 skeleton and deterministic LAND/SHORE/OCEAN.
- System 00F follows **materialization is one-way; activation is reversible**; technical regions are not world identity.
- System 23: **Black = I know nothing. Dark = I remember this place. Full = I can currently acquire what is actually happening.**
- System 24: **Loot exists before you search for it.**
- System 25 interprets authoritative WHEN ticks; it does not create a second simulation clock.
- System 26: **Sound is physical; hearing is an estimate.**
- System 27: **Light is physical; vision is observer-specific.**
- System 28: **Weather is simulation truth; weather animation is presentation.**

---

## Current presentation

The live build is the complete streamed-island critique/playable composition with scavenging, interaction highlighting, freshness labels, time/daylight, spatial sound, physical lighting, illumination/atmosphere-aware vision, optimized low-resolution Weather, and physical lightning.

System 31 remains design-only, so the live build does not yet include the proposed semantic UI icon atlas/catalog.

Weather DEV controls and performance telemetry remain explicitly DEV presentation. Future real equipment/power/object state must replace any DEV-only light-source affordances through existing physical seams.

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
- `verify/performance-architecture`
- `verify/pages-deploy`

All **16 required contexts** are green on System-30 executable head `39716f27b7f91b7007645ceae02dedc47601bf87`.