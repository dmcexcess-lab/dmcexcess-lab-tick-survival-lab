# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract with accepted Trailer v2, accepted Small Farmhouse v2, preserved Large Farmhouse Candidate 004, accepted Compact Laundry House v1, and current Small Gas Station Candidate 001**

Date: 2026-08-16; archetype critique work current through 2026-08-20.

Depends on implemented WHERE / WHAT, Art Catalog + tactical layer renderers, Door State, and System 18 Door Interaction. Future Global World Planning remains a separate higher-level owner.

## 1. Goal

Create a reusable local building generator that turns an already-chosen building/property slot into a believable physical place.

Development loop:

> generate an archetype candidate -> play/inspect it -> user critiques it -> convert critique into archetype rules -> preserve accepted versions -> add the next archetype

System 19 is not a screenshot generator and not the global world planner.

## 2. Architectural boundary

System 19 answers:

> Given a global-space envelope, orientation, frontage, archetype, stable instance namespace and seed, what physical building/property detail exists here?

It does not decide towns, roads, parcels, addresses, utilities, household/business assignment, loot, outbreak history, streaming regions, camera behavior or which property receives which building type.

A request envelope is a bounding area. Archetypes may occupy a rectangle or an irregular subset within it. A local commercial archetype may also use part of that caller-supplied envelope for immediate property fixtures that are inseparable from the business, such as a gas-station pump forecourt. This does not transfer road/parcel/world-planning ownership into System 19.

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
- `commercial.gas_station.small`

It contains no room-layout logic.

### `archetypes/TrailerBuildingGenerator.gd`
Owns the accepted single-wide trailer rules.

### `archetypes/FarmhouseBuildingGenerator.gd`
Owns only the accepted small farmhouse rules.

### `archetypes/LargeFarmhouseBuildingGenerator.gd`
Owns only `residential.house.farm_large`, including its compact three-bedroom/two-bath program and current clustered dressing.

### `archetypes/CompactLaundryHouseBuildingGenerator.gd`
Owns only the accepted `residential.house.compact_laundry` program.

### `archetypes/GasStationBuildingGenerator.gd`
Owns only `commercial.gas_station.small`: compact convenience-store shell, sales floor, office, bathroom, storage room, storefront, immediate pump forecourt and room-specific commercial dressing.

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

Different residential/commercial layouts remain peer archetypes rather than mode flags inside one giant generator.

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

## 8. Accepted Compact Laundry House baseline — v1

Archetype: `residential.house.compact_laundry`

Version: **1**.

The user accepted Candidate 001 on 2026-08-20 with:

> “ok that looks perfect.”

The implementation translates the approved image concept into the game's 1m tactical-grid language rather than attempting pixel-for-pixel architectural tracing.

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

Canonical front is SOUTH.

Doors:

- primary exterior door: local `(7,12)`;
- bedroom 1: `(4,5)`;
- laundry: `(12,2)`;
- bathroom: `(12,6)`;
- bedroom 2: `(11,9)`.

Kitchen/living intentionally use **no door**. Local `(7,5)` and `(8,5)` are a two-cell open threshold with dark-laminate floor.

Candidate 001 has **5 total doors**: one exterior + four interior.

### 8.3 Windows

Ten windows establish the visual shape and room identity: bedroom 1 north/west, two kitchen north windows, laundry north, living west/south, bathroom east and bedroom 2 east/south.

Exterior wall semantic remains `wall.plaster`; interior partitions remain `wall.interior`.

### 8.4 Kitchen/dining dressing

North wall contiguous run:

- refrigerator `(6,1)`;
- straight counter `(7,1)`;
- sink `(8,1)`;
- straight counter `(9,1)`;
- stove `(10,1)`;
- pantry `(11,1)`.

Dining cluster:

- breakfast table `(8,3)`;
- dining chair `(9,3)`.

### 8.5 Laundry/utility dressing

The dedicated 3×3 laundry room uses recovered art semantics:

- `prop.washer_front` at `(13,1)`;
- `prop.dryer_front` at `(14,1)`;
- `prop.utility_sink` at `(13,3)`;
- `prop.hamper` at `(15,3)`.

### 8.6 Living / private-room dressing

Living uses local bookshelf/TV and sofa/coffee/armchair/end-table clusters plus a passable rug. Both bedrooms and the bathroom use compact fixture/furniture groups. The entry has a small table and passable rug directly inside the front door.

### 8.7 Table-facing rule

Canonical NORTH table-like objects use SOUTH or WEST only. House rotation rotates semantic facings; System 07A remains presentation owner.

### 8.8 Prop density / collision

