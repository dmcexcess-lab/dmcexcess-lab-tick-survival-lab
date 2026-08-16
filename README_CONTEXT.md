# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request.

## Identity

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Tick Survival Lab is an original Godot 4 top-down zombie-apocalypse survival/extraction project in a **clean reboot**. Existing artwork is retained; the old gameplay/generator architecture is no longer canonical.

Primary current design/runtime reference: `REBOOT_CORE.md`.

Prefab authoring reference: `PREFAB_WORKSHOP.md`.

`TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` remains useful for later macro progression: the survivor begins on the rural outskirts, gains roaming capability toward small towns/suburbs/city, and vehicles eventually act as strategic gateway/stair transitions rather than requiring a seamless rendered island.

## Current canonical runtime

The active main scene is `game/main.tscn` using `game/scripts/reboot/RebootMain.gd`.

The active runtime intentionally contains only:

- retained tactical/environment/player artwork;
- deterministic **Rural Road generator v4**;
- the active **Prefab Workshop** for authored 16x14-or-smaller generator inserts;
- browser/device-local prefab-library persistence;
- player grid position and cardinal facing;
- forward/back movement and left/right turning;
- collision;
- touch-first controls plus keyboard convenience;
- three tactical zoom levels;
- an event-driven visible-cell renderer;
- cheap static roadside power-line rendering;
- a static strategic progression map.

The current build intentionally does **not** contain tick/calendar, weather, lighting, perception/fog, silent sound, infected, loot/inventory, combat, injuries, vehicles, extraction rewards/loss, off-screen simulation, or normal survivor/world save serialization. `user://reboot_prefabs.json` is a developer-authored prefab library, not the future gameplay save system.

## Current owners

- `game/scripts/reboot/RebootArt.gd` — reboot-only art owner. Canonical structures use the early tactical-atlas vocabulary: walls 16–22, closed/open doors 23/24, window 25, original tactical floors/common props, and the clutter sheet. `world_art` supplements connected road topology.
- `game/scripts/reboot/RebootSiteGenerator.gd` — canonical physical Rural Road generator and all authoritative procedural site/door/road geometry.
- `game/scripts/reboot/RebootPrefabLibrary.gd` — authored-prefab data schema, validation, JSON persistence, trimming, deterministic safe-footprint search and stamping.
- `game/scripts/reboot/RebootPrefabEditor.gd` — touch/mouse-first in-game dev workshop for painting, saving, loading and deleting authored prefabs.
- `game/scripts/reboot/RebootPlayer.gd` — canonical player cell/facing/movement owner.
- `game/scripts/reboot/RebootMain.gd` — active presentation/input shell: visible-cell rendering, buttons, zoom, strategic map, touch/mouse de-duplication, site-selection orchestration, local prefab-library handoff/stamping orchestration, and static visible power-line presentation.
- `game/scripts/ci/RebootSmoke.gd` — deterministic generator/player quality smoke test, including door-axis geometry and road-variety checks.
- `game/scripts/ci/RebootPrefabSmoke.gd` — authored-prefab validation/round-trip/deterministic-stamping smoke test.

Preferred dependency direction:

**site/prefab data -> player/world rules -> presentation/input**

The procedural generator does not own or hardcode user-authored prefab data. `RebootMain` generates the normal site, asks `RebootPrefabLibrary` to attempt a safe deterministic insert, then runs the canonical generator validator over the complete map.

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
- property-specific mailboxes, sheds, barns, fields, propane, firewood and rough-yard clutter;
- optionally, at most one locally saved authored prefab when a safe destination footprint exists.

The authored prefab is currently an **extra structure**. It does not replace one of the canonical four residences or the roadside business because user prefabs do not yet carry semantic room/property roles.

Road topology is generated as authoritative connected cells first, then rendered with horizontal/vertical/corner/T/cross/end road sprites. Later yard, field, building-floor, forecourt and prefab painting may not overwrite main-road cells.

### Room-size rule

All recorded procedural functional rooms are **at least 3x3 usable cells**. This is both a readability rule and a structural safety rule: tiny sliver rooms made interior partition/door intersections too easy to generate incorrectly.

Current residential rooms are compact but functional. The current rural business uses:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x3**;
- bathroom: **3x3**;
- rear service area: **7x3**.

The earlier 3x1 office / 2x2 bathroom contract is superseded by the 3x3 minimum.

### Door geometry contract

The reported “wall behind door” problem was generator geometry, not the tile set.

Doors have authoritative wall-axis metadata:

- `h` = opening in a horizontal wall; north/south are the clear approaches;
- `v` = opening in a vertical wall; east/west are the clear approaches.

For every procedural or authored door:

- the door cell itself is reserved from walls, windows, props and blockers;
- the two approach cells perpendicular to the wall are reserved from structural cells and clutter;
- later wall placement is forbidden from overwriting a reserved door/approach cell;
- the two same-axis neighbors must remain structural, proving that the door sits in one continuous wall rather than at a wall intersection;
- authored exterior-door clearance may extend outside the prefab footprint and must still be safe in the destination map;
- the completed site must pass `RebootSiteGenerator.validate()`.

