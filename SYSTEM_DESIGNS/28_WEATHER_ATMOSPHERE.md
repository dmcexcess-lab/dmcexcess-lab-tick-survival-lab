# Tick Survival Lab — System 28 Weather / Atmosphere

Status: **DRAFT — detailed design refined; implementation awaiting separate approval**

User direction, 2026-08-24:

> **“WEATHER! lets make it low res like the rest of the graphics (except the lighting) lighting strikes that use that coll lighting would be nice. ... low rez pixel weather but its always animated unlike the rest of the world.”**

Design-pass refinement:

> **“focus on low overhead, it will be always animated, even on calm days a leaf or piece of trash can blow by every now and then.”**

Core rule:

> **Weather is simulation truth; weather animation is presentation. Physical weather advances only through WHEN. The atmosphere may remain visually alive while the turn-based world is paused, and that animation must stay bounded, low-resolution and cheap.**

System 28 is the proposed owner for deterministic weather state and its neutral downstream environmental descriptors. It does not become a second lighting, perception or sound system.

---

## 1. Candidate 001 goals

The first playable Weather contract should provide:

- clear weather;
- overcast;
- rain;
- storm;
- fog/mist;
- deterministic transitions over authoritative world time;
- compact wind/cloud/precipitation/fog/wetness truth;
- deliberately low-resolution nearest-neighbor weather presentation;
- presentation motion that may continue while the survivor is decision-paused;
- **ambient calm-day motion** so clear weather is visually alive without becoming visually busy;
- roof/shelter-aware precipitation so rain does not simply draw through buildings;
- wetness that accumulates/decays with simulation time rather than particle count;
- a clean System 27 optics seam for later physical lighting/visibility consequences;
- a clean System 26 acoustic-environment seam for later rain/wind masking;
- deterministic lightning events later in the same owner, with physical System 27 flash lighting and low-res bolt presentation.

Candidate 001 explicitly values **mood per unit of CPU/GPU work**.

Snow, temperature exposure, flooding, fire ignition, weather damage, complex cloud fluid dynamics and persistent individual leaves/trash are not required.

---

## 2. Ownership

System 28 owns:

- current authoritative weather state;
- deterministic transition scheduling/profile;
- precipitation/cloud/fog/wind truth;
- regional/scenario wetness truth;
- weather revision/event identity;
- snapshot/restore of current weather state;
- neutral atmospheric-optics snapshots for System 27;
- neutral acoustic-environment modifier snapshots for System 26;
- low-resolution weather-presentation descriptors;
- cosmetic presentation phase/event state;
- a tiny bounded ambient-motion presentation pool for leaves/paper/dust-like events;
- lightning-event timing/identity in later Slice C.

System 28 reads:

- WHEN `world_tick` / scheduled events;
- System 25 world-time interpretation when time-of-day context is useful;
- a neutral shelter/sky-exposure provider for precipitation masking and later exposure mechanics;
- an optional presentation-only ambient-motion palette/profile selected by composition, never by inspecting art pixels.

System 28 does **not** own:

- physical illumination or vision range (System 27 / System 23);
- sound propagation/hearing (System 26);
- roof/construction truth;
- actor AI;
- health/damage;
- fire;
- electrical power;
- water accumulation/flooding;
- crop simulation;
- ordinary render frame time;
- persistent loose-item/trash entities merely because a cosmetic scrap crossed the screen.

Canonical direction:

`WHEN + world-time/climate profile -> System 28 physical weather truth -> neutral optics/acoustics/exposure descriptors -> Systems 27/26/23 and future survival systems`

Presentation branches from the same weather truth but never becomes gameplay authority.

---

## 3. Two clocks, one truth

Weather deliberately has two different notions of time.

### 3.1 Simulation time

Authoritative physical weather uses WHEN only.

It controls:

- profile transitions;
- precipitation truth;
- physical wind truth;
- fog/cloud truth;
- wetness;
- lightning-event creation;
- downstream optics/acoustic revisions.

If WHEN does not advance, none of these facts advance.

### 3.2 Presentation time

Weather presentation may use render/wall delta to animate:

- rain streak travel;
- fog drift;
- cosmetic splash pixels;
- leaf/paper/dust motion;
- short lightning visual envelopes after an already-created physical event.

Presentation time never schedules a new physical event or changes simulation state.

This distinction is mandatory and testable.

---

## 4. Authoritative `WeatherState`

Candidate state is compact rather than meteorological fluid dynamics.

