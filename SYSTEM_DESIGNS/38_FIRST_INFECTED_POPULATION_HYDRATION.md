# System 38 — First Infected / Population-Backed Hydration

Status: **FIRST REAL INFECTED HYDRATED IN PRODUCTION + INTEGRATED COMBAT/DEATH CI**

## 1. Core rule

> **An infected is a real human resident in an infected state, not a disconnected zombie fixture.**

The island population planner already owns how many residents exist in each settlement and household. System 38 does not create an extra population. It deterministically projects individual identities from those already-counted household resident slots only when an individual must enter active simulation.

Infection is an overlay on the shared human actor identity. The hydrated actor remains semantic `actor.survivor` so canonical Health, equipment, inventory, locomotion, condition, carry, skills, collision and WHEN action systems remain reusable.

## 2. Existing population truth reused

`IslandWorldPlanner` already runs `IslandPopulationPlanner` while generating the global world plan and retains:

- `population_settlements`;
- `resident_population`;
- `infected_population`;
- `survivor_population`;
- `local_area_manifest`.

Each settlement population record contains real household records tied to generated buildings, including:

- `building_id`;
- building archetype;
- household resident capacity;
- settlement/site identity;
- aggregate resident/infected/survivor counts.

The planner intentionally does not pre-create thousands of person WHAT entities. System 38 preserves that efficient aggregate truth and materializes an individual only when needed.

## 3. Deterministic resident projection

`PopulationResidentProjection` converts already-counted household capacity into stable resident slots on demand.

For each household building with capacity N it derives resident identities:

`resident.<building_id>.<ordinal>`

The projected record keeps:

- resident ID;
- source building ID;
- resident ordinal within that household;
- settlement ID;
- area-site ID;
- real generated building home cell.

This projection does **not** increment population totals. It merely gives stable names to resident slots already represented by household capacity.

## 4. Deterministic infection assignment

For each resident slot, a stable infection score is derived from the existing world seed plus building identity and resident ordinal. Resident slots are sorted by that score within the settlement; exactly the settlement's existing `infected_population` count is marked infected.

Therefore:

- repeat generation from the same world/population plan yields the same infected resident identities;
- the projected infected count cannot exceed or invent beyond the planner's infected count;
- a hydrated infected can be traced back to one specific real household/building slot.

The first active infected prefers the central playable area and chooses the nearest deterministic infected resident record to the current player reference cell. If no infected record exists in the preferred site, the projection can fall back to the nearest valid infected resident elsewhere.

## 5. Infection state overlay

`InfectedState` stores the resident provenance for hydrated infected actors. It does not replace the world actor semantic with a parallel zombie species.

A valid infected record requires:

- the same exact resident ID as the actor ID;
- `infected = true`;
- a real source building ID;
- a positive household resident ordinal.

The actor remains `actor.survivor`. This is deliberate: infection changes behavior/state, not the physical fact that the entity is a human body using the same simulation owners.

## 6. Hydration into active simulation

`FirstInfectedHydrationService` accepts the authoritative population plan and a preferred site/reference cell. It:

1. selects one deterministic infected resident slot;
2. reads that resident's real generated home cell;
3. finds a real clear materialized cell near the source household;
4. creates the exact resident ID as an `actor.survivor` WHAT entity;
5. places it on the normal ACTOR channel;
6. enrolls it in shared locomotion, hand equipment, inventory containment, Health, skills, carry and System-34 condition state;
7. records infection/provenance in `InfectedState`;
8. returns the exact hydrated actor ID/record/cell.

`CombatGameMain` performs this after System-37 combat composition boots, using the already-generated global plan. It does not rerun all local-area/population generation just to obtain one actor. Player perception is recomputed after hydration.

## 7. Physical spawn rule

The infected is materially tied to its household record, but active placement must also respect the currently materialized playable world. The hydrator searches a bounded physical radius around the source home's generated cell and uses the existing collision query to choose a real clear cell.

It never silently overlaps a blocker or invents an off-world actor. If no valid materialized cell exists, hydration fails closed.

## 8. Shared combat and death

System 38 owns neither combat nor corpse logic.

Once hydrated, the infected is a normal living actor for System 37. The integrated focused verifier uses that exact production-hydrated resident identity as the firearm target and proves:

- canonical Health receives damage;
- the infected can have an ordinary active WHEN action;
- lethal firearm impact reaches the generic `ActorDeathTransitionService`;
- living ACTOR occupancy is removed;
- a persistent corpse is created;
- the actor's exact equipped/carried WHAT item moves into corpse containment without copying;
- the source resident/infection provenance remains available in `InfectedState` after death.

This prevents infected from developing a bespoke health/death/loot stack.

## 9. Focused verification

Current prompt-owned verifier:

- `game/scripts/ci/PromptCombatFirearmDeathSmoke.gd`
- `.github/workflows/prompt-combat-firearm-death.yml`

Integrated functional head:

- `e997ac13b74a1955fb5fe152f1b0753886009acc`
- `Prompt Combat Firearm Death` run `34170545140` — SUCCESS.

The production-scene verifier proves specifically that:

1. the first infected is hydrated by production boot;
2. its actor ID is recorded by `InfectedState`;
3. its provenance is the central area's real household resident slot;
4. the same identity appears in deterministic population projection as one of the resident slots already counted infected;
5. the world entity remains shared human semantic `actor.survivor`;
6. it has real ACTOR occupancy;
7. Health, equipment, containment, condition, locomotion, carry and skill state all enroll for the exact actor;
8. the exact same resident-backed infected survives normal world mutation and System-37 targeting;
9. lethal firearm damage sends that actor through generic death/corpse truth;
10. population/infection provenance survives that transition.

The first production hydration attempt exposed an owner-interface mismatch: Skill and Carry state owners do not expose `is_ready()` methods. The hydrator was corrected to honor their actual non-null/enrollment API rather than changing those owners or weakening the verifier.

## 10. What is not implemented yet

This closure hydrates a real infected body/state. It does **not** yet implement autonomous infected behavior.

Not yet closed:

- perceiving the player or other stimuli and choosing intentions;
- hearing and investigating System-26 sound observations;
- autonomous path/movement submissions;
- attacking through ordinary System-37 actions;
- persistence/materialization policy for many infected simultaneously;
- survivor NPC behavior/dialogue.

The production first infected is therefore a valid physical actor and combat target, but not yet an autonomous zombie AI.

## 11. Next operation

Build the first infected behavior loop through existing simulation boundaries:

> **perception -> intention -> ordinary WHEN action**

The infected should consume existing System-23 visual truth and System-26 heard-sound observations, choose a small deterministic intention, and submit the same movement/combat actions available to ordinary actors. No custom zombie clock, direct teleport movement, private attack cooldown, magic attraction radius, or duplicate combat state.

Start with exactly the already-hydrated first infected. Prove one actor can perceive, investigate/approach and attack on the shared WHEN clock before scaling hydration to more population slots.

## 12. North-star fit

System 38 preserves the simulation architecture by making the first infected emerge from existing truths:

- world generation already produced homes;
- population planning already counted residents/infected;
- deterministic projection names existing resident slots;
- infection is state on a human actor;
- active hydration enrolls existing actor owners;
- combat/death use existing System-37/Health/corpse truth;
- future behavior must use existing perception/sound/movement/WHEN systems.

No population was invented merely to make a zombie appear.
