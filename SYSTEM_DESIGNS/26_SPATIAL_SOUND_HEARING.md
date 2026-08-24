# Tick Survival Lab — System 26 Spatial Sound / Hearing

Status: **DRAFT — awaiting approval**

User direction, 2026-08-23:

> **“yellow words that are effected by player stats. but even the random location has to make sense, even the worst perception isn't going to see a noise behind him as in front of him.”**

System 26 is the canonical physical sound-propagation and listener-hearing domain for Tick Survival Lab.

Core player-language rule:

> **Sound is physical. Hearing is an estimate. Poor perception makes the estimate broader and less specific; it does not put an impossible sound on the wrong side of the survivor.**

Candidate 001 is intentionally text-first. There is no requirement for conventional game audio. Heard sounds are presented as yellow words in world space / at the viewport edge.

---

## 1. Goal

Add a deterministic spatial-sound model that:

1. creates sound only from real physical events;
2. propagates through current world geometry instead of using simple radius checks;
3. lets walls, doors, windows and distance attenuate sound without making them all absolute blockers;
4. produces listener-specific detection, recognition and localization based on actor stats/status;
5. presents heard sounds as yellow textual cues without revealing hidden terrain;
6. gives future infected/NPC AI the same honest hearing observations rather than exact-source cheating;
7. consumes zero extra world time itself — sound is a consequence of actions that already happened on WHEN.

Immediate gameplay value:

- the player can hear danger outside LOS / behind true-black fog;
- running and other loud actions become meaningful risks before infected AI exists;
- the existing System 23 auditory presentation seam becomes real rather than synthetic;
- future zombies can be attracted by sounds that physically occurred at real locations.

---

## 2. Ownership

System 26 owns:

- immutable physical sound-emission records/descriptors;
- acoustic propagation through currently materialized WHAT / Door State geometry;
- acoustic material/transmission profiles;
- listener hearing-profile derivation through injected stat/status providers;
- heard/not-heard decisions;
- listener-specific recognition quality;
- deterministic listener-specific localization uncertainty;
- recent heard-sound observations and their world-tick lifetime;
- repeated-sound cue grouping/refresh rules;
- observer-facing auditory descriptors supplied to System 23 presentation;
- reusable hearing observations for future AI.

System 26 reads but does not own:

- WHAT terrain/entity/placement truth;
- Door State OPEN/CLOSED truth;
- WHEN `world_tick` for event time and cue aging;
- System 13C base skill levels;
- System 13B fatigue and sleep-pressure truth;
- source-system public action/result signals used by narrow sound-emitter adapters.

System 26 does **not** own:

- movement, doors, loot/search, combat, vehicles, weather or other sound-causing gameplay actions;
- visual LOS / visual memory;
- actor skills/needs/health state;
- AI decision-making;
- world generation/materialization;
- ordinary audio playback / music;
- physical visible-world lighting;
- real-time/frame-time advancement;
- save-file orchestration.

---

## 3. Two truths: emission vs heard observation

System 26 must never confuse exact physical sound truth with what one listener thinks they heard.

### 3.1 `SoundEmission`

An emission is exact simulation truth. Candidate 001 needs at least:

- stable event ID;
- emission world tick;
- exact global origin cell;
- sound profile/category ID;
- integer source acoustic budget/power;
- optional source entity ID for internal grouping/ownership only;
- optional source surface/material tag when the emitter knows it;
- optional repeated-source group key.

The exact source origin is **not** automatically exposed to player UI or future AI.

### 3.2 `HeardSoundObservation`

A heard observation is listener-specific knowledge produced after physical propagation + hearing resolution.

Candidate 001 observation needs at least:

- stable observation/cue ID;
- listener actor ID;
- heard world tick;
- perceived/estimated global cell;
- perceived strength;
- recognition tier / display word;
- localization uncertainty score/range;
- source sound category at only the recognized specificity level;
- expiry tick;
- repeated-cue group identity that does not expose hidden source identity to consumers.

The player renderer and future AI consume the **heard observation**, not the exact emission.

This is the auditory equivalent of System 23's visual-memory rule: internal simulation may know exact current truth, but observer-facing knowledge contains only information the observer physically acquired.

---

## 4. Sound creation: real events only

System 26 never invents threat noise because the game has been quiet.

Sound enters the system through narrow emitter adapters observing already-authoritative physical events.

