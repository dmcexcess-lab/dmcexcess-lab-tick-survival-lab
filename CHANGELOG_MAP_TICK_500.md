# Tick Survival Lab — Map Tick-500 Repair

Date: 2026-09-10

## Scope

Bounded production acceptance/repair pass for the player island map after the user reported that MAP appeared not to work during ordinary play.

The acceptance target was the real production gameplay scene at authoritative simulation tick 500, using the existing TickKernel, generated island plan, PlayerMapBootstrap, CameraControls input path, and live player placement.

## Reproduction

The original map wiring was intact at tick 500, but first-open work was synchronous inside `IslandMapView.set_map_visible()`.

On first MAP open, `IslandMapView` generated the complete 256 x 256 static island texture before returning:

- 65,536 coastline/surface samples;
- road painting;
- settlement painting;
- texture creation.

Baseline focused run:

- workflow run `34505921836` — SUCCESS;
- authoritative WHEN reached tick `500`;
- first MAP open: `244576` microseconds;
- cached reopen: `26` microseconds.

This confirmed that the apparent dead/frozen MAP button was a first-open main-thread latency problem rather than missing map configuration or lost input wiring.

## Repair

`game/scripts/ui/IslandMapView.gd` now:

- starts static island-map prewarming as soon as the canonical map is configured;
- samples only 4 texture rows per process frame;
- completes the 256 rows in 64 bounded slices;
- never performs full island generation synchronously from the MAP button path;
- opens the map shell immediately even when the static texture is still being prepared;
- shows `PREPARING MAP... N%` while the incremental build is incomplete;
- retains the completed texture for instant close/reopen behavior;
- continues resolving the player marker from live WorldState truth.

No road-generation, settlement-generation, simulation-time, movement, streaming, combat, or persistence ownership changed in this pass.

## Focused verification

Fresh prompt-local verifier:

- `game/scripts/ci/PromptMapTick500Smoke.gd`
- `.github/workflows/prompt-map-tick-500.yml`

Post-fix focused run:

- workflow run `34506535591` on `d6da269b20b2269fba5bcca13b4177b97fb4a558` — SUCCESS;
- production gameplay boot succeeded;
- authoritative WHEN reached tick `500`;
- first MAP open: `58` microseconds;
- incremental surface completed in `64` process frames;
- completed texture size: 256 x 256;
- cached reopen: `36` microseconds;
- MAP open/close state and live player marker remained correct.

The verifier enforces a 50,000-microsecond first-open ceiling and a 10,000-microsecond cached-reopen ceiling, so the old synchronous first-open path cannot silently return.

## Web build / deployment

Pages workflow run `34506535611` for `d6da269b20b2269fba5bcca13b4177b97fb4a558` completed successfully:

- Web export: SUCCESS;
- Pages artifact upload: SUCCESS;
- deploy: SUCCESS.

## Preserve

Future work should preserve:

- PlayerMapBootstrap as the production map configuration bridge;
- CameraControls as the user MAP input owner;
- the generated global plan as map geography truth;
- live WorldState placement for the player marker;
- nonblocking/incremental static map generation;
- cached reopen behavior.

The prompt-owned tick-500 verifier pair is disposable and should be retired first when the next distinct code operation begins.
