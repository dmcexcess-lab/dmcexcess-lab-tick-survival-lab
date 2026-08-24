# Tick Survival Lab — System 28 Weather / Atmosphere

Status: **IMPLEMENTED — Slice A; Slices B/C deferred**

User direction, 2026-08-24:

> **“WEATHER! lets make it low res like the rest of the graphics (except the lighting) ... low rez pixel weather but its always animated unlike the rest of the world.”**

Refinement:

> **“focus on low overhead, it will be always animated, even on calm days a leaf or piece of trash can blow by every now and then.”**

Core rule:

> **Weather is simulation truth; weather animation is presentation. Physical weather advances only through WHEN. The atmosphere may remain visually alive while the turn-based world is paused, and that animation must stay bounded, low-resolution and cheap.**

The detailed pre-implementation design remains recoverable in Git history at `9bed8f81b3f34363a9458519d46a73d54917a8d1`. This document is the canonical current contract after Slice A implementation.

---

## 1. Ownership

System 28 owns:

- deterministic current weather state;
- Candidate 001 weather profiles and transition selection;
- transition scheduling through WHEN;
- continuous precipitation/cloud/fog/wind truth derived from authoritative world ticks;
- analytic regional/scenario wetness;
- weather environment revisions;
- Weather snapshot/restore;
- low-resolution weather presentation descriptors;
- presentation-time rain/fog/debris motion;
- a tiny cosmetic ambient-motion pool;
- shelter/sky-exposure precipitation query for the current roof approximation;
- DEV-only weather forcing controls for critique/testing.

System 28 reads:

- WHEN world tick / external scheduled-event seam;
- WHAT terrain/structure placement for the current shelter approximation.

System 28 does **not** own:

- physical illumination or vision range;
- System 23 observer memory/knowledge;
- System 26 acoustic propagation/hearing;
- actor AI;
- health/damage/fire;
- explicit roof/construction truth;
- electricity/power;
- flooding/hydrology;
- crop simulation;
- persistent loose-item/trash entities merely because cosmetic debris crossed the screen.

Canonical direction:

`WHEN -> System 28 physical weather truth -> presentation now; neutral environment adapters later -> Systems 27/26/23`

---

## 2. Two clocks, one truth

### 2.1 Physical simulation time

Authoritative weather advances only through WHEN.

It controls:

- weather transition timing;
- current continuous weather values;
- physical wetness;
- environment revision;
- future lightning-event creation.

Decision pause and hard pause therefore freeze physical Weather automatically.

### 2.2 Presentation time

Weather presentation may use render delta for:

- rain streak travel;
- fog drift;
- cosmetic leaf/paper/dust movement;
- later, the short visual envelope of an already-created lightning event.

Presentation time advances **zero WHEN ticks** and cannot change physical weather, wetness, lighting, perception, hearing or AI state.

Browser/app backgrounding may simply stop rendering. Weather presentation does not try to catch up thousands of cosmetic drops afterward.

---

## 3. Candidate 001 profiles

Implemented profiles:

- `clear`;
- `overcast`;
- `rain`;
- `storm`;
- `fog`.

Each profile carries compact continuous values for:

- precipitation `[0,1]`;
- cloud cover `[0,1]`;
- fog density `[0,1]`;
- normalized wind direction;
- wind strength `[0,1]`;
- wetting rate;
- drying rate;
- deterministic duration range.

The profile name is readable state; continuous fields are the actual current Weather sample.

---

## 4. Deterministic transition model

`WeatherService` schedules one meaningful transition event through WHEN rather than running a weather simulation loop every tick.

Next profile and duration derive from stable facts:

- scenario/weather seed;
- current profile;
- transition serial.

Current continuous weather is analytically interpolated from transition start/end ticks. Queries do not mutate state merely because another tick passed.

Current Candidate transition neighborhood:

- clear -> clear / overcast / fog;
- overcast -> clear / rain / fog;
- rain -> overcast / rain / storm;
- storm -> rain / overcast;
- fog -> clear / overcast.

Candidate 001 is scenario-wide. Weather identity is deliberately unrelated to System 00F technical streaming regions.

---

## 5. Quantized environment revision

Smooth weather truth does not publish a heavyweight downstream revision for every tiny interpolated change.

Candidate 001 uses **12 quantization bands** for the compact environment signature. The signature includes meaningful bands of precipitation/cloud/fog/wind/wetness and broad wind direction.

A changed signature advances `environment_revision` and emits a Weather change notification.

This is the future seam for Slice B so Lighting/Perception/Hearing can update on meaningful physical weather changes rather than 20 presentation frames per second.

