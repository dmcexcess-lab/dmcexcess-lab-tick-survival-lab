# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. For the next distinct repository operation, follow the normal SOP from this recorded final head.

## Current checkpoint — MAP TICK-500 NONBLOCKING OPEN CLOSED — 2026-09-10

The core feature roadmap remains closed and the game remains a beta candidate. This bounded operation reproduced the player's MAP issue in the full production gameplay scene at authoritative simulation tick 500, isolated it to synchronous first-open island texture generation, and replaced that blocking path with incremental prewarming.

Starting head:

`995c4d433a17bec945d364ebfd223a9414877f47`

Production repair commit:

`d7960e86ff2e04e45580bb5a8813d150b1992e06`

Owning fully gated functional head:

`d6da269b20b2269fba5bcca13b4177b97fb4a558`

Documentation head immediately before this final context write:

`bb357ee0207373b8a2690713498e5b5ab33635a1`

## Reproduction / root cause

The production map wiring itself was intact:

- `game/gameplay.tscn` owns `CameraControls` and `PlayerMapBootstrap`;
- `PlayerMapBootstrap` configures the map from the generated global island plan plus live `WorldState`;
- `CameraControls` owns the user MAP input path;
- `IslandMapView` resolves the player marker from live placement truth.

The failure was responsiveness. Before this repair, the first MAP open synchronously generated the complete 256 x 256 island surface before returning from the input event. That meant one MAP click performed 65,536 coastline/surface classifications, painted roads and settlements, and created the texture on the main thread.

A production acceptance verifier advanced the real `TickKernel` to tick 500 with a committed player action and then used the same MAP mouse-release path as the game.

Baseline focused run:

- workflow run `34505921836` — **SUCCESS**;
- authoritative WHEN: `500`;
- first MAP open: `244576` microseconds;
- cached reopen: `26` microseconds.

This proved the map was configured and input-connected, but the first-open synchronous workload was large enough to make the control appear dead/frozen in a browser.

## Implemented repair

`game/scripts/ui/IslandMapView.gd` now:

- begins static island-map prewarming as soon as canonical map configuration succeeds;
- samples only 4 map-texture rows per process frame;
- completes the 256 rows in 64 bounded frame slices;
- no longer performs full island generation synchronously from the MAP input path;
- makes the map shell visible immediately;
- displays `PREPARING MAP... N%` if the cached surface is not finished yet;
- paints roads and settlements once the sampled surface is complete;
- retains the completed 256 x 256 texture for instant close/reopen behavior;
- continues to resolve the player marker from live `WorldState` truth.

No simulation-time ownership, road generation, settlement generation, world streaming, movement, combat, population, utilities, or persistence behavior changed in this repair.

## Verification

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptMapTick500Smoke.gd`
- `.github/workflows/prompt-map-tick-500.yml`

The verifier boots the actual production gameplay scene, waits for `PlayerMapBootstrap`, advances the authoritative `TickKernel` to tick 500, sends the production MAP event, enforces a 50,000-microsecond first-open ceiling, waits for the incremental map build, verifies the final 256 x 256 surface and player marker, then closes and reopens the map under a 10,000-microsecond cached-reopen ceiling.

Post-repair focused run:

- run `34506535591` on `d6da269b20b2269fba5bcca13b4177b97fb4a558` — **SUCCESS**;
- authoritative WHEN: `500`;
- first MAP open: `58` microseconds;
- incremental build: `64` process frames, progress `1.000`;
- cached reopen: `36` microseconds;
- output: `PROMPT_MAP_TICK_500_SMOKE_OK`.

Compared with the baseline, the measured first-open input latency fell from 244,576 microseconds to 58 microseconds on the CI runner, approximately a 4,200x reduction.

Functional-head Pages/Web publication:

- run `34506535611` on `d6da269b20b2269fba5bcca13b4177b97fb4a558`;
- Web export — **SUCCESS**;
- Pages artifact upload — **SUCCESS**;
- Pages deploy — **SUCCESS**.

After this final context commit, perform exact-final-head focused-CI and Pages verification read-only. No further repository writes are permitted in this operation.

## Documentation

Operation-specific ledger:

- `CHANGELOG_MAP_TICK_500.md`

Documentation commit immediately before this final context write:

`bb357ee0207373b8a2690713498e5b5ab33635a1`

## Established systems to preserve

Unless a focused failure proves otherwise, preserve:

- the single authoritative WHEN/TickKernel clock;
- same-WHEN deterministic movement batching and decision-pause semantics;
- healthy ordinary WALK remaining fatigue-free; RUN remains routinely fatiguing;
- the lightweight startup menu plus menu-time gameplay-resource preload boundary;
- `PlayerMapBootstrap` as the production map configuration bridge;
- `CameraControls` as the user MAP input owner;
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

This MAP repair does **not** close the separate region-streaming problem. Ordinary live play can still hit large region-boundary long frames severe enough for browser `Page Unresponsive` warnings; that problem was independently reproduced around the ~800-tick area in deployed play and remains a valid future bounded target.

Startup loading phase 1 also only established the lightweight menu/resource boundary. If the user promotes startup performance again, phase 2 remains: instrument and slice/cache/defer the dominant post-NEW-GAME global-plan, central-area, initial-streaming, materialization, placement/focus, and service-installation work while preserving deterministic world truth.

## NEXT OPERATION — wait for the next explicit bounded target

Do not automatically broaden this map repair into streaming, startup, UI, worldgen, or gameplay work.

For the next **code** operation, retire this prompt-owned verifier pair first:

- `game/scripts/ci/PromptMapTick500Smoke.gd`
- `.github/workflows/prompt-map-tick-500.yml`

Then create a fresh prompt-local verifier for only the next requested behavior and follow the normal direct-to-main closure SOP.

This `README_CONTEXT.md` commit is the **FINAL repository write for the map tick-500 repair operation**. After it lands, perform read-only exact-head and CI/Pages verification only.