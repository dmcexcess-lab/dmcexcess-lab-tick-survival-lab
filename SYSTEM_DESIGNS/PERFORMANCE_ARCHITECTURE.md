# Tick Survival Lab — Performance Architecture Gate

Status: **IMPLEMENTED + CI VERIFIED — P0/P1/P2; P3 Weather presentation implemented**

Approved: **2026-08-24**

P0/P1/P2 first fully green executable head: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

Roadmap role: **non-numbered engineering gate before Phase 1B**.

Core rule:

> **A world mutation may update truth many times; expensive consumers wake only for the domains and completed batches they actually depend on.**

The game is discrete-time, low-resolution and phone/Safari-first. Ordinary walking must not rebuild unrelated world geometry or turn a technical streaming boundary into a synchronous fan-out storm.

## P0 — runtime telemetry

A neutral `PerformanceTelemetry` collector records low-overhead last/max timings and work counts for streaming, lighting simulation/presentation, perception, interaction, Weather CPU presentation housekeeping and sky-exposure rebuilds. The canonical DEV view exposes a compact 2 Hz panel. Telemetry is observation only and never changes simulation/rendering decisions.

CI prefers deterministic work-count and invalidation assertions over fragile wall-clock thresholds.

## P1 — domain revisions + batch summaries

Global WHAT `revision()` remains authoritative. WHAT adds cache-oriented `terrain_revision()` and `placement_revision(channel)` values. `WorldChange` carries before/after placement-channel metadata.

Explicit bulk operations may use `begin_change_batch()` / `end_change_batch()` and emit one compact `WorldChangeBatch` summary after successful completion. Authoritative writes still occur immediately; the legacy `changed` signal remains for unmigrated consumers. Batching is notification compaction, not alternate truth or rollback.

System 00F brackets multi-source streaming materialization with this notification batch inside its existing transaction. A rollback cancels the notification batch first.

## P2 — dependency-correct cache invalidation

System 27 field geometry keys only to terrain + STRUCTURE placement revisions + field bounds. Door optics, ambient, atmosphere and emitters remain their own dependencies. ACTOR and ordinary OBJECT churn must not rebuild lighting geometry or samples.

`SkyExposureQuery` keys its shelter mask to terrain + STRUCTURE revisions, not global WHAT revision.

System 23 and System 29 suppress low-level notifications while an explicit WHAT batch is active, then consume the completed dirty summary once when relevant local bounds intersect. System 24's interaction-offer provider suppresses intermediate enrollment broadcasts during the same batch.

The lighting presentation renderer likewise ignores unrelated ACTOR/OBJECT changes and redraws for visible terrain/STRUCTURE dirtiness or actual light-input changes.

P0/P1/P2 executable `0398a2a49d84e6067f7610727aecacf4c05fe41f` finished **42/42 associated workflow runs successfully** and all **15 required exact-head contexts** were green.

## P3 — GPU Weather presentation

Human playtest after P2 reported ordinary movement as materially improved but exposed Weather as the remaining presentation-specific problem: rain/fog visibly stopped during repeated movement, resumed when movement stopped, and the old forced four-screen-pixel Weather blocks were oversized beside the tactical art.

P3 is therefore implemented as a bounded System 28 presentation refactor, not as a Weather-simulation rewrite.

Current contract:

- physical Weather/WHEN/wetness/lighting/hearing consequences are unchanged;
- one `WeatherAtmosphereSurface` CanvasItem shader owns cosmetic rain/fog/debris/lightning output;
- continuous rain/fog animation uses shader `TIME` and requires **zero CPU canvas redraw loop**;
- base Weather art scale is **2 screen pixels**;
- the old <=180 rain-candidate / <=36 fog-rectangle CPU draw loops are removed;
- rain no longer performs a screen->world conversion and shelter query per candidate;
- shelter is uploaded as one nearest-neighbor texture, one texel per render-window cell;
- camera movement updates only shelter-mapping uniforms and causes **0 Weather redraws** and **0 shelter-texture rebuilds**;
- CPU housekeeping falls to 10 Hz and owns only <=3 debris records, lightning lifetime and a cheap shelter revision poll;
- clear/ordinary overcast hides the GPU surface entirely when no debris/lightning is active.

Focused P3 regression proves:

- `WEATHER_CPU_CONTINUOUS_REDRAWS=0`;
- `WEATHER_OVERLAY_CAMERA_REDRAWS=0` after forty camera changes;
- `WEATHER_OVERLAY_MASK_REBUILDS=1` for the fixture's initial mask;
- System 27/26/23 protected behavior and canonical startup remain green.

The exact canonical P3 executable is established by the final `main` verification carrying this implementation.

## Protected contracts

Preserve WHERE/WHAT identity, 00F rollback/materialization, loot/search/TAKE/STORE, System 23 knowledge, System 27 physical output/shadows/portals, System 28 physical Weather and consequences, System 29 reach/highlights, WHEN, mobile input and renderer layering. No save migration is required; performance revisions/metrics and the shelter texture are derived runtime/presentation state.

## Verification

Permanent performance context: `verify/performance-architecture`.

P0/P1/P2 focused contract proves a 128-object batch emits one completed summary, OBJECT revision changes without terrain/STRUCTURE revision changes, ACTOR/OBJECT churn causes zero lighting-geometry/sample and shelter-cache rebuilds, while a real STRUCTURE change still causes exactly one rebuild after query.

P3 presentation proof lives primarily in `verify/system28-weather`, with `verify/performance-architecture` remaining a protected exact-head context on the final main executable.

## Deferred measured follow-up

**P5 predictive/amortized streaming remains deferred and is not automatically authorized.** Implement it only if post-P3 phone/Safari measurements still identify streaming/action execution as a meaningful stall source.

Phase 1B Item Freshness / Spoilage remains frozen until the human phone/Safari pass confirms this P3 build no longer has unacceptable movement/weather stalls. If Weather stays visually continuous but movement still starves render frames, the next measured target is the synchronous action/streaming path rather than further Weather complexity.