Cosmetic animation itself never advances `environment_revision`.

---

## 6. Analytic wetness

Wetness is physical Weather state but is not maintained by a fine-grained recurring event.

System 28 stores:

- wetness anchor value;
- wetness anchor tick.

`wetness_at(tick)` derives the current value from elapsed WHEN time and the current transition's wetting/drying rates, clamped `[0,1]`.

Consequences:

- rain/storm increase wetness only when WHEN advances;
- clear conditions dry only when WHEN advances;
- waiting at decision pause changes no wetness;
- cosmetic raindrop count has no relationship to physical wetness.

Per-cell puddle hydrology remains intentionally out of scope.

---

## 7. Snapshot / restore

System 28 snapshot schema v1 preserves:

- scenario seed;
- current and target profile IDs;
- transition start/end ticks;
- wetness anchor and anchor tick;
- environment revision;
- transition serial;
- scheduled Weather event serial;
- quantized signature.

Weather is restored together with the owning WHEN snapshot by future save orchestration. Cosmetic rain/fog/debris presentation state is deliberately not persistent.

---

## 8. Shelter / sky exposure

Slice A adds `SkyExposureQuery`, a cached read-only enclosure approximation for precipitation presentation.

Current rule:

- materialized non-structure space reachable from the active bounds perimeter is sky-exposed;
- structure cells form the enclosure boundary;
- enclosed interior cells are sheltered;
- a door/window remains part of the roof/enclosure boundary regardless of OPEN/CLOSED passage state.

Therefore opening the front door does not make the whole house rain-exposed.

The query is cached by bounds + WHAT revision. A future explicit Roof/Shelter owner may replace this approximation without changing Weather presentation behavior.

---

## 9. Low-resolution presentation

`WeatherPresentationRenderer` is one `Node2D` owner.

It deliberately creates:

- no Node per raindrop;
- no Node per fog patch;
- no Node per leaf/paper/dust piece;
- no Sprite2D/CPU/GPU particle swarm.

Presentation is drawn as coarse primitives using a virtual pixel scale.

### 9.1 Resolution bound

Weather pixel size begins at 4 physical pixels and grows when necessary so either virtual axis stays at or below 256.

The weather graphics therefore stay intentionally chunky while System 27 lighting remains smooth.

### 9.2 Cadence

Active weather targets **20 Hz / 50 ms presentation steps** even if the display renders faster.

Long-frame cosmetic catch-up is capped at four presentation steps. Cosmetic weather never tries to simulate an unbounded backlog.

Between presentation steps the cost is essentially the normal `_process` accumulator/branch.

---

## 10. Rain

Rain is a deterministic procedural coarse streak field derived from:

- Weather presentation seed;
- presentation step;
- precipitation intensity;
- wind vector;
- active render window.

Candidate bounds:

- maximum 180 candidate streaks;
- 1–3 coarse weather-pixel segments per streak;
- wind controls slant;
- storm uses greater density/weight;
- shelter query rejects roofed/interior precipitation.

The exact drops have no persistent world identity and may recycle with camera/window changes.

---

## 11. Fog

Fog presentation is deliberately chunky and cheap:

- maximum 36 broad coarse patches;
- low alpha;
- slow wind-driven drift;
- no individual fog-object lifecycle.

This is presentation only. Actual optical extinction/scatter belongs to Slice B through System 27.

---

## 12. Calm-day ambient motion

Clear weather may remain visually alive with rare cosmetic motion:

- leaf;
- paper scrap;
- dust wisp.

These have no WHAT identity, collision, inventory, System 26 sound or AI meaning.

Hard active caps:

- calm wind: max 1;
- breezy: max 2;
- strong wind: max 3;
- global hard maximum: **3**.

Typical calm delay is based around roughly 15–40 presentation seconds and is shortened by wind.

When clear weather has no active debris, the renderer stops requesting redraws until an ambient event begins. It retains only the cheap presentation-time countdown/branch.

The DEV Weather controls include a `BLOW LEAF` action for immediate inspection.

---

## 13. Perception-safe layering

Canonical presentation order is now:

1. world/actors;
2. System 27 physical lighting;
3. **System 28 low-res Weather presentation** at z=50;
4. System 23 perception/knowledge mask at z=100;
5. UI.

Weather therefore cannot reveal hidden roofs/building shapes merely because rain stops over an unexplored structure. UNSEEN remains black and REMEMBERED remains observer memory.

Slice A does not add a weather foreground pass above perception.

---

## 14. DEV critique integration

The Rural Crossroads critique composition starts in **RAIN** intentionally so Weather A is immediately visible after deployment.

A clearly labeled DEV Weather panel can force:

- CLEAR;
- OVERCAST;
- RAIN;
- STORM;
- FOG;
- one calm leaf event.

The DEV control calls `WeatherService.force_profile()` through composition. It is test tooling, not the production climate-selection mechanism.

---

## 15. Performance contract

System 28 remains bounded by viewport/presentation demand, not world size.

Implemented structural limits include:

- one Weather renderer;
- 20 Hz active presentation cadence;
- max virtual axis 256;
- max 180 rain candidates;
- max 36 fog patches;
- max 3 ambient debris records;
- zero per-particle child Nodes;
- one scheduled meaningful physical Weather transition at a time;
- analytic wetness instead of fine recurring updates;
- no lighting/perception/sound recompute from cosmetic animation in Slice A.

Focused CI fixture output on first fully green executable head:

- `WEATHER_VIRTUAL_PIXELS=1296`;
- `WEATHER_ACTIVE_DEBRIS=1`;
- `WEATHER_PRESENTATION_UPDATES=4` for a deliberately supplied 0.5 s long-frame step, proving bounded catch-up.

System 27's existing bounded lighting regression remained unchanged on the Weather runner: 7,680 field cells, 1,676 emitter candidates, 688 optical-ray candidates.

---

## 16. Slice B — deferred

Not implemented by Slice A.

Planned responsibilities:

- System 28 -> System 27 `AtmosphericOptics` adapter;
- overcast/rain/storm effects on daylight and local light;
- physical fog/rain visibility extinction;
- wet-surface reflection response from real Weather wetness;
- System 28 -> System 26 background acoustic masking;
- quantized physical Weather revision drives those consumers;
- cosmetic animation still causes zero physical recomputes.

System 28 will supply neutral descriptors/adapters. System 27 remains lighting owner; System 26 remains hearing owner; System 23 remains observer-knowledge owner.

---

## 17. Slice C — deferred lightning

Not implemented by Slice A.

Planned contract:

- deterministic `LightningEvent` scheduled through WHEN;
- transient physical System 27 lightning contribution;
- actual portal/shadow/illumination response;
- System 23 may genuinely acquire something during the physical flash;
- low-res stable-seeded pixel bolt tied to the same event;
- optional normal System 26 thunder emission/delay;
- no actor damage/fire until their real owners explicitly consume Lightning events.

---

## 18. Verification

Exact-head owner:

`verify/system28-weather`

Slice A smoke proves:

- same seed creates same next profile/duration;
- exactly one meaningful transition event is scheduled;
- physical rain wetness changes only after WHEN advances;
- Weather + WHEN snapshot/restore preserves future transition truth;
- presentation can advance while world tick and physical wetness remain fixed;
- 20 Hz presentation contract;
- bounded long-frame catch-up;
- virtual presentation surface remains bounded;
- room center is sheltered while outside is exposed;
- door semantic in the envelope does not make the interior unroofed;
- zero per-particle child Nodes;
- calm leaf event respects the one-piece calm cap;
- System 27 and System 23 regressions;
- canonical demo startup.

First fully green executable Slice A head:

`dcb400b8507c23a2fc5bdaecf551bc5c0512acce`

All **13 required exact-head contexts** were green on that executable head, including `verify/system28-weather` and `verify/pages-deploy`.

---

## 19. Approved decisions

1. Weather is System 28, not a renderer-only effect.
2. Physical Weather advances only through WHEN.
3. Cosmetic Weather presentation may continue during decision pause using presentation time only.
4. Candidate profiles are clear, overcast, rain, storm and fog with continuous fields beneath them.
5. Physical state is event-driven/analytic; there is no per-tick Weather simulation loop.
6. Wetness is analytic and independent of cosmetic particle count.
7. Environment revision is quantized rather than publishing every tiny interpolated field change.
8. Weather identity is not System 00F stream-region identity.
9. Slice A presentation is one coarse low-res owner with no per-particle Nodes.
10. Active rain/fog presentation targets 20 Hz.
11. Calm clear weather may sleep between rare presentation-only leaf/paper/dust events.
12. Cosmetic ambient debris is capped at three, has no gameplay identity and may reset across camera/window changes.
13. Rain is shelter/sky-exposure masked.
14. Slice A Weather remains below System 23 to prevent hidden geometry leaks.
15. Slice B physical lighting/visibility/hearing integration remains deferred and must use neutral existing owner seams.
16. Slice C lightning remains a real future Weather event feeding System 27 physical lighting, not a fake screen flash.
17. Lightning damage/fire remains deferred until real owners exist.
18. Performance verification prefers structural bounded-work proofs over fragile microbenchmarks.
