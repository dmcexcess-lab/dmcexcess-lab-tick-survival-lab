# Tick Survival Lab — Design Document

## 1. Game identity

Tick Survival Lab is an original top-down, grid-based zombie-apocalypse survival simulation built in Godot 4.

The game is presented as **real time with automatic pause**, but the simulation is driven by an authoritative discrete world tick. The player chooses an action while the world is paused for player input. Once committed, that action runs on the world clock. Other actors and world processes advance according to their own schedules during those same ticks. When the player action completes, or an interruption policy requires player control to return, the game automatically pauses again.

The world is the game. There is no separate camp, expedition, settlement, or tactical layer.

Project Zomboid is a system-coverage reference only. Tick Survival Lab must remain original in code, art, maps, names, UI, text, content, balancing, and implementation.

First Fire is an internal source project by the same owner. Reusable original physical-world/tactical rules may be adapted when they fit Tick Survival Lab's architecture. First Fire's camp/menu/expedition orchestration is not a runtime dependency.

## 2. Prime simulation rules

### 2.1 The world owns time

Every meaningful physical action has a tick cost. Walking, running, sprinting, turning, opening a door, climbing, attacking, reloading, searching, treating wounds, eating, crafting, building, driving, sleeping, and similar actions all advance the same authoritative clock.

The player is not the clock. Other actors can act several times during a slow player action or fail to keep pace with a fast one.

Rendering and animation may interpolate for presentation, but they never decide simulation outcomes.

### 2.2 Automatic pause, not classic turns

The normal gameplay loop is:

1. World is paused because the player character is ready.
2. Player chooses one committed action.
3. Simulation advances while that action executes.
4. Zombies, survivors, animals, vehicles, sound, fire, needs, injuries, and other scheduled systems advance on the same ticks.
5. When the player becomes ready again, the world automatically pauses.

The player cannot freely tactical-pause during an action. The normal pause menu may stop the application, but it is not a combat mechanic.

### 2.3 Actions are commitments with interruption policies

Actions must declare how interruption works rather than relying on one universal cancellation rule.

Core interruption policies:

- **Committed:** damage does not normally cancel the action once it has meaningfully begun. Example: an axe swing already in motion can still land unless the actor is incapacitated or physically unable to finish it.
- **Resumable:** damage interrupts and auto-pauses, but progress/state already completed remains. Example: reloading may resume from the magazine/round stage already reached; construction or suturing can preserve partial work where physically sensible.
- **Canceled:** interruption destroys current progress and the action must be started again.
- **Forced failure:** knockdown, unconsciousness, death, loss of the required limb/tool, or another hard invalidation can terminate any action that can no longer physically continue.

Long actions should be phaseable. A reload is not one magical state change at the final tick; removing a magazine, inserting a new one, chambering a round, or loading individual revolver rounds can create persistent intermediate state.

### 2.4 Consequences are physical

Whenever practical, gameplay results should exist in the world rather than as abstract event rolls.

A survivor assigned to scavenge should physically travel, search, carry loot, encounter danger, and return. A patrol should physically use roads. A reclaimed power plant should affect actual connected infrastructure. A broken wall should remain broken. A corpse should remain where it fell until something moves or destroys it.

Off-screen simulation may use deterministic/coarse representations for performance, but it must model the same underlying world rather than fabricate unrelated outcomes.

### 2.5 No drama director

Threats should arise from the state of the world. Zombies are not spawned because the game has been quiet. Noise attracts zombies that exist. Population moves through the world because of simulation causes. Human groups create risk through travel, power use, gunfire, construction, fires, and conflict.

## 3. Player and world are separate entities

A world seed/save is persistent independently of the current player character.

The world owns:

- seed and generation parameters;
- date/time and outbreak history;
- zombie population/state;
- all living/dead NPCs and animals;
- structures, damage, construction, fires, corpses, dropped items, containers, vehicles, crops, utilities, and infrastructure;
- settlements, patrols, relationships, territorial facts, and discovered consequences.

A player character is one actor record within that world.

If the player dies, permanent death does **not** destroy the world. The player may:

- create/select a new playable survivor in the same continuing world; or
- start a new world seed and new outbreak history.

A later survivor can discover the previous player's corpse, base, stash, vehicle, family, companions, constructions, mistakes, and effects on the island.

## 4. World concept

### 4.1 Large cut-off island region

The long-term world is a large island-like region containing a mix of:

- dense city;
- suburbs;
- commercial corridors;
- industrial districts;
- small towns;
- farms and rural roads;
- deep woods/wilderness;
- water/coastline;
- infrastructure corridors.

The region should look like a place that made sense before the apocalypse. Roads, rail, utilities, towns, farms, industry, hospitals, schools, power, water, and logistics should follow plausible geography.

The playable region can be isolated by destroyed/bombed bridges, collapsed crossings, failed ferries, quarantine barriers, or other outbreak-era destruction. Roads and transmission lines may visibly continue toward a mainland that is no longer reachable.

### 4.2 Hierarchical generation

The existing authored tactical-location schema is the physical building block, not a disposable prototype.

Long-term hierarchy:

**tile/object → room/building/location → block/local area → biome/district → island world**

Current 20×18 authored locations can later be transformed, stitched, nested, or used as templates inside larger generated areas without creating a second incompatible physical language.

### 4.3 New-game outbreak simulation

Eventually a new world should be generated from starting factors, not merely a static post-apocalypse seed.

Possible world-generation parameters include:

- outbreak epicenter(s);
- transmission rules;
- incubation/conversion timing;
- initial infected count and distribution;
- population density;
- public awareness;
- government/emergency response strength;
- evacuation timing;
- quarantine/military actions;
- bridge destruction/isolation timing;
- utility resilience;
- season/weather;
- loot/vehicle abundance;
- starting calendar date and time.

The ultimate version should be capable of simulating the spread and collapse itself. This is a long-term goal and should not block the local survival foundation.

## 5. Character creation and personal starting context

The player begins as a person who existed before the outbreak, not a blank RPG pawn.

New-game character factors can include:

- occupation;
- practical skills;
- traits;
- physical condition;
- home/work starting location;
- family/household members;
- friends or important relationships;
- pets;
- vehicle/property/resources consistent with the scenario.

Family members and known people are real autonomous actors in the world. They should not wait frozen for the player. Their situation, personality, knowledge, location, and relationships determine what they attempt as the outbreak unfolds.

## 6. Skills and learning

### 6.1 Use-based skill growth

Skills improve primarily through meaningful use. Repetition should matter, but trivial exploit loops should have diminishing value or require real task completion.

Occupations influence starting competence and knowledge rather than acting as rigid classes.

Examples:

- carpenter: construction and tool familiarity;
- mechanic: vehicle diagnosis/repair knowledge;
- paramedic: injury recognition and treatment capability;
- electrician: electrical systems and infrastructure work;
- farmer: crop/soil/animal knowledge;
- police/security: firearm handling, threat response, local emergency knowledge;
- veterinarian: animal medicine and overlapping medical skills.

### 6.2 Knowledge media

Books, manuals, recipe books, recorded instructional media, VHS-like tapes/discs, and other world-appropriate training sources can:

- unlock recipes or techniques;
- accelerate learning ranges;
- teach prerequisite theory;
- reveal diagnostic information;
- provide occupation knowledge otherwise learned slowly through practice or another survivor.

Training media should be physical loot and remain part of the persistent world.

## 7. Body, injury, and medicine

The health model should be detailed enough to create survival decisions without attempting unnecessary biomedical simulation.

Desired systems include:

- body-region injuries;
- scratches/lacerations;
- bites;
- deep wounds;
- embedded objects where useful;
- burns;
- fractures/broken bones;
- bleeding;
- pain;
- wound infection and zombie infection as separate concepts where appropriate;
- sickness;
- mobility/use impairment;
- unconsciousness/death;
- hunger, thirst, fatigue/endurance, stress/panic, and environmental exposure.

Deep wounds can be bandaged to control bleeding but may continue/restart bleeding until properly closed. Sutures remain a real treatment. Fractures can require splints and may justify crafted crutches or other mobility aids.

Some trauma is simply fatal or effectively unsurvivable, such as catastrophic head/neck/torso injury depending on severity.

### 7.1 Amputation

Zombie infection originating in an extremity may, under limited circumstances, be stoppable by timely amputation before systemic spread.

Amputation is a desperate intervention, not a guaranteed bite cure. Location, elapsed ticks, infection progression, treatment conditions, blood loss, shock, skill, tools, and uncertainty can matter.

Limb loss is permanent world/character state and must affect movement, equipment, weapon use, construction, driving, treatment, animation/paper-doll state, and future prosthetic/mobility systems.

## 8. Combat

Combat is dangerous and often inferior to avoidance.

The tick model creates risk through exposure time. A heavy weapon can be powerful while leaving the actor committed for more ticks, allowing nearby zombies more scheduled actions. A lighter weapon can resolve faster but produce less force/reach/damage.

Important combat factors include:

- action duration and phases;
- facing;
- reach;
- weapon mass/speed;
- stealth attacks;
- noise;
- multiple attackers;
- knockdown/grabs where appropriate;
- firearms, aiming, recoil, ammunition, and reload phases;
- armor/clothing;
- environmental attacks and hazards;
- persistent wounds and equipment damage.

## 9. Perception, light, and sound

Facing, vision, darkness, doors, windows, and sound are core survival systems.

First Fire already contains original reusable concepts for:

- environment light-source presets;
- powered/unpowered lights;
- radial and directional item lighting;
- daylight through windows;
- darkness affecting visibility distance;
- surface-specific footstep labels/noise concepts;
- uncertain sound-source localization;
- ambient environmental sound profiles.

Tick Survival Lab should adapt those systems rather than rebuild them from nothing, while moving all authority into Tick-native world/perception modules.

Sound must be spatial. It propagates through the physical environment and influences actors that already exist in the world.

## 10. Inventory, loot, crafting, and equipment

Items are persistent physical objects or container contents. Inventory should not become a disconnected menu economy.

Core needs:

- carried weight/encumbrance;
- clothing/equipment;
- containers and capacity;
- weapons/ammunition;
- food/water/medicine;
- tools/materials;
- condition/durability where useful;
- spoilage where useful;
- searching and moving items as tick actions;
- dropped items and persistent storage;
- crafting/repair recipes and workstation requirements.

Crafting depth should be systemic rather than a giant recipe count for its own sake.

## 11. Destruction, construction, and bases

The world should become broadly destructible and buildable.

Authored and player-created structures should converge on compatible runtime concepts. A wall should ultimately be a wall regardless of whether it existed at world generation or was built six months later.

Useful structural properties can include:

- material;
- durability;
- movement blocking;
- opacity/vision blocking;
- sound transmission;
- flammability;
- support/structural relationships where needed;
- ownership/history only when gameplay needs it.

Player actions should support dismantling, barricading, moving furniture, building walls/floors/roofs/fences/gates, demolition, repairs, storage, utilities, farming structures, animal enclosures, and eventually complete free-form bases.

## 12. Settlements and autonomous survivors

A settlement should emerge from ordinary world systems rather than require a separate settlement minigame.

**free building + resources + autonomous survivors + assignable work = settlement**

The player gives goals/jobs/constraints, not frame-by-frame puppet commands.

Example orders:

- guard this entrance;
- patrol this road;
- farm this area;
- cook for the group;
- repair these vehicles;
- scavenge this district for medicine;
- maintain the generator;
- move supplies between these bases.

Survivors execute orders according to their own skills, needs, personality, relationships, perception, equipment, danger tolerance, and priorities.

Multiple player or NPC-created bases can exist simultaneously. Communities can grow, merge, fracture, relocate, abandon sites, reclaim locations, and create patrol/supply routes.

## 13. Social simulation

The First Fire camp/social concept should be transformed into a physical-world simulation rather than imported as a menu layer.

Survivors can have:

- personalities;
- traits;
- needs;
- stress/morale;
- memories;
- friendships/hostility;
- family/romantic ties where appropriate;
- trust and group relationships;
- autonomous conversations/conflicts/cooperation;
- preferences about work, risk, people, and living conditions.

Social outcomes should affect physical behavior: who works together, who refuses dangerous tasks, who leaves, who protects whom, who takes initiative, and who creates conflict.

## 14. Animals

Dogs, cats, and livestock are autonomous physical actors rather than decoration-only UI bonuses.

Dogs can support scouting, warning, tracking, defense, hunting, fetching, bonding, and companionship.

Cats can affect pests, morale/base life, roaming, hunting small animals, and occasional item behavior without pretending to be combat units.

Livestock such as chickens/roosters can provide food production, breeding, noise, enclosure needs, predator/zombie risk, and base life.

## 15. Vehicles

Vehicles use the same authoritative tick model.

Driving actions may commit the vehicle through multiple tiles before the next player-ready pause. Momentum therefore creates risk: a car moving quickly cannot be treated as a one-tile turn token.

Vehicles eventually include:

- acceleration/braking/steering;
- momentum;
- collision;
- noise;
- fuel/battery;
- component damage and repair;
- cargo;
- entering/exiting/seat changes;
- NPC use;
- patrol/supply/logistics use.

## 16. Infrastructure and late-game civilization

The island contains meaningful infrastructure such as:

- power generation/substations/grid segments;
- water systems;
- radio/communications;
- fuel/logistics facilities;
- hospitals/emergency facilities;
- farms/warehouses/industry;
- bridges/roads/rail/ferries.

Communities can attempt to reclaim, repair, defend, and maintain infrastructure. The effect should be physical and regional. Restoring power can illuminate connected areas and create new sound/activity, which can in turn influence zombie movement and human conflict.

## 17. Persistence philosophy

The save file is fundamentally a world-state record.

Important persistent consequences include:

- dead characters and corpses;
- wounds and missing limbs;
- moved/taken/destroyed items;
- broken/open/locked doors and windows;
- destroyed/built structures;
- fires/burn damage;
- cleared or migrated zombie populations;
- vehicles and damage;
- crops/animals;
- survivor locations/relationships/jobs;
- settlements and infrastructure state;
- outbreak history and calendar.

Before Beta, schemas may change aggressively rather than carrying vestigial compatibility forever.

## 18. Architecture direction

Preferred dependency direction remains:

**map/data → persistent world state → authoritative scheduler/rules → actor simulation → presentation/input**

Long-term ownership should keep these concepts separate:

- generated initial world facts;
- mutable persistent world facts;
- world clock/scheduler/action phases;
- player character state;
- NPC/animal actor state;
- perception/light/sound;
- inventory/items;
- body/needs;
- construction/destruction;
- settlements/jobs/social behavior;
- world streaming/coarse simulation;
- persistence.

The UI must never become the authority for simulation state.

## 19. Scope discipline

The final ambition is large, but development remains vertical and incremental.

Do not prebuild every planned system. Each milestone should make the current playable simulation materially better and establish durable owners that later systems can plug into.

The immediate priority remains the local tick/action/perception/zombie survival loop. The island, autonomous settlements, outbreak simulation, vehicles, and infrastructure are long-term directions that architecture must permit without forcing premature implementation.
