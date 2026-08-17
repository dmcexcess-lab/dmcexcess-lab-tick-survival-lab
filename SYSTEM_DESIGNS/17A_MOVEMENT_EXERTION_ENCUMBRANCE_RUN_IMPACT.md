# 17A Movement Exertion / Encumbrance / Run Impact Revision

Status: **IMPLEMENTED + CI — canonical source and live demo integration 2026-08-16**

Approval basis: after the user specified multiplicative terrain/encumbrance movement cost, terrain-only Walk fatigue, terrain+encumbrance Run fatigue, Run lockout at full encumbrance, painful Run impacts, and direct-Google exit, the user explicitly authorized implementation with **“17a Approved.”**

This design supersedes only the affected timing/exertion/impact points of Systems 03 / 13B / 13E / 17. The System 16 Web Leave Game path is also revised as a bounded maintenance change.

## 1. Goal

Make movement effort physically coherent without adding a stamina subsystem:

- terrain is the base movement cost;
- stance, fatigue and encumbrance multiply movement duration;
- Walk fatigue is terrain-driven and ignores carried load;
- Run fatigue responds to terrain and carried load;
- at or above full carrying capacity, Run cannot begin;
- a committed Run into a known hard blocker causes real HP damage;
- Web Leave Game goes directly to Google.

## 2. Canonical movement-time formula

Terrain remains the base physical cost.

- normal demo terrain = 10 Walk ticks;
- Run base stride = `ceil(walk_terrain_ticks * 0.60)`;
- normal terrain therefore remains 6 ticks per Run stride before actor factors.

Actor factors are true multipliers:

- standing step/run stance = `1.00`;
- crouched Walk stance = `1.40`;
- fatigue = `1.00 + fatigue * 0.0065`;
- encumbrance = `1.00 + load_ratio * 0.75`.

Resolved duration conceptually is:

`ceil(base_ticks * stance_scale * fatigue_scale * encumbrance_scale)`

Canonical providers expose positive duration scales in basis points. `ActorMovementCapabilityService` composes the canonical scales multiplicatively and performs one deterministic ceiling at the end. A compatibility read of the old adjustment field remains only for isolated legacy test providers; production Needs/Carry providers use scales.

Over-capacity Walk remains legal and continues slowing unless another capability blocks it.

## 3. Run eligibility

Run-start requirements now include:

- standing stance;
- fatigue below 80;
- derived carry load strictly below 100% capacity;
- known capability/terrain/collision truth.

At `load_ratio_bp >= 10000`, Carry returns `CAPABILITY_BLOCKED` with reason:

`too_encumbered_to_run`

As with System 17, accepted Run capability is latched for the committed sprint. Later condition changes affect the next action rather than canceling stride two by themselves.

## 4. Terrain effort

V1 exertion intentionally reuses Movement's semantic terrain timing instead of introducing a second terrain-stat catalog:

`terrain_effort_factor = walk_terrain_ticks / 10`

This keeps one physical terrain truth for the current simplified model. A later terrain system may split time cost from exertion cost if gameplay requires it.

## 5. Walking fatigue

Successful forward/back Walk placement emits a movement-exertion fact.

Walk fatigue per committed cell is:

`max(1, ceil(walk_terrain_ticks / 10))`

Examples:

- 10-tick terrain -> +1 fatigue;
- 14-tick terrain -> +2;
- 20-tick terrain -> +2.

Carry weight does **not** alter this fatigue charge. It may make the Walk take longer, but direct Walk exertion remains terrain-only.

A damage-canceled Walk that never commits a cell gains no movement fatigue in this version.

## 6. Running fatigue

Run exertion is resolved per successful or impact stride.

Encumbrance factor:

`1.00 + load_ratio * 0.75`

Run-stride fatigue:

`max(1, round((walk_terrain_ticks / 10) * encumbrance_factor))`

The implementation uses deterministic integer half-up rounding over basis-point math.

Examples verified by CI:

- normal terrain, empty -> +1 per stride;
- normal terrain, 75% capacity -> +2 per stride;
- 20-tick terrain, 50% capacity -> +3 per stride.

At 100%+ capacity Run is unavailable.

`MovementExertionService` is the stateless coordinator that reads real Carry and mutates real Needs through its public API. Movement does not import Needs or Carry.

## 7. Run impacts

