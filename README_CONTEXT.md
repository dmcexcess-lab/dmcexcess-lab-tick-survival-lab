# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current checkpoint — simple municipal water + rural private wells complete

### Verified executable

- **Executable:** `4ced86b353d273d54b89e0fb52499f564172364b` — `Align infrastructure smoke with single water facility`.
- **Owning utility CI:** `verify/system33-power-water` run `33988514222` — **SUCCESS** on that exact executable.
- **Pages:** `verify/pages-deploy` run `33988514204` — **SUCCESS** on that exact executable.
- **Live build:** https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
- The documentation-only closure after the executable updated `SYSTEM_DESIGNS/00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`, `SYSTEM_DESIGNS/00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md`, and `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`. Immediately before this mandatory handoff write, documentation head was `444ff9a4bdf2bc145013d3bd1c530711544e7280`.
- A compare from executable `4ced86...` through documentation head `444ff9...` showed **only those three markdown files changed**; no gameplay/source file changed after the verified executable.
- Standing direct-to-`main` authorization remains in `README_SOPS.md`; do not ask again unless the user explicitly changes it.

### Do not misreport the whole suite as green

The requested water/well owner and Pages are green, but several unrelated checks remain red on the current development line.

Most relevant: `verify/system33-roadside-pole-routing` currently fails its shared-trunk two-pole side-hold assertion. That exact check was already failing on pre-well parent `12bcdcd40a7f6ab45ecd2bfa3424e10dfff61935`, before the private-well binding was introduced. Treat it as a separate power-routing defect, not a water/well regression.

Other current red contexts observed around executable `4ced86...` included flashlight/performance/portable-generator/lighting-related checks. Do not silently fold those into the completed private-well task; investigate them only when their owning work is resumed.

## Current canonical potable-water rule

The user explicitly simplified water and then added one rural exception.

### Municipal water

> **One real generated building is the island municipal water facility. If it works, municipal water works island-wide. If it is broken, municipal water is off island-wide.**

Current implementation:

- Global planning owns one stable facility identity, `water.facility.island`.
- The facility resolves to an **already generated real building** in the structural local-area manifest. Current planner prefers `civic.post_office.small` at the selected host site and deterministically falls back to another generated building there if necessary.
- Per-settlement `water_services` are lightweight aliases/references to that same facility for projection/runtime compatibility; they are not separate plants.
- `water_nodes` and `water_segments` are empty in the live contract.
- There is no municipal pipe graph, pressure simulation, service radius or distribution-header topology.
- `GlobalWaterInfrastructureValidator` rejects populated water topology and rejects wastewater population.
- `NeighborhoodUtilityRuntimeState` materializes one municipal source component backed by that real generated facility building.
- `NeighborhoodPowerInfrastructureMaterializer` no longer materializes a second fake treatment shed/tank complex.
- The municipal facility has no external-grid power dependency.
- Damage below the water failure threshold disables municipal service island-wide; repair restores it.

### Rural private wells

> **Deterministically select 10–20% of rural buildings. Each selected building uses its private well instead of the municipal facility.**

Current implementation:

- `UtilityLocalPowerTopologyPlanner` identifies rural sites from their `rural.*` area profile and considers **all generated buildings in those rural sites**, not just residential archetypes.
- Constants are `RURAL_WELL_MIN_PERCENT = 10` and `RURAL_WELL_MAX_PERCENT = 20`.
- Candidate order uses stable world-seed + building-ID hashing.
- The selected count is deterministically chosen between the calculated 10% minimum and 20% maximum; for sufficiently large rural sets the planner validates that the actual fraction remains inside that range.
- Town/non-rural buildings are never selected.
- Each selected building gets one stable private well asset/component/service identity.
- The physical infrastructure materializer creates a simple persistent visible well-cap entity adjacent to the owning building. No pipe graph is created.
- Private wells have **no required grid-power dependency**.
- `well_service_for_building()` returns the selected building's private service.
- `water_service_for_building()` returns that same private service even when the well is broken. Source identity does not change with availability.
- A working well survives a municipal-facility outage.
- If the well is damaged, that building has **no water** until the well is repaired.
- A broken well **does not fall back to municipal water**.
- Repair restores the same private service identity.
- Rural buildings without wells and all town buildings use municipal water.
- Snapshot/restore preserves water-asset condition and rebuilds the private-well building index without rerolling selection.

