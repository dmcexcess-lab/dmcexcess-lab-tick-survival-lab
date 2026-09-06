# Tick Survival Lab — Current Handoff

Last updated: **2026-09-05**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current checkpoint — canonical island map HUD closed; generalized loadout UI remains

- **Current executable gameplay head:** `b4d4e59da5f185cce22a990ce9012b77bb1d3d84`.
- Exact executable-head verification for `b4d4e59d` closed with **47/47 push workflows successful, 0 failed, 0 cancelled, 0 queued and 0 in-progress**.
- HUD/map design documentation commit: `173617e77adfba7c8889101726c9ca75cdc5880d` (`SYSTEM_DESIGNS/15_CANONICAL_HUD_FACING_INSPECTION.md`).
- Player-UI/map changelog commit: `fa44d9790ea59ab423bbee37afe72c48f2f73657` (`CHANGELOG_PLAYER_UI_CLEANUP.md`).
- The first island-map composition candidate `ab5abb518d9c5fd9cc990819e848c8811294c300` is **superseded**. It changed the production scene root and was correctly rejected by existing ownership guards before Godot execution. Do not restore that root subclass.
- Prior corrected HUD/driving executable head `33afe7f459f1cd9d24b493ab935c97b2d4545a35` closed with 44/44 push workflows successful before this map follow-up.
- Prior apparel/catalog executable checkpoint `da35f843020f32740b46dbfb944e3c85f363467d` closed with 44/44 push workflows successful.
- Endpoint-driven island-road hierarchy remains closed and protected; executable road fix `f7cd362310cdabf3a827bd33b5c5d9628e3bc423`, exact-tree re-verification `a312a590fc6ce4eb511ebbb8d4e2bec06c240f69` with 52/52 terminal success.
- **Play:** https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
- Standing direct-main/Pages authorization remains in the SOP; do not ask again.

## Protected player HUD / control / map contract

Preserve this exact current player-facing contract unless later explicit direction changes it.

### Retired player-facing windows/options

- Standalone **Survival** player window is retired. Do not restore it. Condition, sustainment, exact-item eating/drinking, first aid, rest/sleep and related simulation truth remain authoritative through ordinary inventory/world interactions.
- Standalone **Forage** panel is retired. Do not restore it. **FORAGE** lives on the on-foot bottom control surface and calls `ForageNearbyActionService`.
- Player-visible **Dev** window is retired. Do not restore it. Performance telemetry and diagnostic snapshots remain internal; production renderer must not instantiate `PerformanceDevPanel` during ordinary gameplay.
- Visible **ZOOM -** and **ZOOM +** buttons are retired. Do not restore them merely because camera zoom still exists through non-button input routes/signals.
- Health and Fatigue/Stamina **ProgressBars are retired entirely**. Do not recreate or move replacement bars. Health/fatigue simulation truth remains authoritative and readable as compact status text.

### Top status / Looking At presentation

- `CanonicalStatusHud.gd` owns `LookingAtPanel` beginning at approximately **`y = 66`**, directly below **STATS / INVENTORY / MENU**.
- `Looking at:` belongs in this top block. Do not return it to the lower movement/driving-control area.
- Tick, action result, facing, Looking At, health/fatigue text, sustainment/carry/moodlet truth remain presentation-only reads from canonical simulation state.
- HUD owns no gameplay truth and must not add frame-driven polling.

### CENTER / MAP row

- CENTER/FOLLOW remains visible and canonical; it was **moved down**, not removed.
- In the 720p reference layout CENTER/FOLLOW is at approximately **`x = 182, y = 574`**, size `132 x 52`.
- Walking FORWARD begins at `y = 638`, leaving a **12 px non-overlapping vertical gap** below the CENTER/MAP row.
- **MAP** sits immediately to the right at approximately **`x = 326, y = 574`**, same size.
- CENTER/MAP are outside the walking/vehicle swappable surface, so they remain available whether on foot or mounted.
- Opening MAP raises a full-screen overlay above ordinary HUD presentation; MAP toggle or CLOSE returns to the normal HUD.
- Underlying non-button camera zoom remains available; visible Zoom +/- buttons stay retired.

### Canonical island map

- `IslandMapView.gd` is a **read-only presentation overlay**. It does not own movement, navigation, discovery, world topology or procedural generation.
- `PlayerMapBootstrap.gd` is a composition-only child in `main.tscn`; it configures the map after canonical world boot while preserving `VehicleGameMain.gd` as the required production root.
- Production inheritance remains `VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`. Do not introduce a map-specific root subclass.
- The map uses the active `GeneratedGlobalWorldPlan` bounds, seed and profile plus `IslandSurfaceMath.classify(...)` to rasterize the **same deterministic island geometry contract** used by generation.
- It layers the active global plan's generated `road_segments` and `settlements`; it does not rediscover topology from streamed entities or maintain a duplicate map model.
- Player location marker comes from canonical `WorldState.placement(GeneratedIslandCritiqueFixture.PLAYER_ID)` and redraws from world-change notification while visible.
- Island surface raster is generated lazily at bounded **256 x 256** presentation resolution; no frame-driven whole-world scan is introduced.
- `PlayerUiCleanupSmoke.gd` protects map configuration, nonzero generated bounds, canonical player marker, CENTER/MAP adjacency and spacing, open/close state, overlay layer restoration and deterministic surface texture materialization.

