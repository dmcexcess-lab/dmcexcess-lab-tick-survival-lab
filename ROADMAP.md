# Tick Survival Lab — Roadmap

This is implementation order, not a promise to build distant systems before playtesting current work. Current `main` remains the truth for what exists.

## Milestone 0.1 — Authoritative Tick Movement — COMPLETE

Authoritative world tick, player movement/facing, walk/run timing, fatigue/encumbrance-ready modifiers, physical doors, keyboard + pointer/touch controls, developer HUD, and deterministic smoke coverage.

## Milestone 0.2 — Action Execution Model — COMPLETE

Implemented:

- explicit player-ready auto-pause state;
- actions with start/end tick, elapsed/remaining progress, payload and status;
- phased actions;
- committed/resumable/canceled interruption policies;
- forced-failure hook for hard invalidation;
- damage interruption hook;
- no normal mid-action player cancellation;
- multiple scheduled actors advancing during one player action;
- deterministic ordering by next tick then actor ID;
- exact resumable phase/progress snapshots;
- developer diagnostics and light/heavy/reload timing proofs;
- deterministic CI proving concurrent actions, committed-through-damage behavior, and interrupted/resumed reloads.

## Milestone 0.3 — Physical Perception Foundation — IN PROGRESS

### 0.3A Visual perception — COMPLETE

- First Fire tactical atlas presentation restored as Tick-native reusable assets/rendering;
- ground/walls/doors/windows/props/barrels plus directional survivor sprite;
- runtime light sources from authored map markers;
- powered/unpowered environment lights;
- indoor/outdoor ambient lighting;
- window daylight;
- directional carried-light/flashlight profile;
- walls, closed doors and opaque props block LOS/light;
- windows transmit sight/daylight;
- four-direction facing cone;
- darkness-limited recognition;
- visible-cell state plus remembered-cell fog of war;
- deterministic perception smoke coverage.

### 0.3B Spatial sound — NEXT

- real sound event records tied to world tick;
- propagation and attenuation through physical cells;
- door/window/wall occlusion costs;
- uncertain source locations outside vision;
- no UI-owned sound truth;
- later infected hearing consumes the same event model.

Already present as clean helpers: `TacticalLighting.gd` and `TacticalSound.gd`.

## Milestone 0.4 — Persistent Infected

Infected actor records/timing profiles, persistent placement, idle/wander/investigate/chase, sight/sound acquisition, memory, facing, occupancy/pathing, pace variation, basic contact attacks and interruption, corpses, and local persistence. No drama-director edge spawning.

## Milestone 0.5 — Core Combat Commitments

Melee reach/facing, light vs heavy timing, committed swing phases, hit/damage resolution, multiple attackers during long swings, stealth, weapon noise, firearm baseline, phased reload state, and interruption/hard-failure integration.

## Milestone 0.6 — Body and Survival

Body regions; scratches/lacerations/bites; deep wounds; bleeding; bandages/sutures; fractures; splints/crutches; pain/impairment; wound vs zombie infection; fatal trauma; hunger/thirst; fatigue/endurance; encumbrance; stress/panic; sleep; basic exposure; time-sensitive extremity amputation and permanent missing-limb consequences.

## Milestone 0.7 — Inventory, Loot, Equipment, Learning

Persistent items/containers, carrying capacity, clothing/equipment, tools/weapons/ammo, food/water/medicine, useful condition/spoilage, tick-cost manipulation/search, use-based skills, occupations as starting knowledge, books/manuals, recorded/VHS-like training media, and recipe/technique learning.

## Milestone 0.8 — Mutable Local World

Breakable doors/windows, material durability, barricades, furniture movement, dismantling, fire, debris/corpses, persistent destruction, free construction, and convergence of authored vs player-built physical structures.

## Milestone 0.9 — Local Homesteading

Storage, cooking, water collection, farming, generators/electricity, repairs, crafting stations, traps where useful, and enough renewable production to survive long-term in one region.

## Alpha 1 — Persistent World Save / Player Separation

World seed/ID, calendar, versioned world state, player records separate from world identity, permanent character death, new playable survivor in the same world, old corpse/stash/base persistence, independent new-world option, and area unload/reload without reset.

## Alpha 2 — Island World Generation

Large isolated region with city/suburb/commercial/industrial/rural/farm/forest biomes; plausible roads/towns/industry; coast barriers; bombed bridges/quarantine cutoffs; infrastructure corridors; hierarchical generation using the existing physical map language; streaming and deterministic regeneration.

## Alpha 3 — Autonomous Human Survivors

Autonomous actors with traits/skills/needs, self-preservation, equipment use, combat/scavenging, memories/relationships, trust/conflict, recruitment/departure, and player orders expressed as goals/jobs/constraints rather than puppet control.

## Alpha 4 — Animals

Dogs, cats, chickens/roosters and later livestock using the same world as practical: feeding, bonding, roaming, warning/utility behaviors, enclosure, injury/illness, reproduction where appropriate, and zombie/noise interaction.

## Alpha 5 — Emergent Settlements

**free building + resources + autonomous survivors + assignable jobs = settlement**

Multiple bases, NPC bases, work assignments, guard posts, patrol routes, scavenging parties, supply routes, farming/cooking/building/repair/logistics jobs, settlement needs, growth/fracture/relocation/abandonment, and safety emerging from actual people/fortifications.

## Alpha 6 — Vehicles and Logistics

Tick-driven driving, committed multi-tile movement, momentum, collisions, noise, fuel/battery, component repair, cargo, seat actions, NPC driving, patrol/supply/scavenging use, and later towing if worthwhile.

## Alpha 7 — Infrastructure Reclamation

Power generation/substations/grid segments, water simplification, communications, fuel/logistics sites, repair projects requiring skills/materials/time, guards/patrols, and infrastructure that creates actual light/noise/traffic/value/danger.

## Beta 1 — Outbreak Scenario Generator

Epicenter(s), transmission/incubation, initial population/infected distribution, awareness/response, evacuation/quarantine, bridge destruction, utility resilience, season/weather/start date, loot/vehicle abundance, and deterministic generated history for post-collapse starts.

## Beta 2 — Personal Pre-Outbreak Context

Starting occupation, home/work/school locations, family/household, friends, pets, plausible property/vehicles/resources, and autonomous family members who act according to information and circumstance rather than waiting as quest tokens.

## Beta 3 — Live Collapse / Outbreak Start

Long-term crown jewel: functioning civilian world, simulated spread, emergency response, hospitals/roads/refuges stressed by population movement, quarantines/checkpoints/isolation, causal utility failure/survival, and infected produced by the simulated outbreak. Requires aggressive coarse simulation/LOD.

## Beta 4 — Long-Term World Depth

Seasons/weather depth, farming/ecology, degradation, zombie redistribution/migration from stimuli, richer community politics without a menu strategy layer, trade/logistics, and advanced crafting/construction only where it creates decisions.

## Permanent constraints

- world state is authoritative, not UI;
- player and world remain conceptually separate;
- every meaningful physical action uses ticks;
- normal input occurs at player-ready auto-pause points;
- interruption is explicit and rule driven;
- no AI drama director spawning threats for tension;
- persistent physical consequences beat summary event rolls;
- reuse compatible original Tick/First Fire work rather than rebuilding solved systems;
- never import First Fire camp/expedition/menu architecture;
- build vertically and playtest before racing down the roadmap.
