# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2C CAUSAL TRANSITION EDGES COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows, Phase 2B simultaneous melee hit/death semantics, and prior Phase-2C stat-based same-destination arbitration remain protected.

This bounded slice implements the first executable correction from the user's newly approved full tick model:

> A tick is a causal transition from `S_t` to `S_t+1`: consequences already earned for the timestamp are sealed, interactions/occupancy are resolved from stable incoming truth, then outgoing world truth is published. Same-timestamp actors do not take serial mini-turns.

Starting main for this operation: `0f4cb77d3e780bbfd16903cb13ec339227c5ea57`.

Functional/executable owning head: `54a62812bf692816ebf8907ff3f1c91e85296f41`.

Focused verifier head/run: `54a62812bf692816ebf8907ff3f1c91e85296f41` / `36192545127` — **SUCCESS**.

Documentation head immediately before this final handoff write: `223aed4ae439c77ecc5b990b0705b5afc77085d1`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The preceding Phase-2C stat-contest pair had already been deleted before this slice's implementation:

- `game/scripts/ci/Phase2CStatContestsSmoke.gd`
- `.github/workflows/phase2c-stat-contests.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CTransitionEdgesSmoke.gd`
- `.github/workflows/phase2c-transition-edges.yml`

The next code prompt must delete this pair before changing code and create its own focused verifier/workflow.

## User-approved canonical tick model

The user approved the following simulation model on 2026-09-25.

Canonical conceptual order:

1. **Seal incoming consequences** whose commitment/contact matured at the current authoritative WHEN timestamp.
2. **Describe the transition** from the stable incoming state: conditional origin releases, movement trajectories/edges, contact facts, destination claims, shove/pressure forces, topology releases.
3. **Resolve physical interaction** without callback order, actor ID, queue order or hidden initiative.
4. **Solve occupancy dependencies** to a fixed point.
5. **Publish final spatial truth atomically.**
6. **Apply bodily/condition consequences** produced by already-established contact/force facts.
7. **Publish terminal outgoing truth** such as incapacitation, death and corpse placement.
8. The resulting stable world is `S_t+1`; only that outgoing state becomes incoming truth for new decisions.

This is a causal order of consequence categories, not an initiative order among actors.

### Important derived distinction

A movement `X -> Y` is conceptually two linked transition facts:

- a **conditional release** of origin X;
- an **arrival claim** on Y for the outgoing state.

The origin release becomes effective only if the movement survives arbitration and the actor actually leaves X.

This is why a follower may move into a cell vacated by another actor on the same timestamp, while a failed upstream movement can propagate failure backward through dependent followers.

## Completed — reciprocal walk is now a head-on edge conflict

Prior Phase-2C code allowed two adjacent actors walking directly into each other's occupied cells to atomically swap.

That provisional behavior is now superseded.

For ordinary walking:

- `A: X -> Y`
- `B: Y -> X`

is an **opposing traversal of the same physical edge**.

The actors meet. They do not phase through one another.

`MovementActionService` now detects this reciprocal edge traversal during the same timestamp arbitration pass and marks both walkers with:

`movement_edge_conflict`

Both remain in their incoming cells.

No stat comparison is used to let an ordinary walker push through another actor; displacement authority belongs to actual force mechanics such as shove, run impact and future mob pressure.

## Completed — same-direction release chains still work

This correction does not turn incoming occupancy into a permanent blocker for the whole timestamp.

Example:

- A begins in X and claims Y;
- B begins in Y and claims Z;
- C begins in Z and claims W;
- W is genuinely available.

If all three same-timestamp moves survive arbitration, B's departure releases Y for A and C's departure releases Z for B. The placement batch publishes:

- A -> Y
- B -> Z
- C -> W

atomically.

If an upstream departure fails in a later dependency case, the existing fixed-point logic still removes dependent followers rather than allowing phasing.

## Focused production verification

Fresh focused production run:

- functional head: `54a62812bf692816ebf8907ff3f1c91e85296f41`
- run: `36192545127` — **SUCCESS**

Marker:

`PHASE2C_TRANSITION_EDGES_OK reciprocal_blocked=true release_chain=true`

The production scene proves:

### Reciprocal head-on edge

- two production infected begin in adjacent cells;
- both ordinary walk actions are admitted to the same timestamp arbitration;
- each claims the other's incoming cell;
- neither actor swaps through the other;
- both remain at origin;
- both fail explicitly with `movement_edge_conflict`.

### Three-actor release chain

- three production infected occupy consecutive cells facing the same direction;
- all three walks share the same due timestamp;
- the leading destination is empty;
- all three placements advance atomically by one cell;
- trailing actors successfully inherit cells released ahead of them.

