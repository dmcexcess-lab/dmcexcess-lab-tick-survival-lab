# Tick Survival Lab — Clean Reboot Core

Status: current canonical implementation contract.

The project has restarted from a deliberately small runtime foundation. Existing art assets are retained. The active game does not depend on the old v4-v6 generator chain, tick/calendar stack, weather, lighting, perception, extraction-session code, or Safari autoload.

## Current runtime scope

The active build contains only:

- retained composite environment/player artwork;
- deterministic Rural Road generator v2;
- a minimal grid player with facing, forward/back movement, and left/right turning;
- collision against generated walls and blocking fixtures;
- a camera that follows the player;
- three tactical zoom levels;
- large touch-first movement/turn buttons;
- keyboard development controls;
- a static strategic progression map from rural outskirts toward the city;
- touch/mouse de-duplication inside the active presentation layer.

Vision cone, lighting, fog of war, weather, sound, infected, loot, combat, ticks, calendar, injuries, vehicles, and extraction consequences are intentionally absent. They will be reintroduced only after this core is visually and mechanically sound.

## Performance rule

The active presentation is event-driven.

There is no idle `_process()` redraw loop. The tactical board redraws only after a player action, turn, zoom change, map toggle, or site load. Only cells inside the current camera window are rendered; the whole 64x64 site is never redrawn merely because it exists.

## Art vocabulary

The pre-reboot look was a composite renderer, not one monolithic tile atlas. The underlying files were never deleted.

`RebootArt.gd` now restores that vocabulary without depending on legacy `TacticalTiles.gd`:

- `tactical_atlas.svg`
- `world_art_atlas.svg`
- `clutter_atlas.svg`
- `building_props_atlas.svg`
- `final_environment_surfaces_atlas.svg`
- `final_environment_props_atlas.svg`
- four independent directional player sprites.

World-road and shell/opening art is used again for roads, walls, doors and windows; retained final/clutter/building art supplies nature and fixtures where appropriate. The clean reboot architecture remains intact.

## Generator architecture

`RebootSiteGenerator.gd` is a new generator and does not wrap or repair any legacy generator.

The current tactical archetype is:

- `rural_road`

A 64x64 tactical map represents **a sample of rural road**, not one giant farmhouse and not a miniature mixed-biome city.

A generated sample contains:

- one horizontal rural road with dirt shoulders;
- four roadside lots;
- at least two substantial houses;
- at least one small trailer or double-wide;
- at least three property families overall;
- driveways/mailboxes per property;
- sparse utility poles;
- property-specific barns, sheds, gardens, field rows, rough-yard clutter and vegetation.

Current residence sizes are intentionally moderate:

- farmhouse: roughly 15–17 x 12–13;
- country house: roughly 14–16 x 12;
- double-wide: roughly 13–15 x 11;
- small trailer: roughly 8–9 x 12.

The larger houses contain multiple smaller rooms rather than huge open chambers. Houses use living room, kitchen, bedrooms, bathroom, and optional utility space. Manufactured homes use compact independent living/kitchen/bed/bath functions.

## Fixture grammar

Installed fixtures must look installed.

Kitchen sinks, stoves, refrigerators, bathroom sinks/toilets/tubs/showers, washers/dryers and water heaters are placed adjacent to a wall or interior partition. The generator records fixture tags and validation rejects a tested map if one of those wall fixtures floats in open floor space.

Beds/dressers, seating/TV relationships and tables are also placed from room purpose rather than as global random clutter. Environmental clutter remains separate from future inventory/loot.

## Quality validation

Generator validation now checks visual/content structure, not merely successful map creation.

Current invariants include:

- exactly four roadside properties in the bootstrap road sample;
- at least three property families;
- multiple substantial houses;
- manufactured-housing presence;
- readable living, kitchen and bathroom functions across the residences;
- at least fifteen functional room records across the map;
- visible road spine;
- road/gravel no more than 14% of the 64x64 map;
- wall-aware fixed fixtures;
- valid unblocked spawn.

`RebootSmoke.gd` exercises eight independent deterministic seeds, verifies repeated generation is identical, confirms the restored composite world-art shell is actually used, and retains player movement/rotation/spawn checks.

## Player model

The player owns only:

- grid cell;
- cardinal facing.

Actions:

- turn left;
- turn right;
- move forward;
- move backward.

Turning changes facing without changing position. Movement respects the generated `blocked` lookup. No time cost exists yet because the tick system is intentionally not part of this reboot milestone.

## Controls

Touch-first controls:

- `FORWARD`
- `BACK`
- `TURN L`
- `TURN R`
- `MAP`
- zoom `-` / `+`

Keyboard conveniences:

- W / Up = forward
- S / Down = backward
- A / Left = turn left
- D / Right = turn right
- M = map
- - / + = zoom

One physical touch is suppressed from becoming a second synthetic mouse action by a local 650 ms touch/mouse de-duplication window.

## Strategic map

The current map is a cheap static progression display, not simulated terrain.

It reads left-to-right:

**Base / Rural Edge -> Small Town -> Suburbs -> City Edge -> City Core**

Only rural nodes are selectable in this reboot slice. The visible rural nodes are different deterministic seed streams for the same Rural Road biome grammar rather than direct buttons for one farmhouse, one trailer, etc. Small Town and deeper nodes remain locked for later vehicle/range progression.

## Next rule

Do not restore expensive simulation systems simply because the old versions exist. The next step is repeated Rural Road playtesting: composition, floorplans, furniture/fixture placement, exterior clutter and variation should become consistently believable before adding Small Town or reintroducing vision/lighting/weather.
