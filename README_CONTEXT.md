# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2C STAT-BASED PHYSICAL CONTESTS COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows, Phase 2B simultaneous melee hit/death semantics, and Phase 2C same-tick walk batching remain protected.

This bounded continuation refines the provisional same-destination movement rule using the user's newly approved principle:

> When simultaneous physical outcomes genuinely compete for one exclusive result, defer to frozen canonical actor stats/state rather than callback order, actor ID, queue order, or arbitrary initiative.

Starting main for this operation: `4e8981b4cd79b8ac9a69f3da64f7c894e1003bbb`.

Functional/executable owning head: `1689fb3124641b7a9abacfc9010fbc7056951e5f`.

Focused verifier owning run: `36189772342` — **SUCCESS**.

Documentation head immediately before this final handoff write: `4c11bb56a0d4c215c6ba7d95b1512048aa3195ef`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The prior Phase-2C walk-arbitration pair was deleted before this code work:

- `game/scripts/ci/Phase2CMovementConflictsSmoke.gd`
- `.github/workflows/phase2c-movement-conflicts.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CStatContestsSmoke.gd`
- `.github/workflows/phase2c-stat-contests.yml`

The next code prompt must delete this pair before changing code and create its own focused verifier/workflow.

## User-approved physical conflict principle

The user explicitly approved this broader design rule on 2026-09-25:

- when an edge case involves competing physical outcomes, prefer existing actor stats/state;
- evaluate those stats from the same frozen simultaneous timestamp;
- never fall back to callback order, actor ID or queue order as initiative;
- a genuine exact stat tie may remain unresolved/stalemated rather than inventing a winner.

This extends the earlier no-internal-initiative tick rule. It does not mean every simultaneous action needs a contest; independent consequences still all happen. The comparison is for genuinely exclusive physical outcomes such as two actors claiming one space or later opposing displacement/force.

## Completed

### Narrow physical-contest provider seam

Added:

- `game/scripts/simulation/movement/MovementPhysicalContestProvider.gd`
- `game/scripts/simulation/actors/locomotion/ActorPhysicalContestQuery.gd`

`MovementActionService` consumes only the narrow read-only provider. It does not import Health, Carry, condition or actor-state internals.

`System34GameMain` composes the production actor query after canonical condition-adjusted Carry state is available and injects it into Movement.

### No invented Strength stat

There is currently no dedicated persistent Strength attribute in the live actor model. This operation deliberately does not create one merely to settle movement contests.

The current derived physical score uses existing canonical facts:

- condition-adjusted carry capacity;
- current carried load;
- current HP relative to max HP;
- locomotion stance;
- movement intent.

Current interpretation:

- greater physical/carry capacity increases contest force;
- load reduces usable force smoothly;
- low HP/injury-state health loss reduces present physical effectiveness;
- crouched movement has less forward leverage than standing movement;
- running contributes more movement momentum than a walk;
- backward movement contributes less than forward movement.

If a dedicated body/Strength attribute is introduced later, it should extend `ActorPhysicalContestQuery`; it must not create a parallel physical-conflict system.

### Same-destination outcome

When two or more movement candidates claim the same destination cell on one timestamp:

1. all candidates still come from the same pre-resolution occupancy state;
2. each claimant receives a frozen derived physical score;
3. a unique highest score wins that exclusive destination;
4. losing claimants fail with `target_contest_lost`;
5. if the highest score is tied, or required stat truth is unknown, the contest remains a stalemate and tied claimants fail with `target_contest_tied`;
6. there is no random, actor-ID or callback-order tiebreaker.

The earlier rule that all same-destination claimants automatically fail is superseded. It remains the effective fallback only when there is no unique physical-stat winner.

### Existing Phase-2C spatial rules preserved

- reciprocal swaps may still succeed atomically when both actors vacate;
- compatible vacating chains/cycles retain fixed-point blocking semantics;
- static/non-ACTOR blockers remain blockers;
- successful placement still uses `WorldMutationService.set_placements_batch`;
- walk remains CANCELABLE during wind-up and COMMITTED at its final `movement.commit` boundary;
- run/turn behavior outside this contest remains unchanged.

## Focused production verification