### On-foot versus mounted bottom controls

Invariant: **no vehicle controls while on foot; no walking controls while mounted.**

- **On foot:** `PlayerMovementControls` is the only locomotion/action surface in the lower footprint. It includes FORAGE, FORWARD, ENTER VEHICLE, TURN L, TURN R, CROUCH/STAND, BACK and RUN.
- **ENTER VEHICLE** is wired to production `VehiclePlayerController`.
- **Mounted:** the entire walking `PlayerMovementControls` CanvasLayer is hidden.
- Direct `VehicleControlSurface` in `VehiclePlayerControls.gd` replaces walking controls in the **same lower-screen footprint**.
- There is **no `VehiclePanel`** and no separate mounted vehicle window. Do not resurrect one.
- Mounted replacement includes TURN L, FORWARD, TURN R, BRAKE, REVERSE, BACK plus EXIT, START, HOTWIRE, REPAIR, ADD RACK, REFUEL, cargo selectors, STORE → and ← TAKE.
- Dismounting hides the vehicle surface and restores ordinary walking controls.
- UI does not own vehicle movement/action truth.
- Production walking-control node remains named `Controls`.

## Vehicle / equipment / apparel checkpoint

- Vehicle/equipment/apparel aggregate implementation began at `a74c60ea848a35e314c6606a197af6db36abf61b`; compile/catalog/icon contract repairs closed at `da35f843020f32740b46dbfb944e3c85f363467d` before HUD/map work.
- Skateboard straight movement remains **2 cells forward/back**.
- Skateboard steering is a **90° heading change on the current cell**; turning does not also translate two cells.
- **All vehicles must brake/stop before reversing.** Reverse while moving is rejected with `vehicle_brake_before_reverse`.
- Skateboard is persistent semantic `item.vehicle.skateboard`; the same physical board transitions between loose-item occupancy and ridden vehicle occupancy. Do not duplicate it.
- Skateboard legal equipment slots are **right hand, left hand or back only**; actor personal/backpack containment rejects it with `skateboard_requires_hand_or_back`.
- Authoritative equipment slots: **right hand, left hand, back, head, torso, legs, feet, hands**. Equipment is exclusive physical-item disposition, not duplicated inventory truth.
- Actor presentation uses authoritative hand/back assignments and worn equipment for paper-doll overlays.
- Current apparel semantics include baseball cap, beanie, T-shirt, hoodie, work jacket, jeans, cargo pants, sneakers, work boots and work gloves.

### Protected apparel protection model

Preserve exactly:

- `bite_cut_armor`
- `blunt_ballistic_armor`
- `water_resistance`

Retired:

- `armor_bite`
- `armor_cut`
- `armor_blunt`
- `insulation`
- `wind_resistance`

Do not reintroduce split bite/cut, split blunt/ballistic, insulation or wind resistance. `ActorEquipmentProtectionQuery.gd` aggregates only the two merged armor values plus water resistance, capped at 100.

### Remaining player-facing equipment gap

Underlying state and renderer understand back/worn slots, but ordinary Inventory/loadout remains legacy-oriented:

- `ActorInventoryInspectorQuery.gd` currently serializes only two hand slots plus inventory/carry truth.
- `CanonicalPlayerShell.gd` currently exposes RIGHT HAND / LEFT HAND / STOW / DROP-style actions, not ordinary equip/unequip actions for back/head/torso/legs/feet/hands.
- Player shell does not yet expose merged `bite_cut_armor`, `blunt_ballistic_armor`, `water_resistance` totals.

This remains the clearest player-facing closure after HUD/map work. Extend the existing Inventory/loadout route rather than inventing a second cosmetic equipment UI.

## Road contract now expected in the playable island

- **Gateway routes:** four-lane paved, two lanes each direction.
- **Town-touching routes:** paved two-lane unless gateway.
- **One-light-crossroads-touching routes:** paved two-lane unless gateway.
- **Rural hamlet ↔ rural hamlet:** may be gravel or dirt.
- **Alternate links/loops:** classify from actual endpoint settlement types; no special pavement exemption.
- Dirt and gravel are single-lane rural roads and remain traversable.
- Human visual acceptance of road density/mix remains useful, but endpoint classification is regression-protected and closed.

## Protected potable-water contract

### Municipal

- Exactly one authoritative island-wide municipal facility, stable identity `water.facility.island`.
- Facility is one already-generated real building; current planner prefers `civic.post_office.small` at host site with deterministic fallback.
- Settlement `water_services` are lightweight aliases to that same facility, not separate plants.
- No municipal pipe/node graph, pressure model, service radius, distribution topology or duplicate treatment shell.
- Facility has no external-grid dependency.
- Facility failure removes municipal water island-wide; repair restores it.

