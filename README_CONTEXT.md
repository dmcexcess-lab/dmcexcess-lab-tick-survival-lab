# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2C SHOVE TRANSITION ARBITRATION COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows, Phase 2B simultaneous melee hit/death semantics, and prior Phase-2C stat-based movement / release-chain / edge-conflict semantics remain protected.

This bounded slice implements the first cross-system spatial consequence under the approved causal tick model:

> `S_t -> seal consequences already earned -> resolve trajectories / physical interaction / occupancy -> publish outgoing space -> publish bodily/terminal consequences -> S_t+1`.

Starting main for this operation: `68c563962b581282696a54ba7163984f2bb2c124`.

Functional/executable owning head: `355de006567289ac257b0b3437f87946d72c427c`.

Fresh verifier repair head/run: `f161e1673fb23e351399f5d778d4cf8efa4fe4d4` / `36194398176` — **SUCCESS**.

Documentation head immediately before this final handoff write: `8aff313fda84648e60a8c490034c6358ec68580d`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous transition-edge verifier pair was deleted before code work:

- `game/scripts/ci/Phase2CTransitionEdgesSmoke.gd`
- `.github/workflows/phase2c-transition-edges.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CShoveTransitionsSmoke.gd`
- `.github/workflows/phase2c-shove-transitions.yml`

The next code prompt must delete this pair before changing code and create its own focused verifier/workflow.

## Completed — shove is now a forced trajectory, not an immediate placement write

`CombatActionService` no longer resolves shove by directly calling `WorldMutationService.set_placement`.

At `combat.contact`, Combat now freezes:

- attacker/source physical shove score;
- target physical resistance score;
- contact target and direction from the stable incoming contact state.

It then submits a forced-displacement trajectory to `MovementActionService`.

Movement owns the late same-timestamp spatial transition batch and arbitrates the forced trajectory alongside ordinary movement and other spatial claims.

This preserves ownership:

- Combat owns contact/action meaning;
- actor state owns physical-stat inputs;
- Movement owns shared spatial transition arbitration;
- WHAT owns final placement mutation;
- WHEN owns timestamp/action ordering.

## Completed — physical scores are frozen before same-tick damage can rewrite them

Ordinary movement previously derived its physical contest score at the late spatial flush. That allowed damage generated earlier in the same timestamp to reduce HP and therefore weaken an already-earned movement contest.

That is now corrected.

When a movement consequence reaches its commit phase and enters the timestamp batch, its canonical physical contest score is frozen immediately.

Shove source force and target hold resistance are likewise frozen at combat contact before aggregate same-tick damage mutates HP.

Therefore:

- current-tick injury cannot retroactively weaken a movement consequence already earned for that tick;
- a lethal wound does not erase the physical force an already-committed shove brought into the transition;
- outgoing HP/injury state affects future timestamps, not the already-sealed physical consequence.

## Completed — shove versus target movement

A target may have an ordinary movement trajectory already due on the same timestamp when it is shoved.

Movement now resolves these as competing trajectories for the same actor.

If movement and shove point to different destinations:

- frozen target movement score is compared with frozen shove source force;
- stronger shove wins and the target movement fails with `shoved`;
- stronger movement wins and the shove does not displace;
- exact/unknown equality is a trajectory stalemate and the actor remains in its incoming cell.

If movement and shove point to the same destination:

- they are compatible, not contradictory;
- the shared destination claim uses the stronger frozen score;
- shove does not generate an extra square of travel.

Ordinary walking still has no displacement authority merely because its actor has a high stat.

## Completed — simultaneous opposing shoves have no hidden winner

Multiple forced trajectories on one actor are resolved before final occupancy publication.

For equal strongest shove forces pointing to different destinations:

- no attacker ID, callback order, action serial or sort order chooses a winner;
- all tied opposing displacement trajectories fail;
- the target remains in place.

Parallel shove trajectories pointing toward the same outgoing destination are currently coalesced onto one destination result without adding their force together.

That is intentional staging, not final mob force. **Same-direction force aggregation is the next crowd-pressure mechanic and is not claimed complete here.**

## Completed — forced displacement obeys the same space rules as movement

A surviving forced trajectory participates in the same spatial transition rules as movement:

- destination claims;
- actor-only occupancy release dependencies;
- fixed-point failure propagation;
- physical reciprocal-edge conflicts;
- static/non-ACTOR collision;
- atomic `WorldMutationService.set_placements_batch` publication.

A shove cannot phase a target through a wall or a surviving actor.

Push-chain propagation through bodies is not implemented yet. A forced trajectory that meets an unresolved body remains blocked rather than inventing teleportation.

## Completed — lethal same-tick contact now publishes death after spatial consequences

Combat's Health consequence batch no longer closes immediately after applying aggregate same-tick melee damage.

It remains open through the late spatial transition flush.

The terminal batch-close event is scheduled on the same authoritative timestamp after Movement's spatial flush. `ActorDeathTransitionService` therefore knows HP may already be zero but cannot unplace the actor or create a corpse until every already-earned spatial consequence for that tick has settled.

Result:

- shove contact can be lethal-hit-adjacent and still resolve;
- committed movement can survive same-tick lethal melee damage under the established commitment rules;
- corpse placement inherits the actor's resolved outgoing position.

The actor does not snap back to its incoming position merely because death is terminal.

## Focused production verification

Fresh verifier:

- `game/scripts/ci/Phase2CShoveTransitionsSmoke.gd`
- `.github/workflows/phase2c-shove-transitions.yml`

Functional production head:

- `355de006567289ac257b0b3437f87946d72c427c`

Initial run:

- `36194296697` — **FAILED**
- exact failure: lethal-shove fixture left the previous opposing shover occupying the intended displacement destination;
- this was a focused fixture-state defect, not evidence of production shove ordering;
- the fixture was repaired by moving that actor out of the destination; assertions were not weakened.

Focused repair head/run:

- `f161e1673fb23e351399f5d778d4cf8efa4fe4d4`
- run `36194398176` — **SUCCESS**

Marker:

`PHASE2C_SHOVE_TRANSITIONS_OK shove_beats_move=true opposing_tie=true corpse_after_displacement=true`

The real production scene proves:

### Shove versus committed movement

- target begins an ordinary move;
- shove is started later so its contact and the target's movement commitment mature on the same timestamp;
- stronger shove force wins the target's trajectory;
- target ends in the shove destination;
- target movement fails explicitly with `shoved`;
- shove resolves `displaced=true`.

### Equal opposing shoves

- equal physical attackers shove the same stationary target from opposite sides on one contact timestamp;
- target remains in place;
- both shoves report no displacement;
- no hidden initiative chooses an attacker.

### Lethal hit plus shove

- shove and unarmed strike reach the same 1-HP target on one combat contact timestamp;
- strike reduces canonical HP to zero;
- death publication stays deferred;
- already-earned shove displaces the actor;
- terminal death then creates the corpse at that post-shove outgoing cell;
- shove reports `displaced=true`.

## Durable documentation updated

- `DESIGN_DECISIONS.md` records shove as a forced trajectory and terminal death after outgoing spatial truth.
- `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md` records forced-displacement arbitration, frozen physical scores and focused evidence.
- `SYSTEM_DESIGNS/37_TACTICAL_COMBAT_PHYSICAL_IMPACT.md` records shove/contact/death integration.
- `ROADMAP.md` advances Phase 2 beyond shove-vs-move and cross-system melee death/movement ordering.
- `CHANGELOG_LATEST.md` records implementation and both focused runs.

## Emergence direction

Newest user direction is to **let the simulation win** rather than authoring zombie crowd choreography.

Zombies should remain intentionally simple/bumbling actors whose ordinary intentions interact through the physical transition system. Desired crowd behavior should emerge from:

- occupancy;
- conflicting trajectories;
- body resistance;
- momentum / shove force;
- bottlenecks;
- released cells;
- failed releases;
- pressure through neighboring bodies;
- injuries / condition;
- environment geometry.

Do not add a cosmetic/random `stumble` routine merely to make zombies look dumb. Stumble/knockdown should eventually be a physical outcome of losing force/trajectory/stability contests.

It is acceptable and desirable for the same rules to sometimes produce unexpectedly orderly flow and sometimes jams/collisions.

## Scope note — followers versus pets

Human survivor followers/recruitment/social runtime remain retired.

