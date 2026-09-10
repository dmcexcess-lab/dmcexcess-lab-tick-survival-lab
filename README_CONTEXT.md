# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. For the next distinct repository operation, follow the normal SOP from this recorded final head.

## Current checkpoint — STARTUP LOADING SPLIT PHASE 1 CLOSED — 2026-09-10

The core feature roadmap remains closed and the game remains a beta candidate. This bounded performance/UX operation separates the old single startup wall into a lightweight first menu, menu-time gameplay-resource preload, and explicit post-selection world boot.

Starting head:

`5ba5ad951b0f15145bfde2fcd73fe50f63257acd`

Owning fully gated functional head:

`64fcedecfd6d55dc052ba7afeea31b6547cc0cee`

Documentation head immediately before this final context write:

`245c845bdd88b7da448712349f438627e7c845f1`

## Root cause / prior startup shape

Before this pass, `game/main.tscn` was the full production gameplay scene. Its root `_ready()` immediately executed the complete canonical boot before the player received a usable game frame.

That meant the initial wall stacked:

1. Godot/scene startup;
2. the entire gameplay script/resource dependency graph;
3. generated-island planning and playable-seed resolution;
4. central-area generation;
5. playable initial-streaming preflight;
6. actual initial streaming/materialization;
7. player creation/focus setup;
8. the remaining gameplay-service boot.

This matched the user's observation that loading work was not meaningfully spread out.

## Implemented phase-1 split

### Lightweight first scene

`game/main.tscn` is now a small startup/menu scene only. It no longer directly contains the production gameplay renderer, camera, simulation, HUD, inventory, crafting, map, interaction, or other heavy gameplay nodes.

The former full production scene was moved intact to:

- `game/gameplay.tscn`

The menu provides:

- `NEW GAME`;
- disabled `CONTINUE — NO SAVE YET`;
- a loading progress indicator;
- explicit status text.

There is currently no persistent save/continue implementation in the repository, so CONTINUE is deliberately truthful rather than simulated.

### Menu-time gameplay-resource preload

`game/scripts/ui/StartupMenu.gd` lets the lightweight menu paint first, then requests `res://gameplay.tscn` with Godot's threaded `ResourceLoader`.

This allows the heavy gameplay scene/script/resource dependency graph to load while the player can already see the menu.

Resource preloading does **not** choose a new-game seed or generate world truth.

### Post-NEW-GAME world boot

Pressing NEW GAME:

1. enters a visible loading state;
2. finishes the gameplay-scene resource load if needed;
3. shows `Generating island and activating the starting region…`;
4. instantiates/adds the unchanged production gameplay scene;
5. keeps the menu present while the existing synchronous generated-world/service boot runs;
6. hands current-scene ownership to gameplay only after production boot returns.

Interactive new-game seed selection therefore remains where it belongs: after the player chooses NEW GAME.

## What this phase intentionally does not claim

This phase does **not** yet spread the internals of world generation/materialization across frames. It establishes the scene/loading boundary and removes the full gameplay dependency graph from the initial menu scene.

It also does not fix the separately confirmed runtime region-streaming long-frame spikes that can trigger browser `Page Unresponsive` warnings on desktop Firefox/Chromium.

No save/persistence system was added.

## Verification

Previous WALK prompt verifier/workflow was retired at operation start.

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptStartupLoadingSplitSmoke.gd`
- `.github/workflows/prompt-startup-loading-split.yml`

Focused run:

- `34503585383` on `64fcedecfd6d55dc052ba7afeea31b6547cc0cee` — **SUCCESS**.

The smoke proves:

- `main.tscn` starts as the lightweight menu;
- production `TickSurvivalGame` is absent before NEW GAME;
- generated-island active seed remains unset while the menu is open;
- gameplay resources preload while the menu remains current;
- menu preload alone does not create world truth;
- NEW GAME enters explicit loading state;
- the unchanged production gameplay scene then boots successfully;
- generated-island world truth exists only after NEW GAME.

Production smoke log timing on the CI runner also exposed the next bottleneck:

- smoke/process start approximately `16:41:16.8Z`;
- `PLAYABLE_ISLAND_WORLD_READY` approximately `16:41:29.8Z`, about **13 seconds later**;
- `CANONICAL_DEMO_BOOT_OK` approximately `16:41:39.2Z`, another **~9.4 seconds later**.

Thus the new menu/resource phase is split successfully, while roughly 22 seconds of post-selection generated-world + service boot remains serial in that headless run.

Functional-head Pages/Web publication:

- run `34503585382` on `64fcedecfd6d55dc052ba7afeea31b6547cc0cee` — **SUCCESS**, including Web export and deploy.

After this final context commit, perform exact-final-head Pages verification read-only. No further repository writes are permitted in this operation.

## Documentation

Operation-specific ledger:

- `CHANGELOG_STARTUP_LOADING_SPLIT.md`

Documentation commit immediately before this final context write:

`245c845bdd88b7da448712349f438627e7c845f1`

## Established systems to preserve

Unless a focused failure proves otherwise, preserve:

- the single authoritative WHEN/TickKernel clock;
- same-WHEN deterministic movement batching and decision-pause semantics;
- healthy ordinary WALK remaining fatigue-free; RUN remains routinely fatiguing;
- current settlement-first procedural island and building-derived population;
- current road hierarchy and dirt/gravel/paved contracts;
- current generated weather/day-night/physical lighting/night-only streetlights;
- current power/water infrastructure;
- observer-scoped infected/survivor perception and existing population ownership;
- inventory/equipment/sustainment/crafting/skills/doors/windows/utilities/vehicles/combat systems already closed;
- dedicated vehicle rendering without the retired purple diagnostic artifact;
- no generated rivers/wastewater/sewer/septic resurrection;
- no routine broad seed matrices for bounded prompt closure.

## Confirmed performance issue still open

Ordinary live play can hit large region-streaming long frames severe enough for browser `Page Unresponsive` warnings. The assistant reproduced one around the ~800-tick area in an actual deployed-build playtest, and the user reports the same behavior consistently in desktop Firefox.

Do not dismiss this as renderer/test-machine noise. It is a confirmed production performance problem.

## NEXT OPERATION — startup loading phase 2: profile and slice post-NEW-GAME boot

If the user continues this loading/performance work, do **not** redesign blindly. First instrument the post-NEW-GAME production boot by phase, then use those measurements to spread/cache/defer the dominant chunks while preserving deterministic world truth.

Priority measurement boundaries:

1. global island plan / playable-seed resolution;
2. central-area generation;
3. playable initial-streaming preflight;
4. actual initial streaming/materialization;
5. player placement + streaming focus;
6. remaining canonical gameplay-service installation.

Important candidate: `GeneratedIslandCritiqueFixture._resolve_playable_boot()` performs an initial-streaming **probe**, and `build()` later performs the real initial streaming/materialization again. Investigate whether that duplicated work can be safely reused or transformed into a staged prewarm, but preserve the playable-seed correctness guarantee unless a fresh verifier proves the replacement.

For the next **code** operation, retire this prompt-owned verifier pair first:

- `game/scripts/ci/PromptStartupLoadingSplitSmoke.gd`
- `.github/workflows/prompt-startup-loading-split.yml`

Then create a fresh prompt-local verifier for only the next requested behavior and follow the normal direct-to-main closure SOP.

This `README_CONTEXT.md` commit is the **FINAL repository write for startup loading split phase 1**. After it lands, perform read-only exact-head and CI/Pages verification only.
