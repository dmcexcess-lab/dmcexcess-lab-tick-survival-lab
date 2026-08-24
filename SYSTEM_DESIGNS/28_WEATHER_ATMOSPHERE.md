# Tick Survival Lab — System 28 Weather / Atmosphere

Status: **IMPLEMENTED — Slices A+B; Slice C deferred**

User direction, 2026-08-24:

> **“WEATHER! lets make it low res like the rest of the graphics (except the lighting) ... low rez pixel weather but its always animated unlike the rest of the world.”**

Refinement:

> **“focus on low overhead, it will be always animated, even on calm days a leaf or piece of trash can blow by every now and then.”**

Slice-B playtest approval also identified two presentation defects that are now part of the implemented contract: Weather must not visibly trail the moving camera/render window, and unrendered space must not appear grey against System 23 true-black fog.

Core rule:

> **Weather is simulation truth; weather animation is presentation. Physical weather advances only through WHEN. The atmosphere may remain visually alive while the turn-based world is paused, and that animation must stay bounded, low-resolution and cheap.**

The detailed pre-implementation design remains recoverable in Git history at `9bed8f81b3f34363a9458519d46a73d54917a8d1`.

---

## 1. Ownership

System 28 owns:

- deterministic current weather state;
- Candidate 001 weather profiles and transition selection;
- transition scheduling through WHEN;
- continuous precipitation/cloud/fog/wind truth derived from authoritative world ticks;
- analytic scenario wetness;
- quantized weather environment revisions;
- Weather snapshot/restore;
- low-resolution weather presentation descriptors;
- presentation-time rain/fog/debris motion;
- a tiny cosmetic ambient-motion pool;
- shelter/sky-exposure precipitation query for the current roof approximation;
- neutral Weather -> System 27 atmospheric-optics mapping;
- neutral Weather -> System 26 acoustic-environment masking;
- DEV-only weather forcing controls for critique/testing.

System 28 reads:

- WHEN world tick / external scheduled-event seam;
- WHAT terrain/structure placement for the current shelter approximation.

System 28 does **not** own:

- physical illumination or shadow solving — System 27;
- observer LOS/memory/knowledge — System 23;
- sound propagation/heard-observation ownership — System 26;
- actor AI;
- health/damage/fire;
- explicit roof/construction truth;
- electricity/power;
- flooding/hydrology;
- persistent loose-item/trash entities merely because cosmetic debris crossed the screen.

Canonical physical direction:

`WHEN -> System 28 weather truth -> neutral optics/acoustic descriptors -> Systems 27/26 -> System 23 observer acquisition/knowledge`

Presentation branches from the same Weather truth but never becomes gameplay authority.

---

## 2. Two clocks, one truth

### 2.1 Physical simulation time

Authoritative Weather advances only through WHEN.

It controls transition timing, continuous physical weather values, wetness, environment revision, downstream environment descriptors and future lightning-event creation.

Decision pause and hard pause therefore freeze physical Weather automatically.

### 2.2 Presentation time

Weather presentation may use render delta for rain streak travel, fog drift, cosmetic leaf/paper/dust movement and later the short visual envelope of an already-created lightning event.

Presentation time advances **zero WHEN ticks** and cannot change physical weather, wetness, lighting truth, perception truth, hearing truth or AI state.

Browser/app backgrounding may simply stop rendering. Weather presentation does not catch up an unbounded cosmetic backlog afterward.

---

## 3. Candidate 001 profiles

Implemented readable profiles:

- `clear`;
- `overcast`;
- `rain`;
- `storm`;
- `fog`.

Each profile carries compact continuous values for precipitation, cloud cover, fog density, normalized wind direction, wind strength, wetting rate, drying rate and deterministic duration range.

The profile name is readable state. Continuous fields are the downstream physical truth.

---

## 4. Deterministic transition model

`WeatherService` schedules one meaningful transition event through WHEN rather than running a weather simulation loop every tick.

Next profile and duration derive from stable scenario seed, current profile and transition serial. Current continuous weather is analytically interpolated from transition start/end ticks; queries do not mutate state merely because another tick passed.

Candidate transition neighborhood:

- clear -> clear / overcast / fog;
- overcast -> clear / rain / fog;
- rain -> overcast / rain / storm;
- storm -> rain / overcast;
- fog -> clear / overcast.

Candidate 001 is scenario-wide. Weather identity is deliberately unrelated to System 00F technical streaming regions.

---

## 5. Quantized environment revision

Smooth Weather truth does not publish expensive downstream refreshes for every tiny interpolation change.

Candidate 001 uses **12 quantization bands** in a compact signature covering meaningful precipitation/cloud/fog/wind/wetness bands plus broad wind direction. A changed signature advances `environment_revision` and emits `weather_changed`.

Slice B composition consumes that signal to refresh System 27 physical illumination and System 23 acquisition. Cosmetic 20 Hz animation emits no physical Weather revision and therefore requests no lighting/perception recompute.

System 26's Weather acoustic adapter samples the same current physical Weather state when a real sound is evaluated; rain pixels themselves never become sound events.

---

## 6. Analytic wetness

Wetness is physical Weather state but is not maintained by a fine recurring event or particle count.

System 28 stores a wetness anchor value + anchor tick and analytically derives `wetness_at(tick)` from elapsed WHEN time and current transition wetting/drying rates.

Consequences:

- rain/storm increase wetness only when WHEN advances;
- dry weather reduces it only when WHEN advances;
- waiting at decision pause changes no wetness;
- cosmetic rain density has no authority over wetness.

Slice B passes the real current wetness value into System 27 `AtmosphericOptics.wet_surface_factor`, so the already-existing restrained wet-surface reflection treatment now responds to authoritative Weather.

Per-cell puddle hydrology remains out of scope.

---

## 7. Snapshot / restore

System 28 snapshot schema v1 preserves scenario seed, current/target profiles, transition start/end ticks, wetness anchor/tick, environment revision, transition serial, scheduled Weather event serial and quantized signature.

Weather is restored with the owning WHEN snapshot by future save orchestration. Exact cosmetic raindrops/fog patches/debris are intentionally not persistent.

---

## 8. Shelter / sky exposure

`SkyExposureQuery` is a cached read-only enclosure approximation for precipitation presentation.

Current rules:

- materialized non-structure space reachable from active-bounds perimeter is sky exposed;
- structure cells form enclosure boundaries;
- enclosed interior cells are sheltered;
- a door/window remains part of the roof/enclosure boundary regardless of OPEN/CLOSED passage state.

Opening a front door therefore does not make the whole house rain exposed.

The query is cached by bounds + WHAT revision. A future explicit Roof/Shelter owner may replace this approximation without rewriting Weather presentation.

---

## 9. Low-resolution presentation

`WeatherPresentationRenderer` is one `Node2D` owner. It creates no Node per raindrop, fog patch or debris piece and uses no Sprite/CPU/GPU particle swarm.

Weather presentation uses coarse primitives and a virtual-pixel scale while System 27 lighting remains smooth.

Implemented bounds:

- target **20 Hz / 50 ms** active presentation cadence;
- maximum four cosmetic catch-up steps after a long frame;
- virtual axis <= 256;
- maximum 180 rain candidates;
- maximum 36 fog patches;
- maximum three cosmetic debris records.

Clear weather stops requesting continuous redraws when no debris event is active.

---

## 10. Rain / fog / calm motion

Rain is a deterministic coarse streak field from presentation seed, phase, precipitation, wind and active render window. Streaks are shelter masked against the real world cell represented by each coarse sample.

Fog uses at most 36 broad low-alpha coarse patches with slow wind-driven drift.

Clear weather may occasionally show one leaf, paper scrap or dust wisp. These have no WHAT identity, inventory, collision, System 26 sound or AI meaning. Active debris caps are calm 1, breezy 2, strong wind 3.

The DEV panel retains `BLOW LEAF` for immediate inspection.

---

## 11. Camera-motion correction

Slice A exposed a presentation artifact: because Weather was drawn inside the large world render window, smooth camera movement could move the world-relative weather field between its 20 Hz phase updates and make precipitation appear to trail or lag.

Slice B keeps the 20 Hz animation budget but adds a separate camera-presentation anchor:

- camera presentation changes request an immediate Weather redraw;
- camera movement updates a coarse camera offset used by rain/fog/debris drawing;
- that redraw advances **zero Weather presentation steps** and **zero WHEN ticks**;
- shelter masking still maps each final coarse rain sample to the corresponding world cell;
- render-window shifts use `visible_origin * cell_pixels + camera_local_position` so technical window recentering does not become an atmospheric jump.

This is presentation compensation only; no new physical Weather clock or per-frame simulation loop was introduced.

---

## 12. Perception-safe layering and black fallback

Canonical order remains:

1. world/actors;
2. System 27 physical lighting;
3. System 28 low-res Weather at z=50;
4. System 23 perception/knowledge mask at z=100;
5. UI.

Weather therefore cannot reveal hidden roofs/building shapes merely because rain stops over an unexplored structure.

A second A playtest exposed the engine's default grey clear color outside/in-between the large render window. `project.godot` now sets the viewport default clear color to true black. Unrendered technical space therefore no longer announces an approaching render-window/chunk boundary against System 23 black fog.

This fix does **not** create fake terrain or make System 23 reason about rendering partitions.

---

## 13. Slice B physical optics

`WeatherAtmosphericOpticsAdapter` maps continuous Weather fields into System 27's existing `AtmosphericOptics` contract. System 27 does not switch on Weather profile names.

Current mapping behavior:

- Candidate clear baseline is normalized to essentially neutral optics;
- cloud/overcast pressure suppresses direct sky more strongly than diffuse sky;
- rain adds moderate daylight suppression, local-light attenuation, scatter and visibility extinction;
- storm suppresses direct sky strongly and carries high wet-surface response as physical wetness accumulates;
- fog produces the strongest scatter/extinction treatment;
- atmosphere tint shifts modestly cooler as cloud/rain/fog pressure increases;
- Weather `environment_revision` is reused as the optics revision.

System 27 remains the only owner of physical illumination/shadows/portal transfer. Weather supplies environment inputs only.

---

## 14. Slice B visibility extinction

System 23 still resolves opaque geometry first and remains the sole owner of `VISIBLE`, REMEMBERED and UNSEEN.

System 27's acquisition policy now combines:

- target-cell physical luminance;
- `AtmosphericOptics.visibility_extinction`;
- the existing 12-cell geometric maximum;
- protected radius-1 near awareness.

The atmosphere never extends vision beyond the geometric LOS envelope; it can only reduce useful acquisition distance.

Candidate CI examples at full target luminance:

- clear extinction -> full **12-cell** useful range;
- representative fog extinction ~0.60 -> **5-cell** useful range.

Thus a bright distant object can still disappear into physical fog without changing System 23's LOS geometry or reading rendered haze pixels.

---

## 15. Slice B acoustic masking

`WeatherAcousticEnvironmentModifier` plugs into System 26's existing neutral environment seam.

Candidate B intentionally models rain/wind as **competing background noise**, not as thousands of fake rain emissions or invented per-cell acoustic absorption:

- propagation-cost addition remains 0;
- precipitation + wind raise the listener detection threshold;
- precipitation + wind modestly reduce localization quality;
- ordinary rain particles create no `SoundEmission`;
- System 26 still owns propagation, hearing decisions and uncertain localization.

Representative storm CI fixture adds **+19** to the detection threshold and worsens localization quality relative to clear conditions.

Future directional wind propagation can be added only if gameplay/profiling justifies it.

---

## 16. DEV critique integration

The Rural Crossroads critique composition still begins in RAIN intentionally for immediate inspection.

DEV controls can force CLEAR, OVERCAST, RAIN, STORM, FOG and one calm leaf event. These are explicit testing tools, not production climate/front logic.

Because Slice B is live, forcing profiles now changes physical lighting/visibility and hearing environment as well as the visible weather presentation.

---

## 17. Performance contract

System 28 remains bounded by viewport/presentation demand, not world size.

Implemented structural limits include one Weather renderer, 20 Hz active cadence, max virtual axis 256, max 180 rain candidates, max 36 fog patches, max three debris records, zero per-particle child Nodes, one meaningful scheduled physical Weather transition, analytic wetness and quantized downstream physical revisions.

Camera-motion correction adds event-driven redraws on actual camera presentation changes but does not add a second animation/simulation step.

First Slice-A fixture:

- `WEATHER_VIRTUAL_PIXELS=1296`;
- `WEATHER_ACTIVE_DEBRIS=1`;
- `WEATHER_PRESENTATION_UPDATES=4` for an intentionally supplied 0.5 s long frame.

Slice-B fixture:

- `WEATHER_B_CLEAR_RANGE=12`;
- `WEATHER_B_FOG_RANGE=5`;
- `WEATHER_B_STORM_HEARING_MASK=19`;
- `WEATHER_B_CAMERA_REDRAWS=1`.

On the first fully green B runner, System 27's 80x96 / four-light structural regression remained 7,680 field cells, 1,676 local-emitter candidates and 688 optical-ray candidates. Representative light rebuild was ~2.55 ms and focused illumination-aware perception ~9.55 ms; timings remain runner-noisy and structural bounds are the durable proof.

---

## 18. Slice C — deferred lightning

Not implemented by Slices A/B.

Planned contract:

- deterministic `LightningEvent` scheduled through WHEN;
- transient physical System 27 lightning contribution;
- real portal/shadow/illumination response;
- System 23 may genuinely acquire something during the physical flash;
- low-res stable-seeded pixel bolt tied to the same event;
- optional ordinary System 26 thunder emission/delay;
- no actor damage/fire until those real owners explicitly consume Lightning events.

---

## 19. Verification

Exact-head owner:

`verify/system28-weather`

Slice A coverage remains in `WeatherSmoke.gd`.

Slice B coverage in `WeatherEnvironmentIntegrationSmoke.gd` proves:

- clear/rain/fog/storm continuous Weather -> physical optics mapping;
- real analytic Weather wetness enters System 27 wet-surface factor;
- optics revision follows quantized Weather environment revision;
- visibility extinction reduces useful acquisition range while radius-1 near awareness remains protected;
- rain/wind raise hearing threshold and reduce localization through the neutral System 26 environment seam;
- acoustic propagation geometry is not replaced with fake rain absorption;
- camera motion requests an immediate compensated Weather redraw without advancing presentation phase or WHEN;
- unrendered viewport clear color is true black;
- System 27 physical-light and illumination-aware perception regressions;
- System 26 spatial-sound regression;
- System 23 perception regression;
- canonical demo startup.

First fully green executable Slice B head:

`db4681dc53ce6955e9585f4f5b380fe8efef634c`

All **13 required exact-head contexts** were green on that executable head, including `verify/system28-weather`, System 23/26/27 and `verify/pages-deploy`.

---

## 20. Approved decisions

1. Weather is System 28, not a renderer-only effect.
2. Physical Weather advances only through WHEN.
3. Cosmetic Weather may continue during decision pause using presentation time only.
4. Candidate profiles are clear, overcast, rain, storm and fog with continuous fields beneath them.
5. Physical Weather is event-driven/analytic; there is no per-tick Weather simulation loop.
6. Wetness is analytic and independent of cosmetic particle count.
7. Environment revision is quantized rather than publishing every tiny interpolated change.
8. Weather identity is not System 00F stream-region identity.
9. Presentation is one coarse low-res owner with no per-particle Nodes.
10. Active rain/fog presentation targets 20 Hz; camera compensation may redraw immediately without advancing that phase.
11. Calm clear weather may sleep between rare presentation-only debris events.
12. Cosmetic debris is capped at three and has no gameplay identity.
13. Rain is shelter/sky-exposure masked.
14. Weather stays below System 23 to prevent hidden-geometry leaks.
15. Unrendered technical canvas fallback is true black, not a visible grey streaming boundary.
16. Weather feeds System 27 only through `AtmosphericOptics`; Lighting remains illumination owner.
17. Physical visibility combines light + atmospheric extinction downstream of opaque LOS geometry; System 23 remains observer-knowledge owner.
18. Weather feeds System 26 as background detection/localization masking, not fake repeated rain sounds.
19. Cosmetic animation causes zero System 27/23 physical recomputes; quantized Weather revisions drive them.
20. Slice C lightning remains a real future Weather event feeding System 27 physical lighting, not a fake screen flash.
21. Lightning damage/fire remains deferred until real owners exist.
22. Performance verification prefers structural bounded-work proofs over fragile microbenchmarks.
