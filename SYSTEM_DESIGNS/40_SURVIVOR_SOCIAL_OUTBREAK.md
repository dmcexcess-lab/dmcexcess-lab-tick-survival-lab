# System 40 — Resident Survivors, Social Roles, and Causal Local Outbreak

Status: **IMPLEMENTED + AUTOMATED VERIFIED — human gameplay acceptance remains defect-driven**

## Purpose

Close the missing human-survivor half of the existing island population model without introducing a second population authority, second actor stack, second clock, or fake conversation/combat layer.

The authoritative aggregate population remains the generated household/population plan. System 40 deterministically projects the resident slots that are *not* assigned to the existing infected count, hydrates a small active survivor cohort from those exact identities, and gives those real actors neutral/follower/raider behavior through existing movement, perception, sound, combat, Health, inventory, skills, condition, streaming, and WHEN owners.

## Population identity

`PopulationResidentProjection` now exposes complementary deterministic views:

- infected residents are the first `infected_population` slots after the existing deterministic infection-score ordering;
- survivors are the remaining slots from the same household capacities;
- infected + survivor records therefore equal the exact resident aggregate;
- a resident ID cannot exist in both projections;
- projection creates no additional population and owns no independent count.

Each hydrated survivor keeps the same `resident.<building>.<ordinal>` identity used by the population plan.

## Active survivor cohort

The production root hydrates four bounded resident-backed survivor NPCs near the playable start:

- two begin `survivor.neutral`;
- two begin `survivor.raider`.

Hydration creates ordinary `actor.survivor` entities and enrolls them in the canonical owners already used by the player/infected path:

- locomotion;
- hand equipment;
- inventory containment;
- Health;
- the four broad skills;
- carry state;
- survivor condition/Fatigue.

`ActiveSurvivorCohortService` reuses the existing technical-stream activation model. Observer perception is scoped to the NPC itself; there is no hidden-world omniscience and no second AI scheduler.

## Behavior and turn cadence

`SurvivorNpcBehaviorService` is a small intention policy over existing owners:

- neutral survivors remain where they are;
- followers trail the player while preserving a small spacing buffer;
- raiders use their own current sight, last-seen memory, and heard observations to pursue/investigate;
- hostile contact uses ordinary System-37 combat;
- movement/collision still validates every real step.

Survivor NPCs receive at most **one ordinary action opportunity per player commitment**. Boot, stream activation, perception changes, and sound updates may refresh intention but do not grant free world-tick actions. This preserves the existing player-decision / shared-WHEN cadence instead of creating autonomous free turns during scene boot.

## Player-facing social actions

Survivor targets use the existing world interaction/affordance/controller/HUD path. No parallel dialogue UI is introduced.

Available actions:

- `TALK` — returns short context-derived text based on role, injury, and nearby infected pressure;
- `ASK TO FOLLOW` — changes a neutral survivor into a follower;
- `TELL TO STAY` — returns a follower to neutral/waiting state.

Raiders do not expose friendly social offers while hostile.

This is intentionally systemic conversation rather than authored quest dialogue. Richer relationships, memories, factions, authored identities, and longer conversation content remain content/fidelity expansion rather than prerequisites for the core runtime.

## Causal local infection

`SurvivorInfectionService` listens to real `CombatActionService.impact_resolved` events.

A damaging melee impact from an actor already marked infected adds bounded exposure to the struck survivor. Repeated exposure can cross the local infection threshold. Conversion then:

1. keeps the exact same resident/actor ID;
2. records that resident as infected with source actor and tick provenance;
3. removes the actor from survivor social-role/cohort ownership;
4. adds the same already-real actor to the active infected cohort;
5. gives an active converted resident the same perception/behavior/environmental-pressure path as other infected.

No replacement zombie is spawned, no aggregate resident is duplicated, and no invisible outbreak counter substitutes for the physical local event.

## Production composition

The production lineage remains:

`game/main.tscn -> EnvironmentalPressureGameMain -> CombatGameMain -> VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

System 40 composes inside `CombatGameMain`, because it consumes population, actor ownership, perception, movement, sound, combat, and streaming that are already live there. System 39 continues to attach generic opening pressure in `EnvironmentalPressureGameMain`; newly converted infected are resynchronized into that same pressure service.

The existing active infected cohort remains eight resident-backed infected at startup. System 40 adds four survivor NPCs; it does not replace or silently resize the infected baseline.

## What this closes

This closes the core Phase-8 holes that were still real after the roadmap became stale:

- real non-infected resident identities;
- neutral survivor NPCs;
- recruitable followers;
- hostile human raiders;
- observer-scoped survivor/raider behavior;
- player-facing conversation/recruit/dismiss actions;
- same-identity local survivor -> infected transition;
- converted infected joining the existing streaming/perception/combat/environmental-pressure runtime.

Melee/firearms, infected AI, household population, perception/hearing, streaming, Health/death, and environmental opening pressure were already implemented by earlier systems and are reused rather than rebuilt.

## Intentional post-core fidelity backlog

These are not fake-completed inside System 40:

- richer persistent personal relationships and named-character history;
- factions and diplomacy beyond the neutral/follower/raider role slice;
- long-form dialogue or quest scripting;
- island-wide offscreen epidemic propagation between aggregate households;
- large survivor settlements or follower command UI;
- navigation architecture beyond the existing bounded local movement/detour behavior.

Those additions must remain causal consumers of the same resident/actor owners if pursued later.

## Verification contract

The prompt-owned closure verifier proves, without replacing production owners:

- Godot production scripts load/parse;
- infected and survivor projections exactly partition aggregate resident population;
- four resident-backed survivor NPCs hydrate while the existing eight infected remain intact;
- neutral and raider roles exist;
- recruit/talk behavior is reachable through the real social service;
- survivor intention policy does not receive free boot actions;
- repeated real combat-impact exposure converts the same identity;
- the converted resident moves from the survivor cohort to the infected cohort;
- converted active infected receive the existing System-39 environmental-opening-pressure owner;
- Pages export remains green.

## Verification closure — 2026-09-09

Owning functional head: `52c6ef02c8f78b05c6761e73be4c525d1d975efe`.

- Fresh prompt-local verifier: `game/scripts/ci/PromptSurvivorOutbreakClosureSmoke.gd` + `.github/workflows/prompt-survivor-outbreak-closure.yml`.
- Focused run `34406705296`, job `102651283682`: **success** with `PROMPT_SURVIVOR_OUTBREAK_CLOSURE_SMOKE: PASS` after booting the real seed-20001 production scene.
- Exact-head Pages run `34406705275`: **success**.
- The diagnostic run exposed duplicate inherited constant declarations in `ActiveSurvivorCohortService`; removing only those redundant declarations restored Godot parsing. No production survivor/infected ownership rule was weakened.

Exact prompt-close publication/handoff state remains recorded in `README_CONTEXT.md`.