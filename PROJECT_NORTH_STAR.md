# Tick Survival Lab — Project North Star

Status: **canonical game-identity / anti-drift document**.

Read this before detailed system designs. This file exists to preserve the game we are actually trying to make while individual subsystems become more detailed.

## One-line identity

> **Ultima-style turn-based mini Zomboid.**

Tick Survival Lab is a top-down, tile-based, persistent open-world zombie survival simulation with discrete-time actions, systemic consequences, player-built bases, a causally simulated outbreak, and deliberately simplified-but-interconnected survival mechanics.

## Core philosophy

> **Mini means reduced complexity, not reduced consequence or mood.**

The project should capture the decisions, danger, atmosphere and systemic consequences created by deeper simulations without reproducing every internal variable those games simulate.

Examples:

- Health does not need literal blood-volume simulation to make a serious wound frightening. Injury severity, body region, treatment requirements and action/mobility consequences can preserve the meaningful decision.
- Hunger does not need metabolic simulation to make dwindling food matter.
- Weather does not need fluid dynamics to alter visibility, temperature, sound masking and mood.

Simplify internal calculation where possible. Do **not** simplify away consequence, causality, uncertainty, risk or atmosphere.

## Player experience target

The world should feel like a readable Ultima-like top-down world with the systemic survival pressure of a much deeper zombie simulation.

The player should be able to:

- live and travel in one persistent open world;
- enter houses, stores, farms and other believable places;
- scavenge real physical locations;
- carry equipment and supplies physically through that same world;
- build, secure, expand, abandon and revisit bases anywhere the world/construction rules permit;
- interact with doors, containers, vehicles, utilities, weather, light, sound and other persistent actors;
- experience consequences that remain in the world;
- pursue emergent goals rather than being forced through a raid/extraction loop.

**There is no extraction-shooter layer in the current design.** The player may leave home, wander indefinitely, relocate, establish multiple safe places, or never formally designate a base at all. Returning somewhere safe can still be strategically valuable, but it is not a separate extraction mechanic or game-state boundary.

## Persistent open world

The current direction is a **logically continuous persistent open world**, not a collection of independently generated tactical maps or raid instances.

The world may be streamed, partitioned or simulated at different resolutions internally for performance, but those partitions are implementation/storage details rather than separate realities.

Important consequences:

- roads, utilities, rivers, parcels and other large structures are planned in global world coordinates so local partitions cannot invent incompatible geometry;
- a streaming/materialization region asks the global world plan what exists there rather than independently deciding world-spanning geometry;
- once a place exists, persistent world state owns subsequent changes;
- looted containers, broken doors/windows, parked vehicles, corpses, construction and other meaningful changes should remain when the player returns;
- replacing the generator later must not rewrite existing saved world state.

## World generation philosophy

Generation is an **input to the world**, not the owner of the world.

Long-term top-down planning should establish large-scale facts before detailed local dressing:

world seed -> geography -> towns/districts/rural regions -> road network -> utilities/infrastructure -> parcels/addresses -> building footprints/types -> households/businesses/population -> detailed local materialization.

Detailed rooms, furniture, clutter and vegetation may be created when needed, but they must respect higher-level facts already decided globally.

A generated world's roads and infrastructure must be coherent globally before streaming boundaries are considered.

## Outbreak simulation

A major long-term goal is a causally simulated outbreak rather than a static post-apocalypse population roll.

The world can be populated before collapse with persistent people/households, jobs, workplaces, homes, schedules, vehicles and relationships. Outbreak parameters then affect transmission, awareness, emergency response, evacuation, infrastructure failure and population movement.

Accuracy here means **causal persistent simulation**, not necessarily second-by-second full-resolution simulation of every person everywhere.

Simulation resolution may scale with relevance/distance:

- nearby actors: detailed tactical actions;
- distant actors/populations: coarse deterministic actions/events using the same underlying state and causal rules.

If an important person dies across town, there should be a simulated reason. The engine does not need to calculate thousands of invisible individual footsteps to preserve that causality.

## Player stories

The playable survivor should be a person who already belonged to the generated world.

Character setup should eventually support customizable:

- identity/appearance;
- occupation and actual workplace;
- home/property;
- spouse/partner, children, parents, roommates or other household members;
- important relationships/friends/coworkers;
- pets;
- vehicle/property/resources appropriate to the story;
- skills/traits derived partly from background rather than RPG class abstractions;
- outbreak start time/scenario where appropriate.

Family and known people are real persistent actors. Their outbreak situation should emerge from the simulation rather than exist only as scripted quest markers.

## Base philosophy

A base is **not a separate map, menu layer or preselected special property**.

The player may build and secure a base anywhere in the persistent world where ordinary construction/occupancy rules allow it. A starting house may be useful, but it is not mechanically privileged. The player can fortify an existing building, construct in open land, occupy a warehouse, maintain several safe sites, abandon one, or move entirely.

