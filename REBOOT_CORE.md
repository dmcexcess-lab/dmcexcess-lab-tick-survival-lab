# Tick Survival Lab — Clean Reboot Core

Status: current canonical implementation contract.

The project has restarted from a deliberately small runtime foundation. Existing art assets are retained. The active game does not depend on the old v4-v6 generator chain, tick/calendar stack, weather, lighting, perception, extraction-session code, or Safari autoload.

## Current runtime scope

The active build contains only:

- retained environment/player artwork with the original tactical structural vocabulary restored;
- deterministic Rural Road generator v3;
- a minimal grid player with facing, forward/back movement, and left/right turning;
- collision against generated walls and blocking fixtures;
- a camera that follows the player;
- three tactical zoom levels;
- large touch-first movement/turn buttons;
- keyboard development controls;
- cheap static roadside power-line presentation;
- a static strategic progression map from rural outskirts toward the city;
- touch/mouse de-duplication inside the active presentation layer.

Vision cone, lighting, fog of war, weather, sound, infected, loot, combat, ticks, calendar, injuries, vehicles, and extraction consequences are intentionally absent. They will be reintroduced only after this core is visually and mechanically sound.

## Performance rule

The active presentation is event-driven.

There is no idle `_process()` redraw loop. The tactical board redraws only after a player action, turn, zoom change, map toggle, or site load. Only cells inside the current camera window are rendered; the whole 64x64 site is never redrawn merely because it exists. Power lines are static links drawn only during the same event-driven tactical redraw and only when both linked poles are visible.

## Canonical art vocabulary

The remembered pre-reboot structural look is the early `TacticalTiles.gd` vocabulary.

`RebootArt.gd` owns that mapping without importing the old runtime module:

- `tactical_atlas.svg`: canonical common ground/floors, wall tiles **16–22**, closed door **23**, open door **24**, window **25**, and common tactical props;
- `clutter_atlas.svg`: canonical household/street clutter where available;
- `world_art_atlas.svg`: supplemental road topology, dirt/gravel and field rows;
- `building_props_atlas.svg`: supplemental installed fixtures and civic hardware such as utility poles and stop signs;
- `final_environment_props_atlas.svg`: limited supplemental vegetation;
- four independent directional player sprites.

The previous Rural Road v2 restoration was incomplete because it used later `world_art` shell/door tiles for structures. In particular, the later closed-door art contains a wall-colored background. Rural Road v3 supersedes that mapping: generated walls/doors/windows use the original tactical structural tiles.

## Generator architecture

`RebootSiteGenerator.gd` is a new generator and does not wrap or repair any legacy generator.

The current tactical archetype is:

- `rural_road`

A 64x64 tactical map represents **a coherent sample of rural road**, not one farmhouse and not a miniature mixed-biome city.

A generated sample contains:

- one horizontal cross-map main road, visually functioning as a rural two-lane road, with dirt shoulders;
- narrow dirt/gravel roads or driveways branching toward properties;
- exactly four residences;
- exactly one small roadside gas station or corner/convenience store;
- exactly one farm complex;
- one or two manufactured homes;
- remaining residential slots filled with substantial country housing;
- mailboxes, barns/sheds, field context, propane/firewood/rough-yard details as appropriate;
- dense roadside utility poles with connecting power lines;
- sparse stop signs and zero traffic lights;
- substantial grass, tree, bush, scrub and weed coverage without urbanizing the map.

### Residential scale

Current primary shells:

- farmhouse: 15x12 plus barn/shed/field context;
- country house: 13x11;
- double-wide: 13x10;
- small trailer: 8x11.

The homes are divided into compact functional spaces instead of huge open rooms. House grammar includes living, kitchen, bedroom, bathroom, and farmhouse utility functions as appropriate.

### Rural business scale

The rural business is deliberately small. Strip malls do not belong to this band.

Current business shell: 13x11.

Usable room contract:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x1**;
- bathroom: **2x2**.

Room-purpose clutter includes checkout, retail shelves, cold-case/vending, crates/pallets, desk and bathroom fixtures. Gas stations add a compact pump/forecourt/sign arrangement; corner stores receive a small concrete frontage.

## Door/opening contract

Doors are true opening cells.

- Canonical closed-door art is tactical tile 23.
- `_door()` removes any wall, window, prop and blocker at the door cell before recording the door.
- `_can_place_prop()` rejects props on or cardinally adjacent to any known door.
- A final `_clear_all_door_approaches()` pass removes accidental props around all completed door openings.
- Validation rejects any wall/window-door overlap and any prop on the four cardinal approach cells around a door.

This contract prevents both the wall-background door artifact and clutter physically blocking entrances/interior doorways.

## Fixture grammar

Installed fixtures must look installed.

Kitchen sinks, stoves, refrigerators, bathroom sinks/toilets/tubs/showers, washers and water heaters are placed adjacent to a structural wall/window plane. Generator fixture tags allow validation to reject fixed fixtures floating in open floor space.

Furniture and commercial clutter are placed from room purpose rather than by global random scatter. Environmental clutter remains separate from future inventory/loot.

## Quality validation

Generator validation checks authored structure, not merely successful map creation.

`RebootSmoke.gd` exercises eight independent deterministic seeds and verifies:

- repeated generation is identical, including roads and power links;
- exactly five primary properties: four residences and one roadside business;
- one farm complex and one-to-two manufactured homes;
- exact 7x7 / 3x3 / 3x1 / 2x2 business rooms;
- original tactical closed-door art and tactical wall source;
- no wall-door overlap;
- no door-adjacent clutter;
- adequate road/side-road/utility/vegetation structure;
- wall-aware fixed fixtures;
- valid player turn/movement/spawn behavior.

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

Only rural nodes are selectable in this reboot slice. The visible rural nodes are different deterministic seed streams for the same Rural Road biome grammar. Small Town and deeper nodes remain locked for later vehicle/range progression.

## Next rule

Do not restore expensive simulation systems simply because old versions exist. The next step is repeated Rural Road v3 playtesting: road/property composition, exact recovered tile appearance, door clearance, compact room grammar, business clutter, vegetation and infrastructure must consistently look authored before adding Small Town or reintroducing vision/lighting/weather.
