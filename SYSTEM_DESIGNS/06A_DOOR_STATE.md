# Tick Survival Lab — 06A Door State

Status: **IMPLEMENTED — canonical Door State domain and dedicated Godot CI contract present 2026-08-16**

Approval basis: while designing `06_STRUCTURE_LAYER_RENDERER.md`, canonical source was found to have no authoritative door open/closed state. The user first approved Door State as the prerequisite, then explicitly authorized implementation of both Door State and Structure with **“Program both”** on 2026-08-16.

## 1. Goal

Own the authoritative persistent **OPEN / CLOSED** state of door entities by stable WHAT entity ID.

The system provides a small, deterministic, snapshot-safe read/write contract that Structure rendering and future door interaction, collision synchronization, perception, sound, AI, and save orchestration can consume without any of those systems becoming the owner of door state.

Missing/unclassified door state is explicit **UNKNOWN**. A door is never silently assumed closed.

## 2. Why this is separate from WHAT and Collision

WHAT intentionally owns foundation identity/type/placement only. Mechanic-specific durable state attaches through typed stable-ID systems rather than a universal metadata bag.

Collision owns movement blocking, not the reason an entity currently blocks. An open door may later cause a collision override, but `blocks_movement == false` is not proof that a door is open and must never become visual/simulation door truth.

Door State therefore owns only the physical open/closed fact.

## 3. Non-goals

06A does **not** implement:

- player/NPC door interaction;
- open/close/toggle action requests;
- WHEN timing or action phases;
- animation timing;
- collision override synchronization;
- opacity/line-of-sight behavior;
- sound/noise events;
- lock/key state;
- jammed/stuck state;
- broken/destroyed/barricaded state;
- automatic opening;
- AI decisions;
- rendering or Art Catalog selection;
- door generation/placement;
- construction/destruction;
- input/UI;
- frozen reboot compatibility.

Those are later systems consuming this state contract.

## 4. Owners

Canonical source:

- `game/scripts/simulation/doors/DoorStateValue.gd` — semantic OPEN/CLOSED/UNKNOWN vocabulary and validation.
- `game/scripts/simulation/doors/DoorStateRecord.gd` — immutable-style stable-ID door state record with per-door version.
- `game/scripts/simulation/doors/DoorStateStore.gd` — authoritative record store, mutation-safe reads, signals, revision, deterministic snapshot/restore.
- `game/scripts/simulation/doors/DoorStateMutationService.gd` — validated normal write path.
- `game/scripts/ci/DoorStateSmoke.gd` — independent contract smoke.
- `.github/workflows/door-state.yml` — dedicated Godot 4.7.1 contract.

No Godot Node is required per door.

## 5. State vocabulary

`DoorStateValue` exposes stable semantic `StringName` values:

- `OPEN = &"open"`
- `CLOSED = &"closed"`
- `UNKNOWN = &"unknown"`

Only OPEN and CLOSED are valid stored states.

UNKNOWN is a **query result for missing/unclassified state**, never a persisted door record.

Snapshot data stores semantic strings (`"open"` / `"closed"`), not enum integers whose meaning could drift if enum ordering changes.

## 6. Record contract

Each `DoorStateRecord` contains only:

- `door_id: String` — stable WHAT entity ID;
- `state: StringName` — OPEN or CLOSED;
- `version: int` — positive monotonic per-door mutation version.

The record contains no placement, theme, axis, collision, lock, health, sound, art, actor, or timing data.

Reads return copies so external consumers cannot mutate canonical state through a returned record.

## 7. Store read contract

`DoorStateStore` exposes:

- `revision() -> int`
- `has_door(door_id) -> bool`
- `door_ids() -> Array[String]` sorted deterministically
- `record(door_id) -> DoorStateRecord` copy or null
- `state(door_id) -> StringName`
- `version(door_id) -> int`

### Missing-state rule

If no record exists:

- `has_door()` returns false;
- `state()` returns `DoorStateValue.UNKNOWN`;
- `version()` returns 0.

Consumers must never coerce UNKNOWN to CLOSED.

## 8. Explicit enrollment

Door state is **explicitly enrolled**.

Normal enrollment requires:

- valid stable entity ID;
- corresponding entity exists in canonical WHAT;
- entity semantic type belongs to the canonical `door.<theme>` family;
- caller supplies an explicit initial OPEN or CLOSED state;
- no existing door-state record for that ID.

There is **no default initial state parameter**.

This deliberately makes generator/content omissions visible. A content producer that intends most doors to begin closed must explicitly enroll them CLOSED.

