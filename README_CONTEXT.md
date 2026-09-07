# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — ONE RESIDENT-BACKED INFECTED FULL BEHAVIOR LOOP CLOSED 2026-09-07

Production root:

`game/main.tscn -> CombatGameMain.gd -> VehicleGameMain.gd`

System 37 lethal combat remains closed: physical melee/contact, exact firearm/magazine/live-round identity, physical firing, RESUMABLE reload with truthful intermediate state, System-26 firearm sound, and generic Health-driven death/corpse transition.

System 38 now has one fully production-proven resident-backed infected:

> **population record -> hydration -> observer-scoped perception/hearing -> intention -> ordinary WHEN movement/combat -> generic death**

The one-infected loop is complete. Do not redesign it merely to add zombie variety. The next operation is controlled scaling to a **small active resident-backed infected cohort**, with activation/streaming and measured event-driven scheduling/performance before any horde-scale count.

## Prompt start / turnover completed

This prompt started after deleting the prior prompt-owned firearm/death verifier pair FIRST:

- `game/scripts/ci/PromptCombatFirearmDeathSmoke.gd`
- `.github/workflows/prompt-combat-firearm-death.yml`

Turnover commits:

- `595e9f60e5f48c47cbf8f7b0682b70a79bd14809`
- `464b5c219f54b08254df5c4baac65fdaad9f2584`

Then `README_CONTEXT.md` was read first, `README_SOPS.md` second, and `main` was fetched once. Prompt starting head after turnover:

- `464b5c219f54b08254df5c4baac65fdaad9f2584`

No historical broad gameplay fleet, architecture suite or seed matrix was restored.

## System 38 — first infected behavior closure

### Behavior is an adapter, not another simulation

New production owner:

- `game/scripts/simulation/infected/FirstInfectedBehaviorService.gd`

It owns only intention selection. It does **not** own:

- a second clock;
- per-frame AI updates;
- visual truth;
- hearing/source truth;
- collision/path teleporting;
- Health/damage;
- attack cooldowns;
- a duplicate zombie combat system.

Implemented intention vocabulary is deliberately small:

- `infected.idle`;
- `infected.pursue_visible`;
- `infected.pursue_last_seen`;
- `infected.investigate_sound`;
- `infected.attack_visible`.

### System-23 vision

`CombatGameMain` gives the exact already-hydrated infected its own `ObserverPerceptionService` using:

- canonical world + doors;
- shared WHEN clock;
- shared `PerceptionMemoryStore` under the infected's own observer ID;
- the same visual-acquisition provider used by the player, preserving lighting/acquisition rules.

Behavior acquires the player only from the infected observer's System-23 actor memory/current `VISIBLE` state.

Rules now proven:

- currently visible player -> pursue current observed cell;
- visible player in physical forward contact -> attack;
- lost current LOS -> may pursue the last seen player cell;
- no direct hidden player placement lookup grants visual pursuit.

### System-26 hearing

The exact resident-backed infected is registered as an ordinary `SpatialSoundService` listener.

Behavior consumes only observer-safe `HeardSoundObservation` truth. For sound investigation:

- target = System-26 `perceived_cell`;
- exact hidden source actor identity is absent;
- hearing never becomes a magic aggro radius;
- external investigation is latched so the infected's own footstep cues do not replace the external perceived destination with fake exact-source knowledge;
- a cue perceived on the infected's own occupied cell is not used as an investigation destination.

### Shared WHEN / movement

There is no infected simulation timer.

While the player is decision-paused, render frames do not advance the infected. Perception/intention can update from real simulation events, but physical behavior waits for the shared WHEN world clock.

When the player commits an action, WHEN clears decision pause before `action_started` is emitted. A ready infected can therefore submit its ordinary action at the same current world tick. When the infected's action completes while world time is still running, it may select and submit its next ordinary action.

Pursuit/investigation uses the existing movement owner only:

- normal turn left/right;
- normal step forward;
- normal collision/traversal checks;
- deterministic directional preference;
- only a bounded local left/right detour if the direct step is blocked.

No full crowd pathfinder was invented during the one-actor proof.

### System-37 attack

When the currently visible player occupies the infected's physical forward contact cell, the behavior adapter asks `CombatActionService` for lawful strike offers and submits the ordinary strike.

The current empty-handed production infected uses normal `combat.strike_unarmed` and reaches canonical System-37 CONTACT/Health consequences. There is no infected-specific damage or cooldown.

