# Tick Survival Lab

An original Godot 4 top-down zombie-apocalypse survival/extraction project.

## Current status: clean reboot

The project has deliberately restarted from a small runtime core. Existing environment/player artwork is retained; the previous generator/tick/weather/perception/extraction architecture is no longer the active game.

The current playable foundation contains:

- deterministic **Rural Road generator v4**;
- straight, bent/curved-looking, and crossroads rural main-road variants;
- dirt/gravel property connectors;
- exactly four residences plus one gas station or corner/convenience store per tactical sample;
- one farm complex, one or two trailers/double-wides, and substantial country housing;
- compact functional interiors with a **3x3 minimum room size**;
- authoritative wall-axis door geometry with protected approaches;
- the original tactical structural tile vocabulary recovered from historical `TacticalTiles.gd`;
- dense roadside utility poles with static power-line presentation, sparse stop signs and no traffic lights;
- broad grass/tree/bush/scrub vegetation;
- grid player movement with cardinal facing and left/right turning;
- collision against generated walls and blocking fixtures;
- touch-first movement/turn/map/zoom controls;
- three tactical zoom levels;
- a static strategic progression map from rural outskirts toward the city;
- an event-driven renderer that draws only visible tactical cells and does no idle redraw work.

Vision cone, lighting, weather, sound, infected, loot, combat, ticks/calendar, injuries, vehicles, and persistence are intentionally absent for now.

## Current rural slice

A tactical map represents a **sample of rural road** rather than one giant property or a miniature city.

Each seed chooses a main-road topology: straight, a connected bend, or a crossroads. The road graph is generated first and protected from later yard/building/field painting. Four residential properties and one roadside business are then arranged around it.

The residence grammar includes one farm complex, one or two manufactured homes and substantial country houses. The business is either a gas station or corner/convenience store; there is no rural strip-mall generator.

Current small-business interior contract:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x3**;
- bathroom: **3x3**;
- rear service: **7x3**.

Clutter is room-purpose driven: checkout/shelves/cold-case or vending in the sales floor, crates/pallets in stock/service space, desk/chair in the office, and normal bathroom fixtures. Gas stations get a compact pump/forecourt/sign setup rather than a giant parking lot.

## Door geometry

The remaining visible "wall behind door" problem turned out to be **bad partition geometry**, not the tile set.

Doors now know the axis of the wall they belong to. A horizontal-wall door must have clear north/south approaches; a vertical-wall door must have clear east/west approaches. Those approach cells are reserved from later walls, windows, furniture and clutter, while the two cells along the door's own wall axis must remain structural.

This catches doors generated at wall crosses/T-junctions even when no wall occupies the actual door cell. The permanent generator smoke rejects those maps.

Every recorded functional room is also now at least 3x3, reducing cramped partition situations and giving furniture/fixtures usable clearance.

## Artwork

The old tile set was not lost. Canonical structures remain pinned to the early tactical renderer:

- tactical walls **16–22**;
- closed door **23**;
- open door **24**;
- window **25**;
- original tactical ground/floor/common-prop tiles plus the clutter sheet.

`world_art` is supplemental for connected road topology/gravel/field rows; later sheets supplement utility hardware, selected fixtures and vegetation.

## World direction

The strategic world progresses geographically:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

The current build only exposes rural walking-range samples. Deeper nodes remain locked for later roaming/vehicle progression.

## Performance direction

The reboot establishes a cheap baseline:

- no `_process()` redraw loop;
- only visible camera cells are drawn;
- sparse walls/props/blockers use dictionary lookups;
- redraw occurs only after movement, turning, zoom, map toggle, or site generation;
- static power lines draw only during those existing tactical redraws;
- no weather/perception/light calculations are running yet.

## Current code

Canonical reboot runtime:

- `game/scripts/reboot/RebootArt.gd`
- `game/scripts/reboot/RebootSiteGenerator.gd`
- `game/scripts/reboot/RebootPlayer.gd`
- `game/scripts/reboot/RebootMain.gd`
- `game/scripts/ci/RebootSmoke.gd`

See `REBOOT_CORE.md`, `README_CONTEXT.md`, `README_SOPS.md`, and `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md`.

## Run

Open `game/project.godot` in Godot 4.7.1 and run the project.

## Web preview

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
