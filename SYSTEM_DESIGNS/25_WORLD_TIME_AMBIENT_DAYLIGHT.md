# Tick Survival Lab — System 25 World Time / Ambient Daylight

Status: **IMPLEMENTED — Candidate 001, 2026-08-23**

Approval basis: the user requested that REMEMBERED fog vary with overall light/time of day and explicitly gave implementation discretion: **“maybe just as simple as linking it to time of day instead of trying to keep track of varying light levels. but do what you think you can.”** System 25 is the durable implementation of that request rather than a demo-only fake clock.

First fully green executable head: `6b6680c5b8eb4d8db2c4097df093abace661d5c7`.

Exact-head context: `verify/system25-world-time-light`.

## 1. Goal

Provide a real simulation-time interpretation layer downstream of WHEN and a deterministic outdoor daylight baseline that other systems can consume without teaching WHEN what seconds, hours, dawn or night mean.

Immediate player-facing use:

> System 23 REMEMBERED fog uses current outdoor ambient daylight, becoming darker at night and brighter by day while UNSEEN remains true black.

## 2. Ownership

System 25 owns:

- tick-to-simulation-time interpretation;
- scenario-local day index and time of day;
- a baseline dawn/day/dusk/night curve;
- normalized outdoor daylight and phase labels;
- change notification when authoritative WHEN time changes.

System 25 reads but does not own `TickKernel.world_tick()` and its advancement/reset signals.

System 25 does **not** own:

- WHEN scheduling or tick advancement;
- wall-clock time;
- Gregorian calendar/date/season/latitude;
- weather attenuation;
- indoor lighting;
- artificial/local lights, power grids, flashlights or fire;
- LOS or vision-range mechanics;
- save-file orchestration.

Canonical dependency direction:

`WHEN world_tick -> System 25 time interpretation -> daylight consumers`

## 3. Candidate 001 world-time profile

`WorldTimeProfile` is scenario configuration.

Live baseline:

- **5 ticks = 1 simulation second**;
- **300 ticks = 1 simulation minute**;
- **18,000 ticks = 1 simulation hour**;
- **432,000 ticks = 1 simulation day**;
- scenario-local start: **day 0, 08:00:00**.

This makes current common actions physically legible without changing WHEN:

- 3-tick turn ~= 0.6 s;
- 5-tick TAKE/STORE ~= 1.0 s;
- 10-tick one-cell walk ~= 2.0 s;
- 8–15 tick search ~= 1.6–3.0 s.

These are gameplay tuning values, not foundation identity.

## 4. Derived clock

`WorldTimeService` derives its complete clock from current `world_tick`; it owns no second advancing counter.

A time snapshot includes:

- authoritative world tick;
- elapsed simulation seconds;
- subsecond tick;
- day index;
- second of day;
- hour/minute/second;
- normalized day fraction.

Hard pause changes no System 25 time because WHEN advances no ticks. WHEN snapshot/restore deterministically restores the same derived clock.

Candidate 001 intentionally uses day index + time of day rather than inventing a historical calendar date.

## 5. Daylight profile

`DaylightProfile` is separate from the clock.

Temperate Candidate 001 baseline:

- dawn begins: **05:30**;
- full daylight: **07:30**;
- dusk begins: **18:30**;
- night begins: **20:30**;
- night daylight level: **0.08**;
- full daylight level: **1.00**.

Dawn and dusk interpolate smoothly with no abrupt lighting step.

Phase labels:

- `night`
- `dawn`
- `day`
- `dusk`

## 6. Outdoor ambient-light service

`OutdoorAmbientLightService` consumes `WorldTimeService` + `DaylightProfile` and exposes:

- normalized ambient daylight `[0,1]`;
- current daylight phase;
- copied current time/daylight snapshot;
- `ambient_light_changed(level, phase, snapshot)`.

The service performs no frame polling and advances zero ticks.

Weather remains a separate future multiplier rather than being baked into baseline daylight.

## 7. System 23 integration

`PerceptionOverlayRenderer` accepts:

`set_ambient_light_level(level_0_to_1)`

Rules:

- REMEMBERED content remains stale last-observed knowledge;
- memory does not store historical lighting;
- hidden current WHAT is never queried;
- ambient daylight changes presentation only;
- UNSEEN stays fully opaque black at all times;
- VISIBLE current-world rendering is not globally darkened by this slice;
- last-seen actor markers and auditory cues remain separate information/presentation channels.

Remembered environmental luminance:

- full daylight: **0.30**;
- zero ambient input: **0.10**;
- interpolate between them from current ambient daylight.

With Candidate 001's night baseline of `0.08`, remembered luminance is approximately `0.116`: clearly darker than day while still distinct from true-black unexplored fog.

The canonical Rural Crossroads composition wires `OutdoorAmbientLightService.ambient_light_changed` into `TacticalRendererStack.set_perception_ambient_light_level`.

## 8. Why visible-world darkness is deferred

A believable live-world lighting system must eventually account for outdoor daylight, interiors/roofing, windows/openings, weather, local emitters, electrical state, flashlights/fire and light-dependent sight.

Globally tinting all live sprites here would bypass those physical rules. System 25 therefore establishes the correct time/daylight seam first and uses it for the requested remembered-fog behavior only.

## 9. Persistence / restore

System 25 owns no additional mutable time counter.

Deterministic restore needs:

- restored WHEN world tick;
- the same `WorldTimeProfile`;
- the applicable `DaylightProfile`.

Future scenario/save orchestration may persist profile/epoch choices. System 25 does not own the save file.

## 10. Performance

- no `_process()` / `_physics_process()` time advancement;
- no wall-clock polling;
- no world or cell scan;
- derived calculation only when WHEN advances/resets or daylight profile changes;
- one normalized scalar consumed by the perception overlay.

## 11. Verification

Dedicated smoke: `game/scripts/ci/WorldTimeAmbientSmoke.gd`.

Dedicated workflow: `.github/workflows/world-time-ambient.yml`.

The smoke proves:

- exact tick -> second/minute/hour/day mapping;
- midnight rollover;
- hard pause produces zero clock advancement;
- deterministic WHEN snapshot/restore mapping;
- dawn/day/dusk/night boundaries;
- smooth dawn/dusk interpolation;
- System 23 ambient-memory luminance behavior;
- UNSEEN remains true black.

The workflow also runs WHEN, System 23 and canonical-demo startup regressions.

On executable head `6b6680c5b8eb4d8db2c4097df093abace661d5c7`, all ten exact-head contexts were green:

- `verify/system25-world-time-light`;
- `verify/system24-loot`;
- `verify/system23-perception`;
- `verify/system22-area-critique`;
- `verify/system21-camera-view`;
- `verify/system20-local-area`;
- `verify/system19-local-building`;
- `verify/system00f-streaming-materialization`;
- `verify/system00d-global-world`;
- `verify/pages-deploy`.

## 12. Future seams

System 25 prepares cleanly for:

- actual scenario calendar/date/season;
- latitude/day-length variation;
- weather attenuation;
- visible-world ambient lighting;
- indoor/local/artificial light sources;
- light-dependent effective vision;
- survivor schedules and sleep behavior;
- agriculture/crops;
- utility/streetlight schedules;
- outbreak/population schedule simulation;
- time/date HUD presentation.

None of those should require WHEN to learn what a clock means.
