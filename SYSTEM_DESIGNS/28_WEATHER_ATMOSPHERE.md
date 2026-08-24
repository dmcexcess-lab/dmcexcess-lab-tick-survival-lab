# Tick Survival Lab — System 28 Weather / Atmosphere

Status: **DRAFT — awaiting approval**

User direction, 2026-08-24:

> **“WEATHER! lets make it low res like the rest of the graphics (except the lighting) lighting strikes that use that coll lighting would be nice. ... low rez pixel weather but its always animated unlike the rest of the world.”**

Core rule:

> **Weather is simulation truth; weather animation is presentation. The clouds/rain/fog may keep moving while the turn-based world is paused, but physical weather consequences advance only through WHEN.**

System 28 is the proposed owner for deterministic weather state and its neutral downstream environmental descriptors. It does not become a second lighting, perception or sound system.

---

## 1. Candidate 001 goals

The first playable weather pass should provide:

- clear weather;
- overcast;
- rain;
- storm;
- fog/mist;
- deterministic transitions over authoritative world time;
- low-resolution pixel precipitation/fog presentation;
- presentation animation that continues while the decision-paused world is visually still;
- roof/shelter-aware precipitation so rain does not simply draw through buildings;
- wetness that accumulates/decays over simulation time;
- real System 27 atmosphere changes rather than renderer-only darkness;
- rain/fog/storm effects on useful vision through the existing physical-optics/perception seam;
- rain/storm background masking hooks for System 26 hearing;
- lightning flashes that are physical System 27 illumination events and can therefore affect what player/NPC observers can actually acquire;
- a low-resolution lightning-bolt presentation tied to the same weather event rather than a fake unrelated screen flash.

Snow, temperature exposure, flooding, fire ignition and weather damage are not required for Candidate 001.

---

## 2. Ownership

System 28 owns:

- current authoritative weather state;
- deterministic transition scheduling/profile;
- precipitation/cloud/fog/wind/wetness truth;
- lightning-event timing and world-space event identity;
- snapshot/restore of current weather state;
- neutral atmospheric-optics snapshots for System 27;
- neutral acoustic-environment modifier snapshots for System 26;
- low-resolution weather-presentation descriptors;
- presentation animation phase/state that is explicitly cosmetic and not simulation truth.

System 28 reads:

- WHEN world tick / scheduled events;
- System 25 world-time interpretation when time-of-day context is useful;
- a neutral shelter/sky-exposure provider for precipitation presentation and later exposure mechanics.

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
- ordinary render frame time.

Canonical direction:

`WHEN + world-time/climate profile -> System 28 weather truth -> neutral optics/acoustics/exposure descriptors -> Systems 27/26/23 and future survival systems`

Presentation branches from the same weather truth but never becomes gameplay authority.

---

## 3. Authoritative weather state

Candidate `WeatherState` should be compact and causal rather than meteorological fluid dynamics.

Proposed fields:

- `weather_kind`;
- precipitation intensity `[0,1]`;
- cloud cover `[0,1]`;
- fog density `[0,1]`;
- wind direction as a normalized/simple world vector;
- wind strength `[0,1]`;
- ground wetness `[0,1]`;
- state start tick;
- planned transition tick;
- stable weather revision;
- deterministic weather-event serial/seed.

Candidate weather kinds:

- `CLEAR`;
- `OVERCAST`;
- `RAIN`;
- `STORM`;
- `FOG`.

The kind is a readable profile; the continuous fields carry the actual downstream values.

Weather changes only when WHEN advances and resolves a weather event. Auto-pause and hard pause therefore freeze the physical weather state automatically.

---

## 4. Transition model

Candidate 001 should use a deterministic state-transition profile rather than random rerolls every tick.

A weather transition event chooses the next profile and duration from stable facts such as:

- world/scenario weather seed;
- current weather profile;
- current day/time band;
- transition serial.

The resulting next state and next transition tick are persisted/snapshot-able.

The initial implementation may be scenario-wide while the project has one active local survival area. The contract must not equate weather regions with technical streaming regions.

Future climate/front simulation may provide geographically varying weather through the same query/provider boundary without rewriting presentation, lighting or AI consumers.

---

## 5. Wetness

Ground/environment wetness is slow simulation state, not a particle count.

Candidate behavior:

- rain/storm increases wetness while WHEN advances;
- clear/dry conditions decay wetness gradually;
- hard/decision pause changes no wetness;
- System 27 consumes wetness through `AtmosphericOptics.wet_surface_factor` for the existing restrained reflection treatment;
- future exposure, footprints, vehicle traction, fire and agriculture may read the same weather/wetness truth through neutral seams.

Candidate 001 does not need per-cell puddle hydrology. A local/regional wetness scalar preserves the immediate visual/survival decision at far lower complexity.

---

## 6. System 27 physical-optics adapter

System 28 should map current state into the already-existing `AtmosphericOptics` contract rather than make Lighting inspect weather kinds.

Examples:

