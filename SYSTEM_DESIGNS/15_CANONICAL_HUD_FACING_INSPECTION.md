# 15 Canonical HUD / Facing Inspection

Status: **IMPLEMENTED**

Approved originally by the user on 2026-08-16 and subsequently simplified by explicit player-UI direction through 2026-09-05. The current contract is a compact top-screen `Looking at:`/status presentation that reports real canonical state without competing with the active movement or vehicle controls, plus compact camera/map controls immediately above the locomotion footprint.

## 1. Goal

Present only real canonical player/world state in a compact, phone-readable HUD:

- authoritative world tick;
- current N/E/S/W facing;
- one-cell-ahead `Looking at:` physical inspection;
- HP and fatigue as textual status truth;
- sustainment/carry/moodlet summaries;
- latest movement/action result;
- a read-only generated-island map with the canonical player location.

This is presentation/read composition. It creates no gameplay truth.

## 2. Current player-facing layout contract

Newest explicit user direction supersedes the older lower-HUD and vital-bar arrangements.

### Top inspection/status area

- `CanonicalStatusHud.gd` owns a `LookingAtPanel` beginning at approximately `y = 66`.
- The panel sits directly below the top **STATS / INVENTORY / MENU** row.
- `Looking at:` is part of this top block and must not return to the lower movement/control footprint.
- Health and Fatigue/Stamina **ProgressBar nodes are retired entirely**. They are not merely hidden or moved elsewhere.
- Authoritative HP/fatigue values remain readable as compact text in the canonical status presentation.
- Sustainment, carry and moodlet truth remain presentation-only reads from canonical simulation state.

### Bottom control area

The lower control footprint is reserved for exactly one locomotion mode at a time:

- **On foot:** `PlayerMovementControls` is visible, including the normal walking controls plus the production **FORAGE** and **ENTER VEHICLE** actions.
- **Mounted:** the entire walking `CanvasLayer` is hidden. A direct `VehicleControlSurface` occupies the same lower-screen footprint.
- The mounted replacement is **not** a `VehiclePanel` and must not be restored as a separate vehicle window.
- Mounted movement/actions include TURN L, FORWARD, TURN R, BRAKE, REVERSE, BACK, EXIT, START, HOTWIRE, REPAIR, ADD RACK, REFUEL and cargo transfer controls.
- Dismounting hides the vehicle surface and restores the ordinary walking surface.

### Camera controls

- Visible **ZOOM -** and **ZOOM +** buttons are retired.
- CENTER/FOLLOW remains available and is dropped down to the row immediately above FORWARD (`y = 574` in the current 720p reference layout), leaving a small non-overlapping gap to the locomotion controls.
- A **MAP** button sits immediately to the right of CENTER/FOLLOW on that same row.
- Because CENTER/MAP live outside the swappable walking/vehicle control surface, they remain available in either locomotion mode.
- The zoom subsystem itself is not retired; gesture/keyboard/controller or other existing non-button zoom routes may continue to use the canonical zoom signals/state.

### Island map overlay

- `IslandMapView.gd` is a read-only player-facing overlay. It does not own navigation, movement, discovery or procedural-generation truth.
- `PlayerMapBootstrap.gd` configures the map after the canonical playable world has booted while preserving `VehicleGameMain.gd` as the production composition root.
- The map uses the active `GeneratedGlobalWorldPlan` bounds, seed and profile plus `IslandSurfaceMath.classify(...)` to rasterize the same deterministic island coastline/land/shore/ocean geometry used by world generation.
- Existing generated `road_segments` and `settlements` are layered from the global plan; no duplicate road or settlement model is created.
- The player marker is resolved from the canonical `WorldState` placement for the playable actor and redraws when world placement changes.
- Opening MAP raises the overlay above ordinary HUD presentation; CLOSE/MAP toggle returns to the normal HUD without mutating world state.
- The current island raster is generated lazily at a bounded `256 x 256` presentation resolution rather than scanning/materializing the live world.

## 3. Non-goals

System 15 does **not** own or mutate:

- movement or vehicle movement rules;
- Stats/Inventory simulation truth;
- interaction consequences;
- health, needs, fatigue or carry progression;
- perception/LOS/darkness knowledge filtering;
- camera zoom rules;
- procedural generation or generated map topology.

Those remain with their canonical owners. This system only presents their public/read-only state.

## 4. Owners

### `game/scripts/ui/FacingInspectionQuery.gd`

Read-only physical inspection query over WHAT.

Given a stable actor ID it reads actor placement, computes the one-cell-forward target from canonical facing, and reports the highest-priority physical fact in that cell.

Priority remains:

1. STRUCTURE;
2. OBJECT;
3. ACTOR;
4. LOOSE_ITEM;
5. terrain;
6. Unknown when no known physical fact exists.

This is deliberately **not** a perception system. A future vision/perception layer may filter the result without moving world truth into the HUD.

### `game/scripts/ui/ActorStatusSummaryQuery.gd`

Read-only canonical status composer. It consumes public Health, Needs, Carry and Moodlet reads and returns summary truth for the requested actor. It owns no stored actor state and performs no mutations.

### `game/scripts/ui/CanonicalStatusHud.gd`

CanvasLayer presentation owner for the top status/inspection block.

Public surface:

- `configure(kernel, status_query, inspection_query, actor_id) -> bool`
- `refresh() -> void`
- `present_action_result(intent, success, reason, world_tick) -> void`
- `presentation_snapshot() -> Dictionary`

The HUD never mutates simulation state and does not poll every frame.

### `game/scripts/ui/CameraControls.gd`

CanvasLayer presentation/input owner for CENTER/FOLLOW and MAP. It preserves the pre-existing canonical camera signals and touch/mouse duplicate suppression, owns map open/close presentation state, and delegates map rendering to `IslandMapView`.

### `game/scripts/ui/IslandMapView.gd`

Read-only generated-island presenter. It accepts the active global world plan, canonical world state and playable actor ID, then derives a bounded presentation raster and current marker from those sources. It stores no gameplay topology or player position of its own.

### `game/scripts/ui/PlayerMapBootstrap.gd`

Composition-only adapter used by `main.tscn` to configure the map after the existing `VehicleGameMain` root boots the canonical world. This keeps map composition out of simulation owners and preserves the existing root ownership boundary.

## 5. Demo/runtime state wiring

The playable survivor uses the already-implemented canonical state needed for honest reads:

- Health;
- Needs;
- Hands/equipment;
- actor-root inventory containment;
- physical item/weight truth;
- Carry State / Carry Query;
- Moodlet Service;
- canonical `WorldState` placement;
- active `GeneratedGlobalWorldPlan`.

No fake item, health, need, carry, island or player-location values are created for HUD/map presentation.

Skills are owned by the Stats/player-shell route rather than this compact top HUD.

## 6. Facing-inspection public contract

`query(actor_id: String) -> Dictionary`

Result includes:

- `ok` / `reason`;
- actor anchor/facing;
- target cell;
- semantic type/entity ID when applicable;
- stable human-readable label.

Semantic IDs are converted to readable labels without changing world truth. Structure/object presence wins over underlying terrain in the inspected cell.

## 7. Actor-status public contract

`query(actor_id: String) -> Dictionary`

The summary exposes canonical health/needs/carry/moodlet values appropriate to the active simulation version. `CanonicalStatusHud` formats those values; it does not own them.

The absence of Health/Fatigue ProgressBars does **not** mean health or fatigue state has been removed.

## 8. Update model / performance

No `_process()` HUD/map polling and no frame-driven whole-world scans.

The HUD refreshes at explicit lifecycle/action boundaries and through already-owned update paths. Queries remain read-only. Presentation work is bounded to the player-facing summary and one-cell inspection.

The island surface texture is created lazily once per configured active plan at `256 x 256`; it samples deterministic island math and plan-level road/settlement records rather than live streamed entities. Player-marker redraws follow canonical world-change notifications only while the overlay is visible.

## 9. Dependencies

Allowed:

- WHAT / WHERE reads for facing inspection and player marker;
- WHEN read for current tick;
- canonical Health/Needs/Carry/Moodlet public reads;
- active generated global-plan reads for island bounds/coast/roads/settlements;
- semantic input labels for action-result presentation.

