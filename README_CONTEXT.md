# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 1 COMPLETE — 2026-09-25

Phase 1 of `ROADMAP.md` is complete: the live survivor/social/outbreak runtime has been retired from production composition while zombies and shared player/world mechanics remain live.

Starting main for this bounded operation: `4b7115055efae0ea7f59770c04fad395435d839d`.

Functional/executable owning head: `46827d36fd0621a59aadb1e808d004c7ddbfa0a0`.

Documentation head immediately before this final handoff write: `6c93e2673157fda8bb8f644b7694a83a01e2dc99`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Completed

- Removed live production construction of:
  - `SurvivorNpcState`;
  - `SurvivorHydrationService`;
  - `ActiveSurvivorCohortService`;
  - `SurvivorNpcBehaviorService`;
  - survivor TALK / ASK TO FOLLOW / TELL TO STAY offer/handler registration;
  - `SurvivorInteractionService`;
  - `SurvivorInfectionService` and survivor-to-infected conversion wiring.
- `CombatGameMain` now finishes production population boot after the infected path instead of hydrating four living survivors.
- Replaced the production `DynamicInfectedCohortService` composition with `ActiveInfectedCohortService`. The dynamic outbreak-mutation subclass remains only as dormant recovery/history code.
- Preserved generated household/resident/population data and `PopulationResidentProjection` where the infected hydration path still consumes deterministic resident identity.
- Left survivor/social implementation files in the repository as uncomposed archaeology rather than deleting shared-looking code blindly.
- Updated `SYSTEM_DESIGNS/40_SURVIVOR_SOCIAL_OUTBREAK.md`, `ROADMAP.md`, and `CHANGELOG_LATEST.md` to mark Phase 1 retired/complete and Phase 2 next.
- No shared player condition, sustainment, first-aid, hearing, movement, Health, inventory, utility, time, weather, vehicle, rendering or zombie behavior owner was removed.

## Focused before / after evidence

Fresh prompt-local verifier pair:

- `game/scripts/ci/Phase1SurvivorRuntimeRetirementSmoke.gd`
- `.github/workflows/phase1-survivor-runtime-retirement.yml`

Pre-change production measurement, run `36180918709`: **success**.

- boot: 19,780,576 µs;
- infected roster: 8;
- live survivor roster: 4;
- one ordinary player commitment: 8 infected evaluations / 164,489 µs;
- same commitment: 2 survivor evaluations / 43,198 µs.

Post-change focused run `36181091707`: **success** on functional head `46827d36fd0621a59aadb1e808d004c7ddbfa0a0`.

- boot: 19,563,557 µs;
- infected roster: 8;
- live non-infected survivor NPCs: 0;
- survivor/social public composition APIs absent;
- infected cohort no longer exposes the dynamic outbreak add/remove seam;
- one ordinary player commitment still produced 8 infected evaluations / 154,043 µs;
- the action returned to decision pause;
- world time still followed the authoritative tick;
- player inventory remained enrolled;
- utility runtime remained ready.

These are single-run GitHub CI observations, not a stable hardware benchmark. The meaningful retirement result is removal of the survivor behavior work and live survivor actors while the infected/shared path remains operational. Do not infer that zombie performance is solved.

## Publication state at final write

The focused functional verifier succeeded on its owning head.

The owning-head Pages run was cancelled only because later documentation pushes superseded it. The documentation-head verifier/Pages runs were still moving when this final handoff was written. The final context commit itself must be verified read-only to terminal state per `README_SOPS.md`, including exact-head `Phase 1 survivor runtime retirement` success and exact-head `Build and deploy Tick Survival Lab` success.

Do not write a repair after this context commit. If exact-final-head verification unexpectedly fails, inspect and record the evidence in the user response; the repair becomes the next operation.

## Current release direction

Core loop remains: scavenge, fight, craft, survive on the persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well. No freeform settlement/base-building simulation.

Living survivor NPCs, companions/followers, raiders, recruitment/dialogue, household/job/social simulation and local live-society outbreak propagation are not release runtime.

Zombies remain active actors. Shared ticks, interruptible versus committed actions, simultaneous per-tick resolution, mob force and fear define the release combat identity. Real-time-with-automatic-pauses is presentation/feel; the player does not receive arbitrary tactical pause control.

## NEXT OPERATION

Phase 2 of `ROADMAP.md`: implement the shared-tick combat contract and make the surviving zombie path responsive/coherent.

Begin from targeted current owners only:

- `TickKernel.gd`, `TimedAction.gd`, `TickEventQueue.gd` and existing due-tick action resolution seams;
- `CombatActionService.gd`, damage/death/interruption services and the player combat controller;
- `ActiveInfectedCohortService.gd`, `CohortInfectedBehaviorService.gd`, `FirstInfectedBehaviorService.gd`;
- the exact perception/sound callbacks those zombie behaviors consume;
- canonical System-34 fear/condition adapters already present.

First define/verify the existing same-tick ordering and action phase semantics from those owners; do not broad-reread the repository. Then implement a bounded slice that advances the Phase-2 contract: simultaneous due-tick consequences plus explicit committed/interruptible behavior, with mob force/fear integrated through canonical owners and measured zombie evaluation/perception/presentation cost.

Keep hard application pause distinct from tactical decision pauses. Do not resurrect survivor/social runtime. Do not create a new engine, second clock, parallel fear meter or presentation-owned gameplay truth.

Before changing code in the next prompt, delete this prompt's verifier pair and create a brand-new prompt-local verifier/workflow scoped only to the Phase-2 slice, per `README_SOPS.md`.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority;
- eight resident-backed infected startup cohort unless Phase-2 design explicitly changes zombie-count tuning;
- player movement, Health/injury, inventory, condition/moodlets, skills and equipment;
- day/night and weather;
- utility and vehicle state;
- persistent world changes and terrain/streaming improvements;
- physical rendering/perception boundaries;
- input lock until the next legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless a later explicit UX operation replaces it.

Dormant survivor/social files are not protected runtime. Historical gameplay suites and the retired twelve-seed matrix are not current gates.
