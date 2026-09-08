# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once at prompt start. This is the authoritative continuation checkpoint.

## Current checkpoint — MOBILE RENDER-WINDOW EXPERIMENT REVERTED — 2026-09-08

The user reported that new cells were not rendering. A viewport-aware render-window recenter experiment was attempted, but the user immediately reported that it made the live problem worse and explicitly requested a revert.

The entire experiment has been reverted to the exact pre-experiment repository tree from:

- known-good pre-experiment head: `848c4f601716151c198f2a29ae410626321740c9`
- known-good tree: `ac9a2dabd598d4f854b53e6146c164a27915d483`
- revert commit restoring that exact tree: `08b06fdb90933a3dc099cebd927c4da3be7464cf`

Do **not** reapply the viewport-aware recenter-margin change or treat the previous diagnosis as established. The failed experiment changed presentation-window behavior only; the user's original symptom remains unresolved and must be diagnosed fresh from live production behavior.

## Preserved closed work

Roadside power / alternating real streetlights remain closed and restored exactly as they were before the failed render-window experiment.

Reference proof remains:

- 3,157 wire spans
- 1,048 alternating roadside streetlights
- maximum span 16.00 cells
- zero duplicate spans
- zero unsupported wire crossings
- real powered illumination, outage/restoration, and physical-support damage behavior

The restored prompt-owned verifier pair is again:

- `game/scripts/ci/PromptRoadsidePowerSmoke.gd`
- `.github/workflows/prompt-roadside-power.yml`

## NEXT OPERATION — DIAGNOSE ORIGINAL NEW-CELL RENDER FAILURE

Treat the original bug as open. Do not assume it is caused by camera margin, render-window edge distance, or viewport size.

Start from the restored production state and reproduce the exact failure path. Determine separately whether:

1. movement reaches a new technical streaming region;
2. the streaming coordinator activates the expected neighboring regions;
3. materialization produces authoritative terrain/entities for newly activated cells;
4. the renderer receives the changed world state;
5. the render-window origin/coverage updates when required;
6. camera transform, culling, clipping, or stale renderer caches prevent already-materialized cells from appearing.

Use the smallest focused instrumentation needed to identify the first broken boundary. Do not broaden into generation, streaming, renderer, or camera rewrites until the first failing seam is proven.

Phone/Safari remains first-class. Preserve world size 3072×3072, streaming regions 128×128, active radius 1, and the existing 80×96 render window unless concrete evidence proves one of those contracts is itself defective.

At the start of the next code prompt, delete the restored roadside-power prompt verifier pair and create one fresh prompt-local verifier only for the diagnosed render/stream seam.

## Final closure rule

This handoff is the final repository write for the revert prompt. After this commit is published, perform only read-only exact-head branch/Actions/Pages verification. If deployment or verification unexpectedly fails, report the evidence without making another repository write in this prompt.
