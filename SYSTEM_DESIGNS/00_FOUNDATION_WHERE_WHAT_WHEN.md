# Tick Survival Lab — Simulation Foundation: WHERE / WHAT / WHEN

Status: **DRAFT — design discussion only; not permission to implement**

This document defines the proposed lowest-level simulation foundation for Tick Survival Lab.

It is intentionally below map generation, rendering, player controls, zombies, health, inventory, construction, vision, lighting, weather, sound, vehicles, population simulation and the outbreak itself.

The game shorthand remains:

> **turn-based persistent zombie survival.**

And the simplification rule remains:

> **Mini means reduced complexity, not reduced consequence or mood.**

The purpose of this foundation is to make later systems deep where they matter without making them tightly coupled. A generator rewrite must not rewrite movement. A renderer rewrite must not rewrite world state. A health rewrite must not rewrite the scheduler. Streaming must not redefine the world. Construction must use the same physical rules as generated buildings. The outbreak must use the same persistent people and time model as normal play.

The proposed foundation has three durable truths:

- **WHERE — Spatial Model:** where things can exist and how positions, directions, footprints and structures are described.
- **WHAT — Persistent World / Entity State:** what actually exists at those places, including all persistent changes.
- **WHEN — Tick / Action / Pause Kernel:** when actions and world events occur and how simulation time advances.

These are not three giant god objects. They are three narrowly owned domains with stable public contracts.

Generation, construction, destruction, movement, combat, first aid, AI and other gameplay systems sit above them and use those contracts.

---

## 1. Why these three systems are the foundation

A persistent survival world needs to answer three questions before it can answer almost anything else.

### WHERE?

Where is the survivor?

Where is the door relative to the survivor?

Which cells does a bed occupy after it is rotated?

What is north?

Which adjacent cell is behind the player?

Can a vehicle footprint fit in these cells?

Which global coordinates does this road cross?

Those are spatial questions. They should not depend on art, inventory, AI or procedural generation.

### WHAT?

What exists at world cell `(1204, 881)`?

Is the door there open or closed?

Was the window broken?

Is the refrigerator still present?

What items are inside it?

Which survivor owns this actor ID?

Was a wall built by the player here after world generation?

Those are persistent-state questions. They should not depend on whether the relevant area is currently rendered or loaded into the Godot scene tree.

### WHEN?

When may the player act again?

How many ticks does climbing through a window consume?

Does a zombie receive an action before an axe swing finishes?

At what point during a long action is a partial effect committed?

When is the next weather update, healing check, fire spread event or distant-population event due?

Those are simulation-time questions. They should not depend on frame rate or real elapsed wall-clock time.

### The rule

No later system should be allowed to invent a second answer to WHERE, WHAT or WHEN.

There should not be:

- one coordinate model for procedural generation and another for construction;
- one door state in rendering and another in collision;
- one clock for player actions and a separate incompatible clock for zombies;
- one persistent representation for bases and another for normal buildings;
- one road layout when generated and another when streamed;
- one actor identity while loaded and another after the actor is unloaded.

That duplication is where drift and hard-to-fix bugs begin.

---

# PART I — WHERE: SPATIAL MODEL

## 2. Goal

The Spatial Model defines the game's shared physical coordinate language.

It owns:

- global tactical-grid coordinates;
- four-way directions/facing;
- cell adjacency;
- object footprints;
- footprint rotation/transformation;
- structure/opening geometry conventions;
- basic coordinate/shape operations;
- spatial value types that every other system can use without knowing rendering or generation.

It does **not** own what objects currently exist at a coordinate. That belongs to WHAT.

---

## 3. Current spatial direction

The current project decision is an **authoritative invisible tactical grid**.

The grid exists for simulation and graphics simplicity, but does not need visible grid lines.

Baseline rules:

- actors occupy grid cells;
- actors move cell-to-cell;
- four-way facing is N/E/S/W;
- props and fixtures use whole-cell footprints;
- larger objects may occupy multiple cells;
- rotation changes both visual facing and occupied footprint;
- sub-cell/free movement is not part of the baseline;
- world data stores semantic facing/orientation, never atlas-specific rotation rules.

This preserves the persistent-world-like readability and makes collision, generation, AI, persistence and rendering substantially easier than continuous free movement.

---

## 4. Global coordinates are reality; chunks are not

The world uses one logical global grid coordinate space.

A cell such as `(1204, 881)` means that location in the world regardless of:

- which streaming partition currently contains it;
- whether the area is loaded;
- which generator originally created it;
- which renderer is drawing it;
- whether a base, road, house or forest occupies it;
- whether the player has ever visited it.

Streaming chunks/regions are later performance and storage mechanisms only.

A road does not "connect from chunk A to chunk B." The road occupies a sequence/network of global world coordinates. Streaming regions merely load whichever part of that road intersects them.

This is the primary defense against mismatched roads and infrastructure at region boundaries.

### Proposed coordinate type

Use an integer grid coordinate type compatible with Godot's integer spatial values. `Vector2i` is the natural implementation candidate unless later world-size requirements prove it insufficient.

Do not use floating-point position as authoritative simulation truth.

Why:

- deterministic equality;
- stable save/load behavior;
- simple neighborhood queries;
- simple pathfinding;
- simple generator validation;
- no epsilon/rounding problems;
- predictable rendering mapping.

### Physical scale

The contract should not scatter assumptions such as "one tile = exactly X pixels" or "one tile = exactly X meters" throughout systems.

Recommended planning assumption: **one tactical cell represents roughly human-scale floor space, approximately one meter**, because that works naturally for doors, people, beds, counters and rooms.

However, exact real-world meter equivalence should remain a centrally defined world-scale constant until the recovered art and building-scale design are visually verified.

