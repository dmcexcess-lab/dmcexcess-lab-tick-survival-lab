# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request.

## Identity

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Tick Survival Lab is an original Godot 4 top-down zombie-apocalypse survival/extraction project. The project has entered a **clean reboot**. Existing artwork is retained; the old gameplay/generator architecture is no longer canonical.

Primary current design/runtime reference: `REBOOT_CORE.md`.

`TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` remains useful for later macro progression: the survivor begins on the rural outskirts, gains roaming capability toward small towns/suburbs/city, and vehicles eventually act as strategic gateway/stair transitions rather than requiring a seamless rendered island.

## Current canonical runtime

The active main scene is `game/main.tscn` using `game/scripts/reboot/RebootMain.gd`.

The active runtime intentionally contains only:

- retained art assets;
- deterministic rural site generation;
- player grid position and cardinal facing;
- forward/back movement and left/right turning;
- collision;
- touch-first controls plus keyboard convenience;
- three tactical zoom levels;
- an event-driven visible-cell renderer;
- a static strategic progression map.

The current build intentionally does **not** contain the old tick/calendar, weather, lighting, perception/fog, silent sound, infected, loot/inventory, combat, injuries, vehicles, extraction rewards/loss, off-screen simulation, or save system.

Those systems may be redesigned and reintroduced later, one owner at a time, only after the new generator/player foundation is strong.

## Current owners

- `game/scripts/reboot/RebootArt.gd` — retained atlas/player-art index contract for the reboot runtime.
- `game/scripts/reboot/RebootSiteGenerator.gd` — canonical physical site generator. It is new code and does not wrap the legacy v4-v6 generator chain.
- `game/scripts/reboot/RebootPlayer.gd` — canonical player cell/facing/movement owner.
- `game/scripts/reboot/RebootMain.gd` — active presentation/input shell: visible-cell rendering, buttons, zoom, strategic map, touch/mouse de-duplication, and site-selection orchestration.
- `game/scripts/ci/RebootSmoke.gd` — deterministic generator/player smoke test.

Preferred dependency direction:

**site data -> player/world rules -> presentation/input**

Do not move simulation truth into drawing/input helpers when later systems are added.

## Generator direction

A tactical map represents **one place**, not a miniature city or a mixed-biome stress map.

Current rural archetypes:

- Farmstead — large multi-room farmhouse, barn, shed, fields, fences, driveway, clutter and vegetation.
- Small Trailer — narrow trailer floor plan, rough homestead, shed and exterior clutter.
- Double-Wide — wider multi-room manufactured home with distinct property grammar.
- Country House — substantial rural house plus garden/field/outbuilding context.

Site generation uses purpose-built prefabs and functional room names. Roads/driveways serve the site rather than dominating it. Current validation rejects required-room/building omissions and rejects road/gravel coverage above 18% of the 64x64 site.

The next generator work should improve these rural sites until they consistently look authored before adding Small Town/Suburb/City families.

## Strategic world direction

The overworld is cheap/static presentation, not simulated terrain.

Progression runs geographically from:

**BASE -> RURAL EDGE -> SMALL TOWN -> SUBURBS -> CITY EDGE -> CITY CORE**

Only rural sites are selectable in the current reboot slice. Deeper bands are visible but locked. Later roaming/vehicle systems will unlock deeper access.

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

The reboot renderer is event-driven.

- no idle `_process()` redraw loop;
- no weather animation;
- no perception scan;
- no whole-map tactical draw;
- only visible camera cells are rendered;
- redraw happens only after movement, turning, zoom, map toggle, or site load.

Do not regress this baseline casually when expensive systems return.

## Legacy code

Many old scripts remain in the repository temporarily as historical/reference material, but **they are not current architecture and are not part of the active CI contract**. Do not extend them unless the user explicitly asks to recover a specific old algorithm.

Git history is the rollback path. A later cleanup pass may delete/archive unused legacy scripts after the reboot proves itself.

## Current next step

Playtest the new rural generator and core controls on desktop and Safari. Improve site grammar/prefabs/clutter before adding vision, lighting, weather, sound, infected, or deeper city bands.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `REBOOT_CORE.md`
6. `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` for future macro travel direction
7. Legacy design docs only when they do not conflict with the reboot
