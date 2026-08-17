# System 19 — Local Building Generation / Archetype Critique Lab — Implementation Changelog

Status: **IMPLEMENTED**

## Architecture

- Added pure `BuildingGenerationRequest` and semantic `GeneratedBuildingPlan` contracts.
- Added `LocalBuildingGenerator` archetype registry/coordinator.
- Added generic `GeneratedBuildingValidator` for structural validity, unique roles and circulation.
- Archetype-specific room vocabulary/dimensions are locked by focused System 19 smoke assertions rather than hard-coded into the shared validator.
- Added atomic `GeneratedBuildingMaterializer` using public WHAT + Door State contracts only.
- Materialization refuses pre-existing occupied cells and rolls back WHAT/Door State if a later write fails.
- Generator code contains no renderer/art indices, camera, loot, AI, player input or global parcel/road planning.

## Trailer Candidate 001

- Added `residential.trailer.singlewide`, version 1.
- 6×12 shell, distinct living/kitchen, bathroom and bedroom, three doors and four windows.

## Trailer Candidate 002 — accepted saved baseline

- Bumped trailer to **version 2** after user critique.
- Narrowed shell to **5×12**, usable interior width to 3 cells.
- Living/kitchen 3×4; bathroom and bedroom 3×2.
- Switched exterior to light `wall.plaster`.
- Moved sofa/loveseat against the wall opposite the kitchen run and turned it inward.
- Preserved four windows, three doors and centered circulation spine.
- User explicitly accepted/saved Candidate 002 on 2026-08-17.
- `TrailerCritiqueFixture.gd` and CI assertions remain preserved so later archetype work cannot silently change this baseline.

## Farmhouse Candidate 001

- Added new focused archetype owner `FarmhouseBuildingGenerator.gd`.
- Registered `residential.house.farm_small`, **version 1**, without changing the System 19 request/plan/materializer API.
- Canonical shell is **13×13**.
- Exact approved room program:
  - living room 5×5;
  - kitchen 3×3;
  - bedroom 1 3×3;
  - bathroom 3×3;
  - bedroom 2 3×3.
- Kept the middle band open as circulation/dining space rather than inflating requested room sizes.
- Added light plaster exterior, real interior privacy partitions, **5 total doors** and **7 windows**.
- Primary front door enters the living-room side; secondary exterior door enters the kitchen.
- Three rear private rooms each have a centered door from the circulation band.
- Furnishing pass: sofa, armchair, coffee table, stove, refrigerator, sink, two double beds, two dressers, toilet, vanity and clawfoot tub.
- Floors: laminate living/circulation, yellow linoleum kitchen, white tile bath, carpet bedrooms.
- Deterministic N/E/S/W rotation retained.

## Farmhouse critique lot

- Added `FarmhouseCritiqueFixture.gd`.
- Current live lot is fixed **15×15** at **32 px/cell**, still one-screen and still no camera.
- Farmhouse envelope `Rect2i(1,1,13,13)`, instance `building.demo.farmhouse.001`, seed `19002`, NORTH orientation/frontage.
- Player starts at `(4,0)` facing SOUTH toward the CLOSED front door.
- System 18 supplies real Walk/Run automatic passage and manual facing-required close behavior.
- `CanonicalDemoMain.gd` now consumes the fixture-provided cell presentation scale instead of hard-coding 38 px.
- Original authored fixture and Trailer v2 critique fixture remain preserved for regression/history.

## Verification

Original System 19 implementation candidate:
- SHA `c035fe7b3f5d0badab6c5b598996010e92d852b2`
- run `32005363051`: SUCCESS.

Trailer Candidate 002 first green code candidate:
- SHA `30aa8d1af7ca3d694a4085d4ec2a173a783d0dcb`
- run `32006433070`: SUCCESS.

Farmhouse Candidate 001 first green code candidate:
- SHA `65a951bc1d38c055c17cbcfcd496a59cb30727c9`
- run `32007785922`: **SUCCESS**.
- passed Godot parse, protected foundation/art/door regressions, preserved Trailer v2 assertions, exact farmhouse room-size/door/window/rotation assertions, collision/art coverage, generated front-door passage, renderer diagnostics and actual canonical startup.
