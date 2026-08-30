# Tick Survival Lab — 00C Tick / Action / Pause Kernel (WHEN)

Status: **IMPLEMENTED — canonical foundation module as of 2026-08-16**

Parent architecture: `00_FOUNDATION_WHERE_WHAT_WHEN.md`.

Approval basis: after WHERE and WHAT were implemented, the user explicitly instructed: **“Now go when. I assume this is the tic system.”** This authorized the bounded WHEN system only. Calendar/date presentation, movement, AI, health, weather, rendering, input/lifecycle adapters and live-runtime integration remain separate future slices.

## 1. Goal

Define the authoritative deterministic simulation clock and execution-order kernel for Tick Survival Lab.

WHEN owns:

- integer world ticks;
- scheduled simulation events;
- variable-duration actor actions;
- action progress/checkpoints;
- interruption/resume/cancel/failure timing semantics;
- deterministic same-tick ordering;
- tactical player-decision auto-pause;
- hard real-life application pause;
- deterministic in-memory snapshot/restore of timing state.

WHEN deliberately does **not** know what movement, combat, doors, health, weather, AI or other mechanics mean.

## 2. Core rule

> **There is one authoritative simulation clock.**

Player actions, infected actions, NPC actions, healing checks, weather changes, fire spread, generator fuel use, alarms, crop events and distant/coarse population actions all schedule work against the same integer world tick.

Rendering frame rate and wall-clock time never advance simulation by themselves.

## 3. Non-goals

WHEN does not implement:

- movement/collision/pathfinding;
- actor AI or player input;
- combat/damage/health;
- doors/locks/interactions;
- inventory/loot/search;
- weather choice/state;
- lighting/vision/sound;
- vehicles;
- construction;
- world generation;
- rendering/UI;
- streaming/materialization;
- calendar/date formatting;
- browser/mobile focus detection itself;
- WHAT mutations.

Those systems submit/schedule semantic work through WHEN and react to WHEN signals through their own owners.

## 4. Dependency direction

WHEN is a parallel foundation service.

It has **no direct dependency on WHERE or WHAT internals**.

Actor/subject/source IDs are opaque stable strings supplied by callers. Gameplay systems may pass WHAT entity IDs, but WHEN does not import `WorldState`, `WorldEntityRecord`, placement, spatial geometry or any gameplay record.

Forbidden dependencies:

- reboot runtime;
- renderer/art;
- generator;
- input/UI;
- movement/collision;
- health/combat/inventory/door/vehicle/construction/weather/lighting/perception/sound;
- Godot frame-time gameplay loops.

## 5. Owner modules

Canonical implementation lives under `game/scripts/foundation/time/`.

- `TickRules.gd` — enums/constants and shared timing validation.
- `ActionPhase.gd` — immutable-style semantic checkpoint value.
- `TimedAction.gd` — actor action timing/progress/status value.
- `ScheduledEvent.gd` — deterministic scheduled queue record.
- `TickEventQueue.gd` — deterministic min-heap queue and cancellation tombstones.
- `TickKernel.gd` — public orchestration facade: clock, actions, events, pauses, dispatch signals, snapshots.
- `game/scripts/ci/TickKernelSmoke.gd` — independent contract test.

No Main/root behavior belongs here.

## 6. Integer world ticks

`world_tick` is a non-negative integer.

WHEN does not decide how many real seconds/minutes one tick represents. A later calendar/time-presentation system may map ticks to dates and clock time without changing scheduling semantics.

Rules:

- time never moves backward during normal execution;
- an action duration is an integer number of ticks;
- gameplay actions require duration >= 1 tick;
- scheduled events may be due at the current tick or any future tick;
- no event may be scheduled in the past;
- hard pause advances zero ticks.

Zero-cost UI/inspection behavior should remain outside simulation rather than becoming a zero-duration gameplay action.

## 7. Scheduled events

A `ScheduledEvent` contains foundation timing facts only:

- stable monotonic event serial;
- due tick;
- narrow integer priority (default `0`);
- stable owner/source key;
- semantic event type;
- optional subject ID;
- opaque serializable payload owned by the caller;
- internal event kind where needed for action checkpoint/completion scheduling.

Public callers may schedule only ordinary external events. Internal action phase/completion queue entries are created by `TickKernel`.

