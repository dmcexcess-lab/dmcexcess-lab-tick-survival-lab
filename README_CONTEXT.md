# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — INFECTED COUNT LADDER CLOSED; PRODUCTION ACTIVE COHORT = 8 — 2026-09-08

Production root:

`game/main.tscn -> CombatGameMain.gd -> VehicleGameMain.gd`

System 37 combat and System 38 resident-backed infected behavior remain closed. The active infected cohort now uses the same simple production architecture at a measured production count of **8**:

> **population resident -> physical hydration -> technical-stream activation -> System 23 / System 26 knowledge -> simple intention -> ordinary WHEN movement/combat -> generic Health/death**

The approved 4 -> 8 -> 16 ladder is complete. All three counts passed functionally. Production deliberately stays at **8** because the full real System-23 perception sweep grows roughly linearly and reached ~234 ms at 16 on CI. The behavior policy itself stayed stable around ~15–18 ms worst individual evaluation.

No horde AI, AI scheduler, crowd manager, perception queue, group coordination, hidden target sharing, second activation radius or zombie-only optimization layer was added.

Project rule reinforced by the user:

> **Complex behavior, simple systems. Do not over-engineer it.**

## Prompt start / turnover

At the START of this code prompt the previous prompt-owned verifier pair was deleted FIRST:

- `game/scripts/ci/PromptSmallInfectedCohortSmoke.gd`
- `.github/workflows/prompt-small-infected-cohort.yml`

Turnover commits:

- `f2dee7c341327fe81e11cffc08b26c8fac63b03c`
- `cc074ba538e360ca53fffe5232b0e33c45006102`

Then this file was read first, `README_SOPS.md` second, and current `main` was fetched once.

Prompt starting head:

- `cc074ba538e360ca53fffe5232b0e33c45006102`

No broad historical CI fleet, architecture suite, seed matrix or unrelated regression suite was restored.

## Current production active count

`CombatGameMain.gd` now intentionally sets:

`ACTIVE_INFECTED_COHORT_SIZE = 8`

This is not a permanent game-design maximum. It is the highest count adopted in production by this prompt because it provides a real increase over 4 without introducing architecture solely to support a larger number.

Count 16 is **proven functional** but intentionally not the current production active count.

## Count ladder verifier

Current prompt-owned disposable pair:

- `game/scripts/ci/PromptInfectedCountLadderSmoke.gd`
- `.github/workflows/prompt-infected-count-ladder.yml`

Workflow:

- `Prompt Infected Count Ladder`

The smoke boots real `res://main.tscn`. For the configured production count it:

1. confirms the count is one of the approved 4 / 8 / 16 ladder values;
2. confirms exact resident-backed hydrated identities;
3. places every member in a distinct valid ACTOR cell inside the existing technical active envelope;
4. proves ordinary physical congestion is preserved;
5. proves active membership still comes from the existing streaming owner;
6. proves render frames do not become an AI scheduler while player decision-paused;
7. explicitly recomputes System 23 once for every active infected and measures the all-observer sweep;
8. opens ordinary shared WHEN with one player commitment and proves infected react through the existing event-driven behavior path;
9. records placement/perception/cohort timing metrics.

## 4 -> 8 -> 16 evidence

### 4 members — baseline

Head:

- `4d32bd3b848c18731aca96b619a334e905bdb077`

Run:

- `Prompt Infected Count Ladder` run `34173867420` — **SUCCESS**

Measured:

```text
placement_burst_usec      = 260124
perception_sweep_usec     = 60955
behavior_evaluation_max   = 17835
activation_sync_max_usec  = 98580
```

Approximate explicit all-observer System-23 sweep: **61 ms**.

### 8 members — first ladder run

Head:

- `afc5a175f3f0c07827a090cec3f7aa7376b0f74d`

Run:

- `Prompt Infected Count Ladder` run `34173978788` — **SUCCESS**

Measured:

```text
placement_burst_usec      = 694732
perception_sweep_usec     = 113309
behavior_evaluation_max   = 14732
activation_sync_max_usec  = 161719
```

Approximate explicit all-observer System-23 sweep: **113 ms**.

### 16 members — functional but measured bend

Head:

- `0c0b3e7026afff623e3b2f5cd1129056a05c9eea`

Run:

- `Prompt Infected Count Ladder` run `34174095120` — **SUCCESS**

Measured:

```text
placement_burst_usec       = 2517070
perception_sweep_usec      = 233611
behavior_evaluation_max    = 15224
activation_sync_max_usec   = 308325
ordinary_action_submissions = 8
```

Approximate explicit all-observer System-23 sweep: **234 ms**.

All 16 remained valid resident-backed physical ACTORs and ordinary behavior continued to function. The important finding is that the simple behavior did **not** explode in cost. The main growth is the expected cost of doing real observer-scoped perception for more simultaneous observers.

## Decision — do not engineer around 16

A targeted read of `ActiveInfectedCohortService` confirmed there is no obvious needless whole-roster rescan on ordinary actor movement or Health change. Those callbacks already resynchronize only the changed cohort actor.

Therefore no tiny obvious owner-local fix existed that justified modifying production behavior.

Instead of inventing a scheduler/perception queue/horde architecture just to make 16 cheaper, production was returned to **8**.

Final functional 8-member candidate before docs:

- `d3f4a0544be6abec32b084ed77a57880330836be`

Final functional run:

- `Prompt Infected Count Ladder` run `34174173692` — **SUCCESS**

Measured:

```text
placement_burst_usec            = 718903
perception_sweep_usec           = 118140
activation_sync_max_usec        = 165307
behavior_evaluation_count       = 65
behavior_evaluation_max_usec    = 17430
behavior_evaluation_total_usec  = 159910
ordinary_action_submission_count = 3
```

The microsecond values are CI-machine observations, not universal performance budgets. The durable conclusion is:

- 8 is a useful production increase from 4;
- 16 is functionally proven;
- behavior remains simple/event-driven;
- simultaneous perception is the current scaling cost;
- there is no reason to build extra infrastructure until actual gameplay needs more active infected.

## Existing System 38 ownership — preserve

### Population / identity

- infected identities derive only from already-counted household resident slots;
- no extra zombie population exists;
- resident IDs remain deterministic `resident.<building_id>.<ordinal>`;
- `InfectedState` is an overlay on the same shared human actor identity and preserves provenance through death.

### Streaming

- `WorldStreamingCoordinator` remains the sole active-envelope authority;
- dormant infected keep exact physical/state truth;
- dormant System-26 listener work is removed;
- dormant `StreamingObserverPerceptionService` refuses expensive recomputation;
- dormant behavior does not evaluate/submit actions;
- re-entry reuses the same actor/perception/behavior identity.

### Perception / behavior

- System 23 owns observer-scoped vision/memory;
- System 26 owns uncertain heard observations and never leaks hidden exact sound-source identity to behavior;
- intentions remain only idle / pursue visible / pursue last seen / investigate sound / attack visible;
- no group brain, shared target truth, per-frame loop, zombie timer or private cooldown.

### Time / movement / congestion / combat

- WHEN owns simulation time/readiness/interruption;
- movement/world/collision own physical locomotion;
- infected occupy ordinary blocking ACTOR cells;
- congestion/bunching must emerge from collision, not crowd-management code;
- System 37 owns physical melee/firearm combat;
- Health/generic death owns HP/corpse transition.

## Material docs updated

