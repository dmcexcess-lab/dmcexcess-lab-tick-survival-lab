# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request.

## Identity

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Tick Survival Lab is an original Godot 4 top-down zombie-apocalypse survival/extraction project in a **clean reboot**. Existing artwork is retained; the old gameplay/generator architecture is no longer canonical.

Primary current design/runtime reference: `REBOOT_CORE.md`.

`TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` remains useful for later macro progression: the survivor begins on the rural outskirts, gains roaming capability toward small towns/suburbs/city, and vehicles eventually act as strategic gateway/stair transitions rather than requiring a seamless rendered island.

## Current canonical runtime

The active main scene is `game/main.tscn` using `game/scripts/reboot/RebootMain.gd`.

The active runtime intentionally contains only:

- retained tactical/environment/player artwork;
- deterministic **Rural Road generator v4**;
- player grid position and cardinal facing;
- forward/back movement and left/right turning;
- collision;
- touch-first controls plus keyboard convenience;
- three tactical zoom levels;
- an event-driven visible-cell renderer;
- cheap static roadside power-line rendering;
- a static strategic progression map.

The current build intentionally does **not** contain tick/calendar, weather, lighting, perception/fog, silent sound, infected, loot/inventory, combat, injuries, vehicles, extraction rewards/loss, off-screen simulation, or save serialization.

## Current owners

- `game/scripts/reboot/RebootArt.gd` — reboot-only art owner. Canonical structures use the early tactical-atlas vocabulary: walls 16–22, closed/open doors 23/24, window 25, original tactical floors/common props, and the clutter sheet. `world_art` now supplements road topology so straight roads, bends, corners, T junctions and crossroads can use correct cardinal road pieces.
- `game/scripts/reboot/RebootSiteGenerator.gd` — canonical physical Rural Road generator and all authoritative site/door/road geometry.
- `game/scripts/reboot/RebootPlayer.gd` — canonical player cell/facing/movement owner.
- `game/scripts/reboot/RebootMain.gd` — active presentation/input shell: visible-cell rendering, buttons, zoom, strategic map, touch/mouse de-duplication, site-selection orchestration, and static visible power-line presentation.
- `game/scripts/ci/RebootSmoke.gd` — deterministic generator/player quality smoke test, including door-axis geometry and road-variety checks.

Preferred dependency direction:

**site data -> player/world rules -> presentation/input**

## Rural generator direction — v4

A tactical rural map is a **coherent sample of rural road**, not one building and not a miniature city.

Every generated 64x64 sample currently contains:

- one dominant rural main road whose topology can be **straight, bent/curved-looking, or a crossroads**;
- narrow dirt/gravel property roads and driveways branching from it;
- exactly **four residences**;
- exactly **one roadside gas station or corner/convenience store**;
- exactly one farm complex among the residences;
- one or two manufactured homes (`small_trailer` / `double_wide`);
- the remaining residential slots filled by substantial country houses;
- frequent roadside utility poles with static connecting power lines;
- sparse stop signs and **no traffic lights**;
- broad grass plus trees, bushes, scrub, tall grass, weeds and edge growth;
- property-specific mailboxes, sheds, barns, fields, propane, firewood and rough-yard clutter.

Road topology is generated as authoritative connected cells first, then rendered with horizontal/vertical/corner/T/cross/end road sprites. Later yard, field, building-floor and forecourt painting is not allowed to overwrite main-road cells.

### Room-size rule

All recorded functional rooms are now **at least 3x3 usable cells**. This is both a readability rule and a structural safety rule: tiny sliver rooms made interior partition/door intersections too easy to generate incorrectly.

Current residential rooms are compact but functional. The current rural business uses:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x3**;
- bathroom: **3x3**;
- rear service area: **7x3**.

The earlier 3x1 office / 2x2 bathroom contract is superseded by the 3x3 minimum.

### Door geometry contract

The reported “wall behind door” problem was generator geometry, not the tile set.

Doors now have authoritative wall-axis metadata:

- `h` = opening in a horizontal wall; north/south are the clear approaches;
- `v` = opening in a vertical wall; east/west are the clear approaches.

For every door:

- the door cell itself is reserved from walls, windows, props and blockers;
- the two approach cells perpendicular to the wall are reserved from structural cells and clutter;
- later wall placement is forbidden from overwriting a reserved door/approach cell;
- the two same-axis neighbors must remain structural, proving that the door sits in one continuous wall rather than at a wall intersection;
- a final normalization pass clears accidental later conflicts before validation.

This stronger rule caught real prefab bugs during implementation: country-house exterior doors shared an x-axis with an interior divider, and one farmhouse partition door sat too close to a perpendicular junction. The prefab door positions were separated rather than weakening the validator.

### Roadside business grammar

The rural band supports only a small roadside **gas station** or **corner/convenience store**. Strip malls are not generated here.

Store clutter follows room purpose: checkout counter, retail shelving, cold case/vending, crates/pallets, manager desk/chair, bathroom fixtures and rear-service clutter. Gas stations add a compact asphalt forecourt, pumps and gas sign; corner stores use modest frontage.

## Art / tile-set rule

The user's remembered structural look is pinned to historical early `TacticalTiles.gd` mapping:

- `tactical_atlas.svg`: canonical common ground/floors, walls 16–22, closed/open doors 23/24, window 25, and common tactical props;
- `clutter_atlas.svg`: canonical household/street clutter where available;
- `world_art_atlas.svg`: supplemental connected road topology, dirt/gravel and field rows;
- `building_props_atlas.svg`: supplemental fixtures and civic infrastructure such as utility poles/stop signs;
- `final_environment_props_atlas.svg`: limited supplemental vegetation;
- individual directional player sprites remain canonical.

Do not change structural walls/doors/windows to later `world_art` shell tiles unless the user explicitly asks to change the visual style.

## Rural quality validation

`RebootSiteGenerator.validate()` and `RebootSmoke.gd` exercise eight deterministic seeds and check, among other things:

- deterministic complete generation;
- exactly five primary sites: four residences + one roadside business;
- one farm complex;
- one or two manufactured homes;
- multiple substantial residences;
- exactly one gas station/corner store;
- every functional room at least 3x3;
- exact business room sizes 7x7 / 3x3 / 3x3 / 3x3 plus rear service;
- connected main-road and side-road presence;
- straight + bend + crossroads variants represented across the permanent sample set;
- dense utility-pole/power-line infrastructure;
- sparse stop signs and zero traffic lights;
- substantial vegetation presence;
- original tactical structural art source;
- exact tactical closed-door art;
- axis-correct doors with clear approaches and no perpendicular wall intersections;
- no door-adjacent clutter;
- wall-aware installed fixture placement;
- valid player spawn/movement.

## Strategic world direction

The overworld is cheap/static presentation, not simulated terrain.

Progression runs geographically from:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

Only rural nodes are selectable in the current reboot slice. The visible rural nodes are deterministic seed streams for the same Rural Road grammar; deeper bands remain locked for later roaming/vehicle systems.

## Controls / mobile

Logical viewport remains 640x844.

Touch controls:

- FORWARD
- BACK
- TURN L
- TURN R
- MAP
- zoom - / +

Keyboard:

- W/Up forward
- S/Down backward
- A/Left turn left
- D/Right turn right
- M map
- -/+ zoom

Touch is first-class. The active shell suppresses synthetic mouse actions after a real touch instead of using the old Safari autoload.

## Performance contract

The reboot renderer remains event-driven.

- no idle `_process()` redraw loop;
- no weather animation;
- no perception scan;
- no whole-map tactical draw;
- only visible camera cells are rendered;
- redraw happens only after movement, turning, zoom, map toggle, or site load;
- static power lines are drawn only during those same tactical redraws and only for visible linked poles.

## Legacy code

Many old scripts remain temporarily as historical/reference material, but they are not current architecture. Historical `TacticalTiles.gd` remains useful as an exact art-index reference only.

## Current next step

Playtest many Rural Road v4 seeds on desktop and Safari. Specifically inspect door openings/partition junctions and compare straight, bent and crossroads layouts. Keep improving this biome until it consistently looks authored before adding Small Town or reintroducing vision/lighting/weather.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `REBOOT_CORE.md`
6. `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` for future macro travel direction
7. Legacy design docs only when they do not conflict with the reboot