Payload is transport data, not persistent domain state. WHEN deep-copies it and never interprets mechanic-specific fields.

## 8. Deterministic queue ordering

Queue order is:

1. due tick ascending;
2. priority ascending;
3. owner/source key lexical ascending;
4. insertion serial ascending.

Default priority is `0`. Non-default priority exists as an extension seam but should be introduced sparingly by later approved system designs; priority must not become a hidden substitute for explicit physical rules.

Dictionary iteration order, frame timing and signal-connection order do not determine queue ordering.

`TickEventQueue` uses a min-heap rather than full-world/per-tick scanning.

## 9. Same-tick batch rule

A critical invariant:

> **Once world time reaches tick T, every event due at T is drained before tactical player-decision auto-pause may engage.**

This includes events scheduled for the same current tick by another event handler while the batch is being processed.

Why:

- a player action completing at tick 100 must not grant a decision before another already-due tick-100 event;
- same-tick results are deterministic rather than dependent on which queue item happened to be processed first.

A bounded operation guard prevents an accidental infinite same-tick rescheduling loop from hanging the game. Hitting the guard is an explicit kernel stop/failure condition, not silent time advancement.

## 10. Actions are timed work, not mechanic implementations

A `TimedAction` represents one committed action by one actor/source.

It contains:

- stable action serial;
- actor ID;
- semantic action type;
- total duration;
- accumulated elapsed ticks;
- current running-segment start tick;
- status;
- interruption policy;
- ordered semantic phase/checkpoint records;
- next pending phase index;
- opaque serializable payload;
- interruption/failure reason where applicable.

WHEN knows timing only. The gameplay owner decides requirements, cost calculation and physical effects.

## 11. One active action per actor, many actors concurrently

An actor may have at most one active/running action at a time.

The kernel may hold many active actions for different actors concurrently.

This deliberately replaces the golden scheduler's global single-active-player-action assumption.

Examples:

- player begins a 12-tick reload;
- infected A has a 5-tick move finishing during it;
- infected B has an 8-tick attack phase;
- a weather event is due at the same world tick;
- all are ordered through the same queue.

An actor with no active action is simply ready/idle. WHEN does not decide what AI should do next.

## 12. Decision actor and tactical auto-pause

WHEN supports one configurable **decision actor ID** for current single-player tactical control.

Rules:

- when the decision actor has no active action and a decision is pending, simulation is tactically auto-paused;
- beginning a valid action for the decision actor clears tactical auto-pause;
- the kernel advances until that actor becomes ready again, a hard pause is asserted, the queue becomes idle, or a safety stop occurs;
- decision pause is applied only after the entire current-tick batch is drained;
- changing the decision actor later is supported through an explicit setter and does not change entity identity.

Held movement remains an input concern: input may immediately submit another ordinary movement action each time the decision actor becomes ready. WHEN never knows that a key/button is being held.

## 13. Action phases/checkpoints

`ActionPhase` is defined by:

- semantic phase ID;
- absolute `offset_ticks` from action start/progress zero.

Rules:

- phase offsets must be >= 1 and <= total action duration;
- phase offsets are strictly increasing after canonical sorting/deduplication;
- simple actions may have no explicit phases and only complete at duration;
- phases at the total duration are delivered before final completion at the same tick through deterministic internal serial ordering.

When a phase becomes due, `TickKernel` emits a semantic phase signal with a copy of the action and phase. The owning gameplay system may then mutate WHAT through its own contract.

The scheduler does not know what “magazine removed”, “bandage applied” or “door opened” means.

## 14. Interruption policies

Three policies are canonical:

### COMMITTED
Ordinary interruption requests are recorded/notified but the action continues. An explicit forced failure may still stop it.

### RESUMABLE
The action stops with elapsed progress preserved. It may later resume from the same accumulated elapsed ticks; only remaining phase checkpoints are rescheduled.

### CANCELABLE
The action stops and cannot be resumed through WHEN. Any partial physical effects already committed at earlier phases remain whatever their owning gameplay system wrote to WHAT.

WHEN never hardcodes causes such as “damage cancels reload.” Another system issues an interruption request; the action's declared policy determines the timing response.

## 15. Action lifecycle/status

Canonical statuses:

- RUNNING;
- COMPLETED;
- INTERRUPTED;
- CANCELED;
- FAILED.

Completed/canceled/failed actions leave the active-action set and emit completion/status signals.

