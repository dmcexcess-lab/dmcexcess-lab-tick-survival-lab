# First Fire Reuse Audit

Tick Survival Lab is a clean project, but First Fire is an original project by the same owner and contains tactical/world work worth adapting. The goal is **reuse without architectural contamination**.

Audit source: current `dmcexcess-lab/first-fire` `main` inspected during the Tick Survival Lab 2026-08-13 design/roadmap pass.

## Reused now

### `FFTacticalEnvironments.gd` → `TacticalMapGenerator.gd`

Already extracted during bootstrap:

- seven authored physical location families;
- fourteen variants;
- ground and indoor regions;
- walls;
- doors;
- windows/glass;
- obstacles/props;
- barrels;
- light-source markers;
- player spawn and exits;
- structural validation concepts.

Tick deliberately removed First Fire zone/encounter/objective/camp assumptions.

### `FFTacticalLighting.gd` → `TacticalLighting.gd`

Ported in this pass as a clean dependency-free physical-lighting helper:

- theme/day-night ambient levels and tints;
- source presets;
- powered/unpowered source checks;
- radial falloff;
- window daylight contribution;
- directional/radial carried-light contribution from an externally supplied item profile;
- darkness/visibility helpers;
- visual flicker helpers.

Not imported:

- `FFData.gd` gear ownership;
- First Fire inventory slots;
- encounter UI/redraw ownership.

### `FFTacticalSound.gd` → `TacticalSound.gd`

Ported in this pass as a clean sound-interpretation helper:

- surface footstep labels;
- intensity-based zombie localization accuracy;
- awareness/intensity/distance-based player localization accuracy;
- bounded uncertain sound-source estimates;
- compact display labels;
- ambient sound profiles by theme/time/power.

Sound emission, propagation, occlusion, persistence and AI response are intentionally not faked yet; those need Tick-native world owners.

## Reuse as concepts, not copy-paste runtime

### `FFTacticalTime.gd`

Good reusable concepts:

- equipment/encumbrance affects movement and action time;
- fatigue affects movement/turn/interaction/attack time;
- injuries/condition affect movement time;
- skill can reduce costs within bounded limits;
- different infected can have different pace/attack schedules;
- fatigue/load can create breathing noise.

Do not transplant directly because Tick already owns timing in `PlayerActor.gd`/`TickScheduler.gd` and will move to a richer phased action model.

### `FFCombat.gd`

Good reusable concepts:

- facing-aware movement and stealth;
- physical doors/glass/barrels;
- light recalculation before AI perception;
- sound emission from footsteps, doors, glass, melee, firearms and explosions;
- zombies scheduled independently during a player action;
- zombies investigate heard locations and chase visible targets;
- environmental destruction affects state;
- escape/clearing the map need not be the objective.

Do not transplant directly. `FFCombat.gd` mixes UI, encounter objectives, First Fire's `Game` singleton, survivor records, companion logic, combat rules and presentation. Tick needs those behaviors separated into scheduler/world/actor/perception owners.

### First Fire survivor/social systems

Good long-term concepts:

- autonomous survivors rather than pure player puppets;
- personality/relationship-driven interactions;
- stress, morale and social consequences;
- survivors doing useful work while the player is elsewhere.

Do not transplant the camp/menu layer. Tick's version must happen through physical autonomous actors in the persistent world. Jobs/orders should be goals that AI characters execute on their own schedule.

## Candidate assets / presentation work

First Fire also contains tactical tile/visual work such as `FFTacticalTiles.gd` and its tactical atlas. These are same-owner original assets and may be reusable, but they are **not imported in this pass** because Tick's current developer preview is still deliberately minimal and the next architectural priority is action/perception simulation. Revisit when the rendering layer is ready to adopt a durable asset pipeline.

## Explicitly do not import

- camp UI and camp orchestration;
- expedition menu/rules;
- encounter wrapper/scenario completion flow;
- First Fire `Game.gd` state facade;
- First Fire save schema/migrations;
- release/ads/platform glue;
- survivor panel/inspector UI as runtime architecture;
- legacy field-event abstraction;
- companion code that assumes a separate tactical encounter.

## Reuse rule going forward

Before implementing a major tactical/world subsystem from scratch, inspect the current First Fire source for same-owner reusable work. Port only the smallest coherent rule set, remove First Fire-specific dependencies, give it a Tick-native owner, and add deterministic smoke coverage where practical.
