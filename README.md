# Tick Survival Lab

> **Ultima-style turn-based mini Zomboid.**

Tick Survival Lab is an original Godot 4 top-down zombie survival simulation built around a persistent open world, discrete-time actions, systemic consequences, and deliberately simplified-but-interconnected survival mechanics.

The guiding idea is:

> **Mini means reduced complexity, not reduced consequence or mood.**

The game should preserve the decisions, danger, causality and atmosphere created by deeper survival simulations without reproducing every internal variable those games track.

## Current status: modular design freeze

The project is being re-conceptualized around **strict replaceable modules** before the new runtime is written.

The currently deployed clean-reboot build remains playable as a reference, but `game/scripts/reboot/` is **frozen/deprecated architecture**. It is not the long-term game.

The most important design references are:

- [`PROJECT_NORTH_STAR.md`](PROJECT_NORTH_STAR.md) — short canonical game identity and anti-drift reference;
- [`DESIGN_DECISIONS.md`](DESIGN_DECISIONS.md) — cross-system decisions and rationale;
- [`README_CONTEXT.md`](README_CONTEXT.md) — current phase/status/routing index;
- [`DESIGN_WORKFLOW.md`](DESIGN_WORKFLOW.md) — describe → approve → implement → verify process;
- [`SYSTEM_DESIGNS/`](SYSTEM_DESIGNS/) — detailed per-system contracts and approval ledger;
- [`MODULAR_REBUILD_MASTER_DESIGN.md`](MODULAR_REBUILD_MASTER_DESIGN.md) — broad modular architecture inventory, with newer North Star/decision entries taking precedence where direction has evolved.

The master architectural rule remains:

> **Main is composition, not implementation.**

Every independently replaceable system gets a focused owner and public contract. A local change should not require digging through or rewriting thousands of unrelated lines.

## What the game is becoming

### Persistent open world

The long-term physical world is **logically continuous and persistent**, not fundamentally a sequence of disconnected tactical raid maps.

The engine may stream or partition the world internally for performance, but roads, utilities, parcels, buildings and other large-scale facts are planned in global world coordinates so local boundaries cannot independently invent incompatible geometry.

Once a place exists, persistent world state owns what happens to it: looted containers, broken openings, parked vehicles, corpses, construction and other meaningful consequences should still be there when the player returns.

### Turn-based time

The game is turn-based through an authoritative variable-duration tick/action system.

While the player chooses, the world is paused. A committed action consumes world ticks, and other actors/systems whose scheduled time arrives may act during those ticks. When the survivor is ready for another decision, the game automatically pauses again.

That makes slow actions dangerous without requiring ordinary real-time play.

A separate **hard application pause** is also a product requirement: if real life interrupts the player, the simulation must freeze safely. Being called away from the game should never be equivalent to making a bad tactical decision.

### Invisible tactical grid

The current spatial direction keeps an authoritative but invisible grid because it makes graphics, generation, collision, pathfinding, AI, saving and deterministic movement much simpler.

- actors move cell-to-cell;
- grid lines do not need to be shown;
- props and fixtures use whole-cell footprints;
- directional objects carry N/E/S/W orientation;
- suitable art may be rotated in 90-degree increments, while objects that look wrong when rotated can use explicit alternate-facing images;
- generation stores semantic object + facing, not atlas-specific draw instructions.

The exact wall/door/window representation is still being designed rather than assumed.

### Mini-Zomboid simulation

For every survival system we ask:

> **What meaningful player decision does the deeper simulation create?**

Then we implement the smallest causal model that preserves the decision, consequence and mood.

Health is the current example: instead of simulating literal blood flow, an injury can be described by body region, type, coarse severity, treatment/stabilization requirements and healing/worsening state. That simpler model can still change movement, action timing, combat ability and whether continuing an expedition is safe.

Some systems are intentionally allowed more depth because they define the game: persistent world state, tick/action timing, coherent generation, vision/perception, lighting, spatial sound, weather effects and outbreak/population simulation.

## Extraction-shooter influence

The extraction-shooter part is **risk/reward expedition structure**, not necessarily a separate raid-instance architecture.

A typical loop is:

**physical safety/base → choose gear/objective → leave into the persistent world → scavenge/explore/avoid/fight → accumulate risk and loot → decide when to return → get home alive → keep/use what you recovered.**

What matters is that you risk what you take out and own what you successfully bring home.

## Base direction

A base is fundamentally a **real physical place in the world**.

It may begin as the player's actual home and later become a farmhouse, warehouse or other site the player secures and develops.

Long-term mechanics can include physical storage, beds, work areas, refrigeration, generators/power, water, vehicles, construction, survivors, pets, crops and defenses. Higher-level UI may summarize those systems later without replacing their physical-world truth.

## Outbreak and player stories

A major long-term goal is to generate a populated pre-collapse world and simulate the outbreak causally rather than simply rolling a post-apocalypse zombie distribution.

World planning can establish geography, roads, utilities, parcels, homes, businesses, workplaces, households and population. Outbreak parameters then influence infection, awareness, emergency response, evacuation, infrastructure failure and population movement.

Distant simulation can run at coarser resolution for performance while preserving persistent causal state.

The player character should eventually be a real person who already belonged to that world. Character setup can include customizable identity, occupation/workplace, home, spouse/partner, children or other household members, relationships, pets, vehicle/resources, traits/skills and outbreak starting circumstances.

Known people are intended to be persistent actors, not merely scripted quest markers. Finding family can become an emergent world problem because the simulation determined where they actually were and what happened to them.

## Golden visual recovery baseline

The mature pre-clean-rewrite visual/system baseline is commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

The old artwork was **not lost**. The current repo still contains byte-identical copies of the mature six-atlas environment stack plus four directional player sprites.

The richer old look came from historical `TacticalTiles.gd`, which semantically combined:

- `tactical_atlas.svg`
- `clutter_atlas.svg`
- `world_art_atlas.svg`
- `building_props_atlas.svg`
- `final_environment_surfaces_atlas.svg`
- `final_environment_props_atlas.svg`
- `player_north/east/south/west.svg`

The modular renderer will recover those semantics rather than approximating them again.

## Current development process

No new major runtime system is coded merely because it has been discussed.

The project follows:

> **DESCRIBE → USER APPROVES → IMPLEMENT → VERIFY**

If a request spans several major systems, it should be broken into smaller pieces instead of attempting the whole game at once. Small scope does **not** mean placeholder scope: a small implemented slice should be real and finished to its approved contract.

The next foundational design work is below generation/rendering:

1. **Spatial Model** — grid/cells, object footprints, facing, structures/openings and world coordinates.
2. **Tick / Action / Pause Kernel** — variable action duration, scheduling, auto-pause and real-life hard pause.
3. **Persistent World Identity / State** — generation versus persistent ownership, entities/changes and streaming seams.
4. **Population / Household / Outbreak / Player-Story foundations**.
5. Then the generalized world-area data contract, rendering and local materialization/generation systems.

## Current live reference build

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/

The live build still runs the deprecated clean-reboot runtime until the new modular foundation is designed, approved and proven.

## Run current reference locally

Open `game/project.godot` in Godot 4.7.1 and run the project.