A RESUMABLE interrupted action remains stored as resumable timing state but is not active and occupies no future queue entries until resumed.

Actions are addressed by stable monotonic serial; actor lookup is also supported.

## 16. Hard application pause

Hard pause is separate from tactical auto-pause.

`set_hard_paused(true)` freezes **all** simulation advancement immediately:

- current world tick does not change;
- running action progress does not change;
- queued events remain queued;
- no phases/completions dispatch;
- outbreak/healing/weather/etc. cannot advance through WHEN.

Hard pause may occur halfway through an action; resume continues from exactly the same simulation tick/progress.

WHEN exposes the pause mechanism only. Future app/input/Safari lifecycle owners decide when focus loss/backgrounding should call it.

## 17. Running the kernel

Public execution is explicit, not `_process()` driven.

`run_until_stop(max_operations)` advances deterministically by jumping directly to the next due tick rather than iterating every empty tick.

Stop reasons include:

- decision required;
- hard paused;
- idle/no scheduled work;
- safety operation limit.

The kernel may also process one due-tick batch for tests/dev orchestration.

This keeps simulation independent of render FPS and avoids full-world per-frame/per-tick loops.

## 18. Dispatch contract

`TickKernel` emits signals for external consumers:

- external scheduled event due;
- action started;
- action phase reached;
- action interrupted/canceled/failed/completed;
- decision required;
- world tick advanced;
- hard-pause changed;
- timing state reset/restored.

Signals carry mutation-safe copies/snapshot-like records. External systems do not receive the mutable queue/action internals.

Signal handlers may synchronously schedule additional current/future events or submit a new non-conflicting action. Same-current-tick work joins the current batch and is processed before decision pause.

## 19. Snapshot / restore

WHEN provides a deterministic in-memory snapshot dictionary. It is not the final user save-file codec.

Snapshot includes:

- schema version;
- current world tick;
- next event serial;
- next action serial;
- configured decision actor ID;
- tactical decision-pause state;
- hard-pause state;
- active/running actions;
- resumable interrupted actions;
- all pending queue events.

Derived/debug data is not authoritative and need not be serialized.

Restore is atomic:

1. validate complete snapshot into temporary records/queue;
2. reject malformed IDs/ticks/statuses/phases/references/duplicates;
3. ensure queue internal action events reference valid action state;
4. replace canonical timing state only after full validation;
5. emit one timing-state reset/restored signal.

A failed restore leaves the existing kernel untouched.

## 20. Determinism

- all serials are monotonic integers;
- queue ordering uses explicit keys;
- actions/events expose deterministic snapshot ordering;
- restore preserves next-serial values;
- same snapshot + same sequence of submitted semantic work produces the same timing order;
- no RNG exists inside WHEN.

Random outcomes belong to owning gameplay systems with their own deterministic RNG contracts.

## 21. Debug trace

WHEN keeps a **bounded** recent trace for diagnostics/tests rather than an unbounded history.

Trace may record:

- tick advancement;
- event dispatch;
- action start;
- phase dispatch;
- interruption/status change;
- decision pause/hard pause transitions.

The trace is not source of truth and is not required in snapshots.

## 22. Performance

- no `_process()`;
- no frame-time simulation;
- no full-world scan;
- jump directly between due ticks;
- min-heap queue for scheduled work;
- active-action lookup keyed by serial and actor;
- cancellation uses queue tombstones/lazy cleanup rather than resorting the full queue;
- trace is bounded;
- snapshot work is proportional to timing state actually stored.

The design supports coarse distant actions lasting hundreds/thousands of ticks without simulating invisible individual footsteps.

## 23. Safari/mobile requirements

The kernel itself is platform-neutral.

It must make mobile/browser interruption safe by exposing an immediate hard-pause API that requires no frame/tick advancement to take effect.

Future Safari/app lifecycle code must be able to call hard pause without importing timing internals.

## 24. Historical recovery

Golden source:

- commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`;
- `game/scripts/TickScheduler.gd` blob `0d1efa7f76ca58a0357fd9a3d0703320b2ad8d69`.

Recovered concepts:

- authoritative `world_tick`;
- explicit action cost;
- player-ready pause;
- phase/progress tracking;
- COMMITTED/RESUMABLE/CANCELABLE-style interruption semantics;
- resumable progress;
- deterministic actor timing;
- snapshots;
- event trace.

Deliberately rejected old constraints:

- one globally active action;
- player-centric action ownership;
- direct list of scheduled actor objects with methods/Node-like runtime behavior;
- queue ordering tied only to actor objects;
- unbounded trace as durable state.

## 25. Future extension seams

Known future consumers can attach without changing WHEN's mechanic meaning:

- movement/turning;
- infected/NPC AI;
- combat windup/recovery;
- health/healing/infection progression;
- searching/inventory transfer;
- construction/repair;
- weather;
- power/fuel/water;
- fire;
- crops;
- alarms;
- vehicles/coarse travel;
- distant population/outbreak events;
- world calendar/date display;
- save-file persistence;
- Safari/app lifecycle hard-pause adapter.

## 26. Tests / acceptance criteria

Dedicated `TickKernelSmoke.gd` proves:

1. integer world tick starts/restores correctly;
2. deterministic queue ordering by tick/priority/owner/serial;
3. events jump directly across empty time;
4. same-current-tick events scheduled during dispatch are drained in the same batch;
5. decision actor auto-pause occurs only after the full due-tick batch;
6. one active action per actor is enforced while different actors can act concurrently;
7. variable-duration action completion occurs at exact ticks;
8. ordered action phases fire at exact offsets;
9. COMMITTED ignores ordinary interruption but forced failure stops;
10. RESUMABLE preserves elapsed progress and remaining phases;
11. CANCELABLE stops and cannot resume;
12. hard pause advances zero ticks and preserves mid-action progress;
13. event cancellation prevents dispatch;
14. malformed/past events are rejected;
15. snapshots round-trip deterministically;
16. malformed snapshot restore is atomic;
17. action/event serial allocation continues without collision after restore;
18. bounded operation guard stops pathological same-tick rescheduling;
19. no dependency on reboot, WHERE internals, WHAT internals, generator, renderer or gameplay modules;
20. WHERE and WHAT contract smokes plus frozen-reference smokes continue to pass.

## 27. North-star fit

WHEN is the foundation that makes **turn-based persistent zombie survival** mechanically true rather than a UI illusion.

Slow actions create exposure because other scheduled work may resolve before completion. Health/fatigue/equipment can later change action duration without modifying the kernel. Distant people/outbreak systems can schedule coarse causal events on the same world clock. The player can think indefinitely at decision points, while hard pause guarantees real-life interruptions never consume simulation time.

The kernel stays small in meaning even though many future systems use it: **it owns when, never why or what happened.**

## 28. Approved decisions

2026-08-16:

- WHEN is the third bounded foundation implementation after WHERE and WHAT;
- one non-negative integer world tick is authoritative;
- render FPS/wall clock never advance simulation implicitly;
- no fixed tick-to-real-time/calendar mapping in WHEN;
- deterministic scheduled-event min-heap shared by actors and world systems;
- full same-tick batch drains before tactical decision pause;
- one active action per actor, many actors/actions may coexist;
- configurable single decision actor for current single-player control;
- gameplay actions require at least one tick;
- phases use semantic absolute offsets and dispatch mechanic-agnostic signals;
- COMMITTED / RESUMABLE / CANCELABLE interruption policies;
- hard application pause is distinct from tactical auto-pause and advances zero ticks;
- explicit run calls jump between due ticks; no `_process()` simulation loop;
- deterministic atomic in-memory snapshot/restore;
- bounded debug trace;
- opaque payload transport is serializable copied data, not a domain-state metadata store;
- no direct WHERE/WHAT/gameplay/reboot dependency inside WHEN.

## 29. Implementation verification

Implemented owners:

- `game/scripts/foundation/time/TickRules.gd`
- `game/scripts/foundation/time/ActionPhase.gd`
- `game/scripts/foundation/time/TimedAction.gd`
- `game/scripts/foundation/time/ScheduledEvent.gd`
- `game/scripts/foundation/time/TickEventQueue.gd`
- `game/scripts/foundation/time/TickKernel.gd`
- `game/scripts/ci/TickKernelSmoke.gd`

The dedicated WHEN contract smoke passed under Godot 4.7.1 together with WHERE and WHAT contract smokes, frozen-reference smokes, startup and Web export before this status was promoted. The canonical WHEN implementation remains intentionally unwired from the deprecated playable reboot runtime.
