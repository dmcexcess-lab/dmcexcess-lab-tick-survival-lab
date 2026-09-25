# System 40 — Resident Survivors, Social Roles, and Causal Local Outbreak

Status: **RETIRED FROM PRODUCTION — 2026-09-25**

## Current release contract

System 40 is no longer part of the production game composition. The survival release deliberately removes living survivor NPCs, followers, raiders, recruitment/dialogue, survivor social roles, and local survivor-to-infected outbreak conversion.

`CombatGameMain` now boots the existing infected population path directly and does **not** hydrate a survivor cohort, create survivor AI/perception/hearing participants, register survivor social interaction providers/handlers, or attach `SurvivorInfectionService`.

The production infected cohort uses `ActiveInfectedCohortService`, not the former dynamic outbreak-mutation subclass. The eight resident-backed infected at the starting area remain ordinary actors using the shared movement, perception, sound, combat, Health, inventory/condition enrollment and WHEN owners.

Generated aggregate resident/household data and `PopulationResidentProjection` may remain as cheap deterministic generation/identity inputs where the zombie path still consumes them. Their presence does not imply a live society simulation.

## Retained code

The following implementation files remain in the repository as recovery/history substrate but have no production composition consumer:

- `ActiveSurvivorCohortService.gd`
- `SurvivorNpcBehaviorService.gd`
- `SurvivorNpcState.gd`
- `SurvivorHydrationService.gd`
- `SurvivorInteractionOfferProvider.gd`
- `SurvivorInteractionService.gd`
- `SurvivorInfectionService.gd`
- `DynamicInfectedCohortService.gd`

Do not reconnect those files merely to satisfy historical tests or older design text. Git history remains the recovery source if the feature is ever intentionally revived.

Shared classes whose names contain “Survivor” but are used by the player or infected/shared mechanics are **not** retired by this decision. Examples include the canonical condition/sustainment/first-aid owners and the shared hearing profile. Retirement is by live responsibility, not filename vocabulary.

## Production ownership after retirement

The production lineage remains:

`game/main.tscn -> gameplay.tscn -> EnvironmentalPressureGameMain -> CombatGameMain -> VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

Within that lineage:

- `CombatGameMain` owns combat plus resident-backed infected hydration and the active infected cohort.
- `EnvironmentalPressureGameMain` continues attaching opening pressure only to infected behavior.
- Player condition, inventory, time, utilities, vehicles, crafting and other shared systems remain unchanged.
- No TALK / ASK TO FOLLOW / TELL TO STAY provider or handler is registered by production composition.
- No live neutral/follower/raider state or survivor infection conversion is required for a new game.

## Retirement verification — 2026-09-25

Fresh prompt-local verifier:

- `game/scripts/ci/Phase1SurvivorRuntimeRetirementSmoke.gd`
- `.github/workflows/phase1-survivor-runtime-retirement.yml`

Pre-change production measurement on run `36180918709`:

- boot: 19,780,576 µs;
- infected roster: 8;
- survivor roster: 4;
- one ordinary player commitment caused 8 infected behavior evaluations / 164,489 µs and 2 survivor behavior evaluations / 43,198 µs.

Post-change focused run `36181091707` succeeded:

- boot: 19,563,557 µs on the same GitHub runner class;
- infected roster: 8;
- live non-infected survivor NPCs: 0;
- the same ordinary commitment caused 8 infected behavior evaluations / 154,043 µs;
- survivor behavior evaluation work is absent;
- world time remains tied to the authoritative tick;
- the player inventory container and utility runtime remain live.

These are single-run CI observations, useful as before/after evidence rather than a stable performance benchmark. Removing four survivors does not by itself close zombie/perception performance work.

## Historical reference

System 40 was originally closed on 2026-09-09 at functional head `52c6ef02c8f78b05c6761e73be4c525d1d975efe`. That implementation included survivor hydration, neutral/follower/raider policy, social actions and same-identity survivor-to-infected conversion. Its detailed historical contract remains recoverable from Git history.

The superseding release decision is the 2026-09-25 survival roadmap reset. Phase 2 now owns shared-tick combat coherence, commitment/interruption, mob force/fear and measured zombie decision/perception/presentation cost.
