# Tick Survival Lab — 03 Actor Locomotion State & Movement Capability

Status: **IMPLEMENTED — canonical modular source; Run seam activated by implemented System 17 on 2026-08-16**

Approval basis: original 03 was explicitly approved on 2026-08-16. System 17 later activated the already-reserved `movement.run_forward` capability seam without adding persistent Run state.

## 1. Goal

Own persistent actor stance and compose read-only mobility capability without creating a generic ActorState object.

03 answers:

- is the actor standing or crouched?;
- may the actor perform a movement/stance action?;
- how does stance change base timing?;
- how do independent condition domains contribute capability/timing through narrow providers?

Canonical relationship:

**persistent stance + read-only mobility contributors -> actor capability -> Movement/stance actions -> WHEN**

## 2. Ownership boundary

03 does not own identity, placement, collision, Health, fatigue state, inventory/carry truth, equipment, skills, input/UI, rendering, AI, perception, sound, or WHEN internals.

Those domains contribute only through public provider contracts. System 17 does not change that boundary.

## 3. Implemented owners

Under `game/scripts/simulation/actors/locomotion/`:

- `ActorStance.gd`
- `ActorLocomotionRecord.gd`
- `ActorLocomotionState.gd`
- `ActorLocomotionMutationService.gd`
- `ActorMovementCapabilityDecision.gd`
- `ActorMobilityModifierProvider.gd`
- `ActorMovementCapabilityService.gd`
- `ActorMovementTraversalPolicy.gd`
- `ActorStanceActionResult.gd`
- `ActorStanceActionService.gd`

Verification includes `ActorLocomotionSmoke.gd` plus System 17 integration coverage.

## 4. Persistent state

The only persistent locomotion state remains:

- `standing`
- `crouched`

There is **no persistent Run mode**. Running is a semantic Movement action requested when needed.

Actors require explicit locomotion enrollment. Missing state fails closed as `ACTOR_UNCLASSIFIED`. Snapshot/restore remains deterministic and stores stance/version only; pending actions remain WHEN-owned.

## 5. Stance timing

Standing:

- ordinary step scale 1.0x;
- turn scale 1.0x;
- Run permitted subject to registered providers.

Crouched:

- forward/back walk scale 1.4x;
- turn scale 1.0x;
- `movement.run_forward` is explicitly CAPABILITY_BLOCKED.

Crouch/stand are real committed actions with 4-tick base cost before provider modifiers.

All scales use deterministic integer basis points with ceiling division.

## 6. Capability contract

`ActorMovementCapabilityService.evaluate(actor_id, action_type, base_duration_ticks)` returns:

- `ALLOWED`
- `ACTOR_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`

Recognized action vocabulary includes:

- `movement.step_forward`
- `movement.step_backward`
- `movement.run_forward`
- `movement.turn_left`
- `movement.turn_right`
- crouch / stand stance actions.

Unknown actions fail closed.

## 7. Provider seam

Each `ActorMobilityModifierProvider` supplies a stable provider ID and read-only `(actor_id, action_type)` evaluation with:

- ALLOWED / BLOCKED / UNKNOWN;
- signed duration adjustment in basis points;
- semantic reason.

Provider IDs are unique and evaluated in deterministic sorted order. Explicit BLOCKED outranks UNKNOWN; UNKNOWN fails closed; allowed timing adjustments combine additively.

Current canonical demo registers:

- Needs/Fatigue provider;
- Carry/Encumbrance provider.

The demo therefore now uses the already-implemented real fatigue/carry timing seams rather than leaving those providers unwired.

## 8. Run capability semantics

System 17 activates `movement.run_forward` as a real action.

At Run request time:

- actor must be standing;
- Needs provider must permit Run start;
- Carry and other registered providers contribute their timing/capability decisions;
- current provider timing scales each Run stride base duration through the actor-aware traversal policy.

Needs specifically blocks Run start at fatigue 80+ (`too_exhausted_to_run`).

Once a Run is accepted, the two-stride action latches start-time actor capability. System 17 intentionally does **not** re-evaluate actor condition between strides, because Run is a committed action. Therefore self-generated fatigue crossing 80 after stride one does not cancel stride two. New condition affects the next action.

This differs from ordinary Walk/Turn commit behavior, where Movement continues to perform its normal commit-time capability revalidation.

## 9. ActorMovementTraversalPolicy

The adapter keeps base terrain timing separate from actor condition:

- ordinary `evaluate_step` -> base walk terrain timing -> actor capability;
- `evaluate_run_stride` -> base 60%-of-walk Run-stride timing -> actor capability using `movement.run_forward`;
- `evaluate_turn` -> base turn timing -> actor capability.

The adapter does not inspect Needs/Carry internals.

## 10. Stance action contract

`request_crouch` / `request_stand` remain real WHEN COMMITTED actions. Same-stance request is explicit no-op. State mutates only at final stance commit and revalidates expected version/source stance/capability. Hard pause freezes action with zero hidden ticks.

## 11. Historical recovery

Golden `PlayerActor.gd` supplied useful tuning/direction:

- walk ~10 ticks;
- run pace ~6 ticks/square;
- crouched walk ~14;
- turn ~3;
- stance ~4;
- crouch prevents Run;
- actor condition can alter action timing.

Rejected golden architecture remains rejected: no player-only god object and no persistent RUN flag.

## 12. Verified acceptance criteria

03 + System 17 tests now prove:

- explicit enrollment/version/snapshot rules;
- standing 1.0x and crouched 1.4x walk timing;
- committed 4-tick stance change;
- crouched Run blocked;
- standing Run recognized through capability;
- deterministic provider ordering and timing combination;
- fatigue/carry providers can modify Run start timing without Movement imports;
- fatigue 80+ provider block propagates as capability blocked;
- Run start capability can be latched while subsequent condition changes affect the next action;
- no persistent Run state exists;
- Movement/Locomotion remain independent of Needs/Carry implementation internals.

## 13. Supersession note

System 17 supersedes older wording in this design that Run was only a deferred future seam. The seam is now active; the detailed physical Run contract belongs to `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` and Movement System 02.

## 14. North-star fit

03 still supplies the smallest modular locomotion model for **Ultima-style turn-based mini Zomboid**: persistent stance plus composable real capability, with Run now using the seam that was deliberately reserved for it rather than forcing a locomotion-state redesign.
