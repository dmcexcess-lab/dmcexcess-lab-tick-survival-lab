# 17 Run / Damage-Interruptible Walking

Status: **IMPLEMENTED + CI — canonical source and live demo integration 2026-08-16**

Approval basis: user first requested a committed two-square Run versus damage-interruptible walking, then clarified **fewer ticks per square but more ticks for the whole Run, higher fatigue drain, and a fatigue requirement**, and finally authorized implementation with **“17 is go for approval.”**

## 1. Goal

Make movement choice tactically consequential without a persistent Run-mode flag or separate stamina simulation.

Player-facing distinction:

- **Walk:** one cell; healthy demo baseline 10 ticks; damage-interruptible.
- **Run:** two straight forward cells; healthy demo baseline 6 ticks per square / 12 total; extra fatigue; must start below fatigue 80; COMMITTED once begun.

Thus Run costs more total time than one Walk (12 > 10), but moves faster per square and crosses two cells faster than two Walks (12 < 20).

## 2. Movement action contract

Canonical Movement vocabulary after System 17:

- `movement.step_forward` — 1 cell, WHEN CANCELABLE.
- `movement.step_backward` — 1 cell preserving facing, WHEN CANCELABLE.
- `movement.run_forward` — 2 forward cells through two physical stride phases, WHEN COMMITTED.
- `movement.turn_left` — 90-degree in-place turn, WHEN COMMITTED.
- `movement.turn_right` — 90-degree in-place turn, WHEN COMMITTED.

Run is an explicit semantic action. There is no persistent `is_running`, run mode, running backward, diagonal sprint, or strafe.

## 3. Run timing

`MovementTraversalPolicy` derives each Run stride from the terrain it enters:

`run_stride_ticks = ceil(walk_terrain_ticks * 0.60)`

Then `ActorMovementTraversalPolicy` applies start-time actor capability/provider modifiers.

Examples before actor modifiers:

- walk terrain 10 -> Run stride 6;
- two 10-cost cells -> 12 total;
- walk terrain 14 -> Run stride 9;
- 10-cost then 14-cost -> 6 + 9 = 15 total.

Current demo healthy/empty baseline is therefore:

- stride 1 at tick +6;
- stride 2 at tick +12.

The stride schedule is fixed when the committed Run begins. Later fatigue/carry changes affect the next action, not the already-started sprint.

## 4. Two-stride physical execution

A Run is one WHEN action with phases:

- `movement.run_stride_1`
- `movement.run_stride_2`

Request time validates both crossed cells before spending time:

- full actor footprint Collision CLEAR;
- terrain exists and is traversable;
- actor capability permits Run;
- fatigue start requirement passes.

No cell is reserved.

At each stride phase Movement revalidates:

- expected origin/intermediate placement;
- Collision CLEAR at that stride's target;
- request-time terrain semantic truth still matches.

A successful stride advances WHAT exactly one cell and emits `run_stride_committed`.

Run capability itself is **latched at action start**; it is not re-evaluated between strides. This is deliberate committed-action behavior.

If stride 1 succeeds and stride 2 later becomes physically impossible, the actor remains on the intermediate cell. No rollback occurs. COMMITTED never means moving through a wall or stale geometry.

## 5. Fatigue eligibility and exertion

13B fatigue remains the canonical 0..100 pressure scale:

- 0 = fresh;
- 100 = severe fatigue.

Run-start rule through `ActorNeedsMobilityModifierProvider`:

- fatigue 0..79 -> may Run if all other capability checks pass;
- fatigue 80..100 -> CAPABILITY_BLOCKED, reason `too_exhausted_to_run`.

This matches the existing 13F **Exhausted** moodlet threshold at 80.

Acute Run exertion:

- successful stride -> +1 fatigue;
- full Run -> +2 fatigue;
- failed stride that produces no movement -> no fatigue charge.

`MovementRunExertionService` is a stateless coordinator. It observes `run_stride_committed` and calls the existing public Needs `change_need(... FATIGUE, +1)` API. MovementActionService has no Needs dependency.

A Run started at fatigue 79 remains committed: stride 1 may raise fatigue to 80, stride 2 still occurs if physically legal, ending at 81. The next Run is then rejected.

No general walking-fatigue progression, fatigue recovery, or separate stamina state is introduced by System 17.

## 6. Damage-interruptible Walk

System 17 revises forward/back Walk from COMMITTED to WHEN `CANCELABLE`.

13A Health adds the additive semantic signal:

`damage_applied(actor_id, amount, previous_hp, current_hp, version)`

It emits only for real HP loss through `apply_damage()`. Healing and max-HP bookkeeping do not emit it.

`MovementDamageInterruptionService` is a stateless coordinator that:

1. observes `damage_applied`;
2. reads the actor's current WHEN action;
3. if it is a Movement action, requests `interrupt_action(serial, "damage")`;
4. lets WHEN enforce the action's policy.

Result:

- Walk CANCELABLE -> canceled; elapsed ticks remain spent; placement does not commit.
- Run COMMITTED -> interruption ignored; sprint continues if physical path remains legal.
- Turn COMMITTED -> interruption ignored.

