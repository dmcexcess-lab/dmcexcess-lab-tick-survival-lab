# Tick Survival Lab — Latest Changes

This compact ledger records the most recent work. `CHANGELOG.md` remains the historical archive.

## Black-Screen Visibility Recovery — 2026-08-29

Validated executable: `1f65bff312853a44858201b57d9df2e26ee64f80`

- Human browser play reported a completely black game after `6e1298da36e9216139f404696275280fcb944033`, despite that executable passing automated startup and integration checks.
- Isolated the regression to the visibility optimization stack introduced in that follow-up rather than rolling back the accepted input/lighting responsiveness work wholesale.
- Restored the last human-good full 80x96 physical-light presentation path and prior stateless System-23 LOS query.
- Preserved WHEN decision-pause input locking, the one-due-tick-batch-per-render-frame action pump, immediate next-pause acceptance, coalesced settled light/perception work, flashlight facing updates and the runtime naming cleanup.
- Retracted the camera-cropped lighting presentation and revision-cached LOS optimization from canonical runtime until they can be reintroduced without risking visual correctness.
- Strengthened `PlayerInputResponsivenessSmoke.gd` so canonical startup now requires a usable visible field plus initialized multiply/glow lighting textures with nonzero luminance, and proves those properties survive settled player actions.
- Exact-head validation completed with 46 successful workflows, zero failing workflows, and a successful Pages build/deploy.
- Human browser play remains the final acceptance gate for the visual recovery and the remaining first-actions startup hitch.

## Decision-Pause Input + Startup Performance Follow-Up — 2026-08-29

- Replaced the fixed 120 ms input drain heuristic with WHEN's real decision-pause gate: one accepted action, all gameplay input locked through resolution, immediate acceptance at the next pause.
- Coalesced ambient-light, moving flashlight and observer invalidations to one settled perception/light update per player action.
- Bounded physical-light presentation to the actual camera viewport plus a stable cache margin instead of rebuilding the full 80x96 render window.
- Cached System-23's bounded LOS opacity/structure field behind terrain, STRUCTURE and door revisions; repeated focused FOV runs improved from ~11.84 ms to ~2.5-2.9 ms locally.
- Removed dead Weather camera-local compatibility code.
- Renamed the now-canonical runtime roots/controllers from demo/bridge terminology while retaining focused DEV fixtures and the honestly temporary lighting-source adapter.
- Extended permanent responsiveness coverage for decision-pause locking, immediate next-pause input, coalesced work and camera-bounded lighting.

**Acceptance note:** the camera-cropped lighting and cached-LOS portion of this follow-up was later retracted by `1f65bff...` after human play reported a black screen. The decision-pause/input, coalescing, flashlight and naming improvements remain canonical.

## Player Input / Lighting Responsiveness Repair — 2026-08-29

- Removed the playable runtime's blocking `run_until_stop()` call from keyboard/touch callbacks.
- Player actions now advance through at most one authoritative due-tick batch per rendered frame.
- Busy controls and a short drain window discard stale buffered input instead of replaying it past the intended target.
- Fixed the DEV flashlight presentation so facing-only turns update the beam without requiring a later forward move.
- Removed unrelated streaming/world mutation fan-out from the DEV flashlight source adapter.
- Added same-revision lighting-map upload suppression.
- Added permanent `PlayerInputResponsivenessSmoke.gd` coverage for yielding and input-backlog rejection.
- No movement timing, collision, persistence, world identity, crafting or save schema changed.

Human browser acceptance remains required for the reported spawn-step performance behavior.

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

- This commit replaced the planner's historical 160-cell center-distance screening with exact 256x256 rectangle-overlap rejection.
- Automated exact-head checks, including System 00D and Pages, passed on that commit.
- Human play immediately found the deployed game severely broken.
- Therefore this commit is **not an accepted cleanup head** and must not be cited as proof that the compact-island/world-seam cleanup is complete.

## Project Status

- Roadmap Phase 1 remains complete.
- Roadmap Phase 2 / System 32 Crafting remains **COMPLETE + CI VERIFIED** on executable `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.
- Compact-island/world-seam cleanup is **REOPENED**.
- Phase 3 Power and Water remains next in roadmap order, but its DESCRIBE gate should follow resolution/acceptance of the reopened cleanup rather than silently bypassing it.
