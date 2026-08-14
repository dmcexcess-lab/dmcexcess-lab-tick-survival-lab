# Tick Survival Lab — World / Navigation Foundation Audit

## Purpose

This document answers one question: **what belongs in the basic world/navigation foundation before Tick Survival Lab moves into actor systems?**

It is intentionally narrower than the full roadmap. It covers generated geography, movement, physical map facts, lighting, vision/fog, weather presentation, time, mobile controls, and visual clutter. It does not pull inventory, combat, wounds, zombies, companions, crafting, settlements, or persistence implementation forward.

## Current foundation status

### Authoritative time and movement — READY

- Every committed player action advances the authoritative tick scheduler.
- Walking, running, turning, crouching, doors, and developer timing proofs use explicit tick costs.
- Player control auto-pauses when the action resolves.
- Calendar/date/daylight phase advance from scheduler ticks rather than presentation time.
- Mobile forward/back preserve facing; turning costs time independently.
- Safari synthetic-click suppression protects one-touch/one-action behavior.

### Camera and large local map — READY

- Current stress region is 64×64.
- Rendering follows the player and only draws the current camera window.
- Player-controlled zoom changes presentation only.
- World coordinates, movement cost, LOS and simulation geometry do not change with zoom.

### Biomes — FOUNDATION READY

Current local vocabulary:

- residential;
- commercial;
- downtown;
- woods;
- rural.

Biome fields are deterministic and contiguous rather than random tile noise. They are good enough to host the next gameplay systems.

They are **not** the final island geography model. Coastline, elevation, rivers/drainage and macro infrastructure should eventually constrain biome placement.

### Roads — FOUNDATION READY AFTER GENERATOR V2 PASS

Generator v2 replaces the arbitrary full-region street grid with a hierarchy:

- one main connected arterial network reaching all four region exits;
- biome connectors toward the arterial;
- developed local streets;
- rural service roads;
- woodland dirt trails;
- developed sidewalks and rural dirt shoulders.

Spawn and all four edge exits are required to belong to one road-connected network. Validation fails if later generated geometry blocks a road.

Developed structures require useful road frontage and orient their entrance toward the nearest road side.

This is good local logic. **Cross-chunk road contracts remain intentionally unsolved.**

### Structures — FOUNDATION READY, CONTENT LIGHT

Procedural buildings currently prove:

- parcel-based placement;
- road-frontage constraints;
- wall/door/window physical facts;
- indoor areas;
- per-building wall-theme metadata;
- biome-appropriate initial light types;
- deterministic interior/exterior clutter.

The current buildings are still deliberately small/simple. A future structure-content pass should introduce authored archetype/template libraries for richer houses, stores, industrial buildings, garages, sheds, clinics, schools, etc. That is content depth, not a prerequisite for zombies.

### Physical clutter — READY FOR THIS STAGE

The clutter atlas now adds indoor and outdoor place-language without adding a new simulation layer.

Indoor examples:

- chair, desk, toilet, sink;
- cabinet, bookshelf, television, lamp;
- rug, laundry, cardboard.

Outdoor examples:

- tree, bush, fence, mailbox;
- trash can, road sign, bench, hydrant;
- streetlight, planter, tire pile;
- picnic table, firewood.

Important rule: sprite, movement blocking and sight blocking are separate properties. Large objects may enter `obstacles`; tall objects may be opaque; small clutter may be purely visual.

### Lighting — READY, WITH KNOWN FUTURE REFINEMENTS

Current system supports:

- tick-driven night/dawn/day/dusk;
- weather daylight modifiers;
- indoor/outdoor ambient distinction;
- powered/unpowered light sources;
- radial authored lights;
- directional flashlight;
- window daylight;
- LOS occlusion;
- biome-aware ambient levels in procedural regions.

This is sufficient before actors.

Useful future refinements that do **not** block the next milestone:

- smooth sun brightness interpolation instead of four broad daylight bands;
- true additive blending of overlapping weak lights rather than strongest-light dominance;
- persistent/broken light fixtures and player-built lights once mutable-world systems arrive;
- richer indoor room-specific ambient handling;
- renderer use of per-building wall-theme metadata throughout the procedural view.

### Vision / fog — READY

Current system supports:

- four-direction facing cone;
- light-dependent recognition range;
- weather-dependent range;
- wall/closed-door/tall-prop occlusion;
- transparent windows;
- remembered fog;
- local bounded calculations on large maps;
- sealed-corner/supercover-style blocking so diagonal LOS cannot squeeze between two touching opaque cells.

This is enough to build zombie sight on top of.

Potential later refinements:

- partial concealment from brush/smoke instead of binary opacity;
- elevation/height layers;
- actor-to-actor cover and peeking;
- dynamic smoke/fire opacity.

None should block the next actor milestone.

### Weather / environment presentation — READY

Current fixed test profiles include clear, rain, storm, fog, wind and snow.

Weather affects visibility/light and has presentation-only VFX that continue while auto-paused. Weather VFX are masked from indoor/wall cells.

Full weather-pattern simulation, wetness, snow accumulation, crop effects, body temperature and fire interactions are later systems.

## What is genuinely missing before actor systems?

### Option A — move on now

This is the recommended choice if the goal is to prove the survival simulation quickly.

The local world is already sufficient for:

1. spatial silent-sound events;
2. zombie perception;
3. persistent zombie actors;
4. timing-driven pursuit/combat.

Those systems will expose more useful map problems than additional visual polishing will.

### Option B — one more world-only milestone: macro geography + chunk contracts

Do this first only if we want to lock the island topology before actor work.

Scope should be limited to:

- island/coastline mask;
- water/river/drainage channels;
- simple elevation/slope categories;
- deterministic shared chunk-edge contracts for roads/trails/water/utilities/biome continuity;
- bombed bridge/failed crossing hooks at the macro-world layer;
- loading neighboring generated regions while preserving world coordinates.

Do **not** add zombies, loot, settlements, vehicles or outbreak simulation to that milestone.

## Recommendation

The basic navigation/world foundation is now strong enough to move forward.

The best next gameplay milestone remains **0.3C Spatial Sound Visualization**, because it exercises walls, doors, windows, weather, distance, local world coordinates and the authoritative scheduler without requiring combat yet. Persistent zombies should follow immediately after and consume the same sight + sound model.

If play-testing the revised roads reveals obvious geography problems, fix those locally. Otherwise stop polishing the foundation and let actor simulation become the next source of requirements.
