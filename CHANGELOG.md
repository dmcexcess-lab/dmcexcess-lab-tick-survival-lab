# Changelog

## System 19 Rural Diner v2 + DEV New Building Cycle — 2026-08-20

- Responded to the first deployed diner review: the user called it **“very good”** and asked for a few more tables plus a button that renders another building from the rule set.
- Bumped `commercial.diner.rural_small` from v1 to **v2** because same-seed generated dressing intentionally changed.
- Increased the dining room from four to **six booth/table pairs** by adding one middle cluster on each side wall. Total diner props rise from 26 to **30** while the center customer aisle, service-room approaches and storage lane remain clear.
- Expanded the profile from two to **four legal back-of-house room orders**. Seeds 19006 and 19007 preserve the already-reviewed layouts; 19008 and 19009 expose the two additional valid arrangements. The far-east kitchen permutation remains excluded because its customer-counter cluster would collide with east-wall seating.
- Added explicit DEV-only `BuildingGrammarDevSeedSession.gd` and `BuildingGrammarDevControls.gd` owners. A phone-friendly **NEW BUILDING** button now fills the unused center slot between TURN L and TURN R.
- Pressing NEW BUILDING advances the integer seed and reloads the critique scene so the normal System 19 request → grammar → validation → materialization path runs cleanly from scratch. It never rewrites an already-materialized WHAT world in place.
- Web builds carry the critique seed through a `building_seed` URL query parameter; native builds use a runtime `ProjectSettings` override across scene reloads. This is DEV critique tooling only and does not become a production world-generation mechanic.
- `CanonicalDemoMain.gd` remains unchanged and composition-only; the DEV control is wired as its own CanvasLayer in `game/main.tscn`.
- Expanded `BuildingGrammarSmoke.gd` to lock diner v2, 30 props, all six table/booth clusters, four legal sequential seed layouts, DEV seed override/default behavior, 32-seed × four-rotation grammar torture coverage, fixture materialization, System 18 entry and renderer diagnostics.
- Added the DEV owners to the System 19 CI boundary checks and updated System 19 design/context/approval routing notes.
- Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1 and Small Gas Station v1 remain untouched.

## System 19 Building Grammar Hardening — Trial 001 Rural Diner — 2026-08-20

- Promoted `commercial.gas_station.small` v1 to the protected fifth reference example after the user accepted it with “perfect.” Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1 and Small Gas Station v1 remain unchanged during grammar hardening.
- Extracted the recurring critique lessons into explicit shared rules rather than copying exact room dimensions or prop counts: compact purposeful space, meaningful circulation, functional primary entry, real/reachable required rooms, clear doorway/service approaches, local functional clustering, contiguous work runs, deliberate open space, bounded blocking-prop density, frontage/orientation correctness and deterministic seeded variation.
- Added `BuildingArchetypePlacementDescriptor.gd` and `LocalBuildingGenerator.placement_descriptor()` / `placement_descriptors()` as the narrow read-only System 20 seam. Placement facts are derived by probing each archetype's own public generation behavior, so System 20 does not maintain a duplicate size/frontage table.
- Added reusable grammar owners: `BuildingGrammarProfile.gd`, `BuildingGrammarGenerator.gd`, `BuildingRoomDressingPlanner.gd` and `BuildingGrammarQualityValidator.gd`. Generic physical validation remains separate from profile-specific building-quality rules.
- Added the first grammar-driven proof archetype, `commercial.diner.rural_small` v1, through a thin profile/wrapper rather than a hand-authored cell-by-cell diner generator.
- Rural Diner Trial 001 uses a compact **17×11** SOUTH-frontage shell with a **15×5 dining/public hub**, **7×3 kitchen**, **3×3 storage**, **3×3 bathroom**, no dedicated hall/corridor, **5 doors**, **11 windows** and **26 purposeful props**.
- Diner dressing hardens four booth/table clusters, a compact customer-counter group, a contiguous seven-cell kitchen work line, wall-hugging storage clutter with a protected middle service lane, and a compact bathroom fixture group while leaving the central customer aisle open.
- Added deterministic topology variation: seed 19006 orders kitchen → storage → bathroom; seed 19007 orders bathroom → kitchen → storage. The rear service exit follows the storage room instead of remaining hard-coded.
- Added `RuralDinerCritiqueFixture.gd` and switched the canonical demo composition to the diner for playtest. Existing HUD, movement, System 18 door passage, collision and render systems are reused unchanged.
- Added `BuildingGrammarSmoke.gd` to verify placement descriptors for all six callable archetypes, exact Trial 001 structure/dressing, alternate-seed topology, undersized/frontage failures, **32 consecutive seeds × all four cardinal rotations**, materialization, CLOSED initial doors, collision/art coverage, System 18 automatic entry and zero renderer diagnostics.
- Updated the existing System 19 regression smoke only for the registry count; all saved-example geometry/content assertions remain intact.
- Trial 001 is now the first of the two agreed hardening proofs. It is ready for user playtest/acceptance; System 19 is not finalized until a second unrelated grammar-generated building is also accepted.

