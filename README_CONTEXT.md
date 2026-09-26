# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2 EIGHT-INFECTED CALLBACK/PERCEPTION PERFORMANCE BOUNDED — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows, Phase 2B simultaneous melee consequences, Phase-2C causal movement/shove/death ordering, the closed mob-force core, and canonical fear remain protected.

This operation targeted the existing production eight-infected cohort only. It measured real callback/perception cost, removed proven redundant work, and kept infected behavior intentionally simple.

Starting main for this operation: `f61a7318e936cd92f0d6703815a148b505b9b572`.

Functional/executable owning head: `cd28fae78d5bdc80df5721f674265deeb69f4085`.

Focused verifier owning head/run: `4d674f25a00d4c454a40f2652f43fa02cc29e891` / `36206781574` — **SUCCESS**.

Functional-head Pages run: `36206781364` — **SUCCESS**.

Documentation head immediately before this final handoff write: `13f996fc1713a42b6b192480c1a2e496bc4d240b`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous canonical-fear pair was deleted before performance code work:

- `game/scripts/ci/Phase2FearSmoke.gd`
- `.github/workflows/phase2-fear.yml`

Fresh current pair:

- `game/scripts/ci/Phase2InfectedPerceptionPerfSmoke.gd`
- `.github/workflows/phase2-infected-perception-perf.yml`

The next code prompt must delete this pair before changing code and create a fresh focused verifier/workflow for overlapping consequence presentation.

## Completed — measured the real eight-infected route first

The first focused production route used one ordinary player turn with the real active cohort.

Baseline run `36200438756` measured:

```text
active infected          = 8
elapsed_usec             = 269034
perception_recomputes    = 8
behavior_evaluations     = 8
ordinary submissions     = 0
```

That established a real cost rather than assuming more AI architecture was needed.

Inspection then showed a concrete duplication:

- System 23 already recomputed observer truth on relevant world/perception changes;
- infected behavior still explicitly requested another recompute whenever it drove from a player commitment.

No horde manager, scheduler or perception budget queue was justified.

## Completed — event-driven perception freshness

`ObserverPerceptionService` now distinguishes current observer truth from stale truth.

Behavior calls:

`recompute_if_stale(...)`

instead of forcing a full recompute every decision.

Freshness is still invalidated by real dependencies.

This optimization never allows actor callback/order to decide perception truth.

## Completed — acquisition freshness remains correct

Visual acquisition depends on physical lighting, so merely caching by world tick was not sufficient.

System 23 now tracks the acquisition provider's freshness revision separately from geometric/world dirtiness.

If physical-light acquisition truth changes, Perception refreshes even when actor geometry did not.

Thus the optimization does **not** freeze stale darkness/light visibility.

## Completed — cached geometric LOS across lighting-only refresh

Lighting/acquisition changes do not automatically mean walls, doors, terrain or observer facing changed.

System 23 now retains geometric LOS candidates separately.

When only visual acquisition changes:

- cached LOS candidates are reused;
- only acquisition filtering + observer memory refresh run again;
- no LOS ray/opacity geometry pass is repeated.

The final production verifier proves:

`infected_geometry_recomputes=0`

across the measured two-decision route.

Geometry still invalidates for the actual geometry/facing/profile dependencies.

## Completed — one bounded shared physical-light field

The player and active infected observers use the same physical-light acquisition provider.

Previously observer demand could move/rebuild one bounded physical-light query field around separate observer envelopes.

`ActiveInfectedCohortService` now prepares one combined bounded field covering:

- every currently active infected observer's vision envelope;
- the player observer envelope.

No whole-world light field was introduced.

No renderer/camera state became gameplay truth.

## Completed — warm shared field before the first real input

A later diagnostic isolated a large remaining spike.

Before the final warm-preparation fix, the same two-decision route measured:

```text
first_request_usec   = 113442
second_request_usec  = 9855
```

The first infected behavior callback was paying the cold shared-light-field build through visual-acquisition freshness.

`IlluminationVisualAcquisitionProvider.prepare_bounds(...)` now means the bounded field is actually current, not merely that its bounds were stored.

The cohort already prepares those bounds during activation/loading, so the expensive cold build moves out of the first real player input.

No simulation time advances during this preparation.

## Final focused production evidence

Focused run:

- head: `4d674f25a00d4c454a40f2652f43fa02cc29e891`
- run: `36206781574`
- result: **SUCCESS**

Final marker:

`PHASE2_INFECTED_PERF_METRIC`

Key measured values:

```text
active infected                  = 8
first_request_usec               = 9874
second_request_usec              = 9580

first_behavior_eval_usec         = 8984
second_behavior_eval_usec        = 8905
behavior_evaluations             = 16
behavior_eval_max_usec           = 1726

infected_perception_recomputes   = 16
infected_perception_usec         = 15797
infected_geometry_recomputes     = 0
infected_geometry_usec           = 0

intention_usec                   = 1581
submit_usec                      = 14
ordinary submissions             = 0
```

Interpretation:

- exactly one behavior evaluation per active infected per player decision;
- both measured action-start callbacks are under the focused 10 ms per-decision target on this CI route;
- aggregate infected behavior work is under 10 ms per decision;
- geometric LOS is not redundantly rebuilt;
- remaining acquisition/memory refresh is roughly 1 ms per infected observer on this route;
- intention selection and submission are small, so they were not rewritten.

## Important non-claim — total turn performance is not solved

The same final CI route still measured approximately:

- first full turn: `282219` µs;
- second full turn: `287141` µs.

Player Perception accounted for only about `20612` µs across both turns, and infected callback/perception is now bounded as above.

Therefore this operation does **not** claim the entire accepted-action route meets the eventual Phase-2 <50 ms engineering target.

The remaining full-turn cost is outside the bounded infected callback/perception slice and must be attributed from later crowded-fight/Safari acceptance evidence before more optimization.

Do not reopen infected scheduling or perception architecture merely because total turn time remains high.

## Behavior preserved

`FirstInfectedBehaviorService` still owns only simple intention selection:

- idle;
- pursue visible;
- pursue last seen;
- investigate sound;
- attack visible.

No:

- horde brain;
- group target sharing;
- formation logic;
- crowd steering;
- generic AI scheduler;
- budget queue;
- per-frame zombie update;
- private zombie clock

was added.

All actions still submit through normal Movement / Combat / WHEN.

## Measurement hooks

The active-cohort measurement layer now also exposes:

- behavior evaluation count / total / max;
- intention-refresh total microseconds;
- action-submission total microseconds;
- Perception recompute count / total / max;
- geometric LOS recompute count / total.

These are diagnostics only and do not alter gameplay decisions.

## Durable documentation updated

- `SYSTEM_DESIGNS/23_PERCEPTION_LOS_FOG_MEMORY.md` records event-driven freshness, cached geometric LOS, shared acquisition demand and final performance evidence.
- `SYSTEM_DESIGNS/38_FIRST_INFECTED_POPULATION_HYDRATION.md` records eight-infected callback-performance closure and explicitly rejects scheduler/horde-brain drift.
- `SYSTEM_DESIGNS/PERFORMANCE_ARCHITECTURE.md` records the measured P4B callback/perception pass and its non-claim about full-turn performance.
- `ROADMAP.md` marks zombie callback/perception cost bounded and moves Phase 2 forward.
- `CHANGELOG_LATEST.md` records the same-route cold/warm measurements and final proof.

## Current release direction

Core loop remains:

**scavenge -> fight -> craft -> survive**

on the persistent map with day/night, weather, power, water and vehicles.

A base remains an existing fortified house/building with supplies, generator and well.

Human survivor society, raiders and human followers remain outside release scope. Pets remain future bounded scope.

Phase-2 defining work now complete includes:

1. commitment windows / points of no return;
2. simultaneous same-tick melee consequences;
3. terminal death after already-earned spatial consequences;
4. causal `S_t -> transition -> S_t+1` ordering;
5. deterministic same-tick movement/space arbitration;
6. shove as shared forced trajectory;
7. aggregate multi-body mob pressure;
8. canonical Calm/fear;
9. bounded eight-infected callback/perception path.

## NEXT OPERATION

Continue Phase 2 with **coherent overlapping consequence presentation**.

Do not reopen mob force, fear, infected scheduling or Perception performance without a concrete new defect.

The next bounded slice should make the simultaneous simulation legible to the player.

Targeted starting reads only:

- existing combat/movement consequence signals and current player-facing combat/status presentation;
- current corpse/injury/impact feedback surface;
- existing action/consequence message queue or tactical overlays where simultaneous events are currently shown serially;
- no broad renderer rediscovery.

Required outcomes:

- same-timestamp melee impacts that truly resolve together are presented as one coherent consequence moment rather than looking like sequential enemy turns;
- simultaneous movement/shove/crowd outcomes are grouped enough that the player can understand why actors ended where they did;
- mutual hits / mutual lethal remain visibly mutual;
- fear/injury/pressure feedback does not spam duplicate messages for one consequence boundary;
- presentation owns no gameplay truth and advances no WHEN time;
- no cinematic delay that blocks the next legitimate decision;
- phone/Safari remains first-class;
- use one fresh prompt-local verifier/workflow scoped only to consequence presentation.

After coherent consequence presentation, Phase 2 should move directly to the crowded-fight + Safari acceptance/performance route. That acceptance pass should attribute the remaining full-turn cost before any further optimization.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- `S_t -> transition -> S_t+1` causal ordering;
- commitment windows;
- simultaneous melee hit/damage/death behavior;
- deferred terminal death after earned current-tick consequences;
- deterministic movement/space contests;
- mob-force core;
- canonical fear;
- responsive walk/run/shove/snap-fire escape actions;
- event-driven Perception freshness;
- lighting acquisition revision correctness;
- cached geometric LOS;
- one bounded shared player + active-infected acquisition field;
- active cohort size 8;
- simple independent infected intentions;
- no horde brain/scheduler/group coordination;
- resident-backed infected identity;
- player movement, Health/injury, inventory, condition/moodlets, skills/equipment;
- day/night, Weather, utilities and vehicles;
- persistence/terrain/streaming;
- input locked until legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
