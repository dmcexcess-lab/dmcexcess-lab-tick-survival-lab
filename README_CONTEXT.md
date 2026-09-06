# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current checkpoint — vehicle/equipment/apparel pass landed; player-facing loadout UI remains

- **Vehicle/equipment/apparel implementation head:** `a74c60ea848a35e314c6606a197af6db36abf61b`.
- **Executable gameplay head after compile-boundary repair:** `05f2308d83804ed2547214074a7a23bc149f6750`.
- `05f2308` fixes one import-time type typo in `TacticalRendererStack.gd` (`WorldInteractableStateRenderer` → the actual `WorldInteractionStateRenderer`). The initial broad failures on `a74c60e` were caused by that project-import compile error; they were not simulation/regression failures.
- Exact-head verification of `05f2308` reached terminal state across **53 GitHub Actions runs** with **0 failed, 0 cancelled, 0 queued and 0 in-progress** at closure.
- The earlier endpoint-driven island-road hierarchy remains closed and protected; executable road fix `f7cd362310cdabf3a827bd33b5c5d9628e3bc423`, exact-tree re-verification `a312a590fc6ce4eb511ebbb8d4e2bec06c240f69` with 52/52 terminal success.
- **Play:** https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
- Standing direct-main/Pages authorization remains in the SOP; do not ask again.

### Vehicle / equipment / apparel checkpoint

- Skateboard straight movement remains **2 cells forward/back** according to its vehicle profile.
- Skateboard steering is now a **90° heading change on the current cell**; turning does not also translate the board two cells.
- **All vehicles must brake/stop before reversing.** A reverse request while moving is rejected with `vehicle_brake_before_reverse`; reversing is not a direct direction flip while under motion.
- Skateboard is a real persistent item semantic: `item.vehicle.skateboard`.
- The same physical skateboard transitions between **loose-item occupancy when parked/dropped**, **vehicle occupancy while ridden**, and loose-item occupancy again on dismount. Do not materialize a duplicate board for equipment/pickup.
- Skateboard legal equipment slots are **right hand, left hand or back only**.
- Skateboard may not be stored in the actor's personal/backpack containment; rejected storage uses `skateboard_requires_hand_or_back`.
- Authoritative equipment slots now exist for **right hand, left hand, back, head, torso, legs, feet and hands**. Equipment is an exclusive physical-item disposition, not an item simultaneously duplicated inside inventory.
- Actor presentation can render floating/attached equipment from the authoritative slot assignments for **both hands and back**.
- Actor presentation also applies clothing/hat paper-doll overlays from authoritative worn equipment instead of maintaining a separate cosmetic truth.
- Current apparel semantics include baseball cap, beanie, T-shirt, hoodie, work jacket, jeans, cargo pants, sneakers, work boots and work gloves.
- The production vehicle renderer contains **no separate front/heading-indicator overlay**. No distinct purple-front marker source was found in the current renderer/SVG path during this pass, so do not claim an asset was removed; if one is still visibly present in the playable build, capture the vehicle/type/location and trace that actual source.

### Protected apparel protection model

The user explicitly simplified clothing protection. Preserve this exact model unless later direction changes it:

- `bite_cut_armor`
- `blunt_ballistic_armor`
- `water_resistance`

Retired from apparel/equipment truth:

- `armor_bite`
- `armor_cut`
- `armor_blunt`
- `insulation`
- `wind_resistance`

Do not reintroduce separate bite vs cut, separate blunt vs ballistic, insulation, or wind resistance merely because older notes/tests mention them. `ActorEquipmentProtectionQuery.gd` aggregates only the two merged armor values plus water resistance, capped at 100. `ActorHandEquipmentSmoke.gd` has focused regression coverage for the merged-stat contract, retired-key absence, skateboard slot restrictions and representative worn-equipment aggregation.

### Remaining player-facing gap from this checkpoint

The underlying equipment state and renderer now understand back/worn slots, but the ordinary player Inventory/loadout surface is still legacy-oriented:

- `ActorInventoryInspectorQuery.gd` currently serializes only the two hand slots plus inventory/carry truth.
- `CanonicalPlayerShell.gd` currently exposes RIGHT HAND / LEFT HAND / STOW / DROP-style actions, not ordinary equip/unequip actions for back/head/torso/legs/feet/hands.
- The player shell does not yet expose the merged `bite_cut_armor`, `blunt_ballistic_armor` and `water_resistance` totals.

Therefore this pass is **not yet player-complete** under the project's UI practicality rule. The next implementation should extend the existing inventory/loadout route rather than inventing a second cosmetic equipment UI.

## Road contract now expected in the playable island

- **Gateway routes:** four-lane paved, two lanes each direction.
- **Town-touching routes:** paved two-lane unless the route is a gateway.
- **One-light-crossroads-touching routes:** paved two-lane unless the route is a gateway.
- **Rural hamlet ↔ rural hamlet:** may be gravel or dirt.
- **Alternate links/loops:** classify from their actual endpoint settlement types; they do not get a special pavement exemption.
- Dirt and gravel are single-lane rural roads and remain traversable.
- Human visual acceptance of the generated road density/mix remains useful, but the endpoint classification itself is regression-protected and closed.

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

1. **Finish the ordinary Inventory/loadout UI for the generalized equipment state.** Extend the existing player inventory route so items can be equipped/unequipped to back, head, torso, legs, feet and hands as well as right/left hand. Do not create a second cosmetic equipment truth.
2. Expose truthful equipped protection totals in ordinary gameplay UI: `bite_cut_armor`, `blunt_ballistic_armor`, and `water_resistance`. Do not restore insulation, wind resistance, separate bite/cut, or separate blunt/ballistic stats.
3. Exercise the complete skateboard user path in production UI/gameplay: dismount → loose item → pick up/equip to either hand or back → backpack/personal storage rejected → return to world/mount the same physical board. Verify straight skateboard travel remains 2 cells, 90° turns stay on one cell, and all vehicle families require braking/stopping before reverse.
4. If a purple/front vehicle marker is still visibly present, capture the actual vehicle/type/location and trace the rendering/asset source; current production renderer has no explicit heading overlay and this checkpoint does not invent a removal target.
5. Continue the standing full player/world/object-interaction/UI practicality audit and close every backend-only or debug-only gameplay route before combat.
6. After the player/world/UI layer is practical end-to-end: implement combat, then hydrate the first real zombies from existing building-derived population records.
7. Preserve the closed road hierarchy and continue human visual acceptance only as needed for island feel; do not reopen its endpoint classification without a concrete mismatch.
8. Preserve the completed river/wastewater/water-graph removal, municipal/private-well contract, streaming boundaries, decision-pause semantics, and building-derived population.
