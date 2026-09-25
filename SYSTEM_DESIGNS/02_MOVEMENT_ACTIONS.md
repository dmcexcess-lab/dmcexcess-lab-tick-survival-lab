# Tick Survival Lab — 02 Movement Actions

Status: **IMPLEMENTED — canonical modular source; same-tick movement arbitration revised 2026-09-25**

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

`MovementActionService` may consume public contracts from WHERE, WHAT, Collision, WHEN, the replaceable movement policy, and the narrow `MovementPhysicalContestProvider` read-only seam. It must not import Health, Needs, Carry, Inventory, Combat, renderer/art, input/UI, generation, Reboot, or other mechanic internals.

System 17 preserves that boundary through stateless coordinators rather than importing Health/Needs into Movement. The 2026-09-25 stat-contest revision follows the same rule: `ActorPhysicalContestQuery` lives with actor state and supplies only a derived score through the narrow movement provider.

## 5. Request contract

Public methods:

- `request_step_forward(actor_id)`
- `request_step_backward(actor_id)`
- `request_run_forward(actor_id)`
- `request_turn_left(actor_id)`
- `request_turn_right(actor_id)`

Requests reject without spending time when dependencies, actor/placement, static collision, terrain, capability, duration, or WHEN submission are invalid. A walk request aimed at a cell occupied only by blocking ACTOR placement may be admitted so the authoritative timestamp batch can decide whether that actor simultaneously vacates. This is not a reservation and does not guarantee success.

Typed failures continue to distinguish target BLOCKED/UNKNOWN, terrain unclassified/blocked, actor unclassified, capability unknown/blocked, invalid duration, and timing rejection.

## 6. Terrain / timing policy

`MovementTraversalPolicy` owns semantic terrain traversal and base timing. Missing terrain rules fail closed.

Ordinary walk step duration uses the maximum registered walk cost over the target footprint. Turn duration remains independently configured; canonical demo baseline is 3 ticks.

System 17 adds `evaluate_run_stride(actor_id, terrain_types)`. Each run stride base duration is deterministic `ceil(walk_cost * 0.60)` before 03 actor modifiers. Therefore current 10-tick demo terrain resolves to 6 ticks per run square.

`ActorMovementTraversalPolicy` then applies actor capability/provider modifiers. Movement never learns what fatigue, carry, stance, or injuries mean.

## 7. Walking execution / interruption

Forward/backward Walk sequence:

**request -> validate -> spend time -> revalidate at `movement.commit` -> mutate WHAT**

Walk actions use WHEN `CANCELABLE` during wind-up and declare their final `movement.commit` offset as the point of no return. Real HP damage is observed by `MovementDamageInterruptionService`, which asks WHEN to interrupt the actor's active movement action.

Before `movement.commit`, cancellation:

- keeps ticks already elapsed;
- removes the remaining movement phase;
- leaves WHAT placement at the pre-walk cell;
- emits movement failure so callers resolve the action honestly.

At and after the commit timestamp, the action is effectively COMMITTED. Damage arriving later on that same authoritative tick cannot retroactively erase a movement consequence that already reached its commit boundary.

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

## 10. No reservation / simultaneous timestamp arbitration

Walk and Run reserve no cells. Request-time clarity does not guarantee commit-time success, and deterministic callback ordering is not initiative.

Movement phases due on the same WHEN timestamp are collected before placement mutation. The resolver re-reads one unchanged pre-resolution occupancy state, then resolves physical conflicts as a set:

- one uncontested mover into genuinely available space succeeds;
- two or more movers claiming the same destination compare frozen canonical physical scores; a unique highest scorer may win that cell, while an exact/unknown top tie is a stalemate and no claimant wins;
- a same-timestamp departure may release a cell for another actor's arrival claim;
- reciprocal ordinary walks `X -> Y` and `Y -> X` are a head-on traversal of the same physical edge and both fail with `movement_edge_conflict` rather than phasing through one another;
- longer compatible vacating chains/cycles may still succeed while every blocking actor has a surviving simultaneous move that actually vacates the claimed cells;
- if one mover in such a dependency set fails, blocked followers are removed to a fixed point rather than phasing through the actor that stayed;
- static/non-ACTOR blockers are never deferred;
- in-place turns do not count as vacating their occupied cell.

Successful placements are installed through `WorldMutationService.set_placements_batch`, so observers see the complete final occupancy rather than serial intermediate positions. Expected origin/intermediate placement must still match, preventing stale actions from overwriting newer WHAT truth.

`ActorPhysicalContestQuery` currently derives that score from existing state only: condition-adjusted carry capacity, current load, current HP relative to max HP, stance, and movement intent. It deliberately does not create a persistent Strength stat. A later dedicated body/Strength attribute can extend this provider without changing movement arbitration.

Movement now also accepts combat-owned forced-displacement trajectories through its narrow public transition seam. Shove contact supplies a frozen source score plus target resistance before same-timestamp damage mutation; Movement arbitrates that forced trajectory beside any already-due movement for the target and beside other spatial claims. Ordinary walking still never acquires implicit displacement authority. Broader same-direction crowd-force aggregation and push-chain propagation remain Phase-2 work.

## 11. Damage and exertion coordination

