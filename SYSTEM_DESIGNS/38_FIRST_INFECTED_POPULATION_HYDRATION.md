# System 38 — Population-Backed Infected Hydration + Active Cohort

Status: **FIRST REAL INFECTED BEHAVIOR + SMALL STREAMING COHORT SCALING PROOF CLOSED IN PRODUCTION**

## 1. Core rule

> **An infected is a real human resident in an infected state, not a disconnected zombie fixture.**

The island population planner owns how many residents exist. System 38 never creates a second zombie population. It deterministically projects already-counted household resident slots into exact identities only when those people must enter active simulation.

Infection remains an overlay on shared human semantic `actor.survivor`, so Health, equipment, inventory, locomotion, condition, carry, skills, collision, perception, sound, combat and WHEN remain ordinary shared owners.

## 2. Existing population truth reused

`IslandWorldPlanner` already retains:

- `population_settlements`;
- `resident_population`;
- `infected_population`;
- `survivor_population`;
- `local_area_manifest`.

Settlement population records already point at real generated household buildings and household resident capacity. System 38 names those slots; it does not add residents.

## 3. Deterministic resident projection

`PopulationResidentProjection` names each existing household slot as:

`resident.<building_id>.<ordinal>`

Each record keeps the exact resident ID, source building, household ordinal, settlement/site identity and generated home cell.

Stable infection scores are derived from world seed + building identity + resident ordinal, then exactly each settlement's existing `infected_population` count is selected.

For cohort work, `infected_near(...)` returns a deterministic order: infected resident slots from the preferred site sorted by Manhattan distance to the reference cell and resident ID, followed by remaining infected records without duplicate identities. `first_infected_near(...)` is now simply the one-record compatibility view over that deterministic list.

## 4. Infection state overlay

`InfectedState` stores resident provenance on the exact shared actor identity. A valid infected record requires the same resident/actor ID, `infected = true`, a real source building ID and a positive resident ordinal.

Death does not erase provenance. The same population identity remains traceable after generic Health/corpse transition.

## 5. Cohort hydration

`FirstInfectedHydrationService` now supports both:

- `hydrate_first(...)` for the already-closed one-infected compatibility path;
- `hydrate_cohort(...)` for a deliberately bounded deterministic set.

For each selected resident it:

1. starts from the resident's real generated home cell;
2. finds a real clear materialized cell through the ordinary spatial/collision query;
3. creates the exact resident identity as `actor.survivor`;
4. places it on the normal ACTOR channel;
5. enrolls ordinary locomotion, hands, inventory containment, Health, skills, carry and System-34 condition state;
6. records infection/provenance in `InfectedState`.

Hydration never overlaps another blocking ACTOR merely to reach a target count. If a candidate's home is not currently materialized or the identity is unavailable, the deterministic selector can continue to the next valid resident. Other enrollment failures still fail closed.

Production currently sets:

`ACTIVE_INFECTED_COHORT_SIZE = 4`

This is a proof size, not a design declaration that four is the final active limit.

## 6. First infected behavior remains the policy

`FirstInfectedBehaviorService` remains the proven intention-only behavior policy. The small cohort does not get new zombie abilities.

Intentions remain:

- `infected.idle`;
- `infected.pursue_visible`;
- `infected.pursue_last_seen`;
- `infected.investigate_sound`;
- `infected.attack_visible`.

The policy still consumes observer-scoped System-23 visual truth and observer-safe System-26 heard observations, then submits ordinary movement/System-37 actions on shared WHEN.

No per-frame AI, zombie timer, private cooldown, teleport movement, global aggro radius or hidden shared target truth was introduced for scaling.

## 7. Technical-stream activation is authoritative

`ActiveInfectedCohortService` uses the existing `WorldStreamingCoordinator` as the only activation-envelope owner.

The service listens to:

- `WorldStreamingCoordinator.active_regions_changed`;
- exact cohort actor placement changes;
- canonical Health changes.