Examples of legitimate future emitters:

- successful walk step;
- each successful Run stride;
- door opening/closing at the physical transition;
- searching/rummaging while a real search action is underway;
- dropping/placing an item when the physical transfer commits;
- melee impact;
- breaking glass;
- firearm discharge;
- zombie groan/scream;
- vehicle engine/horn/collision;
- generator/machinery;
- alarm;
- weather events.

Rules:

1. failed/rejected actions that create no physical event emit no corresponding sound;
2. an action adapter emits at the physical phase that makes the noise, not at an arbitrary UI click;
3. System 26 core does not import every source system or switch on all gameplay action IDs;
4. source-specific adapters may subscribe to stable public signals and call the narrow System 26 emission API;
5. if an existing action has no truthful public physical phase/event, System 26 does not fake one merely to claim integration complete.

Current Movement already exposes committed movement/stride signals suitable for step emission. Door close already exposes `close_committed`. Search/item-transfer sound integration may use similarly narrow public seams if/when implementation proves one is needed.

---

## 5. Candidate 001 acoustic propagation

### 5.1 Weighted wavefront, not radius-only and not LOS-only

Sound propagation uses a bounded deterministic weighted wavefront (Dijkstra-style field), not:

- Euclidean radius alone;
- visual LOS raycasting;
- collision blocking;
- camera visibility.

A sound can:

- travel around a wall through an open doorway;
- pass through a wall at heavy attenuation;
- pass through a closed door at moderate/heavy attenuation;
- pass through a window at intermediate attenuation;
- take the least-loss physically available route.

This produces believable indoor/outdoor behavior without requiring fluid/acoustic simulation.

### 5.2 Grid neighborhood

Candidate 001 propagation may use eight neighboring cells for a less diamond-shaped wavefront even though actor movement remains four-way.

Distance uses deterministic integer fixed-point cost:

- cardinal open-air step: **10** cost;
- diagonal open-air step: **14** cost.

Diagonal traversal must not create an impossible zero-width leak through two strongly sealing corner cells. The exact sealed-corner rule belongs to the acoustic query and is independent from visual LOS/collision policy.

### 5.3 Acoustic structure costs — initial tuning targets

The structure profile adds cost when the wave crosses/occupies that structure cell.

Candidate starting targets:

- open air / ordinary empty cell: +0 beyond distance cost;
- OPEN door: +0 to +5;
- window: +30 to +45;
- CLOSED door: +55 to +75;
- ordinary wall: +110 to +140;
- malformed/unknown structure: conservative wall-like attenuation, not magical free transmission.

These are gameplay tuning values, not identity.

Walls are **high attenuation, not absolute silence**. A sufficiently loud gunshot may be heard through a wall; a footstep usually will not. The weighted field still prefers an open-door route around the wall when that route loses less energy.

Future materials may distinguish thin interior walls, concrete, metal shutters, broken windows, vegetation, vehicle shells, etc. without changing the propagation contract.

### 5.4 Unknown / unmaterialized space

Candidate 001 detailed propagation does not invent geometry through unknown/unmaterialized cells.

A local acoustic field stops at unmaterialized/unknown detailed space. Future coarse/off-screen simulation may bridge logical regions through a separate adapter without turning technical stream boundaries into world geography.

### 5.5 Performance cap

Propagation is event-driven — no `_process()` / `_physics_process()` sound scan.

Each emission has a finite acoustic budget and a configurable hard propagation radius. Candidate 001 hard ceiling target: **128 cells** for extraordinary sounds, with ordinary actions far below that.

No per-cell Nodes are created.

---

## 6. Initial sound-power vocabulary

Candidate 001 uses integer acoustic budgets, deliberately **not pretending to be calibrated decibels**.

Initial tuning examples:

| Physical event | Acoustic budget target | Approx. open-air reach before hearing threshold |
|---|---:|---:|
| crouched/very quiet step | 60 | very local |
| ordinary walk step | 120 | local |
| Run stride | 200 | larger local |
| door close / solid thump | 180 | local/building |
| rummaging/searching | 140 | local/building |
| dropped heavy object | 240–320 | building / nearby exterior |
| glass break / major crash | 400–550 | neighborhood-local |
| firearm discharge | 850–1000 | very large local field |
| horn / alarm | 900–1100 | very large / repeated |