The accepted house emits **33 props**. Rugs are nonblocking. Furniture/appliances use fixture-local Collision Catalog registrations; art does not decide physics.

## 9. Small Gas Station Candidate 001 — current

Archetype: `commercial.gas_station.small`

Version: **1**.

User requirement: a gas station including a **bathroom, office and storage area**. Candidate 001 interprets this as a compact independent roadside convenience store, not an oversized highway travel center.

### 9.1 Canonical NORTH property plan

Bounding property envelope: **19×15** with SOUTH frontage.

The store building occupies local x=0..18, y=0..9. The immediate forecourt occupies y=10..14 and is part of this archetype's local property dressing.

Declared rooms:

- `storage`: `Rect2i(1,1,5,3)` = 15 cells, warehouse floor;
- `office`: `Rect2i(7,1,4,3)` = 12 cells, office carpet;
- `bathroom`: `Rect2i(12,1,3,3)` = 9 cells, mosaic tile;
- `sales_floor`: front `Rect2i(1,5,17,4)` plus east cooler wing `Rect2i(16,1,2,4)` = 76 connected shop-floor cells.

There is no dedicated hall/corridor. All three back rooms open directly onto the connected customer/sales area.

### 9.2 Storefront / doors / windows

Primary storefront door: local `(9,9)`, SOUTH-facing toward the forecourt.

Rear storage service exit: `(3,0)`.

Back-room doors on partition row y=4:

- storage `(3,4)`;
- office `(9,4)`;
- bathroom `(13,4)`.

Total doors: **5** — two exterior and three interior.

Windows: **10** total.

- six broad front/storefront windows;
- one office back window;
- one bathroom/back window;
- west/east side windows on the sales floor.

Front exterior uses `wall.storefront`/`window.storefront`/`door.storefront`; side/rear shell uses `wall.white_brick` with store/office opening semantics. Interior partitions remain `wall.interior`.

### 9.3 Sales-floor dressing

Candidate 001 keeps the store readable rather than filling every tile:

- checkout + adjacent counter near the front-right side;
- two compact retail shelf/endcap aisle clusters;
- three walk-in cooler fixtures in the east/rear sales wing;
- chest freezer and vending machine on the east sales side;
- wide circulation around the entrance and between the aisles/back-room doors.

### 9.4 Storage room

Storage is a real reachable room with a straight path between its sales-floor door and rear service exit.

Dressing:

- two warehouse racks;
- two pallet stacks;
- one tool cabinet.

The center/service path remains clear.

### 9.5 Office

Office is a real 4×3 room with:

- office desk;
- office chair;
- tall file cabinet;
- copier.

### 9.6 Bathroom

Bathroom is a real 3×3 room with:

- modern toilet;
- pedestal sink;
- towel rack.

The entry cell/center path remains usable.

### 9.7 Pump forecourt

The forecourt uses a concrete strip immediately outside the storefront and faded parking/asphalt farther south.

Two pump islands are represented as four real `prop.gas_pump` objects:

- left pair `(5,12)` / `(6,12)`;
- right pair `(12,12)` / `(13,12)`.

The central x=9 customer path from road/forecourt to the primary door stays clear.

Additional exterior dressing:

- gas-station sign `(1,13)`;
- public trash bin `(15,10)`;
- ice box `(16,10)`;
- vending machine `(17,10)`.

Candidate 001 emits **33 props** total across store, back rooms and forecourt.

### 9.8 Rotation / frontage

Canonical NORTH requires SOUTH frontage. EAST rotation yields a 15×19 envelope with WEST frontage. Undersized envelopes and incompatible frontage fail explicitly.

## 10. Critique fixtures / live demo

### Preserved fixtures

- `SmallFarmhouseCritiqueFixture.gd` preserves accepted Small Farmhouse v2.
- `FarmhouseCritiqueFixture.gd` preserves Large Farmhouse Candidate 004.
- `CompactLaundryHouseCritiqueFixture.gd` preserves accepted Compact Laundry House v1.

### Current live fixture

`GasStationCritiqueFixture.gd` is the current live System 19 critique caller.

Configuration:

- 21×17 critique lot;
- 24 px/cell presentation;
- envelope `Rect2i(1,1,19,15)`;
- instance `building.demo.gas_station.small.001`;
- seed `19005`;
- NORTH orientation / SOUTH frontage;
- player `(10,11)` facing NORTH toward primary door `(10,10)` in global fixture cells;
- pump islands are farther south on the property, leaving the center approach clear;
- road along the south/bottom map row, grass elsewhere;
- no NPCs/infected/loot;
- real Collision, System 18 door passage, renderer, HUD and player shell remain unchanged.

