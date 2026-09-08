# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — SMALL ACTIVE INFECTED COHORT SCALING PROOF CLOSED 2026-09-08

Production root:

`game/main.tscn -> CombatGameMain.gd -> VehicleGameMain.gd`

System 37 combat and the one-infected System-38 behavior loop remain closed. Production now proves a deliberately small **four-member resident-backed infected cohort** using the same architecture:

> **population resident -> physical hydration -> technical-stream activation -> System 23 / System 26 perception -> intention -> ordinary WHEN movement/combat -> generic Health/death**

No zombie-only clock, per-frame AI loop, private cooldown, magic aggro radius, hidden shared target truth, teleport movement, duplicate Health/combat state or horde ghosting was added.

The architecture is proven at four, but current measurements explicitly do **not** justify jumping directly to hordes. The next operation is an active-cohort scheduling/perception budget plus a controlled 4 -> 8 -> 16 count ladder.

## Prompt start / turnover completed

This prompt deleted the previous prompt-owned verifier pair FIRST:

- `game/scripts/ci/PromptFirstInfectedBehaviorSmoke.gd`
- `.github/workflows/prompt-first-infected-behavior.yml`

Turnover completed at:

- `ddb2e031b3c70fd9a0d3255058ff0e20fff7147d`

Then this file was read first, `README_SOPS.md` second, and current `main` was fetched once. That exact turnover SHA was the prompt starting head.

No broad gameplay regression fleet, historical architecture suite or seed matrix was restored.

## System 38 — deterministic small cohort

### Population truth remains authoritative

`PopulationResidentProjection` still names only household slots already counted by island population planning.

Resident identity remains:

`resident.<building_id>.<ordinal>`

Infection assignment remains deterministic from world seed + building identity + ordinal, with exactly each settlement's already-planned infected count selected.

New `infected_near(...)` returns deterministic cohort candidates:

1. preferred-site infected sorted by Manhattan distance to the reference cell, then actor ID;
2. remaining infected appended deterministically without duplicate identities.

No new population is created for cohort scaling.

### Physical cohort hydration

`FirstInfectedHydrationService` now supports `hydrate_cohort(...)` while retaining `hydrate_first(...)` as the one-infected compatibility path.

Production currently sets:

`ACTIVE_INFECTED_COHORT_SIZE = 4`

Each cohort member is the exact projected resident identity and is enrolled through the same ordinary owners:

- ACTOR placement;
- locomotion;
- hand equipment;
- inventory containment;
- Health;
- skills;
- carry;
- System-34 condition;
- `InfectedState` provenance.

Hydration searches real currently materialized clear cells near the resident's home and respects ordinary collision. It never overlaps blocking ACTOR occupancy merely to reach the target count.

The four-member value is a measured proof size, not a declared final active-population limit.

## Technical streaming owns behavior activation

New owner:

- `game/scripts/simulation/infected/ActiveInfectedCohortService.gd`

The existing `WorldStreamingCoordinator` is the **sole activation-envelope authority**.

A living infected is behavior-active only when its exact ACTOR cell satisfies:

`WorldStreamingCoordinator.is_cell_active(actor_cell)`

The cohort listens to the existing `active_regions_changed` signal plus exact cohort actor placement and Health changes. There is no second zombie activation radius.

Existing technical streaming remains 128x128 regions with active radius 1 unless deliberately changed elsewhere.

## Active versus dormant semantics

Leaving the technical active envelope does **not** delete the infected or reset simulation state.

A dormant cohort member retains:

- exact resident/actor identity;
- physical ACTOR placement;
- Health;
- inventory/equipment;
- condition/skills/carry;
- infection/population provenance;
- existing perception memory.

Only expensive behavior participation sleeps:

- System-26 listener registration is removed;
- `StreamingObserverPerceptionService` refuses System-23 recomputation while inactive;
- the same behavior adapter is stopped so event callbacks cannot evaluate/submit actions.

On technical-stream re-entry:

- the same resident identity remains;
- the same perception object is reactivated/recomputed through System 23;
- the same behavior object resumes;
- System-26 listener registration returns.

No replacement actor is substituted.

## Reused behavior policy

`FirstInfectedBehaviorService` remains the behavior policy. Scaling did not add new zombie abilities.

The same intentions remain:

- `infected.idle`;
- `infected.pursue_visible`;
- `infected.pursue_last_seen`;
- `infected.investigate_sound`;
- `infected.attack_visible`.

`CohortInfectedBehaviorService` subclasses that exact policy only to add lifecycle/performance measurement.

Visual truth remains observer-scoped System 23. Heard investigation remains System-26 `HeardSoundObservation` truth and carries only observer-safe perceived location/certainty, never hidden exact source identity.

