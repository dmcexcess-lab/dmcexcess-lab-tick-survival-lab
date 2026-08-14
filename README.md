# Tick Survival Lab

An original Godot 4 top-down zombie-apocalypse survival simulation built around an authoritative world tick.

The design shorthand may reference Project Zomboid's systemic-survival scope, but Tick Survival Lab is original in code, art, maps, names, UI, content and implementation. First Fire is a same-owner source project whose reusable tactical/physical-world work may be cleanly adapted where it fits Tick's architecture.

## Core identity

The game is presented as **real time with automatic pause**.

The world pauses when the current player character is ready for an action. The player commits an action; simulation time advances while that action executes; every other actor/world process advances on the same authoritative tick clock; when the player becomes ready again, the game automatically pauses.

The world is the game. There is no separate camp or expedition layer.

The persistent **world is separate from the player character**. If a player character dies, the world can continue and a new survivor can become the player in the same seed, or the user can start an entirely new world seed.

## Current implementation

**Milestone 0.1 — Authoritative Tick Movement** is on `main`.

Current foundation includes:

- Godot 4.7.1 project and permanent GitHub Pages CI;
- seven authored location families / fourteen variants;
- walls, ground, doors, windows/glass, props/obstacles, light markers, spawns and exits;
- structural map validation;
- authoritative world tick scheduler;
- one player actor with four-direction facing/movement;
- walk/run costs plus fatigue/encumbrance-ready modifiers;
- mutable runtime door state;
- keyboard plus click/tap developer controls;
- visible tick/action developer HUD;
- ported First Fire lighting and tactical-sound helper rules with clean Tick-native dependencies.

## Design documents

- [Design Document](DESIGN.md) — authoritative long-form game direction and simulation principles.
- [Roadmap](ROADMAP.md) — ordered milestones from the current tick foundation through island/outbreak simulation.
- [First Fire Reuse Audit](FIRST_FIRE_REUSE.md) — what has been ported, what should be adapted later, and what must stay out.
- [GPT/Repository SOP](README_SOPS.md) — coding and repository operating rules.
- [Current Context](README_CONTEXT.md) — concise current-state context for future development prompts.

## Long-term direction

The intended world is a large cut-off island-like region containing city, suburban, industrial, rural, agricultural and wilderness areas. Destroyed/bombed bridges and failed infrastructure can show that the region once connected to a larger functioning world.

Long-term systems include persistent infected, sound/vision/lighting, detailed-enough injuries and medicine, use-based skills, skill/recipe books and recorded training media, inventory/loot/crafting, destructible/buildable environments, farming, autonomous human survivors and animals, emergent settlements built through free construction plus NPC job assignment, patrols/supply routes, vehicles, infrastructure reclamation, and eventually configurable outbreak epicenters/spread/response conditions plus occupation/family starting context.

The ambition is large; implementation remains incremental. The next work should strengthen the local action/perception/infected loop rather than racing ahead to island-scale simulation.

## Architecture

Current dependency direction:

```text
map/data → persistent world state → authoritative tick scheduler/rules → actor simulation → presentation/input
```

The UI never owns simulation truth. The map generator owns initial authored physical facts, not gameplay systems.

## Run

Open `game/project.godot` in Godot 4.7.1 and run the project.

## Web preview

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
