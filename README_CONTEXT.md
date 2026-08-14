# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request, not before every edit inside the same coherent batch.

## Identity

Working repo/project name: **Tick Survival Lab**.

GitHub repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

This is an original Godot 4 top-down survival project using “tick-based Project Zomboid-like” as design shorthand only. Do not copy Project Zomboid code, art, maps, UI, text, branding, characters, or other proprietary content.

## Source lineage

The bootstrap map format is extracted from **First Fire** by the same project owner.

Source repository:
`dmcexcess-lab/first-fire`

Source generator:
`game/scripts/FFTacticalEnvironments.gd`

Source-of-extraction First Fire commit:
`5014248de99447b0ca5629f10afd7ba92dd81bf3`

The extraction intentionally does **not** bring over First Fire's camp, menus, expedition orchestration, survivor roster, politics, save state, combat runtime, or companion logic.

## Current milestone

**Bootstrap 0.0 — Map Foundation**

Current canonical source:

```text
game/
  project.godot
  main.tscn
  scripts/
    TacticalMapGenerator.gd
    MapPreview.gd
    ci/MapSmoke.gd
```

`MapPreview.gd` is a disposable development harness. `TacticalMapGenerator.gd` is the durable seed.

## Map reality

The imported First Fire map system is not yet an infinite procedural world generator. It is a data-driven catalog of authored 20×18 locations with randomized environment/variant selection.

Current location families:

- Back Alley
- Gas Station
- Residential House
- Apartment
- Corner Store
- Warehouse Yard
- Drainage Wash

Each map can describe:

- ground regions;
- indoor regions;
- walls;
- doors and initial open/closed state;
- windows/glass;
- obstacles;
- props;
- explosive-barrel markers;
- light-source markers;
- player spawn;
- one or more exits.

This format is the starting physical language for the new game. Expand it rather than building a second unrelated map representation.

## Core design

One player character survives in a persistent hostile world.

The simulation is **tick-driven**. Actions have explicit time costs, and all active actors/world processes advance according to the same authoritative world clock. The eventual control feel may be responsive, but simulation time is discrete and inspectable.

Important intended properties:

- top-down 2D grid movement;
- facing matters;
- vision/fog/darkness matter;
- sound exists spatially and attracts infected already present in the world;
- doors/windows/obstacles are physical simulation objects;
- loot is physical and persistent;
- character condition and needs matter;
- combat is dangerous and is not the only objective;
- state persists instead of resetting when the player leaves a room/location;
- no AI director spawning threats merely to create drama.

## First playable slice

Do not start by recreating all of Project Zomboid.

The first playable slice is complete when one survivor can enter a generated/authored location, move on the tick clock, see/hear/interact with the environment, encounter persistent infected, physically loot useful items, suffer meaningful condition changes, and leave/return to a location whose important state remains changed.

After that works, expand toward connected-world generation/persistence.

## Scope boundaries for bootstrap

Not imported from First Fire:

- Camp/settlement simulation
- Camp politics/events
- Menu-driven expedition layer
- Multiple survivors or tactical companions
- First Fire crafting/building menus
- First Fire `Game.gd` state facade
- First Fire save schema
- First Fire release/ads code

Not required for the first playable slice:

- Multiplayer
- Vehicles
- NPC survivor simulation
- Factions
- Settlement management
- Large narrative system
- Giant crafting tree

These are not necessarily permanent bans. They are outside the bootstrap so the tick/world simulation can become excellent first.

## Architecture direction

Preferred dependency direction:

**map/data → persistent world state → tick scheduler/rules → actor simulation → presentation/input**

Rules should have one durable owner. UI must not own simulation state. The map generator must not become a dumping ground for combat, inventory, AI, or save logic.

Likely future module seams should be created only when their behavior actually exists, for example:

- world/tile state owner;
- tick scheduler;
- player actor rules;
- infected actor rules;
- vision/LOS;
- sound propagation;
- inventory/items;
- body/needs;
- persistence.

Do not prebuild empty architecture for imagined features.

## Platform

Platform target is intentionally not locked yet. Do not assume First Fire's phone-first constraints automatically carry over. Keep simulation/input separable so desktop controls can be developed without burying them inside world rules.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. Human `README.md`
6. Conversation memory only as supporting context

## Continuous deployment

`.github/workflows/pages.yml` is the permanent build/deploy gate. It validates the canonical scaffold, imports/parses with Godot 4.7.1, runs deterministic map validation, starts the real scene headlessly, exports Web, enables/configures GitHub Pages, uploads the artifact, and deploys it.