## Shared WHEN scheduling now proven with multiple infected

There is still no infected clock.

At player decision pause, render frames create no cohort behavior evaluations.

When one ordinary player commitment opens shared WHEN time, multiple active infected can independently submit lawful ordinary actions on that same timeline.

The focused production-scene proof placed two active infected in truthful visible approach lanes and confirmed both increased ordinary action-submission counts from the same player-opened WHEN interval.

Movement remains ordinary movement service truth; attacks remain System 37.

## Physical congestion preserved

Cohort members are ordinary ACTOR occupancy.

The verifier proves:

- all four hydrated residents occupy distinct cells;
- two concurrently scheduled infected remain on distinct cells;
- one infected's occupied cell is blocking to another through the ordinary collision query.

There is no horde-specific pass-through or teleport correction.

## Death remains generic and actor-local

Canonical Health/generic corpse transition remains authoritative.

The focused proof kills one cohort member and confirms:

- that actor leaves active cohort scheduling;
- another living infected remains active;
- active count drops by exactly one;
- resident/infection provenance survives death.

System 38 does not own HP or corpse truth.

## Production measurement added

`ActiveInfectedCohortService` and `CohortInfectedBehaviorService` expose/record:

- roster count;
- active/dormant counts;
- activation/deactivation counts;
- activation-sync count / total / maximum microseconds;
- behavior evaluation count / total / maximum microseconds;
- ordinary action submission count.

These are real production-path measurements and also feed `PerformanceTelemetry`.

Successful four-member focused run metrics:

```text
roster_count = 4
active_actor_count = 3        # after one deliberate lethal transition in the scenario
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

Derived from that focused run:

- average measured behavior evaluation ~= 5.19 ms;
- worst behavior evaluation = 16.67 ms;
- average activation-sync pass ~= 26.00 ms;
- worst activation-sync pass = 95.60 ms.

These numbers include real System-23 / behavior activation work during a deliberately forced technical-stream exit/re-entry. They are not a universal hardware budget, but they establish the next optimization gate.

## Scaling limitation now explicit

Dormant infected no longer pay active hearing, System-23 recomputation or behavior evaluation/submission cost.

However, each hydrated perception/behavior object still inherits its ordinary shared-event signal connections and returns cheaply while stopped/inactive. That fan-out is acceptable at four but must be measured/centralized if it becomes material before hundreds of hydrated actors exist.

Likewise, a 16.67 ms worst behavior evaluation and 95.60 ms worst activation-sync pass are large enough that increasing counts blindly would be the wrong next step.

Do **not** start hordes yet.

## Focused verifier evidence

Current prompt-owned disposable pair:

- `game/scripts/ci/PromptSmallInfectedCohortSmoke.gd`
- `.github/workflows/prompt-small-infected-cohort.yml`

Functional code/test head before documentation:

- `dd178a7c445ea382ea11e27400d3c1c22ec65e79`

Initial focused run:

- `34172671153` — failed before gameplay only because two smoke locals required explicit `Vector2i` typing. Production parsed cleanly. Only verifier typing changed; no scaling assertion was weakened.

Successful focused run:

- `Prompt Small Infected Cohort` run `34172818895` — **SUCCESS**

The successful real-`main.tscn` log proves deterministic resident hydration, distinct physical ACTOR occupancy, authoritative stream activation/deactivation, dormant System-23/System-26 work suspension, identity-preserving re-entry, shared-WHEN multi-actor submission, physical congestion, isolated generic death and real timing metrics.

The log ended:

`PROMPT_SMALL_INFECTED_COHORT_SMOKE: PASS`

## Documentation updated

- `SYSTEM_DESIGNS/38_FIRST_INFECTED_POPULATION_HYDRATION.md` — now records deterministic cohort hydration, stream activation semantics, dormant/reactivation policy, metrics, measured ceiling and next scaling gate.
- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md` — records the four-member scaling proof, verifier history, measurements and ownership boundary.
- This `README_CONTEXT.md` is the **final repository write for this prompt**.

## Current prompt-owned CI turnover rule

At the START of the next code prompt, delete FIRST:

- `game/scripts/ci/PromptSmallInfectedCohortSmoke.gd`
- `.github/workflows/prompt-small-infected-cohort.yml`

Then read this file first, read `README_SOPS.md`, and fetch current `main` once.

Create one fresh focused verifier pair only for the scheduling/perception-budget/count-ladder work actually touched. Do not restore previous infected/combat/human-mobile workflows, broad architecture fleets or routine seed matrices.

## Protected neighboring contracts — preserve

### Infected / combat

