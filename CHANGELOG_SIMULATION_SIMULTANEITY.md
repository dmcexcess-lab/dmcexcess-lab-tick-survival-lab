# Tick Survival Lab — Simulation Simultaneity Closure

Date: 2026-09-09  
Starting main: `1fee3f3c320fdc15e32f0a341dbb1f0678ef4da5`  
Owning functional head: `2734666fe75b747b097dfead5c30ad5e6db6691b`

## Scope

This operation was limited to simulation simultaneity for actor movement. It did not implement or modify visual interpolation, animation smoothing, camera behavior, renderer timing, or presentation ownership.

## What changed

- Same-WHEN successful movement phases now collect movement intents and resolve them at one timestamp consequence boundary instead of mutating actor occupancy one actor at a time.
- The existing `TickKernel` remains the only scheduler. Movement schedules one same-tick external flush through WHEN; no second actor scheduler or frame-time simulation loop was introduced.
- `ACTION_COMPLETE` entries are ordered after non-completion work due at the same tick. This lets mechanic-owned same-WHEN consequence batching finish before the corresponding actions become terminal.
- Movement candidates are resolved deterministically by stable actor ID, then action serial and stride index.
- If multiple otherwise-valid same-WHEN moves claim overlapping clear destination cells, the lower stable actor ID wins and later claimants fail deterministically as blocked.
- Existing conservative occupancy semantics are preserved: a cell occupied in the pre-batch physical snapshot remains blocked even when that occupant also intends to leave at the same timestamp. This pass intentionally does not add swaps, move chains, phasing, or opportunistic entry into vacated cells.
- Winning placement records are installed as one atomic WHAT occupancy update before placement-change or movement-success notifications are emitted. Observers therefore see the complete final successful movement batch rather than an actor-by-actor intermediate state.
- Run conflicts preserve authoritative run-impact behavior and identify the deterministic winning actor as the blocker for the losing run intent.
- `PassageAwareMovementActionService` still owns passage resolution, but actor placement after a resolved passage now returns through the base same-WHEN movement batch instead of bypassing it with a direct placement mutation.

## Production files changed

From the starting main through the owning functional head, only these production/test/workflow files changed:

- `game/scripts/foundation/time/ScheduledEvent.gd`
- `game/scripts/foundation/world/WorldMutationService.gd`
- `game/scripts/simulation/movement/MovementActionService.gd`
- `game/scripts/simulation/movement/PassageAwareMovementActionService.gd`
- `game/scripts/ci/PromptSimulationSimultaneitySmoke.gd`
- `.github/workflows/prompt-simulation-simultaneity.yml`

No renderer, presentation, view, camera, sprite, UI-animation, or interpolation file changed.

## Verification

Fresh prompt-local verifier:

- `game/scripts/ci/PromptSimulationSimultaneitySmoke.gd`
- `.github/workflows/prompt-simulation-simultaneity.yml`

Focused workflow run `34424284356`: **SUCCESS**.

The smoke verifies:

- contested same-cell movement is stable regardless of request order;
- one deterministic winner commits and the loser receives `target_blocked`;
- independent same-WHEN winners are all in their final cells before the first placement-change observer runs;
- the first `movement_committed` observer also sees the complete final batch;
- the successful group is exposed as one WHAT change batch;
- pre-batch occupied destinations remain blocked rather than becoming implicit swaps/chains;
- contested Run preserves deterministic impact/blocker truth.

The Godot 4.7.1 project class scan was clean for the touched movement classes and the focused smoke printed `PROMPT_SIMULATION_SIMULTANEITY_SMOKE: PASS` with no script/parse/load errors.

Exact functional-head Pages workflow run `34424284342`: **SUCCESS** for both Web build and deployment.

## Explicit non-change

Visual interpolation remains a separate future operation. Simulation placement continues to resolve discretely at authoritative WHEN boundaries; this closure only ensures that actors resolving at the same timestamp share one deterministic occupancy consequence boundary.