Door state may exist while the door entity is unplaced. Tactical placement is WHAT's responsibility and is not required for persistent door state after enrollment.

## 9. Normal mutation path

Gameplay/content code does not mutate `DoorStateStore` internals directly.

`DoorStateMutationService` is the validated normal write path and is constructed with:

- `DoorStateStore`;
- read-only `WorldState` for entity/type validation.

Initial API:

- `enroll(door_id, initial_state) -> bool`
- `remove(door_id) -> bool`
- `set_state(door_id, target_state) -> bool`

Rules:

- enrollment validates the WHAT entity and canonical door semantic family;
- `set_state` requires an existing door record, valid current WHAT door identity, and OPEN/CLOSED target;
- same-state `set_state` succeeds as a no-op without revision/version/signal changes;
- state mutation never changes WHAT placement or Collision;
- removal is explicit and may clean up a state record even if the WHAT entity has already been removed by an owning lifecycle coordinator.

The mutation service is a low-level mechanic write contract, **not** a gameplay interaction action. Future door interaction must call it only at its approved commit point.

## 10. Revisions and stale-action protection

The store owns a monotonic global revision.

Each door record owns a positive version.

Successful enrollment, removal, or actual OPEN/CLOSED change increments the store revision.

An actual state change replaces the record with `version + 1`.

Enrollment chooses a version greater than prior store mutation history, so removing and later re-enrolling the same stable door ID cannot accidentally recreate an old version.

This supports a future timed Door Action contract that can store:

- expected door ID;
- expected version;
- expected source state;
- target state;

and reject stale commits if another causal event changed the door first.

06A itself does not implement that action.

## 11. Signals

Simulation-level signals:

- `door_enrolled(door_id, state, version)`
- `door_removed(door_id, previous_state, version)`
- `door_state_changed(door_id, previous_state, new_state, version)`
- `door_state_reset`

Signals expose semantic state only. They contain no rendering behavior or collision side effects.

Structure Renderer 06 consumes enrollment/removal/change/reset read-only for event-driven redraw.

Future gameplay coordinators may observe changes, but authoritative cross-system mutations such as Collision synchronization should be performed deliberately by the future owning Door Interaction/Physical Transition service rather than hidden inside a signal listener whose ordering could become gameplay-significant.

## 12. Snapshot / persistence boundary

`DoorStateStore.snapshot()` returns deterministic serializable data:

- schema version;
- global store revision;
- records sorted by stable door ID;
- each record's stable door ID;
- semantic OPEN/CLOSED state string;
- per-door version.

`load_snapshot()`:

- validates schema/version values;
- rejects invalid IDs;
- rejects duplicate IDs;
- rejects UNKNOWN or any unrecognized stored state;
- rejects non-positive record versions and impossible record-version/revision combinations;
- validates the complete candidate before replacing current state;
- restores atomically;
- emits one `door_state_reset` after success.

Snapshot restore does not require current tactical placement. Save orchestration is responsible for restoring compatible WHAT and Door State domains in an appropriate order.

The store does not serialize Collision overrides, art, placement, or action timing.

## 13. WHAT consistency boundary

Door State does not subscribe to WHAT and does not automatically destroy records when WHAT changes.

Why:

- mechanic stores should not secretly own WHAT lifecycle;
- restore/streaming sequences may temporarily load domains in different orders;
- a door may validly be persistent while unplaced.

Normal enrollment/state mutation uses the mutation service's WHAT validation. Explicit record cleanup belongs to the lifecycle/content coordinator that removes the physical door entity.

An orphan Door State record is invalid cross-domain content but is not silently deleted by this store.

## 14. Collision synchronization boundary

06A deliberately does **not** update `CollisionOverrideState`.

Future expected physical rule:

- closed door -> door type's normal blocking behavior;
- open door -> appropriate non-blocking collision override;
- returning closed -> override may clear back to the type default.

But that coordination must occur in a separately approved door physical-transition/action owner so Door State and Collision are committed coherently at one semantic action phase.

The renderer reads Door State; Movement reads Collision. Neither infers the other's truth.

## 15. Future Door Interaction seam

A later Door Interaction Action system is expected to consume:

- WHAT door entity/placement/axis;
- Door State read/write contract;
- WHEN action timing;
- Collision override state;
- actor reach/interaction legality when designed.

Likely sequence:

**request -> validate door/current state -> spend ticks -> revalidate expected door version -> commit Door State + collision consequence**