Whatever value is chosen, there must be one canonical owner for it.

---

## 5. Direction and facing

Canonical baseline directions:

- NORTH `(0, -1)`
- EAST `(1, 0)`
- SOUTH `(0, 1)`
- WEST `(-1, 0)`

Direction should be a semantic enum/value, not an art frame number.

The Spatial Model should provide operations such as:

- `forward(cell, facing)`
- `behind(cell, facing)`
- `left_of(cell, facing)`
- `right_of(cell, facing)`
- `turn_left(facing)`
- `turn_right(facing)`
- `opposite(facing)`

Later systems can then ask meaningful spatial questions without each reproducing direction math.

Examples:

- vision asks what lies inside the actor's facing cone;
- melee asks whether a target is in front/side/back relation;
- furniture placement rotates a footprint;
- a sink may be placed facing a wall;
- zombie AI can choose a neighboring cell;
- rendering selects/rotates art from semantic facing.

---

## 6. Footprints

Every spatially placed entity that occupies physical space has a footprint.

Do **not** limit the contract to "width x height rectangle" even if most current props are rectangular.

Recommended footprint representation:

> a set/list of relative occupied cell offsets from an anchor cell.

Examples:

A chair:

```text
[(0,0)]
```

A north/south bed:

```text
[(0,0), (0,1)]
```

A 2x4 vehicle:

```text
[(0,0), (1,0),
 (0,1), (1,1),
 (0,2), (1,2),
 (0,3), (1,3)]
```

Rectangular helpers can create common footprints easily, but arbitrary masks leave room for irregular large objects later without changing the public contract.

### Rotation

The Spatial Model owns footprint rotation.

If an object rotates from NORTH to EAST, every relative occupied cell is transformed deterministically.

The object system should not hand-code a second set of occupied cells for every facing unless the actual physical shape differs by facing for a meaningful reason.

### Anchor

Every footprint has a stable anchor coordinate.

The anchor is simulation data and should not be inferred from sprite origin/pivot.

Art may use any visual pivot necessary; physics does not change because the sprite was drawn differently.

---

## 7. Occupancy is layered, not one Boolean

A cell should not have one simplistic `occupied = true/false` fact.

Several logically different things can coexist at one coordinate.

Example:

- grass terrain;
- a dropped backpack;
- blood/debris/effect data;
- an actor standing on that cell.

Recommended conceptual channels:

### Terrain / surface
Exactly one primary terrain/surface fact for a normal cell.

Examples:

- grass
- dirt
- asphalt
- wood floor
- carpet

### Structure
Wall/door/window/fence/gate or other architectural structure according to the final structure representation.

### Physical object / fixture
Furniture, appliances, trees, counters, crates, vehicles, etc.

### Actor
Player, survivor, infected, animal, etc.

### Loose items / contents
One or more items that do not necessarily block occupancy.

### Effects / transient markers
Blood, fire state, smoke state, sound-event marker, weather accumulation, etc. Exact future systems decide their own data; the spatial model only allows them to anchor to coordinates.

The Spatial Model defines how locations/footprints are expressed. WHAT decides which entities occupy these channels.

---

## 8. Walls, doors and windows — recommended DRAFT direction

This remains the largest unresolved spatial decision.

Two models are possible.

### Option A — structure cells

Walls, doors and windows occupy tactical cells.

Advantages:

- matches the existing/golden top-down art vocabulary closely;
- simplest generation;
- simplest collision;
- simplest pathfinding;
- simplest rendering;
- simplest construction/destruction;
- doors/windows are easy semantic replacements/variants of structural cells;
- already proven workable in earlier builds when door geometry is validated correctly.

Disadvantages:

- walls are abstractly "one cell thick";
- door geometry requires strict wall-axis validation;
- badly authored intersections can produce a wall appearing behind/through a door.

### Option B — edge structures

Walls, doors and windows exist on boundaries between floor cells.

Advantages:

- physically elegant;
- rooms do not lose full cells to walls;
- doors are naturally openings between spaces;
- avoids some classes of door-cell geometry errors.

Disadvantages:

- more complicated renderer;
- more complicated generation;
- more complicated collision/LOS rules;
- more complicated construction;
- recovered old art was not authored around this representation;
- introduces additional orientation/edge indexing everywhere.

### Current recommendation

**Use structure cells, not edge structures, unless recovered-art testing shows a decisive reason to change.**

This follows the project's "mini means reduced complexity" rule and preserves the existing graphical vocabulary.

If structure cells are approved, the contract must make door/window axis explicit rather than inferring it from neighboring art.

A door record would conceptually contain:

- world cell;
- structure semantic type;
- wall axis (`horizontal` / `vertical`);
- current open/closed state in WHAT;
- later lock/damage/etc. state in their owning systems.

Geometry rules then remain authoritative:

- a horizontal-wall door has clear perpendicular approaches north/south;
- a vertical-wall door has clear perpendicular approaches east/west;
- same-axis structural continuity must exist where appropriate;
- later furniture/clutter placement cannot overwrite reserved doorway approaches;
- invalid geometry is rejected rather than cosmetically hidden.

This recommendation is DRAFT until the user explicitly approves it.

---

## 9. WHERE must not own

The Spatial Model must not know:

- whether a door is currently open;
- how much health a wall has;
- whether an actor is injured;
- what a refrigerator contains;
- what sprite represents a couch;
- whether a cell is currently lit;
- how many ticks movement costs;
- whether a zombie wants to move there;
- which generator placed an object;
- whether a location is a base;
- whether a region is currently streamed.

Those are other systems' facts.

---

# PART II — WHAT: PERSISTENT WORLD / ENTITY STATE

## 10. Goal

The Persistent World system is authoritative about **what exists and its current persistent state**.

The scene tree is not authoritative.

