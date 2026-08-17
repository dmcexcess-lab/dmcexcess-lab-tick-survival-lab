# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract, accepted Trailer v2 baseline, Farmhouse Candidate 001 and dedicated CI present 2026-08-17**

Date: 2026-08-16; current archetype extension approved 2026-08-17.

Depends on implemented WHERE / WHAT, Art Catalog + tactical layer renderers, Door State, and System 18 Door Interaction. Future Global World Planning remains a separate higher-level owner.

## 1. Goal

Create a reusable local building generator that turns an already-chosen building slot into a believable physical building.

Development loop:

> generate an archetype candidate -> play/inspect it -> user critiques it -> convert critique into archetype rules -> preserve accepted versions -> add the next archetype

System 19 is not a screenshot generator and not the global world planner.

## 2. Architectural boundary

System 19 answers:

> Given a global-space envelope, orientation, frontage, archetype, stable instance namespace and seed, what physical building exists here?

It does **not** decide towns, roads, parcels, addresses, utilities, household occupants, loot, outbreak history, streaming regions, camera behavior or which property receives which building type.

Global planning supplies those higher-level facts first. System 19 never scans the world for a convenient place to build.

## 3. Implemented owners

### `BuildingGenerationRequest.gd`
Pure request facts: instance namespace, archetype ID, seed, global envelope, N/E/S/W orientation and caller-selected frontage.

### `GeneratedBuildingPlan.gd`
Pure semantic result: used footprint, ground, structures, props, generation-only room-purpose regions, deterministic roles, version and seed provenance.

### `LocalBuildingGenerator.gd`
Registry/coordinator only. It currently routes:

- `residential.trailer.singlewide`
- `residential.house.farm_small`

It contains no room-layout logic.

### `archetypes/TrailerBuildingGenerator.gd`
Owns the accepted single-wide trailer rules.

### `archetypes/FarmhouseBuildingGenerator.gd`
Owns only the small farmhouse rules.

### `GeneratedBuildingValidator.gd`
Shared structural validator. It verifies:

- footprint containment;
- deterministic unique roles;
- legal structure axes;
- no structure/prop contradictions;
- valid non-empty room-purpose records;
- exactly one `door.exterior.primary`;
- no blocking furniture on doors;
- one-cell circulation from the primary entrance to every declared room with doors conceptually passable.

The shared validator intentionally does **not** hard-code trailer-specific room names. Each archetype's dedicated CI assertions lock its required room program and dimensions. This keeps the validator reusable for houses, stores and later building families.

### `GeneratedBuildingMaterializer.gd`
Consumes a validated plan and public initial-state contracts only. It writes initial WHAT terrain/entities/placements, explicitly enrolls generated doors CLOSED in 06A, refuses unrelated occupied cells, and restores WHAT + Door State if a later materialization write fails.

After materialization, generator ownership ends; persistent gameplay truth owns later mutations.

## 4. Determinism / identity

Same archetype version + request + seed must produce the same semantic plan/signature.

Child IDs derive from caller instance namespace + deterministic role, not insertion order or Node identity.

When critique intentionally changes same-seed geometry, bump that archetype version rather than silently changing an existing version.

## 5. Accepted Trailer baseline — Candidate 002

Archetype: `residential.trailer.singlewide`

Version: **2**.

The user explicitly accepted Candidate 002 as the saved trailer baseline on 2026-08-17. Preserve its rules unless a later explicit trailer revision supersedes it.

Canonical NORTH geometry:

- **5×12 exterior shell**;
- 3×4 living/kitchen;
- 3×2 bathroom;
- 3×2 bedroom;
- light `wall.plaster` exterior and `wall.interior` partitions;
- one exterior side door + two centered interior doors;
- four windows;
- stove/fridge/sink on one side;
- sofa/loveseat against the opposite wall facing inward;
- toilet, vanity, single bed, dresser;
- middle-column circulation spine.

`TrailerCritiqueFixture.gd` remains preserved as a regression/showcase fixture even though it is no longer the live boot target.

## 6. Farmhouse Candidate 001 — implemented geometry

Archetype: `residential.house.farm_small`

Version: **1**.

Approved user program:

- living room **5×5**;
- kitchen **3×3**;
- bedroom 1 **3×3**;
- bedroom 2 **3×3**;
- bathroom **3×3**.

### Canonical shell / layout

- **13×13 exterior shell**;
- light `wall.plaster` exterior;
- living room occupies the front-left 5×5 zone;
- kitchen occupies the front-right 3×3 zone;
- middle cells remain an open entry/circulation/dining band rather than inflating any requested room;
- rear private band contains bedroom 1, bathroom, bedroom 2 as three separate 3×3 rooms;
- private rooms use real `wall.interior` partitions and one centered door each.

### Doors

Exactly five V1 doors:

1. primary front `door.house` entering the living-room side;
2. secondary side `door.house` entering the kitchen;
3. bedroom 1 door;
4. bathroom door;
5. bedroom 2 door.

System 18 owns runtime opening/closing; generated doors begin CLOSED.

### Windows

Seven V1 `window.house` openings:

- three living-room windows;
- one kitchen window;
- one window for each bedroom;
- one bathroom window.

### Floors

- living + open circulation: `ground.laminate_light`;
- kitchen: `ground.linoleum_yellow`;
- bathroom: `ground.tile_white`;
- bedroom 1: `ground.carpet_beige`;
- bedroom 2: deterministic beige/blue carpet variation.

### Furnishing

Restrained first-pass set:

- living: sofa, armchair, coffee table;
- kitchen: stove, refrigerator, sink;
- bedroom 1: double bed + dresser;
- bedroom 2: double bed + dresser;
- bathroom: toilet, vanity, clawfoot tub.

Furniture placement preserves a one-cell path from the front entrance through the house to every private-room door.

## 7. Live critique integration

`FarmhouseCritiqueFixture.gd` is the current live critique caller.

- fixed **15×15** one-screen lot;
- presentation uses **32 px/cell** so no camera is required;
- authoritative spatial scale remains the canonical 1m tactical cell;
- farmhouse envelope: `Rect2i(1, 1, 13, 13)`;
- instance: `building.demo.farmhouse.001`;
- seed: `19002`;
- orientation NORTH / frontage NORTH;
- player starts at `(4,0)` facing SOUTH toward the CLOSED primary front door;
- no NPCs/infected/loot.

The 15×15 critique lot is a presentation/test caller only, not a new streaming/world-size rule.

`CanonicalDemoFixture.gd` and `TrailerCritiqueFixture.gd` remain preserved for their regression roles.

## 8. Tactical quality rules

A valid generated building must be playable, not merely recognizable in a static image.

Shared validation ensures:

- each declared room has ground cells;
- every declared room is reachable from the primary exterior door with doors treated open;
- no required route relies on a blocking prop cell;
- no wall/door/window duplicate structure cell;
- no blocking prop occupies a structure/door cell;
- rotation stays deterministic/legal;
- materialization does not delete unrelated persistent facts.

Archetype CI additionally locks each building's required room program, dimensions and content counts.

## 9. Verified acceptance

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` now prove:

1. Trailer v2 remains deterministic, 5×12, correctly room-sized, light-walled and keeps the accepted opposite-wall sofa placement;
2. the registry exposes both trailer and farmhouse archetypes;
3. Farmhouse v1 is deterministic and uses the exact approved 13×13 shell;
4. farmhouse room sizes are exactly 25 / 9 / 9 / 9 / 9 cells for living, kitchen, bedroom 1, bathroom, bedroom 2;
5. farmhouse has exactly five doors and seven windows;
6. farmhouse light shell, primary front door and side kitchen door are locked by contract;
7. rotated farmhouse geometry remains deterministic and validates;
8. too-small farmhouse requests fail explicitly;
9. farmhouse materializes into canonical WHAT with five CLOSED Door State entries;
10. all generated blocking semantics have Collision coverage;
11. all generated ground/wall/door/window/prop semantics resolve through current Art Catalog;
12. System 18 can automatically Walk through the generated farmhouse front door;
13. fixed 15×15 / 32px critique rendering produces no diagnostics;
14. foundation/art/door regressions and actual canonical demo startup remain green.

Farmhouse Candidate 001 first green code candidate:

- SHA `65a951bc1d38c055c17cbcfcd496a59cb30727c9`
- Local Building Generation run `32007785922`: **SUCCESS**

## 10. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- no full-world scan;
- no per-frame generation;
- no unbounded random retry loop;
- validation scales with local plan size;
- no generator behavior depends on desktop-only hover;
- live critique remains playable through existing mobile controls + System 18 touch door interaction.

## 11. Forbidden dependencies

Generation production code must not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale parcel/road planner internals or future streaming implementation.

## 12. Future seams / next loop

After Farmhouse Candidate 001 critique:

- refine the farmhouse only if critique identifies reusable farmhouse rules;
- keep accepted Trailer v2 unchanged;
- add further residential/commercial archetypes under the same contract;
- camera/larger local play space remains deferred until multiple simultaneous properties create an actual need beyond the one-screen critique lot.

Potential later archetypes include ranch variants, duplexes, apartments, gas stations, convenience stores, retail, offices, warehouses, cabins, sheds and outbuildings.

## 13. Approved decisions

Approved by the user through 2026-08-17:

1. System 19 is local building generation/materialization, not global planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed.
3. Generate pure semantic plan -> validate -> materialize initial WHAT + Door State.
4. Room-purpose data is generation/validation metadata, not a persistent Room State domain.
5. Trailer v2 Candidate 002 is the accepted saved trailer baseline.
6. Farmhouse archetype is `residential.house.farm_small`.
7. Farmhouse uses a 13×13 shell with exact 5×5 living room and 3×3 kitchen, two bedrooms and bathroom.
8. Front half is living/kitchen with open circulation; rear private band holds the three 3×3 rooms.
9. Farmhouse uses light walls, two exterior doors, three private-room doors and a seven-window first-pass set.
10. Farmhouse critique stays one-screen via a 15×15 view at 32 px/cell; camera remains deferred.
