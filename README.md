# Tick Survival Lab

A clean Godot 4 spin-off built around the tactical map foundation created for **First Fire**.

The design shorthand is “a tick-based Project Zomboid-like survival sandbox,” but this is an original project: no copied code, assets, maps, names, UI, or proprietary content from Project Zomboid. The reference is about the systemic survival fantasy—one fragile person, a persistent dangerous world, scavenging, sound, line of sight, injuries, needs, and long-term survival.

## What exists on day one

This repo begins with **only the reusable map foundation**, not First Fire itself.

- 20×18 grid map specification.
- Seven First Fire place families: back alley, gas station, house, apartment, corner store, warehouse yard, and drainage wash.
- Two authored variants per place.
- Ground regions, indoor regions, walls, doors, windows/glass, obstacles, props, barrels, light-source markers, player spawn, and exits.
- Structural validation that every map has a valid spawn and reachable exit.
- A tiny map-preview scene that exists only to prove the extracted generator works.

There is **no camp simulation, camp UI, survivor roster, expedition layer, politics, crafting menu, First Fire save schema, or First Fire combat runtime** in this bootstrap.

## Core game direction

The project is a **single-character, top-down, grid/tick-driven survival sandbox**.

The central rule is simple: **actions consume world ticks**. Walking, turning, opening a door, searching, attacking, reloading, climbing, treating a wound, eating, sleeping, and other actions take different amounts of simulation time. Other creatures and world systems advance on the same clock.

The intended feel is not an arena game. The player is trying to live in and move through a persistent place. Fighting is one tool and often a bad one.

### Initial scope

The first real playable slice should prove these systems before the project grows outward:

1. One player character moving through the existing map format.
2. Authoritative tick scheduler for player, infected, and timed world processes.
3. Facing, vision, darkness, sound, doors, windows, obstacles, and interaction.
4. Persistent infected that already exist in the world; no edge-spawn director used to manufacture pressure.
5. Physical loot/inventory/equipment.
6. Basic body state: health/injury, fatigue, hunger, thirst, and encumbrance.
7. Persistent local map state so opened doors, broken windows, moved/taken items, corpses, and cleared spaces remain changed.
8. Expansion from individual tactical places into a connected persistent world only after the local simulation is solid.

### Not part of the first slice

Multiplayer, vehicles, NPC companions, faction simulation, settlement management, elaborate story systems, and huge crafting trees are not bootstrap requirements. They can be evaluated later instead of being assumed now.

## Map architecture

`game/scripts/TacticalMapGenerator.gd` is the first permanent owner. It is deliberately independent from UI and gameplay simulation.

It returns map data. Future systems consume that data; they do not hide gameplay rules inside the generator.

```text
map data → world state → tick simulation → player/AI rules → presentation/input
```

The current First Fire maps are **authored layouts with randomized place/variant selection**, not an infinite procedural city generator. That is intentional for the bootstrap. If the project later needs a large continuous world, the existing layout format becomes the building block rather than being mistaken for something it is not.

## Run the bootstrap

Open `game/project.godot` in Godot 4 and run the project.

The preview draws one extracted First Fire map. Click, press **Space**, **R**, or **Enter** to reroll the place/variant.

This preview is a development harness, not a final menu or gameplay screen.

## Web preview

GitHub Pages is built from `main` by `.github/workflows/pages.yml` using Godot's Web exporter.
