# Tick Survival Lab — Performance Architecture Gate

Status: **APPROVED — P0/P1/P2 first executable pass**

Approved: **2026-08-24**

Roadmap role: **non-numbered engineering gate before Phase 1B**.

Core rule:

> **A world mutation may update truth many times; expensive consumers wake only for the domains and completed batches they actually depend on.**

The game is discrete-time, low-resolution and phone/Safari-first. Ordinary walking must not rebuild unrelated world geometry or turn a technical streaming boundary into a synchronous fan-out storm.

## P0 — runtime telemetry

A neutral `PerformanceTelemetry` collector records low-overhead last/max timings and work counts for streaming, lighting simulation/presentation, perception, interaction, Weather drawing and sky-exposure rebuilds. The canonical DEV view exposes a compact 2 Hz panel. Telemetry is observation only and never changes simulation/rendering decisions.

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

## Protected contracts

Preserve WHERE/WHAT identity, 00F rollback/materialization, loot/search/TAKE/STORE, System 23 knowledge, System 27 physical output/shadows/portals, System 28 physical Weather/current appearance, System 29 reach/highlights, WHEN, mobile input and renderer layering. No save migration is required; these revisions/metrics are derived runtime state.

## Verification

Permanent context: `verify/performance-architecture`.

Focused contract proves a 128-object batch emits one completed summary, OBJECT revision changes without terrain/STRUCTURE revision changes, ACTOR/OBJECT churn causes zero lighting-geometry/sample and shelter-mask rebuilds, while a real STRUCTURE change still causes exactly one rebuild after query. Existing performance, lighting, streaming, interaction and startup regressions remain protected.

## Deferred measured follow-up

P3 GPU Weather presentation and P5 predictive/amortized streaming are not automatically authorized. Measure the post-P2 playable build first and design either only if it remains a meaningful Safari bottleneck.

**Phase 1B Item Freshness / Spoilage remains frozen until this gate has a green exact-head executable and human phone/Safari testing confirms ordinary movement no longer has unacceptable stalls.**