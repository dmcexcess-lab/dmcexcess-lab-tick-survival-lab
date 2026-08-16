# Tick Survival Lab — 03 Actor Locomotion State & Movement Capability

Status: **IMPLEMENTED — canonical modular source and dedicated Godot CI contract present 2026-08-16**

Approval basis: after reviewing the DRAFT design, the user explicitly instructed **“Approved!”** on 2026-08-16.

## 1. Goal

Provide the canonical shared locomotion-state and movement-capability layer for persistent actors without creating a generic `ActorState` god object.

The system answers only locomotion questions:

- is an actor standing or crouched?;
- may the actor perform a movement/stance action?;
- how does stance modify a base action duration?;
- how can future health, fatigue, encumbrance, equipment or skill systems affect mobility without Movement, WHAT, Collision or WHEN learning their internals?

Canonical relationship:

**persistent stance + read-only mobility contributors -> actor capability -> Movement policy / stance action -> WHEN**

## 2. Non-goals / ownership boundary

This system does **not** own actor identity, appearance, occupation, relationships, health/wounds, fatigue/stamina, hunger/thirst/temperature, inventory/carry weight, equipment, skills, input/UI, rendering/animation, perception, sound, AI/pathfinding, collision, terrain classification, WHAT placement, WHEN internals, doors, forced displacement, generation or population simulation.

Those domains may later contribute mobility effects through the provider contract without being imported by locomotion.

## 3. Implemented owners

Canonical production source lives under `game/scripts/simulation/actors/locomotion/`:

- `ActorStance.gd` — stable semantic stance vocabulary.
- `ActorLocomotionRecord.gd` — immutable-style actor locomotion value record.
- `ActorLocomotionState.gd` — authoritative locomotion store, safe reads, revision, deterministic snapshot/restore.
- `ActorLocomotionMutationService.gd` — validated normal write path.
- `ActorMovementCapabilityDecision.gd` — typed actor-capability decision.
- `ActorMobilityModifierProvider.gd` — narrow extension contract for future condition domains.
- `ActorMovementCapabilityService.gd` — deterministic stance/provider aggregation.
- `ActorMovementTraversalPolicy.gd` — Movement-policy adapter that layers actor capability over base terrain/timing policy.
- `ActorStanceActionResult.gd` — typed crouch/stand request result.
- `ActorStanceActionService.gd` — timed voluntary stance action owner.

Verification/support:

- `game/scripts/ci/ActorLocomotionTestProvider.gd`
- `game/scripts/ci/ActorLocomotionSmoke.gd`
- `.github/workflows/actor-locomotion.yml`

## 4. Persistent locomotion state

The only persistent locomotion state in 03 is semantic stance:

- `standing`
- `crouched`

Each record is keyed by the stable WHAT entity ID and contains:

- actor ID;
- semantic stance;
- monotonic per-actor locomotion version.

Stance is not stored in `WorldEntityRecord`, does not alter WHAT placement, and does not require the actor to remain tactically placed. An unplaced/distant actor may retain locomotion state.

### Explicit enrollment / fail closed

ACTOR-channel placement does not implicitly create locomotion capability.

- actors must be explicitly enrolled;
- first explicit enrollment defaults to standing unless another valid stance is supplied;
- duplicate enrollment is rejected;
- missing locomotion state is `ACTOR_UNCLASSIFIED`, not an assumed standing actor;
- cleanup is explicit rather than tied to Godot Node lifetime;
- remove/re-enroll receives a newer version basis so stale pending stance work cannot accidentally match a recreated record.

## 5. No persistent run state / no run action yet

`run` is **not** persistent locomotion state. A stationary actor is never physically “running” because an input preference happens to be enabled.

03 deliberately does **not** add `request_run` or a runnable Movement action. Until real fatigue/stamina/sound consequences exist, faster running would be an incomplete always-better placeholder.

The capability service reserves semantic `movement.run_forward` only as a future extension seam. Crouched stance already reports that future action as blocked, without implementing the action itself.

## 6. Stance behavior and timing

Standing:

- step duration scale: `10000` = 1.0x base Movement duration;
- turn duration scale: `10000` = 1.0x.

