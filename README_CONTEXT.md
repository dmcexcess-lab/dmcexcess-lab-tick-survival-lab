# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — REPEATED-SESSION LIFECYCLE REPAIR CLOSED — 2026-09-10

The repeated-session signal-lifetime failure found in the hands-on browser playtest is repaired and published. `NEW GAME` now begins through a deferred button connection, so the asynchronous startup callback retires the title tree only after Godot has finished emitting the original UI signal.

Starting published head: `566bfb59023d3f2fafd61531a87ffbd32a0633be`

Functional published head: `b24bc050b58bf27bd3fca3e8075a9eb117acab31`

Local functional commit with equivalent tree changes: `a05b4a6`

The final documentation head is the commit containing this file after the functional head.

## Completed scope

- `StartupMenu` connects `NewGameButton.pressed` with `CONNECT_DEFERRED`.
- The existing asynchronous preload/world-generation sequence and truthful loading surface are preserved.
- `LEAVE GAME` still returns to the production title scene.
- A second `NEW GAME` creates a fresh gameplay tree and fresh authoritative world/kernel services.
- The previous prompt-owned human-playtest repair verifier/workflow were retired.

## Focused verification

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptRepeatedSessionLifecycleSmoke.gd`
- `.github/workflows/prompt-repeated-session-lifecycle.yml`

The verifier runs exactly two production title-to-game transitions with a real leave-to-title transition between them. It asserts retirement of the first title and gameplay trees, successful second-world boot, and fresh authoritative services. Its workflow also rejects the exact Godot warning `Object was freed or unreferenced while a signal is being emitted` if it appears in the log.

Results on functional head `b24bc050b58bf27bd3fca3e8075a9eb117acab31`:

- local Godot 4.7.1: `PROMPT_REPEATED_SESSION_LIFECYCLE_OK`, exit 0, warning absent;
- GitHub workflow `Prompt repeated session lifecycle`, run `34545792065`: **SUCCESS**;
- `Build and deploy Tick Survival Lab`, run `34545791992`: **SUCCESS**.

After publishing this final context commit, verify its exact-head workflow and Pages runs read-only. Do not write another repair commit in this operation.

## Prior human-playtest repairs preserved

- leave/death returns to the title instead of redirecting externally;
- death opens a hard-paused terminal modal;
- impossible window climbs are not offered;
- action and forage feedback is readable;
- valid inventory rows hide internal IDs and timed consumption warns about nearby threats;
- the nearby-zombie resolution indicator is compact.

## Known playtest findings still open

- Region-boundary and ordinary action latency need phase instrumentation before optimization. Browser observations included typical control round trips around 0.7–0.9 seconds and isolated multi-second stalls; earlier headless measurement found roughly 472 ms p50, 633 ms p95, and one 14.07-second action on a route crossing a streaming boundary, without phase attribution.
- Combat escape/damage cadence and RUN discoverability remain balance/UX follow-ups.

## Protected behavior

Preserve the single authoritative WHEN/TickKernel clock, decision-pause semantics, timed gameplay consequences, input/simulation/UI ownership boundaries, current startup preload/loading behavior, and existing generation/population/perception/gameplay subsystem ownership.

## NEXT OPERATION — wait for explicit approval

Do not begin another code operation automatically. The strongest next technical target is a bounded per-action/streaming phase timing pass to isolate ordinary latency and boundary spikes before attempting optimization. A separate smaller product target is RUN discoverability/combat escape balance.

At the start of the next approved code prompt, delete:

- `game/scripts/ci/PromptRepeatedSessionLifecycleSmoke.gd`
- `.github/workflows/prompt-repeated-session-lifecycle.yml`

Then create a fresh prompt-local verifier/workflow limited to that next target.
