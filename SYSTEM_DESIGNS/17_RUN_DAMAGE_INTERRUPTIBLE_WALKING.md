# 17 Run / Damage-Interruptible Walking

Status: **DRAFT — discussion only; do not implement until explicitly approved**

Drafted from the user direction on 2026-08-16 and revised after clarification:

> “Lets add a run mechanic. More movement less tics, its a committed action vs walk which can be interrupted by dmg. Run has a move of two squares.”
>
> “Fewer tics per square, but more tics over all move. higher fatigue drain, fatigue min requires to run”

## 1. Goal

Add a physically distinct forward sprint action that trades precision and endurance for faster displacement per square, while revising ordinary walking so real damage can interrupt it.

Core player-facing distinction:

- **Walk:** one cell, 10-tick healthy baseline, damage-interruptible.
- **Run:** two cells forward, **6 ticks per square / 12 ticks total** on current demo terrain, fatigue-gated, extra fatigue cost, COMMITTED once started.

Run therefore costs **more total time than one walk action** (12 > 10), but crosses ground substantially faster than walking the same two-cell distance (12 < 20).

No persistent run-mode flag or separate stamina bar is introduced.

## 2. Existing contracts intentionally revised

Current System 02 makes every movement action COMMITTED. If System 17 is approved, that statement is superseded for ordinary walk steps only.

Approved implementation would revise the interruption split to:

- `movement.step_forward` — **CANCELABLE** by damage interruption;
- `movement.step_backward` — **CANCELABLE** by damage interruption;
- `movement.run_forward` — **COMMITTED**;
- `movement.turn_left` — **COMMITTED**;
- `movement.turn_right` — **COMMITTED**.

System 03 already reserves `movement.run_forward` as a capability action and already blocks it while crouched. System 17 activates that seam rather than adding persistent `run` locomotion state.

## 3. Non-goals

System 17 does **not** add:

- persistent walk/run mode;
- running backward;
- diagonal sprinting;
- strafing;
- a separate stamina state/domain;
- general hunger/thirst/sleep progression;
- general walking fatigue progression;
- fatigue recovery/rest actions;
- sound/noise propagation;
- zombie attraction;
- combat attacks;
- knockback/dodge/reaction mechanics;
- vaulting over obstacles;
- movement animation ownership;
- pathfinding/AI run policy;
- new terrain categories;
- camera behavior.

System 17 adds only the **acute extra fatigue cost of successful run strides** plus the fatigue threshold required to begin a run. Broader Needs progression/rest remains a later 13B consumer of WHEN/calendar policy.

## 4. Historical tuning recovered

Golden `PlayerActor.gd` blob `2f839f1a50041c8bd00e144c1a9389d0a33d1401` used:

- Walk = 10 ticks;
- Run = 6 ticks;
- Crouch walk = 14 ticks;
- Turn = 3 ticks;
- Stance = 4 ticks.

The golden implementation used a persistent run-mode flag, which the canonical architecture rejected.

System 17 recovers the useful **6-tick run pace as a per-square sprint pace**, while the new canonical Run action covers two cells. Therefore the healthy current-terrain baseline is **12 ticks total**, not 6 total.

## 5. Run action contract

New semantic movement action:

- `movement.run_forward`

Public Movement API addition:

- `request_run_forward(actor_id)`

V1 run behavior:

- standing only;
- exactly straight ahead along current facing;
- covers **two tactical cells** in one action;
- current 10-tick walk terrain resolves to **6 ticks per run stride / 12 ticks total** before actor modifiers;
- existing System 03 Needs/Carry duration modifiers still apply at action start;
- uses WHEN `COMMITTED` interruption policy;
- ordinary damage interruption requests do not cancel it;
- no destination reservation;
- requires fatigue below the Run cutoff at request time;
- successful run movement adds acute fatigue.

## 6. Two-cell physical execution

Run is two physical strides under one committed action, not a two-cell teleport at the final tick.

Each stride gets its own base traversal duration from the terrain it enters.

On the current 10-tick walk terrain:

- tick +6: attempt/commit stride 1 into cell +1;
- tick +12: attempt/commit stride 2 into cell +2.

For mixed terrain, each stride may have a different base cost. The final action duration is the sum of the two resolved stride durations captured when the Run starts.

### First stride

At stride 1:

- expected original placement must still match;
- target footprint must still be Collision CLEAR;
- current terrain semantic truth for the stride must still match the validated request-time terrain truth;
- if valid, WHAT advances one cell without changing facing;
- the run-exertion coordinator applies the stride’s fatigue cost after successful physical movement.

