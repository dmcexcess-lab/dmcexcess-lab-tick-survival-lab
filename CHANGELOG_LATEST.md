# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Phase 4 — contextual deconstruction route — 2026-09-26

Verified functional head before documentation: `8749642a8ee946ccec4c131bd79c465c34a794b8`.

- Closed the next Phase 4 player-facing link using the production route already present in the established world-interaction owners rather than inventing another subsystem.
- Generated dining chairs expose contextual DECONSTRUCT through the same world-cell interaction panel used by other object actions.
- The route requires the existing hammer/crowbar tool semantics and Mechanical skill, then resolves as a real cancelable WHEN action.
- Pre-commit interruption cancels cleanly: the chair remains and no salvage appears.
- Completion removes the chair through authoritative WHAT, preserves the tool and creates exactly one existing `item.material.wood_plank` through existing inventory/world truth.
- Save -> destroy gameplay scene -> reopen -> Continue keeps the chair removed and the same salvage identity present exactly once.
- Fresh prompt-local verifier/workflow: `game/scripts/ci/Phase4DeconstructionRouteSmoke.gd` + `.github/workflows/phase4-deconstruction-route.yml`; the previous cooking verifier/workflow were deleted before this slice.
- Focused/protected run `36275247010`: **SUCCESS**, marker `PHASE4_DECONSTRUCTION_ROUTE_OK target=dining_chair contextual=true timed=true interrupted_safe=true removed=true salvage=wood_plank salvage_once=true tool_preserved=true continue=true`.
- Protected regressions: world interaction, crafting and canonical production boot all passed before the vertical route.

## Phase 4 — powered stove cooking route — 2026-09-26

Functional production head before documentation: `40b6dab3726759576f078c8ef6b7a5aa3093ad5c`.

- Closed the first incomplete Phase 4 player-facing link: generated stove -> existing contextual crafting offer/panel -> real carried canned-soup input + cooking-pot tool -> WHEN crafting action -> heated soup returned to survivor inventory.
- Added `PoweredCraftingWorkstationAdapter`, a small composition bridge between the existing System 32 workstation-availability seam and System 33 authoritative live power truth. It creates no duplicate appliance, crafting or utility state.
- A stove with failed branch power now blocks cooking as `workstation_unavailable_now`; restoring existing power service makes the same recipe available again.
- Heated soup immediately exposes the already-established contextual EAT route. No generic survival/crafting action strip was added.
- Crafting consumes the canned-soup input exactly once, preserves the cooking pot, and creates exactly one cooked output through the existing WHAT/inventory mutation path.
- Save -> destroy gameplay scene -> reopen -> Continue preserves the cooked output/tool and does not resurrect the consumed input.
- Focused route run `36273690260`: **SUCCESS** with `PHASE4_COOKING_ROUTE_OK`.

## Phase 3 — durable save / leave / reopen / Continue — 2026-09-26

- Added conventional versioned `user://` durable-session storage with checksum verification, validated writes, primary/backup recovery and truthful storage capability reporting.
- Continue reconstructs the same procedural seed then restores existing authoritative WHAT/WHEN/streaming/mechanic snapshots in place; no duplicate persistence state model was introduced.
- New Game, Continue, explicit Save/Save & Menu and safe decision/region/background checkpoints are production-wired.
- Pending committed actions survive Continue without cancellation or duplicate consequences.
- Protected/focused run `36271614098`: **SUCCESS**; exact-head Pages run `36271614056`: **SUCCESS**.
