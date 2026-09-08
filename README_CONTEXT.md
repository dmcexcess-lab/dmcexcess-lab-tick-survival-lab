# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — SYSTEM 39 ENVIRONMENTAL PRESSURE CLOSED — 2026-09-08

Production root:

`game/main.tscn -> EnvironmentalPressureGameMain.gd -> CombatGameMain.gd -> VehicleGameMain.gd`

The production active infected cohort remains intentionally **8** resident-backed actors.

The closed production chain is now:

> **population resident -> physical hydration -> technical-stream activation -> System 23 / System 26 knowledge -> simple intention -> ordinary WHEN movement/combat -> exact physical blocker -> generic opening pressure -> canonical opening consequence -> ordinary traversal -> generic Health/death**

System 39 proves the first emergent environmental-pressure behavior without adding horde AI, a horde clock, group target sharing, a crowd multiplier, teleport movement, a global attraction radius, a building-attack mode, or a new navigation stack.

Project rule remains:

> **Complex behavior, simple systems. Do not over-engineer it.**

## Prompt start / turnover

At the START of the System-39 code prompt the previous prompt-owned count-ladder verifier pair was deleted FIRST:

- `game/scripts/ci/PromptInfectedCountLadderSmoke.gd`
- `.github/workflows/prompt-infected-count-ladder.yml`

Then this file was read first, `README_SOPS.md` second, and current `main` was fetched once.

Prompt starting head after turnover:

- `47ce1b917ceca7cf0a6a25ac22c416cbd41f2cc9`

No broad historical CI fleet, architecture suite, seed matrix, or unrelated regression suite was restored.

## System 39 — environmental pressure / forced entry

### Core rule

An infected does not receive a special "attack building" mode.

It pursues a destination through the already-existing simple behavior and ordinary movement. When an ordinary forward movement attempt is physically rejected, the behavior asks the existing collision query for the exact forward blocking WHAT identities. If the blocker is a lawful opening, it may submit the shared generic actor/opening action against that exact entity.

If there is no lawful opening blocker, existing bounded local detour behavior remains the fallback.

### Generic actor/opening action owner

Production now creates one shared `ActorOpeningPressureActionService` from existing owners:

- world placement / exact WHAT identity;
- spatial collision query;
- canonical door/window/interactable state;
- shared WHEN timing;
- System 26 spatial sound.

The service is actor-generic and does not depend on `InfectedState`.

The focused verifier proves the same owner with both:

- a real resident-backed infected against a door; and
- a generic non-infected `actor.survivor` against a window.

This is intentionally reusable physical simulation, not a zombie-only mechanic.

## TRY OPEN — hidden lock truth is not leaked

An intact closed door is physically tried before resistance is known.

Current first-slice timing:

- `opening.try_open`: **3 ticks**, COMMITTED;
- `opening.impact`: **8 ticks**, COMMITTED, with physical contact at the action phase.

The request path does not inspect hidden lock state to decide whether the actor "knows" the opening is locked. Only after the timed physical try resolves can that actor learn that that exact door resisted.

A resisted try:

- leaves the canonical door closed/locked;
- creates no fake barrier damage;
- does not tell other infected anything directly.

Resistance knowledge is actor/target-local.

## Persistent generic opening condition

`WorldInteractableState` now owns persistent opening damage from 0..100.

This is generic opening condition, not zombie-owned building HP.

Current first-slice contact values:

- wooden-door style body impact: **25**;
- window impact: **55**;
- each board reduces a contact by **5**, minimum **5**;
- breach threshold: **100**.

Each actor contributes only its own real contact. There is no crowd-size multiplier, shared pressure number, or synthetic horde force.

## Canonical breach consequences

### Door

At breach threshold:

- `broken = true`;
- lock truth is destroyed;
- boards are removed as failed fortification truth;
- `DoorPhysicalTransitionService` opens the passage through the existing canonical door transition;
- ordinary collision/movement then sees the opening as passable.