Exact implementation numbers are tuning targets and may move after playtest.

Surface/source context may alter emission budget. Example: the same step on soft ground may be quieter than on hard interior flooring. This belongs to emitter/source profiles, not propagation geometry.

---

## 7. Listener hearing profile

System 13C already stores broad skills rather than a dedicated Perception stat. Candidate 001 therefore derives an **effective auditory perception profile** instead of inventing another persistent character field.

### 7.1 Base effective hearing score

Candidate 001 derived score, normalized 0..100:

- base: **50**;
- `survival` skill level 0..10: up to **+40**;
- fatigue 0..100: up to **−15**;
- sleep pressure 0..100: up to **−20**;
- clamp 0..100.

This is an adapter/read model only. System 26 does not mutate Skills or Needs.

Why Survival:

- the current six-skill catalog has no dedicated Perception/Hearing skill;
- Survival is the closest broad field for environmental awareness;
- a later character-trait/background/equipment system can add hearing modifiers through the same provider contract without rewriting System 26.

### 7.2 What stats affect

Effective hearing affects three different things:

1. **Detection** — whether a weak/attenuated event is heard at all.
2. **Localization** — how tightly the listener places the source.
3. **Recognition** — how specific the yellow word can be.

These are related but not identical.

### 7.3 Domain recognition bonuses

Recognition may additionally use a relevant existing skill without changing detection physics.

Examples:

- `combat` may improve recognition of weapon/combat sounds;
- `technical` may improve machinery/electrical/mechanical recognition;
- `survival` may improve footsteps, animals, environmental movement and outdoor causes;
- other domain mappings are added only when their source content exists.

An obvious event remains obvious: a huge nearby crash should not become `???` merely because the listener lacks Technical skill.

---

## 8. Detection

For each registered listener inside the propagated field:

1. read remaining acoustic energy at the listener cell;
2. derive the listener's hearing profile;
3. compare remaining energy to listener threshold;
4. if below threshold, create no observation;
5. if heard, derive perceived strength, recognition and localization.

Candidate threshold tuning target:

- poor effective hearing requires materially more remaining energy;
- strong effective hearing can detect weaker signals;
- extremely loud/nearby sounds overwhelm ordinary stat differences.

A listener's own deliberate action is special: the actor knows they just made that sound. Self-generated cue feedback may bypass external-source detection/localization uncertainty while still using the same physical emission for other listeners.

---

## 9. Localization: deterministic uncertainty with hard physical constraints

This is a locked design priority from the user request.

### 9.1 No rerolling marker

Localization jitter is deterministic from stable facts such as:

- sound event ID;
- listener actor ID;
- emission tick / cue group.

The yellow word does **not** jump to a new random cell every redraw/frame.

A genuinely new repeated emission may update the estimate.

### 9.2 Direction is more reliable than distance

Poor hearing increases **range uncertainty more strongly than bearing uncertainty**.

Candidate angular-error target:

- worst ordinary effective hearing: roughly **±60° maximum before hard directional constraints**;
- strong hearing/strong signal: may tighten toward roughly **±5–10°**.

Candidate range error may vary from roughly **±60–70%** for weak/poorly heard distant sounds down toward **±10% / about one cell** for strong/skilled localization.

Near/very loud sounds automatically collapse uncertainty; a crash two cells away cannot be perceived as thirty cells away.

### 9.3 Hard actor-relative direction invariants

Randomness is never allowed to contradict basic directional hearing.

Let the listener's current facing define actor-relative `forward` and `lateral` components for the true source delta.

Candidate 001 requires:

- true source clearly in front -> perceived cell remains in the front half-plane;
- true source clearly behind -> perceived cell remains in the rear half-plane;
- true source clearly left -> perceived cell remains on the left side;
- true source clearly right -> perceived cell remains on the right side;
- diagonal sources therefore remain in the same broad actor-relative quadrant;
- source exactly/near an axis may legitimately drift to either adjacent side, but never across the opposite front/rear half-plane;
- estimated cell must have positive distance unless the source is actually at the listener cell.

This is stronger than merely clamping a random radius.

**Example:** survivor faces north, true sound is six cells southwest. A terrible localization may place `THUMP` too near/far or somewhere broadly south/southwest/west depending the configured boundary, but it can never appear north/northeast in front of the survivor.

