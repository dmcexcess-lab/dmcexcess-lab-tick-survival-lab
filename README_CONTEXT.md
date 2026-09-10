# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. For the next distinct repository operation, follow the normal SOP from this recorded final head.

## Current checkpoint — PRODUCTION TICK-1000 PLAYTEST CLOSED — 2026-09-10

The core feature roadmap remains closed and the game remains a beta candidate. This bounded operation exercised the actual production startup/gameplay path to authoritative tick 1000 using real player movement intents. No gameplay/product code was changed by this operation; only its prompt-local verifier/workflow and documentation were added/repaired.

Starting head for this resumed operation:

`b33078700d6791bc090f30d5fb3460c76ab00c6d`

Owning successful verifier head:

`1147dfea23feb55367ce05f46510d9f18e1ae65e`

Documentation head immediately before this final context write:

`44474cad7aa23ea3e5f6ffdaf46a0559683ac660`

## Production playtest contract

The verifier uses the production path rather than a synthetic TickKernel fast-forward:

1. load `main.tscn`;
2. press the real `NEW GAME` button;
3. allow the real `gameplay.tscn` and `GameMain` composition to boot;
4. wait for the actual production `PlayerActionController`, `WorldState`, `TickKernel`, perception service, and renderer;
5. submit ordinary movement intents through `PlayerActionController.submit_intent()`;
6. allow the live controller to advance authoritative WHEN via its normal one-batch-per-rendered-frame behavior;
7. stop only after authoritative tick 1000 or a concrete failure.

The verifier does not teleport the player, directly alter placement, or directly fast-forward WHEN.

## Result — authoritative tick 1000 reached

Focused workflow:

- `Prompt 1000 tick production playtest`
- run `34531513998` on `1147dfea23feb55367ce05f46510d9f18e1ae65e` — **SUCCESS**
- terminal marker: `PROMPT_TICK_1000_PLAYTEST_OK`

Measured production result:

- start tick: `0`
- final tick: `1000`
- accepted actions: `100`
- rejected actions: `0`
- successful movement actions: `100`
- blocked movement actions: `0`
- turns: `0`
- permanent action stalls: `0`
- unique player cells visited: `101`
- start anchor: `(1708, 1552)`
- end anchor: `(1708, 1452)`
- min anchor: `(1708, 1452)`
- max anchor: `(1708, 1552)`
- startup frames after production scene transition: `3`
- maximum settle frames for an accepted action: `1`
- action-loop wall time: `61.187584 s`
- p50 accepted-action wall time: `472.373 ms`
- p95 accepted-action wall time: `632.991 ms`
- p99 accepted-action wall time: `686.130 ms`
- maximum accepted-action wall time: `14.068689 s`
- accepted actions >=100 ms: `100 / 100`
- accepted actions >=500 ms: `17 / 100`
- final visible cells: `152`
- final maximum luminance: `0.973427571846233`

The path moved 100 cells north and crosses the technical 128-cell streaming boundary at world Y=1536, so at least one real streaming-region transition occurred during this run.

## Confirmed correctness findings

On the exercised production path through tick 1000:

- production NEW GAME boot completed;
- player placement remained valid;
- all 100 submitted movement actions were accepted;
- authoritative WHEN advanced to exactly 1000;
- no action permanently stalled;
- no movement was rejected or collision-blocked on the chosen path;
- perception remained populated;
- the player remained visible;
- physical-lighting presentation remained nonblack and valid at the end of the run.

No new production correctness failure was confirmed by this playtest.

## Confirmed performance finding

The existing long-frame/per-action latency concern remains real and is now quantified on a 1000-tick production run.

Even though every accepted action resolved within one rendered settle frame, the frame/action wall times were poor in the GitHub-hosted headless production environment:

- median about 472 ms;
- p95 about 633 ms;
- p99 about 686 ms;
- 17% of accepted actions exceeded 500 ms;
- one accepted action took about 14.07 seconds.

Because this verifier did not record the action index/streaming region associated with the maximum, do **not** state that the 14-second spike was definitely the region-boundary action. The route proves a boundary was crossed, but exact attribution requires a focused per-action streaming timing pass.

This result is consistent with the already-open browser long-frame/streaming concern and makes that the strongest current technical-performance target if the user promotes performance work.

## Earlier verifier failures were not game failures

Several attempts before the successful run failed only because of prompt-verifier defects:

- an initial run used the wrong Godot version; standard project CI is Godot 4.6.1;
- the first production-start version assumed gameplay services existed directly under `main.tscn`, but production `main.tscn` is the startup menu;
- a later verifier used invalid GDScript `bool(...)` constructor calls and crashed after production boot;
- the next verifier waited on a nonexistent/private `_session_started` readiness assumption even though `CANONICAL_DEMO_BOOT_OK` had already printed.

The final verifier instead uses concrete live production service readiness. None of these verifier failures required a gameplay-code change.

## Publication status at owning verifier head

Pages/Web publication:

- run `34531514038` on `1147dfea23feb55367ce05f46510d9f18e1ae65e` — **SUCCESS**

After this final context commit, perform exact-final-head Pages/status verification read-only. No further repository writes are permitted in this operation.

## Documentation

Operation-specific ledger:

- `CHANGELOG_TICK_1000_PLAYTEST.md`

Documentation commit immediately before this final context write:

`44474cad7aa23ea3e5f6ffdaf46a0559683ac660`

## Established systems to preserve

Unless a focused failure proves otherwise, preserve:

- the single authoritative WHEN/TickKernel clock;
- same-WHEN deterministic movement batching and decision-pause semantics;
- one-batch-per-rendered-frame production player-action resolution;
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

### 1. Player action / streaming long frames

The tick-1000 production run quantified substantial wall-time latency and one ~14-second accepted-action frame while traversing a route that crossed a streaming-region boundary. Root cause is not yet isolated.

If promoted, instrument each action with:

- action index and intent;
- tick before/after;
- anchor before/after;
- streaming region before/after;
- total action/frame duration;
- streaming discovery/generation/materialization/snapshot/commit/render notification phase timings.

Use those measurements to locate the ordinary ~0.47–0.63 s cost and the exceptional multi-second spike before attempting architectural changes.

### 2. Startup synchronous phase

The long post-NEW-GAME synchronous boot can still pause the loading ellipsis because the main thread itself is blocked. The successful production run showed world/gameplay boot completing, but this operation did not attempt startup phase-2 optimization.

## NEXT OPERATION — wait for the next explicit bounded target

Do not automatically turn this diagnostic into a performance rewrite. The user asked for a tick-1000 playtest and report; that request is now complete.

For the next **code** operation, retire this prompt-owned verifier pair first:

- `game/scripts/ci/PromptTick1000Playtest.gd`
- `.github/workflows/prompt-tick-1000-playtest.yml`

Then create a fresh prompt-local verifier for only the next requested behavior and follow the normal direct-to-main closure SOP.

The previous MAP/loading verifier pair predates this diagnostic and should also be considered retired historical prompt machinery if still present; do not reuse it as the next prompt verifier.

This `README_CONTEXT.md` commit is the **FINAL repository write for the production tick-1000 playtest operation**. After it lands, perform read-only exact-head and CI/Pages verification only.
