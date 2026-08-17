# System 19 — Local Building Generation / Archetype Critique Lab — Implementation Changelog

Status: **IMPLEMENTED**

## Architecture

- Added pure `BuildingGenerationRequest` and semantic `GeneratedBuildingPlan` contracts.
- Added `LocalBuildingGenerator` archetype registry/coordinator.
- Added `GeneratedBuildingValidator` for deterministic geometry, room requirements and circulation.
- Added atomic `GeneratedBuildingMaterializer` using public WHAT + Door State contracts only.
- Materialization refuses pre-existing occupied cells and rolls back WHAT/Door State if a later write fails.
- Generator code contains no renderer/art indices, camera, loot, AI, player input or global parcel/road planning.

## Trailer Candidate 001

- Added archetype `residential.trailer.singlewide`, version 1.
- Canonical 6×12 single-wide footprint with deterministic N/E/S/W rotation.
- Distinct living/kitchen, bathroom and bedroom spaces.
- One exterior side entrance into living/kitchen.
- Two interior doors separating privacy zones.
- Four exterior windows.
- Restrained functional furniture: stove, refrigerator, sink, sofa/loveseat, toilet, vanity, single bed and dresser.
- Validator guarantees a one-cell route from exterior entrance to every room with doors conceptually open.

## Trailer Candidate 002 — user critique refinement

- Bumped `residential.trailer.singlewide` to **archetype version 2** because the same request/seed intentionally produces different geometry.
- Narrowed the canonical shell from 6×12 to **5×12 exterior cells**, reducing usable interior width from 4 cells to **3 cells** while preserving trailer length and room sequence.
- Living/kitchen is now 3×4; bathroom and bedroom are each 3×2.
- Recentered both interior doors on the middle interior column so the narrower plan preserves a straight one-cell circulation spine.
- Replaced brown `wall.rural_wood` exterior shell tiles with light neutral `wall.plaster` semantics; preserved the existing light `wall.interior` partitions.
- Moved the sofa/loveseat from the kitchen-side area to the interior cell against the wall opposite the kitchen run and turned it inward toward the room.
- Preserved the four-window count, three real doors, functional room split, and restrained fixture set.
- Updated the critique fixture to a 5×12 envelope and moved the player spawn one cell westward so the survivor still begins immediately outside the CLOSED side entrance facing it.
- Extended System 19 smoke coverage to lock the 5×12 footprint, archetype version 2, light plaster shell, opposite-wall sofa placement, rotated 12×5 geometry and new generated-door entry cell.

## Live critique lot

- Added `TrailerCritiqueFixture.gd` as the live 13×13 one-screen showcase caller.
- Candidate instance remains `building.demo.trailer.001`, seed `19001`, NORTH orientation / EAST frontage; the current generated content is archetype v2 / **Trailer Candidate 002**.
- Player starts outside the CLOSED side entrance facing the door.
- System 18 supplies real Walk/Run automatic door passage and manual close behavior.
- The original authored `CanonicalDemoFixture.gd` remains unchanged for regression coverage.
- Camera/streaming remain deferred until multiple properties require more than one screen.

## Verification

First fully green System 19 implementation candidate:

- SHA `c035fe7b3f5d0badab6c5b598996010e92d852b2`
- Local Building Generation workflow run `32005363051`: **SUCCESS**

First fully green Trailer Candidate 002 code candidate:

- SHA `30aa8d1af7ca3d694a4085d4ec2a173a783d0dcb`
- Local Building Generation workflow run `32006433070`: **SUCCESS**
- passed Godot parse, foundation/presentation regressions, Systems 18+19 integration smokes, deterministic 5×12 generation/rotation, light-shell and sofa-placement assertions, generated-door passage, and actual canonical demo startup.
