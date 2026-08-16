# Changelog

## Rural Road Generator v2 / Composite Art Restoration — 2026-08-16

- Replaced the reboot-v1 one-property rural archetypes with one coherent **Rural Road** biome grammar. A tactical map is now a sample of rural road containing four roadside properties rather than one giant showcase farmhouse/trailer property.
- Every bootstrap rural-road sample now contains at least two substantial houses, at least one manufactured-home property (small trailer or double-wide), and at least three property families overall.
- Reduced residential scale from the oversized reboot-v1 farmhouse. Farmhouses are now roughly 15–17x12–13, country houses 14–16x12, double-wides 13–15x11, and small trailers 8–9x12.
- Reworked residential floorplans around smaller functional rooms. Substantial houses use separate living, kitchen, bedroom, bathroom, and optional utility spaces; manufactured homes use compact independent living/kitchen/bed/bath layouts.
- Added roadside-property grammar: individual driveways, mailboxes, sparse utility poles, barns/sheds, field rows/gardens, rough-yard clutter, vegetation, and optional property-line fencing.
- Added installed-fixture placement rules. Kitchen sinks, stoves, refrigerators, bathroom sinks/toilets/tubs/showers, washers/dryers, and water heaters are tagged and placed adjacent to walls/partitions instead of floating in room centers.
- Strengthened `RebootSiteGenerator.validate()` around quality rather than mere parseability: four properties, property diversity, multiple substantial houses, manufactured-housing presence, living/kitchen/bath functions across residences, at least 15 functional rooms, a visible road spine, road/gravel below 14% of the map, and wall-aware fixed fixtures.
- Expanded `RebootSmoke.gd` from one sample per old archetype to eight independent deterministic Rural Road seeds, including composite-art usage plus movement/rotation/spawn checks.
- Restored the pre-reboot **composite tile vocabulary** inside the new `RebootArt.gd` owner. The artwork had not been deleted; reboot v1 had simply stopped using the old selection logic.
- Roads, driveways, structural floors, house/rural/interior walls, doors, and windows again use the retained world-art vocabulary where appropriate. Nature/furniture/fixtures continue to draw from the retained final-environment, clutter, and building-prop atlases.
- Did **not** revive legacy `TacticalTiles.gd` or old gameplay architecture. The clean reboot keeps its event-driven visible-cell renderer and new generator/player owners.
- Changed the four selectable rural map nodes from direct Farmstead/Trailer/Double-Wide/Country-House buttons into seed streams for the same Rural Road biome: Rural Road, Farm Road, County Road, and Country Lane.

## Clean Reboot Core / Rural Generator v1 — 2026-08-16

- Replaced the active prototype runtime with a deliberately small clean-reboot core while retaining the existing environment and directional player artwork.
- Switched `game/main.tscn` to `scripts/reboot/RebootMain.gd`; the running build no longer loads the legacy v4-v6 generator chain, tick/calendar stack, weather, lighting, perception/fog, extraction-session presentation, or the old Safari autoload.
- Added `RebootArt.gd` as the reboot-only art catalog and `RebootSiteGenerator.gd` as a new deterministic 64x64 site generator that does not wrap or repair the legacy generator.
- Added the minimal player/movement/rotation core, phone-first controls, three tactical zoom levels, event-driven visible-cell renderer, static outskirts-to-city strategic map, reboot-only CI, and clean reboot documentation.
- Vision cone, lighting, weather, silent sound, infected, loot/inventory, combat, injuries, ticks/calendar, vehicles, extraction consequences and persistence remain intentionally deferred until the generator/player foundation is strong.

## Prototype era — archived in Git history

The earlier v0-v6 work established the retained art vocabulary and explored ticks, perception, weather, procedural regions, streetscapes, extraction travel and focused interiors. That runtime is no longer canonical after the clean reboot. Its detailed changelog remains available in repository history at commits before this reboot.