Proposed physical fields:

- `weather_kind`;
- precipitation intensity `[0,1]`;
- cloud cover `[0,1]`;
- fog density `[0,1]`;
- wind direction as a small normalized/simple world vector;
- wind strength `[0,1]`;
- wetness anchor value `[0,1]`;
- wetness anchor tick;
- state/transition start tick;
- transition end tick;
- current/target profile IDs where a transition is active;
- stable weather revision;
- deterministic weather-event serial/seed.

Candidate readable kinds:

- `CLEAR`;
- `OVERCAST`;
- `RAIN`;
- `STORM`;
- `FOG`.

The kind is a readable profile. Continuous fields are the downstream truth.

---

## 5. Low-overhead physical transition model

System 28 must not execute a weather simulation loop every world tick.

### 5.1 Event-driven transitions

A transition is selected from stable facts such as:

- scenario/weather seed;
- current profile;
- current day/time band;
- transition serial.

System 28 schedules only meaningful transition/checkpoint events through WHEN.

No per-tick random weather rerolls.

### 5.2 Analytic transition sampling

Continuous fields may interpolate between current and target profiles as a function of `world_tick`.

A query can therefore derive current precipitation/cloud/fog/wind from:

- transition start values;
- target values;
- start/end ticks.

No mutation is needed simply because one more tick passed.

### 5.3 Quantized downstream revisions

Smooth physical truth must not force System 27/23/26 to recompute every tiny numeric change.

Candidate rule:

- continuous weather fields may be sampled smoothly;
- expensive downstream consumers receive a new environment revision only when a meaningful **quantized band** changes;
- Candidate 001 should target roughly 8–16 useful bands for optics/wetness, tuned by profiling;
- the final transition state always publishes exactly.

This lets a storm build gradually without asking Lighting to rebuild hundreds of times during a long action or time skip.

### 5.4 No streaming-grid weather identity

Candidate 001 may use one scenario-wide weather state while the playable world is still locally focused.

Future weather regions/fronts may replace that provider.

Technical System 00F streaming regions must never become weather regions merely because they are convenient rectangles.

---

## 6. Wetness without a wetness tick loop

Wetness is slow physical state, not a counter incremented by every rain particle or every WHEN tick.

Preferred Candidate 001 model:

- store an anchor wetness and anchor tick;
- derive wetness analytically from elapsed WHEN time and the current/transition precipitation/drying rates;
- re-anchor when the weather transition/profile materially changes;
- clamp `[0,1]`;
- publish downstream wetness only when its quantized band changes.

Consequences:

- rain/storm increases wetness only when world time advances;
- clear/dry weather lowers it only when world time advances;
- decision/hard pause changes no wetness;
- no recurring one-event-per-minute wetness job is required merely to maintain a scalar.

System 27 later consumes wetness through `AtmosphericOptics.wet_surface_factor` for the existing restrained reflection treatment.

Candidate 001 deliberately has **no per-cell puddle hydrology**.

---

## 7. Weather A presentation architecture

The presentation goal is **one cheap owner, not a particle ecosystem**.

Proposed owner:

`WeatherPresentationRenderer`

It may internally own one coarse render target/shader surface plus a tiny fixed-size cosmetic-debris array, but it should not create a Node/Sprite for each raindrop, fog puff or leaf.

### 7.1 Coarse virtual weather surface

Preferred path:

- one low-resolution internal weather surface;
- nearest-neighbor upscale;
- weather pixels intentionally much larger than System 27 light-gradient pixels;
- target virtual-pixel scale roughly 4 physical screen pixels per weather pixel at normal presentation scale, adjusted for mobile/viewport bounds;
- cap the internal weather surface to a modest size rather than tracking full display resolution.

Exact dimensions are implementation tuning, not identity. The contract is that weather remains visibly pixelated and bounded.

### 7.2 Fixed presentation cadence

Candidate default continuous-weather animation cadence:

**20 Hz** (`50 ms` presentation steps).

The normal game may render faster. Weather does not need 60/120 Hz to look good; the lower cadence is part of its pixel-art character.

Implementation intent:

- `_process(delta)` may accumulate presentation time;
- actual weather phase/render-target updates occur only when the 20 Hz presentation step is crossed;
- per-render-frame overhead between weather steps is essentially one cheap accumulator/branch;
- no simulation tick advances.

### 7.3 Adaptive sleeping

“Always animated” means **the atmosphere stays alive**, not “burn GPU continuously while nothing is moving.”

