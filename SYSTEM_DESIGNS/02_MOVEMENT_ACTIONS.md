# Tick Survival Lab — 02 Movement Actions

Status: **APPROVED — user explicitly approved implementation 2026-08-16**

Approval basis: after the Movement Actions design was described in chat, the user instructed: **“Approved code it.”**

## 1. Goal

Provide the canonical actor movement bridge across WHERE + WHAT + Collision / Spatial Query + WHEN.

Movement turns a semantic movement request into a deterministic timed action, revalidates physical legality when the action commits, and mutates WHAT placement only through `WorldMutationService`.

## 2. Initial action vocabulary

- `STEP_FORWARD` — one cell along current facing.
- `STEP_BACKWARD` — one cell opposite current facing without changing facing.
- `TURN_LEFT` — rotate 90 degrees in place.
- `TURN_RIGHT` — rotate 90 degrees in place.

No diagonal movement or strafing is part of this slice.

## 3. Non-goals

Movement does not own:

- input, held-button state, touch/Safari handling or UI;
- rendering or animation;
- AI or pathfinding;
- crouch/stance, sprint state, fatigue, injury, encumbrance or equipment;
- doors/interactions, pushing, shoving or forced displacement;
- vision, lighting, sound or weather;
- generation/streaming/materialization;
- collision profiles/overrides;
- WHEN internals or WHAT internals.

Held input may later request another ordinary move whenever WHEN reports the controlled actor ready.

## 4. Owners

Canonical implementation is under `game/scripts/simulation/movement/`:

- `MovementActionResult.gd` — immutable-style request result/status.
- `MovementTraversalPolicy.gd` — replaceable terrain traversal and base duration policy.
- `MovementActionService.gd` — validates, submits, revalidates and commits movement actions.
- `game/scripts/ci/MovementActionsSmoke.gd` — deterministic integration/contract smoke.

## 5. Allowed dependencies

Movement may consume only public contracts from:

- WHERE: facing, footprint and spatial layers;
- WHAT: safe entity/placement reads plus `WorldMutationService` writes;
- Collision / Spatial Query: hypothetical footprint queries and terrain reads;
- WHEN: `TickKernel`, `ActionPhase`, timing enums and semantic action signals;
- the replaceable Movement Traversal Policy.

## 6. Forbidden dependencies

Movement must not import:

- reboot runtime;
- renderer/art/camera;
- input/UI/Safari adapters;
- generator/streaming;
- AI/pathfinding;
- health/needs/inventory/combat;
- door/interaction systems;
- weather/lighting/perception/sound.

## 7. Request contract

`MovementActionService` exposes semantic methods for the four initial actions.

A request is rejected without consuming time when:

- dependencies are not ready;
- actor ID is invalid/missing;
- entity has no placement;
- placement is not on the ACTOR channel;
- actor already has an active WHEN action;
- target Collision query is BLOCKED or UNKNOWN;
- required terrain has no traversal rule or is non-traversable;
- the policy cannot provide a valid positive duration;
- WHEN rejects action submission.

Accepted requests return a MovementActionResult containing the WHEN action serial, duration and target placement facts.

## 8. Execution model

Canonical sequence:

**request -> validate now -> spend simulation time -> revalidate at commit -> mutate WHAT**

Every movement action is submitted to WHEN with one semantic `movement.commit` phase at the action's total duration. WHEN guarantees that a final-duration phase dispatches before the corresponding completion event.

Basic walking/turning actions use WHEN's **COMMITTED** interruption policy. Ordinary interruption therefore does not refund an already chosen movement decision. Hard application pause remains separate and freezes the action without simulation advancement.

## 9. No destination reservation

Movement does **not** reserve target cells.

A destination may be clear when an action begins and become blocked before its commit tick. At commit, Movement repeats the full Collision/terrain legality check. If the target is no longer legal, the action fails and the actor remains at its current placement; elapsed ticks are not refunded.

This allows concurrent actors to race for the same location deterministically without adding a reservation subsystem.

## 10. Origin consistency

The accepted action payload stores the actor's expected starting `WorldPlacement` as serializable primitive data.

At commit, Movement compares the actor's current placement with that expected placement. If another mechanic displaced, rotated, unplaced or otherwise changed the actor while the movement action was pending, Movement fails the stale action rather than overwriting newer world truth.

## 11. Turning and multi-cell footprints

Turning keeps the same anchor and changes only N/E/S/W facing, but it still queries the complete rotated footprint.

Therefore a multi-cell actor may be unable to rotate in place if its rotated footprint would overlap a blocker or UNKNOWN space.

## 12. Terrain traversal / timing policy

Collision answers hard occupancy only. Movement owns the separate traversal seam through `MovementTraversalPolicy`.

The canonical simple policy:

- explicitly registers semantic terrain rules;
- a traversable rule supplies positive step ticks;
- a non-traversable rule blocks stepping;
- missing terrain rules fail closed as unclassified;
- a multi-cell step uses the maximum step cost among target footprint terrain cells;
- turning uses a separately configured positive turn duration and does not imply terrain translation.

The production policy contains no health/injury/fatigue/inventory state. Future richer policy implementations may consume those systems and still satisfy the same MovementActionService contract.

The historical golden `PlayerActor.gd` used 10 ticks for walking and 3 for turning and centralized later cost modifiers. Those values/shape are recovery guidance, not WHEN rules.

## 13. Determinism and persistence seam

Movement itself owns no independent durable pending-action store. All facts needed to resolve a pending move are stored in WHEN's safe serializable action payload. This avoids a second timing truth and leaves future save orchestration able to restore WHEN plus WHAT without reconstructing hidden movement state.

## 14. Signals

Movement emits semantic result signals for:

- successful physical commit;
- failed commit with stable reason.

Input/render/AI may observe those later without Movement owning presentation or decision logic.

## 15. Tests / acceptance criteria

The permanent smoke must prove at least:

- forward movement commits only at the final tick;
- backward movement preserves facing;
- left/right turns change facing in place;
- variable terrain costs are respected;
- missing/untraversable terrain fails closed;
- static blockers reject requests;
- destination becoming blocked mid-action consumes time then fails;
- two actors racing for one target do not reserve it and only one can commit;
- origin displacement during an action prevents stale overwrite;
- multi-cell rotation checks the rotated footprint;
- hard pause freezes a pending movement action;
- the frozen reboot runtime is not imported or modified.

## 16. North-star fit

This is the first real tactical action bridge for **Ultima-style turn-based mini Zomboid**: readable cell movement, variable time exposure, persistent physical consequences and deterministic concurrency, with no real-time or presentation complexity smuggled into simulation truth.
