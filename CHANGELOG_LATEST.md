# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Mobile/Safari new-game bootstrap repair — 2026-09-26

Functional repair head before documentation: `b4f2a317883be7759d7e8ab69ad11eb3c163ee00`.

- Investigated the reported real iPhone/Safari failure: startup menu loads, NEW GAME begins world generation, then WebKit/Godot restarts before the playable map appears.
- Found a concrete bootstrap memory defect in `GeneratedIslandCritiqueFixture`: every candidate seed fully materialized the initial 3x3 streaming neighborhood into a disposable probe world, then immediately materialized the same neighborhood again into authoritative WHAT.
- Removed the disposable full-world streaming probe. Seed selection still validates global generation, central-area generation and a valid player start; the selected world is then materialized exactly once into authoritative WHAT.
- No procedural-world dimensions, streaming radius, generated content, gameplay semantics or persistence ownership were reduced to obtain the fix.
- Fresh prompt-local verifier/workflow: `game/scripts/ci/MobileNewGameBootstrapSmoke.gd` + `.github/workflows/mobile-new-game-bootstrap.yml`; the previous fortification verifier/workflow were deleted before production edits.
- Focused production run `36281756339`: **SUCCESS**, marker `MOBILE_NEW_GAME_BOOTSTRAP_OK production_boot=true single_initial_materialization=true player=true streaming=true`.
- This removes the identified doubled initial-materialization peak; real iPhone/Safari acceptance remains the decisive confirmation for the originally reported WebKit restart.

## Phase 4 — existing-window fortification route — 2026-09-26

Verified functional head before documentation: `e79de8f416649bea627987e6f6aade0330968739`.

- Closed the existing-building fortification slice through the established window/world-interaction owners rather than creating a construction system.
- Fixed the one player-visible missing link: after the first board, contextual interaction now continues to offer BOARD until `WorldInteractableState.MAX_BOARDS` (3) instead of trapping the opening at one layer.
- Each BOARD is the existing timed WHEN action requiring the existing hammer, one wood plank, one nails box and Mechanical semantics; each material pair is consumed exactly once while the hammer is preserved.
- Three authoritative board layers materially change the same opening-pressure path used by infected behavior: verified impact damage falls from 55 unboarded to 40 at three layers, increasing breach resistance rather than merely drawing boards.
- Existing `WorldInteractionStateRenderer` remains presentation-only and reads the authoritative board/damage state.
- Save -> destroy gameplay scene -> reopen -> Continue preserves all three board layers, accumulated opening damage and tool state while consumed materials remain consumed.
- Focused/protected run `36276349197`: **SUCCESS**.

## Phase 4 — contextual deconstruction route — 2026-09-26

- Generated dining chairs expose contextual DECONSTRUCT through the established world-cell interaction panel.
- Existing hammer/crowbar + Mechanical semantics drive a real cancelable WHEN action.
- Pre-commit cancellation leaves the chair intact and creates no salvage; completion removes it through WHAT, preserves the tool and creates exactly one existing wood plank.
- Continue keeps the chair removed and salvage identity present exactly once.
- Focused/protected run `36275247010`: **SUCCESS**.

## Phase 4 — powered stove cooking route — 2026-09-26

- Generated stove -> contextual crafting -> real carried input/tool -> WHEN crafting -> heated soup.
- System 32 workstation availability consumes System 33 live power truth through the small production adapter; no duplicate appliance/crafting/utility state.
- Power failure blocks cooking; restoration re-enables it; heated soup enters the existing EAT route and persists through Continue without resurrecting consumed input.
- Focused route run `36273690260`: **SUCCESS**.

## Phase 3 — durable save / leave / reopen / Continue — 2026-09-26

- Added conventional versioned `user://` durable-session storage with checksum verification, validated writes, primary/backup recovery and truthful storage capability reporting.
- Continue reconstructs the same procedural seed then restores existing authoritative WHAT/WHEN/streaming/mechanic snapshots in place; no duplicate persistence state model was introduced.
- New Game, Continue, explicit Save/Save & Menu and safe decision/region/background checkpoints are production-wired.
- Pending committed actions survive Continue without cancellation or duplicate consequences.
- Protected/focused run `36271614098`: **SUCCESS**; exact-head Pages run `36271614056`: **SUCCESS**.
