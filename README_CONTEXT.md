# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. For the next distinct repository operation, follow the normal SOP from this recorded final head.

## Current checkpoint — MAP SINGLE-PRESS + LOADING ELLIPSIS CLOSED — 2026-09-10

The core feature roadmap remains closed and the game remains a beta candidate. This bounded UI/input pass implements the user's newly confirmed MAP behavior and adds a visible loading-status ellipsis animation to the lightweight startup menu.

Starting head:

`aad85681f8e7fed94520c5b8d8568be9cba587c8`

Owning functional head:

`585cc0753505530a0d700d286827eab9efb4ed86`

Documentation head immediately before this final context write:

`59e6d9593afdb8e980134d87a532102790e527ce`

## User decision / superseded behavior

The user identified the MAP interaction problem as a double-tap/double-click feel and explicitly set the desired contract:

> MAP should open on one press.

The previous release-driven MAP activation is superseded.

The user also requested animation of the trailing loading dots under the startup loading bar so users can visibly tell that loading is progressing rather than looking at a static screen.

## Implemented behavior

### MAP opens on first press

`game/scripts/ui/CameraControls.gd` now:

- activates MAP on the first left-mouse **press**;
- activates MAP on the first screen-touch **press**;
- consumes the matching release without toggling the map closed again;
- starts the existing synthetic-mouse suppression window immediately on touch press so browser-generated mouse input cannot double-toggle the touch-opened map;
- leaves the other camera controls on their existing release-driven semantics.

The previous nonblocking/cached map-generation repair remains intact.

### Animated loading ellipsis

`game/scripts/ui/StartupMenu.gd` now cycles the status suffix:

`.` -> `..` -> `...` -> `.`

at 0.32-second intervals while a loading status is active.

The animation is used while:

- menu-time gameplay resources are preloading;
- NEW GAME is finishing gameplay resource load;
- the status line says the island/start region is being generated/activated.

Completed and error states stay static.

Important truthfulness boundary: the existing legacy synchronous post-NEW-GAME gameplay boot can still block Godot's main thread during its heaviest generation/materialization work. A normal in-engine animation cannot advance while the main thread is genuinely blocked, so the dots pause in that interval rather than falsely indicating responsiveness. Startup-loading phase 2 remains the proper future fix if the user promotes that serial boot again.

## Verification

The previous prompt-owned MAP tick-500 verifier/workflow was retired at operation start:

- `game/scripts/ci/PromptMapTick500Smoke.gd`
- `.github/workflows/prompt-map-tick-500.yml`

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptLoadingUiSinglePressSmoke.gd`
- `.github/workflows/prompt-loading-ui-single-press.yml`

Focused run:

- `34508126852` on `585cc0753505530a0d700d286827eab9efb4ed86` — **SUCCESS**.

The focused smoke proves only this prompt's requested path:

- loading status cycles `. -> .. -> ... -> .` without changing its base words;
- MAP opens on the first mouse press;
- matching mouse release does not toggle it closed;
- MAP opens on the first touch press;
- matching touch release does not toggle it closed;
- synthetic mouse press following touch is consumed and cannot double-toggle MAP.

Functional-head Pages/Web publication:

- run `34508126847` on `585cc0753505530a0d700d286827eab9efb4ed86` — **SUCCESS**;
- Web export — **SUCCESS**;
- Pages deploy — **SUCCESS**.

After this final context commit, perform exact-final-head Pages/status verification read-only. No further repository writes are permitted in this operation.

## Documentation

Operation-specific ledger:

- `CHANGELOG_LOADING_UI_SINGLE_PRESS.md`

Documentation commit immediately before this final context write:

`59e6d9593afdb8e980134d87a532102790e527ce`

## Established systems to preserve

Unless a focused failure proves otherwise, preserve:

- the single authoritative WHEN/TickKernel clock;
- same-WHEN deterministic movement batching and decision-pause semantics;
- healthy ordinary WALK remaining fatigue-free; RUN remains routinely fatiguing;
- the lightweight startup menu plus menu-time gameplay-resource preload boundary;
- MAP first-press activation and touch/mouse de-duplication;
- `PlayerMapBootstrap` as the production map configuration bridge;
- generated global-plan geography as island-map truth;
- live `WorldState` placement as the player-marker source;
- nonblocking incremental static-map generation and cached reopen behavior;
- current settlement-first procedural island and building-derived population;
- current road hierarchy and dirt/gravel/paved traversal contracts;
- current generated weather/day-night/physical lighting/night-only streetlights;
- current power/water infrastructure;
- observer-scoped infected/survivor perception and existing population ownership;
- inventory/equipment/sustainment/crafting/skills/doors/windows/utilities/vehicles/combat systems already closed;
- dedicated vehicle rendering without the retired purple diagnostic artifact;
- no generated rivers/wastewater/sewer/septic resurrection;
- no routine broad seed matrices for bounded prompt closure.

## Confirmed performance issues still open

This UI/input pass does **not** close the separate region-streaming problem. Ordinary live play can still hit large region-boundary long frames severe enough for browser `Page Unresponsive` warnings; that remains a valid future bounded performance target.

Startup loading phase 1 also only established the menu/resource boundary. The long post-NEW-GAME synchronous boot remains capable of pausing the new dot animation because the main thread itself is blocked. If promoted again, startup loading phase 2 should instrument and slice/cache/defer the dominant global-plan, central-area, initial-streaming, materialization, placement/focus, and service-installation work while preserving deterministic world truth.

## NEXT OPERATION — wait for the next explicit bounded target

Do not automatically broaden this UI/input pass into streaming, startup phase 2, worldgen, gameplay, or general polish.

For the next **code** operation, retire this prompt-owned verifier pair first:

- `game/scripts/ci/PromptLoadingUiSinglePressSmoke.gd`
- `.github/workflows/prompt-loading-ui-single-press.yml`

Then create a fresh prompt-local verifier for only the next requested behavior and follow the normal direct-to-main closure SOP.

This `README_CONTEXT.md` commit is the **FINAL repository write for the MAP single-press + loading-ellipsis operation**. After it lands, perform read-only exact-head and CI/Pages verification only.