When `CLEAR`/calm and no ambient-motion event is currently on screen:

- the coarse weather surface may sleep/not redraw;
- the renderer keeps only a tiny countdown/scheduler for the next cosmetic event;
- when a leaf/paper/dust event starts, animation wakes at the low presentation cadence;
- once it exits, clear-weather redraw can sleep again.

Rain/storm/fog naturally keep the weather surface active while their continuous effects exist.

This preserves the user's calm-day motion request at near-zero idle fill cost.

---

## 8. Rain presentation

Rain should look like part of the same low-res game rather than a high-resolution particle overlay.

Candidate visual language:

- 1-pixel-wide, 1–3-weather-pixel streaks;
- nearest-scaled hard pixels, no anti-aliasing;
- slant follows current wind vector;
- several density bands rather than thousands of persistent particles;
- occasional 1–2 pixel exposed-ground splash marks;
- storm rain changes density/speed/slant, not merely alpha.

### 8.1 Procedural field instead of particle objects

Preferred implementation is a coarse deterministic/hash/procedural streak field generated by one shader/draw owner from:

- weather presentation phase;
- stable weather presentation seed;
- precipitation band;
- wind vector;
- camera/window origin.

There is no per-drop Node, collision body, timer or persistent world identity.

### 8.2 Camera behavior

Rain is a near-camera atmospheric presentation and may recycle/reseed across camera movement.

Its exact drops are not simulation entities and do not need persistent world coordinates.

The pattern should nevertheless incorporate camera/world offset enough to avoid an obviously screen-glued static texture.

---

## 9. Fog / mist presentation

Fog graphics visualize System 28 state; later System 27 optics remain the physical owner of extinction/scatter.

Candidate look:

- chunky low-resolution drifting dither/noise fields;
- one or two inexpensive broad layers, not dozens of transparent sprites;
- slow wind-driven drift;
- coarse world-offset anchoring so camera panning does not make the whole fog pattern appear glued to the screen;
- 20 Hz or slower visual phase is acceptable and desirable.

Overcast itself should mostly appear through System 27 light/contrast changes in Slice B. Weather A may use extremely subtle coarse moving cloud/dither presentation, but should not spend meaningful continuous GPU cost merely to prove “clouds exist.”

---

## 10. Calm-day ambient motion

Clear weather should not look dead merely because no precipitation/fog effect is active.

Candidate 001 adds a **tiny bounded cosmetic ambient-motion scheduler**.

Examples:

- one leaf skitters/blows through;
- a paper scrap tumbles across the road;
- a small dust wisp crosses open ground;
- later environment palettes may add dry grass/tumbleweed, blossom/pollen, snow fluff, etc.

### 10.1 Presentation-only identity

These are atmosphere, not physical inventory.

A cosmetic paper scrap:

- has no WHAT entity;
- cannot be picked up;
- does not collide;
- creates no System 26 sound;
- does not become AI evidence;
- may be discarded/reseeded on camera/window changes.

If later gameplay wants persistent collectible trash, that is an actual world entity owned elsewhere and must not be conflated with this cheap visual layer.

### 10.2 Hard budget

Candidate presentation budget:

- calm/clear: normally **0 active debris**, occasionally **1**;
- breezy: max **2**;
- strong wind/storm: max **3** if debris is shown at all, because rain already supplies motion;
- one owner draws all active pieces;
- no child Node per piece.

Exact counts are tuning targets but the fixed tiny cap is a contract.

### 10.3 Event frequency

Frequency is cosmetic and may depend on wind strength.

Target feel, not exact law:

- very calm clear day: roughly one event every 15–40 presentation seconds;
- light breeze: roughly every 8–20 seconds;
- stronger wind: more frequent but still sparse enough not to distract from gameplay.

The scheduler uses presentation time only. Waiting on a decision pause may therefore let a leaf pass by, but it does not advance physical wind/weather.

### 10.4 Ambient-motion palette seam

Weather does not import System 20 generation.

A neutral presentation palette can later be injected by composition/environment presentation:

- `generic_temperate`: leaf, paper, dust;
- rural dry: dry leaf/grass/dust;
- urban: paper/light litter;
- woodland: mostly leaves;
- etc.

Candidate A can ship a small generic-temperate palette without creating a new simulation system.

---

## 11. Shelter / sky-exposure masking

Rain must not draw through roofs.

