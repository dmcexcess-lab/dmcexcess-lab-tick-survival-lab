# Tick Survival Lab — Current Context / Authoritative Handoff

**This file is the first and primary continuation source for active repository work.**

If the user says continue/resume/finish the current coding task, read this file once, fetch current `main` once, and continue from **NEXT OPERATION** below. Do **not** broad-refresh the repo, reread all canonical docs, retrace architecture, or rediscover already-established seams unless a concrete compiler/test failure or unexpected head change requires one targeted read.

Per `README_SOPS.md`, **this file must be updated at the close of every coding/repository-change prompt before the final user-facing response, including interrupted or incomplete prompts whenever write tools remain available.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## Current repository checkpoint

- Last fully verified executable utility/substation head before process-only documentation changes: `a8ccbd8d717c1c61ef2ba3e53cda363ed73824c0`.
- `a8ccbd8` contains the accepted dynamic neighborhood-substation implementation described below.
- Process-only commits after that executable head:
  - `77ad1c4a60e3ff40f00b53e65b0c94c13602b5f7` — temporary continuation guardrail file;
  - `4539378f0cc7813048db78c8707d902a6fd12f64` — removed that duplicate sidecar so process authority lives in SOP;
  - `bdb6dc21b775b5517b876459f3b25c7eb222a951` — rewrote `README_SOPS.md` so continuation is context-first and prompt-close context updates are mandatory;
  - `261e569f390d5e7b1be0a0476d833b38ae4573c4` — refreshed this authoritative continuation handoff;
  - `48d1f609c24c966415b82e3edeed88c1396036f2` — made the no-early-close/evidence-only-blocker/CI-to-terminal rule explicit in the canonical SOP.
- This `README_CONTEXT.md` update is the closing repository write for the current process-rule prompt. On the next continuation, fetch `main` once to obtain the exact current documentation head, then proceed directly from this file.

## Game identity / protected direction

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Protected behavior that must not regress while finishing utilities:

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

Do **not** re-investigate or reconstruct this architecture during continuation unless a concrete test/compile failure names it.

## Active approved utility revamp — NOT YET IMPLEMENTED

The user has explicitly superseded the previous regional-radius water model and the old analytic automatic line-wear failure scheduler.

### Water target

Implement exactly this model:

1. There is **one real water treatment building/facility** on the island, placed somewhere near the shore.
2. It does **not require outside/grid power**.
3. It supplies municipal/potable water **island-wide without simulating long-distance pipes or water flow**.
4. If a critical component at this plant fails, **island-wide municipal water fails**.
5. Rural homes: deterministically choose **10–20%** to have a real persistent well.
6. A well is a **real item/entity in the generated world**, not a boolean/service flag or presentation-only prop.
7. A well requires local electrical power to operate.
8. While powered and maintained, a well provides effectively unlimited water to that home.
9. Wells require maintenance; keep this as real condition/maintenance state, not a fake timer/UI flag.
10. The old four-plant radius-coverage model is **SUPERSEDED**. Do not preserve it underneath the new model.

### Power-line daily snap target

Replace the old automatic analytic threshold-failure schedule for power lines with this daily hazard rule:

1. Once per authoritative game day, every eligible physical power line/span gets one deterministic failure test in stable order.
2. Start with a low daily snap chance.
3. If the entire day passes without a line snapping, increase the chance for the next day's tests.
4. As soon as one line snaps on a given day, **stop all remaining line tests for that day**.
5. When a snap occurs, reset the escalating chance back to its base value for the next day.
6. The snapped line must become a real failed physical asset and use the existing System-33 causal outage mapping; do not create a separate fake outage path.
7. Repair continues through the existing real physical-network repair seam.
8. If the player is within the existing hearing/sound range of the snapped span, emit a yellow spatial sound caption:
   `*SNAP*`
9. The sound must use the existing physical/spatial sound system, not a UI-only notification.
10. No per-line recurring timers/processes. The daily pass is owned by authoritative time/network logic and runs once per day.

The exact numeric base snap chance and daily increment were not specified by the user. Choose conservative low defaults as tuning constants in the owning runtime so they are easy to rebalance; do not block implementation to ask.

## Already-established implementation seams

These were already identified. **Do not broad-search them again.**

Primary files/seams:

- `game/scripts/generation/world/GlobalWaterInfrastructurePlanner.gd`
  - currently implements four regional radius plants; replace with one shore-near islandwide plant plan.
- `game/scripts/generation/world/GlobalWaterInfrastructureValidator.gd`
  - currently enforces four plants/radius service; replace those invariants with the one-plant islandwide contract.
