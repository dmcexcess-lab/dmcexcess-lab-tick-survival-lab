# Tick Survival Lab — 02 Movement Actions

Status: **IMPLEMENTED — canonical modular source; revised by implemented System 17 on 2026-08-16**

Approval basis: original Movement was approved with “Approved code it.” System 03 later extended the typed actor-capability seam. System 17, explicitly approved with “17 is go for approval,” revises walking interruption and activates explicit two-cell running.

## 1. Goal

Own the canonical physical actor-movement bridge across WHERE + WHAT + Collision + WHEN. Movement validates semantic requests, submits deterministic timed actions, revalidates physical truth at movement phases, and mutates WHAT placement only through `WorldMutationService`.

Movement does not own input, rendering, AI/pathfinding, Health, Needs, Carry, stance truth, equipment, doors, perception, sound, weather, generation, or WHEN internals.

## 2. Action vocabulary

- `movement.step_forward` — one cell along facing.
- `movement.step_backward` — one cell opposite facing, preserving facing.
- `movement.run_forward` — two straight forward cells under one committed action, implemented by System 17.
- `movement.turn_left` — rotate 90 degrees in place.
- `movement.turn_right` — rotate 90 degrees in place.

No diagonal movement, strafing, or running backward exists in v1. Run is an explicit action, never persistent movement mode.

## 3. Owners

Canonical source under `game/scripts/simulation/movement/`:

- `MovementPolicyDecision.gd`
- `MovementActionResult.gd`
- `MovementTraversalPolicy.gd`
- `MovementActionService.gd`
- `MovementDamageInterruptionService.gd` — System 17 stateless Health -> WHEN coordination.
- `MovementRunExertionService.gd` — System 17 stateless Movement -> Needs coordination.

Primary verification:

- `game/scripts/ci/MovementActionsSmoke.gd`
- `game/scripts/ci/RunDamageWalkingSmoke.gd`
- `.github/workflows/movement.yml`
- `.github/workflows/run-damage-walking.yml`

03 supplies `ActorMovementTraversalPolicy.gd`, layering actor capability over terrain timing.

## 4. Allowed dependencies / hard boundaries

`MovementActionService` may consume public contracts from WHERE, WHAT, Collision, WHEN, and the replaceable movement policy. It must not import Health, Needs, Carry, Inventory, Combat, renderer/art, input/UI, generation, Reboot, or other mechanic internals.

System 17 preserves that boundary through two stateless coordinators rather than importing Health/Needs into Movement.

## 5. Request contract

Public methods:

- `request_step_forward(actor_id)`
- `request_step_backward(actor_id)`
- `request_run_forward(actor_id)`
- `request_turn_left(actor_id)`
- `request_turn_right(actor_id)`

Requests reject without spending time when dependencies, actor/placement, collision, terrain, capability, duration, or WHEN submission are invalid. Target cells are never reserved.

Typed failures continue to distinguish target BLOCKED/UNKNOWN, terrain unclassified/blocked, actor unclassified, capability unknown/blocked, invalid duration, and timing rejection.

## 6. Terrain / timing policy

`MovementTraversalPolicy` owns semantic terrain traversal and base timing. Missing terrain rules fail closed.

Ordinary walk step duration uses the maximum registered walk cost over the target footprint. Turn duration remains independently configured; canonical demo baseline is 3 ticks.

System 17 adds `evaluate_run_stride(actor_id, terrain_types)`. Each run stride base duration is deterministic `ceil(walk_cost * 0.60)` before 03 actor modifiers. Therefore current 10-tick demo terrain resolves to 6 ticks per run square.

`ActorMovementTraversalPolicy` then applies actor capability/provider modifiers. Movement never learns what fatigue, carry, stance, or injuries mean.

## 7. Walking execution / interruption

Forward/backward Walk sequence:

**request -> validate -> spend time -> revalidate at `movement.commit` -> mutate WHAT**