The stronger v4 rule caught real prefab bugs during implementation: country-house exterior doors shared an x-axis with an interior divider, and one farmhouse partition door sat too close to a perpendicular junction. Those floor plans were corrected rather than weakening the validator.

### Roadside business grammar

The rural band supports only a small roadside **gas station** or **corner/convenience store**. Strip malls are not generated here.

Store clutter follows room purpose: checkout counter, retail shelving, cold case/vending, crates/pallets, manager desk/chair, bathroom fixtures and rear-service clutter. Gas stations add a compact asphalt forecourt, pumps and gas sign; corner stores use modest frontage.

## Prefab Workshop

The active dev workshop is intentionally simple and data-driven.

- Maximum canvas: **16x14 cells**, matching one far-zoom tactical window.
- Empty outer rows/columns are trimmed on SAVE.
- Paintable layers: selected ground/floor tiles, canonical walls, windows, horizontal/vertical doors and common props/furniture.
- Native `LineEdit` is used for naming so Web/Safari gets normal keyboard behavior.
- Paint by tap/click or drag.
- CLEAR and DELETE use two-tap confirmation.
- SAVE validates hard door/overlap rules before writing.
- Library data persists at `user://reboot_prefabs.json` for the current browser/device profile.
- Saved prefabs are reloaded immediately by `RebootMain` and become inputs to future random Rural Road generation.
- Given the same seed and ordered prefab library, prefab selection/origin is deterministic.
- If no safe footprint exists, the normal procedural map is used unchanged.

Safe stamping rejects roads, side roads, spawn proximity, existing buildings/buffers, structural conflicts, non-vegetation props, incompatible road/asphalt/field ground and doorway-clearance conflicts. A small amount of vegetation may be cleared, after which the full Rural Road validator still decides whether the completed map is valid.

Current workshop access:

- strategic map `PREFABS n` button;
- tactical `PREFABS` button;
- desktop F2 convenience.

See `PREFAB_WORKSHOP.md` for the detailed contract and future role/room-tagging/export/import direction.

## Art / tile-set rule

The user's remembered structural look is pinned to historical early `TacticalTiles.gd` mapping:

- `tactical_atlas.svg`: canonical common ground/floors, walls 16–22, closed/open doors 23/24, window 25, and common tactical props;
- `clutter_atlas.svg`: canonical household/street clutter where available;
- `world_art_atlas.svg`: supplemental connected road topology, dirt/gravel and field rows;
- `building_props_atlas.svg`: supplemental fixtures and civic infrastructure such as utility poles/stop signs;
- `final_environment_props_atlas.svg`: limited supplemental vegetation;
- individual directional player sprites remain canonical.

Do not change structural walls/doors/windows to later `world_art` shell tiles unless the user explicitly asks to change the visual style. The workshop must use this same canonical structural vocabulary.

## Quality validation

`RebootSiteGenerator.validate()` and `RebootSmoke.gd` exercise eight deterministic seeds and check, among other things:

- deterministic complete generation;
- exactly five canonical primary sites: four residences + one roadside business;
- one farm complex;
- one or two manufactured homes;
- multiple substantial residences;
- exactly one gas station/corner store;
- every procedural functional room at least 3x3;
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

`RebootPrefabSmoke.gd` additionally checks:

- a real authored cabin prefab;
- 16x14 workshop-content trimming;
- JSON storage encode/decode round trip;
- rejection of broken authored door geometry;
- deterministic safe stamping;
- door-axis preservation after stamping;
- authored-use metadata;
- canonical Rural Road validation after the authored insert.

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
- PREFABS
- zoom - / +

Keyboard:

- W/Up forward
- S/Down backward
- A/Left turn left
- D/Right turn right
- M map
- -/+ zoom
- F2 prefab workshop

Touch is first-class. The active shell and workshop suppress synthetic mouse actions after a real touch. The workshop's native name field is retained for Web/Safari keyboard reliability.

## Performance contract

The reboot tactical renderer remains event-driven.

- no idle `_process()` redraw loop;
- no weather animation;
- no perception scan;
- no whole-map tactical draw;
- only visible camera cells are rendered;
- redraw happens only after movement, turning, zoom, map toggle, site load or explicit dev-editor input;
- static power lines are drawn only during those same tactical redraws and only for visible linked poles;
- the workshop is a bounded 16x14 editor, not a whole-world simulation layer.

## Legacy code

Many old scripts remain temporarily as historical/reference material, but they are not current architecture. Historical `TacticalTiles.gd` remains useful as an exact art-index reference only.

## Current next step

Playtest the Prefab Workshop on desktop and Safari: author several shapes, save/load/delete them, verify native naming input, and generate repeated Rural Road seeds to judge placement quality. Continue inspecting procedural door openings/partition junctions and straight/bent/crossroads layouts. Add semantic prefab roles/room tagging only after the basic author-save-insert loop feels reliable.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `REBOOT_CORE.md`
6. `PREFAB_WORKSHOP.md` for authored-prefab details
7. `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` for future macro travel direction
8. Legacy design docs only when they do not conflict with the reboot
