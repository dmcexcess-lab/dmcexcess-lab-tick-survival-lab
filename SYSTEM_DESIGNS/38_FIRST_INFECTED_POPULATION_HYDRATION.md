# System 38 — Population-Backed Infected Hydration + Active Cohort

Status: **RESIDENT-BACKED INFECTED + STREAMING COHORT + 4 → 8 → 16 COUNT LADDER CLOSED IN PRODUCTION**

## 1. Core rule

> **An infected is a real human resident in an infected state, not a disconnected zombie fixture.**

The island population planner owns how many residents exist. System 38 never creates a second zombie population. It deterministically projects already-counted household resident slots into exact identities only when those people must enter active simulation.

Infection remains an overlay on shared human semantic `actor.survivor`, so Health, equipment, inventory, locomotion, condition, carry, skills, collision, perception, sound, combat and WHEN remain ordinary shared owners.

## 2. Existing population truth reused

`IslandWorldPlanner` already retains `population_settlements`, resident/infected/survivor totals, and `local_area_manifest`. Settlement population records point at real generated household buildings and household resident capacity. System 38 names those slots; it does not add residents.

`PopulationResidentProjection` names each existing household slot as:

`resident.<building_id>.<ordinal>`

Each record keeps exact resident ID, source building, household ordinal, settlement/site identity and generated home cell. Stable infection scores derive from world seed + building identity + resident ordinal, then exactly each settlement's existing infected count is selected.

`infected_near(...)` returns deterministic candidates ordered by preferred-site distance and resident identity, followed by remaining infected records without duplicate identities.

## 3. Infection state overlay

`InfectedState` stores resident provenance on the exact shared actor identity. A valid infected record requires the same resident/actor ID, `infected = true`, a real source building and positive resident ordinal.

Death does not erase provenance. The same population identity remains traceable through generic Health/corpse transition.

## 4. Cohort hydration

`FirstInfectedHydrationService` supports both `hydrate_first(...)` and bounded `hydrate_cohort(...)`.

For each selected resident it:

1. starts from the resident's generated home cell;
2. finds a real clear materialized cell through ordinary spatial/collision truth;
3. creates the exact resident identity as `actor.survivor`;
4. places it on the normal ACTOR channel;
5. enrolls ordinary locomotion, hands, inventory containment, Health, skills, carry and System-34 condition state;
6. records infection/provenance in `InfectedState`.

Hydration never overlaps a blocking ACTOR merely to reach a count. Invalid/unmaterialized candidates can be skipped deterministically; owner-enrollment failures still fail closed.

## 5. Behavior remains deliberately simple

`FirstInfectedBehaviorService` remains the behavior policy. The cohort does not get a horde brain.

Intentions remain only:

- `infected.idle`;
- `infected.pursue_visible`;
- `infected.pursue_last_seen`;
- `infected.investigate_sound`;
- `infected.attack_visible`.

The policy consumes observer-scoped System-23 visual truth and observer-safe System-26 heard observations, then submits ordinary movement/System-37 actions on shared WHEN.

No per-frame AI, zombie timer, private attack cooldown, teleport movement, global aggro radius, shared omniscient target, crowd manager or horde coordinator exists.

## 6. Technical streaming is the activation owner

`ActiveInfectedCohortService` uses the existing `WorldStreamingCoordinator` as the only activation-envelope authority.

A living cohort member is behavior-active only when its exact ACTOR placement satisfies:

`WorldStreamingCoordinator.is_cell_active(actor_cell)`

There is no second zombie activation radius.

The cohort listens to technical stream-envelope changes, exact cohort placement changes and canonical Health changes. Ordinary world/HP changes resync only the changed cohort actor; the whole roster is not rescanned for every mutation.

## 7. Dormant means state persists while expensive participation sleeps

Leaving the active stream envelope does not delete/reset the resident. Dormant members retain identity, placement, Health, equipment/inventory, condition/skills/carry, infection provenance and acquired perception memory.

Dormant members are removed from expensive active work:

- System-26 listener registration is removed;
- `StreamingObserverPerceptionService` refuses expensive System-23 recomputation;
- behavior is deactivated and does not evaluate/submit actions.

Re-entry restores hearing/perception/behavior on the same resident identity and reuses the same objects. No substitute zombie is spawned.

## 8. Shared WHEN and physical congestion remain ordinary simulation

There is no infected clock. At player decision pause, render frames do not create infected behavior evaluations. When an ordinary player commitment opens WHEN, active infected can independently submit normal actions on the same simulation timeline.

Each infected occupies a normal blocking ACTOR cell. Congestion, bunching and blocked movement emerge from ordinary collision. There is no horde ghosting, pass-through or crowd teleport correction.

Killing one infected through canonical Health removes only that actor from active behavior and follows generic corpse transition; the rest remain ordinary active actors.

## 9. Measurement hooks

`CohortInfectedBehaviorService` only adds lifecycle/measurement around the proven behavior. It records evaluation count, total/max evaluation microseconds and ordinary action submissions.

`ActiveInfectedCohortService` records roster/active/dormant counts, activation/deactivation counts and activation-sync timing. These metrics are also surfaced through `PerformanceTelemetry`.

Instrumentation measures real production-scene work; it does not create a synthetic AI execution path.

## 10. Small-cohort proof

The prior four-member production proof established deterministic resident identities, stream activation/deactivation, dormant perception/hearing shutdown, same-identity reactivation, shared-WHEN concurrent actions, normal physical congestion and independent generic death.

Its successful functional head was `dd178a7c445ea382ea11e27400d3c1c22ec65e79`, with `Prompt Small Infected Cohort` run `34172818895` — **SUCCESS**.

