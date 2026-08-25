# Performance Architecture Gate Changelog

## P0/P1/P2 — 2026-08-24

- Implemented the approved non-numbered performance gate before Phase 1B under the rule **“A world mutation may update truth many times; expensive consumers wake only for the domains and completed batches they actually depend on.”**
- Added cache-oriented WHAT terrain and per-placement-channel revisions while preserving the global authoritative world revision and existing low-level change contract.
- Added explicit `WorldChangeBatch` summaries for bulk work. System 00F now brackets its existing rollback-safe multi-source materialization transaction so authoritative truth still changes immediately while expensive consumers can wake once after completion.
- Corrected placement-change channel metadata so domain revisions genuinely advance for STRUCTURE/OBJECT/ACTOR changes.
- Removed the global-WHAT-revision coupling from System 27 geometry/sample invalidation. Static lighting geometry now keys to terrain + STRUCTURE placement; ordinary player movement and loot/object churn no longer rebuild the 80×96 field.
- Keyed Weather `SkyExposureQuery` to terrain + STRUCTURE revisions, so walking or ordinary loot changes no longer rebuild the roof/exterior precipitation mask.
- Coalesced explicit streaming-batch wakeups in System 23 perception, System 29 interaction affordances and System 24 searchable-container offer publication while preserving immediate behavior for ordinary non-batch actions.
- Updated physical-light presentation to redraw for visible terrain/STRUCTURE or real light-input changes rather than every WHAT change.
- Added low-overhead `PerformanceTelemetry` plus a compact 2 Hz DEV performance panel covering streaming, lighting simulation/presentation, perception, interaction, Weather drawing and sky-exposure work.
- Added permanent `verify/performance-architecture` coverage. The deterministic fixture proves **128 OBJECTs / 256 low-level changes -> one completed batch**, ACTOR/OBJECT churn -> **zero** lighting geometry/sample and shelter-mask rebuilds, and a real STRUCTURE mutation -> exactly one relevant rebuild.
- GPU Weather and predictive/amortized streaming were deliberately deferred until real post-P2 measurement justifies them.
- First fully green executable head: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.
- On that exact SHA, **42/42 associated workflow runs completed successfully** and all **15 required exact-head contexts** were green, including `verify/performance-architecture` and `verify/pages-deploy`.
- CI implementation is closed. **Human iPhone/Safari movement/streaming acceptance remains the final performance gate before Phase 1B implementation.**
