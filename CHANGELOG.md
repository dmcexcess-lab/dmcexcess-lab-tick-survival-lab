# Changelog

## Rural Road Generator v3 / Original Tactical Tile Restoration — 2026-08-16

- Corrected the reboot's art restoration after playtesting showed that the v2 mapping still was **not the original tactical look**. The remembered structural vocabulary came from the early `TacticalTiles.gd` path, not the later `world_art` shell/opening tiles.
- Restored the exact original tactical-atlas structural mapping: wall variants **16–22**, closed door **23**, open door **24**, and window **25**. Common ground/floors and many common props also return to the original tactical/clutter sheets.
- Removed the visible "wall behind the door" artifact. The later world-art closed-door tile included its own wall-colored background; the canonical closed door is now the original tactical tile 23, and generated door cells are mutually exclusive with wall/window cells.
- Added hard door-clearance grammar. Furniture/clutter cannot be placed on a door or any cardinal door-approach cell, and a final cleanup pass removes accidental blockers before validation.
- Reframed a rural tactical sample around one cross-map **two-lane rural main road** with dirt shoulders and narrow dirt/gravel connectors serving properties rather than a suburban road grid.
- Each generated sample now contains exactly **four residences plus one roadside business**. The residential mix includes one farm complex, one or two trailers/double-wides, and enough substantial country/farm houses to keep the map rural and inhabited without filling it with buildings.
- The farm complex includes the farmhouse plus barn/shed/field context; other properties use appropriate sheds, propane, firewood, mailboxes and rough-yard details.
- Added exactly one rural roadside commercial site per sample: either a **gas station** or **corner/convenience store**. There is no strip-mall generator in this rural slice.
- The roadside business uses an authored compact room contract: **7x7 storefront, 3x3 stock room, 3x1 manager office, and 2x2 bathroom**, with checkout/shelves/cold-case or vending/stock/office/bath clutter placed by room purpose.
- Gas stations add a small asphalt forecourt, pumps and roadside gas sign; corner stores use a modest concrete frontage rather than a large parking lot.
- Increased rural infrastructure density with frequent utility poles along the main road and cheap static power-line links rendered behind pole sprites. Stop signs remain sparse and **traffic lights are intentionally absent** from this rural band.
- Increased trees, bushes, scrub, tall grass, weeds and edge vegetation while preserving open rural ground around roads and properties.
- Kept the reboot performance contract: no idle redraw loop, only visible tactical cells are drawn, and static power lines redraw only when the board already redraws.
- Strengthened the eight-seed `RebootSmoke.gd` gate to enforce the four-residence/one-business composition, farm/manufactured-home mix, exact business room sizes, original tactical wall/door sources, zero wall-door overlap, clear door approaches, deterministic roads/power links, and player movement invariants.

## Rural Road Generator v2 / Composite Art Restoration — 2026-08-16

- Replaced the reboot-v1 one-property rural archetypes with one coherent **Rural Road** biome grammar. A tactical map became a sample of rural road rather than one giant showcase farmhouse/trailer property.
- Reduced residential scale and introduced smaller functional room grammar, roadside lots, driveways/mailboxes, outbuildings, vegetation and fixture-placement validation.
- Expanded generator smoke coverage to eight deterministic Rural Road seeds.
- Attempted to restore the pre-reboot composite art vocabulary, but this pass incorrectly treated the later `world_art` structural shell/door vocabulary as the remembered old tile set. Generator v3 supersedes that mapping with the actual early `TacticalTiles.gd` structural indices.

## Clean Reboot Core / Rural Generator v1 — 2026-08-16

- Replaced the active prototype runtime with a deliberately small clean-reboot core while retaining the existing environment and directional player artwork.
- Switched `game/main.tscn` to `scripts/reboot/RebootMain.gd`; the running build no longer loads the legacy v4-v6 generator chain, tick/calendar stack, weather, lighting, perception/fog, extraction-session presentation, or the old Safari autoload.
- Added `RebootArt.gd` as the reboot-only art catalog and `RebootSiteGenerator.gd` as a new deterministic 64x64 site generator that does not wrap or repair the legacy generator.
- Added the minimal player/movement/rotation core, phone-first controls, three tactical zoom levels, event-driven visible-cell renderer, static outskirts-to-city strategic map, reboot-only CI, and clean reboot documentation.
- Vision cone, lighting, weather, silent sound, infected, loot/inventory, combat, injuries, ticks/calendar, vehicles, extraction consequences and persistence remain intentionally deferred until the generator/player foundation is strong.

## Prototype era — archived in Git history

The earlier v0-v6 work established the retained art vocabulary and explored ticks, perception, weather, procedural regions, streetscapes, extraction travel and focused interiors. That runtime is no longer canonical after the clean reboot. Its detailed changelog remains available in repository history at commits before this reboot.
