# Tick Survival Lab — Current Repository Handoff

Read this file first, then README_SOPS.md. Fetch current main once at prompt start.

## Current checkpoint — EXPLORATION RENDER BOUNDARY FIXED; BETA NOT FINISHED — 2026-09-09

User requested "ok finish the game". Work proceeded toward a playable survival beta, starting with the recorded new-cell rendering defect. A scope-choice prompt returned no answer; use the canonical roadmap and existing systems, without pretending the full roadmap is complete.

Functional published head: `cb80b6faa72da165bf9913cf70019ea9520a5bc1`.
Tree `fa4bbe93ff43df0004cd594f0315ee929fc10d87` exactly matches local tested commit `13f1d75251a6de63510e7fb67511a24423e48136`.

## Completed and proven

- Production seed-20001 probe confirmed streaming and near-spawn window shifts work.
- Reproduced a concrete exploration failure at (2025,1552): streaming focus correctly advanced into region (19,7), all 441 cells in a 21×21 neighborhood had authoritative terrain, but the player was outside the render window.
- Root cause: GameMain and initial-render clamping used the legacy request AREA_BOUNDS (232,1232,1792,1792), while IslandWorldPlanner expands the actual generated bounds to (-408,592,3072,3072).
- Added GeneratedIslandCritiqueFixture.render_bounds() using the generated plan. Rendering composition and initial-window clamping now use that truth. Generation request unchanged. 80×96 render window, 128×128 streaming regions and active radius 1 preserved.
- Production test passes at (2023,1552) and (2025,1552), including ahead-of-player coverage and materialized terrain. Probe uses direct authoritative placement to isolate the render/stream boundary; it is not an ordinary movement or Safari acceptance test.
- This fixes a proven outer-area clipping defect. Do not claim it reproduces every earlier screenshot or all possible missing-cell issues.
- Changelog updated; retired prior vehicle verifier pair. No actor simultaneity, NPC or interaction changes.

## Verification / publication

Fresh disposable pair:
- `game/scripts/ci/PromptWorldBoundarySmoke.gd`
- `.github/workflows/prompt-world-boundary.yml`

Local Godot 4.7.1 production test: PASS. Binary: `/tmp/finish-godot/Godot_v4.7.1-stable_linux.x86_64`.
Owning-head focused run `34301855756`: success.
Owning-head Pages run `34301855445`: success.
Publication uses connected GitHub API because shell git has no credentials. Direct main publication remains authorized.

This handoff is the FINAL repository write. Publish its containing commit, then verify exact final head and final-head focused CI/Pages read-only through terminal success. Do not write again to insert final run IDs.

## Concrete acceptance blocker

The browser skill successfully connected to the cloud Chrome browser and opened the public live game. The rendered page reports:
"The following features required to run Godot projects on the Web are missing: WebGL2 - Check web browser configuration and hardware support".
Therefore this browser cannot perform the requested player-facing acceptance pass. This is specific to this environment; it is not evidence that the user's desktop/phone cannot run the game. No speculative workarounds or changes to game renderer/backend were made.

## NEXT OPERATION — CONTINUE PLAYABLE BETA CLOSURE

The whole game is NOT finished. Continue from this working rendering fix:
1. Use a WebGL2-capable testing environment when available for desktop and phone-sized interaction acceptance; diagnose concrete failures rather than guessing. Current cloud-browser acceptance is blocked as above.
2. Reconcile Phase-6/7 roadmap closure against newer owning system docs: cooking, first aid, vehicle component consumers and world-object repair were worked on after the roadmap and must not be blindly rebuilt.
3. Complete missing actual player interactions through existing owners; keep source, tests and human acceptance claims separate.
4. The previously recorded real generated-house environmental-pressure acceptance remains a specific gameplay proof to close. Use existing resident-backed cohort and existing generated openings; add navigation only for demonstrated failure.
5. Full survivors/followers/raiders/conversation/outbreak expansion remains roadmap work, not completed beta content. Do not invent a finished status.

At the next distinct code operation delete the PromptWorldBoundarySmoke.gd / prompt-world-boundary.yml pair and create one fresh pair restricted to the touched module. Do not restore historical standing gameplay gates or routine twelve-seed matrices.

Preserve: 3072×3072 generated island, current world generation, streetlights night-only 20:30–05:30 with shared spacing cadence; exclusive dedicated vehicle rendering (no purple diagnostic); current eight-member infected cohort; exact item/action/state ownership. Actor same-tick consequences currently resolve sequentially by priority/owner/serial; simultaneous movement was discussed but is not implemented.