That pass established the scaling seam but did not justify horde-scale machinery.

## 11. Approved count ladder — no new scheduler

The next prompt explicitly preserved the user's rule:

> **Complex behavior, simple systems. Do not over-engineer it.**

A fresh production-scene verifier was added:

- `game/scripts/ci/PromptInfectedCountLadderSmoke.gd`
- `.github/workflows/prompt-infected-count-ladder.yml`

It uses the real production scene and existing owners only. For the currently configured production count it:

- places every hydrated resident into distinct valid cells inside the existing technical active envelope;
- proves all actors remain ordinary physical ACTORs;
- proves no render-frame AI scheduling occurs;
- explicitly recomputes System 23 for each active infected to measure an all-observer perception pass;
- opens ordinary shared WHEN with one player commitment and verifies event-driven infected reaction;
- records placement, perception and cohort metrics.

No scheduler, perception budget queue, horde manager or new AI abstraction was added during the ladder.

## 12. Ladder measurements

### Count 4 — baseline

Functional head: `4d32bd3b848c18731aca96b619a334e905bdb077`

`Prompt Infected Count Ladder` run `34173867420` — **SUCCESS**.

Measured:

```text
placement_burst_usec       = 260124
perception_sweep_usec      = 60955
behavior_evaluation_max    = 17835
activation_sync_max_usec   = 98580
```

Approximate full active-observer perception sweep: **61 ms**.

### Count 8 — first run

Functional head: `afc5a175f3f0c07827a090cec3f7aa7376b0f74d`

`Prompt Infected Count Ladder` run `34173978788` — **SUCCESS**.

Measured:

```text
placement_burst_usec       = 694732
perception_sweep_usec      = 113309
behavior_evaluation_max    = 14732
activation_sync_max_usec   = 161719
```

Approximate full active-observer perception sweep: **113 ms**.

### Count 16 — measured bend

Functional head: `0c0b3e7026afff623e3b2f5cd1129056a05c9eea`

`Prompt Infected Count Ladder` run `34174095120` — **SUCCESS**.

Measured:

```text
placement_burst_usec       = 2517070
perception_sweep_usec      = 233611
behavior_evaluation_max    = 15224
activation_sync_max_usec   = 308325
ordinary_action_submissions = 8
```

Approximate full active-observer perception sweep: **234 ms**.

All 16 remained functionally valid, physically distinct, System-23-active and event-driven. The behavior policy itself did **not** exhibit pathological growth: worst individual evaluation stayed near 15 ms. The expensive part was simply doing the same real perception work for more observers, with roughly linear growth across 4 → 8 → 16.

## 13. Production decision: keep 8, do not engineer around 16

The 16-member proof is evidence, not a mandate to increase production count.

Inspection of `ActiveInfectedCohortService` found no obvious redundant whole-roster callback to delete: ordinary cohort placement and Health changes already resync only the changed actor. Therefore there was no justified tiny optimization that would materially change the 16-observer result.

Rather than invent a scheduler/budget queue/horde subsystem solely to make 16 look cheaper, production was intentionally returned to:

`ACTIVE_INFECTED_COHORT_SIZE = 8`

Final functional 8-member candidate head:

`d3f4a0544be6abec32b084ed77a57880330836be`

`Prompt Infected Count Ladder` run `34174173692` — **SUCCESS**.

Final 8-member rerun measured:

```text
placement_burst_usec          = 718903
perception_sweep_usec         = 118140
activation_sync_max_usec      = 165307
behavior_evaluation_count     = 65
behavior_evaluation_max_usec  = 17430
behavior_evaluation_total_usec = 159910
ordinary_action_submission_count = 3
```

The exact microseconds are CI-machine observations, not universal budgets. The durable conclusion is architectural: 8 is a useful production increase from 4 using the exact same simple systems; 16 works but makes a synchronous all-observer perception burst large enough that there is no reason to adopt it yet.

## 14. Scaling conclusion

System 38 does **not** need more scaling architecture right now.

The measured behavior is healthy enough to continue gameplay development with eight active infected. Complexity should emerge from ordinary systems interacting:

- sound creates investigation/migration pressure;
- sight creates pursuit;
- WHEN creates committed temporal behavior;
- collision creates congestion/bunching;
- openings/terrain create physical constraints;
- combat/Health create consequences.

Do not add a horde brain, group target sharing, formation logic or generic AI scheduler without a concrete gameplay/performance failure that cannot be solved through an existing owner.

## 15. Next operation

Use the now-eight-member active cohort to prove **emergent environmental pressure** rather than increasing counts again.

Infected should encounter ordinary doors/windows/barriers while pursuing sound or sight and interact only through real physical actions. Reuse existing opening state, collision, System-26 sound, movement, WHEN and System-37 consequences. If an infected cannot currently traverse/open/break a barrier, add only the minimum generic actor/opening action seam required to let the existing systems interact.

Do **not** add horde AI, group coordination or zombie-only environmental shortcuts.

## 16. North-star fit

The active infected population still emerges entirely from ordinary simulation truth:

- world generation produced homes;
- population planning counted residents/infections;
- deterministic projection names existing resident slots;
- hydration gives those identities physical bodies;
- technical streaming decides which bodies are behavior-active;
- System 23 supplies observer-scoped vision;
- System 26 supplies uncertain heard observations;
- simple intention chooses what to try;
- movement/WHEN own physical action;
- System 37 owns attack;
- Health/death own mortality;
- ACTOR collision creates congestion.

The count ladder deliberately stopped before scale pressure turned into architecture for architecture's sake.