Canonical WHERE remains 1m/cell. No camera subsystem is introduced for this critique.

## 11. Tactical quality / verification contract

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` must prove:

1. accepted Trailer v2 remains unchanged;
2. accepted Small Farmhouse v2 remains unchanged and rotationally valid;
3. preserved Large Farmhouse v4 remains unchanged and rotationally valid;
4. accepted Compact Laundry House v1 remains unchanged and rotationally valid;
5. registry exposes exactly five archetypes including `commercial.gas_station.small`;
6. Gas Station v1 is deterministic;
7. canonical gas-station property footprint is 19×15;
8. gas-station room counts remain storage 15, office 12, bathroom 9, sales floor 76;
9. no gas-station hall/corridor room exists;
10. gas station has exactly 5 doors and 10 windows;
11. primary front door, rear storage service door and three back-room doors remain at approved cells;
12. forecourt concrete/apron and faded parking surfaces remain authored;
13. gas station emits exactly 33 props;
14. storage uses real warehouse racks/pallets/tool cabinet and retains a clear service path;
15. office uses real office furniture;
16. bathroom uses real bathroom fixtures;
17. sales floor uses real checkout, retail shelf/endcap, cooler/freezer/vending semantics;
18. two pump islands use four real gas-pump semantics;
19. central customer approach remains prop-free;
20. all gas-station prop/structure/ground semantics resolve through existing Art Catalog;
21. all required object semantics have Collision coverage;
22. every declared room remains reachable from the primary entrance;
23. EAST rotation yields valid 15×19 geometry with WEST frontage;
24. undersized envelopes and incompatible frontage fail explicitly;
25. preserved residential fixtures still materialize;
26. gas-station fixture materializes into WHAT + CLOSED Door State;
27. System 18 automatically Walks through the gas-station front door;
28. critique rendering has zero planned diagnostics;
29. canonical demo startup remains green;
30. exact-final-head Web export + Pages deployment remain green.

## 12. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- no full-world scan or unbounded retry loop;
- no per-frame generation;
- validation scales with local plan size;
- no generator behavior depends on hover;
- the 21×17 / 24px critique window remains within the same bounded mobile-friendly demo model used by prior fixtures.

## 13. Forbidden dependencies

Generation production code must not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale parcel/road planner internals or future streaming implementation.

System 07A prop-art orientation is presentation-only. System 19 supplies semantic facing but does not know native sprite transforms.

All five archetype generators are peer owners and must not import or mutate one another.

Gas Station generation may author pump/forecourt facts inside its supplied local property envelope, but must not invent the road network, parcel boundaries, fuel utility network, business assignment, loot or operating state.

## 14. Future seams / next loop

- playtest/critique Small Gas Station Candidate 001;
- convert critique into versioned `commercial.gas_station.small` rules without touching accepted residential archetypes;
- preserve Trailer v2, Small Farmhouse v2, Large Farmhouse v4 and accepted Compact Laundry House v1 unless explicitly reopened;
- continue adding residential/commercial archetypes through pure-plan -> validation -> materialization;
- if clustered-dressing rules prove common across several accepted archetypes, design a dedicated shared dressing owner later rather than prematurely globalizing authored rules;
- allow future global planning to choose these archetypes based on parcel/business/household facts;
- allow future container/loot systems to make shelves, coolers and storage searchable without System 19 owning inventory contents.

## 15. Approved decisions

Approved by the user through 2026-08-20:

1. System 19 is local building generation/materialization, not global planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed.
3. Generate pure semantic plan -> validate -> materialize initial WHAT + Door State.
4. Room-purpose data is generation/validation metadata, not persistent Room State.
5. Trailer v2 is an accepted protected baseline.
6. `residential.house.farm_small` v2 is the accepted Small Farmhouse baseline.
7. Large farmhouse remains a separate `residential.house.farm_large` archetype.
8. Large farmhouse compactness/no-hall/clustering lessons remain preserved in v4.
9. New examples are peer archetypes rather than overwriting saved examples.
10. Compact Laundry House v1 is accepted after the user said it “looks perfect.”
11. The accepted compact house remains protected while commercial archetypes are explored.
12. The next requested archetype is a gas station.
13. The gas station must include a real bathroom, office and storage area.
14. Candidate 001 is a compact roadside convenience-store station with a SOUTH-facing storefront and immediate pump forecourt, not an oversized travel center.
15. Storage gets a rear service exit; office/bath/storage remain real reachable rooms instead of labels on one open floor.
16. The station uses existing recovered commercial/gas-station art semantics; no new art or renderer contract is introduced for Candidate 001.
