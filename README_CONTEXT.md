# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2A COMMITMENT WINDOWS COMPLETE — 2026-09-25

Phase 1 remains complete. This bounded Phase-2 slice implemented explicit action commitment windows in canonical WHEN timing and wired melee contact to the point-of-no-return seam.

Starting main for this operation: `c290e514acb7fec52d2d5c5ff9b2b99fe71ddf79`.

Functional/executable owning head: `bd69adcb19d8b473018cbdbbcd01c9cf41a3c2cd`.

Focused verifier head: `664d33d69168e6354dddd33be863eb87981df137`.

Documentation head immediately before this final handoff write: `c422977dfa04677e37307a0c031673554e159819`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous Phase-1 prompt-owned pair was deleted before Phase-2 code work:

- `game/scripts/ci/Phase1SurvivorRuntimeRetirementSmoke.gd`
- `.github/workflows/phase1-survivor-runtime-retirement.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CombatCommitmentWindowsSmoke.gd`
- `.github/workflows/phase2-combat-commitment-windows.yml`

The next code prompt must delete this Phase-2A pair before changing code and create its own focused verifier/workflow.

## Completed

- Added `commit_offset_ticks` to canonical `TimedAction`.
- A CANCELABLE or RESUMABLE action now keeps that policy only before its declared commit offset; at and after the boundary its effective policy is COMMITTED.
- Already-COMMITTED actions remain committed for their whole duration.
- Added `TimedAction.effective_interruption_policy(world_tick)` and `is_committed_at(world_tick)`.
- `TickKernel.interrupt_action` now checks the effective current policy rather than the action's original static policy.
- Commitment boundaries persist through action copy and WHEN snapshot/restore.
- `TickKernel.begin_action` accepts the optional commit offset without breaking existing callers.
- Melee strike actions use their existing `combat.contact` phase offset as the commitment boundary.
- Light/unarmed strikes therefore remain interruptible during wind-up but cannot be canceled after contact has become consequential.
- Existing heavy strikes and shoves remain fully committed from action start; their current behavior was not weakened.
- Light attack quote text now exposes the transition as `INTERRUPTIBLE → COMMITTED @Nt`.
- Existing same-tick action-phase batching remains intact; this operation did not replace the scheduler or add a second clock.
- No survivor/raider runtime was restored.

## Focused verification

Owning focused run `36183887142`: **success**.

It proved:

- a CANCELABLE action with a commit offset cancels before the boundary;
- two actors' contact phases due at tick 3 are both dispatched in the same tick batch;
- at the contact boundary both actions report effective COMMITTED policy;
- an attempted interruption after commitment returns RUNNING and does not cancel recovery;
- the player returns to the normal automatic decision pause;
- commit offsets survive timing snapshot/restore;
- the real production `CombatActionService` player unarmed strike carries contact as its commit boundary;
- that production strike cancels before contact;
- that production strike refuses cancellation after contact and then returns to the ordinary decision pause.

Successful verifier marker:

`PHASE2_COMMITMENT_WINDOWS_OK same_tick_phases=2 stop=4 production_actor=actor.player.demo`

An earlier verifier revision on old head `95ee496...` intentionally cleared the decision actor and could continue processing recurring world events instead of reaching the normal automatic stop. That was a verifier design defect, not a gameplay failure. It was superseded by `664d33d...`, which keeps the real decision-pause contract and passed.

## What this slice does NOT claim

Phase 2 is still open.

This operation does not yet prove or implement:

- atomic/coherent damage + death publication for all simultaneous contacts;
- contested movement/combat ordering beyond the existing same-tick event ordering;
- mob force/crowd pressure;
- final canonical fear tuning/effects;
- removal of zombie callback/perception fan-out;
- presentation of overlapping actor outcomes as one coherent beat;
- crowded-fight performance targets or Safari timing acceptance.

The existing combat service already gathers same-tick melee contact intents against a stable actor-cell snapshot before applying them. However, individual damage/injury/death mutations are still published sequentially afterward, so downstream death/removal callbacks can make later same-tick effects order-sensitive. That is the next bounded seam.

## Current release direction

The game is player versus zombies. Living survivor NPCs, raiders, followers, recruitment/dialogue and live society simulation remain retired from production.

Core loop: scavenge, fight, craft, survive on the persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well.

Combat identity remains:

- one authoritative WHEN clock;
- automatic decision pauses rather than player-selectable tactical pause;
- explicit action durations and consequential phases;
- interruptible wind-up versus committed point-of-no-return behavior;
- coherent simultaneous effects for events due at the same tick;
- mob force and fear as required mechanics.

Hard application pause remains separate from tactical timing and must freeze without canceling or granting a free order.

## NEXT OPERATION

Phase 2B: make same-tick melee impacts and death consequences coherent at one combat consequence boundary.

Targeted starting reads only:

- `CombatActionService.gd` current `_on_external_event`, stable intent snapshot and resolution path;
- `ActorHealthState.gd` damage mutation/signals;
- `ActorDeathTransitionService.gd` death/corpse callback timing;
- `TickKernel.gd` exact same-tick event ordering only if needed to connect the boundary.

First establish the exact current failure mode for two or more impacts due on the same tick, especially mutual lethal hits and multiple hits on one target. Then implement a bounded deterministic batch/transaction seam so target selection, damage calculation, HP/death truth, injuries and corpse transition do not depend on attacker ID/event callback order.

Preserve the newly implemented commit-offset contract. Do not broaden this operation into mob force, fear tuning, movement conflicts or zombie performance yet; those follow after the combat consequence boundary is trustworthy.

Before changing code, delete the Phase-2A verifier pair and create a new prompt-local verifier/workflow scoped to simultaneous impact/death resolution.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- Phase-2A commitment offsets and snapshot compatibility;
- existing eight resident-backed infected startup cohort;
- no live survivor/raider/social runtime;
- stable pre-contact target snapshot semantics;
- player movement, Health/injury, inventory, condition/moodlets, skills and equipment;
- day/night, weather, utilities and vehicles;
- persistent world changes and terrain/streaming improvements;
- input locked until the next legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless a later explicit UX operation replaces it.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