### Death shutdown

Canonical Health/generic death remains authoritative. When the infected reaches HP <= 0:

- generic death removes living ACTOR occupancy and creates corpse truth;
- the behavior loop stops;
- it submits no additional movement/combat actions;
- `InfectedState` retains the same population/resident provenance after death.

## Focused verifier and failures repaired

Current prompt-owned disposable pair:

- `game/scripts/ci/PromptFirstInfectedBehaviorSmoke.gd`
- `.github/workflows/prompt-first-infected-behavior.yml`

Fresh workflow name:

- `Prompt First Infected Behavior`

The verifier boots real `res://main.tscn`; it is not a disconnected AI unit test.

### Initial compile failure

Run `34171408724` stopped at parsing only:

- `CombatGameMain` redeclared two preload names inherited from `GameMain`;
- two verifier candidate cells required explicit `Vector2i` typing.

The parser defects were corrected without changing intended gameplay behavior.

### First executable behavior run

Run `34171525608` proved production System-23 visual memory and System-26 heard observations were working, but behavior had fail-stopped before action submission.

Root cause was the verifier fixture, not production behavior:

- test relocation used `unplace_entity()` followed by `set_placement()`;
- the intermediate unplaced state emitted a real observer-missing event;
- production behavior truthfully stopped because the infected temporarily had no living ACTOR placement.

`WorldMutationService.set_placement()` already atomically replaces an existing placement. The verifier was repaired to use that canonical path; no gameplay assertion was weakened.

### Successful functional proof

Verified functional head:

- `90f1c0c974afebcee71403bdd39c8ce4d7a52451`

Focused run:

- `Prompt First Infected Behavior` run `34171663807` — **SUCCESS**

The successful production-scene log proves:

1. first resident-backed infected is still hydrated;
2. behavior loop is running;
3. infected has a real System-23 observer;
4. population/infection provenance exists and remains stable;
5. render frames do not advance it during player decision pause;
6. truthful visible player observation becomes `pursue_visible`;
7. player commitment opens the shared WHEN clock;
8. infected autonomously submits ordinary movement;
9. visible pursuit uses normal movement actions;
10. contact pursuit submits ordinary System-37 strike;
11. strike causes canonical player Health damage;
12. an unseen-player scenario receives a real propagated System-26 cue;
13. heard cue becomes `investigate_sound`;
14. auditory intention contains no hidden exact source actor ID;
15. auditory target equals System-26 perceived cell;
16. investigation movement physically advances toward that perceived cell;
17. canonical lethal Health damage stops behavior and removes ACTOR occupancy;
18. dead infected submits no later WHEN actions;
19. resident/infection provenance survives death.

The log ended:

`PROMPT_FIRST_INFECTED_BEHAVIOR_SMOKE: PASS`

## Material documentation updated