### Rural private wells

- Deterministically select **10–20% of all generated buildings on `rural.*` sites**.
- Town/non-rural buildings never receive wells.
- One well max per selected building; identity stable from world seed + building ID.
- Stable IDs remain `water.physical.well.<building_id>`, `water.component.well.<building_id>`, `water.service.well.<building_id>`.
- Physical well cap is a persistent adjacent WHAT entity using `prop.manhole`.
- Selected building's private well is authoritative even while broken.
- Healthy well survives municipal outage; broken well leaves that building dry and **does not fall back to municipal water**.
- Wells have no external-grid dependency.
- Well repair costs 1 maintenance material; municipal repair costs 3.
- Snapshot schema 3 preserves condition and rebuilds derived well-building index on restore.

### Wastewater

Wastewater/sewer/septic remains retired. Do not resurrect it to satisfy stale code/tests/docs. `SYSTEM_DESIGNS/00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is historical/tombstone only.

## Generator / streaming state to preserve

Already implemented:

- 128×128 technical stream regions, radius 1;
- source discovery cached/indexed by stream region;
- boundary updates discover entering strips rather than full 3×3 neighborhood;
- already-materialized handles prefiltered;
- discovery/preparation/snapshot/commit timing instrumentation;
- bounded directional look-ahead near region edges, max one new logical source per movement step;
- render-window recenter timing and PERF/dev reporting through internal telemetry;
- reduced/cached immutable catalog validation.

Remaining streaming debt:

- full-world rollback snapshots still scale with explored/materialized world state;
- distant immutable base WHAT unloading/dematerialization plus persisted deltas is not implemented;
- use existing phase timings before deciding the next rewrite.

## Density/world scale to preserve

Reference seed 20001 after road expansion:

- **627 physical buildings, 2,184 residents**;
- infected allocation **1,929** + survivor allocation **255** = residents;
- two towns, three compact crossroads, thirty sparse rural sites;
- island bounds remain 3072×3072; technical streaming radius/size unchanged;
- population is building-derived, with no fake multiplier or spawned zombies.

Do not run the old 12-seed matrix on every edit. `README_SOPS.md` records focused-test rules; normal work uses focused owner/protected regressions and the reference seed unless broader testing is explicitly justified.

## Player/world priority

Broader order remains:

1. finish rendering/player/world/object interaction/UI practicality;
2. combat;
3. first zombies hydrated from real population records.

A simulation feature is not player-complete until ordinary gameplay UI provides a truthful route to its owning action/state.

Preserve practical closures for exact-item inventory actions, first aid, flashlight state, door/window access/boarding/climb-through, vehicle ignition/hotwire truth, sleep/rest, crafting/deconstruction/search, utility-backed refrigeration/lighting, automatic day/night/weather, and skills Awareness/Stealth/Mechanical/Survival.

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
- no private-well municipal fallback;
- no retired standalone Survival/Forage/player-visible Dev windows;
- no visible Zoom +/- buttons;
- no Health/Fatigue ProgressBars;
- top `LookingAtPanel` below menu row;
- mutually exclusive on-foot/mounted bottom control surfaces;
- no separate `VehiclePanel`;
- CENTER/FOLLOW moved close to FORWARD, not removed;
- adjacent MAP uses canonical generated-plan/world reads only;
- `VehicleGameMain.gd` remains the production root; no map-specific root subclass.

## NEXT OPERATION

1. **Finish the ordinary Inventory/loadout UI for generalized equipment state.** Extend the existing player inventory route so items can be equipped/unequipped to back, head, torso, legs, feet and hands as well as right/left hand. Do not create a second cosmetic equipment truth.
2. Expose truthful equipped protection totals in ordinary gameplay UI: `bite_cut_armor`, `blunt_ballistic_armor`, `water_resistance`. Do not restore retired protection stats.
3. Exercise complete skateboard user path in production UI/gameplay: dismount → loose item → pick up/equip to either hand or back → backpack/personal storage rejected → return to world/mount the same physical board. Verify straight travel remains 2 cells, 90° turns stay on one cell, and all vehicles require braking/stopping before reverse.
4. Continue standing full player/world/object-interaction/UI practicality audit and close backend-only/debug-only gameplay routes before combat. Preserve the corrected HUD, CENTER/MAP row, canonical island map and mutually exclusive on-foot/mounted controls.
5. If a purple/front vehicle marker is still visibly present, capture actual vehicle/type/location and trace rendering/asset source; current production renderer has no explicit heading overlay and this checkpoint does not invent a removal target.
6. After player/world/UI layer is practical end-to-end: implement combat, then hydrate first real zombies from existing building-derived population records.
7. Preserve closed road hierarchy; continue human visual acceptance only as needed for island feel, and do not reopen endpoint classification without concrete mismatch.
8. Preserve completed river/wastewater/water-graph removal, municipal/private-well contract, streaming boundaries, decision-pause semantics, building-derived population and all protected HUD/map/control invariants above.
