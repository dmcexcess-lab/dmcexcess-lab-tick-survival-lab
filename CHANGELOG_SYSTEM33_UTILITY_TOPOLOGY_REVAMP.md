# Tick Survival Lab — Utility Topology / Water Contract Revamp — 2026-08-30

Status: **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING**

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`

## Result

Phase-3 utility behavior was rebuilt around the actual generated island rather than stale settlement-radius and placeholder facility assumptions.

### Local electrical distribution

- Added deterministic `UtilityLocalPowerTopologyPlanner` over the actual generated local-area building manifests.
- Generated buildings are grouped with a target of **10 buildings per local substation**.
- Added `NeighborhoodUtilityRuntimeState` so the regional source feeds those real local substation groups instead of the old single runtime substation model.
- Source/ingress -> local substation is intentionally logical/non-physical for presentation; no fake long-distance transmission line is drawn.
- Added `NeighborhoodPowerInfrastructureMaterializer` with small fenced substation compounds: transformer + two utility boxes + chain-link fence.
- Each served building receives a customer pole placed near its real envelope and a visible span from the owning substation.
- Existing physical span/support condition identity and causal outage mapping remain authoritative.

### Daily power-line failures

- Replaced the earlier continuous analytic-wear future-threshold model with one deterministic pass per authoritative game day.
- Base chance is **0.01% per eligible span/day**.
- Each quiet day adds **0.01%**; chance caps at **1.00%**.
- The first successful snap ends the day's pass and resets quiet-day accumulation.
- Span rolls are deterministic from day index + stable span ID; save/restore preserves processed-day and quiet-day state.
- A snapped span becomes a real failed physical asset and damages only its mapped System-33 service path.
- `line_snapped(asset_id, cell)` is forwarded through System 26 as the spatial text sound `*SNAP*`.
- No per-span Node, Timer, frame polling or continuous wear scheduler was introduced.

### Potable water

- Replaced the old mixed municipal/decentralized radius contract with one **island-wide municipal treatment facility** near the shore.
- Global water planning now records one plant/network, three compact plant nodes and two plant-internal segments.
- Every settlement receives `island_wide_municipal` treated-water service with no positive service radius.
- No long-distance pipe/pressure/flow simulation is created.
- The physical plant is a real fenced utility facility with stable critical-asset identity.
- Municipal plant failure removes island-wide municipal service; repair restores it.
- The municipal plant intentionally has **no external-grid power dependency**.

### Real rural wells

- Private wells are selected from actual generated rural residential buildings rather than global settlement intent.
- Deterministic target is 15% of rural homes, bounded to 10–20% where the population permits.
- Selected wells are real persistent physical assets/services beside their owning homes.
- Private wells depend on the real local power service for their building group and carry persistent condition/repair state.

### Wastewater removal cleanup

The user clarified that wastewater had been removed long ago. Stale dependencies were therefore removed rather than adapted:

- `GlobalWorldPlanner` no longer invokes wastewater planning/validation (`a371541e36af35d62490dbc8c98ba729b80f17fe`).
- `GeneratedGlobalWorldPlan.is_generated()` no longer requires wastewater arrays (`7ab78cb1a39933b96730cc4e33a42da4b9cdc1f8`).
- `System20AreaRequestProjector` no longer injects/requires wastewater and now accepts the island-wide municipal water contract (`b194832bf7f46671eaf340a5382a64fd97bc32d2`).
- The global-planning v7 regression/workflow was migrated away from wastewater and old radius/local-trunk assumptions (`a0299a14d21fb907bdd363ddadb00cc3403b48f1`).
- `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is now explicitly retired historical documentation.

### CI / Pages repair

- System-33 owning verification is green on `a0299a1`, including utility/physical-network smokes, complete-island planning, physical lighting, freshness, performance architecture, input responsiveness and startup.
- Global world planning is green on `a0299a1`, including profile-v7 water planning, complete-island generation, island seam proof, System-20 dependency contract and startup.
- Pages' forbidden-title guard had an unrelated substring false positive (`ultimately`); the matcher was corrected at `a4fbb3bcbe3916c7f8e28bef276edb753d031819`.
- Pages build, Godot web export, artifact upload and deploy are all green on `a0299a1`.

## Human verification still required

Browser play should verify visible local substation count/appearance, local building service drops, absence of fake source-to-substation wires, municipal plant/well placement, outage/repair consequences, and continued performance/visibility behavior before Phase 3 is marked HUMAN ACCEPTED.
