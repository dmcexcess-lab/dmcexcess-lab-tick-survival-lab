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
| 13C | Actor Skills | **IMPLEMENTED scaffold; final catalog replaced in Roadmap Phase 6** | `13C_ACTOR_SKILLS.md` |
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
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Candidate 001** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 25 | World Time / Ambient Daylight | **IMPLEMENTED — Candidate 001** | `25_WORLD_TIME_AMBIENT_DAYLIGHT.md` |
| 26 | Spatial Sound / Hearing | **IMPLEMENTED — Candidate 001 + weather environment seam** | `26_SPATIAL_SOUND_HEARING.md` |
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED — Slices A+B+C + bounded-query optimization + weather optics/lightning input** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED — Slices A+B+C** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **APPROVED — Candidate 001; Roadmap Phase 1A** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — scheduled inside Roadmap Phase 8** | future design |

---

## Roadmap routing

`ROADMAP.md` is the canonical post-System-28 ordering through Beta.

### Phase 1 internal order

1A. **Interaction affordance + reach** — **System 29 APPROVED; implementation authorized 2026-08-24**. Generalize current System-24 forward-contact reach and highlight only real, currently perceived usable targets.

1B. **Item freshness/spoilage** — typed per-instance freshness, analytic world-time aging, future refrigeration-rate seam; no per-item tick loop.

1C. **Semantic inventory/menu icons** — low-resolution UI icon vocabulary with deterministic coverage of current loot/menu semantics.

1D. **Large/multi-cell object visual geometry** — presentation-owned visual span/pivot/overhang so physical multi-cell objects can actually look large.

1E. **Content expansion/integration** — broaden perishables and ordinary props/fixtures/vegetation using the new foundations.

Then:

2. Crafting;
3. three-tier Power + Water utilities, with active wastewater gameplay removed;
4. player physical survival/health — hunger, thirst, sleep/exhaustion, health and **fatigue**; fatigue is the stamina/endurance concept and there is no separate stamina meter;
5. Moodlets — comfort/fear/boredom plus escalating need-state presentation/consequences;
6. final concrete skills + broad world/item interactions;
7. Vehicles;
8. Actor/NPC AI + combat + causal outbreak;
9. final graphics/UI overhaul -> Beta.

The roadmap does **not** pre-authorize all implementation. Each independently owned phase/system still follows DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY.

---

## Approved System 29 Candidate 001

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

Candidate 001 preserves System 24's existing actor-footprint + one-cell-forward reach exactly and moves that rule into a neutral reusable owner. Real mechanic providers publish read-only interaction offers; System 29 composes those offers, filters player presentation through current System-23 `VISIBLE` knowledge, and draws a restrained pixel highlight over only the target's currently visible physical footprint cells.

The first provider is System-24 searchable containers and the first offer is `SEARCH`. Candidate 001 deliberately does not add a universal Interact button or execute actions. Discovery is actor-local through WHAT occupancy and must not scan all world entities.

System 29 remains **APPROVED** until its implementation and focused exact-head contract are green; only then should this ledger mark it IMPLEMENTED.

---

## Current world-generation / materialization truth

System 00D now has two protected world profiles:

- `temperate.rural.region` v6 — mature connected rural-region planning;
- `temperate.island.region` v1 — additive complete-island composition over that proven skeleton with deterministic LAND / SHORE / OCEAN, shoreline-clipped roads, recomputed bridge intent and adapted power ingress.

The complete island keeps the five proven connected sites rather than forcing the broader local morphology library into globally unsuitable locations. System 20 still owns ten area profiles and seven environment palettes; those profiles remain callable content for later world/site planners.

System 00F keeps logical source identity independent from technical stream regions and follows:

> **materialization is one-way; activation is reversible.**

The live island partition is:

1. five settlement area-site sources;
2. exact physical river/watercourse sources;
3. island-surface sources for all remaining cells inside world bounds.

