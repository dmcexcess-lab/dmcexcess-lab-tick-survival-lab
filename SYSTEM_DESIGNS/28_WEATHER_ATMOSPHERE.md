# Tick Survival Lab — System 28 Weather / Atmosphere

Status: **IMPLEMENTED — Slices A+B+C**

Core rule:

> **Weather is simulation truth; weather animation is presentation. Physical Weather advances only through WHEN. Weather graphics are a cheap screen-space atmosphere overlay, while physical wetness, lighting, visibility and hearing consequences remain world/simulation truth.**

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
- low-resolution screen-space rain/fog/debris/bolt presentation;
- cached shelter/sky-exposure query used to suppress rain over known roofed/enclosed cells;
- neutral Weather -> System 27 atmospheric-optics mapping;
- neutral Weather -> System 26 acoustic-environment masking;
- DEV-only Weather/Lightning forcing controls.

System 28 reads:

- WHEN world tick / scheduled-event seam;
- WHAT terrain/structure placement for the current shelter approximation.

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

Decision pause and hard pause therefore freeze physical Weather automatically.

There is no per-frame or wall-clock physical Weather simulation.

### 2.2 Cosmetic atmosphere

Rain, fog, debris and the short visible lightning-bolt envelope may animate from render delta.

This presentation time:

- advances zero WHEN ticks;
- changes no physical wetness;
- changes no physical lighting;
- changes no System 23 knowledge;
- changes no System 26 sound truth;
- changes no AI state.

Browser/app backgrounding may simply stop drawing; Weather never catches up an unbounded cosmetic backlog afterward.

---

## 3. Candidate 001 Weather profiles

Implemented readable profiles:

- `clear`;
- `overcast`;
- `rain`;
- `storm`;
- `fog`.

Each profile carries compact continuous physical values for:

- precipitation;
- cloud cover;
- fog density;
- normalized wind direction;
- wind strength;
- wetting rate;
- drying rate;
- deterministic duration range.

Profile names are readable state; continuous values are the downstream physical contract.

---

## 4. Deterministic event-driven transitions

`WeatherService` schedules one meaningful transition event through WHEN instead of running a Weather update every tick.

Next profile and duration derive from stable scenario seed + current profile + transition serial.

Current continuous values are analytically interpolated from transition start/end ticks. Querying Weather never advances simulation.

Candidate transition neighborhood:

- clear -> clear / overcast / fog;
- overcast -> clear / rain / fog;
- rain -> overcast / rain / storm;
- storm -> rain / overcast;
- fog -> clear / overcast.

Weather identity is unrelated to System 00F technical stream-region identity.

---

## 5. Analytic wetness and quantized revisions

Wetness uses an anchor value/tick and profile wetting/drying rates.

Consequences:

- rain/storm increase wetness only when WHEN advances;
- dry Weather reduces wetness only when WHEN advances;
- waiting at a decision pause changes no wetness;
- cosmetic raindrop count has no physical authority.

System 28 uses a compact **12-band environment signature** so tiny interpolation changes do not force expensive downstream work every tick/frame.

A meaningful signature change increments `environment_revision` and emits `weather_changed`.

Physical Lighting/Perception therefore refresh from physical Weather revisions, never from 20 Hz cosmetic animation.

---

## 6. Snapshot / restore

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

Exact cosmetic raindrop/fog/debris positions are intentionally not persistent.

Weather is restored alongside the owning WHEN snapshot by future save orchestration.

---

## 7. Shelter / sky exposure

`SkyExposureQuery` remains a cached read-only enclosure approximation.

Current rules:

- materialized non-structure space reachable from active bounds perimeter is sky exposed;
- structure cells form the enclosure boundary;
- enclosed interior cells are sheltered;
- door/window structure cells remain part of that enclosure boundary regardless of current OPEN/CLOSED passage state.

Opening a door therefore does not make the entire building rain-exposed.

A future explicit Roof/Shelter owner may replace this approximation without changing the Weather presentation contract.

---

## 8. Screen-space atmosphere presentation

The important post-playtest correction is now canonical:

> **Rain/fog/debris presentation is screen-space. Camera movement is not Weather work.**

`WeatherPresentationRenderer` remains one low-overhead `Node2D` owner with no per-particle child Nodes.

Implemented presentation bounds:

- target **20 Hz / 50 ms** active atmosphere cadence;
- max four cosmetic catch-up steps after a long frame;
- virtual axis <=256;
- max 180 rain candidates;
- max 36 fog patches;
- max three debris records;
- calm clear Weather can sleep between rare ambient events.

`set_camera_local_position()` is now a compatibility seam only. Camera movement:

- requests **zero Weather redraws**;
- advances zero Weather presentation steps;
- advances zero WHEN ticks;
- does not clear/reseed rain;
- does not phase-shift rain/fog/debris;
- cannot make Weather disappear while repeated movement actions are submitted.

Origin-only render-window shifts likewise do not disturb the overlay.

