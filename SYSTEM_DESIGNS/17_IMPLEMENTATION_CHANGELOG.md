# System 17 Implementation Changelog — Run / Damage-Interruptible Walking

Date: 2026-08-16

## Implemented

- Added explicit semantic `movement.run_forward`; no persistent Run mode/state.
- Run moves two straight forward cells under one WHEN COMMITTED action with two physical stride phases.
- Current 10-tick walk terrain resolves to 6 ticks per Run stride / 12 total before actor modifiers.
- Mixed terrain derives each stride independently at 60% of its normal walk cost and sums the result.
- Run validates both cells before starting and revalidates placement/collision/terrain per stride with no reservations.
- A successful first stride remains physically committed if the second later becomes blocked.
- Forward/back Walk changed from COMMITTED to WHEN CANCELABLE.
- Added additive Health `damage_applied` semantic observation for actual `apply_damage()` HP loss only.
- Added stateless `MovementDamageInterruptionService`: real damage asks WHEN to interrupt current Movement; Walk cancels, Run/Turn remain committed.
- Added Run-start fatigue eligibility: fatigue 80+ blocks Run with `too_exhausted_to_run`.
- Added stateless `MovementRunExertionService`: each successful Run stride adds +1 real fatigue; failed strides add none.
- Run capability is latched at commitment, so a Run begun at fatigue 79 can cross to 80 after stride one and still complete stride two.
- Activated the existing 03 Run capability seam; crouched Run remains blocked.
- Canonical demo now registers the already-implemented Needs and Carry mobility providers so real condition timing modifiers are live.
- Added semantic player `RUN_FORWARD` intent.
- Desktop Run: Shift+W / Shift+Up.
- Touch/Safari Run: native RUN button in the lower-right slot beneath Turn R.
- Extended the existing demo controller to route semantic Run intent only; no movement rules moved into input/UI.

## Verification

Initial code candidate:

`33580c2e9016c15591005536707b2729e580876e`

Dedicated workflow:

`Run and Damage-Interruptible Walking contract`

Initial run:

`31998617639` — SUCCESS

The candidate passed:

- architecture/boundary checks;
- Godot 4.7.1 import/parse;
- revised Movement regression;
- Actor Locomotion regression;
- Health / Needs / Carry regressions;
- dedicated System 17 integration smoke;
- Canonical Demo / HUD / Player Shell regressions;
- actual canonical demo startup.

No production repair was required after the first implementation candidate.

## Protected boundaries

Unchanged behaviorally:

- WHERE / WHAT foundation contracts;
- Collision classification;
- WHEN internals;
- persistent locomotion state shape;
- Health HP/injury calculation and persistence;
- Needs persistent state shape;
- Carry/Skills/Inventory/Hands/Item Transfer;
- renderer/art stack;
- HUD/Stats/Inventory/Menu truth;
- authored demo map;
- generation/streaming;
- frozen Reboot reference runtime.

MovementActionService imports neither Health nor Needs. Run/damage/exertion cross-domain effects are coordinated through narrow public contracts.
