# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2C FIRST CROWD-PRESSURE PRIMITIVE COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows, Phase 2B simultaneous melee consequences, and prior Phase-2C causal movement/shove/death semantics remain protected.

This bounded slice implements the first real emergent mob-pressure behavior under the approved simulation-first rule:

> Zombies and other actors submit ordinary intentions. Shared physical state decides jams, surges, releases and pressure. Do not author formation logic or cosmetic random stumbling to force a desired crowd look.

Starting main for this operation: `3120d3f9bb66077d845e0c0c179c55db67dd9b67`.

Functional/executable owning head: `57c4e6d2f3a8b235640b59053fb88fcc8e655ef9`.

Focused verifier head/run: `57c4e6d2f3a8b235640b59053fb88fcc8e655ef9` / `36195331005` — **SUCCESS**.

Documentation head immediately before this final handoff write: `f8209da5b334d5f6201c9525a817907ec82a1462`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous prompt-local shove-transition pair was deleted before code work:

- `game/scripts/ci/Phase2CShoveTransitionsSmoke.gd`
- `.github/workflows/phase2c-shove-transitions.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CCrowdPressureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure.yml`

The next code prompt must delete this pair before changing code and create its own focused verifier/workflow.

## Completed — parallel pressure adds instead of selecting one attacker

Forced-displacement inputs acting on the same actor in one timestamp are now treated as physical force contributions.

Movement's shared spatial arbiter now:

- sums frozen force from parallel cardinal inputs;
- subtracts force from the opposite cardinal direction;
- derives the resulting net cardinal pressure before displacement is decided;
- never chooses a winner from callback order, source actor ID, action serial or sorted processing order.

The previous staging behavior that effectively selected the strongest individual shove is superseded.

## Completed — opposing aggregate force cancels cleanly

For one actor at one timestamp:

- east/west pressure oppose one another;
- north/south pressure oppose one another;
- exact zero net pressure produces no directional winner;
- when both axes have non-zero net pressure, the dominant grid axis owns the candidate trajectory;
- an exact perpendicular-axis tie remains a stalemate rather than inventing a direction.

This remains a grid simulation. No diagonal displacement has been invented.

## Completed — residual force propagates through one packed actor

Pressure now has a real transmission rule.

For a surviving forced trajectory:

1. aggregate force acts on the current target;
2. the resistance already frozen for that current-tick body/trajectory is consumed;
3. only positive residual force may continue forward;
4. if the target's outgoing cell is occupied by one actor, that residual force creates an internal propagated pressure candidate on the blocking actor;
5. the propagated candidate re-enters that actor's same shared trajectory arbitration;
6. it can combine with an independently earned shove already acting on the downstream body;
7. outgoing placements are still published atomically through WHAT after dependency resolution.

Automatic propagation is intentionally capped at **one packed actor** in this slice.

This is a staging limit, not a claim that real crowd pressure stops after one body. The next bounded operation should generalize the same rule safely rather than replacing it.

## Completed — downstream forces can combine before hold resistance rejects them

Hold resistance is now finalized after one-step propagation.

This matters for real crowd behavior.

Example proven by the production verifier:

- rear infected shoves the front infected;
- front infected simultaneously shoves the next body;
- rear shove is strong enough to move the front body but leaves only a small residual;
- front infected's own shove is individually too weak to move the downstream body;
- residual rear pressure reaches that downstream body;
- the residual and the front infected's shove add;
- the aggregate exceeds downstream resistance;
- downstream body moves;
- front body then inherits the cell that downstream body released.

Thus a packed line may surge even when no single shove would have moved the frontmost body.

## Completed — static geometry terminates the chain

Propagated pressure uses the same collision/occupancy truth as every other spatial trajectory.

A propagated body cannot move into static/non-ACTOR blocked space.

When the downstream actor cannot release its cell:

- its displacement fails;
- the existing fixed-point occupancy dependency prevents the upstream actor from occupying that cell;
- pressure does not create phasing or teleportation.

This slice does not yet convert terminated pressure into crush damage, knockdown, fortification damage or another bodily consequence.

## Frozen physical-state rule preserved

All source force and resistance inputs continue to come from frozen current-tick physical state.

Current same-tick damage cannot retroactively weaken a force consequence already sealed into the transition.

The existing derived physical score remains based on canonical state such as condition-adjusted capacity, load, HP state at sealing time, stance and action/movement intent. No standalone Strength stat was invented.

## Zombie AI remains intentionally simple

`FirstInfectedBehaviorService` was inspected but not changed.

It remains an intention selector that submits ordinary movement/combat actions to the existing owners.

No:

- crowd steering;
- formation behavior;
- mob controller;
- random stumble routine;
- special traffic coordinator;
- per-crowd scripted choreography

was added.

The desired behavior is emergent:

- sometimes zombies flow through releases;
- sometimes they collide;
- sometimes they jam;
- sometimes stacked force produces a surge;
- static geometry can hold the line;
- later physical stability consequences may make some failed contests become actual stumbles/knockdowns.

## Focused production verification

Fresh current verifier/workflow:

- `game/scripts/ci/Phase2CCrowdPressureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure.yml`

Functional production head/run:

- `57c4e6d2f3a8b235640b59053fb88fcc8e655ef9`
- run `36195331005` — **SUCCESS**

Marker:

`PHASE2C_CROWD_PRESSURE_OK aggregate=true one_body_propagation=true opposing_cancel=true static_termination=true`

The verifier boots the real production scene and proves:

### Aggregate plus one-body propagation

Three infected form a packed line.

The rear and middle infected both perform real `combat.shove` actions on the same contact timestamp.

