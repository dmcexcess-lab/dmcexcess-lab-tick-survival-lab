# Tick Survival Lab — Compatibility Context Pointer

Status: **legacy bootstrap pointer; not project working memory**

## Load order

1. `README_SOPS.md` — repository execution procedure;
2. `AI_OPERATING_MODEL.md` — reasoning/decision contract;
3. `PROJECT_NORTH_STAR.md` — game identity;
4. `ARCHITECTURE.md` — settled ownership/invariants;
5. `ROADMAP.md` — current rewrite order;
6. `CURRENT.md` — exact active state and NEXT.

Do not reconstruct current state from this file or old commits.

## Current pointer

`CURRENT.md` is canonical working memory.

As of 2026-09-27 the project direction deliberately changed from the experimental tick/WHERE/WHAT/WHEN execution model to a conventional turn-based survival game while preserving the existing procedural persistent world and gameplay content.

Slices 1-2 establish the canonical simple movement spine and plain movement state/query path: one player action, direct authoritative placement, bounded local infected actions, immediate return of control, with no TickKernel/WHEN/MovementActionService or generalized SpatialQueryService/WorldMutationService execution underneath canonical movement.

The old execution architecture remains only as migration debt for bootstrap and unmigrated gameplay routes. It is no longer protected project identity. The next rewrite slice reconnects combat to the simple turn model.

The previous verbose contents remain available in Git history and must not be copied back into active context.