### Wastewater remains removed

There is no active wastewater/sewer/septic system.

Do not restore wastewater planning, validation, local constraints, runtime state or CI expectations merely because historical files/compatibility fields still exist. `SYSTEM_DESIGNS/00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is explicitly retired.

## Private-well verification proven on executable `4ced86...`

`verify/system33-power-water` proves the target behavior, including:

- municipal water has no node/segment graph;
- wastewater remains absent;
- one real generated building is the municipal facility asset;
- municipal facility failure removes island-wide municipal water and repair restores it;
- municipal water is independent of grid power;
- private-well selection is deterministic and within 10–20% of rural buildings;
- only rural buildings receive wells;
- well assets/services map to their exact owning buildings;
- wells have no grid dependency;
- a healthy private well survives municipal failure;
- a damaged well remains the authoritative source and leaves its building dry rather than falling back;
- well repair restores service;
- utility snapshot/restore preserves the state.

The aligned physical-infrastructure smoke additionally proves:

- the municipal facility is an existing generated building;
- no duplicate municipal treatment shell is created;
- every selected private well receives a persistent visible well-cap entity.

Private-well implementation work is complete. Human visual/play acceptance remains separate from automated proof.

## Generator / streaming work already completed in the same development line

The earlier performance/generator pass implemented the following and must not be rediscovered from scratch:

- `GlobalStreamingCoordinator` caches source discovery by technical stream region and spatially indexes source handles.
- Boundary updates discover the **entering strip** instead of rediscovering the full 3×3 active neighborhood.
- Already-materialized handles are prefiltered before expensive coordinator work.
- Streaming phase timing instrumentation covers discovery/preparation/snapshot/commit work.
- `PlayerStreamingFocusAdapter` performs bounded directional look-ahead/preparation near a 128-cell region edge, preparing at most one new logical source per movement step.
- `RenderWindowCoordinator` exposes recenter timing.
- PERF DEV reporting exposes streaming phase and render-window timing.
- Repeated immutable catalog validation was reduced/cached.
- Current technical stream geometry remains **128×128, radius 1**. Do not change it merely because 256 was discussed as a later A/B test.

## Generator / streaming cleanup still unfinished

The user originally asked to remove rivers and generator clog before the water simplification interrupted that cleanup. Do not claim this broader cleanup finished just because the well feature is complete.

Known remaining debt to verify/remove when that task resumes:

- inert/legacy hydrology, river and bridge compatibility classes or fields may still remain in the active tree;
- `GeneratedGlobalWorldPlan` still carried transitional compatibility arrays for rivers/bridges/water topology/wastewater during the refactor;
- `IslandWorldPlanner`, `LocalAreaGenerator`, `System20AreaRequestProjector`, area reservation code and old hydrology/watercourse/wastewater files may still contain dead paths that should be migrated/deleted rather than left as permanent compatibility clutter;
- full-world rollback snapshots still scale with explored/materialized world state;
- live WHAT unloading/dematerialization of distant immutable base world plus persisted deltas has not been implemented;
- prepared/commit separation and bounded prefetch exist, but the larger persistence-ownership rewrite was intentionally not faked as complete.

When resuming this cleanup, protect the **current simplified water contract** above. Removing dead water-network/wastewater code must not delete private wells or the one real municipal facility.

## Density / world-generation state to preserve

The prior density pass remains the intended world scale target until the user gives new playtest feedback.

Reference seed 20001 at that checkpoint:

- 306 buildings;
- 286 residential building records;
- 1,002 residents;
- two towns, three compact crossroads and six rural lane sites;
- population remains building-derived, with infected + survivors == residential capacity;
- no fake population multiplier and no spawned-zombie count source.

Human density/lag acceptance remains pending. Do not reintroduce the old 12-seed matrix on every edit; `README_SOPS.md` records the user's current focused-test rule.

## Current user direction — finish player/world before combat

The user explicitly wants rendering, player systems, inventory and practical world/object interactions substantially complete and usable through normal UI **before NPCs, zombies or combat**.

Practical completion rule:

> **A simulation feature is not player-complete until ordinary gameplay UI provides a truthful route to its owning action and state.**

Protected existing player/world closures include:

- exact-item inventory EAT/DRINK/equip/stow/drop;
- exact-injury first aid through real inventory/Health/WHEN ownership;
- real flashlight item ON/OFF state while hand-equipped;
- doors/windows with per-opening quiet-entry/forced-entry state, boarding and climb-through;
- no house-key/key-ring system;
- vehicles with persistent key-in-ignition/hotwire truth rather than collectible vehicle keys;
- bed/chair rest/sleep;
- crafting/deconstruction/loot/refrigeration routed through their real owners;
- fixed electrical lights follow System-33 service automatically; there are intentionally no light switches;
- weather/day-night are automatic authoritative systems;
- exactly four skills: Awareness, Stealth, Mechanical, Survival.

Construction remains limited to reinforcing existing doors/windows and repairing broken existing objects. Do not add freeform base building unless the user changes direction.

## Protected architecture

Do not regress:

- accepted decision-pause input locking / no queued movement backlog;
- WHERE / WHAT / WHEN ownership boundaries;
- one production interaction chooser;
- exact WHEN terminal semantics;
- physical lighting + stateless LOS + System-23 hidden-information authority;
- real utility topology and refrigeration;
- canonical containment/weight/Health/System-34 ownership;
- building-derived population accounting;
- vehicle persistence/cargo/fuel/lighting/sound/crash behavior;
- no frame-driven skill/condition/resource/vehicle/utility loops;
- no per-entity timers or recurring whole-world scans;
- no UI-owned fake repair/fire/medicine/light/vehicle truth;
- **no wastewater resurrection**;
- **no municipal water pipe/node graph**;
- **no private-well municipal fallback**;
- **no grid dependency for private wells or the municipal facility under the current gameplay contract**.

Current production inheritance remains:

`VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

