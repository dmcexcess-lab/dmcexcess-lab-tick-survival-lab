# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current checkpoint — dirt-road traversal repair CLOSED

- **Verified executable:** `86b201c24f867b5d823633f3f83ae7de982b92e6`.
- **51/51 GitHub Actions workflows succeeded**, no failures or pending runs for that executable.
- **Pages SUCCESS:** https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/actions/runs/33999144142
- **Play:** https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
- Closing commit is documentation-only. Local executable candidate `206fcc7` has the same tree `dd7ec42d4433364ddd54cbe3ffbcd3b20eeac61d` as the published executable.
- Standing direct-main/Pages authorization remains in the SOP; do not ask again.

### Completed in this continuation

- Repaired the user-reported impassable dirt road. `ground.dirt_road` is now registered as traversable by the production generated-world movement rules.
- Registered generated four-lane white-divider terrain as traversable so the markings cannot create invisible movement barriers.
- Yellow and white road-marking cells now participate in live and remembered road-neighbor topology, preventing painted cells from visually breaking adjoining pavement.
- Complete-island generation/replay explicitly proves the new generated terrain types are traversable. Movement, ground renderer and reference-seed playable boot checks passed locally.
- Added up to eight nearest unused settlement-pair connections beyond the road tree.
- Road types survive global planning, local projection and surface materialization: four-lane paved (two each way), two-lane paved (one each way), single-lane gravel and single-lane dirt.
- Four-lane routes paint dashed white lane dividers around the yellow directional centerline. Unpaved surfaces do not paint centerlines. Legacy primary/secondary frontage classes remain.
- Fixed rural branch anchors on partially overlapping collinear approaches; shared route pavement is not a crossing at every cell.
- Removed leftover deleted-hydrology dependencies and river exclusions from CountrysideSourceCatalog and its smoke contract, preserving coverage/materialization/revisit/rollback checks.
- Population-generation errors now retain the local failure reason.
- Local complete-island generation/replay, power/water, alternate-seed legacy seam, countryside materialization and canonical boot passed.
- Initial published candidate `b708ba4` had two CI failures; both repaired in the verified executable above.
- Cached Godot binary was damaged and crashed even on --version. A fresh official 4.7.1 executable resolved this; no current tooling blocker remains.
- No browser FPS or long-distance memory performance claim is made. Human appearance/lag acceptance remains pending.

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

Reference seed 20001 after road expansion:

- **627 physical buildings, 2,184 residents**;
- infected allocation **1,929** + survivor allocation **255** equals residents;
- two towns, three compact crossroads, thirty sparse rural sites;
- island bounds remain 3072×3072; technical streaming radius/size remain unchanged;
- population is building-derived, with no fake multiplier or spawned zombies.

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

## NEXT OPERATION

1. User playtests dirt-road traversal and completes the unfinished feedback that ended with “and”. Then adjust from the concrete remainder.
2. Continue testing the deployed road/density build: four road types, alternate journeys, rural proportions, and movement lag.
3. No CI or publication work remains for this executable. Keep normal seed checks focused; the full twelve-seed matrix remains explicit opt-in.
4. Preserve the completed river/wastewater/water-graph removal and protected municipal/private-well contract above. Do not restart old cleanup steps from historical handoffs.
5. Continue rendering/player/world interaction closure before combat and NPC/zombie work, as directed. Future zombies consume actual population records.
6. Whole-world rollback snapshots, distant immutable unloading/persisted deltas, and human browser/iPhone acceptance remain open; this repair does not claim to solve them.
