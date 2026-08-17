# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract with accepted Trailer v2, accepted Small Farmhouse v2, and Large Farmhouse Candidate 004**

Date: 2026-08-16; farmhouse archetype work current through 2026-08-17.

Depends on implemented WHERE / WHAT, Art Catalog + tactical layer renderers, Door State, and System 18 Door Interaction. Future Global World Planning remains a separate higher-level owner.

## 1. Goal

Create a reusable local building generator that turns an already-chosen building slot into a believable physical building.

Development loop:

> generate an archetype candidate -> play/inspect it -> user critiques it -> convert critique into archetype rules -> preserve accepted versions -> add the next archetype

System 19 is not a screenshot generator and not the global world planner.

## 2. Architectural boundary

System 19 answers:

> Given a global-space envelope, orientation, frontage, archetype, stable instance namespace and seed, what physical building exists here?

It does not decide towns, roads, parcels, addresses, utilities, household occupants, loot, outbreak history, streaming regions, camera behavior or which property receives which building type.

A request envelope is a bounding area. Archetypes may be rectangular or irregular, but geometry should be no more complex than the building needs.

## 3. Implemented owners

### `BuildingGenerationRequest.gd`
Pure request facts: instance namespace, archetype ID, seed, global envelope, N/E/S/W orientation and caller-selected frontage.

### `GeneratedBuildingPlan.gd`
Pure semantic result: bounding footprint, ground, structures, props, generation-only room-purpose regions, deterministic roles, version and seed provenance.

### `LocalBuildingGenerator.gd`
Registry/coordinator only. It routes:

- `residential.trailer.singlewide`
- `residential.house.farm_small`
- `residential.house.farm_large`

It contains no room-layout logic.

### `archetypes/TrailerBuildingGenerator.gd`
Owns the accepted single-wide trailer rules.

### `archetypes/FarmhouseBuildingGenerator.gd`
Owns only the accepted small farmhouse rules. Large-house critique must not modify it unless the user explicitly reopens the small baseline.

### `archetypes/LargeFarmhouseBuildingGenerator.gd`
Owns only `residential.house.farm_large`, including room program, compact partitioning, openings and room-specific prop dressing.

### `GeneratedBuildingValidator.gd`
Shared structural validator verifies footprint containment, unique roles, legal axes, no structure/prop contradictions, valid room records, exactly one primary exterior door, no blocking furniture on doors, and reachability from the primary entrance with doors conceptually passable.

The shared validator does not hard-code archetype-specific room names, dimensions or clutter style. Dedicated CI locks each archetype program.

### `GeneratedBuildingMaterializer.gd`
Consumes a validated plan and public initial-state contracts only. It writes initial WHAT terrain/entities/placements, enrolls generated doors CLOSED, refuses unrelated occupied cells, and restores WHAT + Door State if a later write fails.

After materialization, generator ownership ends.

## 4. Determinism / identity

Same archetype version + request + seed must produce the same semantic plan/signature.

Child IDs derive from caller instance namespace + deterministic role.

Intentional same-seed archetype output changes bump that archetype version.

Different farmhouse sizes remain separate archetypes:

- small: `residential.house.farm_small`
- large: `residential.house.farm_large`

## 5. Accepted Trailer baseline — v2

Preserve the accepted 5×12 trailer baseline unless explicitly reopened.

## 6. Accepted Small Farmhouse baseline — v2

Archetype: `residential.house.farm_small`

User accepted it on 2026-08-17 with:

> “Nice save that as small farm house.”

Canonical program:

- 13×9 shell;
- one 11×3 open living/kitchen;
- bedroom 1 3×3;
- bathroom 3×3;
- bedroom 2 3×3;
- private rooms directly behind one partition row;
- no oversized middle circulation band;
- two exterior + three private-room doors;
- seven windows;
- restrained wall-aware furniture.

This is a protected accepted baseline.

## 7. Large Farmhouse Candidate 004 — current

Archetype: `residential.house.farm_large`

Version: **4**.

Original requirement remains 3 bedrooms, 2 bathrooms, separate living room and kitchen, with compactness taking precedence over decorative irregularity.

### 7.1 Historical critique path

Candidate 001 used a 25×20 L-shaped footprint with large rooms and a central hall and was rejected as too large/hallway-heavy.

