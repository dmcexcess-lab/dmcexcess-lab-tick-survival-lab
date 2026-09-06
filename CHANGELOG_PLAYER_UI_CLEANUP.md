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

- `LookingAtPanel` now begins at approximately `y = 66`, directly below the top menu buttons.
- `Looking at:` no longer occupies the lower movement/control region.
- `HealthBar` and `FatigueBar` nodes are retired rather than repositioned.
- Health/fatigue remain authoritative and readable in textual status output.
- Visible Zoom +/- buttons are retired; CENTER/FOLLOW remains.
- Existing zoom capability is preserved for non-button input paths.

## Verification

Earlier UI-cleanup executable head: `3bc3f2abd74fe82b215b1fbfc7983f45a4bdf057`

- 45/45 push workflows succeeded.

Earlier exclusive mounted-control candidate: `7842806e836f4d868407c96336f4b940e1586fbc`

- 44/44 push workflows succeeded.

**Corrected player-HUD / driving-replacement executable head:** `33afe7f459f1cd9d24b493ab935c97b2d4545a35`

- **44/44 push workflows succeeded.**
- 0 failed.
- 0 cancelled.
- 0 queued.
- 0 in progress.
- The executable tree is terminal-green; subsequent commits in this prompt are documentation/handoff only.