- `game/scripts/simulation/utilities/UtilityRuntimeState.gd`
  - current water materialization still builds host-grid-powered pumps and radius bindings; replace with one grid-independent islandwide municipal chain and failure semantics.
- `game/scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd`
  - dynamic local power topology extension is already correct; preserve it while adding any building-specific well service seam.
- `game/scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd`
  - already has deterministic full generated building records (`building_id`, `archetype_id`, `rect`, `cell`, `site_id`, `settlement_id`) and is the available one-shot generated-building manifest for selecting rural well homes without runtime whole-world scanning.
- `game/scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd`
  - already materializes real local substation/pole infrastructure; preserve current behavior.
- `game/scripts/simulation/utilities/UtilityPowerNetworkRuntime.gd`
  - currently owns physical asset -> service consequences and an old predicted threshold schedule; replace the automatic wear-driven schedule with the once-per-day escalating snap test while retaining direct damage/repair and causal service refresh.
- `game/scripts/simulation/utilities/UtilityNetworkConditionStore.gd`
  - currently stores physical utility asset condition and analytic wear/predicted threshold. Preserve real condition/repair identity as useful, but remove/disable automatic line failure caused solely by the superseded continuous analytic wear scheduler where necessary for the new daily snap rule.
- `game/scripts/app/UtilityGameMain.gd`
  - already wires `world_tick_advanced` into the power-network owner; use this existing event-driven seam to detect day crossings. Do not add frame polling.
- Existing System-23/spatial-sound infrastructure must own the yellow `*SNAP*` hearing event. The exact callable symbol was not yet established; if required during implementation, one **single targeted symbol lookup/read** for the existing sound emission API is permitted. Do not reopen general sound architecture.

Likely focused tests to update/extend:

- System-33 power/water smoke/contract;
- global water planning/validation tests;
- physical power-network condition regression;
- local-area/generated-building regression if needed to prove deterministic 10–20% rural well assignment and real world materialization.

Use existing owning workflows rather than creating a new permanent workflow solely for this change.

## Current process correction — IMPORTANT

The prior repo process contained a contradiction: the top of `README_SOPS.md` required a broad canonical refresh at the start of every new code prompt, while the anti-thrashing section said not to rediscover established state. That contradiction contributed to repeated re-investigation loops.

It has now been removed and the early-close rule is explicit in the canonical SOP.

Canonical process now says:

- continuation = read this context once + fetch `main` once + execute the recorded next operation;
- no broad refresh for continuation prompts;
- targeted reads only for concrete failures, unexpected head drift, internal contradiction, or one exact API that was genuinely never established;
- **no voluntary early close while requested work remains**;
- do not blame or invoke a supposed context window, token/context limit, usage/tool allowance, model budget, session timeout, elapsed-time limit, platform cutoff, or OpenAI-imposed stop unless a concrete current tool/system response explicitly proves the remaining required operation cannot continue;
- pending CI/Pages is not completion and is not a blocker: continue monitoring required checks to terminal state;
- if a required check fails, inspect only the concrete failing evidence, repair it, push, and verify again;
- a coding prompt may end early only if the user explicitly cancels/pauses/redirects it or a concrete current tool/platform error makes the remaining operation impossible;
- **update this file at every coding prompt close before replying to the user**;
- no duplicate sidecar process document; `README_SOPS.md` is the single process authority.

## NEXT OPERATION

**Do not investigate further. Implement the active utility revamp.**

Start directly with edits on top of current `main`:

1. replace `GlobalWaterInfrastructurePlanner.gd` four-radius-plant output with one shore-near islandwide treatment plant;
2. replace matching water validator invariants;
3. migrate `UtilityRuntimeState.gd` to one grid-independent municipal water chain whose plant failure removes water island-wide;
4. deterministically select 10–20% of rural generated homes from the already-available generated-building manifest and materialize/bind real powered-maintained well entities;
5. replace `UtilityPowerNetworkRuntime.gd` automatic predicted threshold failure progression with the once-per-day stable-order escalating snap test, first-snap-stops-day, reset-on-snap behavior;
6. route a real snapped span through existing physical failure/outage truth and emit spatial yellow `*SNAP*` when in hearing range;
7. update focused tests only;
8. run/import the owning focused regressions and protected required integration checks;
9. fix only failures that actually appear, using targeted reads;
10. push/verify exact executable head and Pages as applicable;
11. update utility canonical docs/changelog;
12. **update this `README_CONTEXT.md` again as the final repo write before the final response.**

Do not spend another continuation rediscovering these seams.