- clear: full diffuse/direct/local transmission, no scatter, dry;
- overcast: direct sunlight strongly suppressed, diffuse retained;
- rain: lower contrast/direct light, modest local extinction/scatter, high wetness;
- fog: strong visibility/local-light extinction and strong scatter;
- storm: low direct/diffuse daylight, meaningful extinction/scatter, maximum wetness.

Weather updates increment the optics revision and call the normal System 27 atmosphere seam.

System 27 remains responsible for translating those optics into physical illumination and target-light-dependent acquisition. Weather never edits the vision cone directly.

`visibility_extinction` should be incorporated into the System 27/System 23 acquisition path when System 28 is implemented so fog/rain can reduce useful sight even when a target is adequately illuminated.

---

## 7. System 26 acoustic adapter

Rain and wind are background acoustic conditions, not thousands of fake `RAIN` sound events.

System 28 should provide an `AcousticEnvironmentModifier` adapter that can:

- raise detection thresholds during heavy rain/storm;
- modestly reduce localization quality in rain/wind;
- later support direction-dependent wind effects if profiling/gameplay justifies it.

Discrete thunder is different: it is a real event and may use System 26's normal emission adapter/profile once a lightning event resolves.

The background weather renderer never generates hearing observations by itself.

---

## 8. Low-resolution weather presentation

Weather should visually belong to the pixel-art world even though System 27 light gradients remain smooth/high-resolution.

Preferred implementation:

- one dedicated Weather presentation layer below UI and above normal world lighting where appropriate;
- deliberately low internal render resolution / coarse pixel units;
- nearest-neighbor scaling;
- no high-resolution particle sprites;
- density driven from authoritative weather descriptors;
- local presentation PRNG/phase may animate cosmetically without modifying simulation state.

### Rain

- short 1–2 pixel diagonal streaks;
- direction/slant follows current wind descriptor;
- several density bands rather than thousands of particles;
- occasional tiny low-res splash pixels on exposed ground;
- storm rain is denser/faster, not merely more transparent layers.

### Fog / mist

- chunky low-resolution drifting dither/noise fields;
- slow parallax-like movement;
- System 27 handles the actual physical scatter/extinction; fog graphics only visualize it.

### Overcast

- primarily expressed by System 27's reduced direct light/contrast;
- optional subtle low-res cloud-shadow/dither movement must remain cosmetic unless a later physical cloud-shadow field is deliberately implemented.

### Wind

- changes rain direction and fog drift;
- later may drive leaves/trash only when those are real presentation effects with no implied physical-object mutation.

---

## 9. Always-animated rule

This is a deliberate exception to the otherwise still turn-based world presentation.

While the survivor is waiting at a decision pause:

- rain continues falling;
- fog continues drifting;
- lightning presentation pulses may continue through their short visual envelope;
- lighting glow/shader animation may continue cosmetically;
- actors/world simulation remain still.

The presentation animation uses frame/wall delta only for visual phase.

It must **not**:

- advance weather transitions;
- accumulate wetness;
- move actors;
- advance System 25 time;
- age System 26 simulation observations;
- create new lightning events.

A hard application pause also freezes simulation. If the app is still rendering, cosmetic weather may remain animated; browser/app backgrounding naturally stops presentation frames without changing simulation truth.

---

## 10. Shelter / roof masking

Rain must not simply draw through every roof.

Weather presentation should consume a neutral `SkyExposureProvider`/mask rather than rediscover building geometry or inspect sprites.

Candidate 001 may expose System 27's already-derived sky/enclosure classification through a narrow read-only query because System 27 currently owns that temporary roof approximation.

Rules:

- exposed outdoor cells receive normal precipitation presentation;
- enclosed/roofed cells suppress direct rain streaks/splashes;
- open doors/windows do not make the entire room 'outdoors';
- future explicit Roof/Shelter truth can replace the approximation without rewriting Weather.

Fog/mist may be attenuated indoors rather than absolutely removed, depending on the future shelter profile.

---

## 11. Lightning

Lightning must use the cool physical lighting rather than a renderer-only white flash.

### Authoritative event

A `LightningEvent` should contain stable facts such as:

- event ID/serial;
- event tick;
- storm/weather revision;
- apparent/world strike anchor or distant-strike direction;
- flash intensity profile;
- optional follow-up thunder timing metadata.

The event is created only by System 28 on WHEN time.

### Physical illumination

A narrow Weather -> System 27 adapter should inject a transient lightning illumination event/profile.

Target effect:

- very bright cool-white/blue global outdoor flash;
- strong portal spill through windows/open doors;
- indoor rooms react according to actual enclosure/portal geometry;
- wet neon/road surfaces flare visibly;
- System 23 acquisition recomputes because the physical light changed;
- player and future NPC observers may genuinely acquire something during a lightning flash that was hidden by darkness immediately before/after.

This makes lightning a gameplay perception event, not just eye candy.

The exact physical implementation may be a transient global/direct-light contribution rather than a 128-cell point light; System 27 should own that light shape.

### Pixel bolt presentation

When the event is presented as a nearby/apparent strike, Weather may draw a chunky jagged pixel bolt from the top of the visible weather layer toward the event's apparent world/screen anchor.