## System 19 Small Gas Station Candidate 001 — 2026-08-20

- Promoted Compact Laundry House Candidate 001 / `residential.house.compact_laundry` v1 to an accepted protected baseline after the user said: “ok that looks perfect.”
- Added the new peer commercial archetype `commercial.gas_station.small` at version 1 without modifying Trailer v2, Small Farmhouse v2, Large Farmhouse v4 or Compact Laundry House v1.
- Built a compact **19×15 property envelope** containing a small roadside convenience-store building plus its immediate pump forecourt rather than an oversized highway travel center.
- Implemented the requested back-of-house program as real reachable rooms: **5×3 storage**, **4×3 office**, and **3×3 bathroom**, all opening directly onto a connected 76-cell sales floor with no dedicated hallway.
- Added five doors: primary storefront entrance, rear storage/service exit, and dedicated storage/office/bathroom interior doors. Ten storefront/side/back windows establish the commercial shell.
- Used commercial room/property surfaces: shop floor, warehouse floor, office carpet, mosaic bathroom tile, concrete storefront apron and faded parking/forecourt pavement.
- Added **33 purposeful props** using existing recovered art: checkout/counter, two compact retail shelf/endcap clusters, walk-in coolers, freezer, vending, office furniture, bathroom fixtures, warehouse racks/pallets/tool cabinet and exterior convenience-store dressing.
- Added four real `prop.gas_pump` objects as two pump islands, plus `prop.gas_sign`, exterior ice box, vending machine and trash bin while keeping the central customer path from road/forecourt to storefront clear.
- Added `GasStationCritiqueFixture.gd`: 21×17 lot, 24 px/cell, seed 19005, NORTH orientation / SOUTH frontage, player starting one cell south of the closed storefront door.
- Registered the fifth archetype in `LocalBuildingGenerator.gd` and switched the canonical demo fixture preload to the gas station while keeping `CanonicalDemoMain.gd` composition-only.
- Expanded System 19 CI to protect all four previous archetypes and lock gas-station room sizes, doors/windows, commercial semantics, pump islands, clear circulation, rotation/frontage rejection, collision/art coverage, System 18 entry traversal and renderer diagnostics.
- No Art Catalog/assets, renderer, movement, door-system, HUD or persistent-world contracts were changed.

## System 19 Compact Laundry House Candidate 001 — 2026-08-17

- Added the new peer archetype `residential.house.compact_laundry` at version 1, based on the user-approved generated house reference rather than modifying any existing farmhouse.
- Built a compact **17×13 bounding plan** with an intentionally irregular occupied footprint: two bedrooms, one bathroom, separate kitchen/dining room, central living room, small south/front entry bump and a dedicated 3×3 laundry/utility room.
- Kept circulation compact with **no dedicated hall/corridor room**. The living room acts as the circulation hub, and kitchen/living use a two-cell doorless opening.
- Added one south-facing exterior entry plus four interior room doors, for **5 total doors**, and **10 windows** distributed by room purpose.
- Used room-specific flooring: beige/blue bedroom carpet, white kitchen tile, mosaic bathroom tile and dark laminate through living/entry/laundry.
- Added **33 clustered props** without filling circulation space. Kitchen uses a contiguous refrigerator + counter + sink + counter + stove + pantry run plus adjacent breakfast table/chair.
- Added a real laundry-room cluster using recovered supported semantics: `prop.washer_front`, `prop.dryer_front`, `prop.utility_sink` and `prop.hamper`.
- Added living-room bookshelf/TV-side and sofa/coffee-table/armchair clusters, furnished bedrooms, bathroom fixtures, and a small entry table/rug cluster.
- Kept decorative rugs explicitly nonblocking and carried forward the learned table-orientation rule: table-like props in the canonical NORTH plan face only SOUTH or WEST.
- Added `CompactLaundryHouseCritiqueFixture.gd`: 19×15 lot, 26 px/cell, seed 19004, NORTH orientation with SOUTH frontage, player starting south of the closed front door.
- Registered the new archetype in `LocalBuildingGenerator.gd` and switched the canonical demo fixture preload to the new critique house while keeping `CanonicalDemoMain.gd` composition-only.
- Expanded System 19 CI to protect all three existing archetypes and test the new room program, irregular geometry, laundry equipment, clustering, facing, rotation, frontage rejection, collision/art coverage, System 18 front-door traversal and renderer diagnostics.
- Preserved Trailer v2, Small Farmhouse v2 and Large Farmhouse Candidate 004/v4 unchanged.

## System 19 Large Farmhouse Candidate 004 — 2026-08-17