Candidate 002 established the density direction: 21×9 shell, 10×3 living room, 8×3 kitchen, three 3×3 bedrooms, two 3×3 bathrooms and no hall/corridor room.

Candidate 003 kept that structure while replacing the living/kitchen door with upper divider wall + lower open passage, converting the kitchen bottom row to a clutter-free wood runner, moving the sink to the north wall and adding a breakfast table near the east wall.

Candidate 004 keeps **all Candidate 003 structure and floor geometry unchanged** and changes only prop placement/orientation/density.

### 7.2 Structure/floor lock inherited from Candidate 003

Canonical NORTH structure remains:

- 21×9 shell;
- 10×3 living room;
- 8×3 kitchen;
- three 3×3 bedrooms;
- two 3×3 bathrooms;
- 7 total doors: two exterior + five private-room doors;
- 11 windows;
- living/kitchen divider walls at local `(11,1)` and `(11,2)`;
- no structure at local `(11,3)`, preserving the lower open passage;
- kitchen local x=12..19, y=3 remains `ground.laminate_light` and must remain prop-free.

No structure function changes are part of Candidate 004.

### 7.3 Common-room clutter rule

Candidate 004 introduces a **local-cluster dressing rule** for this archetype:

- do not distribute a small number of props across the full width/length merely to occupy space;
- prefer believable 2–6 item local groups anchored by room purpose, walls, appliances, seating or doors;
- related furniture in a cluster should generally have another cluster member within one or two cells;
- open floor is allowed to remain open;
- circulation routes and the kitchen wood runner take precedence over decorative density.

This is currently a `farm_large` archetype rule, not a new global clutter-generation subsystem.

### 7.4 Living-room cluster

Canonical NORTH living dressing:

- `prop.bookshelf_tall` at local `(1,1)`, SOUTH;
- `prop.end_table` at `(2,1)`, SOUTH;
- `prop.coffee_table` at `(2,2)`, SOUTH;
- sofa at `(1,3)`, EAST;
- armchair at `(3,3)`, WEST;
- nonblocking `prop.rug` at `(5,1)` directly inside the primary front door.

The sofa, coffee table and armchair form a compact seating group rather than spanning the room. Bookshelf/end table remain beside the same cluster. The rug is a door-anchored decorative object and must not block entry movement.

### 7.5 Kitchen clusters

North-wall appliance cluster:

- stove `(12,1)`, SOUTH;
- refrigerator `(13,1)`, SOUTH;
- `prop.counter_straight` `(14,1)`, SOUTH;
- sink `(15,1)`, SOUTH.

The counter intentionally fills the fridge/sink gap rather than leaving isolated appliances.

East dining cluster:

- `prop.dining_chair` `(17,2)`, EAST;
- `prop.breakfast_table` `(18,2)`, WEST.

The chair sits directly beside the breakfast table. Local `(19,2)` remains clear as the interior approach to the east exterior door. The entire y=3 wood runner remains clear.

### 7.6 Table-facing rule

Recovered table art is authored natively toward SOUTH by System 07A presentation metadata. Candidate 004 therefore avoids NORTH-facing tables in the canonical NORTH house.

For this archetype's canonical NORTH layout, generated table-like props use only SOUTH or WEST:

- end table: SOUTH;
- coffee table: SOUTH;
- breakfast table: WEST.

House rotation still rotates these semantic facings with the building. System 19 owns semantic facing only; System 07A owns sprite/native-facing transforms.

### 7.7 Collision semantics

Candidate 004 reuses existing art semantics only.

Blocking additions used by the fixture:

- `prop.bookshelf_tall`;
- `prop.end_table`;
- `prop.counter_straight`;
- `prop.dining_chair`.

`prop.rug` is explicitly nonblocking/passable. Art remains presentation-only and does not decide collision.

## 8. Critique fixtures / live demo

### Preserved small fixture

`SmallFarmhouseCritiqueFixture.gd` preserves accepted Small Farmhouse v2 at 15×15 / 32 px per cell.

### Current live large fixture

`FarmhouseCritiqueFixture.gd` remains the large-house critique caller.

Candidate 004 configuration:

- 23×11 critique lot;
- 23 px/cell presentation;
- envelope `Rect2i(1,1,21,9)`;
- instance `building.demo.farmhouse.large.001`;
- seed `19003`;
- NORTH orientation/frontage;
- player `(6,0)` facing SOUTH toward the primary door;
- no NPCs/infected/loot;
- collision catalog includes all generated blocking prop semantics and explicitly registers the entry rug nonblocking.

Canonical WHERE remains 1m/cell. No camera subsystem is introduced for this critique.

## 9. Tactical quality / verification contract

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` must prove:

1. accepted Trailer v2 is unchanged;
2. accepted Small Farmhouse v2 remains unchanged and rotationally valid;
3. registry exposes trailer + small farmhouse + large farmhouse;
4. Large Farmhouse v4 is deterministic;
5. structure/floor geometry remains Candidate 003: 21×9, same room sizes, same 7 doors/11 windows, same divider/open passage and same clear wood runner;
6. large farmhouse emits exactly 24 props;
7. living seating and wall clutter are placed in the approved compact local cluster;
8. entry rug exists directly inside the front door and is nonblocking;
9. kitchen appliance run is stove + fridge + counter + sink with adjacent cells;
10. breakfast chair is adjacent to breakfast table and exterior-door approach stays clear;
11. all eight wood-runner cells remain prop-free;
12. canonical NORTH end/coffee/breakfast tables face SOUTH/SOUTH/WEST respectively;
13. all new prop semantics resolve through Art Catalog;
14. all blocking/passable object semantics have Collision coverage;
15. shared validator reaches every declared room from the primary door;
16. EAST rotation yields valid 9×21 geometry;
17. undersized large envelopes fail explicitly;
18. saved-small and live-large fixtures materialize into WHAT + CLOSED Door State;
19. System 18 can automatically Walk through each fixture's front door;
20. both critique views render with zero planned diagnostics;
21. canonical demo startup remains green.

Candidate 004 requires exact-final-head verification before completion is claimed.

## 10. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- no full-world scan or unbounded retry loop;
- no per-frame generation;
- validation scales with local plan size;
- no generator behavior depends on hover;
- live critique remains fully visible with existing touch controls.

## 11. Forbidden dependencies

Generation production code must not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale parcel/road planner internals or future streaming implementation.

System 07A prop-art orientation is presentation-only. System 19 supplies semantic facing but does not know native sprite transforms.

Small and large farmhouse generators are peer archetype owners and must not import or mutate one another.

## 12. Future seams / next loop

- playtest/critiqe Large Farmhouse Candidate 004;
- turn critique into `farm_large` versioned rules without touching accepted `farm_small` v2;
- preserve Trailer v2 and Small Farmhouse v2 unless explicitly reopened;
- if the clustered-dressing idea proves reusable across multiple accepted archetypes, design a dedicated shared clutter/dressing owner later rather than prematurely globalizing Candidate 004 logic;
- continue adding residential/commercial archetypes through pure-plan -> validation -> materialization;
- allow future global planning to choose small vs large farmhouse based on parcel/household facts.

## 13. Approved decisions

Approved by the user through 2026-08-17:

1. System 19 is local building generation/materialization, not global planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed.
3. Generate pure semantic plan -> validate -> materialize initial WHAT + Door State.
4. Room-purpose data is generation/validation metadata, not persistent Room State.
5. Trailer v2 is an accepted protected baseline.
6. `residential.house.farm_small` v2 is the accepted Small Farmhouse baseline.
7. Large farmhouse is a separate `residential.house.farm_large` archetype.
8. Large farmhouse requires 3 bedrooms, 2 bathrooms, and separate living/kitchen rooms.
9. Candidate 001's 25×20 L-shape + central hall is rejected as too big/hallway-heavy.
10. Candidate 002 established the compact 21×9 / no-dedicated-hall direction.
11. Candidate 003 established the current structure/floor flow: solid upper divider, lower open passage, wood runner, north-wall sink and east breakfast table.
12. Candidate 004 keeps structure unchanged and replaces stretched sparse common-room dressing with local clusters, more small props, a bookshelf, kitchen counter, breakfast chair and entry rug.
13. Candidate 004 table-like props in the canonical NORTH layout use SOUTH or WEST facing only.