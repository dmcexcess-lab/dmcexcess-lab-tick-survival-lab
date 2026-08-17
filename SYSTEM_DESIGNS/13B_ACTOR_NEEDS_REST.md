# Tick Survival Lab — 13B Actor Needs / Rest

Status: **APPROVED — user explicitly approved all System 13 children for implementation on 2026-08-16**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor fatigue, hunger, thirst, and sleep-pressure truth as simple consequential values suitable for future actions, capability policies, moodlets, and UI.

## Non-goals
13B does not own food/water items, eating/drinking actions, beds, temperature, calendar conversion, UI labels, or an implicit simulation clock.

## Owner
`game/scripts/simulation/actors/needs/`:
- `ActorNeedsState.gd`
- `ActorNeedsMobilityModifierProvider.gd`

## Public contract
`ActorNeedsState` validates `actor.survivor` enrollment through read-only WHAT. Reads expose each need, version/revision, record copy, actor IDs and deterministic snapshot. Mutations enroll/remove, set one/all values, change values by signed deltas, and load snapshot.

## Numeric semantics
All four values are integer **0..100 pressure scales**:
- `fatigue`: 0 fresh, 100 exhausted;
- `hunger`: 0 satiated, 100 severe hunger;
- `thirst`: 0 hydrated, 100 severe thirst;
- `sleep_pressure`: 0 well rested, 100 severe sleep debt.

Enrollment defaults all four to 0. Population/player-story setup may deliberately set other starting values through public mutation.

Fatigue and sleep pressure remain distinct: fatigue is short-horizon exertion; sleep pressure is longer-horizon time-awake debt.

## Time rule
There is no `_process()` and no built-in tick-rate guess. Future needs progression/rest/eating/drinking coordinators own when and by how much these values change, using WHEN/calendar policy explicitly.

## Immediate locomotion seam
13B supplies a read-only `ActorNeedsMobilityModifierProvider` compatible with 03. It recovers golden Tick's fatigue timing pressure: fatigue contributes up to +65% duration at fatigue 100 (`duration_adjustment_bp = fatigue * 65`) to recognized locomotion actions. Missing Needs state returns UNKNOWN/fail-closed through the provider. Hunger/thirst/sleep do not receive invented movement penalties in v1.

## Persistence
Schema-versioned deterministic snapshot, sorted actor IDs, atomic malformed-state rejection, monotonic revision/per-actor version.

## Dependencies
Allowed: WHAT read validation; 03's narrow `ActorMobilityModifierProvider` seam.
Forbidden: Movement internals, Health, Skills, Inventory, Carry, Moodlets, WHEN internals, UI/render/art, reboot.

## Failure cases
Reject invalid actor enrollment, out-of-range values, malformed snapshots. Delta changes clamp at 0/100. Same-value writes are no-ops.

## Tests
Dedicated smoke covers defaults, set/change/clamp, fatigue-vs-sleep independence, non-survivor rejection, copy safety, versioning, deterministic snapshot restore, malformed rejection, and exact recovered fatigue provider scaling.

## Future seams
Eating/drinking/sleep/rest actions mutate Needs after timed outcomes; long-horizon needs progression can be a separate scheduler/policy owner; moodlets read Needs; other capability policies may interpret hunger/thirst/sleep later without 13B importing them.

## North-star fit
Four coarse values preserve the survival decisions without metabolic simulation.

## Approved decisions — 2026-08-16
1. Fatigue/hunger/thirst/sleep-pressure use independent 0..100 integer pressure scales.
2. Zero means no current pressure; 100 means severe pressure.
3. Enrollment defaults to zero without implying future generated actors must start there.
4. No hidden frame-time/tick progression exists in the state owner.
5. Fatigue reuses golden Tick's +0..65% locomotion-duration modifier through 03's provider seam.
6. No hunger/thirst/sleep movement penalties are invented in v1.
