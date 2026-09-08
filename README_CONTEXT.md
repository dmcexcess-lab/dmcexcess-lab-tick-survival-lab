# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once at prompt start. This is the authoritative continuation checkpoint.

## Current checkpoint — STREETLIGHT SPACING / NIGHT-GATING OPERATION REVERTED — 2026-09-08

The user reported that the immediately preceding streetlight-spacing/night-gating operation broke the live game and explicitly requested a full revert. Do not continue, repair, or partially preserve that operation.

The production repository tree from immediately before that operation was restored exactly from:

- pre-operation head: `5a97067773dd0745b1fc32accd87c92eb31d0855`
- pre-operation tree: `2f99ffdeec3afbbd6880beab314d4c8742b5f02f`
- revert commit restoring that exact tree: `529f07ec3d5ecfd4d6d10f480f1986bdeb732f2f`

The unwanted operation ending at `179779450a9743ee6e8ccc24d941e0a9a5a23832` is fully retired. Its 16-cell minimum streetlight-spacing change, customer-tap coalescing change, streetlight day/night gating, temporary base-wrapper scripts, smoke, workflow, and handoff are not part of production anymore.

After the exact-tree revert, one fresh prompt-local verifier pair was added only to prove the restored production state:

- `game/scripts/ci/PromptStreetlightRevertSmoke.gd`
- `.github/workflows/prompt-streetlight-revert.yml`

The executable verification head before this final handoff write is `de3f2218ba610ab14d4b8d1a2dd0a2edef7200ac`.

Focused verification succeeded on run `34189250794`. It proves the production game boots, roadside power and utility lighting are ready, seed 20001 is back to the prior 1,048 streetlights and 3,157 wire spans, and the temporary spacing/night-gating base wrappers are absent.

Pages build/deploy succeeded on run `34189250810` for that executable verification head.

## Preserved production baseline

Roadside power / alternating real streetlights are back to the pre-operation behavior. The prior reference contract remains:

- 3,157 wire spans;
- 1,048 alternating roadside streetlights;
- maximum wire span 16.00 cells;
- zero duplicate spans;
- zero unsupported wire crossings;
- real powered illumination, outage/restoration, and physical-support damage behavior.

Do not reintroduce the just-reverted spacing or night-only behavior unless a future prompt explicitly asks for another attempt after the live game is stable.

The earlier failed viewport-aware render-window recenter experiment also remains reverted. Do **not** treat its diagnosis as established.

## NEXT OPERATION — DIAGNOSE ORIGINAL NEW-CELL RENDER FAILURE

The original bug where new cells fail to appear in live play remains open. Diagnose it fresh from the restored production state rather than changing streetlights, world generation, or render-window margins speculatively.

Determine separately whether:

1. movement reaches a new technical streaming region;
2. the streaming coordinator activates the expected neighboring regions;
3. materialization produces authoritative terrain/entities for newly activated cells;
4. the renderer receives the changed world state;
5. the render-window origin/coverage updates when required;
6. camera transform, culling, clipping, or stale renderer caches prevent already-materialized cells from appearing.

Use the smallest focused instrumentation needed to identify the first broken boundary. Phone/Safari remains first-class. Preserve world size 3072×3072, technical streaming regions 128×128, active radius 1, and the existing 80×96 render window unless concrete evidence proves one of those contracts is itself defective.

At the start of the next code prompt, delete the current prompt-owned verifier pair (`PromptStreetlightRevertSmoke.gd` and `prompt-streetlight-revert.yml`) and create one fresh focused pair for the diagnosed render/stream seam.

## Final closure rule

This `README_CONTEXT.md` update is the final repository mutation of this prompt. After it is published, perform only read-only exact-head branch, focused Actions, and Pages verification. If exact-final-head verification fails, report the evidence and make repair the next operation rather than writing again in this prompt.