Do not add another subclass layer casually. Flattening this inheritance debt is separate from current practical player/world closure.

## Human acceptance still pending

Automated verification does not replace browser/phone play feel. For water specifically, visually verify:

1. no duplicate fake municipal treatment facility appears;
2. the selected municipal facility building behaves as the one islandwide source;
3. roughly 10–20% of rural buildings receive sensible visible well-cap placement;
4. town buildings do not get wells;
5. a well building keeps water through municipal failure;
6. a broken private well leaves that building dry until repaired;
7. no wastewater or pipe-network artifacts appear.

Continue desktop and iPhone/Safari acceptance for interaction chooser readability, inventory actions, board/break/climb feedback, vehicles, utilities, weather/lighting and generated-world proportions.

## NEXT OPERATION

1. **Private-well task is complete. Do not reimplement it.** If the user is continuing the generator/performance cleanup, start by identifying and removing the remaining dead hydrology/river/bridge/wastewater compatibility paths from live generator code while protecting the one-facility + 10–20% rural-well contract.
2. After dead generator code is removed, run focused owning generation/streaming/System-33 regressions rather than the full 12-seed matrix unless explicitly requested.
3. Then continue the streaming debt in evidence order: use the existing phase timings to decide whether full-world rollback snapshots and accumulated materialized WHAT require the next rewrite; do not invent unload/persistence complexity without measurement.
4. Treat the current roadside pole-routing side-hold failure as a **separate pre-existing power bug**. Fix it when power routing is the active task; do not confuse it with private-well completion.
5. Broader game order remains player/world practical closure before combat, then combat, then the first zombies hydrated from actual population records.