Weather presentation consumes a neutral read-only sky-exposure/shelter mask rather than rediscovering building geometry or inspecting sprites.

Candidate A may expose System 27's existing temporary enclosure/sky approximation through a narrow query because that approximation already exists.

Rules:

- exposed outdoor cells receive normal rain/splash presentation;
- enclosed/roofed cells suppress direct precipitation;
- opening a door/window does not make the whole room outdoors;
- future explicit Roof/Shelter truth can replace the approximation without rewriting Weather.

### 11.1 No perception leak

Primary Candidate A weather presentation is composited **below System 23's final perception/knowledge mask**.

Therefore hidden-current shelter geometry cannot be revealed by an absence of rain over an otherwise black unexplored roof.

Candidate A should avoid a second shelter-aware foreground weather pass above System 23. If one is added later, it must use perception-safe information and prove that hidden roof/building shapes cannot be inferred from precipitation masking.

This is both cheaper and safer.

---

## 12. Weather presentation layering

Preferred Candidate A order:

1. live world;
2. System 27 physical lighting;
3. low-res Weather world presentation (rain/fog/debris);
4. System 23 knowledge/fog mask;
5. UI.

Consequences:

- weather does not reveal hidden WHAT truth;
- lighting remains smooth while weather pixels remain chunky;
- rain/fog/debris can remain visually animated inside the observer's known/currently visible presentation while actors remain frozen;
- UI remains crisp and unaffected.

A later safe screen-foreground weather pass is explicitly optional, not required for Candidate 001.

---

## 13. Always-animated pause rule

While the survivor is waiting at a decision pause:

- active rain continues falling;
- fog continues drifting;
- an already-active leaf/paper/dust event continues crossing the view;
- calm weather may start a new **cosmetic** ambient-motion event from presentation time;
- an already-created lightning presentation may finish its short flicker envelope;
- actors/world simulation remain still.

The presentation may start a cosmetic leaf while paused because that leaf has no gameplay meaning.

It must **not**:

- change physical precipitation/wind/cloud/fog values;
- schedule or begin a physical weather transition;
- accumulate physical wetness;
- move actors;
- advance System 25 time;
- age System 26 simulation observations;
- create a physical lightning event;
- alter System 27 physical illumination merely because a rain pixel moved.

Browser/app backgrounding may naturally stop render frames; returning does not “catch up” cosmetic raindrops or debris through simulation time.

---

## 14. Presentation state and reproducibility

Cosmetic weather does not need save persistence, but tests need deterministic stepping.

Preferred contract:

- renderer/presentation owner accepts a stable presentation seed;
- animation phase is explicit and step-able for CI;
- fixed `advance_presentation(delta)` logic can be tested without WHEN changes;
- production `_process(delta)` delegates to the same presentation step;
- camera changes may invalidate/reseed transient screen-local debris without touching physical WeatherState.

Save/load restores physical WeatherState. It does not need to restore the exact leaf halfway across the screen.

---

## 15. System 27 physical-optics adapter — Slice B

System 28 should map current physical state into the already-existing `AtmosphericOptics` contract rather than make Lighting switch on weather kinds.

Examples:

- clear: high diffuse/direct/local transmission, little scatter, dry;
- overcast: direct sunlight strongly suppressed, diffuse retained;
- rain: lower contrast/direct light, modest local extinction/scatter, rising wetness;
- fog: strong visibility/local-light extinction and strong scatter;
- storm: low direct/diffuse daylight, meaningful extinction/scatter, high wetness.

Weather does not edit the vision cone directly.

`visibility_extinction` should become an input to the System 27/System 23 acquisition path in Slice B so fog/rain can reduce useful sight even when a target is adequately illuminated.

### 15.1 Revision budget

Lighting/perception should refresh on **physical weather descriptor revision**, not on every presentation frame.

Rain pixels falling 20 times per second cause zero System 27 rebuilds.

---

## 16. System 26 acoustic adapter — Slice B

Rain and wind are background acoustic conditions, not thousands of fake `RAIN` sound events.

System 28 later supplies an `AcousticEnvironmentModifier` adapter that may:

- raise detection thresholds during heavy rain/storm;
- modestly reduce localization quality in rain/wind;
- later support direction-sensitive wind behavior if actual gameplay/profiling justifies it.

No rain particle creates a System 26 emission.

Discrete thunder is different: it is a real event and can enter System 26 from the LightningEvent seam in Slice C.

---

## 17. Lightning — Slice C

