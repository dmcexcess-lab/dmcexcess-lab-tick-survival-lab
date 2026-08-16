# Tick Survival Lab — 03 Actor Locomotion State & Movement Capability

Status: **DRAFT — discussion only; implementation is not authorized**

Design started 2026-08-16 after the user instructed: **“Ok go ahead with design.”**

## 1. Goal

Provide the canonical shared locomotion-state and movement-capability layer for persistent actors without creating a generic `ActorState` god object.

This system owns only the actor facts and derived rules needed to answer questions such as:

- is this actor standing or crouched?;
- may this actor perform this kind of movement/stance action?;
- how should actor-specific capability modify the terrain/base duration supplied by Movement?;
- how can future health, fatigue, encumbrance, equipment or skill systems affect movement without teaching WHAT, Collision, MovementActionService or WHEN their internal rules?

The intended relationship is:

**persistent stance state + external capability contributors -> actor movement capability -> Movement policy -> timed Movement/stance action**

## 2. Naming / anti-god-object decision

The system is deliberately named **Actor Locomotion State & Movement Capability**, not simply `ActorState` or `PlayerState`.

A generic actor-state object would eventually attract identity, health, hunger, inventory, equipment, infection, skills, relationships, AI state and dozens of unrelated reasons to change. That would recreate the monolithic architecture the modular rebuild is intended to remove.

This system therefore owns only locomotion-relevant state and capability composition.

## 3. Initial persistent state

The only persistent locomotion state in this slice is **stance**:

- `standing`
- `crouched`

Stance is represented by stable semantic `StringName` values rather than renderer animation names or an enum whose numeric order becomes save-file meaning.

Each locomotion record contains:

- stable WHAT entity ID;
- semantic stance;
- monotonic per-actor locomotion version.

The per-actor version increments on every successful locomotion-state mutation so a pending stance action can detect that its starting state was changed by another mechanic before commit.

### No persistent “running” flag

`run` is **not** persistent actor state.

A stationary actor must not be considered physically “running” merely because a control toggle is selected. A future input layer may remember a run preference, but the simulation should represent running as a distinct movement action/variant while it is actually occurring.

This avoids later sound, fatigue, animation and perception systems incorrectly treating an idle actor as running.

## 4. Initial stance behavior

### Standing

- normal walking movement scale;
- normal turning scale;
- eligible for future run actions if other capability rules permit them.

### Crouched

- remains on the same WHAT tactical footprint; crouching does not shrink cell occupancy;
- ordinary forward/backward steps are slower;
- turning remains normal-speed in the initial tuning unless later evidence justifies a stance-specific turn penalty;
- future perception, stealth, sound, vulnerability and animation systems may consume stance but are not implemented here;
- future run actions are disallowed while crouched.

Changing stance is a physical action and therefore consumes simulation time.

## 5. No run implementation in this slice

The golden prototype had WALK/RUN state and made running faster, but a run action currently has no fatigue, stamina, sound or other downside in the new canonical runtime.

Implementing fast running now would therefore create a mechanically incomplete “always better” action and violate the project’s no-placeholder rule.

This design reserves a clean future seam for a semantic `movement.run_forward` action, but **03 implementation should not add running yet**.

When at least the meaningful run consequences are owned by real systems, running can be added without redesigning stance or capability composition.

## 6. Non-goals

This system does **not** own:

- actor identity, name, appearance, occupation, family or relationships;
- health, wounds, body regions, treatment or death;
- fatigue, stamina, hunger, thirst or temperature;
- inventory, carry weight, equipment or item ownership;
- skills/traits;
- input controls or run-toggle UI state;
- rendering or animation;
- vision/perception;
- sound/noise production;
- AI/pathfinding;
- collision/occupancy;
- terrain classification;
- WHAT entity/placement storage;
- WHEN scheduling internals;
- forced displacement;
- doors/interactions;
- generation/population ownership.

Those systems may later contribute to movement capability through the explicit provider seam described below.

## 7. Intended owner modules

Canonical implementation should live under `game/scripts/simulation/actors/locomotion/`:

