# Mini-World / Streetscape 0.5 Design

Status: implementation target for the post-art, pre-infected world pass.

## 1. Goal

Tick Survival Lab is pivoting from the earlier idea of one continuously rendered island toward a **mini-world made of persistent local regions**. The reason is both technical and design-oriented:

- mobile Safari already shows measurable presentation cost when the tactical camera exposes too many cells while weather, lighting and fog are active;
- the tactical game benefits more from dense, believable local spaces than from rendering a huge amount of low-value empty world at once;
- the full-screen map is already useful and can become the world-scale navigation layer without changing authoritative tick semantics;
- the current 64×64 region generator is large enough to contain meaningful neighborhoods, shops, roads, woods and rural space while remaining practical for local simulation.

The target feel is therefore **"mini Zomboid"**: a systemic local survival simulation connected by a cheap, deterministic macro map. Only the current local region is rendered and simulated in tactical detail.

This document defines the world/navigation, streetscape, building-family and presentation rules for that pivot.

---

## 2. Non-goals

This milestone does **not** add:

- infected AI;
- loot economy or inventory world sprites;
- body simulation;
- combat;
- vehicles;
- multi-floor buildings;
- full island coastlines, rivers or elevation;
- long-term save serialization;
- autonomous off-screen simulation of all 25 regions;
- a minimap.

All buildings remain **single level**. Inventory/loot remains data/UI only; the physical world continues to show environment, structure, fixtures, furniture, vegetation, civic infrastructure and clutter.

---

## 3. Architecture

### 3.1 World layer

A new deterministic `MiniWorldState` owns the bootstrap macro world:

- size: **5×5 regions**;
- each region is conceptually one 64×64 tactical area;
- one `world_seed` deterministically defines all 25 region identities and local seeds;
- the current region coordinate is world state, not presentation state;
- the center begins as downtown;
- commercial, residential, rural and woodland identities are guaranteed to exist in every generated world;
- the remaining cells vary from the seed.

This gives an effective conceptual footprint of 320×320 tactical tiles without ever rendering or simulating that entire area at once.

The 5×5 size is intentionally conservative. The architecture may later expand the macro dimensions without changing local-region coordinates or the physical map schema.

### 3.2 Local layer

The existing deterministic `ProceduralRegionGenerator` v4 remains the proven physical baseline for:

- biome fields;
- roads;
- road topology masks;
- walls;
- doors;
- windows;
- lighting markers;
- collision facts;
- rooms;
- parking metadata;
- props;
- exits.

`MiniRegionGenerator` v5 wraps that baseline and applies the new coherence/street/building-family pass. V5 does not invent a second physical-world language.

Dependency direction remains:

**macro region data → local generation → local world state → scheduler/actors → presentation**

### 3.3 Region travel

Every local region still has four edge road ports. Continuing through an edge road transitions to the adjacent macro region when one exists.

Travel rules:

- crossing a region edge is a real movement action and costs authoritative movement ticks;
- opening/closing the world map costs zero ticks;
- scheduler/calendar state persists across region transitions;
- weather state persists across region transitions;
- survivor stats/facing persist;
- local mutable map state is reloaded from generation in this bootstrap pass; durable per-region deltas are deferred to persistence work;
- reaching the edge of the 5×5 macro world blocks movement rather than wrapping.

The eventual save system will store local-region deltas keyed by world seed + region coordinate. This milestone establishes those coordinates but does not implement the save store.

---

## 4. Full-screen mini-world map

The full-screen `MAP` / keyboard `M` view becomes the central world-orientation tool.

It shows:

- all 25 macro regions;
- region identity (downtown, commercial, neighborhood, rural, woods);
- a red survivor dot positioned inside the current macro cell according to the survivor's local 64×64 coordinates;
- current region name;
- world seed;
- current local seed;
- a lightweight adjacency/road-grid abstraction.

It deliberately does **not** render all 25 tactical maps. The map is cheap macro data.

There remains:

- no minimap;
- no second local-area-map mode;
- no world simulation advancement while inspecting the map.

Safari remains first-class: the existing on-screen `MAP` button and touch suppression are retained.

---

## 5. Tactical zoom / performance policy

The overworld now owns broad orientation. Therefore tactical zoom no longer needs to expose the old 16×14, 18×16 or 20×17 high-cost views.

Supported tactical views become:

1. 39 px tiles — 14×12 cells — far local overview;
2. 44 px tiles — 12×10 cells — default;
3. 50 px tiles — 10×9 cells — close detail.

Performance rules:

- the default is 12×10;
- 14×12 is explicitly a lower-fidelity cosmetic mode;
- 14×12 cosmetic animation is capped lower than close views;
- far-view fog uses a cheaper uniform outdoor-cell wash rather than per-cell animated drift;
- far-view rain/snow/wind particle counts are reduced;
- authoritative weather/perception values are unchanged;
- close views keep the richer current weather presentation.

This is an LOD policy, not a gameplay difficulty change.

---

## 6. Streetscape coherence

The current generator contains road connectivity but very little civic grammar. This milestone adds rules that make roads read as actual streets.

### 6.1 Traffic control

Every generated local region must contain visible traffic-control vocabulary.

Main developed intersection:

- traffic lights are guaranteed around the central arterial intersection;
- at least one stop sign is also guaranteed in the local map;
- street-name signage is placed with developed intersections.

Additional intersections:

- arterial/secondary intersections in downtown/commercial space may receive traffic lights;
- local/secondary developed intersections receive stop signs;
- woodland trails do not receive city traffic lights;
- rural/woodland roads bias toward utility poles instead of dense civic furniture.

