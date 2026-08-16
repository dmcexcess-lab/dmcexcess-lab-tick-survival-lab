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
- deterministic **Rural Road generator v3**;
- player grid position and cardinal facing;
- forward/back movement and left/right turning;
- collision;
- touch-first controls plus keyboard convenience;
- three tactical zoom levels;
- an event-driven visible-cell renderer;
- cheap static roadside power-line rendering;
- a static strategic progression map.

The current build intentionally does **not** contain tick/calendar, weather, lighting, perception/fog, silent sound, infected, loot/inventory, combat, injuries, vehicles, extraction rewards/loss, off-screen simulation, or save serialization.

Those systems may be redesigned and reintroduced later, one owner at a time, only after the new generator/player foundation is strong.

## Current owners

- `game/scripts/reboot/RebootArt.gd` — reboot-only art owner. The canonical structural look is the **early tactical atlas vocabulary** recovered from historical `TacticalTiles.gd`: tactical walls 16–22, closed door 23, open door 24, window 25, original tactical floors/common props, and the clutter sheet. Later `world_art`, building-prop, and final-prop sheets are used only for capabilities the early sheets did not supply cleanly (road topology/gravel/field rows, power/road hardware, selected fixtures and vegetation).
- `game/scripts/reboot/RebootSiteGenerator.gd` — canonical physical Rural Road generator. New code; it does not wrap the legacy v4-v6 generator chain.
- `game/scripts/reboot/RebootPlayer.gd` — canonical player cell/facing/movement owner.
- `game/scripts/reboot/RebootMain.gd` — active presentation/input shell: visible-cell rendering, buttons, zoom, strategic map, touch/mouse de-duplication, site-selection orchestration, and static visible power-line presentation.
- `game/scripts/ci/RebootSmoke.gd` — deterministic generator/player quality smoke test.

Preferred dependency direction:

**site data -> player/world rules -> presentation/input**

Do not move simulation truth into drawing/input helpers when later systems are added.

## Rural generator direction — v3

A tactical rural map is a **coherent sample of rural road**, not one building and not a miniature city.

Every generated 64x64 sample currently contains:

- one cross-map horizontal rural main road, visually treated as a two-lane road, with dirt shoulders;
- narrow dirt/gravel property roads/driveways branching from the main road;
- exactly **four residences**;
- exactly **one roadside gas station or corner/convenience store**;
- exactly one farm complex among the residences;
- one or two manufactured homes (`small_trailer` / `double_wide`);
- the remaining residential slots filled by substantial country houses as needed;
- lots of roadside utility poles with static connecting power-line presentation;
- sparse stop signs and **no traffic lights** in this rural band;
- broad grass plus trees, bushes, scrub, tall grass, weeds and edge growth;
- property-specific mailboxes, sheds, barns, fields, propane, firewood and rough-yard clutter.

This composition is a grammar, not a fixed single map. The exact placement, property positions, manufactured-home type, roadside business type and clutter vary by seed.

### Residential scale

Current primary shells are intentionally moderate rather than mansion-sized:

- farmhouse: 15x12 plus farm outbuildings/field context;
- country house: 13x11;
- double-wide: 13x10;
- small trailer: 8x11.

Interiors use multiple compact functional rooms so the map can contain several useful buildings without any one interior consuming the whole tactical site.

### Roadside business grammar

The rural band supports only a small roadside **gas station** or **corner/convenience store**. Strip malls are not generated here.

The current business shell is 13x11 and preserves these usable room footprints:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x1**;
- bathroom: **2x2**.

Store clutter follows room purpose: checkout counter, retail shelving, cold case/vending, crates/pallets, manager desk, and bathroom fixtures. Gas stations add a compact asphalt forecourt, pumps and gas sign; corner stores use a modest concrete frontage.

### Door and fixture rules

Doors are structural openings, never walls with a door picture pasted on top.

- Canonical closed-door art is original tactical tile **23**.
- A generated door cell erases any wall/window/prop/blocker at that exact cell.
- Props/fixtures cannot be generated in the four cardinal approach cells around a door.
- A final cleanup pass clears any accidental door-approach prop/blocker.
- Validation rejects wall/window overlap at a door and rejects clutter immediately blocking a door approach.

Installed fixtures must still read as installed objects. Sinks, stoves, refrigerators, toilets, tubs/showers, washers/water heaters, etc. are placed against a wall/window structural plane and are validated accordingly.

## Art / tile-set rule

The previous v2 documentation incorrectly described later `world_art` house walls/doors as the restored old look. Playtesting disproved that.

The remembered prototype look is now explicitly pinned to the historical early `TacticalTiles.gd` mapping:

- `tactical_atlas.svg`: canonical common ground/floors, walls 16–22, closed/open doors 23/24, window 25, and common tactical props;
- `clutter_atlas.svg`: canonical household/street clutter where available;
- `world_art_atlas.svg`: supplemental road topology, dirt/gravel and field-row surfaces only where useful;
- `building_props_atlas.svg`: supplemental installed fixtures and civic infrastructure such as utility poles/stop signs when the early sheets lack a clean equivalent;
- `final_environment_props_atlas.svg`: limited supplemental vegetation variants;
- individual directional player sprites remain canonical.

Do not switch structural walls/doors/windows back to the later world-art shell vocabulary unless the user explicitly asks to change the visual style.

## Rural quality validation

`RebootSiteGenerator.validate()` and `RebootSmoke.gd` now check multiple authored-quality properties across eight deterministic seeds, including:

- exactly five primary sites: four residences + one roadside business;
- exactly one farm complex;
- one or two manufactured homes;
- multiple substantial residences;
- exactly one gas station/corner store and no strip-mall path;
- business room sizes 7x7 / 3x3 / 3x1 / 2x2;
- main-road and side-road presence;
- dense utility-pole/power-line infrastructure;
- sparse stop signs and zero traffic lights;
- substantial vegetation presence;
- original tactical structural art source;
- exact tactical closed-door art;
- no wall/window-door overlap;
- no clutter in door-approach cells;
- wall-aware installed fixture placement;
- deterministic output and valid player spawn/movement.

## Strategic world direction

The overworld is cheap/static presentation, not simulated terrain.

Progression runs geographically from:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

Only rural nodes are selectable in the current reboot slice. The visible rural nodes are different deterministic seed streams for the same Rural Road biome grammar; deeper bands remain locked for later roaming/vehicle systems.

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

Do not regress this baseline casually when expensive systems return.

## Legacy code

Many old scripts remain in the repository temporarily as historical/reference material, but **they are not current architecture and are not part of the active CI contract**. Historical `TacticalTiles.gd` is now an explicit art-index reference for the recovered look, not an active runtime dependency.

Git history is the rollback/reference path. A later cleanup pass may delete/archive unused legacy scripts after the reboot proves itself.

## Current next step

Playtest many Rural Road v3 seeds on desktop and Safari. Judge whether the roads, five-site composition, farm/country/manufactured mix, business interiors, utility infrastructure, vegetation, door clearance and exact recovered tile vocabulary consistently look authored before adding Small Town or reintroducing perception/weather.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `REBOOT_CORE.md`
6. `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` for future macro travel direction
7. Legacy design docs only when they do not conflict with the reboot
