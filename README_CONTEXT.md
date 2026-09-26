# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — LIGHTING PRESENTATION SIMPLIFIED TO DIRECT TILE TINT — 2026-09-25

User direction superseded the earlier transparent-circle idea:

**Lighting presentation should only change each tile's color/darkness from the real physical lightmap. No bloom, blur, halo, scatter, reflection, or other added visual lighting effects.**

Starting main for this operation: `cdc73bb077101172b9253a4573548aa2f85442c8`.

Functional production lighting cleanup head: `a307e8bb0c268709aa176fae5d5e513922c4dc42`.

Fresh verifier/workflow owning head: `d2c8b6f99c5ddd76920dfb563d3996d7a97c80ed`.

Focused verifier run: `36217199331` — **SUCCESS**.

Documentation head immediately before this final handoff write: `141c3790eb642c5479c61e65ccff5f30364ab8e1`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous pair was retired during this operation:

- `game/scripts/ci/VisionWorldRefreshRegressionSmoke.gd`
- `.github/workflows/vision-world-refresh-regression.yml`

Fresh current pair:

- `game/scripts/ci/SimpleLightingPresentationSmoke.gd`
- `.github/workflows/simple-lighting-presentation.yml`

The next code-changing prompt must delete this pair before changing code and create a fresh prompt-local verifier/workflow scoped only to the next operation.

## Completed — direct tile-tint presentation

The production physical-light presentation is now intentionally minimal.

`physical_lighting_multiply.gdshader` now:

- performs one direct `texture(TEXTURE, UV)` sample;
- uses the sampled physical-light tint and luminance directly;
- performs no neighboring texture samples;
- performs no edge weighting;
- performs no smoothing/blur pass.

`PhysicalLightingPresentationRenderer.gd` now:

- owns one lighting image;
- owns one lighting texture;
- owns one Sprite2D child named `PhysicalLightTileTint`;
- uploads only that one tile-tint map;
- exposes `presentation_mode = "tile_tint_only"`;
- no longer creates or uploads a glow map;
- no longer creates an additive glow Sprite2D;
- no longer computes presentation glow strength, glare, scatter, wet reflections, or emitter core bloom.

The old glow shader source file remains in the repository as inert historical source, but production presentation no longer loads or instantiates it.

## Preserved physical lighting truth

This operation did **not** simplify the authoritative System 27 simulation.

Still preserved:

- day/night physical luminance;
- weather/atmosphere influence on physical illumination;
- opaque structure light blocking;
- closed-door blocking;
- open-door transmission;
- window transmission;
- portal/interior light transfer;
- local artificial emitters;
- flashlight/light-source physical range and occlusion;
- lighting-driven System 23 perception/acquisition.

Therefore this is a presentation simplification, not a gameplay-lighting downgrade.

## Focused verifier evidence

Run `36217199331` — **SUCCESS**.

Marker:

`SIMPLE_LIGHTING_PRESENTATION_OK children=1 mode=tile_tint_only`

The fresh production-scene verifier proves:

1. production `gameplay.tscn` boots;
2. the physical-light presentation node exists;
3. it reports `tile_tint_only`;
4. its single tile-tint texture is ready;
5. it has exactly one render child;
6. that child is `PhysicalLightTileTint`;
7. the multiply shader uses exactly one direct texture lookup;
8. neighbor smoothing code is absent.

## Publication state before final handoff write

On documentation head `141c3790eb642c5479c61e65ccff5f30364ab8e1`:

- fresh focused lighting workflow run `36217258040` was in progress;
- Pages run `36217257995` was in progress.

After this final context write, perform read-only exact-head verification only.

## NEXT OPERATION

Visually playtest the deployed build, especially at night and around:

- streetlights;
- building exteriors;
- windows;
- open/closed doors;
- flashlight or other local emitters.

Confirm that the hard tile-tint lighting aesthetic is readable and that the removal of bloom did not make important light sources visually ambiguous.

If visual acceptance passes, return to the previously identified release gap:

**wire the existing EAT / DRINK / TAP / REST / SLEEP survival-action controls into the production gameplay scene and verify them through ordinary player input.**

Do not reopen physical-lighting simulation unless a concrete gameplay-lighting defect appears.

## Protected behavior

Preserve:

- one WHERE / WHAT / WHEN authority chain;
- System 27 physical-light truth and occlusion;
- lighting-driven perception;
- cached geometric LOS observer-pose invalidation;
- event-driven perception freshness;
- one bounded shared player + active-infected acquisition field;
- active infected cohort size 8;
- simultaneous combat consequences;
- mob-force core;
- canonical fear;
- coherent consequence presentation;
- touch-first semantic controls;
- input locked until legitimate decision pause;
- hard application pause;
- player movement, health/injury, inventory, skills/equipment;
- day/night, weather, utilities, vehicles, persistence/terrain/streaming;
- STATS / INVENTORY / CRAFT / MENU ownership.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
