# Tick 2000 Feel / NPC Proximity Performance Playtest — 2026-09-10

## Scope

Production-path, headless gameplay exercise of the real `main.tscn -> NEW GAME -> gameplay.tscn` composition using the production `PlayerActionController`, `TickKernel`, world, status HUD/query, active infected cohort, and active survivor cohort. This was a feel/performance diagnostic, not a synthetic direct-tick fast-forward and not a Chromium human-input pass.

Owning verifier head: `95722460dfa7278f1c02d387c8651cc97952e85e`

Workflow: `Prompt 2000 tick feel playtest`

Run: `34555968346`

Job: `103128615281`

Result: `PROMPT_TICK_2000_OK`

## Route / completion

- Authoritative tick: `0 -> 2001` (the final accepted action crossed the 2000 target).
- Accepted player actions: `223 / 223`.
- Successful moves: `222`.
- Planned turns: `1`.
- Blocked moves: `0`.
- Unique player cells visited: `223`.
- Start cell: `[1708, 1552]`.
- End cell: `[1862, 1485]`.
- Typical active local population during the run: `10` actors (`6` infected + `4` survivors at the end).

## Measured feel

Normal player decisions are still too expensive to feel like a turn-based simulation instead of input lag:

- Whole accepted action: p50 `364.187 ms`, p95 `487.752 ms`, p99 `513.454 ms`.
- Worst action: `8.763 s`.
- Synchronous `submit_intent()` portion, before presentation can proceed: p50 `112.672 ms`, p95 `120.836 ms`, max `130.155 ms`.
- Largest rendered-frame wait within an action: p50 `245.658 ms`, p95 `304.100 ms`, max `402.252 ms`.
- Player-finished-to-controller-ready tail: p50 `0.124 ms`, p95 `0.150 ms`; this is not the problem.
- Normal actions resolve in one rendered simulation batch: settle-frame p50/p95 `1`. The exceptional long action required `47` frames.

Latency did not accumulate over time. Median whole-action latency was approximately `360–370 ms` in every 500-tick quarter of the run, with p95 approximately `476–492 ms`. This is steady per-turn cost, not a progressive leak.

The single `8.763 s` outlier is consistent with the known transition/streaming class of hitch, but this verifier did not conclusively attribute that individual sample to a specific streaming phase. Do not treat the exact cause of that one sample as proven until phase instrumentation lands.

## NPC work is the dominant scalable problem

Almost every sampled player action had `10` active NPCs. Each player action caused a median/p95 of `10` NPC behavior evaluations, while only about `3` NPC ordinary actions were submitted.

The current behavior architecture has each active infected/survivor behavior independently connected to the shared action lifecycle. On player `action_started`, every active behavior may synchronously drive itself, including perception work, before `submit_intent()` returns to presentation.

Measured aggregate behavior work during the run:

- Infected: `1332` behavior evaluations, `17.081518 s` total evaluation time, max single evaluation `92.810 ms`.
- Survivors: `888` behavior evaluations, `13.025175 s` total evaluation time, max single evaluation `359.930 ms`.
- Combined: about `30.1 s` of measured behavior evaluation over `222` player action starts, or roughly `135.6 ms` of NPC behavior evaluation per player decision in aggregate.

The shared `TickKernel` is authoritative and deterministic, but the player-facing orchestration still exposes scheduler behavior. `PlayerActionController` advances one due-tick batch per rendered frame. Actors whose actions have different durations therefore complete at different due ticks and can appear to update serially across presentation frames. The run also shows that even when only one rendered batch is needed, that batch itself is far too expensive.

## Mood / stats HUD is not the regression source

Direct measurement rules out the canonical status/moodlet presentation as a material performance cost:

- Status query: p50 `0.039 ms`, p95 `0.044 ms`, max `0.093 ms`.
- Explicit HUD refresh: p50 `0.088 ms`, p95 `0.097 ms`, max `0.099 ms`.

These costs are orders of magnitude below the `364–488 ms` ordinary action latency. The recent mood/status visibility work may have coincided with the user noticing the slowdown, but it is not responsible for the measured turn cost. Do not remove or simplify the status/moodlet UI as a performance fix.

## Recommended implementation target

Keep the deterministic tick simulation, but stop making the player experience the scheduler directly.

1. Replace N independent NPC reactions to the player's `action_started` signal with one bounded turn/cohort coordinator. Capture one stable decision snapshot, evaluate active actors as a cohort, and enqueue their intents/results without N global callback fan-outs.
2. Add perception invalidation/caching and a cheap spatial broad phase. Recompute expensive LOS/memory only when the observer, relevant target, or visibility-affecting world state actually changes. Do not run a full 12-cell-radius visibility/LOS scan for every active actor on every player action if nothing relevant changed.
3. Separate simulation resolution from presentation. Resolve the current player decision to a coherent decision boundary internally, then present all actor changes together/concurrently. Preserve authoritative due ticks internally; do not make engine scheduling visually read as one NPC moving after another. Once CPU cost is low enough, a short simultaneous animation window can make turns legible instead of laggy.
4. Instrument and budget streaming independently. Prewarm/incrementally materialize upcoming regions so a cell/region transition cannot generate a multi-second frame.

Performance acceptance target for the next pass: ordinary player-decision simulation under about `50 ms` with the current ~10–12 active actors, no individual rendered frame over `100 ms`, and no multi-second transition hitch. Presentation animation can then be intentionally paced independently of simulation CPU time.

## Temporary verification ownership

This prompt owns these temporary verification files:

- `game/scripts/ci/PromptTick2000FeelPlaytest.gd`
- `.github/workflows/prompt-tick-2000-feel.yml`

Retire both at the start of the next code operation unless that operation explicitly needs to extend this same verifier.
