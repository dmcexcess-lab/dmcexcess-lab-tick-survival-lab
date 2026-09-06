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

## Verification

Executable head: `3bc3f2abd74fe82b215b1fbfc7983f45a4bdf057`

- 45/45 push workflows succeeded.
- 0 failed.
- 0 cancelled.
- 0 queued.
- 0 in progress.