A living cohort member is behavior-active only when its exact ACTOR placement satisfies:

`WorldStreamingCoordinator.is_cell_active(actor_cell)`

There is no second zombie radius layered over streaming.

The existing technical stream geometry remains 128×128 regions with active radius 1 unless intentionally changed elsewhere.

## 8. Dormant means simulation state persists, expensive behavior work sleeps

Leaving the technical active envelope does **not** delete the resident body or reset gameplay state.

Dormant cohort members retain:

- exact actor identity;
- ACTOR placement;
- Health;
- inventory/equipment;
- condition/skills/carry state;
- infection/population provenance;
- perception memory already acquired.

But dormant members are removed from active behavior costs:

- their System-26 listener registration is removed;
- `StreamingObserverPerceptionService` refuses expensive System-23 recomputation while stream-inactive;
- their reused behavior adapter is stopped, so shared event callbacks return without action evaluation/submission.

On stream re-entry the **same objects and identities** reactivate: hearing re-registers, perception recomputes through System 23, and the same behavior service resumes. No fresh zombie is substituted.

## 9. Streaming System-23 adapter

`StreamingObserverPerceptionService` subclasses the ordinary `ObserverPerceptionService` only to add a stream-active gate.

It does not own visual truth. While active, it delegates directly to ordinary System 23. While dormant, `recompute()` exits before expensive acquisition/visibility work and current visibility reports inactive. Existing perception memory remains in the shared memory owner.

This avoids creating a duplicate zombie perception stack while providing a real activation seam for measured scaling.

## 10. Cohort behavior measurement

`CohortInfectedBehaviorService` subclasses the exact proven first-infected behavior policy and only adds lifecycle/measurement hooks.

It records:

- behavior evaluation count;
- total evaluation microseconds;
- maximum single evaluation microseconds;
- ordinary action submissions through the inherited behavior owner.

`ActiveInfectedCohortService` also measures:

- roster count;
- active/dormant counts;
- activation count;
- deactivation count;
- activation-envelope synchronization count;
- total/max activation-sync microseconds.

Metrics are also surfaced through `PerformanceTelemetry`.

This is deliberately instrumentation of real production work, not a synthetic benchmark loop.

## 11. Shared WHEN scheduling

There is still no infected clock.

At player decision pause, render frames do not create cohort behavior evaluations. When an ordinary player commitment opens the shared WHEN clock, multiple active infected can independently submit lawful ordinary actions on that same simulation timeline.

The focused proof places two active infected in truthful visible approach lanes and confirms both increase their ordinary action-submission counts from one shared player-opened WHEN interval.

## 12. Physical congestion remains ordinary collision

Each hydrated infected occupies an ordinary ACTOR cell. Two infected cannot occupy the same blocking cell merely because they are cohort members.

The focused verifier confirms:

- all four hydration placements are distinct;
- two concurrently scheduled infected remain on distinct ACTOR cells;
- querying one infected's cell from another actor sees normal blocking occupancy.

There is no horde-specific ghosting, pass-through mode or crowd teleport correction.

## 13. Death remains generic

Killing one cohort member through canonical Health:

- triggers the existing generic death/corpse path;
- removes only that actor from active cohort scheduling;
- leaves other living cohort members active;
- preserves the dead actor's population/infection provenance.

System 38 still owns neither HP nor corpse truth.

## 14. Focused verification

Current prompt-owned disposable verifier pair:

- `game/scripts/ci/PromptSmallInfectedCohortSmoke.gd`
- `.github/workflows/prompt-small-infected-cohort.yml`

Verified functional head:

- `dd178a7c445ea382ea11e27400d3c1c22ec65e79`
- `Prompt Small Infected Cohort` run `34172818895` — **SUCCESS**.

The production-scene verifier proves:

1. production hydrates exactly four deterministic resident-backed infected;
2. every member maps back to a projected population slot already classified infected;
3. all four remain ordinary physical ACTORs with distinct occupied cells;
4. cohort scheduling order is deterministic by exact actor identity;
5. active membership is exactly tied to `WorldStreamingCoordinator.is_cell_active()`;
6. active members are System-26 listeners with active System-23 perception and the reused behavior loop;
7. render frames during player decision pause create no behavior evaluations;
8. moving the technical stream envelope away deactivates the resident without deleting placement/state/provenance;
9. a dormant resident unregisters from System 26 and refuses System-23 recomputation work;
10. returning the stream envelope reactivates the same resident/perception/behavior identity;
11. two active infected submit ordinary actions on one shared WHEN interval;
12. ordinary collision preserves physical congestion;
13. killing one member removes only that actor from active scheduling while another remains active;
14. metrics are produced from real cohort work.

### Verifier repair

The first run `34172671153` failed before gameplay because two smoke locals needed explicit `Vector2i` typing under Godot's parser. Production parsed cleanly. Only those verifier types were corrected; all scaling assertions were unchanged.

The next run `34172818895` passed the full production-scene proof.

## 15. Measured result

The successful four-member focused run reported:

```text
roster_count = 4
active_actor_count = 3   # after one deliberate lethal transition in the scenario
dormant_actor_count = 1
activation_count = 8
deactivation_count = 5
activation_sync_count = 7
behavior_evaluation_count = 24
ordinary_action_submission_count = 2
behavior_evaluation_total_usec = 124569
behavior_evaluation_max_usec = 16672
activation_sync_total_usec = 182013
activation_sync_max_usec = 95595
```

Derived from that run:

- average measured behavior evaluation ≈ **5.19 ms** across 24 evaluations;
- worst measured behavior evaluation = **16.67 ms**;
- average activation-sync pass ≈ **26.00 ms** across 7 syncs;
- worst activation-sync pass = **95.60 ms**.

These values include real System-23/behavior activation work exercised by the production scene and the deliberate forced stream exit/re-entry test. They are not a stable hardware-independent performance budget, but they are sufficient to establish the next engineering boundary.

## 16. Scaling conclusion

The architecture is proven for a small cohort, but the measurements explicitly **do not justify jumping to hordes yet**.

Current dormant cost is already reduced substantially: no System-26 listener work, no System-23 recomputation, no action evaluation/submission. However, every hydrated behavior/perception object still owns its inherited event connections and returns cheaply while stopped/inactive. That fan-out is acceptable at four and becomes a concrete scaling seam to measure before hundreds of hydrated actors exist.

Likewise, the measured 16.67 ms worst behavior evaluation and 95.60 ms worst activation-sync pass are large enough that the next step should optimize/budget active scheduling and perception activation before simply multiplying actor count.

## 17. Next operation

Do **not** start hordes yet.

Next, build a measured **active-cohort scheduling/perception budget** and count ladder:

1. preserve this exact resident/streaming/WHEN architecture;
2. reduce shared-signal fan-out for dormant hydrated actors if profiling confirms it matters;
3. batch or budget activation-time System-23 recomputation without creating a fake AI clock;
4. run controlled active-count steps such as 4 → 8 → 16 using the same production-scene metrics;
5. stop increasing count when behavior/activation cost crosses the chosen interaction-latency budget;
6. only after that establish the materialization policy for larger off-screen populations/hordes.

Do not trade physical congestion or observer-scoped knowledge away for scale.

## 18. North-star fit

The small cohort still emerges from ordinary simulation truth:

- world generation produced homes;
- population planning counted residents/infections;
- deterministic projection names existing resident slots;
- hydration gives those same identities physical bodies;
- technical streaming decides which bodies are behavior-active;
- System 23 supplies observer-scoped vision;
- System 26 supplies uncertain heard observations;
- the behavior policy chooses intention only;
- shared movement/WHEN perform locomotion;
- System 37 performs attack;
- Health/generic death owns mortality;
- ordinary ACTOR collision creates congestion.

Scaling did not create a hidden zombie reality layer.