### 9.4 Strength and path complexity

Localization quality also responds to the physical signal:

- stronger remaining signal -> tighter estimate;
- heavy barrier/muffling cost -> wider estimate;
- acoustically complicated paths may be less certain than clean open-air paths.

The source's exact hidden location remains internal even when the solver uses it to create a plausible estimate.

---

## 10. Recognition and yellow-word vocabulary

Each sound profile can expose recognition tiers rather than one omniscient label.

Example:

- unknown tier: `NOISE`;
- broad tier: `MOVEMENT`;
- specific tier: `FOOTSTEPS`.

Other examples:

- `NOISE` -> `IMPACT` -> `THUD`;
- `NOISE` -> `BREAKING` -> `GLASS`;
- `NOISE` -> `VOICE` -> `GROAN`;
- future firearm content: `BANG` -> `GUNSHOT` -> more specific recognition only if gameplay supports it.

Recognition depends on:

- source profile recognition difficulty;
- received strength;
- effective auditory perception;
- relevant domain skill where applicable.

The system should prefer **honest broad labels** over confidently wrong labels. Low skill yields less information, not fabricated misclassification for its own sake.

---

## 11. Presentation: yellow words, not crosshairs

Candidate 001 replaces the current synthetic auditory crosshair presentation with textual cues.

### 11.1 In-world cue

For an on-screen perceived cell:

- render the recognized word in canonical yellow;
- center it near/on the perceived cell without revealing the underlying hidden terrain;
- perceived strength controls text emphasis/size/opacity within readable mobile bounds;
- localization certainty may modestly affect opacity/spacing but the system does not need a giant uncertainty circle;
- no visual grid line is required.

The word describes what the **listener believes**, not exact source truth.

### 11.2 Fog interaction

Yellow words may appear over:

- VISIBLE;
- REMEMBERED;
- completely black UNSEEN.

They never:

- reveal terrain;
- mark a cell visually explored;
- refresh System 23 environmental memory;
- expose a hidden actor/entity sprite.

### 11.3 Off-screen sounds

Because textual sound is the game's primary auditory communication, a heard event outside the current viewport must not silently disappear.

Candidate 001:

- clamp an off-screen yellow word to the nearest viewport edge along the **perceived bearing**, not the exact source bearing;
- use a simple ASCII directional affordance if needed for phone-font reliability (for example `< FOOTSTEPS` or `FOOTSTEPS >`);
- do not expose exact off-screen distance;
- panning the camera does not recompute the listener estimate — it reveals the same stored heard observation in world space until it expires/refreshes.

### 11.4 Self-generated sounds

The player may receive exact-position self-noise feedback so stealth consequences are legible even without conventional audio.

Example: a Run stride may briefly show `FOOTSTEPS`/`THUD` at the survivor's own position with strength emphasis. Other listeners still receive independent uncertain observations through normal hearing resolution.

---

## 12. Cue lifetime and repeated sounds

A sound often occurs during an action while the player cannot inspect the screen freely. Therefore a cue must survive into the next decision pause.

Cue age is based on **world ticks, never wall-clock time**.

Candidate 001 target:

- ordinary heard cue persists around **25–40 ticks** (roughly 5–8 simulation seconds under System 25's current profile);
- alpha/emphasis may decay from age when redrawn;
- hard pause/decision pause freezes cue aging automatically because WHEN stops;
- once future action ticks pass expiry, the cue disappears.

Repeated events from the same hidden source/category should not fill the map with one word per step.

Candidate grouping:

- a repeated group (for example one actor's footsteps) refreshes one listener cue;
- new emissions can move the perceived estimate and update strength/recognition;
- grouping uses internal source/event identity but presentation/AI does not receive exact hidden source ID;
- truly distinct simultaneous events remain distinct observations.

---

## 13. Future AI contract — no hearing cheats

Future infected/NPC AI should consume listener-specific heard observations from the same System 26 pipeline.

The AI may receive:

- perceived location;
- perceived strength;
- recognized broad category;
- heard tick / age.

It should **not** automatically receive:

- exact hidden source cell;
- exact source entity ID;
- a direct target lock merely because an emission occurred.

This makes sound-driven investigation physical and fallible:

1. zombie hears a noise estimate;
2. zombie chooses to investigate that perceived location;
3. repeated noises may refine/update its estimate;
4. actual sight can then take over through the visual-perception system.

Different actor species/traits may use different hearing-profile providers while sharing the same acoustic propagation field.

---

## 14. Interaction with visual perception

System 23 and System 26 remain peers.

System 23 answers:

> What has this observer visually seen / remembered?

System 26 answers:

> What sound reached this listener, and what does the listener think it means/where it came from?

System 26 does not mark visual exploration. System 23 does not generate or propagate sound.

Future sensory fusion may let an AI/player reason that a visible source caused a sound, but neither domain should silently absorb the other's state.

---

## 15. Persistence / restore

Physical emissions are transient events and do not become permanent world entities.

Recent heard observations are short-lived observer knowledge. System 26 should own deterministic snapshot/restore of active observations so a future save during a decision pause does not arbitrarily erase a just-heard danger cue.

System 26 does not own the save file.

Snapshot data must never restore exact source truth into a listener observation if the listener only had an uncertain estimate.

---

## 16. Weather / ambient masking seam

Candidate 001 does not require Weather first.

The hearing-profile / propagation pipeline must leave a narrow future seam for masking/attenuation such as:

- heavy rain raising detection threshold;
- wind affecting outdoor propagation/localization;
- storms masking footsteps;
- indoor machinery creating local background noise.

Weather/machinery remain their own owners. System 26 consumes an injected environmental acoustic modifier rather than importing those systems directly.

---

## 17. Candidate 001 implementation shape

Likely cohesive domain under:

`game/scripts/simulation/sound/`

Potential owners (final file count should follow cohesion, not this list mechanically):

- `SoundEmissionProfileCatalog` — source acoustic/recognition definitions;
- `AcousticMaterialCatalog` — wall/door/window transmission costs;
- `AcousticPropagationQuery` — bounded weighted wavefront;
- `HearingProfileProvider` + survivor adapter — derived listener acuity/localization/recognition;
- `SpatialSoundService` — emission -> field -> listener observations;
- `HeardSoundObservationStore` — active listener cue state/snapshot;
- narrow Movement/Door/etc. emitter adapters;
- System 23 presentation adapter producing textual auditory descriptors.

Do not create one-method wrappers solely to match this proposed shape.

---

## 18. Candidate 001 integration scope

First playable integration should prove enough real sources to evaluate the system without prematurely touching combat.

Recommended initial emitters:

1. ordinary Walk step;
2. each Run stride;
3. door close;
4. one real search/rummage emission if System 24 can expose a truthful phase with a narrow seam;
5. a DEV-only remote sound emitter may exist solely in the CI/test fixture, not as fake gameplay.

Likely walking/running presentation words:

- self: `FOOTSTEPS` with exact self position;
- external high recognition: `FOOTSTEPS`;
- broad recognition: `MOVEMENT`;
- weakest recognized: `NOISE`.

Surface-aware label/power refinements can follow without changing the System 26 contract.

---

## 19. Failure behavior

System 26 fails by withholding or weakening information, never by granting impossible knowledge.

- malformed emission -> reject emission;
- invalid/unplaced origin -> reject emission;
- unknown/unmaterialized propagation cell -> do not invent detailed continuation;
- malformed structure/acoustic profile -> conservative high attenuation;
- missing listener placement -> no observation;
- missing required stat/status provider -> use documented neutral/fail-closed hearing profile rather than exact-source knowledge;
- localization candidate violates front/rear/side constraint -> reject/reselect deterministically;
- no valid uncertain candidate -> fall back to a physically valid broad-direction estimate, never the opposite side;
- invalid presentation descriptor -> omit cue without revealing terrain.

---

## 20. Performance / mobile

Candidate 001 requirements:

- event-driven only;
- no per-frame propagation;
- one propagation field per physical emission, not one flood per listener;
- bounded integer/fixed-point costs;
- listener registry/spatial filtering rather than global-world actor scans;
- no per-cell Nodes;
- repeated-source cue grouping limits UI spam;
- mobile-readable yellow text;
- off-screen edge cues so camera size does not become a hearing nerf.

A loud rare gunshot may legitimately cost more propagation work than a quiet step. Common footsteps must remain cheap/bounded.

---

## 21. Verification contract

A dedicated System 26 smoke/contract should prove at least:

1. same emission + world geometry -> deterministic propagation field;
2. open space loses only distance cost;
3. closed door attenuates more than open door;
4. wall attenuates more than closed door;
5. sound can route around a wall/through an open doorway when that is lower loss;
6. window transmission is distinct from wall/door behavior;
7. malformed/unknown structure does not create free sound transmission;
8. unmaterialized space does not get invented detailed propagation;
9. weak event can be unheard by poor listener but heard by stronger listener;
10. survival skill improves effective hearing as designed;
11. fatigue and sleep pressure worsen effective hearing as designed;
12. strong/near event overwhelms ordinary stat differences;
13. low-skill localization has larger range/bearing error than high-skill localization;
14. **rear source can never be localized into the front half-plane**;
15. **front source can never be localized into the rear half-plane**;
16. left/right broad-side constraints hold;
17. deterministic event/listener seed produces stable perceived cell across redraws;
18. repeated sound refreshes one cue instead of creating unbounded spam;
19. cue survives decision/hard pause because world tick does not advance;
20. cue expires only after world ticks advance beyond expiry;
21. recognition tiers expose less-specific truthful words at low confidence;
22. auditory cue over UNSEEN reveals no terrain / creates no visual memory;
23. off-screen heard cue uses perceived bearing rather than exact hidden source bearing;
24. future-AI observation contract does not expose exact hidden source ID/cell;
25. System 23 visual regression remains green;
26. WHEN regression remains green;
27. Movement/Run regressions remain green;
28. Door regression remains green;
29. canonical demo startup remains healthy;
30. bounded propagation benchmark is acceptable on the CI/mobile-target scale.

Proposed exact-head owner when implemented:

`verify/system26-spatial-sound`

---

## 22. Candidate 001 non-goals

Not part of this first implementation:

- conventional positional audio playback;
- voice chat;
- sophisticated frequency-band acoustics;
- reverberation impulse simulation;
- Doppler effect;
- exact real-world decibel calibration;
- weather/wind implementation;
- infected AI itself;
- firearm system itself;
- vehicle system itself;
- continuous ambient-noise ecology;
- global off-screen/coarse-region sound propagation;
- hearing injuries/deafness/tinnitus;
- ear protection/headsets/radios;
- player skill XP awards for merely hearing noises.

The architecture must permit these later where useful.

---

## 23. Proposed approval decisions

1. System 26 owns physical sound propagation + listener hearing observations; source gameplay systems own the actions that make sounds.
2. Exact `SoundEmission` truth and uncertain `HeardSoundObservation` knowledge remain separate.
3. Physical propagation is a deterministic weighted wavefront through current WHAT / Door State geometry, not simple radius and not visual LOS.
4. Walls/closed doors/windows attenuate at different costs; walls are strongly muffling but not universally absolute blockers.
5. Candidate 001 uses integer/fixed-point acoustic budgets rather than pretending they are calibrated decibels.
6. System 13C/13B feed a derived hearing profile; System 26 creates no new persistent Perception stat in Candidate 001.
7. Survival skill improves generic hearing; fatigue and sleep pressure degrade it. Domain skills may improve recognition of relevant sound families.
8. Player-facing auditory cues are yellow words.
9. Poor perception primarily increases distance uncertainty and label vagueness; bearing uncertainty is bounded more tightly.
10. Localization is deterministic per event/listener and never rerolls every frame.
11. Hard actor-relative directional constraints guarantee a true rear sound never appears in front and a true front sound never appears behind; broad left/right constraints also apply.
12. Strong/near sounds naturally localize better regardless of skill.
13. Auditory cues can appear over true-black UNSEEN space but reveal no terrain and create no visual exploration.
14. Off-screen heard sounds receive edge-clamped textual cues based on the perceived bearing.
15. Cue lifetime is measured in world ticks and therefore freezes during auto-pause/hard pause.
16. Repeated sounds from one source/category refresh/group rather than creating one permanent marker per step.
17. Future infected/NPC AI receives the same listener-specific uncertain hearing observations rather than exact source cheating.
18. System 26 is event-driven and performs one bounded propagation field per emission, not per-frame/per-listener floods.
19. Candidate 001 initially integrates real movement/Run/door sounds and only adds search/item sounds where a truthful physical source seam exists.
20. Weather, visible-world lighting, combat, firearms, vehicles and coarse off-screen sound remain later peer systems/consumers.