Crouched:

- same WHAT anchor/footprint as standing;
- forward/backward step scale: `14000` = 1.4x;
- turn scale: `10000` = 1.0x in the initial tuning;
- future run capability is blocked.

Voluntary crouch/stand changes are real actions with base cost **4 ticks** before external capability modifiers.

All timing scaling uses deterministic integer basis points. Positive scaled durations use integer ceil division so they cannot truncate to zero.

These values are balance tuning, not WHEN constants.

## 7. Actor locomotion state contract

`ActorLocomotionState` owns only locomotion records plus store revision.

Public reads return copies/semantic values. Normal writes pass through `ActorLocomotionMutationService`:

- `enroll(actor_id, initial_stance)`
- `remove(actor_id)`
- `set_stance(actor_id, target_stance)`

Successful stance mutation increments both the actor locomotion version and store revision and emits a stance-change fact. Successful enroll/remove also advance the store revision.

The store intentionally does not own WHAT lifecycle. If a WHAT entity is removed, locomotion cleanup remains an explicit domain/orchestration action rather than hidden cross-domain mutation.

## 8. Snapshot / restore

Locomotion snapshot state contains:

- explicit schema version;
- deterministic actor-ID-sorted records;
- semantic stance values;
- per-actor versions;
- store revision.

Restore validates into replacement state first and is atomic on malformed input. No Godot Node references, WHAT placement, health, inventory, fatigue or pending action objects are serialized here.

Pending stance actions remain WHEN-owned serializable action records/payloads, avoiding a second action truth.

## 9. Stance action contract

`ActorStanceActionService` exposes:

- `request_crouch(actor_id)`
- `request_stand(actor_id)`

Request-time requirements:

- service dependencies ready;
- actor exists in WHAT;
- actor has an ACTOR-channel placement;
- actor has explicit locomotion state;
- actor is not already busy in WHEN;
- requested stance differs from current stance;
- capability service allows the transition and resolves a positive duration.

Requesting the already-current stance returns explicit `NO_CHANGE` and consumes no ticks.

Accepted stance actions:

- use WHEN `COMMITTED` interruption policy;
- contain one final `actor.stance.commit` phase;
- store expected locomotion version, source stance and target stance in safe payload data;
- mutate locomotion state only at commit;
- are frozen normally by hard application pause with zero hidden tick advancement.

At commit the service rechecks WHAT actor/placement, expected locomotion version/source stance, action/target consistency and current capability. If any required fact changed, the action fails without overwriting newer state.

## 10. Capability service contract

`ActorMovementCapabilityService.evaluate(actor_id, action_type, base_duration_ticks)` returns typed:

- `ALLOWED`
- `ACTOR_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`

The decision includes resolved duration, reason and stance used for evaluation.

Unknown actor locomotion state fails closed. Unknown action semantics fail closed rather than silently receiving ordinary walk capability.

## 11. Mobility modifier provider seam

Future systems extend mobility through `ActorMobilityModifierProvider`, not by exposing their internal dictionaries to locomotion.

Each provider supplies:

- stable unique provider ID;
- read-only `(actor_id, action_type)` evaluation;
- `ALLOWED`, `BLOCKED` or `UNKNOWN`;
- signed duration adjustment in basis points;
- stable reason where relevant.

Aggregation rules:

- duplicate provider IDs are rejected;
- provider IDs are maintained/evaluated in sorted deterministic order;
- any explicit `BLOCKED` result blocks the action;
- `UNKNOWN` fails closed if no explicit block supersedes it;
- allowed adjustments combine additively in basis points;
- a non-positive combined scale is `INVALID_DURATION`;
- providers do not mutate other domains during evaluation.

Intended future provider owners include Health, Needs/Fatigue, Inventory/Encumbrance, Equipment and Skills/Traits.

## 12. Movement integration / 02 contract revision

03 implements the approved narrow revision to Movement's replaceable policy seam.

New `game/scripts/simulation/movement/MovementPolicyDecision.gd` distinguishes:

- `ALLOWED`
- `TERRAIN_UNCLASSIFIED`
- `TERRAIN_BLOCKED`
- `ACTOR_UNCLASSIFIED`
- `CAPABILITY_UNKNOWN`
- `CAPABILITY_BLOCKED`
- `INVALID_DURATION`

