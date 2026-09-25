# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2C WALK ARBITRATION COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows and Phase 2B simultaneous melee hit/death semantics remain protected. This bounded Phase-2C slice removes hidden initiative from canonical same-tick actor walking: movement consequences due on one timestamp now resolve as a physical conflict set rather than serial occupancy mutations.

Starting main for this operation: `912a86a43ee42b1bced33f7c6c4205f14f53fdeb`.

Functional/executable owning head: `d87f1402b0f06f69f1f8a614b3a7557dd7641b71`.

Focused verifier head/run: `f605987f7feb4fd24e06f3724d90622d900beee9` / `36187796332` — **SUCCESS**.

Documentation head immediately before this final handoff write: `e661e54e9724758881cd4da836ce3aacfedeecf4`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The Phase-2B prompt-owned pair was deleted before Phase-2C code work:

- `game/scripts/ci/Phase2BSimultaneousImpactsSmoke.gd`
- `.github/workflows/phase2b-simultaneous-impacts.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CMovementConflictsSmoke.gd`
- `.github/workflows/phase2c-movement-conflicts.yml`

The next code prompt must delete this Phase-2C pair before changing code and create its own focused verifier/workflow.

## Completed

### Same-tick actor movement arbitration

`MovementActionService` already collected successful movement phases into one late timestamp placement batch. The old implementation still allowed hidden initiative because:

- an actor-occupied walk target could be rejected before the timestamp batch ever saw a possible simultaneous swap;
- same-destination claims were assigned in sorted candidate order, allowing the first processed actor to win the space.

This slice changes the canonical walk path so:

- all due movement candidates re-read one unchanged pre-resolution occupancy state;
- actor-only occupied walk targets may be admitted to timestamp arbitration;
- static/non-ACTOR blockers remain immediate physical blockers;
- multiple movers claiming any same destination cell all fail with `target_contested`;
- no actor ID, callback order or queue order wins a contested empty space;
- reciprocal swaps may succeed atomically when both actors vacate each other's required cells on the same timestamp;
- compatible vacating chains/cycles may succeed only while each blocking actor has a surviving move that actually vacates the required cells;
- dependency failure is propagated to a fixed point so a follower cannot phase through an actor whose own move ultimately failed;
- successful placements continue through `WorldMutationService.set_placements_batch`, preserving one final occupancy publication rather than serial intermediate positions.

In-place turns are not treated as vacating their occupied cell.

### Passage-aware production path

Production uses `PassageAwareMovementActionService`.

Its wrapper previously classified any occupied destination as a blocked passage before base movement arbitration. It now delegates actor-only occupancy to the canonical movement service. Doors/other passage blockers keep their existing resolver path.

### Walk commitment boundary

Ordinary walk remains WHEN `CANCELABLE` during wind-up.

Its final `movement.commit` offset is now declared as the action's Phase-2A commitment point. Once the action reaches that timestamp, later interruption on the same tick cannot retroactively erase the already-due movement consequence.

Run remains COMMITTED under its existing contract. Turn behavior is unchanged.

## Focused production verification

Fresh focused verifier head/run:

- `f605987f7feb4fd24e06f3724d90622d900beee9`
- run `36187796332` — **SUCCESS**

Marker:

`PHASE2C_MOVEMENT_CONFLICTS_OK contest_tick=10 swap_tick=20 no_hidden_winner=true`

The real production scene proves:

### Same destination

- two production infected begin on opposite sides of one empty cell;
- both ordinary walk actions are accepted and reach their commit point on tick 10;
- both claim the same destination from the same pre-resolution occupancy;
- neither moves;
- both fail explicitly with `target_contested`;
- there is no sorted first-actor winner.

### Reciprocal occupied-cell swap

- two production infected begin in adjacent cells facing each other;
- both occupied-cell walk requests are admitted to timestamp arbitration;
- both reach the same commit timestamp, tick 20;
- each actor's destination is the other actor's pre-resolution origin;
- because both blockers simultaneously vacate, `set_placements_batch` atomically swaps their positions;
- both movement commits publish.

