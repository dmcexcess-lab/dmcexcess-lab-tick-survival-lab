# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Phase 4 — existing-window fortification route — 2026-09-26

Verified functional head before documentation: `e79de8f416649bea627987e6f6aade0330968739`.

- Closed the existing-building fortification slice through the established window/world-interaction owners rather than creating a construction system.
- Fixed the one player-visible missing link: after the first board, contextual interaction now continues to offer BOARD until `WorldInteractableState.MAX_BOARDS` (3) instead of trapping the opening at one layer.
- Each BOARD is the existing timed WHEN action requiring the existing hammer, one wood plank, one nails box and Mechanical semantics; each material pair is consumed exactly once while the hammer is preserved.
- Three authoritative board layers materially change the same opening-pressure path used by infected behavior: verified impact damage falls from 55 unboarded to 40 at three layers, increasing breach resistance rather than merely drawing boards.
- Existing `WorldInteractionStateRenderer` remains presentation-only and reads the authoritative board/damage state.
- Save -> destroy gameplay scene -> reopen -> Continue preserves all three board layers, accumulated opening damage and tool state while consumed materials remain consumed.
- Fresh prompt-local verifier/workflow: `game/scripts/ci/Phase4FortificationRouteSmoke.gd` + `.github/workflows/phase4-fortification-route.yml`; the deconstruction verifier/workflow were deleted before production edits.
- Focused/protected run `36276349197`: **SUCCESS**, marker `PHASE4_FORTIFICATION_ROUTE_OK contextual=true timed=true boards=3 materials_once=true tool_preserved=true baseline_damage=55 fortified_damage=40 infected_pressure_owner=true continue=true`.
- Protected regressions: world interaction and canonical production boot passed before the vertical route.

## Phase 4 — contextual deconstruction route — 2026-09-26

Verified functional head before documentation: `8749642a8ee946ccec4c131bd79c465c34a794b8`.

- Generated dining chairs expose contextual DECONSTRUCT through the established world-cell interaction panel.
- Existing hammer/crowbar + Mechanical semantics drive a real cancelable WHEN action.
- Pre-commit cancellation leaves the chair intact and creates no salvage; completion removes it through WHAT, preserves the tool and creates exactly one existing wood plank.
- Continue keeps the chair removed and salvage identity present exactly once.
- Focused/protected run `36275247010`: **SUCCESS**.

## Phase 4 — powered stove cooking route — 2026-09-26

Functional production head before documentation: `40b6dab3726759576f078c8ef6b7a5aa3093ad5c`.

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