Lightning must use System 27's physical lighting rather than a renderer-only white screen flash.

### 17.1 Authoritative `LightningEvent`

Stable facts should include:

- event ID/serial;
- event tick;
- storm/weather revision;
- apparent/world strike anchor or distant direction;
- flash intensity/profile;
- event seed;
- optional thunder delay metadata.

Only System 28/WHEN creates the physical event.

### 17.2 Physical illumination

A narrow System 28 -> System 27 adapter injects a transient physical lightning contribution.

Target effect:

- bright cool-white/blue outdoor flash;
- actual window/open-door portal spill;
- interiors react according to real enclosure geometry;
- wet roads/neon/lighted surfaces flare through the existing lighting renderer;
- System 23 acquisition recomputes because physical light changed;
- something hidden by darkness may genuinely become visible for the strike and then fall back to REMEMBERED afterward;
- future NPC observers receive the same opportunity.

The physical flash may use a transient global/direct contribution rather than a huge point light. System 27 owns that light shape.

### 17.3 Low-res bolt

A nearby/apparent strike may draw one chunky seeded bolt:

- low resolution;
- jagged path;
- at most a few branches;
- stable shape for the event seed;
- short presentation flicker/decay;
- tied to the same event that caused physical illumination.

Candidate 001 does not invent actor damage, fire or structure destruction.

### 17.4 Thunder

Thunder may later use one System 26 sound emission derived from the same event, with distance-based delay where meaningful.

It must not bypass normal hearing/localization to reveal exact strike coordinates.

---

## 18. Performance contract

Weather presentation must be **cheaper than the physical systems it influences**.

Candidate requirements:

- no one-Node-per-raindrop design;
- no thousands of Sprite2D particles;
- no per-cell persistent weather entities;
- one coarse renderer/shader owner for rain/fog;
- one tiny fixed-cap array for ambient debris;
- low-resolution internal presentation;
- continuous weather visual updates target ~20 Hz rather than display FPS;
- calm clear presentation may sleep between ambient events;
- physical transitions are scheduled/analytic, not per-tick simulation loops;
- wetness is analytically derived/re-anchored rather than particle/tick counted;
- optics/acoustics revisions are quantized and event-driven;
- lighting/perception refreshes occur only on physical environment revision or physical lightning phases;
- camera-visible presentation work is bounded by viewport, never world size;
- detailed weather presentation is never instantiated for distant inactive world regions.

### 18.1 Candidate budget measurements

`verify/system28-weather` should report structural counts rather than rely only on noisy wall-clock timings:

- low-res weather surface dimensions/pixel count;
- continuous full-screen weather draw calls/layers;
- active ambient-debris count;
- presentation updates per second;
- physical weather events/revisions during a long simulated interval;
- number of System 27/23 refresh requests caused by physical weather, proving cosmetic frames cause zero refreshes.

Timing benchmarks are useful but secondary to bounded-work proofs.

---

## 19. DEV Weather Lab / selector

Candidate A needs immediate testing without waiting for climate/world-front simulation.

DEV controls should allow:

- force `CLEAR`, `OVERCAST`, `RAIN`, `STORM`, `FOG`;
- adjust precipitation/fog/wind bands;
- freeze/advance physical weather independently through explicit DEV calls;
- show current authoritative WeatherState summary;
- show presentation update cadence/count;
- show current low-res weather surface resolution;
- show active ambient-debris count;
- toggle/inspect shelter mask;
- force an ambient leaf/paper/dust event;
- later force LightningEvent in Slice C.

DEV controls are explicit tooling, not fake production climate logic.

---

## 20. Candidate implementation slices

### Slice A — weather truth + low-overhead always-alive presentation

- `WeatherProfile` / `WeatherState` / `WeatherService`;
- deterministic WHEN transition scheduling;
- analytic/quantized transition sampling;
- analytic wetness;
- clear/overcast/rain/storm/fog profiles;
- `WeatherPresentationRenderer`;
- coarse nearest-neighbor rain/fog surface;
- ~20 Hz active-weather presentation cadence;
- adaptive clear-weather sleep;
- tiny capped leaf/paper/dust ambient-motion scheduler;
- shelter-aware rain masking;
- perception-safe below-System23 composition;
- DEV weather selector/lab;
- snapshot contract;
- structural performance counters.

### Slice B — physical environment integration

- System 27 `AtmosphericOptics` adapter;
- visibility-extinction acquisition consequence;
- quantized optics revision integration;
- System 26 rain/wind masking adapter;
- zero lighting/perception refresh from cosmetic animation;
- wet-surface lighting/reflection response from physical wetness.

