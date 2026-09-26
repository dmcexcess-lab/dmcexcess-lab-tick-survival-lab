# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — PRODUCTION SURVIVAL ACTION STRIP WIRED — 2026-09-25

The previously missing ordinary player route for System 34 survival actions is now live in production gameplay.

Starting main for this operation: `f656bccd1914f815e15f47680c5e07f9cd2e972e`.

Production wiring heads:
- compact touch layout: `a1e33551e8b671f528b9698944ebf3244e37e28b`;
- production scene node: `2697ce62b4c7635f4d41d5c5da73068b1dbb1d26`;
- authoritative sustainment-service wiring: `4194d3e9d4f4342d7ff211d9f7e726bddeb6f557`.

Fresh verifier/workflow owning head: `1eec74a1fb90d8aa945d550cb879659ba4977bac`.

Focused verifier run: `36217859923` — **SUCCESS**.

Marker:

`SURVIVAL_CONTROLS_OK buttons=5 eat=true drink=true tap_status=SURVIVAL — no working tap panel_bottom=632`

Documentation head immediately before this final handoff write: `149adb8b27e07dd608e2c2fc4935f5f42a826b22`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous lighting pair was retired before production changes:

- `game/scripts/ci/SimpleLightingPresentationSmoke.gd`
- `.github/workflows/simple-lighting-presentation.yml`

Fresh current pair:

- `game/scripts/ci/SurvivalControlsSmoke.gd`
- `.github/workflows/survival-controls.yml`

The next code-changing prompt must delete this pair before changing code and create one fresh verifier/workflow scoped only to the next operation.

## Completed — ordinary survival controls

`gameplay.tscn` now includes `SurvivalControls` using the existing `ConditionPlayerControls`.

The production strip exposes:

- **EAT**
- **DRINK**
- **TAP**
- **REST**
- **SLEEP**

The strip is touch-first and sits directly above the existing movement controls:

- panel x = 41;
- panel y = 576;
- panel width = 558;
- panel bottom = 632;
- movement controls begin at y = 638.

This avoids the prior top-HUD overlap risk and preserves the existing lower movement grid.

## Authority and behavior

No parallel survival state or replacement action system was introduced.

`System34GameMain` configures the control strip with the existing authoritative:

- `SurvivorSustainmentActionService`;
- `TickKernel`;
- canonical player identity.

Action behavior remains owned by the existing System 34 service:

- EAT selects the first real carried edible item through carry truth and consumes the exact persistent entity on committed completion;
- DRINK does the same for a carried drink;
- TAP checks the existing real reachable powered potable-fixture provider;
- REST schedules the existing committed one-hour WHEN action;
- SLEEP schedules the existing committed eight-hour WHEN action;
- current bed/ground surface truth continues to affect comfort;
- elapsed-time condition pressure continues during rest/sleep.

The UI owns only touch buttons and concise result text.

## Focused verification

Fresh production-scene verifier:

- `game/scripts/ci/SurvivalControlsSmoke.gd`
- `.github/workflows/survival-controls.yml`

Run `36217859923` — **SUCCESS**.

The verifier proves:

1. `SurvivalControls` exists in production `gameplay.tscn`;
2. all five buttons exist;
3. all five buttons have ordinary pressed routes;
4. the panel fits the 640px phone layout and does not overlap the movement row;
5. a real persistent `item.food.apple` placed in canonical player inventory is consumed through the actual EAT button;
6. authoritative WHEN advances during EAT;
7. a real persistent `item.drink.water_bottle` is consumed through the actual DRINK button;
8. authoritative WHEN advances during DRINK;
9. TAP routes through the real control and returns the truthful unavailable result at the canonical spawn location rather than fabricating water access.

REST and SLEEP button routes are verified as live UI routes without forcing an artificial multi-hour infected-simulation benchmark inside this focused UI smoke.

## Preserved neighboring systems

This operation did not change:

- direct tile-tint lighting presentation;
- System 27 physical lighting truth or occlusion;
- perception / LOS;
- active infected cohort size or behavior;
- simultaneous combat consequences;
- mob force;
- fear;
- vehicles;
- utilities;
- world generation;
- inventory exact-item EAT/DRINK path;
- crafting;
- touch movement controls;
- hard pause ownership.

## Publication state before final handoff write

On documentation head `149adb8b27e07dd608e2c2fc4935f5f42a826b22`:

- fresh survival-control workflow run `36217918808` was in progress;
- Pages run `36217918776` was in progress.

After this final context write, perform read-only exact-head verification only.

## Continuation reconciliation — 2026-09-26

A stale continuation from an older Phase-2 performance checkpoint resumed after the repository had already advanced through **63 newer commits**.

Those newer commits had already completed:

- infected callback/perception performance closure;
- coherent consequence presentation;
- crowded-fight technical acceptance;
- the cached vision-cone/world-refresh regression repair;
- simplified direct per-tile lighting presentation;
- the current production survival-action strip.

One duplicate stale edit was briefly added after those completed slices: an extra `_acquisition.freshness_revision()` call in `ActiveInfectedCohortService.sync_active_now()`. The repository already contained the finalized infected-lighting preparation solution from the completed performance pass, so that duplicate call was removed exactly and no newer work was reverted.

Reconciliation code head: `205acf86867db953f3ab069d37e93c056d40df9e`.

Exact-head survival-control verifier run `36261877837` — **SUCCESS**.

No production survival-control, perception, lighting, combat, fear, crowd-pressure or world behavior was intentionally changed by this reconciliation.

The existing prompt-local pair remains authoritative because this was a restoration/reconciliation, not a new feature slice:

- `game/scripts/ci/SurvivalControlsSmoke.gd`
- `.github/workflows/survival-controls.yml`

This README_CONTEXT write is the final repository mutation for the reconciliation. Everything after it is read-only exact-head verification.

## NEXT OPERATION

Visually playtest the deployed survival strip on the real build.

Check specifically:

- all five controls are comfortable on phone/touch;
- the strip does not obscure important world content;
- EAT / DRINK feedback is readable;
- TAP gives useful failure feedback away from a sink and succeeds beside a working potable fixture;
- REST / SLEEP feel acceptable when actually advancing long stretches of world time.

If visual acceptance passes, continue with the next concrete player-facing release defect or core-loop balance issue exposed by playtest.

Do not reopen System 34 architecture unless the production control path reveals a concrete defect.

## Protected behavior

Preserve:

- one WHERE / WHAT / WHEN authority chain;
- System 27 physical-light truth and tile-tint-only presentation;
- lighting-driven perception;
- observer-pose LOS cache invalidation;
- active infected cohort size 8;
- simultaneous combat consequences;
- mob-force core;
- canonical fear;
- coherent consequence presentation;
- touch-first semantic controls;
- input locked until legitimate decision pause;
- hard application pause;
- player movement, health/injury, inventory, skills/equipment;
- day/night, weather, utilities, vehicles, persistence/terrain/streaming;
- STATS / INVENTORY / CRAFT / MENU ownership.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
