# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract with accepted Trailer v2, accepted Small Farmhouse v2, preserved Large Farmhouse Candidate 004, and current Compact Laundry House Candidate 001**

Date: 2026-08-16; archetype critique work current through 2026-08-17.

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

A request envelope is a bounding area. Archetypes may occupy a rectangle or an irregular subset within it. Geometry should be only as complex as the building needs.

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
- `residential.house.compact_laundry`

It contains no room-layout logic.

### `archetypes/TrailerBuildingGenerator.gd`
Owns the accepted single-wide trailer rules.

### `archetypes/FarmhouseBuildingGenerator.gd`
Owns only the accepted small farmhouse rules.

### `archetypes/LargeFarmhouseBuildingGenerator.gd`
Owns only `residential.house.farm_large`, including its compact three-bedroom/two-bath program and current clustered dressing.

### `archetypes/CompactLaundryHouseBuildingGenerator.gd`
Owns only `residential.house.compact_laundry`, including its irregular two-bedroom/one-bath plan, separate kitchen, central living circulation, small entry and dedicated laundry/utility room.

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

Different residential layouts remain peer archetypes rather than size/mode flags inside one giant house generator.

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

## 7. Large Farmhouse Candidate 004 — preserved

Archetype: `residential.house.farm_large`

Version: **4**.

The preserved large-house candidate remains unchanged by Compact Laundry House work.

### 7.1 Historical critique path

Candidate 001 used a 25×20 L-shaped footprint with large rooms and a central hall and was rejected as too large/hallway-heavy.

Candidate 002 established the density direction: 21×9 shell, 10×3 living room, 8×3 kitchen, three 3×3 bedrooms, two 3×3 bathrooms and no hall/corridor room.

Candidate 003 kept that structure while replacing the living/kitchen door with upper divider wall + lower open passage, converting the kitchen bottom row to a clutter-free wood runner, moving the sink to the north wall and adding a breakfast table near the east wall.

Candidate 004 kept all Candidate 003 structure/floor geometry and changed only common-room prop placement/orientation/density.

### 7.2 Preserved structure and dressing

- 21×9 shell;
- separate 10×3 living room and 8×3 kitchen;
- three 3×3 bedrooms and two 3×3 bathrooms;
- 7 total doors and 11 windows;
- no dedicated hallway/corridor room;
- upper living/kitchen divider remains wall, lower divider remains open;
- kitchen y=3 wood runner remains prop-free;
- living furniture uses compact local clustering;
- kitchen appliance run remains stove + refrigerator + counter + sink;
- breakfast table + chair remain near east wall;
- canonical NORTH table-like props use SOUTH/WEST facings.

## 8. Compact Laundry House Candidate 001 — current

Archetype: `residential.house.compact_laundry`

Version: **1**.

The user approved building the same overall house concept as the generated visual reference: two bedrooms, one bathroom, separate kitchen/dining, central living room, a small front-entry projection, and especially a distinct little laundry/utility room. The implementation translates that image into the game's 1m tactical-grid language rather than attempting pixel-for-pixel architectural tracing.

### 8.1 Canonical NORTH bounding plan

Bounding envelope: **17×13**.

The occupied house is deliberately irregular inside that bounding rectangle:

- top-left bedroom wing;
- top-center kitchen;
- top-right laundry projection;
- mid-right bathroom;
- central/lower living room;
- bottom-right bedroom;
- small south/front entry bump.

There is **no dedicated hall/corridor room**. Living is the circulation hub, and kitchen/living share a two-cell doorless opening.

Room-purpose ground regions:

- `bedroom_1`: local `Rect2i(1,1,4,4)` = 16 cells, beige carpet;
- `kitchen`: `Rect2i(6,1,6,4)` = 24 cells, white tile;
- `laundry`: `Rect2i(13,1,3,3)` = 9 cells, dark laminate;
- `bathroom`: `Rect2i(13,5,3,3)` = 9 cells, mosaic tile;
- `living_room`: `Rect2i(4,6,8,2)` + `Rect2i(4,8,7,3)` = 37 cells, dark laminate;
- `entry`: `Rect2i(6,11,3,1)` = 3 cells, dark laminate;
- `bedroom_2`: `Rect2i(12,9,4,3)` = 12 cells, blue carpet.

Door/passage threshold ground is explicitly authored so connectivity remains physical and readable.

### 8.2 Openings and frontage

