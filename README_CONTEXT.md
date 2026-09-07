# Tick Survival Lab — Current Repository Handoff

This file is the authoritative short handoff for the next repository operation. Read this first, then `README_SOPS.md`. Do not broadly rediscover already-closed work.

## Current checkpoint — SYSTEM 37 COMBAT FOUNDATION + FIRST REAL INFECTED HYDRATION CLOSED 2026-09-07

Production root is now:

`game/main.tscn -> CombatGameMain.gd -> VehicleGameMain.gd`

The combat prerequisite for infected play is closed through real melee, exact firearm/ammunition state, resumable reload, generic living-actor death/corpse transition, and integrated production-scene verification against the first resident-backed infected.

The first infected is now a real production actor hydrated from the already-authoritative island population plan. It is **not autonomous yet**. The next major phase is first-infected behavior through existing perception/sound/movement/combat/WHEN owners.

## Prompt start / turnover completed

This prompt began from exact `main`:

- `36027c1537909d3271859d72ad512a150e413752`

The previous prompt-owned combat-actions verifier pair was deleted first as required:

- `game/scripts/ci/PromptCombatActionsSmoke.gd`
- `.github/workflows/prompt-combat-actions.yml`

Then `README_CONTEXT.md` was read first, `README_SOPS.md` second, and current `main` was fetched once. No broad historical regression fleet or seed matrix was restored.

## System 37 — combat foundation now closed

### Existing melee slice retained

The earlier melee/action slice remains authoritative:

- `combat.strike_primary` uses the exact anatomical RIGHT HAND item;
- `combat.strike_secondary` uses the exact anatomical LEFT HAND item;
- `combat.strike_unarmed` requires a physically empty hand;
- `combat.shove` is a physical committed displacement attempt;
- strikes resolve through explicit CONTACT timing, not immediate button damage;
- movement before CONTACT is real evasion; attacks do not home;
- light effective striking mass is WHEN CANCELABLE;
- heavy strikes and shove are WHEN COMMITTED;
- same-tick contacts resolve together before decision pause;
- canonical Health owns HP/injury;
- System 34 owns Fatigue/condition, with no separate combat Stamina;
- System 26 owns physical combat sound;
- the shared System-29 chooser may expose exact visible ACTOR combat offers, but ACTOR occupancy alone grants no interaction;
- the practical on-foot center `STRIKE` / desktop `F` route remains the blind-forward physical attack intent.

Previous focused melee evidence:

- functional head `9e06f6949062c7598a6a595ca6daed5e369e52f8`;
- `Prompt Combat Actions` run `34165616529` — SUCCESS.

### Exact firearm / ammunition state

New authoritative firearm vocabulary:

- `item.firearm.service_pistol`;
- `item.firearm.magazine.9mm`;
- `item.ammo.9mm_round`.

`FirearmProfileCatalog` supplies the minimum physical firearm profile and registers canonical physical masses.

`FirearmState` owns only firearm-specific physical relationships:

- exact firearm WHAT ID;
- exact inserted magazine WHAT ID;
- exact chambered live-round WHAT ID.

Important invariant:

> **Ammunition truth is physical item identity, not an integer counter.**

The firearm and magazine are real containment owners. Magazine quantity is derived from the exact round WHAT entities contained by that magazine. Chambering moves one exact round from magazine containment into firearm containment.

### Fire / aim actions

`FirearmActionService` implements:

- `combat.fire_snap` — WHEN COMMITTED, discharge at tick +2, total 4 ticks, 6-cell first-slice range;
- `combat.fire_aimed` — WHEN COMMITTED, discharge at tick +5, total 7 ticks, 12-cell first-slice range;
- `combat.reload` — WHEN RESUMABLE.

Discharge:

- revalidates the same exact equipped firearm and exact chambered round;
- follows the latched forward direction through real terrain/collision cells;
- does not target-home;
- applies canonical Health damage/injury on a living actor hit;
- consumes that exact chambered live-round WHAT entity;
- cycles the next exact magazine round into the chamber when available;
- emits physical System-26 combat sound through `FirearmSoundEmitterAdapter`.

`CombatPlayerController` routes the existing `player.combat_forward` intent through an equipped firearm first. With no firearm it falls back to existing melee. An equipped empty-chamber firearm can enter its lawful reload path; UI does not own ammo state.