### Second stride

At stride 2:

- expected intermediate placement must still match;
- target footprint must still be Collision CLEAR;
- current terrain semantic truth for the stride must still match the validated request-time terrain truth;
- if valid, WHAT advances the second cell;
- the run-exertion coordinator applies the second stride’s fatigue cost.

If stride 2 becomes blocked after stride 1 succeeds, the actor remains at the intermediate cell. No rollback occurs.

If stride 1 becomes impossible before its phase, the actor remains at origin.

COMMITTED means the actor does not voluntarily stop because of damage or because their fatigue crosses the run-start threshold after the sprint has already begun. It never means moving through impossible geometry.

## 7. Request-time path validation

A run request validates **both** crossed cells before spending time.

For each stride:

- full actor footprint at that anchor/facing must be Collision CLEAR;
- required terrain must exist;
- terrain must be traversable;
- actor capability must allow `movement.run_forward`;
- fatigue start requirement must be satisfied.

If either cell is BLOCKED/UNKNOWN/untraversable or actor capability/Run eligibility rejects the action, the request consumes zero ticks.

The request stores the validated terrain semantics and expected placements in WHEN-safe payload data so each committed stride can verify that the physical path has not changed underneath the actor.

## 8. Run timing policy

System 02 terrain policy continues to own base traversal timing.

For each run stride independently:

- base run-stride cost = **60% of that stride’s normal walk-terrain cost**;
- use deterministic integer ceiling;
- System 03 then applies actor mobility duration modifiers using the actor state at Run start.

Examples before actor modifiers:

- walk cost 10 -> run stride 6;
- two 10-cost cells -> Run total 12;
- hypothetical 14-cost terrain -> run stride 9;
- 10-cost then 14-cost cells -> Run total 15.

This is the intended relationship:

- fewer ticks **per square** than walking;
- more ticks **for the whole two-square action** than one walk step;
- fewer ticks than walking those same two squares as two separate actions.

The scheduled stride times are fixed when the committed Run begins. Later fatigue/carry changes do not stretch an already-started Run.

## 9. Fatigue requirement to start Run

13B Fatigue is a **pressure scale**:

- 0 = fresh;
- 100 = severe fatigue/exhaustion.

So the user concept “minimum fatigue required to run” is represented canonically as a **maximum fatigue pressure allowed to start**.

V1 proposed cutoff:

- fatigue **0..79** -> Run may start if all other capability checks pass;
- fatigue **80..100** -> Run is CAPABILITY_BLOCKED with reason `too_exhausted_to_run`.

This deliberately aligns with the existing 13F **Exhausted** moodlet threshold at fatigue 80.

A Run that starts at fatigue 79 remains COMMITTED even when its first successful stride raises fatigue to 80+. The start requirement is not reinterpreted as a mid-sprint cancel condition.

Crouched stance remains separately blocking regardless of fatigue.

## 10. Acute Run fatigue cost

Running should have a real endurance consequence now rather than waiting for a future stamina placeholder.

V1 proposed tuning:

- successful run stride: **+1 fatigue**;
- full two-cell Run: **+2 fatigue total**;
- failed stride that causes no physical movement adds no stride fatigue;
- ordinary walk/turn/stance actions receive **no new acute fatigue surcharge in System 17**.

This makes Run explicitly more fatiguing than Walk in this slice while keeping the coarse 0..100 Needs scale usable. General long-distance walking/time-awake fatigue accumulation and fatigue recovery remain future Needs-progression/rest behavior rather than being guessed here.

### Ownership

Movement must not import Needs, and Needs must not learn Movement internals.

System 17 therefore adds a narrow stateless coordinator:

`MovementRunExertionService.gd`

It observes successful Run stride facts and calls the existing public `ActorNeedsState.change_need(actor_id, FATIGUE, +1)` mutation API.

It owns no persistent fatigue state and does not calculate movement timing.

## 11. Committed capability semantics

System 03 remains the actor mobility owner.

At Run request:

- standing/crouched capability is evaluated;
- current Needs/Carry providers contribute duration/capability;
- fatigue 80+ blocks Run start;
- missing capability truth fails closed.

Once accepted, **actor capability is latched for that committed Run**. Individual stride phases revalidate physical placement/collision/terrain truth, but do not cancel the Run solely because actor condition changed after commitment.

This is intentional:

- damage does not interrupt Run;
- Run-generated fatigue crossing 80 does not interrupt Run;
- newly worse fatigue/carry affects the **next** action.

Future mechanics that truly force physical interruption/knockdown can add an explicit forced-failure path rather than quietly turning COMMITTED back into CANCELABLE.

No persistent `is_running` state is added.

## 12. Damage-interruptible walking

### Why a separate coordinator

MovementActionService must not import Health. Health must not learn movement rules.

System 17 adds:

`MovementDamageInterruptionService.gd`

Dependencies:

- Actor Health public damage signal;
- WHEN `TickKernel` active-action/interrupt API;
- Movement action vocabulary only.

It stores no persistent state.

### Health semantic damage signal

13A currently exposes `apply_damage()` but only generic HP-change observation. System 17 proposes one additive Health signal:

`damage_applied(actor_id, amount, previous_hp, current_hp, version)`

Rules:

- emitted only after successful `apply_damage()` with a real HP decrease;
- healing does not emit it;
- max-HP clamping does not emit it;
- no Health calculation or state shape changes.

### Interruption behavior

When `damage_applied` fires:

1. coordinator asks WHEN for the actor’s active action;
2. if it is a Movement action, coordinator calls `interrupt_action(action_serial, "damage")`;
3. WHEN applies that action’s interruption policy.

Result:

- Walk CANCELABLE -> canceled immediately; elapsed ticks remain spent; no walk placement commit occurs.
- Run COMMITTED -> damage interruption request is ignored and Run continues.
- Turn COMMITTED -> interruption request is ignored and turn continues.

## 13. Same-tick ordering

Damage and movement phases use existing deterministic WHEN ordering.

If damage resolves before a walk commit at the same tick, it cancels the walk before movement commits.

If the walk already committed first at that tick, later damage does not retroactively undo it.

No hidden System-17-only scheduler priority is introduced.

## 14. No reservation / races

Run reserves neither intermediate nor final cell.

Each stride revalidates current physical truth:

- stride 1 can fail against a new blocker;
- stride 2 can fail after stride 1 succeeds;
- concurrent actor ordering remains deterministic through WHEN + Collision revalidation.

No rollback moves an actor back from a valid first stride merely because the second later fails.

## 15. Input contract

System 17 adds semantic intent:

- `RUN_FORWARD`

Desktop:

- `Shift+W` or `Shift+Up` -> one Run intent;
- plain W/Up -> ordinary walk.

Touch/Safari:

- native `RUN` button in the unused bottom-right slot beneath `TURN R`;
- one physical press -> one `RUN_FORWARD` intent;
- no hold mode or run toggle.

System 16 modal input blocking remains unchanged.

## 16. Player controller integration

`DemoPlayerActionController` routes `RUN_FORWARD` to `MovementActionService.request_run_forward()` just as it routes other movement intents.

It does not calculate distance, timing, fatigue, collision, damage interruption, or stance legality.

## 17. Expected implementation surface after approval

Production changes expected:

- `game/scripts/simulation/movement/MovementActionService.gd`
- `game/scripts/simulation/movement/MovementTraversalPolicy.gd`
- likely small typed result/policy helpers if required by two-stride diagnostics
- new `game/scripts/simulation/movement/MovementDamageInterruptionService.gd`
- new `game/scripts/simulation/movement/MovementRunExertionService.gd`
- additive `damage_applied` signal in `game/scripts/simulation/actors/health/ActorHealthState.gd`
- bounded System 03 capability revision activating the reserved Run seam and fatigue-start block
- bounded System 13B provider/document revision for Run-start fatigue eligibility; persistent Needs state/API remains unchanged
- `game/scripts/input/PlayerActionIntent.gd`
- `game/scripts/input/KeyboardInputAdapter.gd`
- `game/scripts/ui/DemoMovementControls.gd`
- `game/scripts/player/DemoPlayerActionController.gd`
- composition-only wiring in `CanonicalDemoMain.gd`
- dedicated System 17 smoke/workflow plus protected regressions
- docs/ledger/context/changelog.

## 18. Modules that remain behaviorally untouched

System 17 must not redesign:

- WHERE or WHAT foundations;
- Collision classification;
- WHEN internals/policies;
- persistent locomotion stance representation;
- Health HP/injury calculations;
- Needs persistent record shape or 0..100 semantics;
- Carry or Skills semantics;
- Inventory/Hands/Item Transfer;
- renderer/art stack;
- HUD/Stats/Inventory/Menu truth;
- demo map content;
- generation/streaming;
- Reboot.