`MovementTraversalPolicy` now exposes typed:

- `evaluate_step(actor_id, action_type, terrain_types)`
- `evaluate_turn(actor_id, action_type)`

The simple base policy still owns only terrain/base timing. `ActorMovementTraversalPolicy` delegates to the base policy, then applies `ActorMovementCapabilityService`.

`MovementActionResult` gained matching actor/capability failure statuses so an injured/unknown actor condition is never mislabeled as terrain failure.

The public Movement action vocabulary and semantics remain unchanged: forward, backward, turn left and turn right only.

## 13. Commit-time capability revalidation

Movement already revalidates collision, terrain and expected origin at `movement.commit`. Actor-aware policy evaluation now runs again there as well.

- if the actor becomes **incapable** before commit, the committed action spends its elapsed duration and fails without WHAT movement;
- if the actor remains capable but a new condition would make movement **slower**, the already-scheduled action is not stretched/rescheduled;
- the changed duration applies to the next action.

This preserves deterministic WHEN ownership of the committed duration while still allowing severe physical capability changes to invalidate the final physical result.

## 14. Signals / observation

Locomotion exposes mechanic facts such as record enrolled/removed and stance changed. Stance actions expose committed/failed results.

Renderer, UI, perception, sound and AI may observe these facts later without locomotion owning presentation or decision logic.

## 15. Performance / mobile

Normal locomotion lookup is O(1); capability evaluation is O(P) over a deliberately small provider set. There is no per-frame polling, full-world scan or Node-per-record requirement.

No Safari/touch handling lives here. Future input adapters emit semantic crouch/stand/movement requests. WHEN/application lifecycle remains owner of hard-pause behavior.

## 16. Historical recovery

Golden source inspected:

- `PlayerActor.gd` blob `2f839f1a50041c8bd00e144c1a9389d0a33d1401` from recovery commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Recovered useful behavior:

- walk ~10 ticks;
- crouched walk ~14 ticks;
- turn ~3 ticks;
- stance change ~4 ticks;
- crouch prevents running;
- actor conditions may modify action cost.

Rejected golden architecture:

- one player-only object owning movement, stance, health, carry weight, fatigue and identity;
- persistent RUN mode as physical simulation state;
- float ratios as the cross-system capability contract.

## 17. Verified acceptance criteria

Dedicated Godot 4.7.1 CI proves:

- explicit enrollment and duplicate rejection;
- safe locomotion reads, revision/version progression and explicit cleanup;
- deterministic snapshot round-trip and atomic malformed restore rejection;
- standing 1.0x / crouched 1.4x step timing and normal crouched turning;
- crouched future-run capability blocked without implementing a run action;
- missing locomotion state fails closed;
- deterministic provider ordering, additive modifiers, UNKNOWN handling, BLOCKED priority and invalid non-positive scale rejection;
- crouch/stand mutate only at the final 4-tick stance commit;
- no-change stance requests consume zero ticks;
- stance does not alter WHAT anchor/footprint;
- hard pause freezes stance work with zero hidden time;
- stale locomotion versions prevent overwrite;
- locomotion may persist while WHAT placement is absent;
- WHAT actor removal causes pending stance commit failure without hidden cross-domain cleanup;
- actor-aware Movement distinguishes actor capability failures from terrain failures;
- crouched Movement uses 14 ticks against the 10-tick test terrain while turns remain 3 ticks;
- capability becoming BLOCKED mid-move prevents commit after the already-spent duration;
- a newly slower-but-still-allowed condition does not stretch the current move and affects the next request;
- the existing Movement regression smoke remains green;
- no reboot/input/render/generation/health/needs/inventory implementation was imported into the locomotion owner.

## 18. North-star fit

03 creates the smallest causal locomotion model that preserves meaningful movement/stance consequence for **Ultima-style turn-based mini Zomboid**. It gives later injuries, fatigue and encumbrance a real way to change action capability/cost while keeping those simulations independent, keeping WHEN mechanic-agnostic, and avoiding a generic ActorState god object.