### Slice C — lightning

- scheduled `LightningEvent`;
- transient physical System 27 flash contribution;
- low-res stable-seed bolt/flicker presentation;
- System 23 recompute during physical flash;
- optional System 26 thunder adapter if cleanly supported;
- damage/fire explicitly deferred.

All slices belong to one System 28 contract.

---

## 21. Candidate verification

A future `verify/system28-weather` should prove at least:

### Physical truth

- same seed/state produces the same weather transition sequence;
- physical weather does not advance during decision/hard pause;
- transition queries are deterministic at arbitrary world ticks;
- analytic wetness increases under precipitation and dries under clear conditions only with WHEN time;
- snapshot/restore preserves weather truth and future deterministic transitions;
- technical stream-region coordinates do not appear in weather identity.

### Presentation

- cosmetic phase advances while simulation tick stays fixed;
- active rain/fog presentation targets the bounded low cadence rather than display FPS;
- calm clear renderer can sleep between events;
- a forced leaf/paper/dust event animates while WHEN remains unchanged;
- ambient-debris count never exceeds the fixed cap;
- no per-raindrop/per-fog-puff Nodes are created;
- weather surface remains coarse/nearest-scaled;
- rain is suppressed in roofed/exposure-masked cells;
- opening a door does not remove the room's roof classification;
- weather presentation below System 23 reveals no hidden WHAT truth;
- camera movement may reset cosmetic debris without changing physical weather.

### Future adapters

- physical weather descriptors map into System 27 without Weather owning illumination;
- cosmetic presentation updates request zero System 27/23 recomputes;
- overcast suppresses direct light after Slice B;
- fog increases extinction/scatter after Slice B;
- heavy rain/storm changes System 26 masking only through the neutral modifier seam after Slice B;
- LightningEvent identity/timing deterministic after Slice C;
- physical lightning changes System 27 illumination and may temporarily change System 23 acquisition after Slice C;
- bolt remains presentation-only and tied to the same event;
- no actor damage/fire is invented.

### Runtime

- canonical startup/Web path;
- mobile/Safari-safe lifecycle;
- bounded structural work counters;
- presentation timing benchmark reported but not used as the only regression proof.

---

## 22. Refined proposed approval decisions

1. Weather is System 28, not a renderer-only effect.
2. Physical weather advances only through WHEN.
3. Weather presentation may continue during decision pause using presentation time only.
4. Candidate profiles are clear, overcast, rain, storm and fog with continuous underlying fields.
5. Candidate physical state is event-driven/analytic; there is no per-tick weather loop.
6. Wetness is derived from authoritative time/state rather than particle count and should avoid a recurring fine-grained wetness loop.
7. Expensive downstream consumers receive quantized physical weather revisions rather than every small interpolated field change.
8. Initial weather may be scenario-wide but weather regions never equal technical streaming regions.
9. Weather A presentation uses one coarse nearest-scaled low-res owner, not per-particle Nodes.
10. Continuous rain/fog presentation targets ~20 Hz even if the game renders faster.
11. Calm clear weather may sleep between events while a tiny presentation scheduler occasionally launches a leaf/paper/dust event.
12. Cosmetic ambient debris is capped to a few pieces, is not WHAT/inventory/collision/sound truth, and may be discarded on camera changes.
13. Rain is sky-exposure/shelter masked.
14. Candidate A weather presentation stays below System 23 to prevent shelter/weather animation from leaking hidden world geometry.
15. Weather feeds System 27 later through `AtmosphericOptics`; Lighting never switches on weather kind.
16. Fog/rain visibility extinction becomes a physical observer-acquisition input in Slice B, not only screen haze.
17. Rain/wind feed System 26 as background masking/modifiers in Slice B, not fake repeated rain sounds.
18. Cosmetic rain/fog/debris animation causes zero System 27/23 physical recomputes.
19. Lightning is a real deterministic Weather event in Slice C.
20. Lightning illumination is a transient System 27 physical-light contribution capable of changing actual observer acquisition.
21. The visible lightning bolt/flicker is low-res presentation tied to the same physical event.
22. Lightning damage/fire is deferred until those owning systems explicitly consume lightning events.
23. Performance verification prefers structural bounded-work counters plus timing measurements, following the successful System 27 optimization approach.

No runtime implementation is authorized by this DRAFT status.