The renderer is not authoritative.

The generator is not authoritative after creation.

A loaded chunk is not authoritative merely because it is loaded.

The persistent world owns the durable simulation facts.

---

## 11. Core world-state principle

Once an entity/place exists, its current state belongs to the world.

Example:

1. world generation creates a house and closed door;
2. the player opens the door;
3. the player later breaks the door;
4. the area unloads;
5. the player returns three days later.

The generator does not regenerate a closed door because "that is what belongs in the prefab."

Persistent state says the door was destroyed, so it remains destroyed.

This applies to:

- looted containers;
- moved/destroyed furniture;
- opened/broken doors and windows;
- parked/damaged vehicles;
- corpses;
- dropped items;
- player construction;
- barricades;
- crop state;
- generators/power devices;
- survivors/infected;
- ownership/claims where later systems introduce them;
- meaningful environmental damage.

---

## 12. Stable identity

Persistent entities need stable IDs independent of scene nodes and array positions.

An entity ID must survive:

- save/load;
- streaming unload/reload;
- reordering internal storage;
- renderer destruction/recreation;
- coarse/detailed simulation transitions.

Recommended public contract:

> IDs are opaque stable values. Consumers may compare/store them but may not derive gameplay meaning from their formatting.

For portable save formats, a string/serialized opaque ID is safer than exposing assumptions about memory addresses or object instance IDs.

Implementation may internally map persistent IDs to faster local integer handles, but that optimization must not leak into save/gameplay contracts.

---

## 13. World state is data, not thousands of permanent Nodes

The open world may eventually contain a huge number of persistent things.

Most should not be permanent Godot Nodes.

A house wall five kilometers away still exists, but it does not need an active Node.

A sleeping survivor across town still exists, but it does not need a rendered sprite or per-frame `_process()` call.

A looted refrigerator retains state even if no scene object represents it.

Recommended principle:

> **Plain persistent data is authoritative; active Godot Nodes/views are temporary materializations of relevant state.**

This is essential for performance and for keeping persistence independent of rendering.

---

## 14. Proposed world-state domain owners

The WHAT domain may contain several focused modules rather than one enormous `WorldState.gd`.

Possible responsibilities:

### `WorldState`
High-level facade/composition for world-state stores. It should not become a catch-all implementation file.

### `TerrainStore`
Primary surface/terrain facts by global cell/region.

### `EntityStore`
Stable entity records by persistent ID.

### `PlacementStore`
Entity anchor/facing/footprint placement facts using WHERE values.

### `WorldMutationService`
Validated create/update/remove/move operations and durable mutation recording.

### `WorldChangeSignal/EventBus`
Publishes changes so rendering, path caches, lighting caches, etc. may react without being directly called from unrelated gameplay systems.

### `OccupancyIndex`
Derived fast index from global cells to currently relevant placed entity IDs. This is a cache/index, not the source of truth.

These names are proposals. The important part is separation of responsibility.

---

## 15. Data model: typed semantic records, not one giant metadata Dictionary

Avoid a universal bag such as:

```text
entity.metadata["anything"] = whatever
```

That becomes impossible to reason about and encourages systems to reach into one another's private state.

Instead use explicit semantic records/components where the game actually needs persistent facts.

A placed world entity may conceptually have:

```text
WorldEntity
  id
  semantic_type
  placement
  persistent_tags
```

And optional owned records such as:

- DoorState
- ContainerState
- ActorState
- VehicleState
- DamageState
- ConstructionState
- PowerDeviceState

The Persistent World domain owns storage/identity/mutation infrastructure.

The **meaning** of health, vehicle mechanics, inventory contents, power networks, etc. belongs to those later systems.

WHAT stores their durable state through explicit contracts; it does not become the implementation of every mechanic.

---

## 16. Semantic type, not art type

World state stores semantic identities such as:

- `terrain.grass`
- `wall.house_siding`
- `door.house`
- `fixture.kitchen_sink`
- `furniture.sofa`
- `tree.oak`
- `vehicle.sedan`

It must not store:

- atlas number;
- source rectangle;
- sprite path as gameplay identity;
- rendering rotation rule;
- UI color;
- draw order.

The Art Catalog/renderers later decide how semantic world types look.

**Art remains separate from physics/state.**

---

## 17. Initial world versus current world

The design should explicitly distinguish:

### Initial/generated facts
What the world planner/materializer created when that place first came into existence.

### Current persistent facts
What exists after simulation/gameplay changes.

The player interacts only with current truth.

The generator is allowed to establish virgin state, but is not allowed to overwrite persistent changes later.

### Save strategy implication

The exact save format is deferred, but the architecture must permit efficient persistence strategies such as:

- generated baseline + mutation journal;
- fully serialized changed regions;
- hybrid region snapshots;
- deterministic untouched-region regeneration from world seed.

The save system may choose among those later.

The public gameplay contract must not care which storage optimization is used.

---

## 18. Creation sources all use the same world contract

The world must not care whether an entity came from:

- global procedural generation;
- local room materialization;
- prefab placement;
- pre-outbreak population setup;
- player construction;
- NPC construction;
- dropped inventory;
- destruction debris;
- save restoration;
- outbreak simulation.

All durable entities become ordinary world-state entities using the same spatial/identity rules.

This is what allows player-built bases anywhere without creating a special "base map" technology.

---

## 19. Bases emerge from world state

There is no foundational `BaseMap` or special base terrain.

A base emerges from ordinary systems:

- walls/doors/construction;
- containers/storage;
- beds;
- water;
- power;
- food/crops;
- vehicles;
- survivors;
- defenses;
- safety/control rules.

A future Base/Community Summary system may identify a region as a player's home or safe site and summarize its resources.

That summary is derived from persistent physical facts.

The underlying world remains normal world state.