The image-inspired canonical front is SOUTH.

Canonical NORTH request therefore requires `frontage_side = SOUTH`; orientation rotates that frontage along with the plan.

Doors:

- primary exterior door: local `(7,12)`, SOUTH-facing, on the entry bump;
- bedroom 1: `(4,5)`;
- laundry: `(12,2)`;
- bathroom: `(12,6)`;
- bedroom 2: `(11,9)`.

Kitchen/living intentionally use **no door**. Local `(7,5)` and `(8,5)` are a two-cell open threshold with dark-laminate floor.

Candidate 001 has **5 total doors**: one exterior + four interior.

### 8.3 Windows

Ten house windows establish the visual shape and room identity:

- bedroom 1 north + west;
- two kitchen north windows;
- laundry north;
- living west + south;
- bathroom east;
- bedroom 2 east + south.

Exterior wall semantic remains `wall.plaster`; interior partitions remain `wall.interior`.

### 8.4 Kitchen/dining dressing

The kitchen follows the compact cluster lesson instead of scattering appliances:

North wall, contiguous:

- refrigerator `(6,1)`, SOUTH;
- straight counter `(7,1)`, SOUTH;
- sink `(8,1)`, SOUTH;
- straight counter `(9,1)`, SOUTH;
- stove `(10,1)`, SOUTH;
- pantry `(11,1)`, SOUTH.

Dining cluster:

- breakfast table `(8,3)`, SOUTH;
- dining chair `(9,3)`, WEST.

The two-cell south opening to living remains clear.

### 8.5 Laundry/utility dressing

The dedicated 3×3 laundry room is not a fake label. It uses recovered art semantics already supported by the Art Catalog:

- `prop.washer_front` at `(13,1)`, SOUTH;
- `prop.dryer_front` at `(14,1)`, SOUTH;
- `prop.utility_sink` at `(13,3)`, NORTH;
- `prop.hamper` at `(15,3)`, WEST.

The center of the room stays open enough to enter and use as circulation space.

### 8.6 Living-room dressing

The living room keeps several local clusters rather than stretching a few props across the entire irregular room:

- bookshelf `(4,7)` along west side;
- TV stand `(4,9)` on the same side;
- sofa `(9,8)`;
- coffee table `(7,8)`;
- armchair `(8,10)`;
- end table `(9,9)`;
- passable rug `(7,9)`.

The entry, kitchen opening, bathroom door and bedroom 2 approach remain open.

### 8.7 Bedroom / bath / entry dressing

Bedroom 1:

- single bed;
- nightstand;
- wardrobe;
- passable rug.

Bathroom:

- toilet;
- vanity;
- shower stall;
- passable rug.

Bedroom 2:

- double bed;
- dresser;
- nightstand;
- passable rug.

Entry:

- small end table;
- passable rug directly inside the primary front door.

### 8.8 Table-facing rule carried forward

The earlier large-house critique established that recovered table sprites look wrong when authored NORTH in the canonical view.

Candidate 001 therefore keeps all table-like objects in the canonical NORTH plan facing only SOUTH or WEST:

- bedroom 1 nightstand: SOUTH;
- kitchen breakfast table: SOUTH;
- living coffee table: WEST;
- living end table: WEST;
- bedroom 2 nightstand: WEST;
- entry table: WEST.

House rotation rotates these semantic facings. System 07A remains the presentation owner for sprite-native orientation.

### 8.9 Prop density / collision

Candidate 001 emits **33 props**.

Density is intentionally higher than the farmhouse examples because the reference house is more lived-in, but circulation wins over decorative filling.

Rugs are explicitly nonblocking. Furniture/appliances use fixture-local Collision Catalog registrations; art does not decide physics.

## 9. Critique fixtures / live demo

### Preserved fixtures

- `SmallFarmhouseCritiqueFixture.gd` preserves accepted Small Farmhouse v2.
- `FarmhouseCritiqueFixture.gd` preserves Large Farmhouse Candidate 004.

### Current live fixture

`CompactLaundryHouseCritiqueFixture.gd` is the current live System 19 critique caller.

Configuration:

- 19×15 critique lot;
- 26 px/cell presentation;
- envelope `Rect2i(1,1,17,13)`;
- instance `building.demo.house.compact_laundry.001`;
- seed `19004`;
- NORTH orientation / SOUTH frontage;
- player `(8,14)` facing NORTH toward primary door `(8,13)` in global fixture cells;
- road along the south/bottom map row, grass elsewhere;
- no NPCs/infected/loot;
- real Collision, System 18 door passage, renderer, HUD and player shell remain unchanged.