The overlay surface resizes only when actual viewport/render dimensions change.

Rain still maps a screen sample back to a current world cell when shelter rejection is needed; this lookup does not make the atmosphere world-anchored again.

Focused regression after the screen-space conversion:

`WEATHER_OVERLAY_CAMERA_REDRAWS=0`

after forty rapid camera-position updates.

---

## 9. Perception-safe layering and black fallback

Canonical visual order remains:

1. live world/actors;
2. System 27 physical lighting;
3. System 28 low-res atmosphere;
4. System 23 perception/knowledge mask;
5. UI.

Weather therefore cannot reveal hidden geometry merely because rain is shelter-suppressed.

Godot's default viewport clear color remains explicit true black so unrendered technical space does not show grey partition edges against System 23 UNSEEN black.

---

## 10. Physical optics and vision extinction

`WeatherAtmosphericOpticsAdapter` maps continuous Weather fields into System 27's neutral `AtmosphericOptics` contract.

Current physical behavior:

- clear is essentially neutral;
- cloud/overcast suppresses direct sky more strongly than diffuse sky;
- rain adds moderate daylight/local-light loss, scatter and visibility extinction;
- storm strongly suppresses direct sky;
- fog produces the strongest scatter/extinction;
- tint shifts modestly cooler under cloud/rain/fog pressure;
- real analytic wetness feeds the existing System 27 wet-surface factor.

System 27 remains the only physical illumination/shadow/portal owner.

System 23 still resolves opaque geometry first. System 27's acquisition adapter then combines target luminance with current atmospheric `visibility_extinction`.

Atmosphere can reduce useful visual acquisition inside the geometric envelope; it never expands LOS or reveals through walls.

Representative focused fixture:

- clear full-light useful range: **12 cells**;
- representative fog full-light useful range: **5 cells**;
- radius-1 near awareness remains protected.

---

## 11. Acoustic masking

`WeatherAcousticEnvironmentModifier` plugs into System 26's existing neutral environment seam.

Current policy treats rain/wind as **competing background noise**:

- propagation-cost addition remains 0;
- precipitation + wind raise listener detection threshold;
- precipitation + wind modestly reduce localization quality;
- rain pixels create no `SoundEmission`;
- System 26 still owns physical propagation, hearing decisions and uncertain localization.

Representative storm fixture adds **+19** to the hearing detection threshold relative to clear conditions.

---

## 12. Slice C — physical lightning

Slice C is implemented.

### 12.1 Physical event

`LightningEvent` contains:

- stable event ID;
- authoritative start tick;
- authoritative end tick;
- normalized physical flash intensity;
- deterministic bolt seed.

Lightning exists only during `storm` source Weather.

Storms schedule the next lightning start through WHEN using a deterministic delay. Candidate 001 normal delay range is **30–120 ticks**.

A flash lasts **1 WHEN tick** physically.

When lightning starts:

- the event becomes active Weather truth;
- `environment_revision` advances;
- `weather_changed` publishes the physical change;
- the exact same event is exposed to presentation via `lightning_started`.

At the end tick:

- the physical flash clears;
- environment revision advances again;
- another deterministic storm lightning event may be scheduled.

DEV `force_lightning()` does not create an immediate renderer-only flash; it schedules a real future WHEN lightning event.

### 12.2 System 27 physical flash

Weather -> Lighting uses `AtmosphericOptics.transient_sky_light`.

The physical lighting backend treats lightning as broad transient sky energy.

Consequences include:

- outdoor cells physically brighten;
- roofed cells do not receive full outdoor sky light;
- windows/open portals transmit lightning into interiors through the existing portal solution;
- System 23 may genuinely acquire current truth during the one-tick physical flash;
- the renderer visualizes the resulting physical lighting rather than deciding it.

Focused C regression:

- dark/storm exterior before flash: **0.025** useful luminance;
- same exterior during flash: **0.845**;
- roofed interior receiving the flash through a real window portal: **0.356**.

### 12.3 Low-resolution bolt presentation

The visible bolt is presentation tied to the same physical event ID/seed.

Current visual envelope:

- deterministic chunky/pixel path from event seed;
- bounded short screen-space presentation;
- approximately **0.32 s** visual lifetime;
- may outlast the one-tick physical flash cosmetically;
- cannot keep physical light active after WHEN says the flash ended.

This intentionally separates a readable visual flash/bolt from simulation timing while preserving one causal event.

### 12.4 Thunder remains deferred

Thunder is **not faked** in current Slice C.

The implemented LightningEvent has no exact physical strike cell. System 26's rule remains:

> **Sound is physical. Hearing is an estimate.**

Inventing a spatial thunder source merely to make noise would violate that rule.

Thunder can be added when lightning gains honest strike geography (the same future seam needed for strike damage/fire). At that point System 26 can consume the real strike event with ordinary propagation, delay, uncertainty and localization.

Lightning damage/fire likewise remains deferred until real owners exist.

---

## 13. DEV critique integration

Rural Crossroads remains a DEV critique composition.