An earlier focused run `36187606605` failed only the reciprocal-swap acceptance assertion. Its log identified the production `PassageAwareMovementActionService` wrapper as still rejecting actor occupancy before base arbitration. That exact wrapper was repaired at `d87f1402...`; the unchanged physical assertions then passed. A later test-only commit fixed the evidence marker so the contest tick remains visible after the test clears its event array.

## Durable design rule

`DESIGN_DECISIONS.md` now records:

- same-tick actor movement is a physical conflict set, not serial mini-turns;
- same-destination conflicts fail all competing movers rather than choose an initiative winner;
- reciprocal/vacating movement may succeed atomically;
- deterministic sort order is implementation stability only;
- static blockers do not disappear merely because simultaneous arbitration exists.

`SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md` now reflects the live timestamp arbitration and walk commitment boundary instead of the older serial race wording.

## What this slice does NOT claim

Phase 2 remains open.

This operation establishes the canonical same-tick **walk placement** primitive. It does not yet close:

- shove-vs-move ordering;
- simultaneous shove/displacement conflicts;
- mob-force/crowd-pressure aggregation;
- opening/fortification pressure resolution;
- final cross-system rule for an actor that reaches committed movement on the same tick it is lethally struck;
- firearm/movement same-tick conflicts;
- canonical fear tuning/effects;
- zombie callback/perception fan-out and performance;
- presentation of overlapping outcomes as one coherent visual/audio beat;
- crowded-fight timing budgets or Safari acceptance.

Do not claim that all spatial consequences are solved yet.

## Current release direction

The game remains player versus zombies. Living survivor NPCs, raiders, followers, recruitment/dialogue and live society simulation remain retired from production.

Core loop: scavenge, fight, craft, survive on the persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well.

Combat/time identity now has three executable Phase-2 foundations:

1. explicit interruptible -> committed action windows;
2. simultaneous melee hit/damage/death semantics;
3. same-tick actor walk arbitration without hidden initiative.

## NEXT OPERATION

Phase 2C continuation: integrate combat displacement/shove with the same timestamp spatial-arbitration rule, then close the committed-movement-vs-same-tick-death seam.

Start with targeted current owners only:

- `CombatActionService._apply_resolution_batch` / `_resolve_shove`;
- current `MovementActionService` timestamp candidate/placement batch;
- `ActorHealthState` consequence-batch boundary;
- `ActorDeathTransitionService` deferred lethal transition;
- production composition seam only if one existing service reference must be wired.

Required outcomes:

- a shove and an ordinary move due on the same tick evaluate from one stable physical state;
- two simultaneous displacement claims cannot receive an attacker-ID/order winner;
- blocked shove/displacement cannot phase actors through static or surviving actor blockers;
- a movement or displacement consequence that already reached its commitment point is not erased merely because that actor also receives lethal damage on the same tick;
- death/corpse placement publishes only after every already-committed same-tick spatial consequence that should survive has been accounted for;
- preserve Phase-2B mutual lethal hit semantics.

This should create the shared displacement primitive needed before actual zombie mob-force aggregation. Do not tune mob force or fear yet.

Before changing code, delete the Phase-2C verifier pair and create a new prompt-local verifier/workflow scoped to shove/move/death timestamp interaction.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- Phase-2A commitment offsets and snapshot compatibility;
- Phase-2B simultaneous melee hit/death rule;
- Phase-2C no-hidden-initiative walk arbitration;
- stable pre-contact melee target snapshot;
- existing eight resident-backed infected startup cohort;
- no live survivor/raider/social runtime;
- player movement, Health/injury, inventory, condition/moodlets, skills and equipment;
- day/night, weather, utilities and vehicles;
- persistent world changes and terrain/streaming improvements;
- input locked until the next legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless a later explicit UX operation replaces it.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
