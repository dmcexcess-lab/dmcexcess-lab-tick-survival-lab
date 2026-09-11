# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — 2000-TICK FEEL / NPC PROXIMITY PERFORMANCE PLAYTEST CLOSED — 2026-09-10

The player reported that the game still does not feel right as a tick-based simulation: nearby NPCs make ordinary movement feel like sudden lag, actors appear to resolve one at a time rather than as one coherent turn, and the slowdown seemed to return when mood/stats presentation was restored. The player requested a 2000-tick playtest/report before changing the architecture.

Starting head for this operation: `a98f0d2238ca44caa433becc152afd8ac7bc8d1b`

Owning verifier head: `95722460dfa7278f1c02d387c8651cc97952e85e`

Documentation head immediately before this final context write: `706c65b16ff999325c5ed7a91da5367550bd7686`

Closure ledger: `CHANGELOG_TICK_2000_FEEL_PLAYTEST.md`

The commit containing this file is the final repository write for this operation. After it lands, verification is read-only only.

## Playtest method

The prompt-owned verifier boots the actual production `main.tscn`, presses `NEW GAME`, and exercises the real `gameplay.tscn` composition with production `PlayerActionController`, `TickKernel`, world, status HUD/query, active infected cohort, and active survivor cohort.

This was a production-path headless gameplay/performance exercise, not a synthetic direct-tick fast-forward and not a literal Chromium/manual input session. It advances only through accepted production player intents and normal authoritative WHEN resolution.

Owning workflow:

- `Prompt 2000 tick feel playtest`
- run `34555968346`
- job `103128615281`
- result: `PROMPT_TICK_2000_OK`

## Route / completion

- authoritative tick `0 -> 2001`; the final accepted action crossed the 2000 target;
- `223 / 223` accepted player actions;
- `222` successful moves;
- `1` planned turn;
- `0` blocked moves;
- `223` unique player cells visited;
- start cell `[1708, 1552]`;
- end cell `[1862, 1485]`;
- normal local active population was approximately `10` actors; final cohort was `6` infected + `4` survivors.

## Primary performance finding

The player's feel complaint is valid. Ordinary accepted actions remain far too expensive to read as responsive turn resolution:

- whole accepted action p50 `364.187 ms`;
- p95 `487.752 ms`;
- p99 `513.454 ms`;
- worst action `8.763 s`;
- synchronous `submit_intent()` p50 `112.672 ms`, p95 `120.836 ms`, max `130.155 ms`;
- largest rendered-frame wait inside an action p50 `245.658 ms`, p95 `304.100 ms`, max `402.252 ms`;
- player-finished-to-controller-ready tail p50 `0.124 ms`, p95 `0.150 ms`.

Normal actions usually completed in one rendered simulation batch (`settle_frames` p50/p95 `1`). The exceptional long action required `47` rendered frames.

Latency stayed approximately flat through the run. Whole-action p50 stayed about `360–370 ms` in all four 500-tick quarters and p95 stayed about `476–492 ms`. This is steady per-turn cost, not a progressive leak accumulating with world time.

The single `8.763 s` outlier is consistent with the known transition/streaming class of hitch, but this verifier did not conclusively attribute that individual sample to a specific streaming phase. Do not claim an exact streaming subphase until targeted instrumentation proves it.

## NPC fan-out is the dominant scalable cost

Almost every player action had `10` active NPCs. Each player action caused a median/p95 of `10` NPC behavior evaluations while only about `3` NPC ordinary actions were actually submitted.

Measured behavior work:

- infected: `1332` behavior evaluations, `17.081518 s` total evaluation time, max single evaluation `92.810 ms`;
- survivors: `888` behavior evaluations, `13.025175 s` total evaluation time, max single evaluation `359.930 ms`;
- combined: about `30.1 s` measured behavior evaluation over `222` player action starts, roughly `135.6 ms` of NPC behavior evaluation per player decision in aggregate.

Current behavior services independently subscribe to the shared action lifecycle. On player `action_started`, each active infected/survivor behavior may synchronously drive itself, including perception work, before the player's submit path can return to presentation. The current architecture therefore pays N behavior/perception reactions per player action even when most actors ultimately do not submit a meaningful action.

Perception is a likely dominant sub-cost: individual observers can recompute a roughly 12-cell-radius visibility field, LOS, acquisition/memory, and related state independently. The next optimization should prove/cache/invalidate this work rather than repeatedly scanning unchanged local state for every active actor.

## Why it feels sequential even with one authoritative clock

The simulation does use one deterministic authoritative `TickKernel` clock. It is not one independent clock per actor.

However, `PlayerActionController` currently exposes scheduler cadence to presentation by advancing one due-tick batch per rendered frame. Actor actions can have different durations, so their completions can occur on different due ticks and therefore different rendered frames. That makes nearby actors appear to resolve one after another rather than as one coherent player turn.

