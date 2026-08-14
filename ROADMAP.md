# Tick Survival Lab — Roadmap

This roadmap describes implementation order, not a promise to build every distant system before playtesting the current slice. Current `main` remains the source of truth for what actually exists.

## Milestone 0.1 — Authoritative Tick Movement — COMPLETE

Foundation already on `main`:

- authoritative world tick counter/scheduler;
- player movement/facing;
- walk/run timing;
- fatigue/encumbrance-ready timing modifiers;
- physical door state;
- keyboard and pointer/touch dev controls;
- developer tick/action HUD;
- deterministic CI smoke coverage.

## Milestone 0.2 — Action Execution Model

Goal: turn the current immediate-cost prototype into the real real-time-with-auto-pause action model.

- player-ready automatic pause state;
- actions with explicit start/end ticks;
- action phases;
- committed/resumable/canceled interruption policies;
- hard invalidation for knockdown/unconsciousness/death/lost requirement;
- damage interruption hooks;
- no normal mid-action player cancel;
- scheduler support for multiple actors advancing during one player action;
- deterministic tie/order rules;
- developer timeline/action-phase diagnostics.

Do not add combat breadth until this model is trustworthy.

## Milestone 0.3 — Physical Perception Foundation

Goal: reuse/adapt the strongest existing First Fire tactical-environment work instead of starting over.

Already ported as clean Tick-native helpers:

- `TacticalLighting.gd`;
- `TacticalSound.gd`.

Next:

- runtime light-source state from existing map light markers;
- powered/unpowered environment lights;
- indoor/outdoor ambient light;
- window daylight;
- directional carried lights;
- opaque physical facts for walls/doors/props;
- line of sight and four-direction facing cone;
- darkness-limited recognition;
- spatial sound event representation;
- sound propagation/attenuation/occlusion;
- uncertain sound-location information outside vision.

## Milestone 0.4 — Persistent Infected

Goal: prove the clock by placing zombies on the same scheduler.

- infected actor records and timing profiles;
- persistent initial placement, no drama-director edge spawning;
- idle/wander/investigate/chase behavior;
- sight and sound acquisition;
- memory/last-known-position rules;
- facing;
- actor occupancy/pathing;
- movement pace variation so some infected keep pace, lose ground, or gain ground;
- basic contact attacks/damage interruption;
- corpse state;
- local persistence when leaving/returning.

## Milestone 0.5 — Core Combat Commitments

Goal: make weapon timing tactically meaningful before expanding weapon count.

- melee reach and facing;
- light vs heavy action timing;
- committed swing phases;
- hit/miss/damage resolution;
- multiple attackers acting during long swings;
- shove/space-making equivalent if playtests require it;
- stealth attacks;
- weapon noise;
- firearm aiming/shooting baseline;
- phased reloads with persistent intermediate magazine/round state;
- damage interruptions and hard failures.

## Milestone 0.6 — Body and Survival

Goal: persistent physical consequences that feed directly back into tick costs and capability.

- body regions;
- scratches/lacerations/bites;
- deep wounds and persistent/restarting bleeding;
- bandages and sutures;
- fractures;
- splints;
- crafted crutches/mobility aids;
- pain and impairment;
- wound infection vs zombie infection;
- fatal trauma thresholds;
- hunger/thirst;
- fatigue/endurance;
- encumbrance;
- stress/panic;
- sleep;
- basic environmental exposure;
- extremity amputation as a desperate time-sensitive infection intervention;
- permanent missing-limb consequences.

## Milestone 0.7 — Inventory, Loot, Equipment, Learning

Goal: make scavenging physically meaningful.

- persistent items and containers;
- carried weight/capacity;
- clothing/equipment;
- tools/weapons/ammo;
- food/water/medicine;
- item condition where useful;
- spoilage where useful;
- tick-cost searching/transferring/equipping;
- use-based skill progression;
- occupations as starting knowledge/competence, not classes;
- recipe/skill books and manuals;
- VHS-like/recorded instructional media;
- recipe/technique prerequisites and learning acceleration.

## Milestone 0.8 — Mutable Local World

Goal: authored locations stop being static scenery.

- breakable windows/doors;
- wall/material durability;
- barricades;
- moving furniture;
- dismantling;
- fire/burn damage;
- dropped debris/corpses;
- persistent local destruction;
- player construction using compatible wall/floor/door/fence concepts;
- authored and built structures converge toward one runtime physical model.

## Milestone 0.9 — Local Homesteading

Goal: prove that a player can live in the world instead of only raid it.

- free building improvements;
- storage organization;
- cooking;
- rain/water systems;
- farming baseline;
- generators/electricity baseline;
- repairs;
- crafting stations;
- traps where useful;
- enough renewable production for long-term survival in one region.

## Alpha 1 — Persistent World Save / Player Separation

Goal: the island/world is the durable save; the player is one mortal actor inside it.

- explicit world seed/world ID;
- persistent calendar;
- world-state save schema/version;
- player-character records separate from world identity;
- permanent player death;
- create/select a new playable survivor in the same continuing world;
- previous player corpse/stash/base remain physically present;
- start-new-world option remains independent;
- local-area unload/reload without state reset.