### Resumable reload

Reload physical phases:

1. `combat.reload_eject` — old exact magazine leaves firearm and returns to actor containment;
2. `combat.reload_insert` — selected exact compatible magazine moves into firearm containment;
3. `combat.reload_chamber` — one exact live round moves from magazine to firearm chamber.

`FirearmDamageInterruptionService` routes real Health damage into ordinary WHEN interruption. Because reload is RESUMABLE, completed physical phases remain true after interruption and resume continues the unfinished action using the same exact selected magazine.

The focused verifier specifically proves interruption after ejection leaves truthful empty-magwell / carried-magazine state, then resumes and inserts the same replacement magazine rather than resetting or teleporting ammunition.

### Generic living-actor death / corpse transition

`ActorDeathTransitionService` watches canonical Health crossing from HP > 0 to HP <= 0. Death is generic actor consequence, not firearm-only or infected-only behavior.

On death it:

1. force-fails any active WHEN action;
2. creates exact persistent corpse identity `corpse.<actor_id>` with semantic `object.corpse`;
3. enrolls the corpse as a real containment owner;
4. clears living right/left hand assignment;
5. moves the actor's exact directly carried WHAT identities into corpse containment;
6. removes living ACTOR placement;
7. places the corpse at the same physical location;
8. records source actor <-> corpse provenance in `CorpseState`.

Exact items are moved, never copied into a fake loot table. `object.corpse` has an explicit non-blocking collision profile so corpse persistence does not accidentally become UNKNOWN blocking geometry.

The first firearm/death focused run found a real integration defect: the new death listener initially used the wrong Health `hp_changed` arity. Production was repaired to the canonical five-argument signal contract; the verifier assertion was not weakened.

## System 38 — first real infected hydration closed

### Population truth remains aggregate and authoritative

`IslandWorldPlanner` already runs `IslandPopulationPlanner` and retains on the generated global plan:

- `population_settlements`;
- `resident_population`;
- `infected_population`;
- `survivor_population`;
- `local_area_manifest`.

Settlement records contain real household building IDs and resident capacities. The planner intentionally does not pre-create thousands of person entities.

### Deterministic resident-slot projection

`PopulationResidentProjection` gives stable individual identity to already-counted household capacity only when an individual is needed.

Resident IDs are derived as:

`resident.<building_id>.<ordinal>`

Each projected record preserves:

- exact resident ID;
- source building ID;
- household resident ordinal;
- settlement ID;
- area-site ID;
- real generated home/building cell.

A stable infection score is derived from world seed + building ID + resident ordinal. Within each settlement, exactly the existing `infected_population` number of resident slots is classified infected. This does not increment population totals or invent an extra zombie population.

### Infection is a human-state overlay

`InfectedState` stores infection/provenance on the exact human actor identity.

The production infected remains semantic:

- `actor.survivor`

This is deliberate. Infection is state/behavior, not a parallel species requiring duplicate Health/equipment/movement/combat owners.

### First active infected hydration

`FirstInfectedHydrationService`:

- selects a deterministic infected resident slot, preferring the central playable area;
- starts from that resident's real generated home cell;
- finds a real clear currently materialized cell within a bounded search radius;
- creates the exact resident ID as a normal ACTOR;
- enrolls canonical locomotion, hand equipment, inventory containment, Health, skills, carry and System-34 condition state;
- records infection/resident provenance;
- fails closed if a truthful materialized placement cannot be found.

`CombatGameMain` reuses the already-generated global population/local-area plan. It does **not** regenerate all 35 local areas just to obtain one infected. Player perception is recomputed after hydration.

The first integrated production boot exposed a narrow owner-interface defect: `ActorSkillState` and `ActorCarryState` do not expose `is_ready()` methods. The hydrator was corrected to their actual non-null/enrollment contract without changing those owners or weakening the test.

## Integrated focused verification

Current prompt-owned disposable pair:

- `game/scripts/ci/PromptCombatFirearmDeathSmoke.gd`
- `.github/workflows/prompt-combat-firearm-death.yml`

Integrated functional head:

- `e997ac13b74a1955fb5fe152f1b0753886009acc`

Successful focused run:

- `Prompt Combat Firearm Death` run `34170545140` — SUCCESS.

