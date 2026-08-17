# 17 Run / Damage-Interruptible Walking

Status: **DRAFT — discussion only; do not implement until explicitly approved**

Drafted from the user direction on 2026-08-16:

> “Lets add a run mechanic. More movement less tics, its a committed action vs walk which can be interrupted by dmg. Run has a move of two squares.”

## 1. Goal

Add a physically distinct forward sprint action that trades precision/flexibility for rapid displacement, while revising ordinary walking so real damage can interrupt it.

Core player-facing distinction:

- **Walk:** one cell, slower, damage-interruptible.
- **Run:** two cells forward, faster, committed once started.

This is intended to make movement choice tactically meaningful without introducing a persistent run-mode flag, stamina bar, fake sound system, or unrelated combat mechanics.

## 2. Existing contracts intentionally revised

Current System 02 makes every movement action COMMITTED. If System 17 is approved, that statement is superseded for ordinary walk steps only.

Approved implementation would revise the movement interruption split to:

- `movement.step_forward` — **CANCELABLE** by damage interruption;
- `movement.step_backward` — **CANCELABLE** by damage interruption;
- `movement.run_forward` — **COMMITTED**;
- `movement.turn_left` — **COMMITTED**;
- `movement.turn_right` — **COMMITTED**.

System 03 already reserved `movement.run_forward` as a future capability action and already blocks it while crouched. System 17 activates that seam rather than adding persistent `run` locomotion state.

## 3. Non-goals

System 17 does **not** add:

- persistent walk/run mode;
- running backward;
- diagonal sprinting;
- strafing;
- stamina as a new state domain;
- automatic fatigue accumulation;
- sound/noise propagation;
- zombie attraction;
- combat attacks;
- knockback/dodge/interruption reactions;
- vaulting over obstacles;
- movement animation ownership;
- pathfinding/AI running policy;
- new terrain categories;
- camera behavior.

Existing Needs/Fatigue and Carry modifiers may affect run duration through System 03’s current mobility-provider seam. No new fake fatigue or sound consequence is invented merely to justify running.

## 4. Historical tuning recovered

Golden `PlayerActor.gd` blob `2f839f1a50041c8bd00e144c1a9389d0a33d1401` used:

- Walk = 10 ticks;
- Run = 6 ticks;
- Crouch walk = 14 ticks;
- Turn = 3 ticks;
- Stance = 4 ticks.

The golden implementation used a persistent run-mode flag, which the canonical architecture intentionally rejected. System 17 recovers the useful **6-tick run tuning** but expresses running as one explicit semantic action.

## 5. Run action contract

New semantic movement action:

- `movement.run_forward`

Public Movement API addition:

- `request_run_forward(actor_id)`

V1 run behavior:

- standing only;
- exactly straight ahead along current facing;
- covers **two tactical cells** in one action;
- healthy/unencumbered demo baseline = **6 total ticks**;
- existing System 03 duration modifiers still apply to that base duration;
- uses WHEN `COMMITTED` interruption policy;
- ordinary damage interruption requests do not cancel it;
- no destination reservation.

The 6-tick baseline is balance policy, not a WHEN constant.

## 6. Two-cell physical execution

Run is represented as two rapid physical strides under one committed action rather than teleporting two cells only at the end.

For total resolved duration `D`:

- first stride phase due at `ceil(D / 2)`;
- second/final stride phase due at `D`.

For the unmodified 6-tick baseline:

- tick +3: attempt first cell;
- tick +6: attempt second cell.

This preserves causal physical position while other actors/events may act during the sprint.

### First stride

At the first stride phase:

- expected original placement must still match;
- the intermediate cell/footprint is revalidated through Collision and traversal policy;
- if valid, WHAT placement advances one cell without changing facing.

### Second stride

At the final stride phase:

- expected intermediate placement must still match;
- final cell/footprint is revalidated;
- if valid, WHAT placement advances the second cell.

If the final cell becomes blocked after the first stride, the actor remains at the intermediate cell after the committed exposure already spent.

If the first stride becomes impossible before its phase, the run fails at that phase and the actor remains at the original cell. COMMITTED means damage cannot voluntarily cancel the sprint; it does not force an actor through newly impossible geometry.

## 7. Request-time path validation

A run request validates **both** crossed cells before spending time.

For each stride:

- full actor footprint at that anchor/facing must be Collision CLEAR;
- required terrain must exist;
- terrain must be traversable;
- actor capability must allow `movement.run_forward`.

If either cell is BLOCKED/UNKNOWN/untraversable, the request is rejected with zero ticks spent.

This prevents a two-cell action from passing through a wall, closed hard blocker, or unknown/unmaterialized space simply because the final square is clear.

