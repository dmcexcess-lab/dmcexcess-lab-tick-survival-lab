# Tick Survival Lab

An original Godot 4 top-down zombie-apocalypse survival/extraction project.

## Current status: clean reboot

The project has deliberately restarted from a small runtime core. Existing environment/player artwork is retained; the previous generator/tick/weather/perception/extraction architecture is no longer the active game.

The current playable foundation contains:

- a new deterministic rural site generator;
- four site archetypes: farmstead, small trailer, double-wide, and country house;
- multi-room building prefabs and room-aware furniture/clutter;
- grid player movement with cardinal facing and left/right turning;
- collision against generated walls and blocking fixtures;
- touch-first `FORWARD`, `BACK`, `TURN L`, `TURN R`, `MAP`, and zoom controls;
- keyboard development controls;
- three tactical zoom levels;
- a static strategic progression map from rural outskirts toward the city;
- an event-driven renderer that draws only visible tactical cells and does no idle redraw work.

Vision cone, lighting, weather, sound, infected, loot, combat, ticks/calendar, injuries, vehicles, and persistence are intentionally absent for now. They will be redesigned and added back only after the generator/player foundation is strong.

## World direction

The strategic world progresses geographically:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

The current build only exposes rural walking-range sites. Deeper nodes are visible but locked for later roaming/vehicle progression.

A tactical map represents one detailed place, not a miniature mixed-biome city. Roads and driveways serve the site rather than dominating it.

## Performance direction

The reboot establishes a cheap baseline:

- no `_process()` redraw loop;
- only visible camera cells are drawn;
- sparse walls/props/blockers use dictionary lookups;
- redraw occurs only after movement, turning, zoom, map toggle, or site generation;
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

Legacy prototype files remain temporarily for historical reference but are not part of the active runtime or CI contract.

## Run

Open `game/project.godot` in Godot 4.7.1 and run the project.

## Web preview

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