Long-term base-related mechanics may include physical storage, beds, work areas, refrigeration, generators/power, water, vehicles, construction, survivors, pets, crops and defenses. Higher-level summary/community UI may exist later, but it should summarize underlying physical world facts rather than create a separate base reality.

## Space / tactical presentation

Canonical spatial baseline:

- authoritative **invisible tactical grid**;
- global authoritative positions are integer `Vector2i` cells;
- one tactical cell has a centralized planning scale of approximately **1 meter**;
- actors move cell-to-cell;
- no visible grid lines are required;
- props/fixtures can occupy one or multiple whole cells through arbitrary relative-cell footprints;
- directional props carry N/E/S/W orientation;
- renderer may rotate art in 90-degree steps or use authored directional variants where rotation looks wrong;
- world/generation data stores semantic object + orientation, never renderer-specific atlas assumptions;
- four-way actor facing is the simple baseline and supports vision cone, vulnerability, attacks and readable graphics;
- walls/doors/windows use **structure cells with explicit horizontal/vertical axis**, not cell-edge walls.

Do not introduce sub-cell positioning/free movement unless a concrete gameplay need justifies the added complexity.

The canonical detailed spatial contract is `SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md`.

## Turn-based time / interruption safety

The game is fundamentally **turn-based through an authoritative variable-duration tick/action system**, even if held movement or animation can make traversal appear fluid.

Core intent:

- while the player is choosing, the simulation is paused;
- the player commits one action;
- that action consumes a defined number of world ticks;
- other actors/systems whose scheduled time arrives may act during those ticks;
- when the player is ready for another decision, the game automatically pauses again;
- slow actions create real tactical exposure;
- injuries, fatigue, equipment and skill can change action duration/capability instead of requiring separate special-case combat rules.

Held movement may repeatedly request discrete movement actions. Releasing input means no new action is queued and the game returns to auto-pause.

### Real-life hard pause

The user must be able to put the game down immediately when interrupted at work.

This is a product requirement, not a tactical mechanic.

A hard application pause should freeze simulation without penalizing the player, including during an in-progress action. Mobile/browser focus loss, tab backgrounding, app interruption and an explicit large pause/menu path should be designed with this requirement in mind.

**Real life interrupting the player must never be equivalent to the survivor making a bad tactical decision.**

## Mini-Zomboid simulation rule

For each survival system ask:

> What meaningful player decision does the deeper simulation create?

Then implement the smallest causal model that preserves that decision and its consequences.

Examples of likely simplified state models:

- injury: type + body region + severity + stabilization/treatment/healing;
- hunger: coarse meaningful states rather than digestion chemistry;
- thirst/fatigue/temperature: coarse states with real action/health consequences.

Some systems deserve more depth because they create the game's identity:

- tick/action timing;
- persistent world state;
- perception/vision;
- lighting;
- spatial sound;
- world generation/coherence;
- outbreak/population simulation.

## Mood

Mood is a first-class outcome.

The game should feel lonely, dangerous, uncertain and physically grounded without requiring visual or mechanical complexity for its own sake.

Lighting, weather, darkness, line of sight, silence/spatial sound information, abandoned homes, evidence of the outbreak, persistent consequences and the player's personal connections to the world should create atmosphere through systems rather than scripted drama whenever practical.

## Foundational architecture

The simulation foundation separates three peer truths rather than treating the map generator as the engine:

- **WHERE — spatial model:** global grid coordinates, cells, footprints, facing, structure/opening geometry and pure spatial queries;
- **WHAT — persistent world/entity state:** what terrain, objects, actors, items, structures and mutations exist;
- **WHEN — tick/action kernel:** when actors/systems act, action durations, scheduling, auto-pause and hard pause.

Generation later creates initial persistent world state using WHERE. Construction, destruction and gameplay later mutate that same world state. Rendering reads it. None of those systems owns the others.

**WHERE is implemented. WHAT and WHEN still require their own bounded approved designs/implementation slices.** The umbrella relationship remains `SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md`.

## Modularity / development rule

The project is built one approved system at a time.

- Main/root is composition/wiring only.
- Every independently replaceable system has a focused owner and public contract.
- Systems should not need to inspect thousands of unrelated lines to make a local change.
- A generator rewrite must not change rendering/player/input/world rules.
- A renderer rewrite must not change simulation truth.
- Input should request actions, not implement simulation rules.
- Art is not physics.
- No placeholders or fake systems are presented as finished work.
- If a prompt spans too many systems, split it and push back before implementation.
- If a request is materially ambiguous, inspect what can be inspected and ask the smallest useful clarifying question.

## Design discipline

The North Star is deliberately short enough to reread often.

Detailed mechanics belong in `SYSTEM_DESIGNS/`. Cross-cutting approved choices belong in `DESIGN_DECISIONS.md`. Current work/status belongs in `README_CONTEXT.md`. Coding/GitHub process lessons belong in `README_SOPS.md`.

When later design work conflicts with this document, do not silently overwrite the conflict. Surface it, decide whether the North Star itself has changed, record the decision, then update the relevant documents.
