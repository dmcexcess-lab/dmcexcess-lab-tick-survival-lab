# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current checkpoint — generator cleanup part one CLOSED

The first cleanup pass that removed retired hydrology/wastewater/water-network assumptions from the **active production contract** is complete.

### Verified executable boundary

- **Executable:** `90a919ac367f9cf247c8915f065135f2f1592d79` — `Align System 20 CI with retired hydrology contract`.
- `verify/system33-power-water` run `33992117806` — **SUCCESS**.
- `verify/system20-local-area` run `33992117847` — **SUCCESS**; canonical boot passed inside this gate.
- `verify/system00d-global-world` run `33992117848` — **SUCCESS**.
- `verify/pages-deploy` run `33992117751` — **SUCCESS**.
- Do **not** report the whole suite green. Known unrelated red contexts on this line include performance architecture, roadside pole routing, lighting truth, portable generator and flashlight-item checks.

### What part one changed

- Active municipal-water planning now validates the real current behavior rather than requiring old water-node/segment arrays to exist and be empty.
- System 33 runtime no longer depends on `water_nodes` / `water_segments`.
- Active global island validation no longer requires hydrology, river or bridge contracts and no longer treats “rivers must be empty” as a validity condition.
- `IslandWorldPlanner` no longer invokes bridge planning, hydrology queries, river-clearance passes, or projects retired wastewater/water-network compatibility data.
- System 20/local projection supplies current generation with roads, power and municipal-service facts only; it no longer projects fake potable pipe/node corridors or active hydrology/wastewater constraints.
- The active System 20 rural-open gate no longer expects a regional river. Useful agriculture/seam/road coverage remains.
- Current potable-water documentation now states that the retired arrays are outside the active contract rather than empty requirements.

Part one deliberately stopped short of deleting historical source files and compatibility storage. That physical deletion is **part two**.

## Protected potable-water contract

### Municipal

- Exactly one authoritative island-wide municipal facility, stable identity `water.facility.island`.
- The facility is one already-generated real building; current planner prefers `civic.post_office.small` at the host site with deterministic fallback.
- Settlement `water_services` are lightweight aliases to that same facility, not separate plants.
- No municipal pipe/node graph, pressure model, service radius, distribution topology or duplicate treatment shell.
- Municipal facility has no external-grid dependency.
- Facility failure removes municipal water island-wide; repair restores it.

### Rural private wells

- Deterministically select **10–20% of all generated buildings on `rural.*` sites**.
- Town/non-rural buildings never receive wells.
- One well max per selected building; identity is stable from world seed + building ID.
- Stable IDs remain `water.physical.well.<building_id>`, `water.component.well.<building_id>`, `water.service.well.<building_id>`.
- Physical well cap is a persistent adjacent WHAT entity using `prop.manhole`.
- A selected building's private well is its authoritative source even while broken.
- Healthy well survives municipal outage; broken well leaves that building dry and **does not fall back to municipal water**.
- Wells have no external-grid dependency.
- Well repair costs 1 maintenance material; municipal repair costs 3.
- Snapshot schema 3 preserves condition and rebuilds the derived well-building index on restore.

### Wastewater

Wastewater/sewer/septic remains retired. Do not resurrect it to satisfy stale code, tests or docs. `SYSTEM_DESIGNS/00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is a tombstone/historical guardrail only.

## Generator / streaming state to preserve

Already implemented:

- 128×128 technical stream regions, radius 1;
- source discovery cached/indexed by stream region;
- boundary updates discover entering strips rather than the full 3×3 neighborhood;
- already-materialized handles are prefiltered;
- discovery/preparation/snapshot/commit timing instrumentation;
- bounded directional look-ahead near region edges, max one new logical source per movement step;
- render-window recenter timing and PERF DEV reporting;
- reduced/cached immutable catalog validation.

Remaining streaming debt after the generator cleanup:

- full-world rollback snapshots still scale with explored/materialized world state;
- distant immutable base WHAT unloading/dematerialization plus persisted deltas is not implemented;
- use existing phase timings before deciding the next rewrite; do not invent persistence complexity without evidence.

## Density/world scale to preserve

Reference seed 20001 checkpoint:

- 306 buildings;
- 286 residential building records;
- 1,002 residents;
- two towns, three compact crossroads, six rural lane sites;
- population is building-derived; infected + survivors equals residential capacity;
- no fake population multiplier or fake zombie-count source.

Do not run the old 12-seed matrix on every edit. `README_SOPS.md` records the focused-test rule; normal work uses focused owner/protected regressions and the reference seed unless broader testing is explicitly justified.

## Player/world priority after generator cleanup

The broader order remains:

1. finish rendering/player/world/object interaction/UI practicality;
2. combat;
3. first zombies hydrated from real population records.

A simulation feature is not player-complete until ordinary gameplay UI provides a truthful route to its owning action and state.

Preserve existing practical closures for exact-item inventory actions, first aid, flashlight state, door/window access/boarding/climb-through, vehicle ignition/hotwire truth, sleep/rest, crafting/deconstruction/search, utility-backed refrigeration/lighting, automatic day/night/weather, and the four skills Awareness/Stealth/Mechanical/Survival.

## Protected architecture

Preserve:

- decision-pause input locking / no movement backlog;
- WHERE / WHAT / WHEN ownership boundaries;
- one production interaction chooser;
- exact WHEN terminal semantics;
- no frame-driven simulation loops or recurring whole-world scans;
- no UI-owned fake gameplay truth;
- building-derived population;
- no wastewater resurrection;
- no municipal water pipe graph;
- no private-well municipal fallback.

Production inheritance remains `VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`; flattening is separate work.

## NEXT OPERATION — PART TWO

The user explicitly ordered: **close part one, then complete part two.** Part one is closed by this handoff.

Part two:

1. Delete retired hydrology/river/watercourse/wastewater implementation files that have no remaining live owner.
2. Remove transitional `GeneratedGlobalWorldPlan` compatibility storage for rivers/bridges/water topology/wastewater and all dead signature/serialization/projection references.
3. Remove dead local projection adapters and dead physical-water helpers such as `_water_plant_records()` if still present.
4. Remove or retire stale CI/workflow code whose only purpose is the deleted river/watercourse/wastewater contract. Do not resurrect retired behavior to make old tests pass.
5. Treat bridge code carefully: delete river-only bridge compatibility, but preserve any current road feature that is independently required.
6. Search the resulting live source tree for `river`, `hydrology`, `watercourse`, `bridge`, `wastewater`, `water_nodes`, `water_segments`, and `_water_plant_records`; classify every remainder as legitimate current code, tombstone documentation, or remove it.
7. Run focused `system00d-global-world`, `system20-local-area`, `system33-power-water`, canonical boot/generation checks, and Pages on the exact executable head. Do not run the full 12-seed matrix unless explicitly requested.
8. Finish with updated design docs and a mandatory final `README_CONTEXT.md` handoff.

Treat the roadside-pole side-hold failure as a separate pre-existing power-routing defect, not part of this cleanup.