`MovementDamageInterruptionService` listens only to public Health `damage_applied` and public WHEN active-action/interrupt APIs. It stores no persistent state. WHEN's policy decides the result: Walk cancels; Run/Turn continue.

`MovementRunExertionService` listens only to successful `run_stride_committed` facts and calls the public Needs mutation API to add +1 fatigue per successful stride. Failed physical strides add no fatigue. MovementActionService itself has no Needs dependency.

## 12. Signals

Movement emits:

- `movement_committed`
- `movement_failed`
- `run_stride_committed` for each successful physical sprint stride;
- `forced_displacement_resolved` for combat-owned shove/displacement trajectories after the shared spatial batch settles.

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

## 13A. Phase 2C same-tick conflict verification — 2026-09-25

Fresh prompt-local verifier/workflow:

- `game/scripts/ci/Phase2CMovementConflictsSmoke.gd`
- `.github/workflows/phase2c-movement-conflicts.yml`

Functional production head: `d87f1402b0f06f69f1f8a614b3a7557dd7641b71`.

Focused verifier head/run: `f605987f7feb4fd24e06f3724d90622d900beee9` / `36187796332` — **SUCCESS**.

Marker: `PHASE2C_MOVEMENT_CONFLICTS_OK contest_tick=10 swap_tick=20 no_hidden_winner=true`.

The production scene proved that two infected reaching the same empty destination on one timestamp both remain at their origins and both fail with `target_contested`, while two adjacent infected moving into each other's occupied cells on one timestamp are both admitted to arbitration and atomically exchange positions.

## 13B. Phase 2C stat-based contest verification — 2026-09-25

Fresh prompt-local verifier/workflow:

- `game/scripts/ci/Phase2CStatContestsSmoke.gd`
- `.github/workflows/phase2c-stat-contests.yml`

Functional production head/run: `1689fb3124641b7a9abacfc9010fbc7056951e5f` / `36189772342` — **SUCCESS**.

Marker: `PHASE2C_STAT_CONTESTS_OK unequal_winner=<resident actor> tied_stalemate=true`.

The production scene set two otherwise equivalent infected to unequal canonical carry capacities (24 kg versus 12 kg) and submitted simultaneous moves into the same empty cell. Both actions shared the same movement timestamp; the higher derived physical score won the cell and the weaker actor remained at origin with `target_contest_lost`. Repeating the case at equal 18 kg capacities produced an exact derived-score tie: both actors remained at origin with `target_contest_tied`, proving there is still no actor-ID/order fallback.

This supersedes the provisional 13A assertion that all same-destination claimants necessarily fail. They now all fail only when no unique physical-stat winner exists.

## 13C. Phase 2C transition-edge verification — 2026-09-25

Fresh prompt-local verifier/workflow:

- `game/scripts/ci/Phase2CTransitionEdgesSmoke.gd`
- `.github/workflows/phase2c-transition-edges.yml`

Functional production head/run: `54a62812bf692816ebf8907ff3f1c91e85296f41` / `36192545127` — **SUCCESS**.

Marker: `PHASE2C_TRANSITION_EDGES_OK reciprocal_blocked=true release_chain=true`.

The production scene proves both sides of the new transition model:

- two adjacent walkers attempting to exchange cells on one timestamp do **not** atomically swap; both remain at their incoming positions and fail with `movement_edge_conflict`;
- three walkers in a one-direction chain may all advance together when the leading actor moves into genuinely empty space, allowing each trailing actor to inherit the cell released ahead of it.

This supersedes the earlier Phase-2C claim that reciprocal occupied-cell swaps are always valid. Same-timestamp occupancy is now understood as conditional origin release plus destination arrival claim, with opposing traversal of the same edge treated as a physical conflict.

## 13D. Phase 2C shove-transition verification — 2026-09-25

Fresh prompt-local verifier/workflow:

- `game/scripts/ci/Phase2CShoveTransitionsSmoke.gd`
- `.github/workflows/phase2c-shove-transitions.yml`

Functional production head: `355de006567289ac257b0b3437f87946d72c427c`.

Focused verifier repair head/run: `f161e1673fb23e351399f5d778d4cf8efa4fe4d4` / `36194398176` — **SUCCESS**.

Marker: `PHASE2C_SHOVE_TRANSITIONS_OK shove_beats_move=true opposing_tie=true corpse_after_displacement=true`.

The production scene proves:

- a stronger shove and the target's already-committed movement can mature on the same tick; frozen physical scores select one target trajectory and the losing move fails with `shoved`;
- two equal simultaneous shoves from opposite sides produce no attacker-order winner and leave the target in place;
- a shove and lethal unarmed strike reaching the same target on the same contact tick both remain real consequences: spatial arbitration moves the target first, then deferred death publication creates its corpse at the post-shove outgoing position.

Movement physical scores are now frozen when each movement consequence enters the timestamp batch rather than re-read after combat damage. This prevents same-tick injury from retroactively weakening an already-earned movement contest.

## 14. Supersession note

System 17 supersedes older statements in this design that all Movement actions were COMMITTED and that Run did not exist. The canonical detailed Run contract is `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md`.

## 15. North-star fit

Movement remains readable deterministic grid movement for **turn-based persistent zombie survival**: Walk is cautious and interruptible; Run crosses ground faster per square but commits two physical strides and costs endurance, while timing, actor condition, damage, and presentation remain independently owned.
