# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE ROADMAP RESET — 2026-09-25

Documentation-only operation following the user's explicit scope decisions. The commit containing this handoff is the final repository write for this operation; identify its exact SHA from `main`. Subsequent publication verification is read-only.

Starting main: `a6c48cdb582ff08d9814a70fdce0bf4a3ba9118d`.

Unchanged executable/UI owning head: `621f28ef880d41e8beb730134310c078f7c9bded`.

## Completed

- Replaced ROADMAP.md with a finite survival release plan, explicit exclusions, implementation order and player-facing acceptance criteria.
- Reconciled PROJECT_NORTH_STAR.md and README.md with the new scope.
- Recorded the superseding September 25 decision in DESIGN_DECISIONS.md without erasing historical decisions.
- Updated CHANGELOG_LATEST.md.
- No gameplay, generation, test, workflow or process code changed. No runtime feature was removed or newly implemented by this documentation operation.

## Authoritative direction

Core loop: scavenge, fight, craft, survive on the existing persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well. No freeform building or settlement management.

Keep zombies. Retire living survivor/follower/raider/social runtime and broader household/job/society/outbreak simulation. Preserve shared mechanics used by zombies/player; cheap initial generation data may remain without live society dependencies.

Shared ticks, interruptible versus committed actions, simultaneous per-tick resolution, mob force and fear define combat. It should feel like real time with automatic pauses, not manually selectable tactical pauses. Hard application pause still protects real-life interruptions without cancellation or free orders.

Required remaining scope includes durable save/continue, responsive combat, practical fortified-house survival, zombie-damageable power/water features, realistic vehicle placement via parking/carport/garage/site enrichment, persistent crashes/abandoned or dead-occupant fortified-house stories, loot and moodlet/needs balance, combat cleanup and repeated-day desktop/Safari acceptance.

Old “core roadmap closed” language is superseded. All implementation phases of the new roadmap remain open until their actual outcomes are accepted. Exact formulas/rates are bounded implementation design/tuning work, not newly implemented facts.

## Verification / publication

Documentation diff and consistency reviewed; `git diff --check` passed before this final handoff write. The final documentation bundle must also pass that read-only check. Runtime and workflow files are unchanged; no gameplay tests were run or invented for a documentation-only task.

The starting main's exact-head Pages run `34559224322` succeeded. The final documentation commit's Pages run cannot exist before publication; verify its exact SHA and terminal result read-only after publishing. Do not equate deployment success with gameplay acceptance.

There is no prompt-owned verifier pair from this operation. The previous 2000-tick pair was already retired. The next code prompt should confirm there is no current pair to delete, then create its focused module-local verifier/workflow under the unchanged README_SOPS.md policy. Do not revive historical suites or the twelve-seed matrix. The review's suggested SOP changes were not enacted by this roadmap request.

## Retained performance evidence

CHANGELOG_TICK_2000_FEEL_PLAYTEST.md is the measured baseline: ordinary action p50 about 364 ms, p95 488 ms, p99 513 ms; worst 8.763 s; roughly 10 active NPCs; aggregate NPC evaluation about 135.6 ms per player decision. Status/moodlet query costs were negligible. These are recorded headless figures, not measurements from the user's phone. The specific worst action's cause was not conclusively attributed.

Keep terrain bulk-write/coalescing improvements and shared WHEN truth. Retiring survivors alone does not prove zombie performance solved. Resolve remaining fan-out, repeated perception work, presentation coherence and measured streaming hitches without a new engine.

## NEXT OPERATION

Phase 1 of ROADMAP.md: retire the live survivor/social runtime from production composition while preserving zombies and shared mechanics. This roadmap-writing request did not execute that code phase. Follow the existing bounded-operation approval gate when beginning new implementation.

Targeted starting reads: production composition consumers of ActiveSurvivorCohortService and SurvivorNpcBehaviorService; survivor/social interaction consumers; the exact dependencies shared with zombie cohorts. Determine existing owners and measure the production path before changing it. Do not broadly rediscover the repo.

Close the bounded retirement with ordinary startup/zombie/time/inventory/utility behavior and before/after cost evidence. Next comes Phase 2's shared-tick combat contract, mob force/fear and measured zombie decision/perception/presentation work. Save/continue is the next required release phase, not optional polish.

## Protected behavior

Preserve WHERE/WHAT/WHEN authority; zombie/player mechanics; existing terrain/streaming improvements; canonical condition/moodlet state; input and STATS/INVENTORY/CRAFT/MENU ownership; day/night/weather; current world changes; utility and vehicle state; physical rendering and perception boundaries; hard application pause.

Do not restore the player-facing ZOMBIES/ZOMBIES NEARBY indicator. Keep LOADING unless a later UX decision intentionally replaces it. Do not protect obsolete survivor/society consumers merely because the previous handoff listed population among preserved systems.