---

## 20. Streaming/materialization relationship

Streaming is a future consumer of WHAT, not its owner.

A region may have states such as:

- not currently materialized;
- loaded as data only;
- actively simulated in detail;
- currently rendered.

But those are runtime resolution states.

They do not decide whether the world location exists.

The same entity ID/state must survive transitions among those resolutions.

### Coarse simulation seam

Persistent actors can retain high-level state while unloaded.

For example a distant survivor might have:

- persistent ID;
- current coarse location/route;
- health/infection state;
- household/group affiliation;
- next scheduled coarse event.

When the player approaches, a materialization system can instantiate detailed tactical actor state from the same persistent record.

The actor has not been replaced by a different person; only simulation resolution changed.

---

## 21. World mutation rules

Gameplay systems should not directly modify arbitrary internal dictionaries.

Mutations should pass through narrow explicit operations so invariants can be enforced and changes can be observed/persisted.

Examples:

- place entity;
- move entity;
- rotate entity;
- remove entity;
- set door state;
- update explicit component/record state;
- set terrain/surface where a system has authority;
- attach/detach container contents through inventory ownership;

The exact API is later implementation detail, but the principle is important:

> **World state has validated write paths and public read/query paths.**

Rendering receives change notifications and redraws.

Pathfinding receives occupancy changes and invalidates caches.

Save persistence receives mutation records.

No renderer needs to tell the world what happened visually.

---

## 22. WHAT must not own

Persistent World must not implement:

- procedural road rules;
- zombie decisions;
- first-aid rules;
- weapon damage formulas;
- art selection;
- input buttons;
- camera movement;
- action timing;
- weather simulation;
- lighting calculations;
- vision-cone calculations;
- base-management UI.

It stores durable facts those systems own through their public contracts.

---

# PART III — WHEN: TICK / ACTION / PAUSE KERNEL

## 23. Goal

The Tick/Action/Pause Kernel is authoritative about simulation time and scheduled execution order.

It creates the game's defining turn-based behavior:

> player chooses while time is frozen -> player commits an action -> world time advances through that action -> due actors/events resolve -> player becomes ready -> automatic pause.

The kernel must work without knowing what specific actions mean.

---

## 24. Simulation time is integer ticks, not frame time

Authoritative world time is an integer tick count.

Real rendering frame time is presentation only.

If the browser renders at 30 FPS or 120 FPS, the same committed action still consumes the same simulation ticks.

No zombie should become faster because a phone rendered more frames.

A world tick does not necessarily need a fixed publicly meaningful real-time duration during early design. A later calendar system may define the mapping from ticks to seconds/minutes.

The important contract is:

- ticks are integer;
- actions consume ticks;
- scheduled events have due ticks;
- execution order is deterministic.

---

## 25. Player auto-pause

Normal gameplay is not continuously real time.

Baseline:

1. Player-controlled actor is READY.
2. Simulation is auto-paused awaiting player intent.
3. Player chooses/commits an action.
4. Kernel advances simulation until that player actor becomes ready again or another explicit decision/interruption is required.
5. Simulation auto-pauses.

The player can therefore safely consider the next move indefinitely.

This is the central "turn-based persistent zombie survival" behavior.

---

## 26. Held movement is repeated discrete actions

Holding Forward should not create a separate real-time movement engine.

Instead:

```text
MOVE action
resolve ticks
MOVE action
resolve ticks
MOVE action
resolve ticks
...
```

Input may request another movement action automatically while held.

When input is released, no new action is requested and the next player-ready point remains paused.

This gives fluid-feeling traversal while preserving one authoritative action model.

The input system owns key/touch hold interpretation.

The tick kernel only sees ordinary movement actions.

---

## 27. Action definition versus action instance

Keep these concepts distinct.

### Action definition/spec
Reusable description/rules for an action type.

Examples later:

- move one cell;
- turn left;
- open door;
- search container;
- reload weapon;
- bandage injury;
- build wall.

The owning gameplay system defines requirements/cost calculation/effects.

### Action instance
A specific committed action by a specific actor at a specific world tick.

Conceptually:

```text
ActionInstance
  serial/id
  actor_id
  action_type
  start_tick
  total_duration
  elapsed_ticks
  status
  interruption_policy
  phases/checkpoints
  opaque action payload/reference
```

The scheduler owns timing/status.

The action's owning gameplay system owns the meaning/effects.

---

## 28. Preserve the good old TickScheduler ideas

The golden pre-rewrite `TickScheduler.gd` already proved several useful concepts and should be mined rather than discarded.

Worth preserving conceptually:

- authoritative `world_tick`;
- explicit action cost;
- deterministic actor scheduling;
- automatic player-ready state;
- action phases/progress;
- committed/resumable/cancelable interruption policies;
- resumable-action snapshots;
- event trace useful for debugging/tests;
- snapshot support.

The old implementation's main limitation is not that these ideas were wrong. It was too player-action-centric and accepted scheduled actors directly rather than defining the more general world event/action queue required by an open persistent world.

The new kernel should generalize the good semantics without inheriting old architecture blindly.

---

## 29. General scheduled queue: actors and systems

The scheduler should not only know about "actors."

Future world events also happen in time:

- healing/worsening checks;
- infection progression;
- weather transition/update;
- fire spread;
- generator fuel consumption;
- crop growth;
- power/network events;
- alarm expiry;
- distant-population actions;
- outbreak events;
- vehicle travel/coarse routing events.

Recommended abstraction:

> a deterministic queue of scheduled simulation events/actions with due ticks.

Actor turns are one major source of scheduled work, not the only source.

This prevents later systems from inventing separate clocks.

---

## 30. Deterministic ordering

When several things are due at the same world tick, ordering must be deterministic.

Recommended ordering key conceptually:

1. due world tick;
2. explicit narrow priority class only where physically necessary;
3. stable entity/system ID;
4. stable insertion serial as final tie-break.

Do not allow dictionary iteration order or frame timing to decide who acts first.

The exact priority classes should remain minimal. Overusing priority creates invisible game rules.

---

## 31. Action phases/checkpoints

Long actions should be able to expose meaningful progress without requiring every action to implement a custom scheduler.

Example reload:

```text
0       action begins
4 ticks old magazine removed
9 ticks new magazine inserted
12      weapon ready
```

Example first aid:

```text
0       begin treatment
20      wound exposed/cleaned
60      dressing applied
80      treatment complete
```

The scheduler should understand **time checkpoints/phases**, but not what their gameplay effects mean.

When a checkpoint is reached, it emits/dispatches a semantic action-phase event to the owning action executor.

The owning system may then commit appropriate WHAT mutations.

This allows interruption to preserve physically meaningful partial progress later.

Simple actions may have a single completion checkpoint only.

---

## 32. Interruption policies

Preserve three useful broad policies from the golden scheduler.

### COMMITTED
The action continues despite ordinary interruption unless an explicit forced-failure condition occurs.

Example candidates may include a momentum/commitment-heavy attack after a certain phase.

### RESUMABLE
The action can stop and later continue from saved progress.

Example candidates:

- long repair;
- construction;
- some medical treatment;
- searching a large area.

### CANCELABLE
Interruption ends the action; restarting begins again unless the owning system recorded partial world effects.

The scheduler owns interruption timing/status.

The gameplay system decides which policy applies and what physical effects occur.

Do not hardcode "taking damage cancels X" into the scheduler. Damage merely generates an interruption request/event; the action policy resolves it.

---

## 33. Hard application pause is different from auto-pause

There are two fundamentally different pause concepts.

### Tactical auto-pause
Normal gameplay state while the player must choose an action.

### Hard application pause
Real-life interruption safety.

Hard pause freezes **all simulation advancement**, including:

- active player action progress;
- zombies;
- NPCs;
- weather simulation;
- healing;
- outbreak progression;
- timers/events.

No ticks elapse during real-world absence.

The game must be able to hard-pause:

- through a clear explicit pause/menu action;
- on browser/tab visibility loss when reliable;
- on mobile/app lifecycle interruption where reliable;
- ideally on focus loss when that signal is trustworthy and does not create bad UX.

If hard pause occurs halfway through an action, the action remains halfway through at the same simulation tick when play resumes.

This is a product requirement, not a player ability with an in-world cost.

---

## 34. Save/load and mid-action state

The WHEN system must be serializable.

A save may need to preserve:

- current world tick;
- queued scheduled events;
- active action(s);
- action elapsed/progress;
- interruption/resume state;
- stable serial/tie-break state;
- player-ready/auto-pause state.

Loading a save must not silently restart a 90%-complete action from zero or let scheduled actors skip turns.

The exact save file format is a future persistence design, but the kernel contract must make a complete snapshot possible.

---

## 35. Distant/coarse simulation and the tick kernel

Open-world outbreak/population simulation cannot require every distant actor to execute every tactical step forever.

The WHEN design must therefore support multiple simulation resolutions without multiple incompatible clocks.

Example:

Nearby survivor:

```text
move one cell at tick 1020
open door at tick 1028
search room at tick 1040
```

Distant survivor:

```text
coarse action: travel home
start tick 1020
expected completion tick 1600
possible route-risk checkpoints/events
```

Both use the same world tick.

The coarse simulator may schedule larger semantic actions/events instead of thousands of detailed footsteps.

When an actor enters detailed simulation range, the resolution system translates persistent coarse state into detailed state without changing identity or resetting the clock.

---

## 36. WHEN must not own

The kernel must not know:

- how movement collision works;
- how much damage an axe does;
- how health severity works;
- how weather chooses rain;
- whether an actor is a zombie or human;
- whether a door is locked;
- what items a container holds;
- how a base is defined;
- what anything looks like;
- which key/button initiated an action.

It owns time, scheduling, action progress/status and pause semantics.

---

# PART IV — HOW THE THREE SYSTEMS CONNECT

## 37. Dependency direction

The cleanest proposed dependency direction is:

```text
WHERE: Spatial Model
        |
        v
WHAT: Persistent World State

WHEN: Tick / Action Kernel   (parallel core service)

        \       |       /
         \      |      /
          gameplay/action systems
                  |
       movement / doors / health /
       AI / construction / etc.
```

More precisely:

- WHERE has no gameplay dependency.
- WHAT uses WHERE value types to place persistent facts.
- WHEN uses world/entity IDs and time records but does not inspect WHAT internals.
- gameplay systems bridge them.

This avoids circular ownership.

---

## 38. Example: move forward

Input layer:

> player requests `MOVE_FORWARD`.

Movement system:

1. reads actor facing/position from WHAT;
2. uses WHERE to calculate target cell;
3. queries collision/occupancy derived from WHAT + WHERE;
4. calculates action duration using movement rules, health/fatigue/equipment modifiers supplied by their owning systems;
5. submits a movement ActionInstance to WHEN.

WHEN:

6. advances ticks;
7. resolves due world actions/events;
8. reaches movement completion/checkpoint.

Movement executor:

9. mutates actor placement in WHAT.

Renderer:

10. observes world change and redraws actor position.

No renderer moves the player.

No scheduler knows what a cell is.

No spatial module knows who the player is.

---

## 39. Example: open a door

Interaction system:

1. uses WHERE to identify the cell in front;
2. reads WHAT to confirm a door exists and its state;
3. validates later lock/strength rules through their owners;
4. creates OPEN_DOOR action with appropriate tick cost.

WHEN advances.