- `ActorStance.gd` — semantic stance vocabulary/validation.
- `ActorLocomotionRecord.gd` — immutable-style actor locomotion value record.
- `ActorLocomotionState.gd` — authoritative locomotion record store, safe reads, revision and deterministic snapshot/restore.
- `ActorLocomotionMutationService.gd` — validated write path for enroll/remove/change-stance operations.
- `ActorMovementCapabilityDecision.gd` — typed capability result.
- `ActorMobilityModifierProvider.gd` — narrow extension contract for future health/fatigue/inventory/etc. contributors.
- `ActorMovementCapabilityService.gd` — deterministic stance + provider aggregation.
- `ActorMovementTraversalPolicy.gd` — actor-aware Movement policy adapter.
- `ActorStanceActionResult.gd` — typed stance-action request result.
- `ActorStanceActionService.gd` — timed crouch/stand action owner.
- `game/scripts/ci/ActorLocomotionSmoke.gd` — deterministic subsystem/integration smoke.

File names may be adjusted during implementation, but these responsibilities should remain separate.

## 8. Data ownership

### ActorLocomotionState owns

- locomotion records keyed by stable WHAT entity ID;
- per-actor locomotion version;
- locomotion-state store revision;
- deterministic snapshot/restore of those records.

### ActorLocomotionMutationService owns the normal write path

Gameplay systems should not mutate the store’s internal dictionaries/records directly.

Normal stance actions use this mutation service at their commit phase. A future combat/knockdown mechanic may also intentionally use the same mutation contract at its own approved action phase rather than pretending every stance change is voluntary.

### It does not own WHAT

The locomotion record may persist while its entity is temporarily unplaced. Tactical placement remains WHAT’s responsibility.

Locomotion state is not appended to `WorldEntityRecord` and does not create a generic foundation metadata dictionary.

## 9. Explicit actor enrollment / fail-closed rule

An entity does not silently receive locomotion capability merely because it occupies the ACTOR spatial channel.

An actor that should use this system must have an explicit locomotion record.

Rules:

- enrollment uses a stable valid entity ID;
- initial stance defaults to `standing` only when the caller explicitly enrolls the actor;
- duplicate enrollment is rejected rather than silently resetting state;
- a missing locomotion record is **ACTOR_UNCLASSIFIED**, not an implicit standing actor;
- a record may remain while the actor is unplaced;
- lifecycle cleanup is explicit rather than coupled to Godot Node deletion.

This makes missing actor-domain setup detectable instead of silently masking population/content bugs.

## 10. Stance actions and WHEN

`ActorStanceActionService` exposes semantic requests:

- `request_crouch(actor_id)`
- `request_stand(actor_id)`

Canonical sequence:

**request -> validate current actor/state/capability -> spend stance-action ticks -> revalidate expected locomotion version -> commit stance mutation**

Rules:

- actor must exist in WHAT;
- actor must currently have an ACTOR-channel placement for a tactical stance action;
- actor must have an explicit locomotion record;
- actor may not already have another active WHEN action;
- requesting the already-current stance returns a no-change result and consumes no ticks;
- capability providers may deny or modify the cost of a stance transition;
- accepted stance actions use WHEN `COMMITTED` interruption policy;
- hard application pause freezes the action normally with zero hidden tick advancement;
- stance mutation happens only at a semantic final `actor.stance.commit` phase;
- payload stores expected actor locomotion version + source stance + target stance;
- if locomotion version changed before commit, the stale action fails and does not overwrite newer state.

The golden prototype’s `STANCE_TICKS = 4` is the recommended initial base tuning value, not a WHEN constant.

## 11. Actor movement capability

`ActorMovementCapabilityService` answers actor-specific capability independently from terrain and occupancy.

It receives:

- actor ID;
- semantic action type;
- base duration ticks supplied by Movement/terrain policy where applicable.

It returns a typed decision containing at least:

- status;
- allowed boolean;
- resolved duration ticks;
- stable reason string;
- locomotion stance used for the decision.

Initial statuses should distinguish:

- `ALLOWED`;
- `ACTOR_UNCLASSIFIED`;
- `CAPABILITY_UNKNOWN`;
- `CAPABILITY_BLOCKED`;
- `INVALID_DURATION`.

Missing actor locomotion state fails closed as `ACTOR_UNCLASSIFIED`.

## 12. Initial timing model

Use deterministic integer fixed-point scales; no float is required for core timing.

Recommended planning scale:

- `10000` = 1.000x duration.

Recommended initial locomotion tuning recovered from the old prototype’s feel:

- standing walk: `10000` (1.0x terrain/base walking duration);
- crouched walk: `14000` (1.4x);
- standing turn: `10000` (1.0x Movement base turn duration);
- crouched turn: `10000` initially;
- voluntary stance change: base `4` ticks before external modifiers.

The existing Movement baseline of roughly 10 ticks for ordinary walking and 3 ticks for turning remains owned by Movement’s tuning/terrain policy, not by WHEN or ActorLocomotionState.

