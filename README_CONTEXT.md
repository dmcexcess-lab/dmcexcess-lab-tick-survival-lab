# Tick Survival Lab — Current Context / Authoritative Handoff

**This file is the first and primary continuation source for active repository work.**

If the user says continue/resume/finish the current coding task, read this file once, fetch current `main` once, and continue from **NEXT OPERATION** below. Do not broad-refresh the repo, reread all canonical docs, retrace architecture, or rediscover already-established seams unless a concrete compiler/test failure or unexpected head change requires one targeted read.

Per `README_SOPS.md`, **this file must be updated at the close of every coding/repository-change prompt before the final user-facing response, including interrupted or incomplete prompts whenever write tools remain available.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## Current repository checkpoint

- Last fully verified executable utility/substation head remains `a8ccbd8d717c1c61ef2ba3e53cda363ed73824c0`.
- Terminology cleanup closed at context-repair head `925787988d0ff14706244e5a9aafc815559184ca` before the interrupted utility implementation attempt described below.
- **No utility gameplay/runtime implementation from the interrupted attempt was committed to `main`.** Do not falsely treat the draft blobs below as landed code.
- This context-only handoff update exists specifically so a new chat does not repeat the utility investigation/drafting work.

## Terminology cleanup — COMPLETE

The active repository tree uses project-native terminology.

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

## Seed state — COMPLETE / PROTECTED

The playable-seed problem is already fixed. Do not revisit seed selection unless a concrete failing regression names it.

Protected seed behavior includes:

- invalid-seed reroll/fallback;
- playable-materialization preflight/resolution;
- deterministic playable-seed fallback/resolution;
- regression coverage for the playable seed path.

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

## Power — current implemented state on `main`

The fixed/single-substation architecture has already been replaced by generated neighborhood substations.

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

## Active approved utility revamp — IMPLEMENTATION DRAFTED, NOT COMMITTED

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

The exact numeric base snap chance and daily increment were not specified. The interrupted draft chose conservative low constants: `100 / 1,000,000` base per eligible span per day, `+100 / 1,000,000` per quiet day, capped at `10,000 / 1,000,000`.

## Work completed during the interrupted utility attempt

The prior chat did substantial targeted investigation and drafted replacement source into GitHub blob objects, but **did not create a tree/commit or move `main` to them**. These blobs are useful continuation material and should prevent repeating the investigation.

Established findings:

- `GlobalWaterInfrastructurePlanner.gd` old code created four regional radius plants.
- `GlobalWaterInfrastructureValidator.gd` enforced four plants/radius coverage.
- `GlobalWorldProfileCatalog.gd` still carried old `water_regional_plant_count`, `water_service_radius_cells`, and regional source/treatment offsets.
- Base `UtilityRuntimeState.gd` itself still contained the obsolete four-plant, host-grid-powered, radius-based runtime; it must be migrated, not merely hidden by the neighborhood subclass.
- `GlobalWaterInfrastructureQuery.gd` also still used radius lookup and must migrate to island-wide semantics.
- `NeighborhoodUtilityRuntimeState.gd` is the right place for building-specific private-well bindings while preserving existing local power topology.
- `UtilityLocalPowerTopologyPlanner.gd` already exposes stable generated building records sufficient to choose rural wells once, without runtime whole-world scans.
- `NeighborhoodPowerInfrastructureMaterializer.gd` is the correct physicalization seam for the single water facility and private wells alongside existing local power infrastructure.
- `UtilityNetworkConditionStore.gd` can preserve real damage/repair condition identity while removing spontaneous analytic wear progression.
- `UtilityPowerNetworkRuntime.gd` receives authoritative tick advancement already; it can process day crossings without frame polling or per-line timers.
- Exact spatial-sound callable was established: `SpatialSoundService.emit_sound(profile_id, origin_cell, emitter_entity_id, emitter_token)`.
- `SoundEmissionProfileCatalog.gd` is the correct profile owner; a `utility.power_line_snap` profile can use `*SNAP*` at all recognition tiers so existing yellow spatial-caption presentation owns the cue.
- `UtilityGameMain.gd` is the correct place to connect the physical network's `line_snapped` signal to the existing spatial sound service.
- Existing art can physically represent the facility/wells without a fake UI marker: facility shell/equipment can use existing `prop.shed`, `prop.water_heater_tall`, `prop.industrial_machine`, `prop.utility_box`, `prop.chainlink_fence`; a stable well entity can use an existing visible ground-cap prop while its stable entity/asset ID + System-33 condition state carry actual well identity.
- Focused owning tests are `System33PowerWaterSmoke.gd`, `System33PowerInfrastructureSmoke.gd`, and `System33PowerPhysicalNetworkSmoke.gd`; existing `.github/workflows/system33-power-water.yml` already runs them plus protected integration regressions. Do not create a new permanent workflow.

