# Tick Survival Lab — 02 Movement Actions

Status: **IMPLEMENTED — canonical modular source and dedicated Godot CI contract present 2026-08-16**

Approval basis: after the Movement Actions design was described in chat, the user instructed: **“Approved code it.”**

03 Actor Locomotion later made an explicitly approved **typed policy-contract extension** without changing Movement's physical action semantics.

## 1. Goal

Provide the canonical actor movement bridge across WHERE + WHAT + Collision / Spatial Query + WHEN.

Movement turns a semantic request into a deterministic timed action, revalidates legality at commit, and mutates WHAT placement only through `WorldMutationService`.

## 2. Action vocabulary

- `movement.step_forward` — one cell along current facing.
- `movement.step_backward` — one cell opposite facing without changing facing.
- `movement.turn_left` — rotate 90 degrees in place.
- `movement.turn_right` — rotate 90 degrees in place.

No diagonal movement, strafing or run action is implemented by 02/03.

## 3. Non-goals

Movement does not own input/held-button state, touch/Safari UI, rendering/animation, AI/pathfinding, stance state, health, fatigue, encumbrance, equipment, doors/interactions, forced displacement, vision, lighting, sound, weather, generation/streaming, collision profiles, WHAT internals or WHEN internals.

Actor-specific stance/condition capability is supplied through the replaceable policy seam established by 03, not stored in MovementActionService.

## 4. Owners

Canonical source under `game/scripts/simulation/movement/`:

- `MovementPolicyDecision.gd` — typed traversal/capability policy result.
- `MovementActionResult.gd` — typed request result/status.
- `MovementTraversalPolicy.gd` — simple terrain/base timing policy.
- `MovementActionService.gd` — request validation, WHEN submission, commit revalidation and WHAT placement mutation.
- `game/scripts/ci/MovementActionsSmoke.gd`
- `.github/workflows/movement.yml`

03 supplies optional actor-aware adapter `game/scripts/simulation/actors/locomotion/ActorMovementTraversalPolicy.gd` through the same policy contract.

## 5. Allowed dependencies

MovementActionService may consume public contracts from:

- WHERE: facing, footprint and spatial layer vocabulary;
- WHAT: safe entity/placement reads plus `WorldMutationService` writes;
- Collision / Spatial Query: hypothetical footprint queries and terrain reads;
- WHEN: `TickKernel`, phases and timing enums;
- replaceable Movement policy.

It must not import reboot runtime, renderer/art/camera, input/UI, generator/streaming, AI/pathfinding, health/needs/inventory/combat, door systems, weather/lighting/perception/sound.

## 6. Request contract

Public semantic methods remain:

- `request_step_forward(actor_id)`
- `request_step_backward(actor_id)`
- `request_turn_left(actor_id)`
- `request_turn_right(actor_id)`

A request is rejected without spending simulation time when dependencies/actor/placement are invalid, actor is busy, Collision returns BLOCKED/UNKNOWN, policy rejects traversal/capability, duration is invalid, or WHEN rejects submission.

Accepted results contain action serial, resolved duration and target placement facts.

`MovementActionResult` distinguishes physical and policy-domain failures, including:

- target blocked / target unknown;
- terrain unclassified / terrain blocked;
- actor unclassified;
- capability unknown / capability blocked;
- invalid duration / timing rejected.

## 7. Typed policy contract

The policy seam uses `MovementPolicyDecision` with statuses:

- `ALLOWED`
- `TERRAIN_UNCLASSIFIED`
- `TERRAIN_BLOCKED`
- `ACTOR_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`

Canonical policy methods:

- `evaluate_step(actor_id, action_type, terrain_types) -> MovementPolicyDecision`
- `evaluate_turn(actor_id, action_type) -> MovementPolicyDecision`

The simple `MovementTraversalPolicy` owns semantic terrain rules and base timing only. Existing terrain must be registered; missing rules fail closed. Multi-cell step duration uses the maximum target-footprint terrain cost. Turn duration is configured independently.

03's `ActorMovementTraversalPolicy` composes the simple base policy with actor locomotion/capability. MovementActionService remains ignorant of stance, injuries, fatigue, inventory or provider internals.

## 8. Execution model

Canonical sequence:

**request -> validate now -> spend simulation time -> revalidate at `movement.commit` -> mutate WHAT**

Every accepted movement action has one final `movement.commit` phase at its total duration and uses WHEN's `COMMITTED` interruption policy. Ordinary interruption does not refund/cancel the chosen move. Hard application pause remains separate and advances zero simulation ticks.

Pending placement facts are stored in WHEN's serializable action payload rather than in a second Movement pending-action store.

## 9. No destination reservation

Movement does **not** reserve target cells.

A target may be clear when an action starts and become occupied before commit. Commit repeats collision/terrain/policy legality. If the destination is no longer legal, the actor remains at origin and elapsed ticks are not refunded.

Concurrent actors may therefore both begin toward one cell; deterministic WHEN ordering and commit-time revalidation permit only a still-legal commit.

## 10. Origin consistency

The accepted action payload stores the expected starting `WorldPlacement` as safe serializable data.

At commit, current placement must still be equivalent. If another mechanic moved, rotated or unplaced the actor meanwhile, the stale movement fails rather than overwriting newer WHAT truth.

## 11. Turning / multi-cell footprint

Turning preserves anchor and changes facing only, but Collision receives the complete rotated footprint. A multi-cell actor therefore cannot rotate through a blocker/UNKNOWN cell.

Backward movement changes anchor opposite current facing and preserves facing.

## 12. Commit-time policy/capability revalidation

Movement reevaluates its policy at commit for both steps and turns.

With 03 actor capability:

- if capability becomes blocked/unknown before commit, the move fails after the committed duration;
- if capability remains allowed but now implies a slower duration, the already-scheduled action is **not stretched or rescheduled**;
- the new duration applies to the next request.

This keeps WHEN authoritative over an action's committed schedule while allowing a severe newly changed condition to invalidate the final physical effect.

## 13. Terrain/base timing

Collision answers hard occupancy; Movement policy answers traversal/timing.

The simple policy explicitly registers semantic terrain as traversable/non-traversable with positive step ticks for traversable terrain. Missing rules fail closed. Turning has a separate positive base duration.

The historical golden prototype's ~10-tick walk and ~3-tick turn remain tuning guidance, not WHEN constants.

## 14. Signals

Movement emits semantic commit/failure facts. Future input/render/AI systems may observe them without Movement owning presentation or decisions.

## 15. Verified acceptance criteria

Movement CI and 03 regression coverage prove:

- forward commit only at final tick;
- backward preserves facing;
- left/right turn in place;
- semantic terrain duration and fail-closed terrain handling;
- static blockers reject before time is spent;
- mid-action blocker causes full-duration failure;
- same-cell races use no reservation and deterministic commit revalidation;
- stale origin never overwrites newer placement;
- multi-cell rotation checks rotated footprint;
- COMMITTED behavior and hard-pause zero-time behavior;
- typed policy results preserve terrain errors and distinguish actor/capability failures;
- actor-aware crouched movement can change duration without Movement importing stance state;
- capability becoming blocked at commit prevents placement;
- newly slower-but-allowed capability affects the next action, not the current schedule;
- no run action was smuggled into Movement;
- frozen reboot runtime remains untouched.

## 16. North-star fit

Movement provides readable cell-by-cell, variable-duration physical action for **Ultima-style turn-based mini Zomboid** while keeping occupancy, actor condition, timing and presentation in their proper owners.
