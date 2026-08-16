# Tick Survival Lab

An original Godot 4 top-down zombie-apocalypse survival/extraction project.

## Current status: modular rebuild design freeze

The project is being re-conceptualized around **strict replaceable modules**.

The currently deployed clean-reboot build remains playable as a reference, but `game/scripts/reboot/` is now **frozen/deprecated architecture**. Do not extend `RebootMain.gd` as the long-term game.

The canonical next-build document is:

**[`MODULAR_REBUILD_MASTER_DESIGN.md`](MODULAR_REBUILD_MASTER_DESIGN.md)**

The master rule is simple:

> **Main is composition, not implementation.**

Rendering, art resolution, player state/movement, collision, input, camera, zoom, controls, strategic map, travel, extraction, procedural generation, prefab authoring, validation, persistence, and later simulation systems each get standalone owners. A subsystem should be deletable/rewriteable behind a stable contract without changing unrelated systems.

## Golden visual recovery baseline

The mature pre-clean-rewrite visual/system baseline is commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

The old artwork was **not lost**. The current repo still contains byte-identical copies of the mature six-atlas environment stack plus the four directional player sprites.

The richer old look came from historical `TacticalTiles.gd`, which semantically combined:

- `tactical_atlas.svg`
- `clutter_atlas.svg`
- `world_art_atlas.svg`
- `building_props_atlas.svg`
- `final_environment_surfaces_atlas.svg`
- `final_environment_props_atlas.svg`
- `player_north/east/south/west.svg`

The clean rewrite changed the catalog/renderer behavior, which changed the appearance even though the art files remained present. The modular rebuild will recover that semantic mapping exactly into a standalone art catalog and independent rendering layers rather than approximate it again.

## Core architectural boundary

Procedural generation outputs **semantic world data**, never atlas indices or draw calls.

Examples:

- `ground.grass_lush`
- `ground.gravel_driveway`
- `wall.house_siding`
- `door.house`
- `fixture.kitchen_sink`
- `prop.utility_pole`

A separate art catalog decides how those concepts look. Physics such as collision, opacity, door state and interaction also remain separate from art.

That boundary is intended to make a request such as **“rewrite the random map generator”** safe: generation can be completely replaced without changing graphics, player icon, movement, controls, camera, zoom, strategic map, lighting, or other systems.

## Current world/game direction

The macro world is a **static strategic map image/background with interactive nodes**.

Progression runs geographically:

**BASE / RURAL EDGE → SMALL TOWNS → SUBURBS → CITY EDGE → CITY CENTER**

The survivor begins with limited foot travel. Vehicles later act primarily as strategic gateway/“stairs” to farther staging regions. Deeper travel changes access, opportunities and logistical commitment rather than simply applying RPG difficulty scaling.

Core loop:

**STATIC STRATEGIC MAP → REACHABLE DESTINATION → GENERATED TACTICAL RAID → PHYSICAL EXTRACTION → RETURN TO STAGING → EXPAND ROAMING RANGE.**

## First tactical biome: Rural Edge

The first generator to rebuild and polish is Rural Edge. Do not move on to Small Town until many rural seeds consistently look believable.

Current grammar:

- one two-lane rural main road;
- weighted straight, bend/curve-like and crossroads layouts, with more variants later;
- small dirt/gravel drives and side roads;
- lots of grass, trees, bushes, scrub, weeds and meaningful open land;
- frequent utility poles/power-line runs along developed frontage;
- sparse stop signs and few/no traffic lights;
- roughly 3–4 residential properties as a normal scale, **not a rigid quota**;
- property mix can include a farm complex, substantial rural houses, trailers and double-wides;
- normally zero or one compact gas/convenience/corner store; never a rural strip mall.

Interior guidance:

- functional procedural rooms normally at least 3x3 usable cells;
- public/storefront rooms typically about 5x5–7x7;
- support/back rooms typically about 3x3;
- installed sinks, ranges, refrigerators and bathroom fixtures belong against sensible walls/plumbing planes;
- furniture and retail shelving preserve believable circulation;
- clutter never blindly blocks doors or required approaches;
- every door has an authoritative wall axis and cannot sit at a perpendicular wall intersection.

## Prefab direction

Prefab authoring remains planned, but it will be rebuilt on the shared semantic data and canonical renderer.

A prefab will be portable semantic data with structure/room/frontage/biome tags rather than raw atlas indices. Builder controller, view, palette, preview renderer, validator, serializer and storage are separate modules.

The prefab builder must render through the same art catalog/layer renderer used by tactical gameplay so it cannot become a second visual system.

## Recovered systems for later

The pre-rewrite repo already contains substantial solved work that should be inspected and ported into new standalone modules when needed:

- authoritative tick/action scheduler;
- world calendar;
- mutable local world/door state;
- Safari input de-duplication;
- tactical lighting;
- vision/perception/fog memory;
- weather state;
- silent spatial sound/localization;
- extraction-state concepts;
- streetscape/interior generation ideas.

Vision cone, lighting and weather are intentionally deferred until the modular renderer/player/input/map/generator foundation is correct.

The game remains intentionally **silent** unless that direction is explicitly changed; sound is simulation data communicated visually.

## Next implementation phase

The next code phase should **not** start by writing another random generator.

1. Create bootstrap-only Main.
2. Create stable semantic map/data records.
3. Recover exact historical `TacticalTiles.gd` visual mappings into standalone `ArtCatalog`.
4. Split ground, structure, prop and player rendering into separate modules.
5. Display a tiny authored test map and visually verify that the richer mature graphics are actually back.
6. Add separate player state/movement/facing/collision modules.
7. Add separate camera/zoom modules.
8. Add separate touch/keyboard/Safari input and control-view modules.
9. Add separate static strategic-map state/view/input modules.
10. Only then build the new modular Rural Edge generator.

See `README_CONTEXT.md` and `README_SOPS.md` for the permanent anti-drift/architecture rules.

## Current live reference build

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/

The live build still runs the deprecated clean-reboot runtime until the modular replacement is proven.

## Run current reference locally

Open `game/project.godot` in Godot 4.7.1 and run the project.