This directly verifies the distinction between **leaving a cell** and **arriving into a cell**.

## Existing rules preserved

- same-destination claims still use the approved frozen canonical physical-stat contest;
- a unique highest physical score may win an exclusive empty destination;
- exact/unknown top score remains a stalemate;
- actor ID/callback/sorted queue order never becomes initiative;
- static/non-ACTOR blockers remain blockers;
- compatible non-reciprocal release chains/cycles retain fixed-point dependency semantics;
- successful placements still publish through `WorldMutationService.set_placements_batch`;
- walk remains CANCELABLE before its final commitment point and COMMITTED once that point matures;
- Phase-2B same-tick melee contacts/damage/deferred death remain protected.

## Durable documentation updated

- `DESIGN_DECISIONS.md` now records the canonical `S_t -> transition -> S_t+1` causal model and the distinction between origin release and destination arrival.
- `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md` now replaces unconditional reciprocal-swap language with head-on edge-conflict semantics and records the focused verifier.
- `ROADMAP.md` reflects valid release chains versus invalid reciprocal ordinary-walk swaps.
- `CHANGELOG_LATEST.md` records this executable slice and verifier evidence.

## What this slice does NOT claim

Phase 2 remains open.

This operation implements only the movement-edge correction from the larger approved tick model. It does not yet close:

- shove-vs-move trajectory arbitration;
- simultaneous opposing shoves/displacements;
- same-direction force aggregation / zombie mob pressure;
- push-chain force propagation;
- impact/crush consequences when force terminates against an immovable blocker;
- final cross-system committed consequence versus same-tick lethal death ordering;
- door/topology transition participation in the same pipeline;
- firearm/movement interaction;
- canonical fear tuning;
- zombie callback/perception performance;
- overlapping consequence presentation;
- crowded-fight/Safari performance acceptance.

Do not claim the entire causal transition pipeline is executable yet. Its ordering is now an approved design contract being implemented in bounded slices.

## Current release direction

The game remains player versus zombies. Living survivor NPCs, raiders, followers, recruitment/dialogue and live society simulation remain retired.

Core loop: scavenge, fight, craft, survive on the persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well.

Phase-2 executable foundations now include:

1. explicit interruptible -> committed action windows;
2. simultaneous melee hit/damage/death semantics;
3. same-tick occupancy batching and fixed-point release chains;
4. stat-based exclusive shared-space contests;
5. head-on reciprocal movement-edge conflict detection.

## NEXT OPERATION

Continue Phase 2C by routing combat shove/displacement into the approved causal transition model.

Targeted starting reads only:

- `CombatActionService._apply_resolution_batch` / current shove resolution path;
- current `MovementActionService` timestamp candidate/arbitration seam;
- `MovementPhysicalContestProvider.gd` / `ActorPhysicalContestQuery.gd`;
- `ActorHealthState` consequence-batch boundary and `ActorDeathTransitionService` only for the exact same-timestamp terminal ordering seam;
- production composition only where one public seam must be wired.

Required outcomes for the next bounded slice:

- shove contact is sealed as an incoming current-timestamp consequence rather than immediately mutating target placement;
- shove produces a forced trajectory/displacement claim that enters the same spatial arbitration as movement;
- a target's own committed movement and incoming shove can oppose or align without callback-order initiative;
- ordinary movement never gains implicit shove authority merely from a high stat;
- static blockers remain absolute for this slice;
- competing displacement outcomes reuse frozen canonical physical state;
- already-earned current-tick force/contact is not retroactively erased by lethal damage generated on the same timestamp;
- death/corpse publication occurs only after spatial consequences that legitimately survive that timestamp are accounted for;
- preserve Phase-2B mutual lethal hits and every completed Phase-2C movement rule above.

Do not tune mob-force magnitudes or fear yet. Shape the shove path so later same-direction crowd force can aggregate through it instead of requiring a replacement architecture.

Before changing code, delete the current prompt-local pair:

- `game/scripts/ci/Phase2CTransitionEdgesSmoke.gd`
- `.github/workflows/phase2c-transition-edges.yml`

Then create a brand-new focused verifier/workflow scoped to shove/displacement transition arbitration.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- Phase-2A commitment offsets;
- Phase-2B simultaneous melee hit/death rule;
- Phase-2C stat-based same-destination arbitration;
- Phase-2C release-chain/fixed-point movement semantics;
- Phase-2C head-on reciprocal walk conflict;
- stable pre-contact melee target snapshot;
- existing eight resident-backed infected startup cohort;
- no live survivor/raider/social runtime;
- player movement, Health/injury, inventory, condition/moodlets, skills and equipment;
- day/night, weather, utilities and vehicles;
- persistent world changes and terrain/streaming improvements;
- input locked until legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
