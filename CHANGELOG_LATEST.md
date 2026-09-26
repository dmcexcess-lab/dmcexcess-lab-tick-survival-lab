# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Phase 4 — powered stove cooking route — 2026-09-26

Functional production head before documentation: `40b6dab3726759576f078c8ef6b7a5aa3093ad5c`.

- Closed the first incomplete Phase 4 player-facing link: generated stove -> existing contextual crafting offer/panel -> real carried canned-soup input + cooking-pot tool -> WHEN crafting action -> heated soup returned to survivor inventory.
- Added `PoweredCraftingWorkstationAdapter`, a small composition bridge between the existing System 32 workstation-availability seam and System 33 authoritative live power truth. It creates no duplicate appliance, crafting or utility state.
- A stove with failed branch power now blocks cooking as `workstation_unavailable_now`; restoring existing power service makes the same recipe available again.
- Heated soup immediately exposes the already-established contextual EAT route. No generic survival/crafting action strip was added.
- Crafting consumes the canned-soup input exactly once, preserves the cooking pot, and creates exactly one cooked output through the existing WHAT/inventory mutation path.
- Save -> destroy gameplay scene -> reopen -> Continue preserves the cooked output/tool and does not resurrect the consumed input.
- Fresh prompt-local verifier/workflow: `game/scripts/ci/Phase4CookingRouteSmoke.gd` + `.github/workflows/phase4-cooking-route.yml`; the previous Phase 3 verifier/workflow were deleted before production edits.
- Focused route run `36273690260`: **SUCCESS** with `PHASE4_COOKING_ROUTE_OK`.
- Protected workflow covers crafting, physical power network, survivor condition, live world interaction and canonical production boot before the cooking vertical verifier.

## Phase 3 — durable save / leave / reopen / Continue — 2026-09-26

- Added conventional versioned `user://` durable-session storage with checksum verification, validated writes, primary/backup recovery and truthful storage capability reporting.
- Continue reconstructs the same procedural seed then restores existing authoritative WHAT/WHEN/streaming/mechanic snapshots in place; no duplicate persistence state model was introduced.
- New Game, Continue, explicit Save/Save & Menu and safe decision/region/background checkpoints are production-wired.
- Pending committed actions survive Continue without cancellation or duplicate consequences.
- Protected/focused run `36271614098`: **SUCCESS**; exact-head Pages run `36271614056`: **SUCCESS**.
