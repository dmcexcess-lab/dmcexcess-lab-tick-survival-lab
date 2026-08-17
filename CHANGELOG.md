# Changelog

## System 19 Large Farmhouse Candidate 002 — 2026-08-17

- Rejected Large Farmhouse Candidate 001 after playtest feedback: **too big and too hallway-heavy**.
- Preserved accepted Trailer v2 and accepted Small Farmhouse v2 unchanged.
- Bumped `residential.house.farm_large` to archetype version 2.
- Rebuilt the large farmhouse from 25×20 down to **21×9**, matching the accepted small farmhouse's depth instead of scaling every room up.
- Removed the dedicated central hall entirely. The primary exterior door now enters the living room directly, and all five private rooms open directly from living/kitchen through one partition row.
- Kept the required separate common rooms: living is **10×3**, kitchen is **8×3**, separated by real wall structure and `door.interior.living_kitchen`.
- Kept all private rooms compact: three **3×3 bedrooms** and two **3×3 bathrooms**.
- Candidate 002 has two exterior doors, six interior doors and eleven windows.
- Retained existing recovered prop semantics and System 07A facing-aware furniture orientation; no renderer/art/collision contract changed.
- Reduced the live critique lot to **23×11 at 23 px/cell**, improving readability without adding a camera subsystem.
- Updated System 19 focused CI to lock the compact room dimensions, zero dedicated hallway room records, direct private-door row, deterministic rotation, materialization, Door State, Collision/Art coverage, renderer diagnostics and canonical startup.
- The previous L-shaped Candidate 001 remains historical only; compactness now takes precedence over irregular-shape complexity for the large-house critique loop.

## System 19 Large Farmhouse Candidate 001 — 2026-08-17

- Promoted the accepted compact farmhouse to the protected **Small Farmhouse** baseline after the user explicitly said: “Nice save that as small farm house.”
- Preserved `residential.house.farm_small` at archetype version 2 with its exact 13×9 geometry, 11×3 open living/kitchen, two bedrooms, one bathroom, five doors and seven windows.
- Added the peer archetype `residential.house.farm_large` with standalone owner `LargeFarmhouseBuildingGenerator.gd`.
- Candidate 001 used a 25×20 L-shaped occupied building with 3 bedrooms, 2 bathrooms, separate living/kitchen and a central hall.
- Candidate 001 first-green code was `a533f4f27de6f37b92b5e8472bb4b81220b2e06e`; Local Building Generation run `32011785845` passed. It is now superseded by Candidate 002 after playtest critique.

## Earlier project changelog

The full prior changelog is preserved verbatim in `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md`. Git history also retains every earlier version of this file.