- Preserved the entire Candidate 003 structure unchanged: same 21×9 shell, room sizes, wall/opening geometry, 7 doors, 11 windows, open lower living/kitchen passage and clutter-free wood kitchen runner.
- Bumped `residential.house.farm_large` to archetype version 4 because same-seed generated prop placement/orientation intentionally changed.
- Reworked common-room furnishing from sparse room-spanning placement into compact local clusters. The large open areas are allowed to remain open instead of stretching a few objects across the room.
- Living-room seating now forms one tight cluster: sofa, coffee table and armchair stay within two cells of one another, with a nearby tall bookshelf and end table against the same side of the room.
- Added a nonblocking `prop.rug` directly inside the primary front door as entry dressing without changing movement/collision behavior.
- Kitchen appliance dressing is now contiguous: stove + refrigerator + `prop.counter_straight` + sink share the north wall, with the counter physically filling the gap between refrigerator and sink.
- Added `prop.dining_chair` directly beside the existing breakfast table near the east wall. The table remains off the wood runner and the exterior-door approach stays clear.
- Corrected table-facing choices in the canonical NORTH layout: end table and coffee table face SOUTH; breakfast table faces WEST. Tables are no longer authored facing NORTH in this archetype.
- Added collision coverage for bookshelf, end table, counter and dining chair as blocking props; the entry rug is explicitly registered passable/nonblocking.
- Expanded System 19 CI to lock the unchanged structure, 24-prop clustered dressing, cluster distances, table orientations, counter placement, chair/table adjacency, clear wood runner, art/collision coverage, rotation, materialization and canonical startup.

## System 19 Large Farmhouse Candidate 003 — 2026-08-17

- Preserved accepted Trailer v2 and accepted Small Farmhouse v2 unchanged.
- Bumped `residential.house.farm_large` to archetype version 3 after the next large-house playtest critique.
- Kept Candidate 002's compact **21×9** shell, 10×3 living room, 8×3 kitchen, three 3×3 bedrooms, two 3×3 bathrooms and zero dedicated hallway rooms.
- Removed `door.interior.living_kitchen`: its former middle divider cell is now solid `wall.interior`, while the lower divider cell is completely open for a doorless passage between living and kitchen.
- Changed the full bottom row of kitchen tiles to `ground.laminate_light`, creating an eight-cell wood-floor runner from the living/kitchen passage toward the east side.
- Locked the new wood runner as generated-clutter-free: no prop may occupy any of those eight cells.
- Moved the kitchen sink from the lower/east side onto the north wall beside the stove and refrigerator.
- Added a real `prop.breakfast_table` in the open linoleum area near the east exterior wall, positioned off the runner and clear of the exterior-door approach.
- Door count drops from eight to **seven**: two exterior doors plus five private-room doors. Eleven windows remain unchanged.
- Updated the large-house critique fixture collision catalog for the existing breakfast-table semantic; no renderer, art, movement, door-system or public System 19 contract changed.
- Expanded focused System 19 CI to lock the removed living/kitchen door, replacement wall, open lower passage, wood-runner terrain/clearance, sink/table positions, collision/art coverage, rotation, materialization and canonical startup.

## System 19 Large Farmhouse Candidate 002 — 2026-08-17

- Rejected Large Farmhouse Candidate 001 after playtest feedback: **too big and too hallway-heavy**.
- Preserved accepted Trailer v2 and accepted Small Farmhouse v2 unchanged.
- Bumped `residential.house.farm_large` to archetype version 2.
- Rebuilt the large farmhouse from 25×20 down to **21×9**, matching the accepted small farmhouse's depth instead of scaling every room up.
- Removed the dedicated central hall entirely. The primary exterior door enters the living room directly, and all five private rooms open directly from living/kitchen through one partition row.
- Kept the required separate common rooms: living is **10×3**, kitchen is **8×3**.
- Kept all private rooms compact: three **3×3 bedrooms** and two **3×3 bathrooms**.
- Candidate 002 had two exterior doors, six interior doors and eleven windows.
- The previous L-shaped Candidate 001 remains historical only; compactness now takes precedence over irregular-shape complexity for the large-house critique loop.

## System 19 Large Farmhouse Candidate 001 — 2026-08-17

- Promoted the accepted compact farmhouse to the protected **Small Farmhouse** baseline after the user explicitly said: “Nice save that as small farm house.”
- Preserved `residential.house.farm_small` at archetype version 2 with its exact 13×9 geometry, 11×3 open living/kitchen, two bedrooms, one bathroom, five doors and seven windows.
- Added the peer archetype `residential.house.farm_large` with standalone owner `LargeFarmhouseBuildingGenerator.gd`.
- Candidate 001 used a 25×20 L-shaped occupied building with 3 bedrooms, 2 bathrooms, separate living/kitchen and a central hall.
- Candidate 001 first-green code was `a533f4f27de6f37b92b5e8472bb4b81220b2e06e`; Local Building Generation run `32011785845` passed. It is now superseded by Candidate 002 after playtest critique.

## Earlier project changelog

The full prior changelog is preserved verbatim in `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md`. Git history also retains every earlier version of this file.
