# Tick Survival Lab — Clean Reboot Core

Status: current canonical implementation contract.

The project has restarted from a deliberately small runtime foundation. Existing art assets are retained. The active game does not depend on the old v4-v6 prototype generator chain, tick/calendar stack, weather, lighting, perception, extraction-session code, or Safari autoload.

## Current runtime scope

The active build contains only:

- retained environment/player artwork with the original tactical structural vocabulary restored;
- deterministic **Rural Road generator v4**;
- the active **Prefab Workshop** for authored generator inserts up to 16x14 cells;
- browser/device-local prefab-library persistence;
- a minimal grid player with facing, forward/back movement, and left/right turning;
- collision against generated walls and blocking fixtures;
- three tactical zoom levels;
- large touch-first movement/turn buttons;
- keyboard development controls;
- cheap static roadside power-line presentation;
- a static strategic progression map from rural outskirts toward the city;
- touch/mouse de-duplication inside the active presentation and dev-editor layers.

Vision cone, lighting, fog of war, weather, sound, infected, loot, combat, ticks, calendar, injuries, vehicles, extraction consequences, and normal gameplay save serialization are intentionally absent. `user://reboot_prefabs.json` is developer-authored content persistence, not the future survivor/world save system.

## Performance rule

The active tactical presentation is event-driven. There is no idle `_process()` redraw loop. The tactical board redraws only after a player action, turn, zoom change, map toggle, site load, or explicit workshop input. Only cells inside the current camera window are rendered. Power lines are static links drawn only during those same tactical redraws. The workshop is bounded to a 16x14 canvas.

## Canonical art vocabulary

The remembered pre-reboot structural look is the early `TacticalTiles.gd` vocabulary.

`RebootArt.gd` owns that mapping without importing the old runtime module:

- `tactical_atlas.svg`: common ground/floors, wall tiles **16–22**, closed door **23**, open door **24**, window **25**, common tactical props;
- `clutter_atlas.svg`: household/street clutter where available;
- `world_art_atlas.svg`: supplemental connected road topology, dirt/gravel and field rows;
- `building_props_atlas.svg`: supplemental fixtures and civic hardware such as utility poles and stop signs;
- `final_environment_props_atlas.svg`: limited supplemental vegetation;
- four independent directional player sprites.

The Prefab Workshop uses this same structural vocabulary. Authored content does not get a separate visual ruleset.

## Generator architecture

`RebootSiteGenerator.gd` is the canonical procedural Rural Road generator and does not wrap the legacy generator stack.

The current tactical archetype is `rural_road`. A 64x64 map represents a coherent rural-road sample containing exactly four canonical residences and one small roadside gas station/corner store.

The residential mix contains one farm complex, one or two manufactured homes, and substantial country houses. Sites include appropriate barns/sheds/field context, mailboxes, propane/firewood/rough-yard clutter, frequent utility poles, sparse stop signs and substantial vegetation.

### Authored insertion layer

`RebootPrefabLibrary.gd` is a separate focused owner for user-authored structure data. The runtime sequence is:

1. `RebootSiteGenerator.generate()` creates the normal deterministic site.
2. `RebootPrefabLibrary.try_stamp_random()` receives the locally saved prefab library and seed.
3. At most one valid authored prefab is inserted when a safe footprint exists.
4. `RebootSiteGenerator.validate()` validates the complete site, including authored doors and conflicts.

The procedural generator therefore does not become a hardcoded catalog of every developer-built cabin/shed/site.

Current authored prefabs are **additional structures**. They do not replace one of the four canonical residences or roadside business because workshop prefabs do not yet carry semantic property/room roles.

## Road topology v4

The main road varies by seed:

- **straight** — cross-map rural main road;
- **bend** — connected corner/jog segments create a curved/bending rural road at this tile scale;
- **crossroads** — horizontal and vertical road connectivity creates a true intersection.

Road cells are generated first. Their north/east/south/west neighbors select horizontal, vertical, corner, T, cross and end sprites. Main-road ground cells are protected against later building-floor, field, yard, driveway, forecourt, or authored-prefab painting.

Property connectors query the road alignment at their x position, so driveways continue to meet bent roads rather than assuming one global y coordinate.

## Room-size contract

Every recorded procedural functional room is at least **3x3 usable cells**.

Current homes use compact but readable living/kitchen/bed/bath/utility spaces. The rural business uses:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x3**;
- bathroom: **3x3**;
- rear service: **7x3**.

The earlier 3x1 manager-office and 2x2 bathroom experiment is superseded by the 3x3 minimum.

## Door/opening contract

The reported wall-behind-door defect was a **floor-plan geometry problem**, not a door-art problem.

