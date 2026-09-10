# Loading UI + MAP Single-Press Closure — 2026-09-10

## User-reported behavior

The MAP control was discovered to feel like it required a double tap/click. The desired behavior is one press. The startup/loading menu also needed a visibly changing ellipsis after the status words so users can distinguish active loading from a static screen.

## Implemented

### MAP input

`game/scripts/ui/CameraControls.gd` now activates MAP on the first left-mouse press or first screen-touch press rather than waiting for release.

The corresponding release is consumed without toggling the map again. Touch activation also starts the existing synthetic-mouse suppression window immediately, preventing a browser-generated mouse press from double-toggling the touch-opened map.

Other camera controls retain their existing release-driven behavior.

### Loading-status ellipsis

`game/scripts/ui/StartupMenu.gd` now owns a lightweight status animation that cycles:

- `.`
- `..`
- `...`
- back to `.`

at 0.32-second intervals while a loading status is active.

The animation is used for menu-time gameplay preload, finishing gameplay load, and island/start-region generation status. Completed/error states remain static.

Important limitation: the existing legacy synchronous gameplay boot can still block Godot's main thread during the heaviest post-NEW-GAME generation/materialization phase. A normal in-engine animation cannot advance while that main thread is genuinely blocked, so the ellipsis intentionally pauses rather than falsely indicating responsiveness. Startup loading phase 2 remains the correct future fix if that serial boot is promoted again.

## Verification

Fresh prompt-local verifier:

- `game/scripts/ci/PromptLoadingUiSinglePressSmoke.gd`
- `.github/workflows/prompt-loading-ui-single-press.yml`

Owning functional head:

`585cc0753505530a0d700d286827eab9efb4ed86`

Focused run:

- `34508126852` — **SUCCESS**

It proves:

- the loading label cycles `. -> .. -> ... -> .` without changing the base status words;
- MAP opens on the first mouse press;
- mouse release does not toggle MAP back closed;
- MAP opens on the first touch press;
- touch release does not toggle MAP back closed;
- the synthetic mouse press after touch is consumed and cannot double-toggle MAP.

Functional-head Pages publication:

- run `34508126847` — **SUCCESS**
- Web export — **SUCCESS**
- Pages deploy — **SUCCESS**

No map generation, simulation timing, movement, world generation, streaming, population, utility, combat, or persistence semantics were changed by this bounded UI/input pass.
