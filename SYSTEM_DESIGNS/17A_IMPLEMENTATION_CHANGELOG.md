# System 17A Implementation Changelog

Date: 2026-08-16

System: **Movement Exertion / Encumbrance / Run Impact Revision**

## Player-visible changes

- Terrain, fatigue and encumbrance now multiply movement tick cost rather than contributing as additive percentage pressure.
- Fresh/empty normal movement remains 10-tick Walk and 6+6-tick two-cell Run.
- At 100% or greater carry capacity, Run is disabled; Walk remains possible and increasingly slow.
- Successful walking now adds fatigue based on terrain only. Carried weight does not directly increase Walk fatigue.
- Running fatigue now increases with both terrain difficulty and encumbrance below the Run cutoff.
- Running into a known solid blocker is a real committed impact rather than a harmless Run rejection.
- A hard Run impact stops at the last legal square, charges the attempted stride's exertion and causes 5 HP damage.
- Web `LEAVE GAME` now navigates directly to Google instead of attempting browser Back first.

## Architecture changes

- Canonical mobility providers now expose multiplicative duration scales in basis points.
- `ActorMovementCapabilityService` composes stance, fatigue and carry scales multiplicatively with one deterministic final ceiling.
- `MovementTraversalPolicy` exposes read-only base Walk terrain timing so exertion can reuse terrain truth without duplicating a terrain catalog.
- Added `MovementExertionService` as the one stateless Movement -> Needs/Carry exertion coordinator.
- Added `MovementRunImpactDamageService` as a stateless Movement -> Health impact coordinator.
- Removed the superseded Run-only `MovementRunExertionService`.
- `MovementActionService` emits semantic exertion and Run-impact facts while retaining no Health/Needs/Carry implementation dependency.

## Verification

Initial candidate:

`ac949279d0c0474e2c566b4d24f614947e442320`

It passed project parse and all protected System 02/03/13A/13B/13E/17 regressions. The new 17A smoke exposed a test-fixture lifetime mistake: stateless `RefCounted` coordinators were created only as local variables and freed when the fixture returned, so their signal observations disappeared.

No production change was needed for that failure.

Hardened test head:

`eeb5eb421337df3067f45b41fb4837fdb9b8875b`

Dedicated **Movement Exertion Encumbrance and Run Impact contract** run `32000627706` passed:

- project parse;
- Movement/Locomotion regressions;
- Health/Needs/Carry regressions;
- System 17 regression;
- multiplicative timing assertions;
- 100% encumbrance Run lockout;
- over-capacity Walk;
- terrain-only Walk fatigue;
- terrain + encumbrance Run fatigue;
- first- and second-stride Run impacts;
- 5 HP impact damage;
- UNKNOWN fail-closed behavior;
- damage-canceled Walk exertion edge;
- canonical demo/HUD/player-shell regressions;
- canonical startup.

Final promoted-head Web/Pages validation is recorded in the completion response after exact-SHA verification.
