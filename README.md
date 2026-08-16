# Tick Survival Lab

An original Godot 4 top-down zombie-apocalypse survival/extraction project.

## Current status: clean reboot

The project has deliberately restarted from a small runtime core. Existing environment/player artwork is retained; the previous generator/tick/weather/perception/extraction architecture is no longer the active game.

The current playable foundation contains:

- deterministic **Rural Road generator v4**;
- straight, bent/curved-looking, and crossroads rural main-road variants;
- dirt/gravel property connectors;
- exactly four canonical residences plus one gas station or corner/convenience store per tactical sample;
- one farm complex, one or two trailers/double-wides, and substantial country housing;
- compact functional interiors with a **3x3 minimum room size**;
- authoritative wall-axis door geometry with protected approaches;
- an in-game **Prefab Workshop** for painting/saving reusable structures up to 16x14 cells;
- deterministic safe insertion of locally saved prefabs into later generated Rural Road maps;
- the original tactical structural tile vocabulary recovered from historical `TacticalTiles.gd`;
- dense roadside utility poles with static power-line presentation, sparse stop signs and no traffic lights;
- broad grass/tree/bush/scrub vegetation;
- grid player movement with cardinal facing and left/right turning;
- collision against generated walls and blocking fixtures;
- touch-first movement/turn/map/prefab/zoom controls;
- three tactical zoom levels;
- a static strategic progression map from rural outskirts toward the city;
- an event-driven tactical renderer that draws only visible cells and does no idle redraw work.

Vision cone, lighting, weather, sound, infected, loot, combat, ticks/calendar, injuries, vehicles, and normal gameplay persistence are intentionally absent for now. The prefab library has its own developer-only browser/device-local persistence.

## Prefab Workshop

Open the workshop with `PREFABS` in tactical play, `PREFABS n` on the strategic map, or F2 on desktop.

The workshop gives you a **16x14 maximum grid**—one far-zoom tactical window—to author reusable structures directly in the running game. Current tools include common floors, several canonical wall types, windows, horizontal/vertical doors, and multiple pages of furniture/fixtures/props.

You can tap/click or drag to paint, name the prefab with a native text field, then SAVE it. Empty outer rows/columns are trimmed, so an 8x9 structure is stored as 8x9 rather than carrying the whole editor canvas.

Saved prefabs live in `user://reboot_prefabs.json`. In the Web build that library persists for the current browser/device profile. It does not automatically sync to another device or commit itself to GitHub.

Future Rural Road generations load that local library and deterministically attempt to insert **at most one** authored prefab into a safe location. Placement rejects roads, access roads, spawn proximity, existing buildings, structural conflicts, non-vegetation props, incompatible ground, and door-clearance conflicts. If no safe footprint exists, the map simply stays procedural.

The completed map still runs through the normal Rural Road validator, so user-authored doors do not get weaker geometry rules. See `PREFAB_WORKSHOP.md` for the full authoring/stamping contract.

## Current rural slice

A tactical map represents a **sample of rural road** rather than one giant property or a miniature city.

Each seed chooses a main-road topology: straight, a connected bend, or a crossroads. The road graph is generated first and protected from later yard/building/field/prefab painting. Four residential properties and one roadside business are arranged around it.

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

Doors know the axis of the wall they belong to. A horizontal-wall door must have clear north/south approaches; a vertical-wall door must have clear east/west approaches. Those approach cells are reserved from walls, windows, furniture and clutter, while the two cells along the door's own wall axis must remain structural.

This rule applies to procedural and workshop-authored doors. Exterior authored doors can reserve a clear approach outside the saved prefab footprint, and destination placement checks it before stamping.

Every recorded procedural functional room is also at least 3x3, reducing cramped partition situations and giving furniture/fixtures usable clearance.

## Artwork

Canonical structures remain pinned to the early tactical renderer:

- tactical walls **16–22**;
- closed door **23**;
- open door **24**;
- window **25**;
- original tactical ground/floor/common-prop tiles plus the clutter sheet.

`world_art` is supplemental for connected road topology/gravel/field rows; later sheets supplement utility hardware, selected fixtures and vegetation. The Prefab Workshop uses the same vocabulary.

## World direction

The strategic world progresses geographically:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

The current build only exposes rural walking-range samples. Deeper nodes remain locked for later roaming/vehicle progression.

## Performance direction

The reboot establishes a cheap baseline:

- no idle tactical `_process()` redraw loop;
- only visible camera cells are drawn;
- sparse walls/props/blockers use dictionary lookups;
- redraw occurs only after movement, turning, zoom, map toggle, site generation, or explicit workshop input;
- static power lines draw only during those existing tactical redraws;
- the dev workshop is bounded to 16x14 cells;
- no weather/perception/light calculations are running yet.

## Current code

Canonical reboot runtime:

- `game/scripts/reboot/RebootArt.gd`
- `game/scripts/reboot/RebootSiteGenerator.gd`
- `game/scripts/reboot/RebootPrefabLibrary.gd`
- `game/scripts/reboot/RebootPrefabEditor.gd`
- `game/scripts/reboot/RebootPlayer.gd`
- `game/scripts/reboot/RebootMain.gd`
- `game/scripts/ci/RebootSmoke.gd`
- `game/scripts/ci/RebootPrefabSmoke.gd`

See `REBOOT_CORE.md`, `PREFAB_WORKSHOP.md`, `README_CONTEXT.md`, `README_SOPS.md`, and `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md`.

## Run

Open `game/project.godot` in Godot 4.7.1 and run the project.

## Web preview

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/