Walk actions use WHEN `CANCELABLE` interruption policy after System 17. Real HP damage is observed by `MovementDamageInterruptionService`, which asks WHEN to interrupt the actor's active movement action. A canceled walk:

- keeps ticks already elapsed;
- removes the remaining movement phase;
- leaves WHAT placement at the pre-walk cell;
- emits movement failure so callers resolve the action honestly.

Healing or max-HP bookkeeping is not damage interruption.

Hard application pause remains separate and advances zero simulation ticks.

## 8. Turn execution

Turns remain one final `movement.commit` phase and remain WHEN `COMMITTED`. Ordinary damage interruption does not cancel a turn. Collision checks the complete rotated footprint, so multi-cell actors cannot rotate through blockers/UNKNOWN space.

## 9. Run execution

`movement.run_forward` is one WHEN `COMMITTED` action containing two physical phases:

- `movement.run_stride_1`
- `movement.run_stride_2`

The request validates both crossed cells before time is spent and stores request-time physical path facts in the serializable WHEN payload.

For each stride:

- expected origin/intermediate placement must match;
- target footprint must remain Collision CLEAR;
- request-time terrain semantic truth must still match;
- if valid, WHAT advances exactly one cell;
- successful stride emits `run_stride_committed`.

A full healthy demo Run is 6 + 6 = 12 ticks. Mixed terrain sums the two independently resolved stride durations, e.g. walk costs 10 then 14 -> Run 6 + 9 = 15 ticks.

Run does not re-evaluate actor capability between strides. Capability is intentionally latched at Run start because Run is committed. Newly changed fatigue/carry affects the next action. Physical impossibility still stops the affected stride.

If stride 1 succeeds and stride 2 later fails, the actor remains at the intermediate cell; there is no rollback.

## 10. No reservation / race semantics

Walk and Run reserve no cells. Request-time clarity does not guarantee commit-time clarity. Deterministic WHEN ordering plus per-phase collision/path revalidation resolves races. Movement never overwrites a newer external placement because expected origin/intermediate placement must still match.

## 11. Damage and exertion coordination

`MovementDamageInterruptionService` listens only to public Health `damage_applied` and public WHEN active-action/interrupt APIs. It stores no persistent state. WHEN's policy decides the result: Walk cancels; Run/Turn continue.

`MovementRunExertionService` listens only to successful `run_stride_committed` facts and calls the public Needs mutation API to add +1 fatigue per successful stride. Failed physical strides add no fatigue. MovementActionService itself has no Needs dependency.

## 12. Signals

Movement emits:

- `movement_committed`
- `movement_failed`
- `run_stride_committed` for each successful physical sprint stride.

Presentation/input/AI may observe/request through public contracts without owning physical truth.

## 13. Verified acceptance criteria

Movement + System 17 CI cover:

- ordinary 10-tick forward/backward walk;
- backward facing preservation;
- committed 3-tick turns;
- walk CANCELABLE interruption plus hard-pause zero-time safety;
- real Health damage canceling Walk before commit;
- Run remaining COMMITTED under damage;
- two-cell Run request path validation;
- healthy Run physical stride at tick 6 and final stride at tick 12;
- mixed-terrain 60%-per-stride timing;
- no reservation and commit-time blocker handling;
- successful first stride retained when second fails;
- stale origin/intermediate placement never overwrites newer WHAT;
- semantic terrain fail-closed behavior;
- typed capability failures;
- crouched and exhausted Run rejection through 03/provider seams;
- no persistent run-mode state;
- no Health/Needs import in MovementActionService;
- frozen Reboot remains untouched.

## 14. Supersession note

System 17 supersedes older statements in this design that all Movement actions were COMMITTED and that Run did not exist. The canonical detailed Run contract is `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md`.

## 15. North-star fit

Movement remains readable deterministic grid movement for **Ultima-style turn-based mini Zomboid**: Walk is cautious and interruptible; Run crosses ground faster per square but commits two physical strides and costs endurance, while timing, actor condition, damage, and presentation remain independently owned.
