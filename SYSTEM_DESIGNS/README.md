# Tick Survival Lab — System Design Index / Approval Ledger

Canonical status/routing index. Read `PROJECT_NORTH_STAR.md` and `README_SOPS.md` first.

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
| 23 | Perception / LOS / Fog Memory | **IMPLEMENTED — geometry + light-aware acquisition + memory/audio presentation** | `23_PERCEPTION_LOS_FOG_MEMORY.md` |
| 24 | World Loot / Searchable Containers / Scavenging | **IMPLEMENTED — Candidate 001** | `24_WORLD_LOOT_SEARCHABLE_CONTAINERS.md` |
| 25 | World Time / Ambient Daylight | **IMPLEMENTED — Candidate 001** | `25_WORLD_TIME_AMBIENT_DAYLIGHT.md` |
| 26 | Spatial Sound / Hearing | **IMPLEMENTED — Candidate 001 + onomatopoeia / cue lifetime refinement** | `26_SPATIAL_SOUND_HEARING.md` |
| 27 | Physical Lighting / Illumination / Shadows | **IMPLEMENTED — Slices A+B+C + bounded-query optimization** | `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md` |
| 28 | Weather / Atmosphere | **IMPLEMENTED — Slice A; B/C deferred** | `28_WEATHER_ATMOSPHERE.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | future design |

## Current System 19 / 20 / 00F truth

System 19 exposes 24 callable one-story building archetypes and a stable generated-role -> entity-ID seam. System 20 owns ten area profiles and seven environment palettes with deterministic parcel-fit building selection. System 00F keeps logical source identity independent from technical stream regions and follows **materialization is one-way; activation is reversible**.

Exact-head contexts: `verify/system19-local-building`, `verify/system20-local-area`, `verify/system00f-streaming-materialization`.

## Current System 23 truth

> **Black = I know nothing. Dark = I remember this place. Full = I can currently acquire what is actually happening.**

System 23 geometry provides the 12-cell / 120-degree maximum candidate envelope plus radius-1 near awareness. A neutral `VisualAcquisitionProvider` filters geometric candidates before they become `VISIBLE`; only acquired cells refresh observer memory.

The live game injects System 27's target-light acquisition adapter. Darkness can therefore shrink current acquired vision while physical light expands it toward illuminated targets. Opaque geometry remains authoritative first. REMEMBERED stays stale and UNSEEN stays true black.

System 26 auditory observations remain orthogonal to visual fog and do not reveal terrain. Player-facing lifetime classification uses the perceived auditory cell, never exact hidden source truth: VISIBLE sound text fades by about one second; REMEMBERED/UNSEEN sound text latches at its uncertain location until the next observer action/unpause.

Exact-head context: `verify/system23-perception`.

## Current System 24 truth

> **Loot exists before you search for it.**

Candidate 001 provides deterministic one-way persistent loot initialization into physical System 11 containers, location-aware tables, timed search and timed TAKE/STORE through System 12. Empty/looted containers do not automatically repopulate.

Exact-head context: `verify/system24-loot`.

## Current System 25 truth

System 25 interprets authoritative WHEN ticks as scenario-local time without changing WHEN. Candidate 001 uses 5 ticks/second, starts day 0 at 08:00, and exposes a smooth 05:30–07:30 dawn / 18:30–20:30 dusk outdoor daylight baseline.

Exact-head context: `verify/system25-world-time-light`.

## Current System 26 truth

> **Sound is physical. Hearing is an estimate.**

Candidate 001 separates exact `SoundEmission` truth from listener `HeardSoundObservation` knowledge. Weighted material-aware propagation uses current WHAT + Door State; listener hearing derives from a neutral provider seam and current survivor stats/status. Localization uncertainty cannot flip true actor-relative front/rear/left/right signs.

Recognized player-facing cues prefer onomatopoeia (`*step step*`, `*thump thump*`, `*creak*`, `*SLAM*`), while low-confidence recognition remains honest `NOISE`/broader wording.

Underlying heard observations age by WHEN ticks. Player presentation is separate: a cue whose perceived cell is VISIBLE is a ~1-second transient fade; one whose perceived cell is REMEMBERED/UNSEEN is latched at that approximate cell until the listener starts the next action. Opaque cue/group IDs allow replacement and suppression without exposing exact source identity.

Future AI consumes ordinary `HeardSoundObservation`, not the player renderer's latch.

Latest fully green executable refinement head: `aa5e1b622c8efe555d22e5d56514b9490776be16`.

Exact-head context: `verify/system26-spatial-sound`.

## Current System 27 truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

Slice A owns deterministic headless illumination and the target-cell useful-range policy. Slice B renders darkness/tint/glow/scatter below System 23. Slice C makes live observer acquisition consume physical target illumination through a neutral System 23 provider seam.

The current provider guarantees a 25×25 observer-centered light-query envelope only when the presentation field does not already cover the survivor's full 12-cell geometric vision area. Camera movement therefore does not become gameplay vision truth, while normal camera-following play can reuse the current lighting field.

The 2026-08-24 optimization keeps all existing physical/visual rules but caches materialized/topology/optical facts, evaluates local emitters only inside their useful-range rectangles, prepares presentation queries once per map refresh, and reuses lighting image buffers. An 80×96 / four-light CI fixture proves 1,676 bounded emitter candidates and 688 optical-ray candidates versus 30,720 naive full-field-per-emitter visits.

Latest fully green optimized pre-Weather executable head: `5958d887807e5b64c9fc4cf5d3d45c7dfd4083d2`.

Exact-head context: `verify/system27-physical-lighting`.

## Current System 28 truth

> **Weather is simulation truth; weather animation is presentation.**

Slice A is implemented. Physical Weather is deterministic and event-driven through WHEN; clear/overcast/rain/storm/fog expose continuous precipitation/cloud/fog/wind values plus analytic wetness. No per-tick Weather loop exists.

The low-resolution presentation owner animates at a bounded 20 Hz, remains below System 23, shelter-masks rain through cached sky exposure, and uses no per-particle child Nodes. Calm clear weather can remain visually alive with rare leaf/paper/dust motion while retaining a hard three-piece cosmetic cap and no gameplay identity.

The Rural Crossroads critique build starts in DEV rain for immediate inspection and exposes CLEAR/OVERCAST/RAIN/STORM/FOG plus `BLOW LEAF` controls.

Slices B/C remain deferred: Weather does not yet alter System 27 physical optics, System 26 hearing, or System 23 visibility through fog/rain, and lightning is not implemented yet.

First fully green executable Slice A head: `dcb400b8507c23a2fc5bdaecf551bc5c0512acce`.

Exact-head context: `verify/system28-weather`.

## Current presentation

The live Rural Crossroads critique build has canonical scavenging, time/daylight, physical sound, physical lighting, illumination-aware vision, and **low-resolution animated Weather A**. Sound is represented with yellow onomatopoeia/uncertainty text. Active flashlight/lamp/neon/streetlight sources remain explicitly DEV-only until real equipment/power owners exist. Weather A is also exposed through a clearly labeled DEV selector while climate/world-front logic remains future work.

## Required exact-head stack

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
