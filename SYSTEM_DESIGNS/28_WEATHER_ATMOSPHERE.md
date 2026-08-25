# Tick Survival Lab — System 28 Weather / Atmosphere

Status: **IMPLEMENTED — Slices A+B+C + P3 GPU presentation revamp**

Core rule:

> **Weather is simulation truth; weather animation is presentation. Physical Weather advances only through WHEN. Cosmetic atmosphere may remain visually alive without becoming simulation work.**

The original design/drafting path remains recoverable in Git history. This file is the canonical implemented contract.

---

## 1. Ownership

System 28 owns:

- deterministic scenario-wide Weather state;
- Candidate 001 clear / overcast / rain / storm / fog profiles;
- deterministic Weather transition selection and scheduling through WHEN;
- continuous precipitation, cloud, fog and wind truth derived from authoritative world tick;
- analytic scenario wetness;
- quantized physical-environment revisions;
- Weather snapshot/restore;
- deterministic storm lightning scheduling/state;
- `LightningEvent` identity, intensity, timing and presentation seed;
- one bounded screen-space cosmetic atmosphere presentation;
- cached shelter/sky-exposure query used to suppress rain over roofed/enclosed cells;
- neutral Weather -> System 27 atmospheric-optics mapping;
- neutral Weather -> System 26 acoustic-environment masking;
- DEV-only Weather/Lightning forcing controls.

System 28 reads:

- WHEN world tick / scheduled-event seam;
- WHAT terrain/STRUCTURE placement for the current shelter approximation;
- current camera presentation only to map the shelter texture under a screen-space effect.

System 28 does **not** own:

- physical illumination/shadow solving — System 27;
- observer LOS/memory/knowledge — System 23;
- sound propagation/heard-observation truth — System 26;
- actor AI;
- health/damage/fire;
- explicit roof/construction truth;
- electricity/power;
- flooding/hydrology;
- persistent debris entities merely because a cosmetic leaf/paper/dust event crossed the screen.

Canonical physical dependency:

`WHEN -> System 28 Weather -> neutral environment descriptors -> Systems 27/26 -> System 23 observer acquisition/knowledge`

Presentation branches from the same Weather/lightning truth but never becomes gameplay authority.

---

## 2. Physical time versus presentation time

### 2.1 Physical Weather

Authoritative Weather advances only through WHEN.

It controls:

- profile-transition timing;
- continuous Weather values;
- wetness;
- environment revision;
- lightning start/end timing;
- downstream optics/hearing consequences.

Decision pause and hard pause therefore freeze physical Weather automatically. There is no per-frame or wall-clock physical Weather simulation.

### 2.2 Cosmetic atmosphere

Rain, fog, debris and the short visible lightning envelope may animate from presentation time.

This presentation time:

- advances zero WHEN ticks;
- changes no physical wetness;
- changes no physical lighting;
- changes no System 23 knowledge;
- changes no System 26 sound truth;
- changes no AI state.

Browser/app backgrounding may simply stop rendering. Weather never catches up an unbounded cosmetic backlog afterward.

---

## 3. Candidate 001 physical Weather

Implemented readable profiles:

- `clear`;
- `overcast`;
- `rain`;
- `storm`;
- `fog`.

Each profile carries compact continuous physical values for precipitation, cloud cover, fog density, normalized wind direction, wind strength, wetting/drying rates and deterministic duration range.

Profile names are readable state; continuous values are the downstream physical contract.

`WeatherService` schedules one meaningful transition event through WHEN rather than running a Weather update every tick. Next profile and duration derive from stable scenario seed + current profile + transition serial. Current continuous values are analytically interpolated from transition start/end ticks. Querying Weather never advances simulation.

Candidate transition neighborhood:

- clear -> clear / overcast / fog;
- overcast -> clear / rain / fog;
- rain -> overcast / rain / storm;
- storm -> rain / overcast;
- fog -> clear / overcast.

Weather identity is unrelated to System 00F technical stream-region identity.

---

## 4. Analytic wetness and quantized physical revisions

Wetness uses an anchor value/tick and profile wetting/drying rates.

Consequences:

- rain/storm increase wetness only when WHEN advances;
- dry Weather reduces wetness only when WHEN advances;
- waiting at a decision pause changes no wetness;
- cosmetic raindrop count has no physical authority.

System 28 uses a compact **12-band environment signature** so tiny interpolation changes do not force expensive downstream work every tick/frame.

A meaningful signature change increments `environment_revision` and emits `weather_changed`.

