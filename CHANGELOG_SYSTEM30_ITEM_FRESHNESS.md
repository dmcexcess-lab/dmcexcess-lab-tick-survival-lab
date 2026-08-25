# System 30 Item Freshness / Spoilage — Implementation Changelog

Date: 2026-08-25

Status: **COMPLETE — IMPLEMENTED + CI VERIFIED**

First fully green executable head: `39716f27b7f91b7007645ceae02dedc47601bf87`

Permanent context: `verify/system30-item-freshness`

## Candidate 001

- Added explicit semantic freshness profiles and sparse typed per-instance freshness state.
- Added deterministic bounded virgin-stock initial age.
- Added analytic FRESH / AGING / STALE / SPOILED derivation from authoritative WHEN time through cumulative exposure contexts.
- Added ambient Candidate-001 exposure provider and a neutral future environment reanchor seam.
- Added no per-item timer, `_process`, `_physics_process`, scheduled spoilage event, or world-time item scan.
- Added Candidate-001 perishables: apple, bread loaf, milk carton, raw chicken, deli meat and fresh salad.
- Shelf-stable items remain outside freshness state unless explicitly profiled later.
- Virgin world perishables use logical scenario origin tick 0 so first technical materialization on a later day never creates magically fresh food.
- Extended System-24 source initialization with an optional freshness mutation dependency.
- Perishable enrollment is inside System 24's existing initialization transaction.
- Rollback now restores WHAT, System-11 containment, System-24 loot provenance/current state and System-30 freshness together.
- Added an injected rollback regression proving no orphan freshness record survives a post-create containment failure.
- Production System-24 loot probabilities, search timing, TAKE/STORE timing and stable item IDs are unchanged.
- Existing searchable-container and actor-inventory inspection readers now expose coarse freshness labels read-only.
- Wired System 30 into the canonical playable composition using the same `WorldTimeProfile`/TickKernel authority as System 25.
- Refrigerators remain ordinary ambient containers until Phase 3 supplies real power/appliance truth.
- Eating/drinking/nutrition/sickness remain deferred to Phase 4.
- Strengthened `.github/workflows/item-freshness.yml` to parse/import the project, run System-30 smoke, System-24 regression, System-25 regression, canonical startup and structural no-loop/no-cross-domain checks.
- Exact executable head `39716f27b7f91b7007645ceae02dedc47601bf87` completed all **16 required exact-head contexts** successfully, including `verify/system30-item-freshness` and `verify/pages-deploy`.

## Roadmap closure

Roadmap Phase **1B Item freshness / spoilage** is complete.

Next bounded target: **Phase 1C Semantic inventory/menu icons — DESCRIBE only**. Completion of System 30 does not pre-authorize Phase 1C implementation.
