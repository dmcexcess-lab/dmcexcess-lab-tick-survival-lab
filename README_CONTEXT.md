# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2 OVERLAPPING CONSEQUENCE PRESENTATION CLOSED — 2026-09-25

Phase 1 remains complete. Phase 2 commitment windows, simultaneous melee consequences, causal movement/shove/death ordering, the closed mob-force core, canonical fear, bounded eight-infected callback/perception cost, and coherent overlapping consequence presentation are now protected.

Starting main for this operation: `bd94f7e13556c68277026dacde95d20bc4170676`.

Functional/executable owning head: `e76f9411f297c753f5c439b30756110622b814c3`.

Focused verifier owning head/run: `e76f9411f297c753f5c439b30756110622b814c3` / `36207564242` — **SUCCESS**.

Functional-head Pages run: `36207564248` — **SUCCESS**.

Documentation head immediately before this final handoff write: `66a2bf3b4aa9375449a8d677809926f945850627`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous infected-performance verifier/workflow were retired before production code work:

- `game/scripts/ci/Phase2InfectedPerceptionPerfSmoke.gd`
- `.github/workflows/phase2-infected-perception-perf.yml`

Fresh current pair:

- `game/scripts/ci/Phase2ConsequencePresentationSmoke.gd`
- `.github/workflows/phase2-consequence-presentation.yml`

The next code prompt must delete this pair before changing code and create a fresh focused verifier/workflow for the crowded-fight + Safari acceptance/performance route.

## Completed — one consequence moment per shared timestamp

New production presentation owner:

- `game/scripts/ui/ConsequenceMomentPresenter.gd`

It consumes already-resolved production signals from:

- Combat impact/shove;
- Movement commits;
- physical crowd-pressure summaries;
- generic actor death;
- Health consequence-batch closure.

It does not mutate gameplay truth, own combat/movement/health state, schedule WHEN work, or advance simulation time.

Events are grouped by canonical world tick. Combat consequence batches flush only after the existing Health batch closes, so already-earned movement/shove/death outcomes can join the same presentation moment.

## Completed — simultaneous combat remains visibly simultaneous

When two reciprocal hits resolve on the same timestamp, the player-facing surface explicitly presents them as a mutual exchange rather than serial enemy turns.

Mutual lethal remains visibly mutual and uses one shared consequence summary.

Multiple same-tick impact/death events do not become separate cinematic waits or action locks.

## Completed — movement, shove and mob pressure are legible together

The presenter groups:

- shove success/failure;
- pressure displacement/trapping;
- same-timestamp actor movement;
- combat impact/death when they share the timestamp.

Repeated pressure summaries for the same target/timestamp are coalesced.

A lone ordinary movement event is suppressed, preventing routine infected movement from spamming the consequence surface.

No crowd-force or movement-resolution rules changed.

## Completed — resident-backed infected labels use real identity

The first focused run exposed a presentation defect: resident-backed infected actor IDs do not necessarily contain the literal word `infected`.

The production presenter now receives the actual hydrated active-cohort actor IDs from `CombatGameMain` and uses that identity set for player-facing labels.

No actor identity or hydration truth was changed.

## Focused verifier evidence

Fresh verifier/workflow:

- `game/scripts/ci/Phase2ConsequencePresentationSmoke.gd`
- `.github/workflows/phase2-consequence-presentation.yml`

Initial run:

- `36207501236` — **FAILURE**
- correctly exposed the resident-backed infected labeling defect;
- production was repaired rather than weakening the assertion.

Final functional run:

- head: `e76f9411f297c753f5c439b30756110622b814c3`
- run: `36207564242`
- result: **SUCCESS**

Marker:

`PHASE2_CONSEQUENCE_PRESENTATION_OK`

The production-scene verifier proves:

1. the presenter is wired to real Combat/Movement/Death production signals;
2. two reciprocal hits remain one simultaneous consequence moment;
3. mutual death remains visibly mutual;
4. shove + pressure + two same-tick moves are grouped coherently;
5. duplicate pressure for one target is coalesced;
6. one isolated ordinary movement does not create presentation spam;
7. presentation work leaves the WHEN world tick unchanged.

## Phone/Safari presentation contract

The consequence surface is:

- viewport-relative;
- non-interactive;
- presentation-only;
- free of cinematic delays or timers that gate the next decision.

No desktop-only input assumption was introduced.

## Durable documentation updated

- `SYSTEM_DESIGNS/37_TACTICAL_COMBAT_PHYSICAL_IMPACT.md` records the consequence-presentation contract and focused proof.
- `ROADMAP.md` marks overlapping consequence presentation complete and advances Phase 2.
- `CHANGELOG_LATEST.md` records implementation, verifier evidence and the repaired labeling defect.

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
9. bounded eight-infected callback/perception path;
10. coherent overlapping consequence presentation.

## NEXT OPERATION

Continue Phase 2 directly with the **crowded-fight + Safari acceptance/performance route**.

Do not reopen mob force, fear, infected scheduling, Perception performance or consequence presentation without a concrete defect.

This next bounded slice is acceptance + attribution, not another architecture pass.

Targeted starting reads only:

- the current player action/run loop needed to drive a real crowded fight;
- the current fresh consequence presenter only as an observed output;
- current performance counters already exposed by the active infected cohort / perception owners;
- Safari/web input and viewport seams needed to exercise the same route;
- current Pages/export configuration only if the Safari run exposes a concrete web defect.

Required outcomes:

- run a real production crowded fight with the active eight-infected cohort through ordinary player actions;
- verify automatic decision-pause/input-lock behavior remains usable under crowd pressure;
- verify simultaneous impact/movement/shove/death presentation remains coherent in the real route;
- verify touch/mobile/Safari path for the same decision loop rather than a desktop-only substitute;
- measure end-to-end accepted-action/turn cost in the crowded route;
- attribute the remaining full-turn cost by existing measured phases before changing performance architecture;
- only optimize a component if this acceptance evidence identifies a concrete bounded bottleneck;
- no broad gameplay gate, no historical suites, no retired seed matrix;
- use one fresh prompt-local verifier/workflow scoped only to this acceptance/performance route.

After this acceptance/performance slice, Phase 2 should close or identify one concrete release blocker. Do not create a new indefinite technical phase.

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
- coherent same-timestamp consequence presentation;
- no presentation-owned gameplay truth or time advancement;
- player movement, Health/injury, inventory, condition/moodlets, skills/equipment;
- day/night, Weather, utilities and vehicles;
- persistence/terrain/streaming;
- input locked until legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