Canonical WHERE remains 1m/cell. No camera subsystem is introduced for this critique.

## 10. Tactical quality / verification contract

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` must prove:

1. accepted Trailer v2 remains unchanged;
2. accepted Small Farmhouse v2 remains unchanged and rotationally valid;
3. preserved Large Farmhouse v4 remains unchanged and rotationally valid;
4. registry exposes all four archetypes;
5. Compact Laundry House v1 is deterministic;
6. canonical bounding footprint is 17×13;
7. room counts remain bedroom1 16, kitchen 24, laundry 9, bathroom 9, living 37, entry 3, bedroom2 12;
8. no hall/corridor room exists;
9. house has exactly 5 doors and 10 windows;
10. front door remains on south entry bump;
11. kitchen/living two-cell opening remains doorless and wood-thresholded;
12. laundry contains real washer + dryer + utility sink + hamper semantics;
13. kitchen keeps its contiguous appliance/counter run and adjacent table/chair cluster;
14. entry rug is directly inside the front door and nonblocking;
15. living sofa/coffee/end-table remain locally clustered;
16. canonical table-like props use only SOUTH/WEST facings;
17. all prop semantics resolve through Art Catalog;
18. all blocking/passable object semantics have Collision coverage;
19. every declared room remains reachable from primary entrance;
20. EAST rotation yields valid 13×17 geometry with WEST frontage;
21. undersized envelopes and incompatible frontage fail explicitly;
22. preserved small/large fixtures still materialize;
23. new compact-laundry fixture materializes into WHAT + CLOSED Door State;
24. System 18 automatically Walks through its front door;
25. critique rendering has zero planned diagnostics;
26. canonical demo startup remains green;
27. exact-final-head Web export + Pages deployment remain green.

## 11. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- no full-world scan or unbounded retry loop;
- no per-frame generation;
- validation scales with local plan size;
- no generator behavior depends on hover;
- the 19×15 / 26px critique window remains within the same bounded mobile-friendly demo model used by prior fixtures.

## 12. Forbidden dependencies

Generation production code must not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale parcel/road planner internals or future streaming implementation.

System 07A prop-art orientation is presentation-only. System 19 supplies semantic facing but does not know native sprite transforms.

All four archetype generators are peer owners and must not import or mutate one another.

## 13. Future seams / next loop

- playtest/critique Compact Laundry House Candidate 001;
- convert critique into versioned `compact_laundry` rules without touching existing archetypes;
- preserve Trailer v2 and Small Farmhouse v2 unless explicitly reopened;
- preserve Large Farmhouse v4 while the new-house critique loop is active;
- if clustered-dressing rules prove common across several accepted archetypes, design a dedicated shared dressing owner later rather than prematurely globalizing authored house rules;
- continue adding residential/commercial archetypes through pure-plan -> validation -> materialization;
- allow future global planning to choose among these archetypes based on parcel/household facts.

## 14. Approved decisions

Approved by the user through 2026-08-17:

1. System 19 is local building generation/materialization, not global planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed.
3. Generate pure semantic plan -> validate -> materialize initial WHAT + Door State.
4. Room-purpose data is generation/validation metadata, not persistent Room State.
5. Trailer v2 is an accepted protected baseline.
6. `residential.house.farm_small` v2 is the accepted Small Farmhouse baseline.
7. Large farmhouse remains a separate `residential.house.farm_large` archetype.
8. Large farmhouse compactness/no-hall/clustering lessons remain preserved in v4.
9. New residential examples should be built as peer archetypes rather than overwriting saved examples.
10. Compact Laundry House is a new peer archetype based on the approved image concept.
11. Its program is 2 bedrooms, 1 bathroom, separate kitchen/dining, central living room, small entry and distinct little laundry/utility room.
12. The image concept should be translated into compact game-grid geometry, not reproduced as an oversized literal floor plan.
13. The new house keeps circulation compact, avoids dedicated hall inflation, uses local clutter clusters and carries forward the SOUTH/WEST table-facing rule.
14. Existing Trailer v2, Small Farmhouse v2 and Large Farmhouse v4 must remain unchanged during this new-house implementation.