Functional production head/run:

- `1689fb3124641b7a9abacfc9010fbc7056951e5f`
- run `36189772342` — **SUCCESS**

Marker:

`PHASE2C_STAT_CONTESTS_OK unequal_winner=<resident actor> tied_stalemate=true`

The real production scene proves:

### Unequal canonical physical stats

- two production infected are placed on opposite sides of one empty cell;
- both submit ordinary forward walks with the same due timestamp;
- one actor's canonical carry capacity is set to 24,000 g and the other's to 12,000 g;
- neither capacity change affects the movement timestamp in this zero-load fixture;
- the higher derived physical score wins the destination;
- the weaker actor stays at origin and receives `target_contest_lost`.

### Exact physical tie

- both actors are reset to equal 18,000 g canonical carry capacity with otherwise equivalent focused state;
- both again claim the same cell on the same timestamp;
- neither actor moves;
- both receive `target_contest_tied`;
- no ID/order tiebreaker appears.

## Durable documentation updated

- `DESIGN_DECISIONS.md` records the approved stat-first physical-conflict principle and explicitly supersedes automatic all-fail same-destination arbitration.
- `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md` documents the provider boundary, score inputs, unique-winner/tie semantics and focused evidence.
- `ROADMAP.md` now describes Phase-2C shared-space contests as stat-based.
- `CHANGELOG_LATEST.md` records the executable slice and focused run.

## What this slice does NOT claim

Phase 2 remains open.

This operation does not yet implement or close:

- shove-vs-move arbitration;
- simultaneous opposing shoves/displacements;
- group/zombie mob-force accumulation;
- opening/fortification force aggregation;
- dedicated persistent Strength/body-mass attributes;
- cross-system committed movement/displacement versus same-tick lethal death;
- firearm/movement interaction;
- final fear tuning/effects;
- zombie callback/perception performance;
- coherent presentation of overlapping consequences;
- crowded-fight/Safari performance acceptance.

The current contest score is a real derived rule over canonical state, not a claim that the final body-model vocabulary is complete.

## Current release direction

The game remains player versus zombies. Living survivor NPCs, raiders, followers, recruitment/dialogue and live society simulation remain retired.

Core loop: scavenge, fight, craft, survive on the persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well.

Phase-2 foundations now include:

1. explicit interruptible -> committed action windows;
2. simultaneous melee hit/damage/death semantics;
3. same-tick movement batching with atomic swaps/chains;
4. stat-based resolution of exclusive shared-space physical contests.

## NEXT OPERATION

Continue Phase 2C by routing combat shove/displacement through the same physical-contest seam and timestamp arbitration.

Targeted starting reads only:

- `CombatActionService._apply_resolution_batch` and `_resolve_shove`;
- `MovementPhysicalContestProvider.gd` / `ActorPhysicalContestQuery.gd`;
- current `MovementActionService` timestamp-arbitration/public seam;
- `ActorHealthState` consequence batch and `ActorDeathTransitionService` only where necessary for same-tick death/displacement closure;
- production composition only for exact wiring.

Required behavior:

- shove force versus a moving/holding actor is decided from frozen canonical physical stats/state, not attacker order;
- opposing simultaneous displacements cannot use actor ID or callback order as a winner;
- movement momentum/stance/load/health/current physical capacity remain reusable inputs;
- mob force later aggregates through this same physical contest model rather than bypassing it;
- static blockers remain absolute unless a separate real damage/breakage mechanic changes them;
- an already-committed same-tick physical consequence is not retroactively erased merely because its actor is lethally hit on that same tick;
- preserve Phase-2B mutual lethal hits and all Phase-2C walk/swap/stat-contest semantics.

Do not tune mob-force numbers or fear in the next slice. First establish one shared shove/displacement arbitration path.

Before changing code, delete the current Phase-2C stat-contest verifier pair and create a new prompt-local verifier/workflow scoped to shove/displacement arbitration.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- Phase-2A commitment offsets;
- Phase-2B simultaneous melee hit/death semantics;
- Phase-2C atomic movement batching/swaps/chains;
- Phase-2C stat-based same-destination contest rule;
- no hidden initiative/order fallback;
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