Physical Lighting/Perception refresh from physical Weather revisions, never from cosmetic animation.

---

## 5. Snapshot / restore

Weather snapshot schema is **v2**.

It preserves:

- scenario seed;
- current/target profile;
- transition start/end ticks;
- wetness anchor/tick;
- environment revision;
- transition serial;
- scheduled Weather event serial;
- quantized signature;
- lightning serial;
- scheduled lightning event kind/serial;
- active lightning ID/start/end/intensity/seed when a flash is in progress.

Exact cosmetic rain/fog/debris positions are intentionally not persistent.

---

## 6. Shelter / sky exposure

`SkyExposureQuery` is a cached read-only enclosure approximation.

Current rules:

- materialized non-structure space reachable from active bounds perimeter is sky exposed;
- structure cells form the enclosure boundary;
- enclosed interior cells are sheltered;
- door/window structure cells remain part of that enclosure boundary regardless of current OPEN/CLOSED passage state.

Opening a door therefore does not make the entire building rain-exposed.

Its cache keys only to terrain revision, STRUCTURE placement revision and requested bounds. ACTOR/ordinary OBJECT churn does not rebuild shelter truth.

A future explicit Roof/Shelter owner may replace this approximation without changing the Weather presentation contract.

---

## 7. P3 — persistent GPU atmosphere presentation

The phone/Safari performance playtest after the P0/P1/P2 architecture gate exposed one remaining Weather-specific flaw: Weather presentation was still doing unnecessary CPU/canvas work and its four-screen-pixel minimum made rain/fog look too large beside the world art.

The P3 correction is canonical:

> **Continuous atmosphere is one persistent GPU surface. Camera movement changes only shelter mapping; it is not a Weather animation step.**

### 7.1 One surface, not particle/canvas loops

`WeatherPresentationRenderer` owns exactly one `WeatherAtmosphereSurface` child.

The surface uses one CanvasItem shader and:

- `SCREEN_UV` for screen-space placement;
- built-in shader `TIME` for cosmetic rain/fog motion;
- no rain/fog particle Nodes;
- no CPU loop producing hundreds of `draw_rect()` calls;
- no per-raindrop screen->world conversion;
- no per-raindrop `SkyExposureQuery` call.

Rain/fog therefore continue to animate as the camera/player moves without waiting for a CPU Weather phase or canvas redraw request.

### 7.2 Pixel scale

P3 deliberately reduces the presentation scale:

- rain base pixel: **2 screen pixels**;
- rain streaks: **1–2 weather pixels** rather than the former 1–3 blocks at a forced 4 px minimum;
- rain shader cadence: **14 visual frames/sec**;
- fog base pixel: **2 screen pixels**;
- fog drift cadence: **4 visual frames/sec** with smaller coherent blocks;
- cosmetic leaf/paper/dust silhouettes are likewise reduced to the same finer screen-pixel language;
- lightning bolt width is approximately **2 screen pixels**, not the former 8 px line produced by the old weather-pixel multiplier.

The intention is pixel-art readability at the scale of the recovered tactical art, not giant foreground Weather sprites.

### 7.3 Cached shelter texture

Rain still appears only where current shelter truth says sky is exposed, but P3 changes how presentation consumes that truth.

`WeatherPresentationRenderer` builds one nearest-neighbor exposure texture:

- one texel per current render-window tactical cell;
- typical critique size is 80×96 = 7,680 texels;
- rebuilt only when the render-window bounds change or `SkyExposureQuery` reports a real terrain/STRUCTURE cache rebuild;
- ordinary camera/player movement does **not** rebuild the texture.

The current camera snapshot updates only `mask_uv_origin` / `mask_uv_scale` shader uniforms so the existing texture remains aligned beneath the screen-space effect.

This preserves the rule that Weather may use world truth only to decide **where** rain can appear; world geometry does not drive the rain animation itself.

### 7.4 CPU housekeeping

CPU Weather presentation housekeeping is reduced to **10 Hz / 100 ms** and owns only:

- progress/lifetime for at most three cosmetic debris records;
- rare clear-weather ambient-event timing;
- the 0.32 s cosmetic lightning lifetime envelope;
- a cheap 0.25 s shelter-cache revision poll.

Long-frame CPU housekeeping catch-up remains capped at four steps.

Continuous rain/fog produces **zero CPU canvas redraw requests**.

### 7.5 Idle Weather sleeps

When there is no precipitation/fog, no active cosmetic debris and no lightning visual, `WeatherAtmosphereSurface.visible` is false. Clear/ordinary overcast therefore do not pay a transparent fullscreen shader pass merely because System 28 exists.