Weather controls expose:

- CLR;
- OVR;
- RAIN;
- STM;
- FOG;
- STRIKE;
- BLOW LEAF.

The panel now sits **below the existing STATS / INVENTORY / MENU header row** and uses a layer that keeps it above ordinary HUD/world presentation without hiding behind the player-shell header controls.

Forcing profiles changes both visible atmosphere and real physical optics/hearing conditions.

`STRIKE` is accepted only when current source Weather is storm and schedules a real lightning event.

---

## 14. Performance contract

System 28 remains bounded by viewport/presentation demand, not world size.

Structural constraints:

- one Weather renderer;
- 20 Hz active atmosphere animation;
- no per-particle Nodes;
- <=256 virtual axis;
- <=180 rain candidates;
- <=36 fog patches;
- <=3 debris records;
- one meaningful Weather transition event;
- at most one scheduled/active lightning chain per Weather service;
- analytic wetness;
- quantized downstream physical refreshes;
- **zero camera-motion Weather redraws**.

Current System 27 structural regression remains independent:

- 7,680 field cells;
- 1,676 local-emitter candidates;
- 688 optical-ray candidates for the representative four-light field.

On the first fully green Slice-C runner, representative System 27 rebuild was ~2.00 ms and illumination-aware perception ~7.28 ms. These timings are runner-noisy; bounded work contracts are the durable requirement.

---

## 15. Verification

Exact-head owner:

`verify/system28-weather`

Coverage:

### `WeatherSmoke.gd`

- deterministic transition plan;
- analytic wetness;
- snapshot/restore;
- pause/presentation separation;
- 20 Hz bounded presentation;
- shelter query;
- no per-particle Nodes.

### `WeatherEnvironmentIntegrationSmoke.gd`

- continuous Weather -> System 27 optics;
- real wetness -> wet-surface factor;
- clear/fog useful visual ranges;
- rain/wind System 26 masking;
- zero fake rain absorption;
- **screen-space overlay ignores repeated camera movement**;
- black technical fallback.

### `WeatherLightningSmoke.gd`

- deterministic lightning event state/seed;
- WHEN-driven start/end;
- snapshot schema v2 lightning state;
- transient physical System 27 sky-light contribution;
- window portal transmission into roofed interior;
- physical flash ends with WHEN;
- zero fake permanent light.

Protected regressions in the Weather owner workflow include System 27 physical lighting, illumination-aware System 23 perception, System 26 spatial sound, System 23 fog/memory and canonical demo startup.

First fully green executable Slice-C head:

`21014fe5915e47344b4b8d5f48e52fa69c386254`

Focused C outputs:

- `WEATHER_OVERLAY_CAMERA_REDRAWS=0`;
- `WEATHER_C_LIGHTNING_BEFORE=0.025`;
- `WEATHER_C_LIGHTNING_FLASH=0.845`;
- `WEATHER_C_LIGHTNING_PORTAL=0.356`;
- `WEATHER_C_LIGHTNING_SEED=629519319`.

All **13 required executable-head contexts** were green on `21014fe5915e47344b4b8d5f48e52fa69c386254`, including `verify/system28-weather`, Systems 23/26/27 and `verify/pages-deploy`.

---

## 16. Approved/implemented decisions

1. Weather is physical simulation state, not merely a visual effect.
2. Physical Weather advances only through WHEN.
3. Cosmetic atmosphere may animate while the player is decision-paused.
4. Candidate profiles are clear, overcast, rain, storm and fog with continuous physical fields beneath them.
5. Physical Weather is event-driven/analytic; no fine per-tick Weather loop exists.
6. Wetness is analytic and independent of cosmetic rain count.
7. Environment revision is quantized.
8. Weather identity is not technical streaming-region identity.
9. Weather presentation is one bounded low-res owner with no per-particle Nodes.
10. **Rain/fog/debris are a screen-space overlay; camera movement requests zero Weather redraws.**
11. Calm clear Weather may sleep between rare cosmetic debris events.
12. Cosmetic debris has no persistent gameplay identity.
13. Rain shelter masking cannot reveal hidden geometry because Weather remains below System 23.
14. Unrendered technical fallback remains true black.
15. Weather feeds System 27 only through neutral atmospheric optics; Lighting remains physical-light owner.
16. Weather feeds System 26 as background masking, not fake repeated rain emissions.
17. Physical visibility combines atmosphere + physical light downstream of opaque System 23 geometry.
18. Lightning is a deterministic real WHEN event.
19. The visible bolt and physical flash share one LightningEvent identity/seed but may have different presentation/simulation lifetimes.
20. Lightning physically illuminates the System 27 field and real portals; System 23 may therefore acquire truth during the flash.
21. Thunder is deferred until an honest strike location exists; no fake spatial thunder source is permitted.
22. Lightning damage/fire is deferred until real damage/fire owners consume a future geographic strike event.
23. Performance verification prefers structural bounded-work proofs over fragile microbenchmarks.