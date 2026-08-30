# Tick Survival Lab — Current Context / Authoritative Handoff

**This file is the first and primary continuation source for active repository work.**

If the user says continue/resume/finish the current coding task, read this file once, fetch current `main` once, and continue from **NEXT OPERATION** below. Do not broad-refresh the repo, reread all canonical docs, retrace architecture, or rediscover already-established seams unless a concrete compiler/test failure or unexpected head change requires one targeted read.

Per `README_SOPS.md`, **this file must be updated at the close of every coding/repository-change prompt before the final user-facing response, including interrupted or incomplete prompts whenever write tools remain available.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## Current repository checkpoint

- Last fully verified executable utility/substation head remains `a8ccbd8d717c1c61ef2ba3e53cda363ed73824c0`.
- No gameplay/runtime code was changed by the terminology cleanup that followed; `a8ccbd8` remains the executable checkpoint for the pending utility implementation.
- Canonical terminology cleanup reached functional cleanup head `f06a6174771e66b95759b16d05580a6161e51c42`.
- The one-shot cleanup workflow that produced that head completed successfully and was designed to fail if either forbidden third-party comparison title remained anywhere in readable repository text.
- The temporary one-shot cleanup workflow was then removed at `c899b2d616ef0abd89cb7bba30ec5c60ad9bb9ca`; it must not be recreated unless a future explicit cleanup task genuinely needs it.
- This `README_CONTEXT.md` update is the final repository write for the terminology-cleanup close. It repairs the stale handoff that previously pointed directly to utility implementation even though additional terminology-cleanup commits had occurred afterward.

## Terminology cleanup — COMPLETE

The active repository tree now uses project-native terminology.

Canonical identity:

> **Sprite-based zombie survival game.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Rules going forward:

- Do not use third-party game/franchise names as project identity, architecture shorthand, design-rule names, or explanatory comparisons in active canonical repository text.
- Do not reopen terminology archaeology during normal continuation work.
- Historical Git commits may still contain superseded language. Ordinary cleanup does not rewrite Git history.
- There is exactly one root continuation handoff file: `README_CONTEXT.md`. `README_SOPS.md` is process authority, not a second context/handoff file.
- The stale-context incident was caused by later automated cleanup commits occurring after the previous context close, not by duplicate context files.

## Protected direction

Do not regress these behaviors while finishing utilities:

- accepted black-screen recovery (`1f65bff312853a44858201b57d9df2e26ee64f80` lineage): full physical-light presentation and stateless LOS; do not reintroduce rejected camera-cropping/LOS-cache behavior;
- one-due-tick-batch-per-render-frame action progression;
- input locked until WHEN returns to a real decision pause; stale input discarded;
- weather/perception performance gains;
- 00F one-way materialization and stable persistent identity;
- deterministic playable-seed fallback/resolution;
- world-domain revision batching/caching;
- rendering/presentation never becoming utility truth.

## Power — current implemented state

The fixed/single-substation architecture has already been replaced on `main` by generated neighborhood substations.

Implemented at executable head `a8ccbd8`:

- substation count derives from the actual deterministic generated-building population;
- generated buildings are grouped locally per site, targeting/capping about 10 buildings per substation;
- every generated building is assigned exactly one local power service;
- each substation is physically materialized as real persistent infrastructure with transformer/utility boxes and a small chain-link enclosure;
- each served building receives a real nearby utility pole/service endpoint;
- physical local wires run from the substation transformer to those service poles;
- the regional power source -> substation relationship is causal/logical only and does not create cross-island overhead feeder art;
- local physical line/support damage feeds the existing System-33 outage/repair truth;
- no per-pole/per-line Nodes or timers were introduced.

**Do not re-investigate or reconstruct this architecture during continuation unless a concrete test/compile failure names it.**

## Active approved utility revamp — NOT YET IMPLEMENTED

The user explicitly superseded the previous regional-radius water model and the old analytic automatic line-wear failure scheduler.

### Water target

1. There is **one real water treatment building/facility** on the island, placed somewhere near the shore.
2. It does **not require outside/grid power**.
3. It supplies municipal/potable water **island-wide without simulating long-distance pipes or water flow**.
4. If a critical component at this plant fails, **island-wide municipal water fails**.
5. Deterministically choose **10–20% of rural homes** to have a real persistent well.
6. A well is a **real item/entity in the generated world**, not a boolean/service flag or presentation-only prop.
7. A well requires local electrical power to operate.
8. While powered and maintained, a well provides effectively unlimited water to that home.
9. Wells require real condition/maintenance state; no fake timer/UI flag.
10. The old multi-plant radius-coverage model is **SUPERSEDED** and must not remain underneath the new model.

