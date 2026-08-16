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

- retained composite environment/player artwork;
- deterministic **Rural Road generator v2**;
- player grid position and cardinal facing;
- forward/back movement and left/right turning;
- collision;
- touch-first controls plus keyboard convenience;
- three tactical zoom levels;
- an event-driven visible-cell renderer;
- a static strategic progression map.

The current build intentionally does **not** contain tick/calendar, weather, lighting, perception/fog, silent sound, infected, loot/inventory, combat, injuries, vehicles, extraction rewards/loss, off-screen simulation, or save serialization.

Those systems may be redesigned and reintroduced later, one owner at a time, only after the new generator/player foundation is strong.

## Current owners

- `game/scripts/reboot/RebootArt.gd` — reboot-only composite art owner. It deliberately restores the prototype-era tactical visual vocabulary by selecting from `tactical_atlas.svg`, `world_art_atlas.svg`, `clutter_atlas.svg`, `building_props_atlas.svg`, `final_environment_surfaces_atlas.svg`, `final_environment_props_atlas.svg`, and the four directional player sprites. It does **not** depend on legacy `TacticalTiles.gd`.
- `game/scripts/reboot/RebootSiteGenerator.gd` — canonical physical site generator. New code; does not wrap the legacy v4-v6 generator chain.
- `game/scripts/reboot/RebootPlayer.gd` — canonical player cell/facing/movement owner.
- `game/scripts/reboot/RebootMain.gd` — active presentation/input shell: visible-cell rendering, buttons, zoom, strategic map, touch/mouse de-duplication, and site-selection orchestration.
- `game/scripts/ci/RebootSmoke.gd` — deterministic generator/player quality smoke test.

Preferred dependency direction:

**site data -> player/world rules -> presentation/input**

Do not move simulation truth into drawing/input helpers when later systems are added.

## Rural generator direction — v2

The current tactical rural map is **not one farmhouse/trailer property**. It is a **sample of rural road**.

Every generated 64x64 Rural Road sample contains:

- one restrained horizontal rural road with dirt shoulders;
- four roadside property lots;
- at least two substantial houses (`farmhouse` / `country_house`);
- at least one manufactured-home property (`small_trailer` / `double_wide`);
- at least three distinct property kinds overall;
- individual driveways and roadside mailboxes;
- sparse utility poles;
- barns/sheds/gardens/fields or rough-yard clutter according to property type;
- vegetation and edge growth without turning the whole map into empty grass.

Houses are intentionally smaller than the reboot-v1 showcase farmhouse. Current approximate residential shells are:

- farmhouse: 15–17 x 12–13;
- country house: 14–16 x 12;
- double-wide: 13–15 x 11;
- small trailer: 8–9 x 12.

Rooms are correspondingly smaller and more numerous across the road sample. Substantial houses use separate living, kitchen, bedrooms, bathroom, and (for farmhouses) utility space. Manufactured homes use compact but distinct living/kitchen/bed/bath layouts.

### Fixture-placement rule

Fixed fixtures must read as installed objects, not random loot or center-room clutter.

Kitchen sinks, stoves, refrigerators, bathroom sinks/toilets/tubs/showers, washers/dryers, and water heaters are placed in cells adjacent to walls/partitions. Generator validation explicitly rejects tested samples if a tagged wall fixture floats away from a wall.

Environmental props remain separate from future inventory/loot data.

### Rural quality validation

`RebootSiteGenerator.validate()` and `RebootSmoke.gd` now check multiple quality properties, including:

- four roadside properties;
- property-family diversity;
- multiple substantial houses;
- manufactured-housing presence;
- readable living/kitchen/bathroom functions across all residences;
- at least 15 functional rooms across the sample;
- visible but restrained road coverage;
- road/gravel below 14% of the 64x64 map;
- wall-aware installed fixture placement;
- deterministic output.

The permanent smoke samples eight independent seeds rather than only one selected map.

## Art / tile-set rule

The old visual style was never a single tile atlas. The previous renderer composed several retained atlases depending on object type.

The reboot initially lost that appearance because `RebootArt.gd` rendered almost everything from the final-environment atlases. The assets were **not deleted**.

Generator v2 restores the composite presentation while keeping the clean reboot architecture:

- rural road / driveway / structural floors: world-art atlas where appropriate;
- house/rural/interior walls, doors, and windows: world-art shell/opening vocabulary;
- nature and selected furniture: final environment props;
- installed fixtures/tools: building-props atlas where appropriate;
- household/street clutter: clutter atlas where appropriate;
- directional player: retained individual facing sprites.

Do not revive legacy `TacticalTiles.gd` merely for rendering. The new art owner recreates only the retained visual vocabulary.

## Strategic world direction

The overworld is cheap/static presentation, not simulated terrain.

Progression runs geographically from:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

Only rural nodes are selectable in the current reboot slice. The current rural nodes all generate the same Rural Road biome grammar with different deterministic seed streams; they do not correspond to a single farmhouse/trailer prefab. Deeper bands remain visibly locked for later roaming/vehicle systems.

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
- redraw happens only after movement, turning, zoom, map toggle, or site load.

The restored composite art selection must not regress this performance baseline.

## Legacy code

Many old scripts remain in the repository temporarily as historical/reference material, but **they are not current architecture and are not part of the active CI contract**. Do not extend them unless the user explicitly asks to recover a specific old algorithm.

Git history is the rollback path. A later cleanup pass may delete/archive unused legacy scripts after the reboot proves itself.

## Current next step

Playtest many Rural Road seeds on desktop and Safari. Improve roadside composition, property grammar, floorplans, fixture/furniture placement, clutter and visual coherence until the rural biome consistently feels authored before adding Small Town/Suburb/City families or reintroducing perception/weather.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `REBOOT_CORE.md`
6. `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` for future macro travel direction
7. Legacy design docs only when they do not conflict with the reboot
