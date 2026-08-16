# Tick Survival Lab — Clean Reboot Core

Status: current canonical implementation contract.

The project has restarted from a deliberately small runtime foundation. Existing art assets are retained. The active game no longer depends on the old v4-v6 generator chain, tick/calendar stack, weather, lighting, perception, extraction-session code, or Safari autoload.

## Current runtime scope

The active build contains only:

- retained environment/player artwork;
- a new deterministic rural site generator;
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

## Generator architecture

`RebootSiteGenerator.gd` is a new generator and does not wrap or repair any legacy generator.

Current site archetypes:

- `farmstead`
- `small_trailer`
- `double_wide`
- `country_house`

A site is generated as one coherent rural property rather than a miniature mixed-biome district. Roads/driveways exist only to serve the property.

The current farmstead includes a large multi-room farmhouse, barn, shed, fields, fences, driveway, yard clutter, vegetation, and room-aware fixtures. Trailer and double-wide archetypes use distinct footprints and interior plans rather than relabeling a generic house.

The current validator rejects sites with missing required room/building functions and rejects road/gravel coverage above 18% of the full site.

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

Only rural nodes are selectable in this first reboot slice. Small Town and deeper nodes are shown locked for later vehicle/range progression.

Selecting a rural node generates a fresh deterministic site for that node and closes the strategic map. Re-selecting a node later increments its visit count and generates a new seed for playtesting variety.

## Next rule

Do not restore expensive simulation systems simply because the old versions exist. The next step is to playtest and improve the rural generator until its sites consistently feel authored. Only then should the next progression band/site family be added.
