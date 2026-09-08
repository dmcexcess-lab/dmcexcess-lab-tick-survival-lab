# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — WORLD RESOLUTION INDICATOR CLOSED — 2026-09-08

Production root remains:

`game/main.tscn -> EnvironmentalPressureGameMain.gd -> CombatGameMain.gd -> VehicleGameMain.gd`

Production active infected cohort remains intentionally **8** resident-backed actors.

System 39 environmental pressure remains closed. This prompt added only a presentation seam to explain two pauses the player already feels during normal play:

- **`ZOMBIES`** while shared WHEN is resolving and at least one infected is currently stream-active;
- **`LOADING`** when the existing technical streaming owner reports a real active-region transition; `LOADING` has display priority over `ZOMBIES`.

There is no new turn system, AI scheduler, streaming system, progress model, gameplay pause, or UI-owned simulation truth.

Project rule remains:

> **Complex behavior, simple systems. Do not over-engineer it.**

## Prompt start / turnover

At the START of this prompt the previous prompt-owned System-39 verifier pair was deleted FIRST:

- `game/scripts/ci/PromptEnvironmentalPressureSmoke.gd`
- `.github/workflows/prompt-environmental-pressure.yml`

Turnover commits:

- `7cec0a2ab7ddd8aec697729e5dce040621b03675`
- `08559d1342d859ef74fbc42de185d22605ace9c0`

Then this file was read first, `README_SOPS.md` second, and current `main` was fetched once.

Prompt starting head after turnover:

- `08559d1342d859ef74fbc42de185d22605ace9c0`

No broad historical CI fleet, architecture suite, seed matrix, or unrelated regression suite was restored.

## World-resolution indicator

Production now mounts:

- `game/scripts/ui/WorldResolutionIndicator.gd`
- `ResolutionIndicator` node in real `game/main.tscn`

`EnvironmentalPressureGameMain` configures the indicator from the already-existing authoritative owners:

- `TickKernel` for shared WHEN / player decision-pause truth;
- `ActiveInfectedCohortService` for the current stream-active infected set;
- `WorldStreamingCoordinator` for technical active-region transitions.

### `ZOMBIES`

`ZOMBIES` is visible only when:

1. WHEN is not hard-paused;
2. the player is not at the authoritative decision pause;
3. at least one infected is currently stream-active.

It does **not** mean infected have a private turn. It is presentation shorthand for the shared world-resolution interval that feels slower when active infected are participating.

The existing `PlayerActionController` remains authoritative for action resolution. It already advances one due-tick WHEN batch per rendered frame and discards player input while busy. The indicator does not add or change input locking.

When the real player decision pause returns, `ZOMBIES` disappears and the existing controls unlock at the same boundary.

### `LOADING`

`LOADING` listens to the existing `WorldStreamingCoordinator.active_regions_changed` signal.

A real technical region transition raises a short presentation pulse so the player understands a boundary/materialization hitch. It does not change streaming state, start a second loader, estimate progress, or add a fake delay.

`LOADING` has presentation priority over `ZOMBIES`.

There is intentionally:

- no progress bar;
- no spinner;
- no percentage;
- no fake ETA;
- no modal window;
- no queued input behavior.

## Functional verification

Current prompt-owned disposable verifier pair:

- `game/scripts/ci/PromptWorldResolutionIndicatorSmoke.gd`
- `.github/workflows/prompt-world-resolution-indicator.yml`

Workflow:

- `Prompt World Resolution Indicator`

Verified functional head before documentation:

- `bda3b12b31430b8feafa0a5b52e4bec2d99647aa`

Successful focused run:

- run `34180003360`
- job `101916994037`
- `PROMPT_WORLD_RESOLUTION_INDICATOR_SMOKE: PASS`

The real seed-20001 production-scene proof confirms:

1. real `main.tscn` boots with the existing System-39 root;
2. the indicator is mounted and configured from authoritative owners;
3. ready state is silent and player controls are enabled;
4. real stream-active infected exist;
5. an ordinary player action opens shared WHEN;
6. `ZOMBIES` becomes visible while that shared world time resolves;
7. existing player input remains locked during the same interval;
8. a technical active-region transition raises `LOADING`;
9. `LOADING` overrides `ZOMBIES` without inventing a new simulation pause;
10. when shared WHEN returns to the player decision pause, `ZOMBIES` clears and controls unlock;
11. a region transition while no zombie resolution is active still shows `LOADING`;
12. `LOADING` clears without a spinner, progress bar, or persistent modal.

The focused run parsed cleanly and required no gameplay, infected, combat, WHEN, or streaming repair.

## Documentation closure

Material documentation writes before this final handoff:

- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md`
  - updated at commit `a5d66e023aaa5454fa3ef30cf2c5f5d502b99820`;
  - records the `ZOMBIES` / `LOADING` presentation contract, focused evidence, ownership boundary, and unchanged next gameplay operation.
- This `README_CONTEXT.md` update is the **FINAL repository write for this prompt**.

After this file is committed, perform read-only exact-head verification only. No repository mutation is permitted after this handoff write.

## Current prompt-owned CI turnover rule

At the START of the next code prompt, delete FIRST:

- `game/scripts/ci/PromptWorldResolutionIndicatorSmoke.gd`
- `.github/workflows/prompt-world-resolution-indicator.yml`

Then:

1. read this `README_CONTEXT.md` first;
2. read `README_SOPS.md` second;
3. fetch current `main` once;
4. create one brand-new focused verifier pair only for the generated-house environmental-pressure work actually changed.

Do not restore this prompt verifier afterward, the prior System-39 prompt verifier, count-ladder verifier, infected/combat verifiers, broad architecture fleets, routine seed matrices, or unrelated historical regression suites.

# NEXT OPERATION — REAL GENERATED-HOUSE ENVIRONMENTAL PRESSURE

Do **not** add route-planning architecture first.

Use the existing production eight-member cohort and closed System-39 chain against **naturally generated seed-20001 island houses and their existing generated doors/windows**.

The next focused verifier must use real generated building/opening geometry rather than prompt-created door/window semantics.

Prove, in order:

1. identify a suitable real generated seed-20001 house/building and one of its existing exterior doors or windows through existing world/materialization/building truth;
2. use a real resident-backed infected from the production cohort;
3. establish a lawful destination from observer-scoped System-23 sight/last-seen truth or a System-26 heard observation — never hidden exact player coordinates;
4. let ordinary shared-WHEN movement approach the generated building;
5. confirm ordinary collision discovers the exact generated opening as the physical blocker;
6. submit the existing generic System-39 TRY OPEN / pressure path against that exact generated WHAT identity;
7. if the generated opening resists, prove resistance is learned only after the timed physical try;
8. prove repeated physical impacts change the same persistent opening condition and eventually change canonical passability when breach is physically reached;
9. prove impact/break sound propagates through System 26 and can cause another infected with no visual target knowledge to independently investigate;
10. prove the infected passes through the changed generated opening using ordinary movement or the existing window-climb action;
11. preserve ordinary ACTOR congestion and exact resident/infection provenance throughout.

## Navigation gate

If that real generated-building scenario succeeds with current bounded local behavior, **stop there**. Do not add pathfinding.

Only if that exact scenario exposes a concrete navigation failure should the failing geometry and behavior trace be inspected. Then add only the smallest **generic actor/world route-planning seam** needed to solve the demonstrated failure.

Do not preemptively add:

- global A*;
- horde routing;
- zombie navigation grids;
- flow fields;
- attack slots;
- shared destinations;
- magical door targeting;
- teleport correction;
- crowd coordinators.

## System 38 / 39 ownership — preserve

### Population / active cohort

- infected identities derive only from already-counted household resident slots;
- no extra zombie population exists;
- `InfectedState` remains an overlay on shared human actor identity;
- production active cohort remains **8**;
- 16 is functionally proven but intentionally not adopted;
- `WorldStreamingCoordinator` remains the sole active-envelope authority.

### Perception / behavior / sound

- System 23 owns observer-scoped vision and memory;
- System 26 owns uncertain heard observations;
- no hearing path may leak hidden exact source identity to behavior;
- intentions remain deliberately small: idle / pursue visible / pursue last seen / investigate sound / attack visible / press barrier;
- no group brain, shared target truth, per-frame AI, private zombie clock, or magic attraction radius.

### Time / movement / collision / openings

- WHEN owns simulation time, readiness, phases, interruption, and the player decision pause;
- movement/world/collision own physical locomotion and blockers;
- infected occupy ordinary blocking ACTOR cells;
- System 39 reacts only to exact physical opening blockers found through those owners;
- opening damage is generic persistent opening condition, not zombie building HP;
- canonical door/window owners control broken/open/passable state;
- System 26 carries impact/break sound consequences;
- System 37 owns actor combat;
- Health/generic corpse transition owns mortality.

## Protected neighboring contracts — preserve

- exact firearm/magazine/live-round identity remains containment truth; no integer ammo counters;
- reload remains WHEN RESUMABLE with truthful eject/insert/chamber state;
- player ordinary LOCK/UNLOCK remains retired; locked openings do not leak hidden lock truth;
- shattered-window replacement remains deferred until real glass exists;
- exact selected item -> lawful action -> authoritative WHEN -> exact-entity consequence;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- skateboard remains one identity across loose/equipped/ridden;
- skateboard 2 cells / 2 ticks; bicycle 3 / 2; motorcycle/car/truck 3 / 1;
- mounted vehicle controls replace walking controls in the same footprint;
- UI owns no gameplay truth;
- no Survival window, Forage panel, player-visible Dev window, Zoom +/- buttons, or Health/Fatigue bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW + MAP remain available on foot/mounted.

## World / performance contracts — preserve

- world size 3072x3072;
- streaming regions 128x128, active radius 1;
- gateways four-lane paved;
- routes touching town/crossroads paved two-lane unless gateway;
- rural-rural links may be gravel/dirt single-lane traversable;
- reference seed 20001 remains the focused generated-world target;
- water remains one municipal facility + service aliases with deterministic rural wells and no municipal pipe network;
- wastewater remains retired;
- do not reintroduce routine 12-seed testing.

## Final closure rule

This file is the final repository mutation for the world-resolution-indicator prompt.

From this point onward in this prompt:

- do not edit code;
- do not edit docs;
- do not delete the current prompt verifier;
- do not create commits;
- do not rerun by changing workflow files;
- only perform read-only branch, commit, focused-CI, and Pages verification.
