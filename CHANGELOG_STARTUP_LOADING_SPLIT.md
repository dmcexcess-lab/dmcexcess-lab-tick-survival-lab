# Startup Loading Split — 2026-09-10

## Goal

Reduce the single uninterrupted startup wall by separating Godot/menu startup, gameplay-resource loading, and new-game world generation without changing world truth, seed semantics, or gameplay behavior.

## Starting point

- Starting head: `5ba5ad951b0f15145bfde2fcd73fe50f63257acd`
- The previous `main.tscn` was the full production gameplay scene.
- Its root `_ready()` immediately ran the complete canonical boot, including generated-island planning, playable-seed preflight, initial streaming/materialization, player creation, and the rest of the gameplay-service setup before the first usable frame.

## Changes

### Lightweight first scene

`game/main.tscn` is now a small startup menu rather than the full game scene. It contains:

- `NEW GAME`;
- a truthful disabled `CONTINUE — NO SAVE YET` because persistent save/continue does not exist yet;
- a progress indicator and explicit loading status;
- no gameplay renderer, world, simulation, camera, inventory, or other heavy gameplay nodes.

The former full gameplay scene was moved intact to `game/gameplay.tscn`.

### Menu-time resource preload

`game/scripts/ui/StartupMenu.gd` waits for the lightweight menu to paint, then requests `gameplay.tscn` through Godot's threaded ResourceLoader. This moves the heavy gameplay scene/script/resource dependency load behind a responsive menu instead of making it part of the initial scene wall.

This preload does **not** choose a new-game seed or create world truth.

### Explicit post-selection world boot

Pressing `NEW GAME`:

1. enters a visible loading state;
2. finishes the gameplay-scene resource load if necessary;
3. changes the status to `Generating island and activating the starting region…`;
4. instantiates/adds the unchanged production gameplay scene;
5. keeps the menu present while the existing synchronous world/service boot runs;
6. hands current-scene ownership to gameplay only after that boot returns.

This is intentionally phase 1. World generation/materialization internals have not yet been rewritten or spread across frames.

## Important semantics preserved

- Interactive new-game seed selection still occurs only when NEW GAME starts.
- No speculative island/world state is created while the player is merely sitting at the menu.
- `GeneratedIslandCritiqueFixture`, streaming, materialization, gameplay systems, and the single authoritative WHEN clock retain their existing ownership and behavior.
- No fake persistence layer was added; CONTINUE remains disabled until real save data exists.
- Runtime region-boundary streaming spikes are not claimed fixed by this operation.

## Verification

Fresh prompt-local gate:

- `game/scripts/ci/PromptStartupLoadingSplitSmoke.gd`
- `.github/workflows/prompt-startup-loading-split.yml`

Focused run `34503585383` on functional head `64fcedecfd6d55dc052ba7afeea31b6547cc0cee`: **SUCCESS**.

It proves:

- `main.tscn` boots as the lightweight menu;
- no `TickSurvivalGame` exists before NEW GAME;
- generated-island active seed remains unset while the menu is open;
- gameplay resources preload while the menu remains current;
- preload alone does not create world truth;
- NEW GAME enters an explicit loading state;
- the production gameplay scene boots successfully afterward;
- generated island world truth exists only after NEW GAME.

The smoke log also exposed useful startup timing on the CI runner:

- smoke began at approximately `16:41:16.8Z`;
- `PLAYABLE_ISLAND_WORLD_READY` printed at approximately `16:41:29.8Z` (~13 seconds later);
- `CANONICAL_DEMO_BOOT_OK` printed at approximately `16:41:39.2Z` (~9.4 seconds after world-ready).

So the first-scene wall is now split, while the remaining post-click boot still contains large serial chunks that should be profiled and sliced in a later bounded performance pass.

Functional-head Pages run `34503585382`: **SUCCESS** including Web export and deploy.

## Next useful target

Instrument the post-NEW-GAME boot by phase before changing architecture. In particular, separately time:

- global island planning / playable-seed resolution;
- central-area generation;
- playable initial-streaming preflight;
- actual initial streaming/materialization;
- player placement/focus setup;
- later canonical gameplay-service installation.

The current playable-seed path performs an initial-streaming **probe** and later performs the real initial streaming again. That duplication is a strong candidate for investigation, but it remains a correctness guarantee until a focused follow-up proves a safe replacement.