That unchanged production-scene verifier boots real `res://main.tscn` and proves:

1. production firearm and generic death/corpse owners are ready;
2. production first infected is hydrated;
3. its exact actor ID is a deterministic central household resident slot already counted infected;
4. infection overlays shared human semantic `actor.survivor`;
5. the exact actor has real ACTOR occupancy;
6. canonical Health, equipment, containment, condition, locomotion, carry and skill owners enroll;
7. exact firearm/magazine/live-round entities use real containment;
8. reload is WHEN RESUMABLE;
9. eject creates truthful physical intermediate state;
10. real damage interrupts reload without erasing progress;
11. resume inserts the same exact selected replacement magazine;
12. one exact persistent live round is chambered;
13. magazine quantity derives from remaining exact round identities;
14. the same real resident-backed infected can be physically repositioned into the focused firing scenario without changing identity;
15. that infected can carry/equip one exact item identity;
16. the infected can have an ordinary active WHEN action;
17. snap fire begins as a real timed action;
18. the exact chambered round is consumed on discharge;
19. lethal firearm consequence triggers the generic death transition on that exact infected;
20. death removes living ACTOR occupancy and creates persistent corpse occupancy;
21. death force-fails the infected's active WHEN action;
22. exact equipped/carried item identity moves into corpse containment without copying;
23. infection/population provenance survives the source actor's death;
24. corpse collision is explicit and non-blocking;
25. firearm discharge reaches System 26;
26. semiautomatic cycling chambers the next exact remaining magazine round.

The final log ended:

`PROMPT_COMBAT_FIREARM_DEATH_SMOKE: PASS`

## Material documentation updated

- `SYSTEM_DESIGNS/37_TACTICAL_COMBAT_PHYSICAL_IMPACT.md` — System-37 combat foundation now records melee + exact firearm/ammunition/reload + generic death/corpse closure and focused evidence.
- `SYSTEM_DESIGNS/38_FIRST_INFECTED_POPULATION_HYDRATION.md` — records aggregate population truth, deterministic resident-slot projection, infection-as-human-state overlay, first hydration, integrated death/combat evidence, and explicit behavior boundary.
- `SYSTEM_DESIGNS/29_IMPLEMENTATION_CHANGELOG.md` — records this combat + first-infected closure.

## Deliberately not implemented yet

Do not misread this checkpoint as full infected/NPC completion.

Still deferred:

- autonomous infected perception/intention behavior;
- heard-sound investigation;
- autonomous movement/action submission;
- infected attacks against player through System 37;
- scaling hydration to many infected;
- survivor NPC behavior/dialogue;
- true stability/knockdown/brace system;
- broader firearm/magazine/ammunition catalog and advanced firearm mechanics;
- richer corpse dragging/decomposition unless later justified by physical primitives.

No Combat skill was reintroduced.

## Fresh disposable verifier for this closed prompt

Current prompt-owned pair to delete FIRST at the start of the next code prompt:

- `game/scripts/ci/PromptCombatFirearmDeathSmoke.gd`
- `.github/workflows/prompt-combat-firearm-death.yml`

Then create one brand-new prompt-local focused verifier pair only for first-infected behavior actually changed. Do not restore historical combat, architecture, seed-matrix or broad regression fleets.

## Protected neighboring contracts — preserve

### Vehicle / skateboard

- on foot click the exact vehicle for lawful ordinary interaction;
- REPAIR / REFUEL appear there only when physically valid;
- HOTWIRE remains mounted-only;
- clicking one vehicle must never silently operate another;
- no separate vehicle-maintenance window;
- `ADD RACK` is optional/legacy, not a protected gameplay requirement;
- skateboard movement 2 cells / 2 ticks;
- bicycle 3 / 2;
- motorcycle/car/truck 3 / 1;
- skateboard only is brakeless and may reverse/dismount while moving;
- other vehicles require stopped state before reverse/exit;
- mounted controls replace walking controls in the same lower footprint.

### Inventory / equipment

- exact selected persistent item -> lawful action -> authoritative WHEN -> mutate/remove only that exact entity;
- skateboard remains one physical identity across loose/equipped/ridden states;
- skateboard legal equipment destinations RIGHT HAND / LEFT HAND / BACK only;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- one physical item cannot occupy multiple slots.