Forbidden:

- direct world/stat mutation from HUD/query/map code;
- movement/collision/vehicle-rule implementation in HUD;
- renderer/art lookup as gameplay truth;
- perception claims;
- generator mutation or a second map/topology model;
- fake/default gameplay truth inside presentation.

## 10. Acceptance contract

Protected player-facing acceptance now requires:

1. main scene and Godot project parse;
2. `LookingAtPanel` exists at the top directly under the player menu row;
3. `Looking at:` remains backed by canonical facing inspection;
4. no `HealthBar` or `FatigueBar` ProgressBar nodes are instantiated;
5. HP/fatigue simulation truth remains available textually;
6. visible `ZOOM -` and `ZOOM +` buttons are absent while CENTER/FOLLOW remains;
7. CENTER/FOLLOW is dropped close to FORWARD without overlap and MAP sits immediately to its right;
8. MAP is configured from the active generated island plan and canonical player placement;
9. opening MAP presents the generated island raster and a player marker, and closing restores normal HUD presentation;
10. on foot, the walking control surface is visible and vehicle controls are absent;
11. mounted, the complete walking CanvasLayer is hidden and direct `VehicleControlSurface` controls occupy the lower walking-control footprint;
12. no separate `VehiclePanel` is instantiated;
13. dismount restores the walking controls and removes the mounted surface;
14. HUD/query/map owners perform no frame polling or simulation mutation;
15. protected startup/Web/Pages checks remain green when executable changes touch this surface.

`PlayerUiCleanupSmoke.gd` protects the current cross-UI layout/map contract; Canonical HUD and camera contracts protect their narrower owners.

## 11. Historical recovery source

Golden `MapPreview.gd` at commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`, blob `8ef5d900e5f56bb557bba496d10acc47438b38de`, remains recovery evidence for the useful one-cell-ahead `Looking at:` concept. Its monolithic input/render/simulation architecture is not restored.

## 12. Verification / implementation record

Original System 15 implementation first landed at `87c8426247b90b83badc300a3c664f1da10f37f5`; hardened original verification head `fb19c7b86569c388dcb251b2b61210e745f3909a` passed the dedicated Canonical HUD Facing Inspection contract.

The September 2026 player-UI cleanup superseded the original lower-gap placement. The corrected executable head `33afe7f459f1cd9d24b493ab935c97b2d4545a35` removes the visible vital bars and Zoom +/- buttons, moves `Looking at:` to the top under the menu row, and replaces walking controls with a direct mounted driving surface in the same bottom footprint. That executable head closed with **44/44 push workflows successful and no failures or pending runs**.

The island-map follow-up executable head `b4d4e59da5f185cce22a990ce9012b77bb1d3d84` drops CENTER/FOLLOW to `y = 574`, adds adjacent MAP, presents the canonical generated island (coast/land/shore plus generated roads/settlements), and marks the canonical player placement. The first composition candidate correctly exposed an existing ownership guard when it changed the root script; the repaired head preserves `VehicleGameMain.gd` as production root and configures the map through `PlayerMapBootstrap.gd`. The repaired executable head closed **47/47 push workflows successful, 0 failed, 0 cancelled**.

## 13. Future seams

- Stats/Inventory may reuse canonical status reads without adding duplicate HUD truth.
- A future perception service may wrap/filter `FacingInspectionQuery` results before presentation.
- Future calendar/time presentation may add a separate WHEN-derived presenter.
- Camera input may continue to expose zoom through non-button routes without restoring the retired Zoom +/- buttons.
- The island map can add additional generated-plan overlays (for example named landmarks or road labels) without creating a second navigation/world model.

## 14. North-star fit

The HUD keeps actionable world/status truth readable while reserving the lower screen for whichever locomotion mode is actually active. CENTER/MAP remain compact and mode-independent, and the map visualizes the same canonical generated island/player truth the simulation already owns. Presentation remains truthful, bounded and replaceable: no fake simulation state, no duplicate locomotion UI, no second map model, and no permanent test panels.