The current playable island uses real player-following streaming at 128×128 technical regions with active radius 1. Those values are configuration, not geography or persistent identity.

Exact-head contexts: `verify/system00d-global-world`, `verify/system00f-streaming-materialization`, `verify/system19-local-building`, `verify/system20-local-area`.

---

## Current System 23 truth

> **Black = I know nothing. Dark = I remember this place. Full = I can currently acquire what is actually happening.**

System 23 geometry provides the 12-cell / 120-degree maximum candidate envelope plus radius-1 near awareness. A neutral `VisualAcquisitionProvider` filters geometric candidates before they become `VISIBLE`; only acquired cells refresh observer memory.

The live game injects System 27's acquisition adapter. Darkness and physical atmospheric extinction may shrink current acquired vision while physical light expands it toward illuminated targets. Opaque geometry remains authoritative first. REMEMBERED stays stale and UNSEEN stays true black.

System 29's player highlight must consume this existing knowledge rather than expose hidden WHAT targets. Roadmap Phase 6 Awareness/Sneak must extend observer/signal contracts rather than bypass them. Roadmap Phase 8 NPC AI receives ordinary observer knowledge rather than hidden world truth.

Exact-head context: `verify/system23-perception`.

---

## Current System 24 truth

> **Loot exists before you search for it.**

Candidate 001 provides deterministic one-way persistent loot initialization into physical System 11 containers, location-aware tables, timed search and timed TAKE/STORE through System 12. Empty/looted containers do not automatically repopulate.

Before the approved System-29 migration, System 24 owns `LootInteractionReach`, shared by search and external container access. System 29 Candidate 001 moves that exact rule into a neutral owner with zero reach rebalance. Roadmap Phase 1 then adds spoilage/icons/content; Phase 2 adds crafting on top of real items rather than reward-generation menus.

Exact-head context: `verify/system24-loot`.

---

## Current Systems 25–28 truth

**25 World Time:** authoritative WHEN ticks are interpreted as scenario-local time. Candidate 001 uses 5 ticks/second and starts day 0 at 08:00; hard pause freezes time automatically. Phase 1B spoilage must age from this authoritative time rather than create a second clock. Exact context: `verify/system25-world-time-light`.

**26 Spatial Sound:** **Sound is physical; hearing is an estimate.** Material-aware propagation reads WHAT + Door State and produces listener-specific uncertain observations. Weather supplies competing rain/wind masking. Current lightning has no fake thunder because it lacks an honest strike cell. Exact context: `verify/system26-spatial-sound`.

**27 Physical Lighting:** **Light is physical; vision is observer-specific.** Gameplay/AI never read rendered pixels as illumination truth. System 27 supplies deterministic headless light/shadow/portal facts and the acquisition adapter consumed by System 23. Weather optics/wetness and physical lightning feed the same backend. Exact context: `verify/system27-physical-lighting`.

**28 Weather:** **Weather is simulation truth; weather animation is presentation.** Physical clear/overcast/rain/storm/fog, analytic wetness and deterministic lightning are WHEN-driven. Rain/fog/debris are a low-resolution screen-space overlay whose animation advances zero simulation ticks. Exact context: `verify/system28-weather`.

---

## Current presentation

The live build is the **complete streamed island critique/playable composition** with scavenging, time/daylight, physical sound, physical lighting, illumination/atmosphere-aware vision, screen-space low-resolution Weather and real physical lightning.

The player still begins in the central Rural Crossroads/diner area, but that area now exists inside the complete island rather than being the entire playable world.

Weather DEV controls remain below the STATS / INVENTORY / MENU header row. Active flashlight/lamp/neon/streetlight sources remain explicitly DEV-only until Roadmap Phase 3/6 real equipment/power/object state replaces them.

---

## Required executable-head stack before System 29 implementation closes

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
- `verify/pages-deploy`

System 29 implementation must add `verify/system29-interaction-affordance` and pass it on the exact executable head before being marked IMPLEMENTED.