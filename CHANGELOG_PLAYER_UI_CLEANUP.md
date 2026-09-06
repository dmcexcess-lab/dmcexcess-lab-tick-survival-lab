# Tick Lab — Player UI Cleanup

Date: 2026-09-05

## Closed

- Retired the standalone **Survival** player window. Authoritative condition, sustainment, exact-item inventory consumption and first-aid systems remain intact.
- Retired the standalone **Forage** panel. **FORAGE** is now an on-foot bottom action wired directly to the existing `ForageNearbyActionService`.
- Retired the player-visible **Dev** window. Performance telemetry and diagnostic snapshots remain available internally; the production renderer no longer instantiates `PerformanceDevPanel`.
- Moved **ENTER VEHICLE** to the on-foot bottom action strip and wired it to the production `VehiclePlayerController`.
- Vehicle detail/cargo controls are now mounted-only; the duplicate vehicle-panel ENTER action was removed.
- Moved the Health and Fatigue/Stamina bars to the top HUD (`y = 70`) so they no longer overlap the lower `Looking at:` context presentation.
- Added `PlayerUiCleanupSmoke.gd` and protected Canonical HUD workflow coverage for the cleaned player-facing contract.
- Updated the Performance Architecture workflow so it protects the absence of a renderer-created Dev panel while retaining the telemetry architecture.
- CI caught and fixed a real scene-node hookup error (`Controls`, not `PlayerControls`) before closure, ensuring the new bottom **ENTER VEHICLE** action actually reaches production gameplay.

## Mounted control-surface swap

- On foot, only the normal `PlayerMovementControls` bottom surface is visible.
- Mounting a vehicle hides the entire player movement surface and replaces it with `VehiclePlayerControls` in the same bottom control zone.
- The mounted surface now exposes vehicle movement directly: **TURN L**, **FORWARD**, **TURN R**, and **BACK**, routed through the existing authoritative `VehiclePlayerController` intent path.
- The same mounted surface preserves all vehicle actions: **EXIT**, **START**, **HOTWIRE**, **BRAKE**, **REVERSE**, **REPAIR**, **ADD RACK**, **REFUEL**, and vehicle cargo controls.
- No vehicle control surface is visible while on foot, and no player movement surface is visible while mounted.
- Dismounting restores the on-foot control surface immediately.
- `PlayerUiCleanupSmoke.gd` now regression-protects the exclusive swap, bottom placement, mounted movement buttons, preserved vehicle actions, and restoration after dismount.

## Verification

Previous UI-cleanup executable head: `3bc3f2abd74fe82b215b1fbfc7983f45a4bdf057`

- 45/45 push workflows succeeded.

Exclusive mounted-control executable head: `7842806e836f4d868407c96336f4b940e1586fbc`

- 44/44 push workflows succeeded.
- 0 failed.
- 0 cancelled.
- 0 queued.
- 0 in progress.
- Pages deployment completed successfully.