### Doors / windows / lighting / utilities

- closed locked openings expose TRY OPEN rather than leaking hidden lock truth;
- break/board/unboard/climb remain existing closed work;
- shattered-window repair remains deferred until real replacement glass exists;
- generated fixed room lighting follows System-33 power automatically; no residential light-switch gameplay;
- exact flashlight item owns persistent switched state; no invented battery depletion;
- portable generator ordinary click INSPECT/REFUEL/START/STOP uses real fuel/running truth and only local-power contribution;
- physical distribution-support repair remains System 33B/System-33 truth; direct span repair waits for clickable WHAT span identity.

### Player HUD / interaction

- no Survival window;
- no Forage panel;
- no player-visible Dev window;
- no visible Zoom +/-;
- no Health/Fatigue bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW + MAP remain available on foot/mounted;
- walking controls disappear while mounted and vehicle controls replace the same footprint;
- shared world chooser preserves every actionable exact overlapping target;
- action/cancel controls remain touch-practical and chooser remains viewport-clamped;
- UI owns no game truth.

### World / streaming

- island 3072x3072;
- stream regions 128x128, active radius 1 unless deliberately changed;
- gateway roads four-lane paved;
- routes touching town/crossroads paved two-lane unless gateway;
- only rural-rural links gravel/dirt, traversable single lane;
- reference seed 20001 roughly 627 buildings / 2184 residents / 2 towns / 3 crossroads / 30 rural settlements;
- exactly one municipal water facility plus aliases;
- no municipal pipe/node/pressure graph;
- deterministic 10–20% rural private wells only;
- wastewater/sewer/septic retired;
- no routine 12-seed matrix.

## Design philosophy — preserve

Target:

> **deep interaction as an emergent property of relatively light simulation**

Prefer exact physical/stateful primitives over bespoke genre features:

- WHAT identity;
- containment;
- equipment/hand state;
- material/condition/damage;
- collision/LOS;
- perception and sound;
- power/fuel/fluid;
- temperature/weather exposure;
- tools/capabilities;
- weight/carry;
- authoritative WHEN action timing and interruption.

For infected behavior especially, reuse ordinary actor actions. Do not create a zombie-only simulation clock, magic aggro radius, teleport movement, private attack cooldown, duplicate health, or duplicate combat system.

## Permanent disposable prompt-local CI policy

`README_SOPS.md` remains authoritative:

- every code prompt deletes the previous prompt-owned smoke + workflow first;
- create a completely fresh focused verifier pair only for code actually changed;
- test only touched play path plus necessary protected seam behavior;
- no standing broad gameplay regression fleet;
- no historical architecture suite / seed matrix restoration;
- `.github/workflows/pages.yml` remains deployment-only;
- inspect actual focused job logs and repair production defects instead of weakening truthful assertions.

# NEXT OPERATION — FIRST INFECTED BEHAVIOR

Start the next code prompt by deleting the current firearm/death prompt-owned verifier pair, reading this file first, then `README_SOPS.md`, then fetching current `main` once.

Build behavior for **exactly the already-hydrated first resident-backed infected** before scaling population hydration.

Target architecture:

> **perception -> intention -> ordinary WHEN action**

Use existing owners:

- System 23 current visual/perception truth;
- System 26 heard-sound observations/uncertainty;
- ordinary actor placement/collision/movement;
- System 37 melee/combat actions;
- canonical Health/condition;
- the one shared WHEN clock.

Minimum first behavior closure should prove the real infected can:

1. perceive a currently visible player without omniscient position access;
2. hear/investigate a real propagated System-26 sound when the player is not visible;
3. choose a small deterministic intention from those observations;
4. submit ordinary movement actions on the shared WHEN clock toward the lawful perceived/investigated target;
5. submit ordinary System-37 attack when physically in reach;
6. stop acting when generic death removes living ACTOR occupancy;
7. retain the same resident/infection provenance throughout.

Do not scale to hordes until one actor's behavior loop is correct and focused-CI proven.

This `README_CONTEXT.md` update is the **FINAL repository write** for the combat/firearm/death/first-infected-hydration prompt. After this commit there must be zero repository mutations; only read-only exact-head branch / focused-CI / Pages verification is allowed.