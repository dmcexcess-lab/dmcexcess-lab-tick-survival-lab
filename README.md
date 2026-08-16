# Tick Survival Lab

An original Godot 4 top-down zombie-apocalypse survival/extraction project.

## Current status: clean reboot

The project has deliberately restarted from a small runtime core. Existing environment/player artwork is retained; the previous generator/tick/weather/perception/extraction architecture is no longer the active game.

The current playable foundation contains:

- deterministic **Rural Road generator v3**;
- one rural main road with dirt/gravel property connectors;
- exactly four residences plus one gas station or corner/convenience store per tactical sample;
- one farm complex, one or two trailers/double-wides, and substantial country housing;
- compact functional interiors and wall-aware installed fixtures;
- the **actual original tactical structural tile vocabulary** recovered from historical `TacticalTiles.gd`;
- hard door/door-approach clearance against walls and clutter;
- dense roadside utility poles with static power-line presentation, sparse stop signs and no traffic lights;
- broad grass/tree/bush/scrub vegetation;
- grid player movement with cardinal facing and left/right turning;
- collision against generated walls and blocking fixtures;
- touch-first `FORWARD`, `BACK`, `TURN L`, `TURN R`, `MAP`, and zoom controls;
- keyboard development controls;
- three tactical zoom levels;
- a static strategic progression map from rural outskirts toward the city;
- an event-driven renderer that draws only visible tactical cells and does no idle redraw work.

Vision cone, lighting, weather, sound, infected, loot, combat, ticks/calendar, injuries, vehicles, and persistence are intentionally absent for now. They will be redesigned and added back only after the generator/player foundation is strong.

## Current rural slice

A tactical map represents a **sample of rural road** rather than one giant property or a miniature city.

Each seed produces one cross-map rural main road, small dirt/gravel access roads, four residential properties and one roadside business. The residence grammar includes one farm complex, one or two manufactured homes and the remaining substantial houses. The business is either a gas station or corner/convenience store; there is no rural strip-mall generator.

The current small-business interior contract is:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x1**;
- bathroom: **2x2**.

Clutter is room-purpose driven: checkout/shelves/cold-case or vending in the sales floor, crates/pallets in stock, desk in the office, and normal bathroom fixtures. Gas stations get a compact pump/forecourt/sign setup rather than a giant parking lot.

Roadside infrastructure is intentionally rural: frequent utility poles and visible static power lines, a few stop signs, and no traffic lights. Grass, trees, bushes, scrub and weeds fill the negative space around properties and road shoulders.

## Artwork

The old tile set was not lost. The reboot initially restored the wrong structural layer.

The remembered look came from the early tactical renderer:

- tactical walls **16–22**;
- closed door **23**;
- open door **24**;
- window **25**;
- original tactical ground/floor/common-prop tiles plus the clutter sheet.

The later `world_art` closed-door tile contains its own wall-colored background, which caused the visible "wall behind doors" effect during the earlier reboot pass. `RebootArt.gd` now pins the original tactical structural indices and uses later atlases only as supplements for road topology, utility hardware, selected fixtures and vegetation.

Doors are true opening cells. Generator rules erase any wall/window/prop at the door itself, reserve cardinal approach cells from clutter, and run a final approach cleanup before validation.

## World direction

The strategic world progresses geographically:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

The current build only exposes rural walking-range samples. Deeper nodes are visible but locked for later roaming/vehicle progression.

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

See:

- `REBOOT_CORE.md` — current implementation contract;
- `README_CONTEXT.md` — current development context;
- `README_SOPS.md` — repository/coding rules;
- `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` — later strategic travel/vehicle direction.

Legacy prototype files remain temporarily for historical/reference use but are not active runtime dependencies.

## Run

Open `game/project.godot` in Godot 4.7.1 and run the project.

## Web preview

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