13A receives only an additive damage-observation signal. 13B receives only a narrow Run capability rule through its existing mobility seam; acute Run fatigue is coordinated through the existing public Needs mutation API.

## 19. Acceptance tests

Dedicated System 17 verification should prove:

1. existing Movement/Locomotion/Health/Needs/System14–16 regressions remain green;
2. plain forward walk remains one-cell movement at 10 healthy demo ticks;
3. forward/back walk actions use CANCELABLE timing policy;
4. real `apply_damage()` during an in-progress walk cancels it before commit;
5. canceled walk keeps elapsed ticks spent and leaves WHAT placement unchanged;
6. healing/max-HP bookkeeping does not masquerade as damage interruption;
7. Run is rejected while crouched;
8. fatigue 79 permits Run start; fatigue 80 blocks Run start with explicit reason;
9. Run request validates both intermediate and final cells before spending time;
10. two current 10-tick walk cells resolve to **12 total Run ticks**;
11. stride 1 reaches cell +1 at tick 6;
12. stride 2 reaches cell +2 at tick 12;
13. Run is still faster over two cells than two 10-tick walks;
14. damage between Run strides does not cancel the COMMITTED Run;
15. fatigue crossing 80 after stride 1 does not cancel stride 2;
16. successful stride 1 adds +1 fatigue and successful stride 2 adds another +1;
17. a blocked/failed stride that produces no movement adds no stride fatigue;
18. blocker appearing in final cell after stride 1 leaves actor at intermediate cell;
19. blocker appearing before stride 1 prevents that stride and fails safely;
20. Needs/Carry duration modifiers still affect Run scheduling from start-state truth;
21. Shift+W/Shift+Up emits one RUN_FORWARD; plain W/Up remains walk;
22. touch RUN emits one RUN_FORWARD and remains blocked under System 16 modals;
23. no persistent run-mode or stamina state exists;
24. no Health or Needs dependency enters MovementActionService;
25. exact-final-SHA Godot parse/startup, System 17 CI, Web export and Pages deploy succeed.

## 20. Future seams

Later systems may extend running without changing its core ownership:

- broader Needs progression/rest can add walking fatigue, recovery, sleep interactions and calendar-aware exertion;
- sound can emit louder spatial noise per Run stride;
- injuries/equipment/skills may alter whether a Run may **start** through capability providers;
- AI may request the same semantic Run action;
- explicit knockdown/trip/forced-failure mechanics may later terminate a committed Run through a dedicated physical-interruption contract;
- animation may visualize stride phases without owning movement.

## 21. North-star fit

This preserves **Ultima-style turn-based mini Zomboid** by making sprinting a simple but consequential tactical choice:

- walking is slower and cautious enough to be interrupted by damage;
- running uses fewer ticks per square, but the two-square commitment costs more total ticks than one walk action;
- running has an immediate endurance cost and cannot be started while Exhausted;
- the world remains grid-based and deterministic;
- Health, Needs, Movement, capability and WHEN remain separate owners connected through narrow public contracts.

The design adds consequence rather than a second stamina simulation.

## 22. Draft decisions requiring explicit approval

1. Run is one explicit `movement.run_forward` action, never persistent run mode.
2. Run moves two straight cells through two physical stride phases.
3. Healthy current-terrain pace is **6 ticks per square / 12 ticks total**: stride 1 at tick 6, stride 2 at tick 12.
4. Each stride derives as 60% of that stride’s normal walk terrain cost before actor modifiers; total Run duration is the sum of the two resolved strides.
5. Crouched running remains blocked.
6. Run may start only below fatigue 80; 80+ (`Exhausted`) blocks Run.
7. Each successful Run stride adds **+1 fatigue**; full Run therefore adds +2.
8. Run-start capability is latched for the committed action; self-generated fatigue crossing 80 does not cancel the second stride.
9. Forward/back walking changes from COMMITTED to CANCELABLE; turns stay COMMITTED.
10. `apply_damage()` gains additive `damage_applied`; a separate coordinator asks WHEN to interrupt current Movement work.
11. Damage cancels walk but does not cancel committed Run/turn.
12. Run performs request-time and per-stride physical collision/terrain revalidation with no reservation.
13. If stride 1 succeeds but stride 2 later fails, actor remains on intermediate cell.
14. Desktop Run is Shift+W / Shift+Up; touch Run uses the empty bottom-right slot beneath Turn R.
