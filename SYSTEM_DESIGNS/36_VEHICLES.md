# Tick Survival Lab — 36 Vehicles

Status: **APPROVED — design complete, implementation not started**

Approved: **2026-09-03**

## Goal

Add persistent, physically grounded transportation without introducing continuous real-time vehicle physics or a separate Driving skill.

System 36 owns cars, trucks, motorcycles, bicycles and skateboards as persistent world objects with real movement, condition, fuel where applicable, cargo, occupants and Mechanical interactions.

Core rule:

> **Real vehicle + real physical prerequisites + relevant owning state + Mechanical where competence matters + real WHEN time = persistent result.**

The canonical player skill catalog remains exactly **Awareness, Stealth, Mechanical and Survival**.

## Vehicle classes

### Skateboard

A skateboard is deliberately **not** a full vehicle-driving model. It is a mobility item that behaves like running with these differences:

- movement distance: **2 tactical cells per committed movement**;
- propulsion adds **no Fatigue cost**;
- no fuel;
- nearly silent;
- no meaningful cargo storage;
- actor-like cardinal movement/facing rather than vehicle 45-degree steering;
- terrain restrictions are stricter than ordinary walking/running: smooth pavement/sidewalk is the intended surface, while stairs, deep rubble, water and similarly unsuitable terrain block use.

There is no live Stamina system. “No stamina cost” means skateboard propulsion adds no canonical Fatigue.

### Bicycle

- movement distance: **3 tactical cells per committed movement**;
- no fuel;
- very quiet;
- **does add Fatigue**, but materially less Fatigue per distance than running;
- small cargo capacity where the specific bicycle/rack supports it;
- uses vehicle steering/heading rules below.

### Motorcycle

- movement distance: **3 tactical cells per normal committed movement**;
- powered/fueled;
- lower fuel use than cars/trucks;
- smaller cargo/storage than cars;
- easier to steal/hot-wire than a car or truck;
- lower mass and occupant protection;
- uses vehicle steering/heading rules below.

### Car

- movement distance: **3 tactical cells per normal committed movement**;
- powered/fueled;
- medium cargo/storage;
- standard Mechanical theft/hot-wire difficulty;
- medium mass/protection.

### Truck

- movement distance: **3 tactical cells per normal committed movement**;
- powered/fueled;
- higher fuel use;
- largest ordinary cargo/storage;
- heavier mass and larger footprint;
- standard or harder Mechanical theft/hot-wire difficulty depending on profile.

## Spatial representation

Vehicles reuse canonical WHERE global integer cells and whole-cell footprints.

Cars/trucks/motorcycles/bicycles use an eight-heading vehicle presentation/movement vocabulary at 45-degree increments while preserving integer-cell authoritative placement.

The underlying tactical world remains grid-based. Vehicle movement never introduces floating-point authoritative positions.

Skateboards are the exception: they intentionally reuse actor-like cardinal movement because they are mechanically “running without Fatigue” rather than a full driving model.

## Vehicle movement

### Straight movement

For bicycle/motorcycle/car/truck:

- one normal committed move advances **3 tactical cells** along the current vehicle heading/path;
- every traversed cell/footprint state is collision-validated;
- the action cannot teleport through an occupied or illegal intermediate cell;
- WHEN owns elapsed action time;
- movement consequences belong to the vehicle movement owner, never UI.

### Turning

A moving vehicle turn is not an instant 90-degree pivot.

- each committed turn movement advances **3 cells** along the turning/diagonal path;
- heading/sprite orientation changes by **45 degrees per turning movement**;
- repeated turn actions can therefore move N -> NE -> E -> SE -> S, etc.;
- collision legality is checked across the complete moved footprint/path;
- presentation interpolates/animates the 45-degree visual turn but does not own physics.

### Stopping / braking

A moving vehicle does not stop instantaneously.

- a committed stop/brake action requires **2 tactical cells of forward stopping distance**;
- the vehicle comes to rest only after traversing that bounded two-cell braking path;
- each braking cell is collision checked;
- an obstruction inside required stopping distance produces the appropriate collision consequence rather than silently snapping the vehicle to a stop before the obstacle.

This two-cell stop rule applies to moving bicycles, motorcycles, cars and trucks. Skateboard stopping remains actor-like and does not create a separate powered-vehicle brake simulation.

## Persistent vehicle state

Each vehicle uses typed persistent state keyed by the stable WHAT entity ID. The compact condition model includes:

- vehicle class/profile;
- body/frame condition;
- propulsion/drivetrain condition;
- wheel/rolling condition;
- electrical/battery condition where applicable;
- fuel quantity where applicable;
- engine/powered state where applicable;
- locked/unlocked state where applicable;
- ignition/key state and persistent hot-wire bypass state where applicable;
- installed modifications;
- cargo container identity/capacity where applicable;
- occupants/driver relationship;
- current vehicle heading/state needed for movement.

The system deliberately avoids unnecessary fine-grained automotive simulation such as individual tire pressures, spark plugs, suspension arms, oil chemistry or frame-by-frame engine state.

Damage remains consequential: destroyed/failed critical condition can prevent starting or movement.

## Entering, driving and exiting

When an actor enters a vehicle, occupancy is represented through the vehicle/containment relationship rather than leaving a second independent tactical ACTOR collision body underneath the moving vehicle.

The driver commits vehicle movement intents. The vehicle owner validates state, collision and terrain, then WHEN charges the action.

Exiting requires a legal adjacent location and a stopped vehicle.

## Keys, theft and hot-wiring

Powered motor vehicles normally require their real matching key/authorized ignition state.

Without the key, Mechanical may attempt a real hot-wire interaction when the necessary physical prerequisites exist.

Typical hot-wire prerequisites include a concrete access/tool path such as screwdriver/pliers and wire/electrical material where required by the specific vehicle profile.

Hot-wiring:

- costs real WHEN time;
- uses Mechanical difficulty;
- failure can waste time and may damage electrical condition or expend/damage a relevant material where appropriate;
- success creates a persistent ignition-bypass state rather than a one-time UI permission;
- skill never substitutes for a missing required tool/material.

Motorcycles are intentionally **easier to steal/hot-wire** than cars/trucks.

Bicycles/skateboards do not use powered ignition. A bicycle may later have a real physical lock state, but no fake ignition abstraction is added.

## Fuel

Cars, trucks and motorcycles have finite persistent fuel.

- motorcycles use less fuel than cars/trucks;
- trucks consume more than ordinary cars;
- fuel is consumed only when powered movement/actions actually occur;
- parked vehicles do not run per-frame/per-tick fuel simulation merely because they exist;
- refueling requires a real fuel source/container and physical transfer;
- later siphoning may use a real hose/container + target fuel + Mechanical + WHEN interaction.

Fuel may use compact integer units rather than fluid simulation, but it remains owned persistent state with physical acquisition/transfer prerequisites.

## Bicycle Fatigue

Bicycle propulsion is human-powered and therefore contributes to canonical Fatigue.

It should be materially more efficient per traveled cell than running, preserving the reason to use a bicycle while retaining a real exertion consequence.

Exact tuning belongs to implementation/playtest but there is no separate Stamina reserve.

## Cargo

Vehicle cargo reuses existing real inventory/containment/item-weight owners.

- truck: large cargo;
- car: medium cargo;
- motorcycle: small cargo;
- bicycle: small/optional cargo depending on rack/basket profile;
- skateboard: none by default.

Cargo is not a fake list attached only to UI. Items remain persistent WHAT entities contained by the vehicle cargo container and counted through the canonical physical item model.

## Repair

Vehicle repair is a target interaction, not merely a generic crafting recipe.

Mechanical repairs require concrete tools/materials appropriate to the damaged subsystem.

Examples:

- drivetrain/engine: wrench + suitable fasteners/metal/component;
- electrical: screwdriver/pliers + wire/electrical component;
- wheel/rolling system: wrench + real replacement wheel/tire/part;
- body/frame: hammer/wrench + real metal/fastening material;
- battery: appropriate tools + real replacement battery.

Mechanical affects duration, success and material/effectiveness outcome. It cannot repair an absent required part with skill alone.

## Modifications

Vehicle modifications use the same physical-prerequisite + Mechanical + WHEN architecture but install persistent components instead of restoring condition.

Initial bounded modification candidates:

- reinforced bumper/body protection;
- cargo rack/storage expansion;
- improved lights;
- repaired/quieter exhaust where applicable;
- bicycle/motorcycle rack or basket.

Installed modification components should remain real persistent items/components attached to or contained by the vehicle so removal can return a real object instead of toggling a presentation-only boolean.

## Lighting and sound

Powered headlights integrate with the existing physical-light system and depend on the relevant electrical/power condition.

