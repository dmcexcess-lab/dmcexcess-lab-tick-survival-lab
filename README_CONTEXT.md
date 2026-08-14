# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request, not before every edit inside the same coherent batch.

## Identity

Working repo/project name: **Tick Survival Lab**.

GitHub repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

This is an original Godot 4 top-down zombie-apocalypse survival simulation. Project Zomboid is a systemic-scope reference only; do not copy its code, art, maps, UI, names, text or proprietary content.

First Fire is a same-owner source project. Reusable tactical/physical-world work may be adapted after inspection, but Tick must not inherit First Fire's camp/menu/expedition architecture.

Durable design references now live in:

- `DESIGN.md`
- `ROADMAP.md`
- `FIRST_FIRE_REUSE.md`

## Current milestone

**Milestone 0.1 — Authoritative Tick Movement** is implemented.

Current canonical source includes:

```text
game/
  project.godot
  main.tscn
  scripts/
    TacticalMapGenerator.gd
    LocalWorldState.gd
    TickScheduler.gd
    PlayerActor.gd
    TacticalLighting.gd
    TacticalSound.gd
    MapPreview.gd
    ci/
      MapSmoke.gd
      TickSmoke.gd
      EnvironmentSmoke.gd
```

Ownership:

- `TacticalMapGenerator.gd` — authored initial physical map facts;
- `LocalWorldState.gd` — mutable local physical facts such as door state/collision;
- `TickScheduler.gd` — authoritative world tick/action ledger;
- `PlayerActor.gd` — current player location/facing/movement mode and timing modifiers;
- `TacticalLighting.gd` — dependency-free environment/carried-light calculation helpers adapted from First Fire;
- `TacticalSound.gd` — dependency-free surface/localization/ambient sound helpers adapted from First Fire;
- `MapPreview.gd` — development input/presentation harness only.

## Core timing design

The intended final control model is **real time with automatic pause**, not a classic synchronized turn system.

Normal loop:

1. world is paused because the player character is ready;
2. player commits one action;
3. simulation advances through that action's ticks;
4. other actors/world processes act on their own schedules during those ticks;
5. world auto-pauses when the player becomes ready again.

The player cannot normally cancel a committed action or tactical-pause mid-action. The actual pause menu may pause the application.

Actions will gain explicit interruption policies:

- committed through ordinary damage where physically sensible;
- interrupted/resumable from persistent intermediate state;
- interrupted/canceled;
- forced failure when death, unconsciousness, knockdown, lost limb/tool or other invalidation makes continuation impossible.

Long actions such as reloads should eventually have phases and persistent intermediate state.

Current implementation is still the simpler 0.1 immediate commit model; Milestone 0.2 in `ROADMAP.md` is the planned action-execution upgrade.

## Player/world separation

The persistent world is conceptually separate from the player character.

The world/save owns seed, calendar, outbreak history, actors, zombies, structures, construction/destruction, items, corpses, vehicles, crops, settlements, infrastructure and other persistent consequences.

The player is one mortal actor record within that world.

On player death, the user can eventually:

- play a new survivor in the same continuing world; or
- start a new world seed.

A later player can encounter the previous player's corpse, base, stash, family, vehicles and world consequences.

## Map/world direction

The imported First Fire map foundation remains an authored-layout catalog of 20×18 physical locations. Current families:

- Back Alley
- Gas Station
- Residential House
- Apartment
- Corner Store
- Warehouse Yard
- Drainage Wash

Each can describe ground, indoor regions, walls, doors, windows/glass, obstacles, props, barrels, light markers, player spawn and exits.

Do not replace this with a second incompatible map language. Long-term world hierarchy should compose it into:

**tile/object → building/location → local area/block → biome/district → large island world**

The long-term island mixes city, suburban, commercial/industrial, rural/farm and woods/wilderness biomes. Destroyed/bombed bridges and other failed crossings can make it clear the region used to connect to a larger world.

## Long-term simulation direction

The complete design is in `DESIGN.md`. Major intended systems include:

- persistent infected responding to sight/sound rather than drama-director spawns;
- darkness, lighting, facing and spatial sound;
- dangerous combat where slow actions expose the player to more enemy actions;
- hunger/thirst/fatigue/encumbrance/stress;
- body-region wounds, deep wounds, bleeding, sutures, fractures, splints and crutches;
- zombie infection and possible time-sensitive extremity amputation with permanent consequences;
- persistent inventory/loot/equipment;
- use-based skills;
- occupations as starting knowledge/competence rather than rigid classes;
- physical skill/recipe books, manuals and VHS-like recorded training media;
- destructible and freely buildable environment;
- farming/crafting/homesteading;
- autonomous human survivors, dogs, cats and livestock;
- free building + resources + assignable autonomous NPC jobs producing emergent settlements;
- multiple bases, patrols, scavenging parties and supply routes;
- tick-driven vehicles/logistics;
- reclaimable power/water/communications infrastructure;
- eventual new-world outbreak parameters including epicenter/spread/response/isolation factors;
- eventual starting occupation, family, friends, pets, home/work context, with those people as autonomous world actors.

## First Fire reuse policy

Before recreating a major tactical/world subsystem, inspect current First Fire for same-owner reusable work.

Port only coherent rules that fit Tick-native ownership. Remove `Game`, encounter UI, camp, expedition, objective and save-schema coupling. Add smoke coverage where practical.

Already reused/adapted:

- tactical authored map schema;
- tactical lighting helpers;
- tactical sound/localization helpers.

Good concepts to adapt later rather than copy wholesale:

- timing/load/fatigue concepts from `FFTacticalTime.gd`;
- facing/LOS/noise/infected scheduling concepts from `FFCombat.gd`;
- survivor/social concepts transformed into physical autonomous-world behavior.

See `FIRST_FIRE_REUSE.md` for the audit.

## Scope discipline

Do not attempt the whole roadmap at once.

The near-term vertical slice remains:

1. robust phased action scheduler/auto-pause/interruption model;
2. physical perception/lighting/sound;
3. persistent infected on the same clock;
4. core dangerous combat;
5. body/injury and inventory persistence.

Island-scale generation, settlements, vehicles, live outbreak simulation and large autonomous populations are long-term directions whose architecture should be permitted but not prematurely implemented.

## Architecture direction

Preferred dependency direction:

**map/data → persistent world state → tick scheduler/rules → actor simulation → presentation/input**

Rules get one durable owner. UI must not own simulation state. The map generator must not become a dumping ground for combat, inventory, AI, saves or social systems.

## Platform

Platform target is not locked. Keyboard and pointer/touch controls should continue to be developed together with input separated from simulation rules.

Current developer controls:

- WASD/arrows: turn toward direction first, then move if already facing it;
- Tab: toggle walk/run mode without advancing time;
- E/Space/Enter: toggle the door directly ahead if present;
- R: reroll/reset the current development map;
- click/tap around the player: directional turn/move;
- click/tap the player: interact with facing door;
- click/tap HUD regions: mode / interact / reroll.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `DESIGN.md` / `ROADMAP.md` / `FIRST_FIRE_REUSE.md`
6. Human `README.md`
7. Conversation memory only as supporting context

## Continuous deployment

`.github/workflows/pages.yml` is the permanent build/deploy gate. It validates the canonical scaffold, imports/parses with Godot 4.7.1, runs deterministic map/tick/environment smoke tests, starts the real scene headlessly, exports Web, uploads the artifact, and deploys GitHub Pages.
