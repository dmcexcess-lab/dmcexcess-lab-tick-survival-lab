# Tick 1000 Production Playtest — 2026-09-10

## Scope

Bounded production playtest through the real startup and gameplay path. The verifier loads `main.tscn`, presses the actual `NEW GAME` button, waits for `gameplay.tscn` and live production services, then submits ordinary `PlayerActionController` movement intents until the authoritative `TickKernel` reaches tick 1000. It does not teleport the player or directly mutate/fast-forward WHEN.

## Owning verifier head

`1147dfea23feb55367ce05f46510d9f18e1ae65e`

Focused workflow run:

- `34531513998` — **SUCCESS**

Pages/Web publication for the same head:

- `34531514038` — **SUCCESS**

## Result

The production run reached authoritative tick **1000 exactly** and emitted `PROMPT_TICK_1000_PLAYTEST_OK`.

Measured result:

- start tick: 0
- final tick: 1000
- startup frames after NEW GAME transition: 3
- player start anchor: `(1708, 1552)`
- player end anchor: `(1708, 1452)`
- accepted actions: 100
- rejected actions: 0
- successful movement actions: 100
- blocked movement actions: 0
- turns: 0
- unique player cells visited: 101
- permanent action stalls: 0
- maximum settle frames for an accepted action: 1
- action-loop wall time: 61.187584 seconds
- p50 accepted-action wall time: 472.373 ms
- p95: 632.991 ms
- p99: 686.130 ms
- maximum accepted-action wall time: 14.068689 seconds
- actions >=100 ms: 100/100
- actions >=500 ms: 17/100
- final visible cells: 152
- final maximum luminance: 0.973427571846233

The 100-cell northbound path crosses the 128-cell streaming-grid boundary at world Y=1536, so this run exercises at least one real streaming-region transition. The verifier did not record the action index of the 14.069-second maximum, so that spike must not be attributed to the boundary without a more focused timing probe.

## Findings

Correctness remained intact through tick 1000 on this path: player placement survived, every submitted movement action was accepted, authoritative WHEN advanced, no action remained busy, perception remained populated, the player remained visible, and physical-lighting textures/luminance remained valid.

Performance is the material finding. Even though the controller resolved each accepted action within one rendered settle frame, every action took at least 100 ms wall time in this headless production run, median latency was about 472 ms, 17% exceeded 500 ms, and one action took about 14.07 seconds. This corroborates the already-open long-frame concern but does not by itself isolate the responsible subsystem.

Production startup itself was not the source of the earlier 30-minute apparent stall. Earlier prompt verifier attempts failed from verifier defects after `CANONICAL_DEMO_BOOT_OK`; the Godot process then remained alive until CI timeout. Those failures are not product failures.

## Verifier history during this operation

Two prompt-verifier defects were corrected before the successful run:

1. invalid GDScript `bool(...)` constructor usage;
2. waiting on a nonexistent/private `_session_started` readiness assumption instead of live production services.

Neither required a gameplay-code change.

## Next bounded diagnostic

If performance work is promoted, instrument per-action timing with action index, tick before/after, player anchor, streaming region before/after, and streaming/materialization phase timings. The first target should be identifying the 14-second long frame and the persistent ~0.47–0.63 second ordinary-action cost without changing simulation semantics.
