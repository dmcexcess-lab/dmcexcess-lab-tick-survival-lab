# Tick Survival Lab — System 26 Spatial Sound / Hearing

Status: **IMPLEMENTED — Candidate 001 + onomatopoeia / seen-vs-unseen cue presentation**

Original user direction, 2026-08-23:

> **“yellow words that are effected by player stats. but even the random location has to make sense, even the worst perception isn't going to see a noise behind him as in front of him.”**

Presentation refinement, 2026-08-24:

> **“lets replaces some or most of them with their onimonapias. like *step step* for seen noises they fade after a sec, for unseen sounds they stay in the aprrox position until the next unpause.”**

Core rule:

> **Sound is physical. Hearing is an estimate.**

First fully green original Candidate 001 executable head: `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.

First fully green onomatopoeia / cue-lifetime refinement executable head: `aa5e1b622c8efe555d22e5d56514b9490776be16`.

Exact-head owner: `verify/system26-spatial-sound`.

---

## 1. Ownership

System 26 owns:

- exact transient physical sound emissions;
- deterministic acoustic propagation through current materialized WHAT + Door State geometry;
- acoustic material/transmission costs;
- neutral listener-hearing provider and environmental acoustic-modifier seams;
- listener-specific detection, recognition and localization;
- recent heard-sound observations and world-tick aging/grouping;
- observer-facing auditory descriptors for presentation and future AI;
- the neutral listener action-start lifecycle signal used by player presentation to clear stale unseen hearing markers.

System 26 reads but does not own WHAT, Door State, WHEN, Skills, Needs, Movement or Door transition events.

It does **not** own visual LOS/memory, AI decisions, ordinary audio playback, weather, combat, generation, streaming, source gameplay actions, player-facing visual fade timing or save-file orchestration.

---

## 2. Two truths

`SoundEmission` is exact simulation truth and may contain the exact origin/source identity.

`HeardSoundObservation` is listener knowledge and contains only:

- listener ID;
- heard tick;
- perceived cell;
- perceived strength/certainty;
- recognized display word/category;
- expiry tick;
- opaque repeated-cue group identity.

It deliberately contains **no exact source cell or source entity ID**. Player UI and future AI consume heard observations, not exact emissions.

Presentation descriptors may additionally expose stable **opaque** `cue_id` / `group_id` values so the UI can update or suppress a cue without receiving hidden source truth.

---

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

---

## 4. Source profiles

Current live physical profiles remain:

- walk step: acoustic power `120`, observation lifetime `30` ticks;
- Run stride: `200`, lifetime `35`;
- normal door transition: `180`, lifetime `35`;
- loud door transition: `240`, lifetime `40`.

CI additionally owns a `test.impact` profile at `320`.

These are gameplay acoustic units, not claimed decibels. The presentation refinement changed words/lifetimes of **display cues**, not acoustic power, propagation or observation lifetime.

---

## 5. Real event integration

`ActionSoundEmitterAdapter` observes existing truthful public events; source systems remain sound-agnostic.

Live Candidate 001 emits from:

- successful Walk forward/back commits;
- each successful Run stride;
- `DoorPhysicalTransitionService.transition_resolved`, including its existing normal/loud distinction.

Rejected/failed movement produces no step sound. Run is not double-emitted through the general movement-complete signal.

Search/rummaging remains deferred until System 24 exposes a truthful physical search phase/event worth sounding. No fake mystery noises are injected into normal play.

---

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

---

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

---

## 8. Recognition / onomatopoeia vocabulary

Recognition remains tiered. Low-quality hearing yields **less information**, not a confidently wrong classification.

Current player-facing profile vocabulary:

- Walk: `NOISE -> *scuff* -> *step step*`;
- Run: `NOISE -> *thump thump* -> *step step step*`;
- normal door transition: `NOISE -> *thunk* -> *creak*`;
- loud door transition: `NOISE -> *BANG* -> *SLAM*`;
- CI impact: `NOISE -> *thud* -> *THUD*`.

Case and punctuation are preserved. Onomatopoeia is presentation vocabulary only; it does not alter source category, physical power or AI access to heard observations.

The controlled survivor knows their own deliberate sound and receives exact/self-recognized feedback; other listeners still resolve the same physical emission through normal hearing uncertainty.

---

## 9. Player auditory presentation

System 23 remains the visual knowledge/presentation owner. System 26 supplies listener descriptors.

Yellow sound text may appear over:

- `VISIBLE`;
- `REMEMBERED`;
- fully black `UNSEEN`.

It never reveals terrain, refreshes visual memory, marks a cell explored or exposes a hidden actor sprite.

### 9.1 Seen cue

For presentation lifetime, **seen** means:

> the sound's already-uncertain `perceived_cell` is currently `VISIBLE` to System 23 when the cue arrives.

This deliberately does **not** ask whether the exact hidden source is visible.

A seen cue:

- appears at the perceived cell;
- remains full-strength briefly;
- begins fading after about `350 ms`;
- reaches zero at about `1 second`;
- uses presentation wall-clock time only for the visual fade;
- advances zero WHEN ticks.

The renderer uses a small timer only while a seen cue is actively fading. There is no continuous sound-simulation `_process()` loop.

### 9.2 Unseen cue

If the perceived cell is `REMEMBERED` or `UNSEEN` when the cue arrives, the cue becomes an **unseen hearing marker**.

It:

- remains at the same stored approximate/perceived location;
- may remain even after the underlying transient `HeardSoundObservation` has expired by WHEN ticks;
- clears when that listener next starts/commits an action — the next decision unpause;
- is presentation memory only and is not added to AI hearing state or save truth;
- cannot expose exact source identity/location.

This makes the marker useful while the player is paused deciding what to do, without turning hearing into permanent map knowledge.

### 9.3 Repeated cues / suppression

Repeated events with the same opaque group update/replace the previous presentation cue instead of leaving a breadcrumb trail.

When a seen cue finishes fading or an unseen cue is cleared on unpause while its underlying observation is still temporarily reported upstream, that exact opaque cue ID is suppressed until upstream stops reporting it. This prevents a cleared marker from immediately reappearing because of observation-store lifetime.

### 9.4 Offscreen cues

Offscreen cues still clamp to the viewport edge using the **perceived** location, never the exact source location.

---

## 10. Simulation time / observation grouping / persistence boundary

Underlying `HeardSoundObservation` records continue to age only by authoritative WHEN ticks. Hard pause therefore freezes **simulation hearing knowledge** exactly as before.

The new player-facing split is deliberately separate:

- seen text fade = short presentation wall-clock effect;
- unseen marker = temporary UI latch until next listener action-start;
- neither changes physical emissions, observation expiry, AI knowledge or WHEN.

`HeardSoundObservationStore` retains deterministic snapshot schema v1 for active listener knowledge. System 26 does not persist transient exact emissions and does not own save orchestration.

---

## 11. Future environment / actor seams

`AcousticEnvironmentModifier` is neutral in Candidate 001 and provides narrow hooks for future:

- propagation attenuation/masking;
- detection-threshold changes;
- localization-quality changes.

Weather, machinery and background noise can later provide an adapter without changing core acoustics.

`HearingProfileProvider` likewise permits infected, animals and other actors to use different hearing capability without rewriting propagation.

Future AI must consume `HeardSoundObservation`, never exact hidden `SoundEmission` coordinates and never the player renderer's seen/unseen cue latch.

---

## 12. Performance

System 26 physical propagation remains event-driven; there is no `_process()` / `_physics_process()` sound scan and no per-cell Node graph.

On first fully green original executable head `2d3dcfa6...`, CI measured a 100-run common walk-footstep wavefront average of:

`SPATIAL_SOUND_FOOTSTEP_AVG_US=13268.29`

That passes the Candidate 001 `<16,000 µs` single-field target, but the margin remains a scale seam. Before many simultaneous noisy actors/infected exist, profiling may justify tighter power-derived bounds, shared/cached fields, listener-target pruning, or a coarse distant propagation layer.

The onomatopoeia / cue-lifetime refinement does not change propagation complexity. Its only recurring presentation work is the short-lived timer while a currently seen word is fading; latched unseen markers perform no per-frame simulation work.

---

## 13. Verification

Dedicated workflow: `.github/workflows/spatial-sound.yml`.

Primary smoke: `game/scripts/ci/SpatialSoundSmoke.gd`.

It proves:

- source/profile validation and Run > Walk loudness;
- onomatopoeia recognition vocabulary while uncertain hearing remains `NOISE`;
- derived survivor hearing differences;
- cardinal/diagonal acoustic travel;
- open/closed door, window and wall attenuation ordering;
- cheaper routing around high-loss barriers;
- no invented unmaterialized-space propagation;
- stat-dependent heard/not-heard resolution;
- hard front/rear/left/right localization invariants;
- no exact source truth in listener observations or presentation descriptors;
- stable opaque cue/group identity;
- stored deterministic localization/no presentation reroll;
- repeated cue grouping;
- world-tick observation pause/expiry semantics;
- listener action-start presentation lifecycle;
- unseen-marker unpause clearing and suppression;
- one-second seen-cue fade function;
- deterministic observation snapshot roundtrip;
- common-footstep performance budget;
- WHEN, Movement, Run, Door, System 23 and canonical startup regressions.

System 23's perception smoke additionally proves a **configured** visible perceived-cell cue becomes transient while an UNSEEN perceived-cell cue becomes latched, and that the unseen marker reveals no terrain.

On executable head `aa5e1b622c8efe555d22e5d56514b9490776be16`, all twelve required exact-head contexts were green, including `verify/system26-spatial-sound`, `verify/system23-perception` and Pages.
