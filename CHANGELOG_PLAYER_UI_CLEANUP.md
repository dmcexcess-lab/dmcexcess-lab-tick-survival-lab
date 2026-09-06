# Tick Lab — Player UI Cleanup

Date: 2026-09-05

## Closed

- Retired the standalone **Survival** player window. Authoritative condition, sustainment, exact-item inventory consumption and first-aid systems remain intact.
- Retired the standalone **Forage** panel. **FORAGE** is now an on-foot bottom action wired directly to the existing `ForageNearbyActionService`.
- Retired the player-visible **Dev** window. Performance telemetry and diagnostic snapshots remain available internally; the production renderer no longer instantiates `PerformanceDevPanel`.
- Moved **ENTER VEHICLE** to the on-foot bottom action strip and wired it to the production `VehiclePlayerController`.
- Retired visible **ZOOM -** and **ZOOM +** buttons. CENTER/FOLLOW remains, and the underlying zoom subsystem/signals remain available to non-button input routes.
- Removed the Health and Fatigue/Stamina **ProgressBars entirely**. Authoritative health/fatigue values remain available as compact textual status truth.
- Moved the canonical `Looking at:`/status presentation to the top of the screen, beginning around `y = 66` directly below the **STATS / INVENTORY / MENU** row.
- Added and extended `PlayerUiCleanupSmoke.gd` plus protected HUD/camera workflow coverage for the cleaned player-facing contract.
- Updated the Performance Architecture workflow so it protects the absence of a renderer-created Dev panel while retaining the telemetry architecture.
- CI previously caught and fixed the real scene-node hookup error (`Controls`, not `PlayerControls`), ensuring **ENTER VEHICLE** reaches production gameplay.
- Dropped **CENTER/FOLLOW** down to `y = 574`, directly above the FORWARD row with a small non-overlapping gap.
- Added an adjacent **MAP** button that opens a read-only generated-island overlay in either walking or mounted mode.
- The map raster uses the active generated world plan and canonical island-surface math, layers generated roads/settlements, and marks the player's canonical `WorldState` placement.
- Map presentation is lazy and bounded (`256 x 256` raster); it does not scan the live streamed world or create duplicate navigation/topology truth.
- Preserved `VehicleGameMain.gd` as the production root. Map configuration is a composition-only `PlayerMapBootstrap.gd` child after canonical world boot.

## Corrected mounted control replacement

The earlier interpretation that kept mounted vehicle controls as a separate vehicle panel/window was explicitly rejected by the user and is superseded.

Current contract:

- **On foot:** only the normal `PlayerMovementControls` lower-screen surface is visible.
- **Mounted:** the entire walking `CanvasLayer` disappears.
- A direct `VehicleControlSurface` replaces the walking controls in the **same lower-screen footprint**. There is no `VehiclePanel` and no separate mounted vehicle window.
- Mounted driving controls include **TURN L**, **FORWARD**, **TURN R**, **BRAKE**, **REVERSE**, and **BACK**, routed through the existing authoritative `VehiclePlayerController` intent path.
- The same replacement surface preserves **EXIT**, **START**, **HOTWIRE**, **REPAIR**, **ADD RACK**, **REFUEL**, actor/vehicle cargo selection, **STORE →**, and **← TAKE**.
- Dismounting removes the vehicle surface and restores the ordinary walking surface.
- No player walking controls remain visible while mounted; no vehicle surface is visible while walking.
- This is a presentation/layout swap only. Vehicle movement, braking/reverse rules, cargo state and action consequences remain owned by their existing simulation/controller services.

## Corrected top HUD/camera layout

- `LookingAtPanel` begins at approximately `y = 66`, directly below the top menu buttons.
- `Looking at:` no longer occupies the lower movement/control region.
- `HealthBar` and `FatigueBar` nodes are retired rather than repositioned.
- Health/fatigue remain authoritative and readable in textual status output.
- Visible Zoom +/- buttons are retired; CENTER/FOLLOW remains.
- CENTER/FOLLOW now occupies `(x = 182, y = 574)` in the 720p reference layout; MAP occupies the same row immediately to its right at `x = 326`.
- Existing zoom capability is preserved for non-button input paths.

## Canonical island map follow-up

- `CameraControls.gd` owns the MAP toggle alongside CENTER/FOLLOW while retaining its existing touch/mouse duplicate-suppression path.
- `IslandMapView.gd` is a presentation-only full-screen overlay with a CLOSE action.
- Coastline/shore/land/ocean are sampled from the active plan's bounds/seed/profile using `IslandSurfaceMath.classify(...)`, so the displayed island follows the same deterministic geometry contract as generation.
- `GeneratedGlobalWorldPlan.road_segments` and `.settlements` are rendered as overlays rather than rediscovered from streamed entities.
- The player marker is derived from the canonical playable actor placement and redraws from world-change notification while MAP is visible.
- The initial attempt changed the root scene script to a subclass and was correctly rejected by existing System 34 ownership guards before Godot execution. The repaired implementation keeps the required `VehicleGameMain.gd` root and uses `PlayerMapBootstrap.gd` only for composition wiring.
- `PlayerUiCleanupSmoke.gd` now proves CENTER/MAP positioning, canonical plan configuration, canonical player marker presence, open/close behavior, overlay layer restoration and deterministic raster materialization.

## Verification

Earlier UI-cleanup executable head: `3bc3f2abd74fe82b215b1fbfc7983f45a4bdf057`

- 45/45 push workflows succeeded.

Earlier exclusive mounted-control candidate: `7842806e836f4d868407c96336f4b940e1586fbc`

- 44/44 push workflows succeeded.

Corrected player-HUD / driving-replacement executable head: `33afe7f459f1cd9d24b493ab935c97b2d4545a35`

- 44/44 push workflows succeeded.
- 0 failed.
- 0 cancelled.

**Canonical island-map executable head:** `b4d4e59da5f185cce22a990ce9012b77bb1d3d84`

- **47/47 push workflows succeeded.**
- **0 failed.**
- **0 cancelled.**
- Godot import/parse succeeded.
- Protected UI/HUD/camera, vehicle, generation, performance, startup and Web/Pages regressions succeeded.
- The executable tree is terminal-green; subsequent commits in this prompt are documentation/handoff only.