Final duration uses integer ceil division so a positive action never becomes zero ticks.

Exact balance values are tuning, not architectural constants, and may be changed without rewriting the contract.

## 13. Future capability contributor seam

Future systems should affect movement without ActorLocomotion importing their internals.

`ActorMovementCapabilityService` therefore supports registered **modifier providers** through the narrow `ActorMobilityModifierProvider` contract.

A provider has:

- stable unique provider ID;
- read-only evaluation for `(actor_id, action_type)`;
- allowed/blocked/unknown result;
- signed duration adjustment in basis points;
- stable reason when blocking/unknown.

Examples of future independently owned providers:

- Health provider: serious leg injury blocks running or increases step duration.
- Needs provider: fatigue increases movement/stance costs.
- Inventory provider: encumbrance increases movement cost or eventually blocks certain actions.
- Equipment provider: restrictive gear alters stance/movement.
- Skill/trait provider: modest deterministic movement adjustment where justified.

Those providers live with or beside their owning domain. The capability service knows only the provider contract, never wound dictionaries, inventory lists or fatigue variables.

### Deterministic aggregation

- provider IDs must be unique;
- providers are evaluated in sorted provider-ID order;
- any explicit BLOCKED result blocks the action;
- any UNKNOWN result fails closed if no stronger explicit domain result resolves it;
- duration adjustments combine additively in basis points so result does not depend on provider iteration order;
- combined scale must remain positive or the result is INVALID_DURATION;
- no provider may mutate another domain during capability evaluation.

## 14. Movement integration and required narrow contract revision

The existing `MovementActionService` public requests remain conceptually intact, but its current traversal-policy return shape is too terrain-specific to report actor-domain failures cleanly.

Implementation of 03 should therefore make one explicit narrow revision to the **02 Movement policy contract**, not redesign Movement itself.

### Add typed `MovementPolicyDecision`

`game/scripts/simulation/movement/MovementPolicyDecision.gd` should replace the current mix of Dictionary step results and integer-only turn results.

It should distinguish at least:

- `ALLOWED`;
- `TERRAIN_UNCLASSIFIED`;
- `TERRAIN_BLOCKED`;
- `ACTOR_UNCLASSIFIED`;
- `CAPABILITY_UNKNOWN`;
- `CAPABILITY_BLOCKED`;
- `INVALID_DURATION`.

It carries `duration_ticks` and a stable reason.

### Policy receives semantic movement action type

Proposed Movement policy API:

- `evaluate_step(actor_id, action_type, terrain_types) -> MovementPolicyDecision`
- `evaluate_turn(actor_id, action_type) -> MovementPolicyDecision`

The current simple `MovementTraversalPolicy` may ignore actor/action-specific facts and continue to provide terrain/base behavior.

`ActorMovementTraversalPolicy` composes/delegates that base terrain policy, then applies ActorMovementCapabilityService.

`MovementActionService` remains the owner of collision checks, WHEN submission, commit-time revalidation and WHAT placement mutation.

### MovementActionResult status extension

Movement request results should gain explicit actor/capability failure statuses rather than mislabeling them as terrain failures.

This is a contract extension only; forward/back/left/right semantics and the no-reservation/commit-revalidation rules remain unchanged.

## 15. Commit-time capability revalidation

Movement already rechecks terrain/collision at commit. Actor-aware policy should also re-evaluate current capability at that point.

Rules:

- if the actor becomes incapable of the action before commit, the move fails after elapsed time and does not mutate WHAT;
- if the actor is still capable but a newly changed condition would merely make future movement slower, the already-scheduled action is **not rescheduled or stretched**;
- the new duration applies to the next action.

This avoids scheduler rewrites and preserves the meaning of committing an action duration at request time while still allowing a severe new condition to invalidate the physical result.

Normal stance mutation cannot occur mid-movement because the actor is already busy in WHEN. Direct store mutation is not public gameplay API.

## 16. Signals / observation

Actor locomotion should expose mechanic-level signals such as:

- actor locomotion record enrolled/removed;
- stance changed with actor ID, previous stance, new stance and locomotion version.

These signals report simulation facts only.

Future renderer, perception, sound and UI systems may observe them without locomotion knowing presentation rules.

## 17. Persistence and restore

`ActorLocomotionState` snapshot requirements:

- explicit schema version;
- deterministic actor-ID ordering;
- semantic stance values;
- per-actor versions;
- store revision;
- atomic validation/restore;
- no Godot Node/object references;
- no copied health/inventory/fatigue state.

