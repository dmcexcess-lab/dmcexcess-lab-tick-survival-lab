# Tick Survival Lab — 13B Actor Needs / Rest

Status: **IMPLEMENTED + CI**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor fatigue, hunger, thirst, and sleep-pressure truth as simple consequential values suitable for future actions, capability policies, moodlets, and UI.

## Owner
- `game/scripts/simulation/actors/needs/ActorNeedsState.gd`
- `game/scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd`
- smoke: `game/scripts/ci/ActorNeedsSmoke.gd`

## Contract
All four values are independent integer **0..100 pressure scales**: fatigue, hunger, thirst, and sleep pressure. Zero means no current pressure; 100 means severe pressure. Enrollment defaults all four to zero; future population/player-story setup may explicitly choose other starting values.

Fatigue is short-horizon exertion/tiredness. Sleep pressure is longer-horizon time-awake debt. They are intentionally separate.

## Time rule
13B has no `_process()` and no guessed tick/calendar conversion. Future eating, drinking, rest, sleep, exertion, and needs-progression coordinators explicitly mutate these values using WHEN/calendar policy.

## Locomotion seam
`ActorNeedsMobilityModifierProvider` plugs into 03's existing read-only provider contract. It recovers golden Tick fatigue timing pressure exactly: `duration_adjustment_bp = fatigue * 65`, so fatigue 100 adds 6500 basis points (+65%) to recognized locomotion action duration. Missing Needs state returns UNKNOWN/fail-closed. Hunger, thirst, and sleep pressure receive no invented movement penalty in v1.

## Persistence
Deterministic schema-v1 snapshot/restore, sorted actor IDs, atomic malformed-state rejection, global revision and per-actor version.

## Boundaries
Allowed: read-only WHAT validation and 03's narrow mobility-provider seam.
Forbidden: Movement internals, Health, Skills, Inventory, Carry, Moodlets, WHEN internals, UI/render/art, reboot.

## Verification
`ActorNeedsSmoke.gd` covers defaults, independent fatigue/sleep values, set/change/clamp, non-survivor rejection, no-op versioning, deterministic snapshot restore, malformed rejection, unrelated-action neutrality, and exact recovered +65%-at-100-fatigue provider scaling.

Initial complete System 13 candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed **Actor Stats Domains contract** run `31992365565` with no production repair.

## Approved decisions — 2026-08-16
1. Fatigue/hunger/thirst/sleep-pressure use independent 0..100 integer pressure scales.
2. Zero means no current pressure; 100 means severe pressure.
3. Enrollment defaults to zero without constraining future generated starts.
4. No hidden frame-time/tick progression exists in the state owner.
5. Fatigue reuses golden Tick's +0..65% locomotion-duration modifier through 03.
6. No hunger/thirst/sleep movement penalties are invented in v1.