Health does not import Movement and MovementActionService does not import Health.

## 7. Stance / actor capability

03 remains the actor capability owner.

- standing recognizes Run;
- crouched Run is CAPABILITY_BLOCKED;
- missing capability fails closed;
- Needs and Carry providers contribute start-time timing/capability through the existing provider seam.

The canonical demo now registers both the already-implemented Needs and Carry mobility providers with `ActorMovementCapabilityService`.

No persistent Run stance/mode was added.

## 8. Input / demo integration

Semantic intent:

- `RUN_FORWARD`

Desktop:

- Shift+W or Shift+Up -> Run;
- W/Up -> Walk.

Touch/Safari:

- native Godot `RUN` button in the lower-right slot beneath Turn R;
- one press -> one Run intent;
- System 16 modal blocking disables it with the rest of gameplay input.

`DemoPlayerActionController` only routes semantic Run intent to `request_run_forward`; it does not calculate distance, timing, collision, fatigue, or interruption.

## 9. Owners / implementation surface

Production owners changed or added:

- `game/scripts/simulation/movement/MovementActionService.gd`
- `game/scripts/simulation/movement/MovementTraversalPolicy.gd`
- `game/scripts/simulation/movement/MovementDamageInterruptionService.gd`
- `game/scripts/simulation/movement/MovementRunExertionService.gd`
- `game/scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd`
- `game/scripts/simulation/actors/health/ActorHealthState.gd` — additive damage signal only
- `game/scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd` — Run-start fatigue block
- semantic input/controller/demo composition wiring.

Verification:

- `game/scripts/ci/RunDamageWalkingSmoke.gd`
- `.github/workflows/run-damage-walking.yml`
- protected Movement/Locomotion/Health/Needs/Carry/System14–16 regressions.

## 10. Boundaries / non-goals

System 17 does not redesign:

- WHERE / WHAT / Collision / WHEN internals;
- persistent stance representation;
- Health HP/injury calculation;
- Needs persistent record shape;
- Carry/Skills truth;
- Inventory/Hands/Item Transfer;
- renderer/art/HUD/inspectors/menu;
- demo map content;
- generation/streaming;
- Reboot.

It does not implement sound/noise, zombie attraction, combat attacks, knockdown/tripping, AI Run policy, vaulting, animation ownership, or camera behavior.

## 11. Verified acceptance criteria

Dedicated Godot 4.7.1 System 17 CI proves:

- normal one-cell Walk remains 10 ticks on demo terrain;
- forward/back Walk are CANCELABLE;
- real `apply_damage()` during Walk cancels before placement commit and preserves elapsed ticks;
- healing/max-HP changes do not masquerade as damage;
- crouched Run rejected;
- fatigue 79 permits Run start and fatigue 80+ rejects explicitly;
- two 10-cost cells resolve to 12 Run ticks;
- stride 1 physically commits at tick 6 and stride 2 at tick 12;
- full Run adds +2 fatigue;
- Run started at 79 completes to 81 and only the next Run is blocked;
- damage between strides does not cancel Run;
- mixed 10/14 terrain resolves to 15 Run ticks;
- blocker appearing after stride 1 leaves actor on intermediate cell;
- failed second stride charges only the first stride's fatigue;
- no persistent Run mode/stamina exists;
- MovementActionService has no Health/Needs implementation dependency;
- Movement, Locomotion, Health, Needs, Carry, Systems 14–16, startup and Web deployment regressions remain protected.

Initial implementation candidate `33580c2e9016c15591005536707b2729e580876e` passed dedicated System 17 run `31998617639` with no production repair.

## 12. Future seams

Later systems may add without changing System 17 ownership:

- louder spatial sound/noise per Run stride;
- injury/equipment/skill Run-start modifiers through capability providers;
- AI requesting the same semantic Run action;
- explicit forced knockdown/trip failure separate from ordinary damage interruption;
- broader Needs progression/recovery;
- animation observing the physical stride phases.

## 13. Approved decisions — 2026-08-16

1. Run is explicit action, never persistent mode.
2. Run moves two forward cells through two physical phases.
3. Healthy demo pace is 6 ticks/square / 12 total.
4. Each stride is 60% of its walk terrain cost before actor modifiers.
5. Crouched Run is blocked.
6. Fatigue 80+ blocks Run start.
7. Each successful Run stride adds +1 fatigue.
8. Start capability is latched; crossing fatigue 80 mid-Run does not cancel stride two.
9. Walk forward/back are CANCELABLE; turns remain COMMITTED.
10. Real Health damage interrupts Walk through a stateless coordinator.
11. Damage does not cancel committed Run/Turn.
12. Both Run cells validate at request and each stride revalidates physical truth without reservations.
13. A valid first stride is never rolled back because the second later fails.
14. Desktop Run is Shift+W/Shift+Up; touch Run uses the bottom-right control slot.

## 14. North-star fit

System 17 adds a simple but consequential movement choice for **Ultima-style turn-based mini Zomboid**: Walk is cautious and interruptible; Run is faster per square, physically committed over two cells, and consumes real endurance, while Health, Needs, Movement, capability, time, and presentation remain modular owners.