The 2000-tick run adds an important qualification: ordinary actions usually needed only one rendered batch, so the normal `364–488 ms` lag is not caused merely by dozens of sequential batches. A single normal turn is already computationally too heavy, especially because NPC behavior/perception fans out synchronously around player action start. Presentation cadence then compounds the feel problem when multiple due ticks are involved.

Animation can improve the visual interpretation, but animation alone cannot hide a 300–500 ms simulation frame. CPU work must be reduced first; then outcomes should be presented concurrently in a short intentional animation window.

## Mood / stats are not the performance regression

Direct measurement rules out the current canonical status/moodlet UI as a material source of the lag:

- status query p50 `0.039 ms`, p95 `0.044 ms`, max `0.093 ms`;
- explicit HUD refresh p50 `0.088 ms`, p95 `0.097 ms`, max `0.099 ms`.

These are orders of magnitude below ordinary action latency. The mood/stats repair coincided with the user noticing the slowdown but did not cause it. Do not remove or simplify the status/moodlet UI as a performance fix.

## Recommended architecture for the next implementation pass

Keep tick-based determinism. Change orchestration and presentation so the player does not experience internal scheduler mechanics.

1. Replace N independent NPC reactions to player `action_started` with one bounded cohort/turn coordinator. Capture one stable decision snapshot, evaluate active actors together, and enqueue their intents/results without N global callback fan-outs.
2. Add perception invalidation/caching plus a cheap spatial broad phase. Recompute expensive LOS/memory only when observer position/facing, relevant targets, or visibility-affecting world state changes.
3. Separate simulation resolution from presentation. Resolve the current player decision to a coherent decision boundary internally, then present all resulting actor changes together/concurrently. Preserve authoritative due ticks internally; do not visually expose one-NPC-after-another scheduler ordering.
4. Instrument and budget streaming separately. Prewarm/incrementally materialize upcoming regions so boundary transitions cannot create a multi-second frame.
5. After CPU cost is low enough, use a short concurrent animation window to communicate movement/combat/state changes. Animation should explain the turn, not mask blocking work.

Performance acceptance target for the next pass:

- ordinary player-decision simulation under roughly `50 ms` with the current ~10–12 active actors;
- no individual rendered frame over `100 ms`;
- no multi-second transition hitch;
- player-visible actor outcomes presented coherently/concurrently rather than exposing internal due-tick sequencing.

## Previous verifier cleanup

At this operation's start, the preceding stats/moodlet prompt-owned pair was retired:

- `game/scripts/ci/PromptStatsMoodletsSmoke.gd`
- `.github/workflows/prompt-stats-moodlets.yml`

Current temporary prompt-owned verification pair:

- `game/scripts/ci/PromptTick2000FeelPlaytest.gd`
- `.github/workflows/prompt-tick-2000-feel.yml`

Retire both at the start of the next code operation unless that operation explicitly extends this same verifier.

## Protected behavior

Preserve:

- one deterministic authoritative WHEN/TickKernel clock and decision semantics;
- real production world/actor/perception/condition state rather than demo-only approximations;
- System 34 condition state/query semantics and the current status/moodlet UI presentation;
- terrain bulk-write/coalescing optimization and previous streaming improvements;
- STATS / INVENTORY / CRAFT / MENU modal ownership and interaction blocking;
- current world generation, utilities, weather, interaction, vehicle, combat, population, and rendering ownership boundaries unless a measured hotspot requires a bounded change.

The old `PlayerActionController` one-due-tick-batch-per-rendered-frame presentation behavior is no longer protected as a player-facing requirement. Internal deterministic due-tick ordering may remain, but presentation should be redesigned so the scheduler does not look like lag or serial actor animation.

## Other known player targets

Still separate from this completed measurement pass unless explicitly promoted:

- more realistic vehicle placement tied to roads/residences/business/parking context;
- higher believable road/building density and more alternate routes/loops;
- removal of the player-facing `ZOMBIES`/`ZOMBIES NEARBY` status bar/indicator while preserving underlying infected systems;
- gameplay-density polish: clearer affordances, less dead travel, stronger first-day survival decisions, clearer time costs, distinct building usefulness, and stronger vehicle progression.

## NEXT OPERATION — wait for explicit implementation target

Do not change simulation architecture automatically from this measurement-only request.

If the player promotes the performance fix, start with the smallest coherent implementation pass around NPC decision fan-out + perception caching/invalidation + coherent turn presentation, preserving deterministic TickKernel truth. Instrument before/after and compare against the 2000-tick baseline above.

At the start of that next code operation, retire the current prompt-owned verifier pair unless intentionally extending it.