### Window

At breach threshold:

- `broken = true`;
- lock truth is destroyed;
- boards are removed;
- `window_open = true`;
- subsequent lawful traversal delegates to the already-existing generic `WINDOW_CLIMB` action.

There is no special zombie vault/breach movement mode.

## Sound creates environmental attraction

System 39 adds only physical opening sound profiles:

- `opening.impact`;
- `opening.break`.

They emit through System 26 at the exact opening cell.

The successful focused proof establishes the intended causal chain:

> **first infected physically impacts door -> System 26 propagates sound -> second infected receives its own heard observation -> existing behavior chooses `investigate_sound`**

The second infected is not handed the first infected's target, the hidden exact player location, or group aggro state.

## Minimal infected behavior change

`CohortInfectedBehaviorService` remains the small existing behavior wrapper over the already-proven simple intention policy.

System 39 adds one intention label:

- `infected.press_barrier`

The new decision seam is only after ordinary forward movement fails:

1. query exact physical forward blockers from the existing collision owner;
2. if one is a lawful opening, request the generic opening action;
3. otherwise keep the existing bounded local detour path.

There is still no behavior tree, horde coordinator, per-frame AI, group target, private cooldown, or second simulation clock.

## Physical congestion remains real

Infected remain ordinary blocking ACTOR bodies.

System 39 does not allow overlap, ghosting, abstract attacker slots, or pressure transfer through bodies. Only an actor that physically reaches contact with an opening can apply its own impact.

Literal crowd-force transfer remains deferred until a real generic actor force/stability system exists. Do not fake it with a horde-strength number.

## Functional verification

Current prompt-owned disposable verifier pair:

- `game/scripts/ci/PromptEnvironmentalPressureSmoke.gd`
- `.github/workflows/prompt-environmental-pressure.yml`

Workflow:

- `Prompt Environmental Pressure`

Verified functional head before documentation:

- `a4126f97ddd26711c768edd92a0cf98b519e3978`

Successful focused run:

- run `34175935673`
- job `101905204489`
- `PROMPT_ENVIRONMENTAL_PRESSURE_SMOKE: PASS`

That production-scene verifier proves:

1. real `main.tscn` boots through the System-39 root;
2. the production resident-backed cohort remains size 8;
3. two real infected share the same generic pressure owner;
4. the first infected obtains legitimate System-23 player knowledge before the barrier blocks line of sight;
5. the second infected has no visual player knowledge in the causal hearing proof;
6. blocked pursuit submits generic opening pressure against the exact door;
7. hidden lock resistance is not known before timed TRY OPEN resolves;
8. a resisted try leaves canonical locked-door truth intact and causes no fake damage;
9. the first body impact adds exactly one actor's 25 damage;
10. that impact emits real System-26 sound;
11. the second infected receives its own heard observation and chooses ordinary `investigate_sound` rather than shared aggro;
12. repeated independent contacts reach the 100-point breach threshold;
13. breach destroys lock truth and opens the canonical door passage;
14. the first infected then enters through ordinary movement;
15. ACTOR congestion remains intact;
16. a generic non-infected actor can use the same pressure owner on a window;
17. first window contact leaves persistent partial damage;
18. second contact shatters/opens the canonical window;
19. the broken window delegates to the existing `WINDOW_CLIMB` action;
20. the generic actor traverses through that existing climb path.

### Verification history

Run `34175706820` failed before gameplay because the new cohort subclass redeclared inherited `Facing`. That was a real production parser defect. The duplicate declaration was removed without changing gameplay design.

Run `34175793072` reached the real gameplay chain and System-39 mechanics passed, but two fixture assertions expected the prompt-only static blocking semantic to be transparent to System 23 while its door collision override was open. That was a focused-fixture LOS defect. The verifier was corrected to establish legitimate visual/last-seen memory before introducing the prompt barrier. No gameplay assertion was weakened.