## 8. Run timing policy

System 02’s terrain policy continues to own base traversal timing.

V1 run timing uses the recovered relationship between the current 10-tick walk and 6-tick run:

- run scale = **60% of the slowest relevant walk terrain cost** across the two-stride path;
- deterministic integer ceiling keeps duration positive;
- demo road/grass currently using 10-tick walking therefore resolve to the recovered **6-tick base run**.

Then System 03 applies stance/provider mobility modifiers to the run action exactly as it already does for other movement actions.

Examples before external modifiers:

- walk terrain 10 -> run base 6;
- hypothetical walk terrain 14 -> run base 9.

This keeps terrain timing ownership in Movement policy and avoids requiring every terrain entry to duplicate a separate manually registered run cost.

## 9. Stance / capability

System 03 remains the actor mobility owner.

Existing reserved behavior becomes active:

- standing may evaluate `movement.run_forward`;
- crouched returns CAPABILITY_BLOCKED;
- missing locomotion/capability remains fail-closed;
- Needs/Fatigue and Carry providers continue to contribute through their existing generic action-type contract;
- newly slower-but-still-allowed capability does not stretch a run action already scheduled; it affects the next request, matching existing Movement semantics.

No persistent `is_running` state is added.

## 10. Damage-interruptible walking

### Why a separate coordinator

MovementActionService must not import Health. Health must not learn movement rules.

System 17 therefore adds a narrow coordination owner:

`MovementDamageInterruptionService.gd`

Dependencies:

- Actor Health public damage signal;
- WHEN `TickKernel` active-action/interrupt API;
- Movement action vocabulary only.

It stores no persistent state.

### Health semantic damage signal

13A currently exposes `apply_damage()` but only emits generic HP-change facts. To distinguish actual damage from healing or max-HP bookkeeping, System 17 proposes one additive Health observation signal:

`damage_applied(actor_id, amount, previous_hp, current_hp, version)`

Rules:

- emitted only after successful `apply_damage()` with a real HP decrease;
- healing does not emit it;
- direct max-HP clamping does not emit it;
- it adds no new Health state and changes no Health calculation.

Future combat/environmental damage should use the existing `apply_damage()` path when it intends to produce canonical HP damage.

### Interruption behavior

When `damage_applied` fires:

1. coordinator asks WHEN for the actor’s active action;
2. if it is a Movement action, coordinator calls `interrupt_action(action_serial, "damage")`;
3. WHEN applies that action’s interruption policy.

Result:

- walk step CANCELABLE -> action becomes canceled immediately, remaining movement phase is removed, elapsed ticks stay spent, WHAT placement remains at its pre-walk cell;
- run COMMITTED -> interruption request is ignored by WHEN and the sprint continues;
- turn COMMITTED -> interruption request is ignored and turn continues.

The coordinator does not mutate WHAT, Health, Locomotion or Movement state.

## 11. Same-tick ordering

Damage and movement phases use existing deterministic WHEN event ordering.

If damage is resolved before a walk commit at the same world tick, the damage signal cancels the walk before its movement phase can commit.

If the walk commit already resolved first at that tick, later damage does not retroactively undo the movement.

No special hidden priority is introduced solely for System 17.

## 12. No reservation / races

Run reserves neither intermediate nor final cell.

A cell may become occupied after request validation.

Each stride revalidates at its own phase:

- first stride can fail against a new blocker;
- second stride can fail after first stride succeeded;
- concurrent actor ordering remains deterministic through WHEN + Collision revalidation.

No rollback moves the actor back from a legitimately committed first stride merely because the second stride later fails.

## 13. Input contract

System 17 adds semantic player intent:

- `RUN_FORWARD`

Desktop:

- `Shift+W` or `Shift+Up` -> one run-forward intent;
- plain W/Up remains one walk-forward intent.

Touch/Safari:

- one native Godot `RUN` button;
- placed in the currently unused bottom-right control slot beneath `TURN R`;
- one physical press emits one semantic `RUN_FORWARD` intent;
- no hold-mode or toggle state required.

Modal input blocking from System 16 remains unchanged.

## 14. Player controller integration

`DemoPlayerActionController` may route `RUN_FORWARD` to `MovementActionService.request_run_forward()` exactly as it already routes walk/turn intents.

It does not calculate run distance, timing, interruption policy, collision, damage semantics or stance legality.

The controller still runs accepted actions through WHEN to the next stop and reports the semantic result to the existing HUD.

## 15. Expected implementation surface after approval

Production changes expected:

- `game/scripts/simulation/movement/MovementActionService.gd`
- `game/scripts/simulation/movement/MovementTraversalPolicy.gd`
- likely small typed result/policy helpers only if needed by path diagnostics
- new `game/scripts/simulation/movement/MovementDamageInterruptionService.gd`
- additive `damage_applied` signal in `game/scripts/simulation/actors/health/ActorHealthState.gd`
- bounded System 03 capability/document revision activating reserved run seam
- `game/scripts/input/PlayerActionIntent.gd`
- `game/scripts/input/KeyboardInputAdapter.gd`
- `game/scripts/ui/DemoMovementControls.gd`
- `game/scripts/player/DemoPlayerActionController.gd`
- composition-only wiring in `CanonicalDemoMain.gd`
- dedicated System 17 smoke/workflow plus protected regressions
- docs/ledger/context/changelog.

## 16. Modules that must remain behaviorally untouched

System 17 must not redesign:

- WHERE or WHAT foundations;
- Collision classification rules;
- WHEN internals/policies;
- persistent locomotion stance representation;
- Needs, Carry or Skills semantics;
- Inventory/Hands/Item Transfer;
- renderer/art stack;
- HUD/Stats/Inventory/Menu truth;
- demo map content;
- generation/streaming;
- Reboot.

13A Health receives only the additive damage observation signal described above; its HP/injury truth remains unchanged.

## 17. Acceptance tests

Dedicated System 17 verification should prove:

1. existing Movement/Locomotion/Health/System14–16 regressions remain green;
2. plain forward walk remains one-cell movement at 10 demo ticks;
3. forward/back walk actions use CANCELABLE timing policy;
4. real `apply_damage()` during an in-progress walk cancels it before commit;
5. canceled walk keeps elapsed ticks spent and leaves WHAT placement unchanged;
6. healing does not interrupt walking;
7. max-HP bookkeeping does not masquerade as damage interruption;
8. run request is rejected when crouched;
9. run request validates both intermediate and final cells before spending time;
10. standing healthy/unencumbered run on current 10-tick terrain resolves to 6 total ticks;
11. first run stride reaches cell +1 at tick 3;
12. second run stride reaches cell +2 at tick 6;
13. damage between run strides does not cancel the COMMITTED run;
14. a blocker appearing in the final cell after stride one leaves the actor at the intermediate cell;
15. a blocker appearing before stride one prevents that stride and fails safely;
16. Needs/Carry duration modifiers still affect run through System 03’s provider seam;
17. Shift+W/Shift+Up emits one semantic RUN_FORWARD; plain W/Up remains walk;
18. touch RUN emits one semantic RUN_FORWARD and remains blocked under System 16 modals;
19. no persistent run-mode state exists;
20. no Health dependency enters MovementActionService;
21. no sound/stamina/fatigue-progression placeholder is introduced;
22. exact-final-SHA Godot parse/startup, System 17 CI, Web export and Pages deploy succeed.

## 18. Future seams

Later systems may extend running without changing its core ownership:

- Needs may add real fatigue accumulation from completed/partial run strides;
- sound may emit louder spatial noise per run stride;
- injuries/equipment/skills may block or alter run through System 03 providers;
- AI may request the same semantic run action;
- slippery terrain/tripping can later become an explicit consequence rather than hidden randomness;
- animation may visualize the two stride phases without owning physical movement.

None of those are required to make the current run-vs-walk commitment choice real.

## 19. North-star fit

This preserves **Ultima-style turn-based mini Zomboid** by making sprinting a simple but consequential tactical choice:

- walking is slower and cautious enough to be interrupted by damage;
- running crosses ground dramatically faster but commits the survivor to momentum;
- the world remains grid-based and deterministic;
- damage, movement, capability and time remain separate owners connected through narrow public contracts.

The design adds consequence, not simulation clutter.

## 20. Draft decisions requiring explicit approval

1. Run is one explicit `movement.run_forward` action, never persistent run mode.
2. Run moves two straight cells through two physical stride phases.
3. Healthy standing baseline is the recovered **6 ticks total**: stride one at tick 3, stride two at tick 6.
4. Run timing derives as 60% of the slowest relevant walk-terrain cost before actor mobility modifiers.
5. Crouched running remains blocked through existing System 03 capability.
6. Forward/back walking changes from COMMITTED to **CANCELABLE**; turns stay COMMITTED.
7. Existing `apply_damage()` gains an additive semantic `damage_applied` signal; a separate coordinator asks WHEN to interrupt current Movement work.
8. Damage cancels walk but does not cancel committed run/turn.
9. Run performs request-time and per-stride collision/terrain revalidation with no reservation.
10. If stride one succeeds but stride two later fails, the actor remains on the intermediate cell.
11. Desktop Run is Shift+W / Shift+Up; touch Run uses the empty bottom-right slot beneath Turn R.