A known hard Collision `BLOCKED` cell is now a Run impact candidate rather than a zero-cost request rejection.

Run request still rejects without spending time when target truth is:

- UNKNOWN/unmaterialized;
- missing/unclassified terrain;
- explicitly untraversable terrain;
- invalid actor/capability/timing state.

At each committed Run stride:

- CLEAR -> move one cell normally;
- BLOCKED -> remain at the last legal cell, charge the attempted stride's Run fatigue, emit `run_impact`, and terminate the Run;
- UNKNOWN -> fail closed without fake impact damage.

Consequences:

- blocker in stride 1 -> impact at stride-1 time, remain at origin;
- blocker in stride 2 -> keep valid first stride, impact at stride-2 time;
- a blocker appearing after Run start produces the same impact behavior when that stride resolves.

No rollback occurs.

## 8. Impact damage

`MovementRunImpactDamageService` observes `run_impact` and calls public Health damage.

V1 hard Run impact damage:

**5 HP**

The damage is real `ActorHealthState.apply_damage()` damage, so normal Health observation/HUD updates apply. It does not create an injury record, damage the blocker, or knock either body back.

Movement has no Health dependency.

## 9. Signals / coordination

Movement now emits generic resolved movement effort facts:

`movement_exertion_resolved(actor_id, action_serial, action_type, stride_index, terrain_walk_ticks, impacted)`

and physical Run impact facts:

`run_impact(actor_id, action_serial, stride_index, target_anchor, target_facing, blocking_entity_ids)`

These facts are consumed by stateless coordinators. Movement remains owner of physical movement only.

The old Run-only exertion coordinator is removed so there is one exertion path.

## 10. Leave Game revision

System 16 Web Leave Game now directly executes:

`window.location.assign('https://www.google.com/')`

There is no browser-history/back heuristic. Native non-Web quit behavior is unchanged.

## 11. Non-goals / protected domains

17A does not redesign WHERE, WHAT, Collision classification, WHEN internals, persistent stance, Health persistence/injury model, Needs record shape, Carry derivation/capacity state, Inventory/Hands/Item Transfer, rendering/art/HUD/inspectors, demo map, generation/streaming, or Reboot.

No stamina bar, persistent run mode, AI running, sound/noise, knockback, collision injury type, or terrain-effort catalog is added.

## 12. Verification

Dedicated implementation coverage:

- `.github/workflows/movement-exertion-encumbrance.yml`
- `game/scripts/ci/MovementExertionEncumbranceSmoke.gd`
- protected Movement / Locomotion / Health / Needs / Carry / System 17 / canonical demo/HUD/player-shell/startup regressions.

The first implementation candidate `ac949279d0c0474e2c566b4d24f614947e442320` passed parse and every protected regression, but the new 17A smoke initially failed because its local stateless `RefCounted` coordinators were not retained by the test fixture and were therefore correctly freed by Godot before signal observation. Production code required no repair.

Hardened candidate `eeb5eb421337df3067f45b41fb4837fdb9b8875b` retained those test services and passed dedicated 17A run `32000627706`, including the full 17A smoke, protected regressions and canonical startup.

Exact promoted-head Web/Pages validation is required before completion is claimed.

## 13. Approved decisions — 2026-08-16

1. Terrain, stance, fatigue and encumbrance compose multiplicatively for movement duration.
2. Existing carry pressure remains +75% duration at exactly capacity; over-capacity Walk remains possible.
3. Run is blocked at 100%+ capacity with `too_encumbered_to_run`.
4. Terrain effort derives from walk terrain ticks / 10 in v1.
5. Successful Walk fatigue is terrain-only and ignores weight.
6. Run stride fatigue multiplies terrain effort by encumbrance effort, minimum 1.
7. Known hard Run blockers are physical impacts, not harmless request rejection.
8. An impact stride charges Run fatigue and stops at the last legal cell.
9. Hard Run impact causes 5 HP through a separate Movement -> Health coordinator.
10. UNKNOWN/untraversable space does not become impact damage.
11. Web Leave Game navigates directly to Google.

## 14. North-star fit

17A preserves the mini-Zomboid rule: hard terrain, heavy loads and careless sprinting produce meaningful consequences, while the implementation remains coarse, deterministic and modular rather than adding a second stamina/physics simulation.