The art already exists; this milestone makes the generator actually consume it.

### 6.2 Street furniture

Developed arterial frontage can place:

- streetlights;
- hydrants;
- street-name signs;
- stop signs;
- traffic lights.

Rural/woodland frontage can place:

- utility poles;
- sparse road-control objects;
- existing natural clutter.

Art remains separate from physics. A sign is not automatically collision or LOS authority merely because it is visible.

---

## 7. Parking rule

Parking must have a reason to exist.

Old behavior allowed a commercial parcel to become a standalone parking lot with no destination. That is no longer valid.

V5 invariant:

> Every `parking_lot` rectangle must overlap a generated building footprint.

Existing parking-only commercial parcels are repaired into attached multi-unit strip malls rather than simply deleted. This preserves paved commercial variety while giving the pavement a destination.

Parking remains valid for:

- standalone stores;
- strip malls;
- offices/industrial contexts when generated with attached structures;
- future civic/service destinations.

Pure woods/rural empty-space generation must not create unexplained commercial lots.

---

## 8. Building-family grammar

The art freeze is complete; this milestone makes the generator use more of that vocabulary through recognizable single-story families.

Every `building_rects` entry gains a sixth field: `building_kind`. Existing themes remain presentation/material metadata.

### 8.1 Existing/default families

- `house`
- `farmhouse`
- `standalone_store`
- `office`
- `warehouse`

### 8.2 New families

#### Trailer

- long/narrow single-story footprint;
- compact living/kitchen zone;
- sleeping/bath zone;
- refrigerator/stove/bed/bath fixtures;
- residential/rural weighting.

#### Mansion / estate house

- uses the largest available house footprint in the current parcel grammar;
- four distinct room zones;
- richer flooring;
- denser living/kitchen/bed/bath furniture;
- residential/rural-estate weighting.

This is a gameplay-scale "mansion," not a literal architectural megamansion; the world remains tile-efficient.

#### Duplex

- one shell divided into two sealed residential units;
- two separate exterior entrances;
- shared dividing wall;
- no unnecessary interior connection between the two units.

#### Strip mall

- two- or three-unit single-story commercial shell;
- unit partitions;
- each unit receives its own exterior storefront door;
- doors are spaced, never a solid run of adjacent door tiles;
- storefront glass vocabulary is used between entrances;
- existing parking remains in front/around the attached building.

The family system is intended to expand later by adding constrained grammars, not by scattering arbitrary wall tiles.

---

## 9. Door sanity rules

The reported "three doors in a row" artifact is invalid procedural output.

V5 post-generation sanitation and validation enforce:

- no horizontal run of three adjacent door cells;
- no vertical run of three adjacent door cells;
- intentional multi-unit frontage uses separated entrances;
- accidental middle doors in a three-door run are converted back into wall using the nearest wall material theme.

Two-door adjacency remains allowed for future deliberate double-door cases, but current strip-mall generation does not require it.

---

## 10. Determinism

For a fixed world seed:

- macro region identities are deterministic;
- each macro coordinate gets a deterministic local seed;
- streetscape dressing is deterministic;
- building-family substitutions are deterministic;
- parking repairs are deterministic;
- traffic-control placement is deterministic.

Starting a new world seed creates a different 5×5 world.

This milestone does not yet persist runtime modifications between unload/reload. Deterministic regeneration is the baseline underneath future saved deltas.

---

## 11. Validation / CI contract

A new permanent mini-world smoke test must prove:

- 5×5 macro dimensions;
- deterministic macro generation;
- all five region identities exist;
- deterministic local region generation;
- generator version 5 metadata;
- base road/network validation still passes;
- at least one stop sign and traffic light in each v5 local map;
- no parking lot without an overlapping building;
- no three-door run;
- building-family metadata is present;
- across representative region identities the new trailer, mansion, duplex and strip-mall families appear;
- world-edge movement bounds work.

The normal permanent gate still must pass:

- Godot import/parse;
- authored map smoke;
- legacy v4 region smoke;
- new v5 mini-world smoke;
- tick/calendar/environment/perception smokes;
- startup;
- Web export;
- Pages deploy.

Keeping the v4 smoke is intentional: v5 must not silently break the physical baseline it wraps.

---

## 12. Acceptance criteria

This milestone is complete when a player can:

1. load a new seeded 5×5 mini world;
2. open the full-screen map with `M` or the Safari `MAP` button;
3. see a red dot inside the current macro region;
4. identify broad region types from the map;
5. move through a local edge road into an adjacent macro region without resetting world time;
6. encounter visibly more civic road furniture, including traffic lights and multiple stop signs;
7. encounter trailers, mansions/estate houses, duplexes and multi-unit strip malls across generated regions;
8. never encounter a generated parking lot with no building destination;
9. never encounter a three-door run;
10. use only the three performance-safe tactical zoom levels;
11. use the farthest local zoom without the previous wide-map full-fidelity weather cost.

---

## 13. Deferred next steps

Once this world/navigation pass is stable, the preferred gameplay-system sequence remains:

1. spatial silent sound visualization;
2. infected actors consuming sight + sound on the scheduler;
3. loot/search/inventory data;
4. combat/body state;
5. per-region persistence deltas;
6. richer macro road topology / blocked crossings / larger world options if performance data supports it.

The critical architectural decision is now fixed: **the macro map is cheap world-scale data; tactical rendering is local.**