- `SYSTEM_DESIGNS/38_FIRST_INFECTED_POPULATION_HYDRATION.md` — 4 -> 8 -> 16 ladder, measurements, production=8 decision, and simple-systems boundary recorded at docs commit `efdc2cd5fe8d29daa66cbc354ff4901451aa9c22`.
- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md` — ladder evidence and explicit no-overengineering decision recorded at docs commit `117a0a310dd043f825441f0889f7bf6114db83ee`.
- This `README_CONTEXT.md` is the **final repository write for this prompt**.

## Current prompt-owned CI turnover rule

At the START of the next code prompt, delete FIRST:

- `game/scripts/ci/PromptInfectedCountLadderSmoke.gd`
- `.github/workflows/prompt-infected-count-ladder.yml`

Then read this file first, read `README_SOPS.md` second, and fetch current `main` once.

Create one brand-new focused verifier pair only for the next environmental-pressure code actually changed. Do not restore this ladder verifier afterward, prior infected/combat verifiers, broad architecture fleets or routine seed matrices.

## Protected neighboring contracts — preserve

### Combat

- physical melee/contact remains WHEN-timed with committed/interruption semantics;
- exact firearm/magazine/live-round identity remains containment truth, never an ammo integer;
- reload remains WHEN RESUMABLE with truthful eject/insert/chamber intermediate state;
- System 26 owns firearm/combat sound;
- generic Health-driven death/corpse transition preserves exact carried item identity;
- no Combat skill.

### Vehicle / skateboard

- on foot click exact vehicle for lawful interaction;
- REPAIR/REFUEL appear only when physically valid; HOTWIRE mounted-only;
- clicking one vehicle never operates another;
- no separate vehicle-maintenance panel;
- skateboard 2 cells / 2 ticks; bicycle 3 / 2; motorcycle/car/truck 3 / 1;
- skateboard only is brakeless and may reverse/dismount while moving;
- other vehicles require stopped state before reverse/exit;
- mounted controls replace walking controls in the same footprint.

### Inventory / equipment / interaction

- exact selected persistent item -> lawful action -> authoritative WHEN -> exact-entity consequence;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- one physical item cannot occupy multiple slots;
- skateboard remains one physical identity across loose/equipped/ridden;
- shared world chooser preserves every actionable exact overlapping target;
- UI owns no gameplay truth.

### Doors / lighting / utilities

- locked closed openings expose TRY OPEN instead of hidden lock truth;
- break/board/unboard/climb remain closed work;
- shattered-window repair remains deferred until real replacement glass exists;
- fixed room lighting follows System-33 power automatically; no residential light-switch gameplay;
- exact flashlight owns persistent switched state; no invented battery depletion;
- portable generators use real INSPECT/REFUEL/START/STOP fuel/running/local-power truth;
- physical distribution-support repair remains System 33B/System-33 truth.

### HUD / world

- no Survival window, Forage panel, player-visible Dev window, visible Zoom +/- or Health/Fatigue bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW + MAP remain available on foot/mounted;
- island remains 3072x3072;
- technical stream regions remain 128x128 with active radius 1 unless deliberately changed;
- gateway roads four-lane paved; town/crossroads routes two-lane paved unless gateway; only rural-rural links gravel/dirt single-lane traversable;
- reference seed 20001 remains roughly 627 buildings / 2184 residents / 2 towns / 3 crossroads / 30 rural settlements;
- exactly one municipal water facility plus aliases; no municipal pipe graph;
- deterministic 10–20% rural private wells only;
- wastewater/sewer/septic remain retired;
- no routine 12-seed matrix.

## Design philosophy — preserve

Target:

> **deep interaction as an emergent property of relatively light simulation**

Prefer reusable physical/stateful primitives and owner truth over feature-specific stacks: WHAT identity, containment, equipment, material/condition/damage, openings/barriers, collision/LOS, observer-scoped perception, sound, power/fuel/fluid, weather/temperature, tools/capabilities, carry/weight and authoritative WHEN action costs.

Especially for infected:

> **Complex behavior should emerge from simple systems interacting.**

Do not build a horde brain because ordinary hearing, sight, collision, openings, WHEN and combat can create herding, bunching, pursuit and pressure themselves.

## NEXT OPERATION — EMERGENT ENVIRONMENTAL PRESSURE

Do **not** increase infected counts again yet.

Use the now-eight-member active cohort to prove that existing simple systems create meaningful pressure against the real environment:

1. infected pursue real System-23 sight and System-26 sound through ordinary movement;
2. ordinary ACTOR collision creates bunching/congestion naturally;
3. real doors/windows/barriers interrupt movement rather than being ignored or teleported through;
4. infected interact with openings only through real physical timed actions;
5. reuse existing door/window state, collision, movement, System-26 sound, WHEN and System-37 consequences;
6. if non-player actors currently cannot open/break/traverse an opening, add only the minimum **generic actor/opening action seam** needed to expose the already-existing physical action;
7. breaking/opening must create ordinary sound and state consequences that other infected can perceive naturally;
8. do not add group coordination, shared aggro, horde AI, formation logic or zombie-only environmental shortcuts.

The desired result is emergent: one infected hears/sees something, acts physically, its movement/noise/state changes alter what nearby infected perceive, and crowd pressure develops from those ordinary interactions.