The user clarified that an earlier reference to `followers` should not restore that system. However, the user expects **pets to return eventually** as a distinct future feature. Pets should later use ordinary physical movement/intent/world rules rather than resurrecting the retired human follower/social simulation.

No pet runtime is part of Phase 2C and none was added in this operation.

## What this slice does NOT claim

Phase 2 remains open.

Not yet complete:

- additive same-direction zombie/crowd force;
- push-chain force propagation through packed actors;
- force loss/transmission through geometry;
- knockdown / stumble / prone stability consequences;
- impact/crush consequences when pressure terminates against walls/doors/bodies;
- door/fortification pressure aggregation and breakage;
- firearm/movement same-tick ordering;
- canonical fear tuning/effects;
- zombie callback/perception performance;
- overlapping consequence presentation;
- crowded-fight/Safari performance acceptance.

The current forced-trajectory seam is intentionally shaped so these can emerge from one shared physical transition model rather than parallel special cases.

## Current release direction

The game remains primarily player versus zombies. Living survivor NPC society, raiders, human followers, recruitment/dialogue and live social simulation remain retired.

Core loop: scavenge, fight, craft, survive on the persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well.

Phase-2 executable foundations now include:

1. explicit interruptible -> committed action windows;
2. simultaneous melee hit/damage semantics;
3. deferred terminal death after current-tick consequence resolution;
4. conditional origin releases / destination arrival claims;
5. atomic compatible movement chains;
6. stat-based exclusive destination contests;
7. head-on reciprocal edge conflicts;
8. shove as a frozen forced trajectory sharing the same spatial arbiter;
9. shove-vs-target-movement trajectory competition;
10. no-hidden-initiative opposing shove ties;
11. corpse placement at resolved outgoing position.

## NEXT OPERATION

Continue Phase 2 with the first genuine **crowd-pressure / mob-force** slice while staying faithful to the simulation-first direction.

Targeted starting reads only:

- current forced-displacement / actor-trajectory logic in `MovementActionService`;
- `MovementPhysicalContestProvider.gd` / `ActorPhysicalContestQuery.gd`;
- current infected action-selection call site only as needed to prove ordinary zombies naturally generate relevant contacts;
- existing stance/Health/condition inputs only if needed by the physical result;
- door/static collision only if required by the focused pressure endpoint test.

Required bounded outcomes:

- multiple same-direction shove/pressure inputs on one actor combine physically rather than selecting one attacker;
- opposing directional forces resolve from aggregate frozen forces, not callback order;
- pressure can propagate through at least one packed actor when downstream space is available, using the same conditional-release / outgoing-occupancy model;
- if the chain terminates against static blocked space, nobody phases through it;
- do not create authored zombie formation logic, crowd steering or random stumble behavior;
- do not tune fear yet;
- do not build a complete knockdown/crush model yet unless a minimal typed consequence is required by actual pressure resolution;
- preserve all completed movement, shove, melee and terminal-death semantics.

The goal is the smallest real force-propagation primitive from which zombie jams, surges and pile pressure can emerge naturally.

Before changing code, delete the current prompt-local verifier pair:

- `game/scripts/ci/Phase2CShoveTransitionsSmoke.gd`
- `.github/workflows/phase2c-shove-transitions.yml`

Then create a fresh focused verifier/workflow scoped only to aggregate crowd-pressure / one-chain propagation.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- `S_t -> transition -> S_t+1` causal ordering;
- Phase-2A commitment offsets;
- Phase-2B simultaneous melee contacts/damage;
- terminal death after surviving same-tick spatial consequences;
- frozen physical scores for current-tick trajectory resolution;
- stat-based same-destination arbitration;
- release-chain/fixed-point movement semantics;
- head-on reciprocal walk conflict;
- shove-vs-move trajectory arbitration;
- equal opposing shove no-hidden-winner behavior;
- stable pre-contact melee target snapshot;
- existing eight resident-backed infected startup cohort;
- no live survivor/raider/human-follower/social runtime;
- player movement, Health/injury, inventory, condition/moodlets, skills and equipment;
- day/night, weather, utilities and vehicles;
- persistent world changes and terrain/streaming improvements;
- input locked until legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