- `SYSTEM_DESIGNS/38_FIRST_INFECTED_POPULATION_HYDRATION.md` — hydration + observer-scoped perception/hearing + intention + ordinary WHEN movement/combat + death shutdown now documented as closed; docs commit `b3d487d61a906743d7c5bc3a3798820afd967862`.
- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md` — one-infected behavior closure/failure evidence/scaling boundary recorded at docs commit `39da08a9242a0817fb509dec77f4bc55173d981f`.

## Current prompt-owned CI turnover rule

At the START of the next code prompt, delete FIRST:

- `game/scripts/ci/PromptFirstInfectedBehaviorSmoke.gd`
- `.github/workflows/prompt-first-infected-behavior.yml`

Then read this file, read `README_SOPS.md`, fetch current `main` once, and create one brand-new verifier pair only for the small-cohort/scaling code actually touched.

Do not restore the firearm/death verifier, melee verifier, human/mobile verifier, broad architecture suites, historical gameplay fleets or seed matrices.

## Protected neighboring contracts — preserve

### Combat / infected

- infection is an overlay on shared human actor identity, currently semantic `actor.survivor`;
- resident IDs derive deterministically from already-counted household slots;
- no extra zombie population is invented;
- System 23 owns observer-scoped vision/memory;
- System 26 owns uncertain heard observations and must not leak hidden source identity;
- WHEN owns world time/readiness/interruption;
- movement/world/collision own physical locomotion;
- System 37 owns melee/firearm physical combat;
- Health/generic death owns HP/corpse transition;
- exact firearm/magazine/round identities remain physical containment truth, never ammo integers;
- reload remains WHEN RESUMABLE with physical eject/insert/chamber intermediate state;
- no Combat skill;
- no zombie-only clock, magic aggro radius, private attack cooldown or duplicate combat/Health.

### Vehicle / skateboard

- on foot click exact vehicle for lawful interaction;
- REPAIR/REFUEL appear there when physically valid; HOTWIRE mounted-only;
- clicking one vehicle never silently operates another;
- no separate vehicle-maintenance panel;
- `ADD RACK` is optional/legacy, not protected gameplay;
- skateboard 2 cells / 2 ticks; bicycle 3 / 2; motorcycle/car/truck 3 / 1;
- skateboard only is brakeless and may reverse/dismount while moving;
- other vehicles require stopped state before reverse/exit;
- mounted controls replace walking controls in the same footprint.

### Inventory / equipment / interaction

- exact selected item -> lawful action -> authoritative WHEN -> exact entity consequence;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- one physical item cannot occupy multiple slots;
- skateboard remains one identity across loose/equipped/ridden, legal equipment destinations RIGHT/LEFT/BACK only;
- shared world chooser preserves all actionable exact overlapping targets;
- UI owns no gameplay truth.

### Doors / lighting / utilities

- locked closed openings expose TRY OPEN rather than hidden lock truth;
- break/board/unboard/climb remain closed work;
- shattered-window repair waits for real replacement glass;
- fixed room lighting follows System-33 power; no residential light-switch gameplay;
- exact flashlight owns persistent switched state; no invented battery depletion;
- generators use real INSPECT/REFUEL/START/STOP fuel/running/local-power truth;
- physical power-support repair remains System 33B/System-33 truth.

### HUD / world

- no Survival/Forage/visible Dev windows;
- no visible Zoom +/- or Health/Fatigue bars;
- `Looking at:` remains below STATS/INVENTORY/MENU;
- CENTER/FOLLOW + MAP remain available on foot/mounted;
- island 3072x3072;
- stream regions 128x128 active radius 1 unless deliberately changed;
- reference seed 20001 remains roughly 627 buildings / 2184 residents / 2 towns / 3 crossroads / 30 rural settlements;
- no routine 12-seed matrix;
- wastewater/sewer/septic remain retired.

## Design philosophy — preserve

Target:

> **deep interaction as an emergent property of relatively light simulation**

For NPC/infected scaling especially, preserve the proven pattern:

> **perception -> intention -> ordinary WHEN action**

Prefer activation/streaming, event boundaries and shared owner truth over continuously ticking every actor.

## Permanent disposable prompt-local CI policy

`README_SOPS.md` remains authoritative:

- every code prompt deletes the previous prompt-owned smoke + workflow first;
- every code prompt creates a completely fresh focused verifier pair only for touched code;
- test touched play path plus necessary protected seam behavior only;
- no standing broad gameplay regression fleet;
- no historical architecture suite or seed-matrix restoration;
- `.github/workflows/pages.yml` remains deployment-only;
- inspect focused logs and repair actual production/fixture defects instead of weakening truthful assertions.

# NEXT OPERATION — SMALL ACTIVE INFECTED COHORT / SCALING PROOF

Do **not** jump directly to island-wide hordes.

Scale the now-proven first-infected pattern to a small deterministic set of additional **real resident-backed infected slots**.

Required architecture direction:

1. Keep population aggregate while inactive; hydrate only real already-counted resident slots entering the active simulation envelope.
2. Define explicit activation/deactivation/streaming ownership so inactive infected do not require live WHAT actors/perception loops.
3. Reuse the same per-actor System-23 observer-scoped vision and System-26 observer-safe hearing semantics.
4. Reuse the same small intention model and ordinary movement/System-37 WHEN actions; do not add special horde combat.
5. Avoid one per-frame `_process`/timer per infected. Use controlled event/tick boundaries and batch/bounded scheduling suitable for later scale.
6. Measure active-cohort behavior/performance before increasing counts.
7. Preserve physical collision/congestion; do not teleport actors through each other to make crowds easy.
8. Let shared sound/occupancy produce early group/herd effects before inventing authored group AI.

Start with a small cohort sufficient to expose scheduling, simultaneous action, collision and perception-cost problems. Only after that proof should active counts be increased toward horde-scale scenarios.

This `README_CONTEXT.md` update is the FINAL repository write for the one-infected behavior prompt. After this commit there must be **zero repository mutations**; perform only read-only exact-head / focused CI / Pages publication verification.