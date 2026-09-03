# Tick Survival Lab — 13B Actor Needs / Rest

Status: **IMPLEMENTED + CI — Run eligibility/exertion seam activated by System 17**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor fatigue, hunger, thirst, and sleep-pressure truth as simple consequential values suitable for actions, capability policies, moodlets, and UI.

## Owner
- `game/scripts/simulation/actors/needs/ActorNeedsState.gd`
- `game/scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd`
- smoke: `game/scripts/ci/ActorNeedsSmoke.gd`

## Contract
All four values remain independent integer **0..100 pressure scales**: fatigue, hunger, thirst, sleep pressure. Zero means no current pressure; 100 means severe pressure. Enrollment defaults all four to zero.

Fatigue is short-horizon exertion/tiredness. Sleep pressure is longer-horizon time-awake debt. They remain intentionally separate.

## Live System 34 composition
This v1 owner remains as a protected compatibility scaffold for its isolated regressions, but it is not the playable survivor's current status truth. System 34 owns the live Satiety, Hydration, Rest, Engagement, Comfort, Calm, and Fatigue channels. Its Fatigue is the canonical short-horizon exertion value (`0` rested -> `100` exhausted), while Rest remains the distinct long-horizon sleep/recovery reserve (`100` rested -> `0` depleted).

`System34GameMain` removes this legacy provider from the live movement-capability composition and disconnects its legacy movement-exertion adapter. The playable HUD, status summary, sustainment actions, moodlets, and movement costs all consume the System 34 condition state. Keeping this state available does not authorize a second live stamina/fatigue meter.

## Time rule
13B has no `_process()` and no guessed tick/calendar conversion. Eating, drinking, rest, sleep, exertion, and broader needs progression explicitly mutate these values through owning actions/coordinators.

System 17 adds only one acute physical exertion consequence: each **successful Run stride** adds +1 fatigue through the existing public `change_need()` API. A failed stride that produces no movement adds no fatigue. Ordinary Walk/Turn/Stance gain no new acute fatigue surcharge in System 17.

## Locomotion seam
`ActorNeedsMobilityModifierProvider` plugs into 03's read-only provider contract.

Existing timing rule remains:

`duration_adjustment_bp = fatigue * 65`

So fatigue 100 adds +65% to recognized locomotion action duration. Missing Needs state returns UNKNOWN/fail-closed.

System 17 adds Run-start eligibility:

- fatigue 0..79 -> Run may start if other capability checks pass;
- fatigue 80..100 -> provider returns BLOCKED with `too_exhausted_to_run`.

This aligns with 13F's existing **Exhausted** moodlet threshold at 80.

The threshold is a **start requirement**, not a mid-sprint cancellation rule. A committed Run begun at fatigue 79 may cross 80 after stride one and still complete stride two. The changed fatigue applies to future action capability/timing.

Hunger, thirst, and sleep pressure still have no invented locomotion penalty in v1.

## Run exertion ownership
System 17's stateless `MovementRunExertionService` observes successful public Movement run-stride facts and calls:

`ActorNeedsState.change_need(actor_id, FATIGUE, +1)`

Needs does not import Movement, and MovementActionService does not import Needs. Persistent Needs state/API shape is unchanged.

## Persistence
Deterministic schema-v1 snapshot/restore remains unchanged: sorted actor IDs, atomic malformed-state rejection, global revision and per-actor version.

## Boundaries
Allowed: read-only WHAT validation and 03's narrow mobility-provider seam; ordinary public Needs mutation by external owning coordinators.
Forbidden: Movement internals, Health, Skills, Inventory, Carry internals, Moodlets, WHEN internals, UI/render/art, Reboot.

## Verification
Needs/System17 CI covers:

- default/independent 0..100 pressure state;
- set/change/clamp/no-op/versioning;
- deterministic persistence;
- exact +65%-at-100 fatigue timing rule;
- Run permitted at fatigue 79 and blocked at 80+;
- successful Run stride +1 fatigue;
- full Run +2 fatigue;
- failed stride no fatigue charge;
- fatigue crossing 80 after committed stride one does not cancel stride two.

## Approved decisions — 2026-08-16
1. Fatigue/hunger/thirst/sleep-pressure use independent 0..100 pressure scales.
2. Zero means no current pressure; 100 means severe pressure.
3. Enrollment defaults to zero without constraining future generated starts.
4. No hidden frame-time/tick progression exists in the state owner.
5. Fatigue uses +0..65% locomotion-duration modifier through 03.
6. No hunger/thirst/sleep movement penalties are invented in v1.
7. Run start requires fatigue below 80.
8. Each successful Run stride adds +1 fatigue through a stateless external coordinator.
9. Run-start eligibility is latched for the committed sprint; crossing 80 mid-Run affects the next action, not the current second stride.