Exact tick cost, interruption policy, locked doors, noise, AI opening, and perception effects are intentionally not decided by 06A.

## 16. Dependencies

Allowed production dependencies:

- stable WHAT entity-ID validation;
- read-only WHAT entity lookup for normal mutation validation.

No WHERE placement dependency is required by the core state store.

## 17. Forbidden dependencies

06A production code does not import or inspect:

- renderers or Art Catalog;
- Collision / `CollisionOverrideState`;
- WHEN / TickKernel;
- Movement / Actor Locomotion;
- input/UI;
- generation/prefab internals;
- reboot runtime;
- camera;
- perception/lighting/weather/sound;
- AI;
- inventory/keys/locks;
- construction/destruction.

## 18. Failure / edge cases

Handled explicitly:

- invalid stable ID;
- missing WHAT entity on enrollment;
- non-door WHAT entity on enrollment;
- missing record query -> UNKNOWN;
- duplicate enrollment;
- UNKNOWN/invalid target state;
- same-state no-op;
- record persists while entity is unplaced;
- explicit removal;
- removal followed by re-enrollment of same stable ID gets a newer version;
- malformed snapshot;
- duplicate snapshot IDs;
- UNKNOWN stored in snapshot;
- orphan record after external WHAT removal remains detectable state, not silently reclassified.

## 19. Performance / mobile

- O(1) state lookup by stable door ID;
- no Node per door;
- no per-frame polling;
- no full-world scan during ordinary reads/mutations;
- snapshot O(number of enrolled doors) is acceptable;
- signals are event-driven;
- no Safari/input behavior belongs in Door State.

This remains suitable for a large persistent world where many doors may exist but only a small visible subset is rendered tactically.

## 20. Verified acceptance

The first complete implementation head `2c69a98633b7a8bccfa64001921e0a6a19b36583` passed the dedicated **Door State contract** under Godot 4.7.1 with no production repair required.

Verification covers:

- source-boundary isolation;
- project import/parse;
- WHAT and Collision regression smokes;
- explicit OPEN and CLOSED enrollment with no default state path;
- missing record -> UNKNOWN;
- duplicate/missing/non-door enrollment rejection;
- mutation-safe record copies;
- same-state no-op semantics;
- OPEN/CLOSED version + revision changes and exact semantic signals;
- persistent unplaced door state;
- explicit orphan cleanup;
- remove/re-enroll stale-version protection;
- deterministic sorted IDs and snapshot order;
- deterministic atomic snapshot round-trip;
- malformed/duplicate/UNKNOWN/bad-version snapshot rejection;
- successful restore reset signaling.

## 21. Recovery source

Golden recovery source:

- commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`
- `LocalWorldState.gd` blob `f8fd11ebbf0ff2b3958fd46000404cbb12142fc5`

Useful recovered fact:

- each golden door had explicit persistent `bool` open/closed state;
- movement queried that state separately from walls/obstacles.

Rejected golden architecture:

- coordinate-keyed local dictionaries as authoritative world identity;
- one `LocalWorldState` object mixing doors, walls, glass, obstacles, map bounds, and collision behavior;
- door state keyed by cell rather than stable persistent door entity ID.

06A preserves the solved semantic fact while fitting current WHAT stable-ID architecture.

## 22. Future extensions deliberately deferred

Possible later typed state/systems include:

- lock/key/access state;
- door durability/damage/destruction;
- barricades;
- powered/electronic doors;
- automatic doors;
- noise/sound consequences;
- opacity/perception consequences;
- AI interaction;
- door animation/VFX.

Do not overload OPEN/CLOSED with these meanings. Add future state only when its owning gameplay system is designed.

## 23. North-star fit

A persistent survival world needs doors to remain physically what happened to them when the player leaves and returns. The smallest causal model is an explicit stable-ID OPEN/CLOSED state with UNKNOWN for missing data.

This preserves consequence and persistence without recreating a detailed door simulator, and it keeps rendering, collision, action timing, AI, generation, and perception independently replaceable.

## 24. Approved decisions

Approved and authorized by the user on 2026-08-16:

- Door State is the canonical prerequisite for Structure rendering;
- stable door ID -> explicit OPEN/CLOSED persistent state;
- missing state is UNKNOWN, never implicit CLOSED;
- explicit enrollment has no default initial state;
- per-door versions provide a stale-action seam;
- state is independent from Collision/WHEN/rendering;
- low-level mutations validate current WHAT door identity where applicable;
- orphan cleanup is explicit;
- implementing Door State and Structure together was explicitly authorized with **“Program both”**.