## Alpha 2 — Island World Generation

Goal: connect local physical locations into a large coherent region.

- island/isolated-region world seed;
- city, suburb, commercial, industrial, rural, farm, forest/wilderness biomes;
- road network and plausible town/industry placement;
- coast/water barriers;
- destroyed/bombed bridges and other quarantine-era cutoffs;
- infrastructure corridors that visibly used to connect beyond the playable region;
- hierarchical generation: world → district → local area → building/location → tile/object;
- reuse/stitch/transform existing authored location schema rather than replace it;
- streaming and deterministic regeneration of unchanged initial facts.

## Alpha 3 — Autonomous Human Survivors

Goal: bring First Fire's survivor/social ambitions into the physical world instead of a menu layer.

- autonomous survivor actors;
- personalities/traits/skills/needs;
- perception and self-preservation;
- equipment choice/use;
- combat/scavenging behavior;
- memories and relationships;
- trust/conflict/cooperation;
- recruitment and departure;
- player orders as goals/jobs/constraints rather than puppet control;
- autonomous task execution on the same clock/world.

## Alpha 4 — Animals

Goal: living companions and base ecology.

- dogs: warning, tracking/scouting, defense, bonding, fetching/hunting where appropriate;
- cats: roaming, pest hunting, base life/morale, autonomous behavior;
- chickens/roosters and basic livestock loops;
- feeding, enclosure, injury/illness, reproduction where appropriate;
- zombie/predator/noise interactions;
- animals use the same physical actor/world model as far as practical.

## Alpha 5 — Emergent Settlements

Goal: no separate settlement minigame.

**free building + resources + autonomous survivors + assignable jobs = settlement**

- multiple player bases;
- NPC-created/occupied bases;
- work assignments;
- guard posts;
- patrol routes;
- scavenging parties;
- supply routes between bases;
- cooking/farming/building/repair/logistics jobs;
- storage/bed/food/water/power needs;
- community growth, fracture, relocation, abandonment, merging;
- local safety emerges from actual patrols/fortifications/population.

## Alpha 6 — Vehicles and Logistics

Goal: make the island's geography and multiple bases operationally meaningful.

- tick-driven acceleration/braking/steering;
- committed multi-tile movement and momentum;
- collisions and zombie impacts;
- vehicle noise;
- fuel/battery;
- component damage/repair;
- cargo;
- entering/exiting/seat changes;
- NPC driving;
- patrol/supply/scavenging use;
- towing later if it earns its complexity.

## Alpha 7 — Infrastructure Reclamation

Goal: late-game communities can physically reclaim pieces of civilization.

- power plant/generation;
- substations/grid segments;
- regional powered light state;
- water facilities/network simplification;
- radio/communications;
- fuel/logistics sites;
- repair projects requiring skills/materials/time;
- guards/patrols required to keep sites usable;
- restored infrastructure creates real light, noise, traffic, value, and danger.

## Beta 1 — Outbreak Scenario Generator

Goal: a new world can be parameterized by how the apocalypse began.

- outbreak epicenter(s);
- infection/transmission/incubation settings;
- initial infected/population distribution;
- public awareness;
- emergency/government response factors;
- evacuation/quarantine timing;
- bridge destruction/isolation events;
- utility resilience;
- season/weather/start date;
- loot/vehicle abundance;
- deterministic world-history generation when starting after collapse.

## Beta 2 — Personal Pre-Outbreak Context

Goal: the starting character already belongs to the generated world.

- starting occupation;
- home/work/school-relevant locations;
- family/household relationships;
- friends/known survivors;
- pets;
- plausible starting property/vehicle/resources;
- family members are autonomous real actors, not frozen quest tokens;
- communications/knowledge determine what people attempt during collapse.

## Beta 3 — Live Collapse / Outbreak Start

Long-term crown-jewel simulation. Do not force this early.

- functioning pre-collapse civilian world at start;
- infection spreads from generated conditions;
- civilians/emergency services respond;
- hospitals/roads/refuges become stressed by actual population movement;
- quarantines/checkpoints/bridge destruction emerge from configured response;
- utilities fail or survive according to world causes;
- infected are created through the simulated outbreak rather than post-hoc placement;
- aggressive coarse simulation/LOD required for island-scale population counts.

## Beta 4 — Long-Term World Depth

- seasons/weather depth;
- farming/ecology expansion;
- long-term building/infrastructure degradation;
- zombie redistribution/migration caused by world stimuli;
- larger community politics without turning into a menu strategy game;
- trade and inter-base logistics;
- advanced construction/crafting only where it creates new decisions;
- richer animals/vehicles/infrastructure as playtests justify them.

## Permanent design constraints

Across every milestone:

- world state is authoritative, not UI;
- player and world saves remain conceptually separate;
- every meaningful physical action uses ticks;
- normal player input happens at player-ready auto-pause points;
- action interruption is explicit and data/rule driven;
- no AI drama director spawning threats to manufacture tension;
- persistent consequences beat summary event rolls;
- reuse Tick/First Fire original systems when they fit; do not rebuild solved work merely for purity;
- do not import First Fire camp/expedition/menu architecture into the runtime;
- build vertically and playtest before racing down the roadmap.
