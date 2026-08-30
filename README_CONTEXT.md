# Tick Survival Lab — Current Handoff

Last updated: **2026-08-30**

This file is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION** without rediscovering completed architecture.

## Current heads

- **Exact verified executable:** `a0299a14d21fb907bdd363ddadb00cc3403b48f1` — `Align global planning regression with current water model`
- **Canonical documentation parent immediately before this final handoff write:** `0615ab09896be94ff6c061a0f0aae36ea2ff18f7` — `Document current island utility contract`
- This `README_CONTEXT.md` update is intentionally the **final repository write** of the completed utility-revamp prompt. The commit containing this file is the current documentation/handoff head; executable verification remains anchored to `a0299a1` because all commits after it are documentation-only.

## Completed operation — Phase 3 utility topology / water revamp

The requested utility behavior is implemented for the real procedurally generated island rather than faked/demo-only geometry.

### Power

- `UtilityLocalPowerTopologyPlanner` derives utility groups from the actual deterministic generated building manifest.
- Local substations target **~10 generated buildings each** (`TARGET_BUILDINGS_PER_SUBSTATION = 10`); count scales with actual generated content rather than using a fixed island count.
- Each local substation has stable service/component identity and physically materializes as a small fenced electrical compound containing a transformer, two utility boxes and chain-link fencing.
- Regional source / power-plant ingress -> local substation is intentionally **logical/non-physical for presentation**. No fake long-distance source-to-substation transmission line is drawn.
- Visible local distribution spans originate at the substation transformer and terminate at customer poles placed near the real generated buildings they serve.
- Physical spans/supports have stable condition identity and map causally to the System-33 services they can interrupt.

### Daily line failures

The old continuously predicted analytic-wear failure scheduler is superseded by the approved day-boundary rule:

- one deterministic eligible-span pass per authoritative game day;
- **0.01%** base chance per eligible span/day (`100 / 1,000,000`);
- **+0.01%** per quiet day;
- **1.00%** cap (`10,000 / 1,000,000`);
- failed spans are skipped;
- first successful snap ends that day's pass;
- a snap resets quiet-day accumulation;
- roll derives from authoritative day index + stable span ID;
- snapshot/restore preserves last processed day + quiet-day state so history is not rerolled;
- the real snapped span fails, only its mapped System-33 service path is damaged, and canonical repair restores only outage state owned by that physical fault;
- live composition forwards `line_snapped(asset_id, cell)` through System 26 as the spatial text sound `*SNAP*`.

No per-span Node, Timer, render-frame utility loop or continuous whole-network wear scan was introduced.

### Potable water

- One real **island-wide municipal treatment facility** is planned near the shoreline.
- Global water contract is one plant/network with exactly three compact plant nodes (`raw_water_source`, `treatment_plant`, `island_service_anchor`) and two short plant-internal segments.
- Every settlement gets `island_wide_municipal` / `treated_municipal` service referencing that same plant.
- There is **no positive municipal service radius** and no simulated long-distance municipal pipe/pressure/flow network.
- The physical municipal plant is a real persistent fenced utility facility with a stable critical asset.
- Municipal plant failure removes island-wide municipal service; repair restores it.
- The municipal plant intentionally **does not require external grid power**. A normal electrical-grid outage alone does not disable municipal water.

### Rural wells

- Private wells are selected from the **actual generated rural residential buildings**, not from imaginary settlement intent.
- Target is **15%** of rural homes, bounded to **10–20%** when the rural-home population permits a meaningful range.
- Selection is deterministic from world seed + stable building identity.
- Each selected well is a real persistent physical asset/service beside its owning generated building with persistent condition and repair state.
- Current private wells are electrically pumped and depend on that building group's real local power service.
- `water_service_for_building()` prefers an available private well for its owning building and otherwise can use the settlement's island-wide municipal service.

## Wastewater — retired, do not resurrect

The user explicitly confirmed wastewater was removed long ago. It is **not an active game system, planning stage, local-generation requirement or System-33 dependency**.

Completed cleanup:

- `a371541e36af35d62490dbc8c98ba729b80f17fe` — removed live wastewater planner/validator orchestration from `GlobalWorldPlanner`.
- `7ab78cb1a39933b96730cc4e33a42da4b9cdc1f8` — removed wastewater arrays from generated-world validity requirements.
- `b194832bf7f46671eaf340a5382a64fd97bc32d2` — removed wastewater constraints/requirements from `System20AreaRequestProjector` and migrated it to the island-wide municipal water contract.
- `a0299a14d21fb907bdd363ddadb00cc3403b48f1` — migrated the broader global-planning regression/workflow away from wastewater, profile-v6 and radius/local-trunk assumptions.
- `SYSTEM_DESIGNS/00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is now explicitly **RETIRED / historical only**.

Legacy wastewater source/data files may remain inert for historical compatibility. Their existence is not permission to call them from live generation/runtime or to restore wastewater to satisfy stale tests.

## Verification — exact executable `a0299a14d21fb907bdd363ddadb00cc3403b48f1`

### System 33 power/water

Workflow run: `33300034410`

Result: **SUCCESS**

Passed:

- source-boundary validation;
- Godot 4.7.1 import/parse;
- `System33PowerWaterSmoke.gd`;
- `System33PowerInfrastructureSmoke.gd`;
- `System33PowerPhysicalNetworkSmoke.gd`;
- protected complete-island planning;
- System-27 physical-lighting regression;
- System-30 item-freshness regression;
- performance-architecture regression;
- player-input-responsiveness regression;
- canonical startup;
- exact-head System-33 status publication.

### Global world planning

Workflow run: `33300034407`

Result: **SUCCESS**

Passed:

- System-00D source boundary;
- Godot import/parse;
- corrected profile-v7 / island-wide-water global planning smoke;
- complete-island planning;
- legacy crossroads seam proof;
- System-20 dependency/local-generation contract;
- canonical startup.

### Pages / live web build

Workflow run: `33300034385`

Result: **SUCCESS**

- build job `99226316055`: success;
- canonical validation/import/integration/startup: success;
- Godot Web export: success;
- Pages artifact upload: success;
- deploy job `99226666936`: success.

The earlier unrelated Pages failure was a false-positive forbidden-title substring match (`Ultima` inside `ultimately`). Commit `a4fbb3bcbe3916c7f8e28bef276edb753d031819` changed that guard to whole-word matching.

## Canonical documentation close

Documentation-only commit `0615ab09896be94ff6c061a0f0aae36ea2ff18f7` updated:

- `SYSTEM_DESIGNS/00D_GLOBAL_WORLD_PLANNING.md`;
- `SYSTEM_DESIGNS/00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`;
- `SYSTEM_DESIGNS/00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md`;
- `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`;
- `SYSTEM_DESIGNS/33B_POWER_PHYSICAL_NETWORK_CONDITION.md`;
- `SYSTEM_DESIGNS/README.md`;
- `CHANGELOG_LATEST.md`;
- new `CHANGELOG_SYSTEM33_UTILITY_TOPOLOGY_REVAMP.md`.

A compare from executable `a0299a1` to `0615ab0` confirmed that commit changes documentation/changelog files only; no executable or workflow source changed after the green executable.

## Current project/lifecycle state

- Utility revamp implementation: **COMPLETE**.
- Wastewater stale dependency cleanup: **COMPLETE**.
- Owning + protected automated verification: **GREEN** on exact executable `a0299a1`.
- Pages build/export/deploy for executable `a0299a1`: **GREEN**.
- Canonical utility/global-planning docs: **UPDATED**.
- No known implementation or CI blocker remains for this operation.
- **Phase 3 human browser acceptance is still pending** for the current visible/game-feel utility behavior; CI alone does not mark it HUMAN ACCEPTED.

## NEXT OPERATION

Do **not** reopen the utility implementation, old radius-water model, analytic-wear scheduler, or wastewater cleanup by default.

If the next user request is to verify/finish Phase 3, perform a focused human/browser playtest against the current live Pages build and check:

1. substations appear as small fenced electrical compounds and scale roughly one per ten generated buildings;
2. no fake source/power-plant -> substation transmission line is visible;
3. local wires originate from substations and terminate near the buildings they serve;
4. physical line failure/repair causes/restores only the expected local outage and `*SNAP*` behavior remains correct;
5. the municipal plant exists physically near shore and its critical-asset failure removes island-wide municipal water;
6. ordinary grid loss does not disable the municipal plant;
7. a deterministic minority of rural homes have real private wells and their powered-well failure/repair behaves correctly;
8. powered lighting/refrigeration consequences remain truthful;
9. no black-screen, first-step hitch growth or input-backlog regression returns;
10. phone/Safari remains first-class.

If human play exposes a concrete defect, reproduce it against this baseline, make the smallest owner-correct repair, run `verify/system33-power-water` plus the specifically affected protected regression(s), follow Pages to terminal deployment, update canonical docs/changelog if behavior changed, and update this file last.

If the user instead gives a new roadmap/gameplay task, accept that explicit direction and continue from the current canonical docs/executable baseline without reopening completed Phase-3 architecture.