Occupancy/placement is not serialized here because WHAT already owns it.

Pending stance actions are not separately serialized here; WHEN owns pending action timing/payload. This avoids a second action truth.

## 18. Failure / edge cases

The implementation must define deterministic behavior for:

- actor ID missing from WHAT;
- actor exists but has no locomotion record;
- actor locomotion record exists while entity is currently unplaced;
- actor placement is not ACTOR channel;
- actor already busy in WHEN;
- stance request equals current stance;
- malformed/unknown stance value;
- modifier provider duplicate ID;
- modifier provider reports UNKNOWN/BLOCKED;
- combined duration scale becomes non-positive;
- actor locomotion version changes during pending stance action;
- actor is removed before stance commit;
- hard pause during stance action;
- malformed snapshot restore.

No case should silently coerce unknown actor state into a normal standing/walking actor.

## 19. Performance

Normal locomotion/capability work is O(1) for state lookup plus O(P) for the small number of registered capability providers.

Requirements:

- no full-world scan during normal movement requests;
- no per-frame polling;
- no Node per locomotion state;
- providers are read-only during evaluation;
- snapshot/diagnostic scans may be O(number of locomotion records) because they are not per-action hot paths.

## 20. Safari / mobile

No Safari-specific input logic belongs here.

Future touch/keyboard adapters decide when to emit crouch/stand or movement intents. One physical touch remains one semantic action. Hard application pause behavior remains owned by WHEN/application lifecycle.

## 21. Historical recovery

Golden source inspected:

- `PlayerActor.gd` blob `2f839f1a50041c8bd00e144c1a9389d0a33d1401` from recovery commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Useful recovered concepts:

- standing walk around 10 ticks;
- crouch walk around 14 ticks;
- turn around 3 ticks;
- stance change around 4 ticks;
- crouching prevents running;
- movement cost can be modified by fatigue/encumbrance-like conditions.

Rejected golden architecture:

- one `PlayerActor` owning identity, location, facing, movement mode, crouch, health, carry weight, capacity, encumbrance and fatigue;
- player-only state rather than shared actor semantics;
- direct float ratios as the long-term cross-system contract;
- persistent RUN mode as physical simulation state.

## 22. Future extension points

This contract intentionally leaves room for:

- future `movement.run_forward` once real fatigue/sound/etc. consequences exist;
- additional stances only if gameplay justifies them;
- health/body mobility provider;
- needs/fatigue provider;
- inventory/encumbrance provider;
- equipment/skill providers;
- sound generation based on actual movement action + stance;
- perception/visibility based on stance;
- animation selection based on stance/action;
- AI using the same locomotion and stance actions as the player;
- combat/knockdown forcing stance changes through the locomotion mutation contract;
- save orchestration restoring WHAT + ActorLocomotionState + WHEN without hidden state.

None of those systems is implemented merely to prove the seam.

## 23. North-star fit

This design preserves the meaningful survival decision—standing is faster, crouching costs time and makes movement slower, future injuries/fatigue/encumbrance can matter—without turning the project into a physiological simulator or a giant actor-state object.

It serves **Ultima-style turn-based mini Zomboid** by making actor posture and movement consequences persistent, deterministic and shared by player/NPC actors while keeping each deeper survival domain independently replaceable.

## 24. Proposed decisions awaiting user approval

The following are recommendations in this DRAFT and are **not locked until explicitly approved**:

1. Narrow the system to **Actor Locomotion State & Movement Capability**, rejecting a generic ActorState owner.
2. Persist only `standing` / `crouched` stance in this slice.
3. Do not persist RUN as actor state; future running is an actual movement action.
4. Do not implement running until real consequences such as fatigue/sound exist.
5. Make actor locomotion enrollment explicit and missing state fail closed.
6. Make crouch/stand timed COMMITTED actions; recommended base stance-change cost 4 ticks.
7. Use standing walk 1.0x and crouched walk 1.4x as initial tuning; keep turns 1.0x.
8. Use integer basis-point modifiers and a deterministic external capability-provider seam.
9. Future health/fatigue/inventory/etc. contribute movement modifiers without ActorLocomotion importing their internals.
10. Revise Movement’s internal policy contract to a typed `MovementPolicyDecision` with explicit actor/capability failure states and semantic action type input.
11. Revalidate capability at movement commit, but do not reschedule an already-started move solely because a new condition would make future moves slower.
12. Keep the frozen `game/scripts/reboot/` runtime untouched during this canonical subsystem implementation.
