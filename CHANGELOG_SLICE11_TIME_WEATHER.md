# Slice 11 — Day/Night, Weather + World Time — 2026-09-29

## Outcome

Slice 11 reconnects physical world time, daylight and Weather to canonical turn-based action completion without restoring generalized scheduling.

## Canonical time

- `WorldTimeService` now supports an explicit authoritative manual clock.
- Canonical actions advance that clock to the same elapsed tick already committed by the survival condition seam.
- Idle render frames and wall-clock time advance nothing.
- Candidate 001 retains 5 ticks/second, day index + 24-hour clock, and the existing 08:00 start.
- Long actions advance once by their full duration rather than simulating intermediate minutes.

## Daylight and lighting

- Existing `DaylightProfile` and `OutdoorAmbientLightService` remain authoritative.
- Dawn/day/dusk/night still use the existing smooth curve.
- Existing physical lighting, light-cone perception, utility/street lighting and vehicle headlights remain downstream consumers.
- No bloom/shadow framework or per-frame physical lighting clock was introduced.

## Weather

- Existing `WeatherService`, `WeatherState` and Candidate 001 profiles remain weather truth.
- Canonical weather progression now advances coarsely to the authoritative world-time tick.
- Deterministic profile transitions, analytic wetness, optics, acoustic masking, lightning state and GPU atmosphere presentation remain owned by the existing weather stack.
- Weather never rerolls merely because a frame rendered or an ordinary action occurred.

## Persistence and UI

- Durable sessions now include optional `world_time` state alongside the existing weather snapshot.
- Continue restores exact day/time and weather progression.
- Older saves without `world_time` migrate from the restored survival elapsed clock rather than failing.
- The compact HUD now shows day, 12-hour time and current weather.

## Verification

Fresh prompt-local verification:

- `game/scripts/ci/verify_slice11.gd`
- `.github/workflows/slice11.yml`

The verifier proves production boot, idle-time stability, ordinary and vehicle action time advancement, one bounded eight-hour action, weather progression, daylight phase/brightness, retained artificial-light/perception owners, frozen legacy TickKernel, compact HUD output and real durable snapshot/Continue restoration.
