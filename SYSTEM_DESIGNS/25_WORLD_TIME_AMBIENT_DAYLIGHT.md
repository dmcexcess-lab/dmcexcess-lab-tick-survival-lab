# Tick Survival Lab — System 25 World Time / Ambient Daylight

Status: **APPROVED — implementation authorized 2026-08-23**

Approval basis: after asking for remembered fog darkness to vary with overall light/time of day, the user explicitly chose the durable architecture over a demo-only curve: **“lets set it up right even if i cant test it.”**

## 1. Goal

Add a real simulation-time interpretation layer without teaching WHEN what a minute, hour, day, dawn or night means.

System 25 provides:

- a validated mapping from authoritative WHEN ticks to simulation-local day/time;
- a deterministic outdoor daylight baseline derived from that time;
- a small public presentation/mechanics seam that can later feed lighting, weather, schedules, crops, utilities, outbreak simulation and perception.

Immediate player-facing use:

> System 23 REMEMBERED fog uses the current ambient-light value so remembered places are darker at night and brighter during the day while remaining distinct from true-black UNSEEN fog.

## 2. Ownership

System 25 owns:

- tick-to-simulation-time interpretation;
- scenario-local day index and time-of-day derivation;
- the baseline daylight profile for dawn/day/dusk/night;
- normalized outdoor daylight output and phase labeling;
- deterministic change signals when authoritative time advances.

System 25 reads but does not own:

- `TickKernel.world_tick()` and timing/reset signals.

System 25 does **not** own:

- WHEN scheduling or advancement;
- wall-clock/real-world time;
- absolute historical calendar/era;
- seasons/latitude/astronomy;
- weather/cloud cover;
- indoor/local light sources;
- flashlights, fires, generators, streetlights or electrical grids;
- LOS/vision-range mechanics;
- renderer draw rules other than consumers using its public light value;
- save orchestration.

## 3. WHEN remains mechanic-agnostic

Canonical dependency direction:

`WHEN integer world tick -> System 25 time interpretation -> daylight/lighting consumers`

WHEN remains unchanged and continues to know only integer simulation ticks.

System 25 may be replaced or retuned without changing scheduled action/event semantics.

## 4. World-time profile

`WorldTimeProfile` is validated scenario configuration.

Candidate 001 live baseline:

- **5 ticks = 1 simulation second**;
- **300 ticks = 1 simulation minute**;
- **18,000 ticks = 1 simulation hour**;
- **432,000 ticks = 1 simulation day**;
- scenario-local start is **day 0, 08:00:00**.

This makes current common action timings physically plausible without forcing WHEN to adopt the interpretation:

- 3-tick turn ~= 0.6 s;
- 5-tick item TAKE/STORE ~= 1.0 s;
- 10-tick one-cell walk ~= 2.0 s;
- 8–15 tick container search ~= 1.6–3.0 s.

These values are gameplay tuning, not foundation identity. Changing the profile later does not rewrite WHEN.

## 5. Derived clock contract

`WorldTimeService` is derived from current `world_tick` plus `WorldTimeProfile`; it does not maintain a second advancing clock.

A current time snapshot exposes at least:

- authoritative `world_tick`;
- elapsed simulation seconds from the scenario origin;
- scenario-local `day_index`;
- `second_of_day`;
- hour/minute/second;
- normalized day fraction.

Time never advances from render frames or wall clock. Hard pause therefore changes no System 25 time because WHEN changes no tick.

Crossing midnight increments `day_index` deterministically.

## 6. Calendar scope

Candidate 001 deliberately uses **scenario-local day index + time of day**, not an invented Gregorian date/year.

Future world/scenario design may map day index to an actual date, season and latitude without changing the tick/time contract.

## 7. Daylight profile

`DaylightProfile` is validated configuration separate from the clock.

Candidate 001 temperate baseline:

- dawn begins: **05:30**;
- full daylight: **07:30**;
- dusk begins: **18:30**;
- night begins: **20:30**;
- normalized night daylight: **0.08**;
- normalized full daylight: **1.00**.

Dawn and dusk interpolate smoothly rather than stepping abruptly.

Phase labels are:

- `night`
- `dawn`
- `day`
- `dusk`

The fixed Candidate 001 profile is a baseline only. Seasons/latitude may later replace/update it.

## 8. Ambient daylight service

`OutdoorAmbientLightService` consumes `WorldTimeService` and `DaylightProfile` and exposes:

- current normalized daylight `[0,1]`;
- current phase;
- a copied time/daylight snapshot;
- a change signal when authoritative time or the daylight profile changes.

It owns no render state and advances zero ticks.

Weather is intentionally not folded into this service. A later lighting/environment owner may combine baseline daylight with cloud/fog/storm attenuation and local artificial sources.

## 9. System 23 integration

System 23 gains one presentation-only input:

`set_ambient_light_level(level_0_to_1)`

Rules:

- environmental memory remains stale last-observed world truth;
- remembered records do **not** store remembered historical lighting;
- hidden WHAT is never polled;
- current ambient light changes only how remembered snapshots are presented;
- true `UNSEEN` stays fully opaque black at every time of day;
- `VISIBLE` current-world renderers are not darkened by this slice.

Candidate 001 remembered environmental luminance:

- full daylight: preserve the existing **0.30** memory luminance;
- deepest ambient darkness: **0.10** memory luminance;
- interpolate between those values from the supplied ambient-light level.

This keeps REMEMBERED readable but clearly darker at night while preserving the hard information boundary between REMEMBERED and UNSEEN.

Last-seen actor marker styling remains separately readable and is not made mechanically authoritative by ambient changes.

## 10. Why visible world lighting is deferred

A real visible-world lighting pass must eventually account for:

- outdoor daylight;
- interiors/roofing;
- windows/openings;
- local light emitters;
- power state;
- flashlights/fire;
- weather attenuation;
- vision-range consequences.

Darkening all live sprites globally in this slice would look like progress while bypassing those physical rules. Candidate 001 therefore establishes the correct clock/daylight seam and uses it only for the requested remembered-fog presentation.

## 11. Persistence / restore

System 25 stores no second mutable time counter.

Deterministic restore requires:

- restored WHEN `world_tick`;
- the same scenario `WorldTimeProfile`;
- the applicable `DaylightProfile`.

A future scenario/save owner may persist those profiles/epoch choices. System 25 does not own the save file.

## 12. Performance / mobile

- no `_process()` or wall-clock polling;
- no per-cell lighting simulation;
- one derived calculation when WHEN advances/reset or profile changes;
- Perception overlay simply redraws with one normalized scalar;
- no world scan.

## 13. Verification requirements

Dedicated System 25 CI must prove:

- exact tick -> second/minute/hour/day mapping;
- midnight rollover;
- hard pause produces no time change because WHEN produces no tick change;
- deterministic mapping after WHEN snapshot/restore;
- dawn/day/dusk/night phase boundaries;
- smooth normalized dawn/dusk interpolation;
- System 23 remembered luminance responds to ambient light while true fog remains black;
- no System 25 `_process()`/wall-clock advancement;
- WHEN regression;
- System 23 perception regression;
- canonical demo startup.

Exact-head context:

`verify/system25-world-time-light`

## 14. Future seams

System 25 intentionally prepares for:

- actual scenario calendar/date/season;
- latitude/day-length variation;
- weather attenuation;
- visible-world ambient lighting;
- artificial/local light sources;
- light-dependent effective vision;
- survivor schedules/sleep;
- crops/agriculture;
- utilities/streetlights;
- outbreak/population schedules and curfews;
- time/date HUD presentation.

None of those future systems should require WHEN to learn what a clock means.