At the action effect checkpoint, Door/Interaction system mutates door state in WHAT.

Pathfinding/collision/rendering observe the change.

The scheduler does not contain `door.open = true`.

---

## 40. Example: serious leg injury

Health system stores/owns injury meaning.

It exposes derived modifiers such as:

- movement capability;
- movement-time multiplier;
- maybe stance/attack restrictions.

Movement system uses the modifier when building an action cost.

WHEN merely executes the longer duration.

Result:

A simple three-level injury model creates deep consequence because it feeds the universal action-time system.

No blood-volume simulation is necessary.

---

## 41. Example: player construction/base building

Construction system:

1. uses WHERE to test proposed footprint/orientation;
2. reads WHAT occupancy/current terrain;
3. validates materials/skills through inventory/character systems;
4. submits construction action to WHEN;
5. commits structure creation/mutations into WHAT at appropriate checkpoints.

The created wall is the same kind of persistent world structure as a generated wall.

No separate base map exists.

A future base summary may recognize that several beds, containers, powered appliances and walls form a useful home, but the physical reality is ordinary WHAT state using ordinary WHERE coordinates.

---

## 42. Example: world generation

Global World Planner:

- chooses coherent roads/utilities/parcels/building footprints in global WHERE coordinates.

Local Materializer:

- creates initial terrain/structures/props into WHAT according to those global facts.

After creation, WHAT is authoritative.

The generator does not remain active as a repair layer over player changes.

WHEN is not required to generate virgin geometry, although later outbreak/pre-start simulation uses WHEN/world time to evolve the populated world before player control.

---

## 43. Example: outbreak simulation

Population system creates persistent people in WHAT with homes/jobs/relationships and locations expressed through WHERE.

Outbreak/infection/behavior systems schedule actions/events through WHEN.

Nearby people may use detailed tactical movement.

Distant people may use coarse travel/work/home actions.

All remain persistent entities with stable IDs in WHAT and positions/routes anchored to the same WHERE world.

This lets the player story be embedded in the same causal simulation instead of spawning family members as quest props.

---

# PART V — FUTURE SYSTEM COMPATIBILITY CHECK

## 44. Rendering

Rendering reads WHAT placement/state using WHERE coordinates.

It maps semantic types/facing through ArtCatalog.

It must not mutate simulation truth.

The recovered multi-atlas graphics can therefore be rewritten independently of world persistence and time.

---

## 45. Vision/perception

Perception consumes:

- actor position/facing from WHAT;
- spatial direction/cell relationships from WHERE;
- opacity/structure facts from WHAT;
- later lighting levels from Lighting.

It does not need generation internals.

---

## 46. Lighting

Lighting consumes:

- global time/day phase eventually derived from WHEN/calendar;
- light-source entities/states from WHAT;
- structure/opacity geometry from WHERE + WHAT.

Lighting results can be cached/derived rather than becoming terrain identity.

---

## 47. Weather

Weather owns atmospheric state and schedules changes through WHEN.

It may affect:

- lighting;
- visibility;
- temperature;
- sound masking;
- ground/wetness later.

Weather VFX is separate rendering.

The spatial/world foundation does not implement rain.

---

## 48. Spatial sound

Sound events have:

- origin coordinate using WHERE;
- creation tick/duration using WHEN;
- semantic source/intensity owned by Sound;
- propagation affected by WHAT structures/environment.

The game may remain audibly silent while still simulating these events and displaying information visually.

---

## 49. Health and first aid

Health owns injury type/body region/severity/treatment/healing.

It reads/updates actor persistent state in WHAT through explicit records.

It schedules healing/worsening events through WHEN.

It exposes action modifiers to movement/combat rather than modifying the scheduler itself.

---

## 50. Inventory/containers

Items have stable persistent identities/ownership/location in WHAT.

A location may be:

- world cell;
- container entity ID;
- actor inventory/equipment owner.

Searching/transferring consumes time through WHEN.

Rendering does not need a loose tactical sprite for every inventory item.

---

## 51. AI / infected

AI reads perceived world state and emits desired semantic actions.

It does not directly teleport actors or advance time.

Movement/combat/etc. validate/execute those actions through the same WHERE/WHAT/WHEN contracts as player actions.

This prevents zombies from using a second magic movement system.

---

## 52. Vehicles

Vehicles are persistent entities with multi-cell footprints in WHERE/WHAT.

Driving/action mechanics later use WHEN.

The foundation does not decide whether tactical driving is detailed, coarse, or hybrid; the contracts support all three.

---

## 53. Construction/destruction

Construction/destruction mutate ordinary WHAT entities placed through WHERE.

Generated and player-built structures share the same physical representation.

This is required for bases anywhere.

---

## 54. Streaming

Streaming indexes global WHERE space and materializes relevant WHAT records.

It must not rewrite global coordinates or identity.

WHEN may reduce simulation detail outside active regions, but world tick remains globally authoritative.

---

# PART VI — SHARED FOUNDATION RULES

## 55. Determinism

Simulation order and persistent generation should be reproducible where practical.

Rules:

- use integer authoritative coordinates;
- use integer authoritative ticks;
- deterministic event tie-breaking;
- stable entity IDs;
- avoid relying on Dictionary iteration order for simulation outcomes;
- generation RNG should use explicit deterministic seeded streams;
- unrelated systems should not share one fragile global RNG sequence where adding a decorative roll changes outbreak outcomes.

Recommended later RNG strategy:

- world seed;
- named/sub-seeded streams by subsystem and/or region;
- deterministic derivation of child seeds.

This keeps modular rewrites from perturbing unrelated randomness unnecessarily.

---

## 56. Event/change communication

Avoid direct cross-module reach-through.

Prefer:

- narrow queries for current state;
- explicit commands/mutation methods for owned changes;
- signals/events for observations such as `entity_moved`, `door_state_changed`, `world_tick_changed`, `action_completed`.

Rendering can subscribe to change events.

Pathfinding can invalidate only affected regions.

Lighting can invalidate cells affected by a changed door/light source.

Save persistence can mark changed regions dirty.

This prevents one local change from forcing a full-world update.

---

## 57. No monolithic per-tick world loop

Do not create a loop that scans every persistent entity every world tick.

Open-world performance requires event-driven scheduling and spatial relevance.

Nearby detailed entities may update frequently because they are relevant.

Distant entities can schedule coarse future events.

Static terrain does nothing merely because time passed.

A closed refrigerator five kilometers away should consume approximately zero CPU until some system has a reason to act on it.

---

## 58. Mobile/Web performance principles

Because Safari/mobile is first-class:

- no permanent Node for every persistent object;
- no per-frame simulation of static world data;
- visible/render-active region only;
- event-driven redraw/invalidations where possible;
- O(1)-style spatial indexes for nearby occupancy/query;
- bounded active simulation bubble;
- coarse scheduled events outside detailed simulation;
- hard pause on reliable lifecycle interruption.

The goal is not to simulate less causally. It is to spend detail only where detail can matter.

---

# PART VII — PROPOSED MODULE OWNERSHIP

## 59. WHERE domain

Possible focused files:

```text
spatial/
  WorldCell.gd / shared coordinate conventions
  Direction4.gd
  Footprint.gd
  GridTransform.gd
  StructureGeometry.gd
```

Do not split helper functions merely for file count. The principle is one coherent reason to change per module.

---

## 60. WHAT domain

Possible focused files:

```text
world/
  WorldState.gd              # facade/composition only
  TerrainStore.gd
  EntityStore.gd
  PlacementStore.gd
  WorldMutationService.gd
  OccupancyIndex.gd          # derived cache/index
  WorldChangeBus.gd
```

Later systems add their own explicit durable records rather than filling `WorldState.gd` with mechanic-specific logic.

---

## 61. WHEN domain

Possible focused files:

```text
time/
  WorldClock.gd
  ActionScheduler.gd
  ActionInstance.gd
  ScheduledEvent.gd
  SimulationPauseController.gd
```

Action meaning/execution stays in owning gameplay systems.

---

## 62. Action layer above the foundation

The three foundations need an explicit bridge layer rather than cross-calling each other's internals.

Conceptually:

```text
actions/
  ActionRequest.gd
  ActionResult.gd
  ActionCoordinator.gd
```

But do **not** make `ActionCoordinator` a god object containing movement/combat/health rules.

Its role is orchestration/routing only.

Movement, doors, inventory, combat, first aid, construction, etc. remain their own action providers/executors.

---

# PART VIII — TESTING / ACCEPTANCE CRITERIA

## 63. WHERE contract tests

Before WHERE is considered implemented, tests should prove at least:

- cardinal direction transforms are exact;
- left/right/opposite are deterministic;
- arbitrary footprints rotate correctly through all four facings;
- rotated footprints return to original after four rotations;
- global coordinate operations do not depend on streaming partitions;
- structure/door geometry contract rejects invalid arrangements once cell-vs-edge representation is approved;
- renderer-specific data is absent from spatial values.

---

## 64. WHAT contract tests

Tests should prove:

- entity IDs survive serialization round-trip;
- placed entities retain global position/facing;
- create/update/remove/move operations are deterministic;
- a persistent mutation survives unload/reload simulation;
- generated baseline cannot overwrite a recorded mutation;
- derived occupancy indexes rebuild from authoritative state;
- world state can exist headlessly without rendering/Godot scene nodes;
- two different creation sources (for example generated object and test construction object) become equivalent ordinary persistent entities after creation.

---

## 65. WHEN contract tests

Tests should prove:

- identical action/event inputs produce identical execution order;
- same-tick ties are deterministic;
- player-ready state causes auto-pause;
- action duration advances exactly the correct number of ticks;
- other due actions/events resolve during a long player action;
- phases/checkpoints occur at expected ticks;
- committed/resumable/cancelable interruption semantics work;
- hard pause advances zero simulation ticks;
- save/snapshot + restore preserves active action progress and queue ordering;
- coarse scheduled events and detailed actor actions can coexist on one world clock.

---

## 66. Integration foundation tests

Use synthetic test entities/actions, not fake gameplay features presented as final mechanics.

Examples:

### Movement contract smoke
A test actor at `(10,10)` facing EAST performs a 5-tick test move to `(11,10)` while another scheduled test event occurs at tick 3. Final state proves time/order/position integration.

### Door-state contract smoke
A test structural entity receives a timed state-change action. Collision/query state changes only when the action checkpoint commits WHAT mutation.

### Persistence smoke
Create an entity, mutate it, simulate region unload/reload through data serialization/reconstruction, prove the mutation remains and generator baseline does not return.

These are foundation tests, not placeholder zombie/combat systems.

---

# PART IX — FAILURE MODES THIS DESIGN IS INTENDED TO PREVENT

## 67. Generator owns the world

Bad:

> regenerate local map every visit and patch remembered changes over it.

Better:

> generator creates initial state once; persistent WHAT is authoritative afterward.

---

## 68. Renderer owns collision

Bad:

> sprite index 23 means closed door, so collision checks atlas index 23.

Better:

> WHAT says this semantic door is closed; ArtCatalog independently chooses sprite 23 or another recovered visual.

---

## 69. Player-only time system

Bad:

> player action advances ticks but weather/zombies/outbreak use separate timers.

Better:

> all simulation events share one world tick/scheduling contract at suitable resolution.

---

## 70. Chunk boundaries define geography

Bad:

> each generated chunk chooses where its road exits.

Better:

> global road network already exists in WHERE/world plan; materialized regions follow it.

---

## 71. Godot scene tree equals persistent world

Bad:

> unloading a Node destroys the only copy of an entity's state.

Better:

> Nodes/views are temporary materializations of authoritative WHAT records.

---

## 72. Base becomes a special mode

Bad:

> BaseScene uses separate building/storage rules from the open world.

Better:

> construction/storage/power/etc. work anywhere legal; a base is an emergent cluster of ordinary world systems.

---

## 73. Health invades scheduler

Bad:

> TickScheduler contains special code for broken legs.

Better:

> Health exposes movement/action modifiers; Movement calculates action duration; Scheduler executes generic duration.

---

# PART X — IMPLEMENTATION ORDER AFTER APPROVAL

## 74. Recommended order

Even though WHERE/WHAT/WHEN form one foundation conceptually, do not implement all three in one giant prompt.

Recommended implementation slices after explicit approval:

### Slice 1 — WHERE

Implement only:

- global integer cell conventions;
- directions;
- footprints/rotation;
- approved structure/opening representation;
- headless tests.

No generator. No renderer. No player movement system.

### Slice 2 — WHAT

Implement only:

- persistent entity identity;
- terrain/entity/placement stores;
- validated mutations;
- occupancy index;
- serialization-ready snapshot contract;
- headless tests.

No procedural generator yet.

### Slice 3 — WHEN

Implement only:

- world clock;
- deterministic scheduled queue;
- action instances/phases;
- interruption policies;
- auto-pause/hard-pause state;
- snapshot contract;
- headless tests.

No combat/health/zombie rules.

### Slice 4 — Foundation integration harness

Use synthetic test actions/entities to prove WHERE/WHAT/WHEN work together through public APIs.

After that, future systems can be designed against real stable contracts.

---

# PART XI — OPEN DECISIONS BEFORE APPROVAL

## 75. Spatial structure model

**Recommendation:** structure cells with explicit wall/door/window axis, because it is simpler and compatible with recovered art.

Alternative: edge structures.

This must be explicitly approved before WHERE implementation.

---

## 76. Exact cell physical scale

**Recommendation:** approximately 1 meter per cell as the planning baseline, held behind one canonical scale constant rather than duplicated assumptions.

Exact visual/physical scale should be confirmed against recovered art and believable room sizes before being treated as immutable.

---

## 77. Action checkpoint effect timing

**Recommendation:** scheduler owns checkpoint timing only; owning gameplay action executor commits world effects at checkpoints.

This avoids a scheduler full of mechanic-specific code while supporting partially completed long actions.

---

## 78. Event priority

**Recommendation:** deterministic ordering by due tick -> minimal priority class -> stable ID -> insertion serial.

Keep priority classes extremely small and explicit.

---

## 79. Persistent storage strategy

Do **not** lock save files to one implementation yet.

The WHAT contract should permit generated baseline + mutations, region snapshots, or hybrids.

Choose the concrete save/storage strategy only after streaming/materialization design and performance testing.

---

# PART XII — NORTH-STAR FIT

## 80. persistent-world

The authoritative grid, four-way facing and tile-scale physical objects preserve a readable top-down world without demanding continuous 3D/free-movement complexity.

## 81. Turn-based

The universal integer tick/action scheduler makes every committed action carry time/risk while allowing unlimited decision pause and immediate real-life hard pause.

## 82. Mini survival-game

Persistent world state plus shared spatial/time consequences lets simplified systems interact deeply.

A simple injury model can still slow movement actions.

A simple weather state can still alter visibility, light and sound masking.

A simple container model can still remember that a house was looted months ago.

A simple zombie can still respond to the same physical sound/perception/action rules as everything else.

The complexity is spent on **connections and consequences**, not internal simulation trivia.

## 83. Mood

Persistent places, darkness, weather, line of sight, spatial sound, family history and the causally evolved outbreak all become compatible with the same foundation without being hardcoded into it.

That keeps mood systemic rather than dependent on scripted event tricks.

---

# PART XIII — APPROVAL STATUS

## 84. Settled cross-system decisions already inherited

Already settled outside this document:

- persistent logically continuous open world;
- no extraction/raid/staging loop;
- player-built/secured bases anywhere ordinary world rules permit;
- invisible tactical grid;
- cell-to-cell actors;
- N/E/S/W orientation;
- whole-cell footprints rather than sub-cell/free movement baseline;
- hard real-life pause requirement;
- global planning owns cross-region road/infrastructure coherence;
- generation is input to persistent world, not owner after creation;
- causal outbreak/population simulation is a long-term goal;
- player story is embedded in the generated pre-collapse world;
- Main/root remains composition only.

## 85. New DRAFT proposals in this document

Require explicit user review/approval before implementation:

- WHERE/WHAT/WHEN as the canonical lowest-level simulation foundation;
- structure cells rather than edge structures;
- approximately one-meter planning scale per tactical cell;
- arbitrary-mask footprints with generic 90-degree transforms;
- layered occupancy concept;
- stable opaque persistent entity IDs;
- persistent plain data rather than permanent Godot Nodes;
- deterministic scheduled event queue shared by actors and world systems;
- scheduler checkpoints with gameplay effects committed by owning action systems;
- committed/resumable/cancelable interruption policy family;
- one global world tick supporting both detailed and coarse simulation;
- separate tactical auto-pause versus hard application pause;
- event-driven world changes and scheduling rather than full-world per-tick scans;
- implementation order WHERE -> WHAT -> WHEN -> synthetic integration harness.

This document remains **DRAFT** until the user approves or revises these proposals. Approval of the umbrella does not require all three systems to be implemented together; implementation must still proceed one bounded subsystem at a time.
