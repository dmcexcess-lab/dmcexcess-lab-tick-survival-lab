# Tick Survival Lab — Latest Changes

This compact ledger records the most recent work. `CHANGELOG.md` remains the historical archive.

## Settlement-Planner Regression Rollback — 2026-08-28

Restored runtime executable: `f6a06add3dfd212c0c29b343d24a8f7d28a89bca`

- Reverted the settlement-overlap planner change from `918f1dbd7b033fa179522a112b1507d9a2c63890` after the deployed game was reported completely broken in human play.
- Restored `GlobalSettlementPlanner.gd` exactly to the pre-regression implementation from `ba706f18017d4d72b950f18d3e988ce75592f0a6`.
- The rollback Pages build/deploy completed successfully, so the live game is again built from the pre-regression planner.
- The rollback re-exposes the previously known System-00D seam failure in `Legacy Crossroads Is Not Embedded In Island`; that is intentional and preferable to shipping a user-visible gameplay regression.
- The old seam remains associated with the alternate-seed `island_base_site_overlap:area.smalltown.center.001` case.
- The failed attempt proved an important verification gap: exact-head CI can remain green while a generator change still causes unacceptable whole-world gameplay/layout behavior. Future repair must be proven in a focused planner fixture and then human-played before the cleanup is closed.
- No Crafting, item, UI, streaming, WHAT/WHEN, or Phase-3 runtime code was reverted.

Rollback commit: `f6a06add3dfd212c0c29b343d24a8f7d28a89bca` (`Revert settlement overlap planner regression`).

## Retracted Compact-Island Fix — 2026-08-28

Attempted executable: `918f1dbd7b033fa179522a112b1507d9a2c63890`

- This commit replaced the planner's historical 160-cell center-distance screening with exact 256x256 site-rectangle overlap rejection.
- Automated exact-head checks, including System 00D and Pages, passed on that commit.
- Human play immediately found the deployed game severely broken.
- Therefore this commit is **not an accepted cleanup head** and must not be cited as proof that the compact-island/world-seam cleanup is complete.

## Project Status

- Roadmap Phase 1 remains complete.
- Roadmap Phase 2 / System 32 Crafting remains **COMPLETE + CI VERIFIED** on executable `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.
- Compact-island/world-seam cleanup is **REOPENED**.
- Phase 3 Power and Water remains next in roadmap order, but its DESCRIBE gate should follow resolution/acceptance of the reopened cleanup rather than silently bypassing it.