Run `34175935673` then passed the complete door + sound + second-infected + breach + window/climb chain.

## Documentation closure

Material documentation writes completed before this final handoff:

- `SYSTEM_DESIGNS/39_ENVIRONMENTAL_PRESSURE_FORCED_ENTRY.md`
  - created at commit `8f3397d99a0fc5f233060251b8a14fa07bb9e7ba`;
  - defines the System-39 ownership boundary, timings, persistent opening damage, sound causality, exact-blocker behavior, non-goals, verification, and next operation.
- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md`
  - updated at commit `9a34d80ab664b4cb74cf43dd5554c33a6350af3b`;
  - records the functional evidence, parser/fixture failures, ownership boundary, and generated-house next phase.
- This `README_CONTEXT.md` update is the **FINAL repository write for this prompt**.

After this file is committed, perform read-only exact-head verification only. No repository mutation is permitted after this handoff write.

## Current prompt-owned CI turnover rule

At the START of the next code prompt, delete FIRST:

- `game/scripts/ci/PromptEnvironmentalPressureSmoke.gd`
- `.github/workflows/prompt-environmental-pressure.yml`

Then:

1. read this `README_CONTEXT.md` first;
2. read `README_SOPS.md` second;
3. fetch current `main` once;
4. create one brand-new focused verifier pair only for the generated-house environmental-pressure scenario.

Do not restore this prompt verifier afterward, the count-ladder verifier, prior infected/combat verifiers, broad architecture fleets, routine seed matrices, or unrelated historical regression suites.

# NEXT OPERATION — REAL GENERATED-HOUSE ENVIRONMENTAL PRESSURE

Do **not** add navigation architecture first.

Use the existing production System-39 chain against **naturally generated seed-20001 island houses and their existing generated doors/windows**.

The next focused verifier must use real generated building/opening geometry rather than prompt-created door/window semantics.

Prove, in order:

1. identify a suitable real generated seed-20001 house/building and one of its existing exterior doors or windows through the existing world/materialization/building truth;
2. use a real resident-backed infected from the production cohort;
3. establish a lawful destination from existing observer-scoped System-23 sight/last-seen truth or System-26 heard observation — never hidden exact player coordinates;
4. let ordinary shared-WHEN movement approach the generated building;
5. confirm ordinary collision discovers the exact generated opening as the physical blocker;
6. submit the existing generic System-39 TRY OPEN / pressure path against that exact generated WHAT identity;
7. if the generated door resists, prove resistance is learned only after the timed try;
8. prove repeated physical impacts change the same persistent opening condition and eventually change canonical passability when breach is physically reached;
9. prove impact/break sound propagates through System 26 and can cause another infected with no visual target knowledge to independently investigate;
10. prove the infected passes through the changed generated opening using ordinary movement or the existing window climb action;
11. preserve ordinary ACTOR congestion and exact resident/infection provenance throughout.

### Navigation gate

If that exact real generated-building scenario succeeds with the current bounded local behavior, **stop there**. Do not add pathfinding.

Only if the real generated-house proof exposes a concrete navigation failure should the failing geometry and behavior trace be inspected. Then add only the smallest **generic** route-planning/navigation seam needed to solve that demonstrated failure.

Do not preemptively add:

- global A*;
- horde routing;
- zombie navigation grids;
- group flow fields;
- attack slots;
- shared destinations;
- magical door targeting;
- teleport correction;
- crowd coordinators.

A route-planning seam, if proven necessary, must remain an ordinary actor/world capability reusable outside infected behavior.

## Existing System 38 / cohort ownership — preserve

### Population / identity

- infected identities derive only from already-counted household resident slots;
- no extra zombie population exists;
- resident IDs remain deterministic `resident.<building_id>.<ordinal>`;
- `InfectedState` is an overlay on the same shared human actor identity;
- population/infection provenance survives ordinary behavior and generic death.

### Active count / streaming

- production active cohort remains **8**;
- 16 is functionally proven but intentionally not adopted;
- `WorldStreamingCoordinator` remains the sole active-envelope authority;
- dormant infected keep exact physical/state truth;
- dormant listener/perception/behavior work sleeps through the existing stream lifecycle;
- re-entry reuses the same identity/state objects.

### Perception / sound / behavior

- System 23 owns observer-scoped visual truth and memory;
- System 26 owns uncertain heard observations;
- no auditory path may leak hidden exact source identity to behavior;
- intentions remain deliberately small: idle / pursue visible / pursue last seen / investigate sound / attack visible / press barrier;
- no group brain, shared target truth, per-frame AI, zombie timer, or private attack cooldown.

### Time / movement / collision / combat

- WHEN owns shared simulation time, action phase, interruption, readiness and pause semantics;
- movement/world/collision own locomotion and physical blockage;
- infected occupy ordinary blocking ACTOR cells;
- System 39 only reacts to exact physical opening blockers found by those owners;
- System 37 owns actor combat;
- canonical Health/generic corpse transition owns mortality;
- no duplicate infected health/combat clock exists.

## Protected neighboring contracts — preserve

### Combat / firearms

- melee/contact remains physical and WHEN-timed;
- exact firearm/magazine/live-round identities remain real containment truth, never integer ammo counters;
- reload remains RESUMABLE with truthful eject/insert/chamber intermediate state;
- System 26 owns firearm/combat sound;
- generic death/corpse transition moves exact carried/equipped entities rather than cloning loot;
- no Combat skill.

### Openings / world interaction

- closed locked ordinary openings do not leak hidden lock truth to player or NPC behavior;
- player-facing ordinary lock/unlock actions remain retired;
- existing BREAK / BOARD / UNBOARD / CLIMB behavior remains with canonical world-opening owners;
- shattered-window replacement remains deferred until real glass inventory truth exists;
- System 39 opening damage is generic condition truth, not a UI state or zombie-only HP bar.

### Vehicle / skateboard

- on foot click exact vehicle for lawful interaction;
- REPAIR/REFUEL appear only when physically valid; HOTWIRE mounted-only;
- clicking one vehicle never operates another;
- no separate vehicle-maintenance panel;
- skateboard 2 cells / 2 ticks; bicycle 3 / 2; motorcycle/car/truck 3 / 1;
- skateboard only is brakeless and may reverse/dismount while moving;
- other vehicles require stopped state before reverse/exit;
- mounted controls replace walking controls in the same footprint.

### Inventory / equipment / UI

- exact selected persistent item -> lawful action -> authoritative WHEN -> exact-entity consequence;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- one physical item cannot occupy multiple slots;
- skateboard remains one physical identity across loose/equipped/ridden;
- shared world chooser preserves every actionable exact overlapping target;
- UI owns no gameplay truth;
- no Survival window, Forage panel, player-visible Dev window, Zoom +/- buttons, or Health/Fatigue bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW + MAP remain available on foot/mounted.

## World / performance contracts — preserve

- world size remains 3072x3072;
- streaming regions remain 128x128 with active radius 1;
- gateways remain four-lane paved;
- routes touching town/crossroads remain paved two-lane unless gateway;
- rural-rural links may be gravel/dirt single-lane traversable;
- reference seed 20001 remains the generated-world target for focused real-building verification;
- water remains one municipal facility + service aliases with deterministic rural private wells and no municipal pipe network;
- wastewater remains retired;
- do not reintroduce routine 12-seed testing.

## Final closure rule

This file is the final repository mutation for System 39.

From this point onward in this prompt:

- do not edit code;
- do not edit docs;
- do not delete the current prompt verifier;
- do not create commits;
- do not rerun by changing workflow files;
- only perform read-only branch, commit, focused-CI, and Pages verification.