The rear shove transmits residual force through the middle actor. That residual combines with the middle actor's own independently earned shove. The downstream target moves even though neither downstream contribution alone is sufficient. The middle actor then moves into the released cell.

Both contributing real shoves report successful displacement through their causal linked results.

### Opposing aggregate cancellation

The public forced-trajectory seam applies two same-direction contributions whose total exactly equals an opposing contribution.

The target remains at its incoming cell. No source/action ordering chooses a direction.

### Static termination

A strong pressure chain is placed against real production static blocked geometry.

The downstream actor cannot enter the blocked endpoint, so fixed-point dependency prevents the upstream packed body from advancing. Nobody phases through the obstacle.

## Durable documentation updated

- `DESIGN_DECISIONS.md` records crowd pressure as aggregate emergent force rather than authored zombie behavior.
- `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md` records aggregate force, residual transmission, one-body propagation and focused evidence.
- `SYSTEM_DESIGNS/37_TACTICAL_COMBAT_PHYSICAL_IMPACT.md` records how real shove contacts feed the aggregate spatial pressure seam.
- `ROADMAP.md` advances Phase 2 through the first mob-pressure primitive.
- `CHANGELOG_LATEST.md` records the implementation and focused run.

## Scope note — humans and pets

Living survivor NPC society, raiders, human followers, recruitment/dialogue and social simulation remain retired.

Pets are expected to return later as a distinct bounded feature. They should use the same ordinary intent, movement, occupancy and physical consequence rules rather than restoring the retired human follower/social architecture.

No pet runtime was added here.

## What this slice does NOT claim

Phase 2 remains open.

Not yet complete:

- automatic pressure propagation beyond one packed actor;
- arbitrary-depth pile compression;
- attenuation/transmission rules across a longer body chain;
- cycle/loop protection for deeper pressure graphs;
- knockdown / stumble / prone stability consequences;
- crush / impact injury from pressure terminating against walls or bodies;
- door / barricade / fortification pressure damage;
- fear tuning/effects;
- firearm/movement same-tick ordering;
- zombie callback/perception performance;
- overlapping consequence presentation;
- crowded-fight/Safari performance acceptance.

Do not add random stumbling merely for appearance. If stumble/knockdown is added, it should be a consequence of the physical transition/stability model.

## Current release direction

Core loop remains: **scavenge, fight, craft, survive** on the persistent map with day/night, weather, power, water and vehicles.

A base is an existing fortified house/building with supplies, generator and well.

The game remains primarily player versus zombies. Human society simulation remains out of release scope.

Phase-2 executable foundations now include:

1. explicit interruptible -> committed action windows;
2. simultaneous melee hit/damage semantics;
3. deferred terminal death after surviving current-tick spatial consequences;
4. conditional origin releases / destination arrival claims;
5. atomic compatible movement chains;
6. stat-based exclusive destination contests;
7. head-on reciprocal edge conflicts;
8. shove as a frozen forced trajectory;
9. shove-vs-movement trajectory competition;
10. aggregate same-actor forced pressure;
11. opposing aggregate cancellation without hidden initiative;
12. one-packed-body residual force transmission;
13. downstream force combination;
14. static endpoint termination without phasing.

## NEXT OPERATION

Continue Phase 2C by generalizing one-body pressure transmission into a **bounded multi-body pressure chain** using the same simulation-first physical rules.

Targeted starting reads only:

- current aggregate force / `_propagate_forced_pressure_one_step` path in `MovementActionService`;
- current forced candidate bookkeeping / linked-result handling;
- current occupancy fixed-point and edge-conflict pass;
- physical contest provider only if one existing frozen input is needed.

Required bounded outcomes:

- residual pressure may propagate through multiple contiguous packed actors in one timestamp;
- each body's frozen resistance consumes force before any residual continues;
- a downstream independently earned force contribution can join propagated pressure at the correct body;
- propagation terminates naturally when residual force is exhausted;
- propagation terminates at static geometry;
- propagation has explicit cycle/duplicate protection and a finite bound so malformed/cyclic occupancy can never create an infinite resolver;
- all final actor placements remain one atomic outgoing spatial state;
- no authored zombie crowd logic;
- no random stumble;
- no crush/knockdown/fear tuning yet;
- preserve all completed movement, shove, damage/death and one-tick causal ordering semantics.

The goal is to make a longer packed zombie column behave through the same mechanics already proven for one body, then inspect what emerges before adding stability or injury consequences.

Before changing code, delete the current prompt-local pair:

- `game/scripts/ci/Phase2CCrowdPressureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure.yml`

Then create a fresh prompt-local verifier/workflow scoped only to bounded multi-body pressure transmission and termination.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- `S_t -> transition -> S_t+1` causal ordering;
- Phase-2A commitment offsets;
- Phase-2B simultaneous melee contacts/damage;
- terminal death after surviving same-tick spatial consequences;
- frozen physical scores for current-tick force/trajectory resolution;
- stat-based same-destination arbitration;
- release-chain/fixed-point movement semantics;
- head-on reciprocal walk conflict;
- shove-vs-move trajectory arbitration;
- aggregate/opposing force semantics from this slice;
- one-body residual transmission semantics as the base case;
- stable pre-contact melee target snapshot;
- existing eight resident-backed infected startup cohort;
- no live survivor/raider/human-follower/social runtime;
- pets only as future bounded scope;
- player movement, Health/injury, inventory, condition/moodlets, skills and equipment;
- day/night, weather, utilities and vehicles;
- persistent world changes and terrain/streaming improvements;
- input locked until legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
