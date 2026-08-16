# Tick Survival Lab

> **Ultima-style turn-based mini Zomboid.**

Tick Survival Lab is an original Godot 4 top-down zombie survival simulation built around a persistent open world, discrete-time actions, systemic consequences, player-built bases and deliberately simplified-but-interconnected survival mechanics.

The guiding idea is:

> **Mini means reduced complexity, not reduced consequence or mood.**

The game should preserve the decisions, danger, causality and atmosphere created by deeper survival simulations without reproducing every internal variable those games track.

## Current status: modular foundation implementation

The project is being rebuilt around **strict replaceable modules**.

The currently deployed clean-reboot build remains playable as a reference, but `game/scripts/reboot/` is **frozen/deprecated architecture**. It is not the long-term game.

The first canonical new subsystem is now implemented: **00A WHERE / Spatial Model** under `game/scripts/foundation/spatial/`, with its own permanent headless CI contract test.

Important design references:

- [`PROJECT_NORTH_STAR.md`](PROJECT_NORTH_STAR.md) — canonical game identity / anti-drift reference;
- [`DESIGN_DECISIONS.md`](DESIGN_DECISIONS.md) — cross-system decisions and rationale;
- [`README_CONTEXT.md`](README_CONTEXT.md) — current phase/status/routing index;
- [`DESIGN_WORKFLOW.md`](DESIGN_WORKFLOW.md) — describe → approve → implement → verify;
- [`SYSTEM_DESIGNS/`](SYSTEM_DESIGNS/) — detailed per-system contracts and approval ledger;
- [`MODULAR_REBUILD_MASTER_DESIGN.md`](MODULAR_REBUILD_MASTER_DESIGN.md) — broad architecture inventory; newer North Star/decision entries supersede older raid/extraction assumptions.

The master architectural rule remains:

> **Main is composition, not implementation.**

Every independently replaceable system gets a focused owner and public contract. A local change should not require digging through or rewriting thousands of unrelated lines.

## What the game is becoming

### Persistent open world

The long-term physical world is **logically continuous and persistent**, not a sequence of raid maps.

The engine may stream or partition the world internally for performance, but roads, utilities, parcels, buildings and other large-scale facts are planned in global world coordinates so local boundaries cannot independently invent incompatible geometry.

Once a place exists, persistent world state owns what happens to it: looted containers, broken openings, parked vehicles, corpses, construction and other meaningful consequences should still be there when the player returns.

There is **no extraction-shooter loop in the current design**. The survivor can roam indefinitely, relocate, live nomadically, establish multiple safe sites or never designate a formal base at all.

### Turn-based time

The game is turn-based through an authoritative variable-duration tick/action system.

While the player chooses, the world is paused. A committed action consumes world ticks, and other actors/systems whose scheduled time arrives may act during those ticks. When the survivor is ready for another decision, the game automatically pauses again.

That makes slow actions dangerous without ordinary real-time play.

A separate **hard application pause** is also a product requirement: if real life interrupts the player, the simulation must freeze safely. Being called away from the game should never be equivalent to making a bad tactical decision.

### Invisible tactical grid

The spatial foundation is now implemented and uses:

- authoritative global integer `Vector2i` cells;
- a centralized planning scale of roughly **1 meter per tactical cell**;
- cell-to-cell actors;
- no required visible grid lines;
- arbitrary one-or-more whole-cell object footprints;
- N/E/S/W semantic orientation;
- deterministic 90-degree footprint rotation around a stable anchor;
- **structure cells with explicit horizontal/vertical axis** for walls/openings;
- semantic world geometry only — no atlas or sprite assumptions.

Suitable art may later be rotated in 90-degree increments, while objects that look wrong when rotated can use explicit alternate-facing images. Rendering owns that choice; WHERE does not.

### Mini-Zomboid simulation

For every survival system we ask:

> **What meaningful player decision does the deeper simulation create?**

Then we implement the smallest causal model that preserves the decision, consequence and mood.

Health is the current example: instead of simulating literal blood flow, an injury can be described by body region, type, coarse severity, treatment/stabilization requirements and healing/worsening state. That simpler model can still change movement, action timing and combat ability.

Some systems intentionally deserve more depth because they define the game: persistent world state, tick/action timing, coherent generation, vision/perception, lighting, spatial sound, weather effects and outbreak/population simulation.

## Bases

A base is not a special map or mode. The player can build and secure a base **anywhere in the persistent world** where ordinary construction/occupancy rules allow it.

The player can fortify an existing house, develop open land, occupy a warehouse, maintain several safe sites, abandon one or move completely.

Long-term mechanics can include physical storage, beds, work areas, refrigeration, generators/power, water, vehicles, construction, survivors, pets, crops and defenses. Higher-level UI may summarize these later without replacing the physical-world truth.

## Outbreak and player stories

A major long-term goal is to generate a populated pre-collapse world and simulate the outbreak causally rather than simply rolling a post-apocalypse zombie distribution.

World planning can establish geography, roads, utilities, parcels, homes, businesses, workplaces, households and population. Outbreak parameters then influence infection, awareness, emergency response, evacuation, infrastructure failure and population movement.

Distant simulation can run at coarser resolution for performance while preserving persistent causal state.

The player character should eventually be a real person who already belonged to that world. Character setup can include customizable identity, occupation/workplace, home, spouse/partner, children or other household members, relationships, pets, vehicle/resources, traits/skills and outbreak starting circumstances.

Known people are intended to be persistent actors, not merely scripted quest markers.

## Foundational architecture

The lowest-level model is **WHERE / WHAT / WHEN**:

1. **WHERE — Spatial Model:** global grid coordinates, facing, footprints and structure/opening geometry. **Implemented.**
2. **WHAT — Persistent World / Entity State:** what terrain, objects, actors, items, construction and mutations actually exist. **Next bounded foundation system.**
3. **WHEN — Tick / Action / Pause Kernel:** who acts when, how long actions take, auto-pause and hard pause. **Later bounded foundation system.**

The map/world generator comes **after these contracts**. It creates the initial world using the same spatial/state language that construction and gameplay later mutate. It does not own reality.

## Golden visual recovery baseline

The mature pre-clean-rewrite visual/system baseline is commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

The old artwork was **not lost**. The current repo still contains byte-identical copies of the mature six-atlas environment stack plus four directional player sprites.

The richer old look came from historical `TacticalTiles.gd`, which semantically combined those sources. The modular renderer will recover those semantics rather than approximating them again.

## Current development process

The project follows:

> **DESCRIBE → USER APPROVES → IMPLEMENT → VERIFY**

If a request spans several major systems, it is broken into smaller pieces instead of attempting the whole game at once. Small scope does **not** mean placeholder scope: a small implemented slice should be real and finished to its approved contract.

Current foundation order:

1. Spatial Model (WHERE) — **implemented**
2. Persistent World / Entity State (WHAT)
3. Tick / Action / Pause Kernel (WHEN)
4. Global world planning / generation contract
5. Population / household / outbreak / player-story foundations
6. Streaming/materialization, rendering/input and detailed generation after the foundations are stable

## Current live reference build

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/

The live build still runs the deprecated clean-reboot runtime until enough of the new modular foundation exists to replace it cleanly. The new WHERE code is intentionally not wired into the deprecated runtime through a temporary compatibility layer.

## Run current reference locally

Open `game/project.godot` in Godot 4.7.1 and run the project.
