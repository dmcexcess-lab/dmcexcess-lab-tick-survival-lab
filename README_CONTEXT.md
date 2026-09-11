# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — PLAYER-FACING ZOMBIE WARNING REMOVED — 2026-09-10

This was a deliberately narrow UI closure following the completed 2000-tick feel/performance playtest.

Starting head after retiring the previous prompt-owned 2000-tick verifier pair: `c8f86a0275946d93a5a0971017d36d51764b8ba9`

Executable/UI head: `621f28ef880d41e8beb730134310c078f7c9bded`

The commit containing this file is the final repository write for this operation. After it lands, verification is read-only only.

## Completed change

`game/scripts/ui/WorldResolutionIndicator.gd` no longer presents the player-facing `ZOMBIES NEARBY` message.

The change removed only the presentation constant/branch that selected that text when the active infected cohort was non-empty.

Preserved unchanged:

- infected cohort activation and proximity behavior;
- infected simulation, perception, combat, and opening-pressure logic;
- authoritative TickKernel/WHEN behavior;
- the `LOADING` region-transition indicator and its existing streaming signal path;
- the rest of the canonical status HUD and moodlet/condition presentation.

This is a UI cleanup only, not a zombie-system simplification or performance workaround.

## Verification

Read-back of `WorldResolutionIndicator.gd` at executable head `621f28ef880d41e8beb730134310c078f7c9bded` confirms:

- `ZOMBIES_TEXT` is absent;
- the infected-active branch that set `ZOMBIES NEARBY` is absent;
- `_refresh()` still shows `LOADING` while `_loading_visible` is true;
- infected cohort wiring remains present for the existing resolution-indicator composition/snapshot contract.

GitHub Pages build/deploy for executable head:

- workflow: `Build and deploy Tick Survival Lab`;
- run: `34558848632`;
- head: `621f28ef880d41e8beb730134310c078f7c9bded`;
- build job: success;
- deploy job: success.

## Previous performance baseline remains authoritative

The immediately preceding 2000-tick production-path playtest remains the performance baseline. Do not reinterpret this UI removal as addressing the measured simulation cost.

Key findings from that closed pass:

- whole accepted action p50 about `364 ms`, p95 about `488 ms`, p99 about `513 ms`;
- one multi-second transition-class outlier remained;
- approximately 10 active NPCs caused synchronous behavior/perception fan-out around player actions;
- combined measured NPC behavior evaluation was about `135.6 ms` per player decision in aggregate;
- status/moodlet query and HUD refresh costs were negligible relative to the action latency.

The existing recommendation remains: optimize NPC decision fan-out/perception work and coherent turn presentation before treating animation as a solution.

## Prompt-owned verifier cleanup

The preceding 2000-tick temporary verifier pair was retired before this UI change:

- `game/scripts/ci/PromptTick2000FeelPlaytest.gd`
- `.github/workflows/prompt-tick-2000-feel.yml`

There is no new prompt-owned verifier pair from this UI-only operation.

## Protected behavior

Preserve:

- one deterministic authoritative WHEN/TickKernel clock and decision semantics;
- real production world/actor/perception/condition state;
- System 34 condition state/query semantics and current status/moodlet UI;
- existing terrain bulk-write/coalescing and streaming improvements;
- STATS / INVENTORY / CRAFT / MENU modal ownership and interaction blocking;
- current world generation, utilities, weather, interaction, vehicle, combat, population, and rendering ownership boundaries unless a measured hotspot requires a bounded change;
- the `LOADING` transition indicator unless a later UX pass intentionally replaces it.

Do not restore the player-facing `ZOMBIES` / `ZOMBIES NEARBY` indicator unless explicitly requested.

## Known player targets still open

- reduce ordinary action latency caused by NPC behavior/perception fan-out;
- make nearby actor outcomes feel coherent/concurrent rather than visibly serial;
- eliminate remaining multi-second transition hitching;
- more realistic vehicle placement tied to roads, residences, businesses, parking, and roadside context;
- higher believable road/building density with alternate routes/loops while keeping rural/open farmland character;
- gameplay-density polish: clearer affordances, less dead travel, stronger first-day decisions, clearer time costs, distinct building usefulness, and stronger vehicle progression.

## NEXT OPERATION

Continue from the measured performance work unless the player promotes another target.

For performance, start with the smallest coherent pass around NPC decision fan-out and perception caching/invalidation, preserving deterministic TickKernel truth. Measure before/after against the closed 2000-tick baseline.

Do not broadly reread the repository unless a targeted failure requires it.
