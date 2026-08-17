# Changelog

## System 19 Large Farmhouse Candidate 001 — 2026-08-17

- Promoted the accepted compact farmhouse to the protected **Small Farmhouse** baseline after the user explicitly said: “Nice save that as small farm house.”
- Preserved `residential.house.farm_small` at archetype version 2 with its exact 13×9 geometry, 11×3 open living/kitchen, two bedrooms, one bathroom, five doors and seven windows. The small generator itself was not modified by large-house work.
- Added `SmallFarmhouseCritiqueFixture.gd` so the accepted small-house critique setup remains independently materializable/tested after the live demo moves on.
- Added the new peer archetype `residential.house.farm_large` with standalone owner `LargeFarmhouseBuildingGenerator.gd`; `LocalBuildingGenerator` now routes trailer, small farmhouse and large farmhouse without owning room-layout logic.
- Implemented **Large Farmhouse Candidate 001** as a genuine L-shaped occupied building inside a 25×20 NORTH bounding footprint: a 19×20 main body plus a 6×8 front-right kitchen wing, with the southeast notch remaining outdoor ground.
- Added the requested **3 bedrooms / 2 bathrooms** with separate room-purpose records and real partition geometry.
- Living room is a separate 6×5 room behind its own wall/door; kitchen is a separate 5×5 room in the wing behind its own wall/door rather than an open-plan floor-color zone.
- Added a central hall so all seven declared rooms are reachable without using another declared room as circulation.
- Candidate 001 has two exterior doors, seven interior doors and twelve windows. Furnishings reuse existing recovered semantic art/collision vocabulary and System 07A N/E/S/W orientation.
- Moved the live farmhouse critique to a 27×22 visible lot at 19 px/cell so the full large candidate can be playtested without prematurely adding a camera subsystem; canonical WHERE remains 1m/cell.
- Expanded `LocalBuildingGenerationSmoke.gd` to protect Trailer v2, the accepted Small Farmhouse v2, the new large archetype, its non-rectangular notch, deterministic EAST rotation, room dimensions, materialization, CLOSED Door State, Collision/Art coverage, System 18 front-door traversal and zero renderer diagnostics for both small and large fixtures.
- First green large-house code candidate: `a533f4f27de6f37b92b5e8472bb4b81220b2e06e`; Local Building Generation run `32011785845` passed source boundaries, Godot 4.7.1 parse, foundation/presentation regressions, Systems 18/19 integration and canonical startup.

## Earlier project changelog

The full prior changelog is preserved verbatim in `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md`. Git history also retains every earlier version of this file.