Every procedural and authored door records which wall axis owns it:

- `h`: horizontal-wall opening; north and south are clear approach cells;
- `v`: vertical-wall opening; east and west are clear approach cells.

Door creation/authoring reserves the door cell and both perpendicular approach cells. Reserved cells cannot receive walls, windows, fixtures or clutter. Validation additionally requires the two same-axis neighbors to remain structural. A door therefore has to be seated in one continuous wall and cannot survive at a perpendicular partition intersection.

Authored exterior doors may have a clear approach outside the saved prefab bounds. Safe destination placement checks those external approach cells before stamping.

The stronger validator exposed concrete v4 floor-plan defects: country-house front doors were aligned with an interior divider, and one farmhouse door sat too close to another partition junction. Those locations were moved; the validator was not weakened.

## Prefab Workshop contract

Detailed reference: `PREFAB_WORKSHOP.md`.

- Maximum editable canvas: **16x14 cells**, matching one far-zoom tactical window.
- SAVE trims empty outer margins and stores only the used bounding box.
- Current tools cover common floors, canonical wall types, windows, `DOOR H`, `DOOR V`, and several pages of common furniture/fixtures/props.
- Native `LineEdit` naming is intentional for Safari/mobile keyboard reliability.
- Tap/click and drag painting are supported.
- CLEAR and DELETE require a second tap for destructive confirmation.
- Invalid doorway/overlap geometry is rejected on SAVE.
- Persistence lives at `user://reboot_prefabs.json` and is local to the current browser/device profile in Web builds.
- Library changes affect future generated sites; they do not rewrite an already-loaded map.
- Given the same seed and ordered library, selection and placement are deterministic.
- If no safe footprint exists, generation continues without an authored insert.

Safe placement rejects player-spawn proximity, roads and side roads, existing buildings/buffers, walls/windows/doors, non-vegetation props, incompatible road/asphalt/field ground, and doorway-clearance conflicts. A small amount of ordinary vegetation may be cleared if the resulting site still passes canonical validation.

## Fixture and clutter grammar

Installed procedural fixtures must look installed. Kitchen/bath/utility fixtures are placed against structural wall/window planes. Furniture and commercial clutter are placed from room purpose rather than global scatter.

Door-reserved cells override clutter placement. Authored props currently store explicit blocking facts and are never permitted in a reserved door approach.

## Quality validation

`RebootSmoke.gd` exercises eight deterministic seeds and verifies:

- repeat procedural generation is identical;
- all three road variants appear across the permanent sample set;
- four canonical residences + one roadside business;
- one farm complex and one-to-two manufactured homes;
- every procedural functional room is at least 3x3;
- business room sizes are 7x7 / 3x3 / 3x3 / 3x3 with 7x3 rear service;
- original tactical wall and closed-door art;
- every door has valid axis metadata;
- no wall/window on a door cell;
- no perpendicular wall geometry through a doorway;
- no clutter on door approaches;
- each door remains seated between two structural cells on its own wall axis;
- adequate road/side-road/utility/vegetation structure;
- valid player turn/movement/spawn behavior.

`RebootPrefabSmoke.gd` additionally verifies:

- a real authored cabin prefab;
- 16x14-canvas content trimming to its used footprint;
- storage encode/decode round trip;
- rejection of deliberately broken doorway geometry;
- deterministic insertion decisions/origins;
- door-axis preservation after stamping;
- authored-use metadata;
- full canonical Rural Road validation after stamping.

Both smokes are permanent Pages CI gates.

## Player model

The player owns grid cell and cardinal facing. Actions are turn left/right and move forward/backward. Movement respects the generated `blocked` lookup. No time cost exists yet because ticks are intentionally absent.

## Controls

Touch-first tactical controls: `FORWARD`, `BACK`, `TURN L`, `TURN R`, `MAP`, `PREFABS`, zoom `-`/`+`.

Keyboard: W/Up forward, S/Down backward, A/Left turn left, D/Right turn right, M map, -/+ zoom, F2 prefab workshop.

The strategic map also exposes `PREFABS n`, where `n` is the locally saved prefab count.

## Strategic map

The current map is a cheap static progression display:

**Base / Rural Edge -> Small Town -> Suburbs -> City Edge -> City Core**

Only rural nodes are selectable. Small Town and deeper nodes remain locked for later vehicle/range progression.

## Next rule

Playtest the complete author-save-insert loop on desktop and Safari. Build several prefabs of different shapes, verify save/load/delete and naming behavior, then generate many Rural Road seeds and judge whether safe placement looks natural. Keep procedural door/partition geometry and road variety under review. Semantic prefab roles/room tagging should come only after the basic workshop loop is reliable.
