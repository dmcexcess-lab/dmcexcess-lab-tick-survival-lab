# Tick Survival Lab — System 26 Spatial Sound / Hearing

Status: **IMPLEMENTED — Candidate 001**

User direction, 2026-08-23:

> **“yellow words that are effected by player stats. but even the random location has to make sense, even the worst perception isn't going to see a noise behind him as in front of him.”**

Core rule:

> **Sound is physical. Hearing is an estimate.**

First fully green executable head: `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.

Exact-head owner: `verify/system26-spatial-sound`.

## 1. Ownership

System 26 owns:

- exact transient physical sound emissions;
- deterministic acoustic propagation through current materialized WHAT + Door State geometry;
- acoustic material/transmission costs;
- neutral listener-hearing provider and environmental acoustic-modifier seams;
- listener-specific detection, recognition and localization;
- recent heard-sound observations and world-tick aging/grouping;
- observer-facing auditory descriptors for presentation and future AI.

System 26 reads but does not own WHAT, Door State, WHEN, Skills, Needs, Movement or Door transition events.

It does **not** own visual LOS/memory, AI decisions, ordinary audio playback, weather, combat, generation, streaming, source gameplay actions or save-file orchestration.

## 2. Two truths

`SoundEmission` is exact simulation truth and may contain the exact origin/source identity.

`HeardSoundObservation` is listener knowledge and contains only:

- listener ID;
- heard tick;
- perceived cell;
- perceived strength/certainty;
- recognized yellow word/category;
- expiry tick;
- opaque repeated-cue group identity.

It deliberately contains **no exact source cell or source entity ID**. Player UI and future AI consume heard observations, not exact emissions.

## 3. Physical propagation

Candidate 001 uses one bounded deterministic weighted eight-neighbor wavefront per emission.

Base travel costs:

- cardinal open-air step: `10`;
- diagonal open-air step: `14`;
- hard radius ceiling: `128` cells.

Structure attenuation additions:

- open air: `0`;
- open door: `4`;
- window: `36`;
- closed door: `64`;
- wall: `124`;
- unknown/malformed structure: `132` conservative attenuation.

Sound is not visual LOS and not Collision. Walls strongly muffle rather than universally deleting sound, and the weighted solver may route around a wall through a cheaper opening. Diagonal propagation cannot leak through a zero-width corner sealed by two strong barriers.

Detailed Candidate 001 propagation never invents unknown/unmaterialized cells.

## 4. Source profiles

Current live profiles:

- walk step: acoustic power `120`, cue lifetime `30` ticks;
- Run stride: `200`, lifetime `35`;
- normal door transition: `180`, lifetime `35`;
- loud door transition: `240`, lifetime `40`.

CI additionally owns a `test.impact` profile at `320`.

These are gameplay acoustic units, not claimed decibels.

## 5. Real event integration

`ActionSoundEmitterAdapter` observes existing truthful public events; source systems remain sound-agnostic.

Live Candidate 001 emits from:

- successful Walk forward/back commits;
- each successful Run stride;
- `DoorPhysicalTransitionService.transition_resolved`, including its existing normal/loud distinction.

Rejected/failed movement produces no step sound. Run is not double-emitted through the general movement-complete signal.

Search/rummaging is intentionally deferred until System 24 exposes a truthful physical search phase/event worth sounding. No fake mystery noises are injected into normal play.

## 6. Hearing profile

The neutral `HearingProfileProvider` keeps species/actor hearing replaceable. The live survivor adapter derives effective hearing from existing persistent truth instead of inventing a new Perception stat.

Candidate survivor score:

- base `50`;
- Survival level 0..10: `+4` per level, max `+40`;
- fatigue 0..100: up to `-15`;
- sleep pressure 0..100: up to `-20`;
- clamp `0..100`.

Detection threshold is `60 - round(score * 0.40)` remaining acoustic-energy units. Stronger hearing therefore detects weaker residual signals.

Recognition uses hearing, received signal and an optional domain-skill level. Current movement/door vocabulary uses Survival.

## 7. Deterministic localization uncertainty

Localization is computed once per physical event/listener and stored. Presentation never rerolls it per frame.

Poor conditions degrade range more aggressively than broad direction:

- angular error trends from about `±60°` at poor quality toward about `±8°` at high quality;
- range error trends from about `±70%` toward about `±10%`;
- very near strong sounds clamp to materially tighter error.

### Hard directional invariant

Actor-relative signs are enforced after uncertainty:

- a true front sound remains in the front half-plane;
- a true rear sound remains in the rear half-plane;
- true left remains left;
- true right remains right;
- diagonal sources therefore remain in the same broad quadrant.

A bad listener may estimate a rear-left noise at the wrong distance or broad bearing, but can never move it into front-right space.

Localization also widens with muffling/path loss. The jitter seed is deterministic from stable event/listener identity.

## 8. Recognition / yellow words

Candidate vocabulary includes tiered labels such as:

- `NOISE -> MOVEMENT -> FOOTSTEPS`;
- `NOISE -> IMPACT -> THUD`.

Low skill/weak signal yields less-specific information rather than fabricated confident misclassification.

The controlled survivor knows their own deliberate sound and receives exact/self-recognized feedback; other listeners still resolve the same physical emission through normal hearing uncertainty.

## 9. Presentation

System 23 remains the visual knowledge/presentation owner. System 26 supplies auditory descriptors.

`PerceptionOverlayRenderer` now draws yellow text instead of the old synthetic crosshair. Yellow words may appear over:

- `VISIBLE`;
- `REMEMBERED`;
- fully black `UNSEEN`.

They never reveal terrain, refresh visual memory, mark a cell explored or expose a hidden actor sprite.

Off-screen cues clamp to the viewport edge using the **perceived** location and use simple direction text such as `< FOOTSTEPS`, `FOOTSTEPS >`, `^ THUD`, or `v NOISE`.

Cue emphasis is influenced by perceived strength/certainty and remains phone/browser friendly.

## 10. Time / grouping / persistence boundary

Auditory observations age only by authoritative WHEN ticks. Auto-pause and hard pause therefore preserve a cue while the player is deciding.

Repeated events with the same opaque source/category group refresh one active listener cue rather than leaving a trail of stale labels.

`HeardSoundObservationStore` has deterministic snapshot schema v1 for active listener knowledge. System 26 does not persist transient exact emissions and does not own save orchestration.

## 11. Future environment / actor seams

`AcousticEnvironmentModifier` is neutral in Candidate 001 and provides narrow hooks for future:

- propagation attenuation/masking;
- detection-threshold changes;
- localization-quality changes.

Weather, machinery and background noise can later provide an adapter without changing core acoustics.

`HearingProfileProvider` likewise permits infected, animals and other actors to use different hearing capability without rewriting propagation.

Future AI must consume `HeardSoundObservation`, never exact hidden `SoundEmission` coordinates.

## 12. Performance

System 26 is event-driven; there is no `_process()` / `_physics_process()` sound scan and no per-cell Node graph.

On first fully green executable head `2d3dcfa6...`, CI measured a 100-run common walk-footstep wavefront average of:

`SPATIAL_SOUND_FOOTSTEP_AVG_US=13268.29`

That passes the Candidate 001 `<16,000 µs` single-field target, but the margin is intentionally treated as a scale seam. Before many simultaneous noisy actors/infected exist, profiling may justify tighter power-derived bounds, shared/cached fields, listener-target pruning, or a coarse distant propagation layer. The current result is acceptable for the present sparse local actor count, not proof of unlimited emitter scale.

## 13. Verification

Dedicated workflow: `.github/workflows/spatial-sound.yml`.

Primary smoke: `game/scripts/ci/SpatialSoundSmoke.gd`.

It proves:

- source/profile validation and Run > Walk loudness;
- derived survivor hearing differences;
- cardinal/diagonal acoustic travel;
- open/closed door, window and wall attenuation ordering;
- cheaper routing around high-loss barriers;
- no invented unmaterialized-space propagation;
- stat-dependent heard/not-heard resolution;
- hard front/rear/left/right localization invariants;
- no exact source truth in listener observations;
- stored deterministic localization/no presentation reroll;
- repeated cue grouping;
- world-tick pause/expiry semantics;
- deterministic observation snapshot roundtrip;
- yellow-word descriptor presentation;
- common-footstep performance budget;
- WHEN, Movement, Run, Door, System 23 and canonical startup regressions.

On executable head `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`, System 26 and all ten protected exact-head contexts were green, including Pages.