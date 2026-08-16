# Tick Survival Lab — Clean Reboot Core

Status: current canonical implementation contract.

The project has restarted from a deliberately small runtime foundation. Existing art assets are retained. The active game does not depend on the old v4-v6 prototype generator chain, tick/calendar stack, weather, lighting, perception, extraction-session code, or Safari autoload.

## Current runtime scope

The active build contains only:

- retained environment/player artwork with the original tactical structural vocabulary restored;
- deterministic **Rural Road generator v4**;
- a minimal grid player with facing, forward/back movement, and left/right turning;
- collision against generated walls and blocking fixtures;
- a camera that follows the player;
- three tactical zoom levels;
- large touch-first movement/turn buttons;
- keyboard development controls;
- cheap static roadside power-line presentation;
- a static strategic progression map from rural outskirts toward the city;
- touch/mouse de-duplication inside the active presentation layer.

Vision cone, lighting, fog of war, weather, sound, infected, loot, combat, ticks, calendar, injuries, vehicles, and extraction consequences are intentionally absent.

## Performance rule

The active presentation is event-driven. There is no idle `_process()` redraw loop. The tactical board redraws only after a player action, turn, zoom change, map toggle, or site load. Only cells inside the current camera window are rendered. Power lines are static links drawn only during those same event-driven redraws.

## Canonical art vocabulary

The remembered pre-reboot structural look is the early `TacticalTiles.gd` vocabulary.

`RebootArt.gd` owns that mapping without importing the old runtime module:

- `tactical_atlas.svg`: common ground/floors, wall tiles **16–22**, closed door **23**, open door **24**, window **25**, common tactical props;
- `clutter_atlas.svg`: household/street clutter where available;
- `world_art_atlas.svg`: supplemental connected road topology, dirt/gravel and field rows;
- `building_props_atlas.svg`: supplemental fixtures and civic hardware such as utility poles and stop signs;
- `final_environment_props_atlas.svg`: limited supplemental vegetation;
- four independent directional player sprites.

## Generator architecture

`RebootSiteGenerator.gd` is a new generator and does not wrap the legacy generator stack.

The current tactical archetype is `rural_road`. A 64x64 map represents a coherent rural-road sample containing exactly four residences and one small roadside gas station/corner store.

The residential mix contains one farm complex, one or two manufactured homes, and substantial country houses. Sites include appropriate barns/sheds/field context, mailboxes, propane/firewood/rough-yard clutter, frequent utility poles, sparse stop signs and substantial vegetation.

## Road topology v4

The main road no longer has one fixed straight-line shape.

Every seed selects one of three authoritative road patterns:

- **straight** — cross-map rural main road;
- **bend** — the main road changes alignment through connected corner/jog segments, reading as a curved/bending rural road at this tile scale;
- **crossroads** — horizontal and vertical road connectivity creates a true intersection.

Road cells are generated first. Their north/east/south/west neighbors select horizontal, vertical, corner, T, cross and end sprites from the retained road-topology atlas. Main-road ground cells are protected against later building-floor, field, yard, driveway or forecourt painting.

Property connectors query the road alignment at their x position, so driveways continue to meet bent roads rather than assuming one global y coordinate.

## Room-size contract

Every recorded functional room is at least **3x3 usable cells**.

Current homes use compact but readable living/kitchen/bed/bath/utility spaces. The rural business uses:

- storefront: **7x7**;
- stock room: **3x3**;
- manager office: **3x3**;
- bathroom: **3x3**;
- rear service: **7x3**.

The earlier 3x1 manager-office and 2x2 bathroom experiment is superseded by the 3x3 minimum.

## Door/opening contract

The reported wall-behind-door defect was a **floor-plan geometry problem**, not a door-art problem.

Every generated door now records which wall axis owns it:

- `h`: horizontal-wall opening; north and south are clear approach cells;
- `v`: vertical-wall opening; east and west are clear approach cells.

Door creation reserves:

- the door cell itself;
- both perpendicular approach cells.

Reserved cells cannot later receive walls, windows, fixtures or clutter. Validation additionally requires the two same-axis neighbors to remain structural. A door therefore has to be seated in one continuous wall and cannot survive at a perpendicular partition intersection.

The stronger validator exposed concrete prefab defects during v4 development: country-house front doors were aligned with an interior divider, and one farmhouse door sat too close to another partition junction. Those prefab door locations were moved; the validator was not weakened.

## Fixture and clutter grammar

Installed fixtures must look installed. Kitchen/bath/utility fixtures are placed against structural wall/window planes. Furniture and commercial clutter are placed from room purpose rather than global scatter.

Door-reserved cells override clutter placement, so a shelf, sofa, fixture, tree or other prop cannot occupy an entrance/interior-door approach.

## Quality validation

`RebootSmoke.gd` exercises eight deterministic seeds and verifies:

- repeat generation is identical;
- all three road variants appear across the permanent sample set;
- four residences + one roadside business;
- one farm complex and one-to-two manufactured homes;
- every functional room is at least 3x3;
- business room sizes are 7x7 / 3x3 / 3x3 / 3x3 with 7x3 rear service;
- original tactical wall and closed-door art;
- every door has valid axis metadata;
- no wall/window on a door cell;
- no perpendicular wall geometry through a doorway;
- no clutter on door approaches;
- each door remains seated between two structural cells on its own wall axis;
- adequate road/side-road/utility/vegetation structure;
- valid player turn/movement/spawn behavior.

## Player model

The player owns grid cell and cardinal facing. Actions are turn left/right and move forward/backward. Movement respects the generated `blocked` lookup. No time cost exists yet because ticks are intentionally absent.

## Controls

Touch-first: `FORWARD`, `BACK`, `TURN L`, `TURN R`, `MAP`, zoom `-`/`+`.

Keyboard: W/Up forward, S/Down backward, A/Left turn left, D/Right turn right, M map, -/+ zoom.

## Strategic map

The current map is a cheap static progression display:

**Base / Rural Edge -> Small Town -> Suburbs -> City Edge -> City Core**

Only rural nodes are selectable. Small Town and deeper nodes remain locked for later vehicle/range progression.

## Next rule

Continue repeated Rural Road v4 playtesting. Door/partition geometry, road variety, property composition, compact room grammar, business clutter, vegetation and infrastructure must consistently look authored before adding Small Town or reintroducing vision/lighting/weather.
