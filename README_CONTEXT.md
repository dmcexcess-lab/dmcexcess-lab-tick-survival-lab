# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current checkpoint — endpoint-driven island road hierarchy CLOSED

- **Executable road fix:** `f7cd362310cdabf3a827bd33b5c5d9628e3bc423`.
- **Exact-tree CI re-verification head:** `a312a590fc6ce4eb511ebbb8d4e2bec06c240f69`.
- `a312a59` is an empty re-verification commit with the **same tree** (`35d6b403b8a2df288d8dcd52302e5b56d0dfbc0f`) as `f7cd362`; it contains no gameplay/code change.
- **52/52 GitHub Actions checks reached terminal success** on `a312a59`; there were no failures or pending checks at closure.
- **Global World Planning SUCCESS** on the exact-tree re-verification: https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/actions/runs/34000866485
- **Pages SUCCESS** on the exact-tree re-verification: https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/actions/runs/34000866519
- **Play:** https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
- The first exact-head run on `f7cd362` had one infrastructure failure in Global World Planning at **Install Godot 4.7.1**, before any Godot/test step ran. The identical-tree re-verification succeeded; no code change was needed for that runner/download failure.
- Standing direct-main/Pages authorization remains in the SOP; do not ask again.

### Completed in this continuation

- Replaced the old route-family/legacy-primary paving behavior with **endpoint-driven road hierarchy**.
- Any generated route touching either a **town** or a **one-light crossroads** is paved.
- Only **rural-to-rural** settlement links may become gravel or dirt.
- Island gateway approaches remain **four-lane paved**.
- Ordinary paved settlement routes remain **two-lane paved**; assigning primary hierarchy for pavement does not turn them into gateway-width roads.
- Alternate/loop links use the same endpoint-driven classification as tree links instead of receiving pavement merely because their route ID belongs to an alternate family.
- Added focused one-seed `IslandRoadHierarchySmoke.gd` regression coverage for gateway four-lane routes, town/crossroads paved routes, rural-only unpaved eligibility, and alternate-link endpoint classification.
- Wired that focused regression into the owning **Global World Planning** workflow.
- The old twelve-seed matrix was **not** restored. Normal edits remain reference-seed + focused owner/protected regressions unless broader testing is specifically justified.
- Protected movement, streaming, population, power and potable-water behavior were not intentionally changed by this road-hierarchy repair.
- Human visual acceptance of the generated road mix remains the next checkpoint; CI verifies generated classifications/contracts, not whether the island looks right to the user.

## Road contract now expected in the playable island

- **Gateway routes:** four-lane paved, two lanes each direction.
- **Town-touching routes:** paved two-lane unless the route is a gateway.
- **One-light-crossroads-touching routes:** paved two-lane unless the route is a gateway.
- **Rural hamlet ↔ rural hamlet:** may be gravel or dirt.
- **Alternate links/loops:** classify from their actual endpoint settlement types; they do not get a special pavement exemption.
- Dirt and gravel are single-lane rural roads and remain traversable.

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

1. **User visual acceptance of the deployed road hierarchy.** Inspect the playable island and verify that gateway approaches are four-lane, routes reaching either town or any one-light crossroads are paved two-lane, and gravel/dirt appear only on rural-to-rural links.
2. Specifically inspect alternate/loop journeys: an alternate touching a town/crossroads must be paved; a rural-to-rural alternate may be gravel/dirt. If a mismatch is visible, capture the seed plus the route/endpoints or visible location pattern and make a targeted generator fix.
3. Continue evaluating whether the overall road density/mix still feels like scattered rural and one-light-town geography rather than over-roaded suburbia. Classification is closed; appearance remains human acceptance.
4. After road visual acceptance, return to the standing priority: rendering/player/world/object-interaction/UI practicality, then combat, then the first zombies hydrated from real population records.
5. Preserve the completed river/wastewater/water-graph removal and protected municipal/private-well contract above. Do not restart old cleanup steps from historical handoffs.
6. Whole-world rollback snapshots, distant immutable unloading/persisted deltas, and human browser/iPhone performance acceptance remain open; this road repair does not claim to solve them.
