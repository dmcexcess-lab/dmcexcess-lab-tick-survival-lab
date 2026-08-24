# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, `ROADMAP.md`, and `README_CONTEXT.md` first.

| Order | System | Status | Canonical design |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 00D | Global World Planning / Generation | **IMPLEMENTED — v6** | `00D_GLOBAL_WORLD_PLANNING.md` + infrastructure children |
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
| 20 | Local Area Generation | **IMPLEMENTED — ten area / seven environment profiles** | `20_LOCAL_AREA_PARCEL_GENERATION.md` |
| 21 | Tactical Camera / View Control | **IMPLEMENTED** | `21_TACTICAL_CAMERA_VIEW_CONTROL.md` |
| 22 | Large-Area DEV Critique Runtime | **IMPLEMENTED** | `22_LARGE_AREA_CRITIQUE_RUNTIME.md` |
| 23 | Perception / LOS / Fog Memory | **IMPLEMENTED — geometry + light/atmosphere-aware acquisition + memory/audio presentation** | `23_PERCEPTION_LOS_FOG_MEMORY.md` |
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Candidate 001** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 25 | World Time / Ambient Daylight | **IMPLEMENTED — Candidate 001** | `25_WORLD_TIME_AMBIENT_DAYLIGHT.md` |
| 26 | Spatial Sound / Hearing | **IMPLEMENTED — Candidate 001 + weather environment seam** | `26_SPATIAL_SOUND_HEARING.md` |
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED — Slices A+B+C + bounded-query optimization + weather optics/lightning input** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED — Slices A+B+C** | `28_WEATHER_ATMOSPHERE.md` |
| 29 | World Interaction Affordance / Reach | **DRAFT — awaiting approval; Roadmap Phase 1A** | `29_WORLD_INTERACTION_AFFORDANCE_REACH.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED — scheduled inside Roadmap Phase 8** | future design |

---

## Roadmap routing

`ROADMAP.md` is the canonical post-System-28 ordering through Beta.

### Phase 1 internal order

1A. **Interaction affordance + reach** — System 29 DRAFT; generalize current System-24 forward-contact reach and highlight only real, currently perceived usable targets.

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

## Current System 29 proposal

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

Candidate 001 preserves System 24's existing actor-footprint + one-cell-forward reach exactly, moves that rule into a neutral reusable owner, composes offers only from real mechanic providers, filters player presentation through current System-23 VISIBLE knowledge, and draws a restrained pixel highlight over the target's visible physical footprint.

The first provider is System-24 searchable containers. Candidate 001 deliberately does not add a universal Interact button or execute actions.

---

## Current Systems 19 / 20 / 00F truth

System 19 exposes 24 callable one-story building archetypes and a stable generated-role -> entity-ID seam. System 20 owns ten area profiles and seven environment palettes with deterministic parcel-fit building selection. System 00F keeps logical source identity independent from technical stream regions and follows:

> **materialization is one-way; activation is reversible.**

Exact-head contexts: `verify/system19-local-building`, `verify/system20-local-area`, `verify/system00f-streaming-materialization`.

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

System 24 currently owns `LootInteractionReach`, shared by search and external container access. Proposed System 29 migrates that exact rule into a neutral interaction-reach owner without changing range behavior. Roadmap Phase 1 then adds spoilage/icons/content; Phase 2 adds crafting on top of real items rather than reward-generation menus.

Exact-head context: `verify/system24-loot`.

---

## Current System 25 truth

System 25 interprets authoritative WHEN ticks as scenario-local time without changing WHEN. Candidate 001 uses 5 ticks/second, starts day 0 at 08:00, and exposes a smooth 05:30–07:30 dawn / 18:30–20:30 dusk outdoor daylight baseline.

System 27 consumes daylight downstream. System 28 uses the same WHEN clock and modulates it through continuous atmospheric optics/lightning without owning a second physical clock. Roadmap Phase 1B spoilage should derive age from authoritative ticks rather than introduce another clock.

Exact-head context: `verify/system25-world-time-light`.

---

## Current System 26 truth

> **Sound is physical. Hearing is an estimate.**

Candidate 001 separates exact `SoundEmission` truth from listener `HeardSoundObservation` knowledge. Weighted material-aware propagation uses current WHAT + Door State; listener hearing derives from a neutral provider seam and current survivor stats/status. Localization uncertainty cannot flip true actor-relative front/rear/left/right signs.

Recognized player-facing cues prefer onomatopoeia (`*step step*`, `*thump thump*`, `*creak*`, `*SLAM*`), while low-confidence recognition remains honest `NOISE`/broader wording.

System 28 supplies rain/wind as competing background noise through the existing environment seam. Current lightning does not invent thunder because the lightning event has no honest strike cell.

Roadmap Phase 6 powered TVs/dialogue and Phase 8 NPC conversations should use real sound/information-source events downstream of real object/actor state.

Exact-head context: `verify/system26-spatial-sound`.

---

## Current System 27 truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

System 27 owns deterministic headless illumination, target-condition useful-range policy, and rich visible lighting. System 23 consumes the neutral acquisition adapter.

Weather feeds continuous cloud/rain/fog/wetness values through `AtmosphericOptics`. System 28 also supplies a short `transient_sky_light` from the real WHEN lightning event.

The physical lightning regression proves the same event brightens an exterior from 0.025 to 0.845 useful luminance and transmits 0.356 useful luminance into a roofed interior through a real window portal.

Roadmap Phase 3 powered fixtures and Phase 6 TVs/appliances must activate real light emitters through source-state adapters; emissive art alone never creates physical light.

Exact-head context: `verify/system27-physical-lighting`.

---

## Current System 28 truth

> **Weather is simulation truth; weather animation is presentation.**

Slices A+B+C are implemented.

Physical Weather remains deterministic/event-driven through WHEN with clear/overcast/rain/storm/fog profiles, continuous precipitation/cloud/fog/wind values, analytic wetness, quantized environment revisions, snapshot schema v2 and deterministic storm lightning.

Presentation is explicitly a **screen-space low-resolution atmosphere overlay**. Camera movement is a compatibility no-op for Weather presentation and requests zero Weather redraws. Rain/fog/debris therefore do not trail, clear or disappear during repeated movement/camera updates.

Weather still retains shelter rejection by mapping a screen rain sample to the corresponding current world cell. It remains below System 23 so this cannot reveal hidden structure truth.

Physical environment integration remains Weather -> System 27 atmospheric optics/wetness/visibility and Weather -> System 26 hearing masking. Slice C adds deterministic LightningEvent, one-tick physical sky flash, portal/perception consequences, stable-seeded bolt presentation and DEV STRIKE, with no fake thunder/damage/fire.

Focused verified outputs on executable head `21014fe5915e47344b4b8d5f48e52fa69c386254` include zero camera-motion Weather redraws and physical lightning 0.025 -> 0.845 exterior / 0.356 interior portal luminance. All 13 required contexts were green there including Pages.

Exact-head context: `verify/system28-weather`.

---

## Current presentation

The live Rural Crossroads critique build has canonical scavenging, time/daylight, physical sound, physical lighting, illumination/atmosphere-aware vision, screen-space low-resolution Weather and real physical lightning.

Weather DEV controls sit below the existing STATS / INVENTORY / MENU header row. Active flashlight/lamp/neon/streetlight sources remain explicitly DEV-only until Roadmap Phase 3/6 real equipment/power/object state replaces them.

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
- `verify/pages-deploy`
