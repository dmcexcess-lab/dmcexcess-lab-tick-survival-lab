# Tick Survival Lab — Latest Changes

This compact ledger records the most recent completed work. `CHANGELOG.md` remains the historical archive.

## Compact Island / Global Settlement Cleanup — 2026-08-28

Verified executable: `918f1dbd7b033fa179522a112b1507d9a2c63890`

- Closed the remaining compact-island / legacy-map seam cleanup without weakening System-00D or System-20 validators.
- Recovered the exact alternate-seed failure from CI: `island_base_site_overlap:area.smalltown.center.001`.
- Root cause was in `GlobalSettlementPlanner`: legal geography candidates were screened with a 160-cell center-distance heuristic even though local sites are 256x256 rectangles. Grid-snapped centers could therefore pass the heuristic while their real site rectangles overlapped.
- Replaced that heuristic with actual positive-area `Rect2i` overlap rejection using the authoritative local-site size.
- Edge-touch remains legal; true overlap advances to the next deterministic geography/hydrology-valid candidate.
- Preserved protected `temperate.rural.region` v6 behavior, island v3 seed-dependent placement, hydrology clearance, local morphology ownership, streaming architecture, WHAT/WHEN and performance boundaries.
- The formerly failing `Legacy Crossroads Is Not Embedded In Island` System-00D step now passes.
- Exact-head verification also passed canonical startup, local-area generation, large-area critique, streaming materialization, canonical player shell, System-32 Crafting, performance architecture, build and Pages deployment.
- After all workflow-run cascades settled, the exact executable head reported **zero failed runs and zero in-progress runs**.

Implementation commit: `918f1dbd7b033fa179522a112b1507d9a2c63890` (`Prevent global settlement site overlap`).

## Project Status Reconciliation — 2026-08-28

- Rewrote `README_CONTEXT.md` around current canonical truth instead of stale historical active-work text.
- Marked Roadmap Phase 2 / System 32 Crafting as **COMPLETE + CI VERIFIED** using its verified executable `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.
- Recorded the compact-island/world-seam cleanup as complete on verified executable `918f1dbd7b033fa179522a112b1507d9a2c63890`.
- Advanced the canonical roadmap to **Phase 3 — Power and Water: DESCRIBE**.
- No Phase-3 runtime implementation was added during this cleanup.