### Power-line daily snap target

1. Once per authoritative game day, every eligible physical power line/span gets one deterministic failure test in stable order.
2. Start with a low daily snap chance.
3. If the entire day passes without a line snapping, increase the chance for the next day's tests.
4. As soon as one line snaps on a day, **stop all remaining line tests for that day**.
5. A snap resets the escalating chance to base for the next day.
6. The snapped line becomes a real failed physical asset and uses the existing System-33 causal outage mapping.
7. Repair continues through the existing physical-network repair seam.
8. If the player is in existing hearing/sound range, emit a yellow spatial caption: `*SNAP*`.
9. Use the existing physical/spatial sound system, not a UI-only notification.
10. No per-line recurring timers/processes; the daily pass is event-driven from authoritative time.

The exact numeric base snap chance and daily increment were not specified. Choose conservative low tuning constants and do not block implementation to ask.

## Already-established implementation seams

**Do not broad-search these again.**

- `game/scripts/generation/world/GlobalWaterInfrastructurePlanner.gd` — replace four regional radius plants with one shore-near island-wide plant plan.
- `game/scripts/generation/world/GlobalWaterInfrastructureValidator.gd` — replace four-plant/radius invariants with the one-plant island-wide contract.
- `game/scripts/simulation/utilities/UtilityRuntimeState.gd` — replace host-grid-powered water pumps/radius bindings with one grid-independent municipal chain and island-wide failure semantics.
- `game/scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd` — dynamic local power topology is correct; preserve it while adding any building-specific well seam.
- `game/scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd` — already exposes deterministic generated building records (`building_id`, `archetype_id`, `rect`, `cell`, `site_id`, `settlement_id`) for rural-well selection without runtime whole-world scans.
- `game/scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd` — current real local substation/pole infrastructure is protected.
- `game/scripts/simulation/utilities/UtilityPowerNetworkRuntime.gd` — replace old predicted-threshold automatic failure progression with the once-per-day escalating snap test while retaining direct damage/repair and causal service refresh.
- `game/scripts/simulation/utilities/UtilityNetworkConditionStore.gd` — preserve real condition/repair identity but remove/disable spontaneous failure caused solely by the superseded continuous analytic wear scheduler where required.
- `game/scripts/app/UtilityGameMain.gd` — already wires `world_tick_advanced` into power-network logic; use this event-driven seam for day crossings, not frame polling.
- Existing System-23/System-26 spatial-sound infrastructure must own the yellow `*SNAP*` event. If the exact callable was never established, one targeted symbol lookup/read is allowed; do not reopen sound architecture generally.

Focused tests should extend the existing owning System-33/global-water/physical-network regressions. Do not create a permanent new CI workflow solely for this change.

## Canonical execution/process rule

`README_SOPS.md` is the single process authority.

For continuation work:

- read this context once;
- fetch current `main` once;
- execute the recorded next operation;
- do not broad-refresh or rediscover established state;
- targeted reads are allowed only for a concrete compile/test failure, unexpected head drift, internal contradiction, or an exact API genuinely never established;
- do **not** voluntarily close while requested implementation or required verification remains;
- pending CI/Pages is not completion and not a blocker: continue to terminal status, repair failures, and reverify;
- never invoke supposed context/token/tool/session/model/platform limits or an alleged forced stop unless concrete current tool/system evidence proves the required operation cannot continue;
- before every coding/repository final response, update this file with the exact checkpoint, completed work, unfinished work, next operation, and verification state.

## NEXT OPERATION

The terminology cleanup is finished. **Do not perform more cleanup or archaeology unless explicitly requested.**

On the next ordinary Tick Lab coding continuation, implement the already-approved utility revamp:

1. replace `GlobalWaterInfrastructurePlanner.gd` four-radius-plant output with one shore-near island-wide treatment plant;
2. replace matching water validator invariants;
3. migrate `UtilityRuntimeState.gd` to one grid-independent municipal water chain whose plant failure removes water island-wide;
4. deterministically select 10–20% of rural generated homes from the already-available generated-building manifest and materialize/bind real powered-maintained well entities;
5. replace `UtilityPowerNetworkRuntime.gd` automatic predicted-threshold failure progression with the once-per-day stable-order escalating snap test, first-snap-stops-day, reset-on-snap behavior;
6. route a real snapped span through existing physical failure/outage truth and emit spatial yellow `*SNAP*` when in hearing range;
7. update focused tests only;
8. run the owning focused regressions and protected required integration checks;
9. fix only failures that actually appear, using targeted reads;
10. push/verify exact executable head and Pages as applicable;
11. update utility canonical docs/changelog;
12. **update this `README_CONTEXT.md` again as the final repo write before the final response.**
