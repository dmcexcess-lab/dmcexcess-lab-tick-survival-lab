# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — STATS / MOODLET HUD VISIBILITY REPAIR CLOSED — 2026-09-10

The player reported that after the terrain-streaming performance improvement, the stats/status information and moodlets were not appearing in the live game. The final clarification was specifically **not** that System 34 said unavailable or that the state was logically broken; the visible presentation was missing/obscured.

Starting head for this operation: `bef76f776f0d5c4f84e4e1131b2d5362eba8f2dd`

Successful functional/owning verifier head: `2edc622852eea7990d750128d93b7b02717c7a8e`

Documentation head immediately before this final context write: `2f8d3ea8360b4b69fc90f991110711f02ec1d183`

Closure ledger: `CHANGELOG_STATS_MOODLET_VISIBILITY.md`

The commit containing this file is the final repository write for this operation. After it lands, verification is read-only only.

## Diagnosis

Production-scene verification established that the underlying gameplay data was healthy:

- System 34 condition state was configured and queryable;
- the status summary returned valid condition values;
- the STATS modal projection contained live health, condition, modifiers, skills, and moodlet text;
- an authoritative condition change into hunger pressure produced a real hunger moodlet descriptor/chip.

The persistent `CanonicalStatusHud` presentation contract was too weak. It remained on CanvasLayer 21 while newer ordinary/transient presentation surfaces existed above it. Its moodlet row also began immediately below the old 100-pixel status panel background, so colored moodlet text could float directly over world art.

A diagnostic attempt that treated the headless test runner viewport as browser geometry was explicitly discarded: headless Godot reports a synthetic 64x64 root viewport for this script path, while the canonical production design surface is 640x844. The final verifier validates the actual UI design bounds and draw-order contract instead.

Historical standalone `ConditionPlayerControls`, `ForagePlayerControls`, `WeatherDevControls`, and `UtilityDevControls` source files were inspected during diagnosis, but they are not instantiated by current `gameplay.tscn`; they were not modified and are not claimed as the cause.

## Completed implementation

`game/scripts/ui/CanonicalStatusHud.gd` now:

- owns persistent HUD layer 36;
- draws above the transient `WorldResolutionIndicator` layer 35;
- remains below interactive/modal presentation such as `WorldInteractionPanel` and `PlayerShell`;
- expands the status panel from 100 to 122 pixels tall so the moodlet row is fully backed by the same HUD surface;
- explicitly places status labels and the moodlet row above the panel background with local z-index 1;
- gives status text and colored moodlet chips dark outlines for contrast against world art.

The status block remains directly below the top STATS / INVENTORY / MENU/CRAFT header as previously approved. No condition, health, carry, skill, moodlet, world, rendering truth, or WHEN/TickKernel semantics were changed.

## Focused verification

Fresh prompt-owned verifier pair:

- `game/scripts/ci/PromptStatsMoodletsSmoke.gd`
- `.github/workflows/prompt-stats-moodlets.yml`

The final verifier boots the real production `main.tscn -> NEW GAME -> gameplay.tscn` path and checks only this repaired presentation seam:

- System 34 status is configured and valid;
- HUD CanvasLayer is visible and exactly layer 36;
- HUD is above transient resolution presentation and below PlayerShell;
- all five persistent status lines have drawable size and occupy the canonical 640x844 design surface;
- the expanded background fully contains the moodlet row;
- status labels/moodlets draw above the background;
- an authoritative hunger-pressure change produces an active hunger moodlet and visible moodlet-chip child;
- moodlet chips have contrast outlines;
- STATS modal opens and contains live health, condition, and moodlet text.

Functional-head focused verifier:

- run `34554733414`: **SUCCESS** on `2edc622852eea7990d750128d93b7b02717c7a8e`.

Functional-head Pages:

- run `34554733439`: build **SUCCESS**, deploy **SUCCESS**.

Documentation-head verification on `2f8d3ea8360b4b69fc90f991110711f02ec1d183`:

- focused verifier run `34554849685`: **SUCCESS**;
- Pages run `34554849744`: build **SUCCESS**, deploy **SUCCESS**.

After this final context commit, verify its exact-head focused verifier and Pages runs read-only. Do not make another repository write in this operation.

## Previous verifier cleanup

The preceding terrain optimization prompt-owned verifier pair was retired at the start of this operation:

- `game/scripts/ci/PromptTerrainBulkWriteOptimizationSmoke.gd`
- `.github/workflows/prompt-terrain-bulk-write-optimization.yml`

At the start of the next code operation, retire the current stats/moodlet verifier pair listed above before creating a fresh prompt-local verifier/workflow.

## Protected behavior

Preserve:

- one authoritative WHEN/TickKernel clock and decision-pause semantics;
- production `PlayerActionController` one-authoritative-batch-per-rendered-frame behavior;
- the terrain bulk-write/coalescing optimization and its measured streaming-seam improvement;
- System 34 condition state/query semantics and analytic time drift;
- STATS / INVENTORY / CRAFT / MENU modal ownership and interaction blocking;
- current world generation, utilities, weather, perception, interaction, vehicle, combat, population, and rendering ownership boundaries;
- the persistent status location directly below the top player menu row.

Do not resurrect historical standalone DEV/control panels as production UI without an explicit target.

## Known follow-up targets from player direction

These remain separate operations unless explicitly promoted:

- ordinary same-region action latency / nearby-infected performance profiling and optimization;
- more realistic vehicle placement tied to roads/residences/business/parking context;
- higher believable road/building density and more alternate routes/loops;
- removal of the player-facing `ZOMBIES`/`ZOMBIES NEARBY` status bar/indicator while preserving underlying infected systems;
- gameplay-density polish: interaction affordance clarity, less dead travel, stronger early survival decisions, clearer action-time costs, distinct building usefulness, and stronger vehicle progression.

## NEXT OPERATION — wait for explicit bounded target

Do not begin another code operation automatically.

At the start of the next approved code prompt, delete:

- `game/scripts/ci/PromptStatsMoodletsSmoke.gd`
- `.github/workflows/prompt-stats-moodlets.yml`

Then create a fresh prompt-local verifier/workflow limited to that next target.