### 7.6 Camera contract

`TacticalRendererStack.set_camera_presentation(snapshot)` remains the external camera seam.

Camera movement:

- requests **zero Weather redraws**;
- advances zero Weather presentation steps;
- advances zero WHEN ticks;
- performs no shelter-mask rebuild;
- performs no rain/fog reseed or phase shift;
- updates only the small shelter-mapping uniforms.

Focused P3 regression sends forty rapid camera changes and proves:

- `WEATHER_OVERLAY_CAMERA_REDRAWS=0`;
- `WEATHER_OVERLAY_MASK_REBUILDS=1` for the original fixture mask;
- continuous rain CPU redraw count remains 0.

---

## 8. Perception-safe layering and black fallback

Canonical visual order remains:

1. live world/actors;
2. System 27 physical lighting;
3. System 28 atmosphere;
4. System 23 perception/knowledge mask;
5. UI.

Weather therefore cannot reveal hidden geometry merely because rain is shelter-suppressed.

Godot's default viewport clear color remains explicit true black so unrendered technical space does not show grey partition edges against System 23 UNSEEN black.

---

## 9. Physical optics and visual extinction

`WeatherAtmosphericOpticsAdapter` maps continuous Weather fields into System 27's neutral `AtmosphericOptics` contract.

Current physical behavior:

- clear is essentially neutral;
- cloud/overcast suppresses direct sky more strongly than diffuse sky;
- rain adds moderate daylight/local-light loss, scatter and visibility extinction;
- storm strongly suppresses direct sky;
- fog produces the strongest scatter/extinction;
- tint shifts modestly cooler under cloud/rain/fog pressure;
- real analytic wetness feeds the existing System 27 wet-surface factor.

System 27 remains the only physical illumination/shadow/portal owner. System 23 resolves opaque geometry first; System 27's acquisition adapter then combines target luminance with atmospheric extinction.

Representative focused fixture remains:

- clear full-light useful range: **12 cells**;
- representative fog full-light useful range: **5 cells**;
- radius-1 near awareness remains protected.

---

## 10. Acoustic masking

`WeatherAcousticEnvironmentModifier` plugs into System 26's existing neutral environment seam.

Rain/wind are competing background noise:

- propagation-cost addition remains 0;
- precipitation + wind raise listener detection threshold;
- precipitation + wind modestly reduce localization quality;
- rain graphics create no `SoundEmission`;
- System 26 owns propagation, hearing decisions and uncertain localization.

Representative storm fixture adds **+19** to the hearing detection threshold relative to clear conditions.

---

## 11. Physical lightning

Lightning is a real WHEN event.

`LightningEvent` contains stable event ID, authoritative start/end tick, normalized physical flash intensity and deterministic bolt seed.

Storms schedule deterministic lightning starts; Candidate 001 normal delay range is **30–120 ticks**. A physical flash lasts **1 WHEN tick**.

Weather -> Lighting uses `AtmosphericOptics.transient_sky_light`. Outdoor cells physically brighten, roofs block full outdoor sky light, windows/open portals transmit lightning through the existing System 27 solution, and System 23 may genuinely acquire current truth during the flash.

Focused regression remains:

- dark/storm exterior before flash: **0.025** useful luminance;
- same exterior during flash: **0.845**;
- roofed interior through a real window portal: **0.356**.

The visible bolt shares the same event ID/seed but is cosmetic, screen-space and approximately **0.32 s** long. P3 renders the bolt on the same GPU atmosphere surface.

Thunder remains deferred because current LightningEvent has no honest physical strike cell. Lightning damage/fire likewise remains deferred until real strike geography and owning mechanics exist.

---

## 12. DEV critique integration

Weather DEV controls remain:

- CLR;
- OVR;
- RAIN;
- STM;
- FOG;
- STRIKE;
- BLOW LEAF.

Forcing profiles changes both visible atmosphere and real physical optics/hearing conditions. `STRIKE` is accepted only while storm is the current source Weather and schedules a real lightning event.

---

## 13. Performance contract

System 28 presentation cost is bounded by the visible screen and tiny cached data, not world size.

Durable P3 constraints:

- one `WeatherPresentationRenderer` owner;
- exactly one persistent `WeatherAtmosphereSurface` child;
- one CanvasItem shader for rain/fog/debris/lightning visuals;
- **2 px** base Weather art scale;
- no per-particle Nodes;
- no CPU rain/fog primitive loop;
- **0 CPU continuous-atmosphere redraw requests**;
- camera movement causes **0 Weather redraws** and **0 shelter-texture rebuilds**;
- shelter texture is one texel per active render-window cell;
- CPU housekeeping is 10 Hz and max four catch-up steps;
- <=3 cosmetic debris records;
- idle clear/overcast atmosphere surface hides completely;
- one meaningful Weather transition event;
- at most one scheduled/active lightning chain;
- analytic wetness;
- quantized downstream physical refreshes.

System 27's independent structural regression remains 7,680 field cells, 1,676 local-emitter candidates and 688 optical-ray candidates for the representative four-light field.

Performance verification prefers structural bounded-work proofs over fragile runner timings.

---

## 14. Verification

Exact-head owner:

`verify/system28-weather`

### `WeatherSmoke.gd`

Covers:

- deterministic transition plan;
- analytic wetness;
- snapshot/restore;
- physical/presentation pause separation;
- one persistent atmosphere surface and no per-particle Nodes;
- 2 px Weather scale;
- 10 Hz bounded CPU housekeeping;
- cached one-texel-per-cell shelter texture;
- **zero CPU redraw loop for continuous rain/fog**;
- calm debris cap.

### `WeatherEnvironmentIntegrationSmoke.gd`

Covers:

- continuous Weather -> System 27 optics;
- real wetness -> wet-surface factor;
- clear/fog useful visual ranges;
- rain/wind System 26 masking;
- zero fake rain absorption;
- forty camera changes update mapping uniforms only;
- zero Weather redraws from camera movement;
- zero shelter-texture rebuilds from camera movement;
- black technical fallback.

### `WeatherLightningSmoke.gd`

Covers deterministic lightning state/seed, WHEN-driven start/end, snapshot v2 state, transient System 27 sky light, window-portal transmission and physical flash termination.

Protected regressions in the Weather owner workflow include System 27 physical lighting, illumination-aware System 23 perception, System 26 spatial sound, System 23 fog/memory and canonical demo startup.

P3 focused branch verification produced:

- `WEATHER_CPU_CONTINUOUS_REDRAWS=0`;
- `WEATHER_OVERLAY_CAMERA_REDRAWS=0`;
- `WEATHER_OVERLAY_MASK_REBUILDS=1`;
- clear range 12 / fog range 5;
- storm hearing mask +19;
- lightning 0.025 -> 0.845 exterior and 0.356 through a real window portal.

Final canonical executable evidence is the exact `main` head carrying this implementation after `verify/system28-weather` and the repository's full required exact-head suite are green.

---

## 15. Implemented decisions

1. Weather is physical simulation state, not merely a visual effect.
2. Physical Weather advances only through WHEN.
3. Cosmetic atmosphere may animate while the player is decision-paused.
4. Candidate profiles are clear, overcast, rain, storm and fog with continuous physical fields beneath them.
5. Physical Weather is event-driven/analytic; no fine per-tick Weather loop exists.
6. Wetness is analytic and independent of cosmetic rain count.
7. Environment revision is quantized.
8. Weather identity is not technical streaming-region identity.
9. Weather presentation owns no per-particle Nodes.
10. **Rain/fog/debris/lightning cosmetic output is one screen-space GPU atmosphere surface.**
11. **Camera movement updates only shelter mapping and causes zero Weather redraw/phase work.**
12. **Continuous rain/fog requires zero CPU canvas redraw loop.**
13. Weather presentation uses a 2 px base art scale rather than the previous forced 4 px blocks.
14. Shelter rejection uses one cached per-cell texture, not a world query per raindrop.
15. Idle clear/overcast presentation hides the atmosphere surface.
16. Cosmetic debris has no persistent gameplay identity.
17. Rain shelter masking cannot reveal hidden geometry because Weather remains below System 23.
18. Unrendered technical fallback remains true black.
19. Weather feeds System 27 only through neutral atmospheric optics; Lighting remains physical-light owner.
20. Weather feeds System 26 as background masking, not fake repeated rain emissions.
21. Physical visibility combines atmosphere + physical light downstream of opaque System 23 geometry.
22. Lightning is a deterministic real WHEN event.
23. The visible bolt and physical flash share one LightningEvent identity/seed but may have different presentation/simulation lifetimes.
24. Thunder is deferred until an honest strike location exists; no fake spatial thunder source is permitted.
25. Lightning damage/fire is deferred until real owners consume a future geographic strike event.
26. Performance verification prefers structural bounded-work proofs over fragile microbenchmarks.