### Uncommitted draft blobs from that attempt

These are **reference drafts only**. Fetch by blob SHA if useful, review/repair, then commit through a normal tree/commit. Do not assume they parse or pass tests until CI proves it.

- `game/scripts/generation/world/GlobalWaterInfrastructurePlanner.gd` -> blob `9d1e1d2ff452b7c7daa7c79ed10ffbdc5a603233`
- `game/scripts/generation/world/GlobalWaterInfrastructureValidator.gd` -> final draft blob `dbb52909391e7044e8915701febd248bba4f6965`
- `game/scripts/generation/world/GlobalWorldProfileCatalog.gd` -> blob `5b44d4cb4aceccab5c133e24e40984e7680f8ce4`
- `game/scripts/generation/world/GlobalWaterInfrastructureQuery.gd` -> blob `6170715b00aa4c87f45bb63d7270ce0663286895`
- `game/scripts/simulation/utilities/UtilityRuntimeState.gd` -> blob `61d527feec3a0f56d16eb4427f0c165935996779`
- `game/scripts/simulation/utilities/NeighborhoodUtilityRuntimeState.gd` -> blob `1ae62c52559cebbd345eb502d1dcdd4d283ee1bc`
- `game/scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd` -> blob `98dd33cdc02e9868a1411c1a1fd5f922e7b59e8a`
- `game/scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd` -> blob `5b2d0cdfe0f754f3b5059bcd0d5f6db829064bf4`
- `game/scripts/simulation/utilities/UtilityNetworkConditionStore.gd` -> blob `320a61f27c17b7dd8a6ff0268c79ac8be75d7e1f`
- `game/scripts/simulation/utilities/UtilityPowerNetworkRuntime.gd` -> blob `a83fa5af3053a04dfc8cd4d84b5ce7a2a38921d7`
- `game/scripts/simulation/sound/SoundEmissionProfileCatalog.gd` -> blob `383f6434bac50356741078d5e4998baf0426434d`
- `game/scripts/app/UtilityGameMain.gd` -> blob `4d3c3bb4d3cbf300a2634a2054a11a36ad2f6d57`
- `game/scripts/ci/System33PowerWaterSmoke.gd` -> final draft blob `f348f59bae3eb8b359f78e4421ca49174c07fe41`
- `game/scripts/ci/System33PowerInfrastructureSmoke.gd` -> blob `a22eebf1f4c5c6e91d35d222bba207a45d801703`
- `game/scripts/ci/System33PowerPhysicalNetworkSmoke.gd` -> blob `d50fba224426e01eda71157cecc1bae9475669c4`

Earlier superseded draft blobs from the same attempt should be ignored when a final-draft SHA is listed above.

## Important caveats before committing the drafts

- The draft set was **not parsed or executed in Godot** before interruption.
- Treat compile/test failures as expected cleanup, not a reason to redo architecture.
- Review the draft set as a coherent migration because base water runtime/query and neighborhood private-well runtime must agree.
- Preserve current local-substation behavior exactly unless a failing test identifies a concrete incompatibility.
- The existing `System33PowerWaterSmoke.gd` draft was rewritten once during the attempt; use the listed final blob SHA, not earlier draft content.
- The physical water representation intentionally reuses existing art semantics; if a concrete art/collision regression rejects one semantic, replace only that semantic without converting water truth into presentation-only state.
- Do not revisit seeds, terminology cleanup, black-screen recovery, or broad world architecture during this continuation.

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

**Do not redo the utility investigation. Do not redo seed work. Do not do more terminology cleanup.**

Resume the interrupted utility implementation from the uncommitted draft blobs above:

1. fetch current `main` once and confirm only expected context/head drift;
2. fetch the listed draft blobs and assemble them as one coherent candidate tree over current `main`;
3. perform only a focused static sanity review for obvious draft mistakes/contradictions; do not broad-reread the repo;
4. commit the candidate utility migration to a normal reachable commit on `main`;
5. run/observe the owning `system33-power-water` CI to terminal status, including Godot parse/import and focused utility smokes;
6. fix only concrete failures with targeted reads and recommit/reverify until green;
7. run/confirm protected required integration checks and exact-head status; verify Pages/live build if the repository process requires it for this executable change;
8. update canonical utility docs/changelog to describe the landed one-plant municipal water, real powered-maintained rural wells, and daily physical line snap model;
9. **make `README_CONTEXT.md` the final repository write again**, recording the exact executable head, CI/Pages terminal state, any tuning constants actually landed, and the next real gameplay operation.

Completion means the utility code is actually committed and verified, not merely drafted.