- infection remains an overlay on shared human semantic `actor.survivor`;
- resident identities derive from already-counted household slots; no extra zombie population;
- System 23 owns observer-scoped visual knowledge/memory;
- System 26 owns uncertain heard observations and never leaks hidden source identity to behavior;
- technical `WorldStreamingCoordinator` owns active-envelope truth;
- WHEN owns timing/readiness/interruption;
- ordinary movement/world/collision own locomotion and congestion;
- System 37 owns physical melee/firearm combat;
- Health/generic death owns HP/corpse transition;
- exact firearm/magazine/round identities remain physical containment truth;
- reload remains WHEN RESUMABLE with truthful eject/insert/chamber intermediate state;
- no Combat skill;
- no zombie clock, per-frame AI, magic aggro radius, hidden group target, private attack cooldown, teleport movement, duplicate combat/Health or collision ghosting.

### Vehicle / skateboard

- on foot click exact vehicle for lawful interaction;
- REPAIR/REFUEL appear there only when physically valid; HOTWIRE remains mounted-only;
- clicking one vehicle never silently operates another;
- no separate vehicle-maintenance panel;
- `ADD RACK` remains optional/legacy, not protected gameplay;
- skateboard 2 cells / 2 ticks; bicycle 3 / 2; motorcycle/car/truck 3 / 1;
- skateboard only is brakeless and may reverse/dismount while moving;
- other vehicles require stopped state before reverse/exit;
- mounted controls replace walking controls in the same lower footprint.

### Inventory / equipment / interaction

- exact selected persistent item -> lawful action -> authoritative WHEN -> exact-entity consequence;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- one physical item cannot occupy multiple slots;
- skateboard remains one identity across loose/equipped/ridden; legal equipment destinations RIGHT HAND / LEFT HAND / BACK only;
- shared world chooser preserves every actionable exact overlapping target;
- UI owns no gameplay truth.

### Doors / lighting / utilities

- closed locked openings expose TRY OPEN instead of leaking hidden lock truth;
- break/board/unboard/climb remain closed work;
- shattered-window repair remains deferred until real replacement glass exists;
- fixed room lighting follows System-33 power automatically; no residential light-switch gameplay;
- exact flashlight item owns persistent switched state; no invented battery depletion;
- portable generators use real INSPECT/REFUEL/START/STOP fuel/running/local-power truth;
- physical distribution-support repair remains System 33B/System-33 truth; direct span repair waits for clickable WHAT span identity.

### HUD / world

- no Survival window, Forage panel, player-visible Dev window, visible Zoom +/- or Health/Fatigue bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW + MAP remain available on foot/mounted;
- island remains 3072x3072;
- stream regions remain 128x128 active radius 1 unless deliberately changed;
- gateway roads four-lane paved; town/crossroads routes two-lane paved unless gateway; only rural-rural links gravel/dirt single-lane traversable;
- reference seed 20001 remains roughly 627 buildings / 2184 residents / 2 towns / 3 crossroads / 30 rural settlements;
- exactly one municipal water facility plus aliases; no municipal pipe/node/pressure graph;
- deterministic 10-20% rural private wells only;
- wastewater/sewer/septic remain retired;
- no routine 12-seed matrix.

## Design philosophy — preserve

Target:

> **deep interaction as an emergent property of relatively light simulation**

Prefer reusable physical/stateful primitives and owner truth over bespoke feature stacks: WHAT identity, containment, equipment, material/condition/damage, collision/LOS, observer-scoped perception, sound, power/fuel/fluid, weather/temperature, tools/capabilities, carry/weight and authoritative WHEN action costs.

## NEXT OPERATION — ACTIVE COHORT SCHEDULING / PERCEPTION BUDGET + COUNT LADDER

Start the next code prompt by deleting the current small-cohort verifier/workflow first, reading this file, reading `README_SOPS.md`, then fetching current `main` once.

Preserve the exact resident-backed / streaming / System-23 / System-26 / intention / ordinary-WHEN architecture.

Next work:

1. Profile whether dormant inherited shared-signal fan-out materially contributes cost; centralize/batch only if measurement justifies it.
2. Reduce or budget activation-time System-23 recomputation so stream-boundary activation cannot create an uncontrolled spike, without creating a fake AI clock.
3. Establish an explicit interaction-latency/per-tick budget from production measurements.
4. Run controlled active-count steps **4 -> 8 -> 16** using the same production-scene metrics. This is a count ladder, not a seed matrix.
5. Preserve physical ACTOR congestion and observer-scoped visual/heard knowledge at every count.
6. Stop increasing the count when measured behavior/activation work exceeds the chosen budget; fix the owner/scheduling seam before proceeding.
7. Do not start hordes yet.
8. Only after the count ladder is healthy should the next phase establish materialization/persistence policy for larger off-screen infected populations.