Vehicle movement/operation emits real spatial sound through the existing sound owner.

Relative intent:

- skateboard: nearly silent;
- bicycle: very quiet;
- motorcycle: powered moderate/loud profile;
- car: powered moderate profile;
- truck: heavier/louder profile.

Later infected/NPC AI consumes this sound truth; System 36 does not fake AI reactions before those consumers exist.

## Collision consequences

A blocked movement path does not permit the vehicle to pass through persistent world objects.

At minimum, an impact:

- stops/interrupts the attempted movement according to the owning movement/action rules;
- can damage vehicle condition based on movement/mass/profile;
- can injure occupants through the existing Health owner where appropriate.

Running over living actors/infected belongs with the later combat/actor interaction owner and must not be faked merely to make vehicles appear complete.

## World generation / persistence

Vehicles are ordinary persistent generated world content, not DEV-only fixtures.

Appropriate generated locations may create parked cars, trucks, motorcycles, bicycles and occasional skateboards using contextual placement such as:

- driveways;
- parking lots;
- road shoulders;
- homes;
- businesses;
- other believable parking/storage contexts.

Generation creates virgin initial state once. After materialization, WHAT + typed vehicle state own the current vehicle permanently.

A generated vehicle may start with varying but deterministic/persistent combinations of:

- fuel;
- condition/damage;
- battery/electrical state;
- locked state;
- key availability/location;
- missing or degraded components.

Returning later must reveal the same vehicle state unless gameplay or simulation actually changed it.

## Performance contract

Forbidden:

- `_process`/`_physics_process` as vehicle simulation authority;
- one timer or recurring event per parked vehicle;
- whole-world scans for fuel, damage or parked-vehicle updates;
- floating-point continuous vehicle physics as authoritative movement;
- pre-simulating invisible travel merely because render frames pass.

Allowed work is action/event/materialization bounded and proportional to the active vehicle/path/footprint being resolved.

Parked vehicles should be effectively dormant persistent records.

## Construction boundary

System 36 must not create or depend on a freeform base-building system.

The user has superseded the old open-land base-construction direction. The later final interaction closure pass will make the project-wide rule canonical:

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken objects.**

Vehicle repair/modification remains Mechanical target interaction and does not imply structural base construction.

## Implementation boundary approved for the next operation

The approved first implementation should be a coherent real vehicle foundation rather than five disconnected demos. It should cover:

1. shared persistent vehicle state/profile owner;
2. generated persistent parked vehicle entities for the five approved classes;
3. enter/exit/driver containment;
4. skateboard 2-cell actor-like no-Fatigue movement;
5. bicycle/motorcycle/car/truck 3-cell vehicle movement;
6. 45-degree vehicle heading/turning presentation and bounded integer-grid path resolution;
7. two-cell braking/stopping distance for true vehicle classes;
8. bicycle Fatigue cost;
9. fuel for motorcycle/car/truck with class-scaled consumption;
10. cargo containment/capacity;
11. keys/locks/hot-wiring with motorcycles easier to steal;
12. typed condition and Mechanical repair;
13. bounded persistent modifications;
14. physical light/spatial sound integration where existing owners already provide the required public seam;
15. owning smoke/workflow and protected movement/collision/inventory/skills/health regressions;
16. live player controls sufficient to exercise the real system without making UI own truth.

## Explicit non-goals for the first implementation

- no separate Driving skill;
- no real-time rigid-body vehicle physics;
- no zombie/actor roadkill semantics before combat/actor impact ownership exists;
- no freeform base construction;
- no fake vehicle AI;
- no frame-driven parked-vehicle simulation;
- no detailed engine-part simulation for complexity's sake.

## Approval record

2026-09-03 user-approved design decisions:

- vehicles first, followed by one final skills/crafting/items/usable-object closure pass;
- skateboard behaves like running with no Fatigue cost and moves 2 cells;
- skateboard is not treated as a full powered-vehicle steering model;
- bicycles and all true vehicle classes use the 3-cell movement baseline;
- moving true vehicles use 45-degree heading changes during 3-cell turning moves;
- true vehicles require 2 cells of stopping/braking distance;
- bicycles do incur Fatigue;
- motorcycles are easier to steal, use less fuel and have less storage than cars;
- no new Driving skill;
- project-wide final closure must include cooking, first aid, vehicle repair/modification, object repair/reclamation and the restricted reinforcement/repair-only construction rule.
