# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2B SIMULTANEOUS MELEE CONSEQUENCES COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows remain protected. This bounded Phase-2B slice implements the approved rule that one combat tick has no internal initiative: every melee contact due on that tick is resolved from the same pre-impact state, every valid hit is accounted for, and death/corpse transition publishes only afterward.

Starting main for this operation: `004f55a77ca93c17bfa6a4501c60a5c40a486fa7`.

Functional/executable owning head: `a33e302467921ab58541c462a89fc37b6f2b6964`.

Focused verifier owning run: `36185910858` — **SUCCESS**.

Documentation head immediately before this final handoff write: `02c00963d1ac203a79c7809198b85848dd83af31`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## User-approved simultaneous tick rule

The user's explicit combat rule is now canonical:

- there is no "first attacker" inside one authoritative tick;
- freeze the relevant pre-resolution state;
- determine all attacks that legitimately reach contact on that tick;
- calculate all those impacts from that same frozen state;
- account for every hit/injury;
- only then publish HP-zero death, corpse conversion and downstream removal.

Therefore:

- if player and zombie mutually land lethal hits on one tick, both hits land and both actors die;
- if multiple attackers hit one target on one tick, every already-due hit lands even when aggregate damage is lethal;
- deterministic sorting may stabilize processing but may never become hidden initiative or erase an already-due consequence.

This rule is also recorded in `DESIGN_DECISIONS.md` and System 37.

## Prompt-local verifier lifecycle

The Phase-2A prompt-owned pair was deleted before Phase-2B code work:

- `game/scripts/ci/Phase2CombatCommitmentWindowsSmoke.gd`
- `.github/workflows/phase2-combat-commitment-windows.yml`

Fresh current pair:

- `game/scripts/ci/Phase2BSimultaneousImpactsSmoke.gd`
- `.github/workflows/phase2b-simultaneous-impacts.yml`

The next code prompt must delete this Phase-2B pair before changing code and create its own focused verifier/workflow.

## Completed

### Combat consequence preparation

`CombatActionService` already collected all CONTACT intents due on one tick and selected targets from a stable actor-cell snapshot. Phase 2B completes that seam:

- all target choices are frozen before mutation;
- all strike damage values are derived before mutation;
- same-target strike damage is aggregated for canonical HP mutation;
- every valid contact retains its own injury and `impact_resolved` publication;
- HP is clamped at zero, but overkill does not erase an already-due contact.

### Health consequence batch

`ActorHealthState` now provides a bounded nested consequence-batch boundary:

- `begin_consequence_batch()`;
- `end_consequence_batch()`;
- `consequence_batch_active()`;
- start/finish signals for downstream canonical owners.

The batch does not create a parallel health model. System 13A remains the HP/injury owner.

### Deferred lethal transition

`ActorDeathTransitionService` still owns generic death/corpse conversion.

Outside a consequence batch, HP > 0 -> HP <= 0 transitions remain immediate.

Inside a combat consequence batch:

- lethal HP changes are recorded as pending deaths;
- no actor is unplaced and no corpse is created while same-tick impacts are still being published;
- when the outer batch closes, pending lethal actors are transitioned deterministically;
- active WHEN actions are then failed by the existing death owner;
- exact carried/equipped item identities still move through the existing corpse path.

### Protected Phase 2A semantics

The new batch does not weaken commitment windows:

- light/unarmed strike wind-up remains interruptible;
- contact is still the point of no return;
- after contact, same-tick damage cannot retroactively cancel the already-due attack;
- heavy strikes/shoves remain committed according to their existing policy;
- WHEN remains the single authoritative clock.

## Focused production verification

Fresh focused run `36185910858`: **SUCCESS**.

Successful marker:

`PHASE2B_SIMULTANEOUS_IMPACTS_OK shared_tick=3 mutual_tick=10 impacts_before_death=true`

The production-scene verifier proves two required cases.

### Two hits on one lethal target

- player and a second attacker both reach CONTACT against the same 1-HP infected on tick 3;
- both `impact_resolved` events publish;
- both contacts create injuries;
- the target reaches canonical HP 0;
- the death/corpse event occurs only after both impacts;
- one persistent corpse is created for the dead target.

### Mutual lethal contact

- player and infected begin from living pre-tick state at 1 HP each;
- both attacks reach CONTACT on tick 10;
- both `impact_resolved` events publish on tick 10;
- neither death/corpse transition publishes before both hits;
- both actors reach HP 0;
- both receive their generic persistent corpse transition.

This directly verifies the user's approved "we both got hit and both died" rule in the real production combat/death owners.

## What Phase 2B does NOT claim

Phase 2 remains open.

This slice does not yet close:

- contested same-tick movement into the same cell;
- simultaneous shove/displacement conflicts;
- mob-force/crowd-pressure rules;
- opening/fortification force aggregation;
- canonical fear tuning/effects;
- zombie callback/perception fan-out and performance;
- presentation of overlapping outcomes as one visual/audio beat;
- crowded-fight timing budgets or Safari acceptance;
- firearm same-tick batching beyond existing firearm behavior.

Shoves remain in the melee resolver but conflicting displacement ordering is not claimed solved by this operation.

## Current release direction

The game remains player versus zombies. Living survivor NPCs, raiders, followers, recruitment/dialogue and live society simulation remain retired from production.

Core loop: scavenge, fight, craft, survive on the persistent map with day/night, weather, power and water. A base is an existing fortified house/building with supplies, generator and well.

Combat identity now has two executable Phase-2 foundations:

1. explicit interruptible -> committed action windows;
2. true simultaneous melee consequence/death semantics at one CONTACT tick.

## NEXT OPERATION

Phase 2C: define and implement deterministic same-tick physical conflict resolution for movement/displacement, using the simultaneous-tick rule rather than actor order.

Start with targeted current owners only:

- movement action CONTACT/completion and any existing batch placement seam;
- `WorldMutationService.set_placements_batch` and exact occupancy validation;
- `CombatActionService._resolve_shove`;
- current infected forward movement submission;
- opening-pressure/mob-pressure code only where a concrete displacement/force seam requires it.

Required rule:

- actors due to move/displace on the same tick evaluate against one stable pre-resolution occupancy state;
- processing order cannot allow one actor to "win" merely because its callback ran first;
- direct swaps, same-destination contests, shove-vs-move and blocked displacement need explicit deterministic outcomes;
- no actor phases through a blocker;
- a zombie killed by a same-tick attack still contributes any movement/force consequence that had already reached its own committed consequence point on that tick.

This operation should establish the physical conflict primitive needed by later mob force. Do not broaden into final mob-force tuning, fear, zombie performance or presentation until same-tick spatial consequences are trustworthy.

Before changing code, delete the Phase-2B verifier pair and create a new prompt-local verifier/workflow scoped to same-tick movement/displacement conflicts.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- Phase-2A commitment offsets and snapshot compatibility;
- Phase-2B simultaneous melee hit/death rule;
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
