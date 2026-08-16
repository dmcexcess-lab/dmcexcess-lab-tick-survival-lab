# Tick Survival Lab — Roadmap

This is implementation order, not a promise to build distant systems before playtesting current work. Current `main` remains the truth for what exists.

## Milestone 0.1 — Authoritative Tick Movement — COMPLETE

Authoritative world tick, player movement/facing, walk/run timing, timing modifiers, physical doors, keyboard/touch controls, developer HUD, and deterministic smoke coverage.

## Milestone 0.2 — Action Execution Model — COMPLETE

Player-ready auto-pause, explicit action windows, phased actions, committed/resumable/canceled/forced-failure interruption, deterministic actor ordering, scheduler proof actors, and CI coverage.

## Milestone 0.25 — Extraction Raid Shell — COMPLETE / PLAYTEST NEXT

The original seamless-mini-world experiment has been replaced by an extraction structure.

Implemented:

- full-screen 5×5 destination map;
- destination types: commercial/strip-mall, downtown/office, residential, woods, rural;
- safe base/staging map state;
- tap/click destination to deploy;
- fresh deterministic raid seed for every visit to a destination;
- one active 64×64 tactical raid at a time;
- generated green edge exits act as extraction points;
- final extraction step costs normal movement ticks;
- extraction returns to base/staging instead of entering an adjacent region;
- map is view-only during an active raid;
- repeat deployment to the same destination creates a different local map while remaining reproducible for a fixed world/visit sequence;
- v5 streetscape/building-family generation remains intact.

Immediate priority: **playtest this loop before adding more scope.**

## Milestone 0.3 — Physical Perception Foundation — IN PROGRESS

### 0.3A Visual perception — COMPLETE

Lighting, LOS, four-direction facing cone, windows/daylight, powered lights, directional flashlight, darkness-limited recognition, opaque props, sealed-corner LOS, visible cells and remembered fog.

### 0.3B Weather foundation — FUNCTIONALLY PRESENT

Current fixed clear/rain/storm/fog/wind/snow profiles already modify presentation/perception and support silent sound-masking hooks. Weather-pattern evolution remains deferred.

### 0.3C Spatial sound visualization — NEXT SYSTEM AFTER EXTRACTION PLAYTEST

There is **no audible sound playback**.

- tick-owned sound event records;
- propagation/attenuation through physical cells;
- wall/door/window effects;
- rain/storm masking;
- uncertain localization outside vision;
- yellow spatial sound markers;
- infected hearing later consumes the same event model.

## Milestone 0.4 — Persistent Infected

Infected actor timing, local persistent placement, idle/wander/investigate/chase, sight/sound acquisition, memory, facing, occupancy/pathing, pace variation, basic contact attacks and corpses. No drama-director edge spawning.

This milestone should make each extraction raid dangerous without changing the deploy/extract structure.

## Milestone 0.5 — Search / Loot / Inventory / Extraction Stakes

Bring the extraction loop its first meaningful reward/risk economy:

- searchable containers and fixtures;
- persistent item records;
- carrying capacity;
- clothing/equipment/tools/weapons/ammo/food/water/medicine;
- destination-biased loot probabilities;
- extraction retains acquired items;
- failure/death rules define what does not return;
- no loose-world sprite requirement for ordinary inventory items.

## Milestone 0.6 — Core Combat Commitments

Melee reach/facing, light/heavy timing, committed swing phases, hit/damage resolution, stealth, weapon noise, firearm baseline, phased reload state, and interruption integration.

## Milestone 0.7 — Body and Survival

Body regions, scratches/lacerations/bites, deep wounds, bleeding, bandages/sutures, fractures, splints/crutches, pain/impairment, wound vs zombie infection, fatal trauma, hunger/thirst, fatigue/endurance, encumbrance, stress/panic, sleep, exposure, and severe-limb consequences where worthwhile.

## Milestone 0.8 — Raid Objectives / Destination Identity

Layer objectives onto the same extraction loop:

- recover a specific item;
- rescue/retrieve a survivor;
- investigate a site;
- repair/activate infrastructure;
- deliver/place something;
- recover a failed-raid cache/corpse where persistence supports it;
- destination-specific population/loot/structure weighting.

Objectives should pull the player deeper into danger rather than replace extraction.

## Milestone 0.9 — Physical Base / Progression Hub

Only after loot, injury and survivor progression justify it:

- persistent storage;
- loadout preparation;
- healing/recovery;
- crafting/repair stations where useful;
- water/food/power support;
- survivor roster functions if/when human survivors exist;
- optional physical hideout map replacing the temporary map-only staging representation.

Do not turn this into First Fire's menu/camp architecture.

## Alpha 1 — Persistent Save / Player Separation

World seed/ID, calendar, versioned state, survivor records separate from world identity, permanent death, new survivor in the continuing world, base/stash persistence, active-raid save policy, and deterministic destination history.

## Alpha 2 — Rich Raid Generation

Broader destination catalogs, larger grammar libraries, coherent roads/buildings/woods/rural spaces, destination modifiers, special landmarks, extraction variants, and optional larger destination maps if performance supports them.

## Alpha 3 — Autonomous Human Survivors

Autonomous actors with traits/skills/needs, self-preservation, equipment use, combat/scavenging, relationships, recruitment/departure, and goal/job-oriented orders.

## Alpha 4 — Animals

Dogs, cats, chickens/roosters and later livestock where they create survival gameplay: feeding, bonding, warning/utility, roaming/enclosure, injury/illness, reproduction where appropriate, and zombie/noise interaction.

## Alpha 5 — Emergent Settlements

Free building + resources + autonomous survivors + assignable jobs = settlement. Multiple bases, guard posts, patrols, scavenging parties, supply routes, farming/cooking/building/repair/logistics, and settlement change emerging from actual simulation.

## Alpha 6 — Vehicles and Raid Travel

Vehicles finally make abstract deployment travel physical/economic: fuel/battery, cargo, seat actions, noise, repair, travel cost, destination access, extraction variants and later NPC logistics.

## Alpha 7 — Infrastructure Reclamation

Power/water/communications/fuel/logistics sites and repair projects that create light/noise/value/danger and can become raid objectives.

## Beta — Outbreak / World Depth

Later work may add outbreak-history generation, personal pre-outbreak context, live-collapse scenarios, seasons, degradation, richer communities, trade/logistics and advanced construction. Those systems must serve the extraction-survival game rather than force a return to a giant continuously simulated map.

## Permanent constraints

- world/session state is authoritative, not UI;
- the player and persistent world remain conceptually separate;
- every meaningful tactical physical action uses ticks;
- normal input occurs at player-ready points;
- interruption is explicit and rule-driven;
- no AI drama director spawning threats for tension;
- no audible game sound; simulated sound is communicated visually;
- presentation animation may continue while paused only when it cannot advance simulation state;
- destination selection may remain abstract until transit systems actually exist;
- the destination map chooses risk, the tactical raid contains risk, extraction brings progress home;
- reuse compatible original Tick/First Fire work without importing First Fire camp/expedition/menu architecture;
- build vertically and playtest before racing down the roadmap.