The bolt:

- is deliberately low resolution;
- may branch once or twice;
- uses a stable event seed so it does not change shape each frame;
- flickers/decays over a short presentation envelope;
- is tied to the same physical lightning event that caused System 27 illumination.

Candidate 001 should **not** silently apply actor damage, fire ignition or structural damage until those owners have explicit lightning-event consumers. If local lethal strikes become gameplay-relevant later, the event seam already exists.

### Thunder

Thunder should be a later/current narrow System 26 adapter from the same event, with delay derived from strike distance when a meaningful distance exists. It must not reveal exact strike coordinates beyond normal System 26 localization.

---

## 12. Presentation layering

Recommended order:

- normal live world;
- System 27 physical lighting;
- low-res precipitation/fog/weather presentation as appropriate;
- System 23 final knowledge mask where weather should not reveal hidden world truth;
- UI.

Some atmospheric screen-space effects may need a second foreground pass above the perception mask. If so, that pass must contain only weather pixels with no hidden world information.

Lightning physical illumination remains below System 23 and therefore cannot expose hidden truth unless System 23 actually acquires it.

---

## 13. Performance rules

Weather animation must be cheaper than the physical systems it influences.

Candidate requirements:

- no one-Node-per-raindrop design;
- no thousands of Sprite2D particles;
- use one coarse draw/shader/multimesh-style owner;
- precipitation count is presentation-bounded by viewport, not world population;
- low-resolution internal surface strongly limits fill cost;
- simulation weather transitions are event-driven, not per-frame;
- wetness updates occur only on scheduled/tick changes, not every render frame;
- lighting/perception recomputation occurs when physical weather state/revision changes or a lightning flash phase changes, not because rain pixels moved one screen pixel.

This is especially important because System 27/23 already have measured lighting/perception costs and Actor AI is next on the scaling path.

---

## 14. Candidate implementation slices

### A — weather truth + low-res presentation

- `WeatherProfile/WeatherState/WeatherService`;
- deterministic WHEN transitions;
- wetness;
- clear/overcast/rain/storm/fog profiles;
- low-res animated rain/fog renderer;
- shelter-aware precipitation masking;
- DEV weather selector for immediate visual testing;
- snapshot contract.

### B — physical environment integration

- System 27 `AtmosphericOptics` adapter;
- visibility-extinction acquisition consequence;
- System 26 rain/wind masking adapter;
- lighting/perception refresh only on physical weather revisions.

### C — lightning

- scheduled `LightningEvent`;
- transient physical System 27 flash contribution;
- low-res stable-seed bolt/flicker presentation;
- perception recompute during physical flash;
- optional System 26 thunder adapter if cleanly supported;
- damage/fire explicitly deferred.

All slices belong to one System 28 contract.

---

## 15. Candidate verification

A future `verify/system28-weather` must prove at least:

- deterministic weather transition sequence from same seed/state;
- physical weather does not advance during decision/hard pause;
- cosmetic rain/fog presentation phase can advance while simulation tick stays fixed;
- rain increases wetness only with WHEN time;
- clear weather dries wetness with WHEN time;
- weather optics map to System 27 without Weather owning illumination;
- overcast suppresses direct light;
- fog increases extinction/scatter;
- heavy rain/storm changes System 26 masking through the neutral modifier seam;
- rain presentation suppresses roofed cells;
- open door does not remove roof classification;
- weather pixels reveal no hidden WHAT truth;
- lightning event identity/timing deterministic;
- lightning physical flash changes System 27 illumination and can temporarily change System 23 acquisition;
- pixel bolt is presentation-only and tied to the physical event;
- no actor damage/fire is invented;
- canonical startup/mobile-Web rendering path;
- bounded animation/performance budget.

---

## 16. Proposed approval decisions

1. Weather becomes System 28, not a renderer-only effect.
2. Physical state advances only through WHEN; pixel weather keeps animating while decision-paused.
3. Candidate 001 profiles: clear, overcast, rain, storm and fog.
4. Weather state uses compact continuous cloud/precip/fog/wind/wetness fields under those profiles.
5. Initial weather may be scenario-wide, but weather regions must never equal technical streaming regions.
6. Weather feeds System 27 through `AtmosphericOptics`; Lighting does not switch on weather kind.
7. Fog/rain visibility extinction becomes a physical observer-acquisition input, not only screen haze.
8. Rain/wind feed System 26 as background masking/modifiers, not fake repeated rain sound cues.
9. Precipitation/fog graphics are intentionally low-resolution and nearest-scaled.
10. Rain is shelter/sky-exposure masked.
11. Low-res weather animation is cosmetic frame-time presentation and may continue while the turn-based world is paused.
12. Lightning is a real deterministic Weather event.
13. Lightning illumination is a transient System 27 physical-light contribution capable of changing actual observer acquisition.
14. The visible bolt/flicker is low-res presentation tied to that physical event.
15. Lightning damage/fire is deferred until those owning systems explicitly consume lightning events.
16. Optimize/measure System 27 before Weather implementation rather than paying avoidable lighting cost under additional atmosphere/light updates.
