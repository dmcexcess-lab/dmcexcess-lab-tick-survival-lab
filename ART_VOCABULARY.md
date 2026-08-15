# Tick Survival Lab — Art Vocabulary

This document defines the procedural-world art vocabulary and the physical-meaning boundaries future generators must preserve.

## Core rule

**Art is not physics.** A visual tile or prop does not become solid, opaque, destructible, searchable, lootable, or interactive merely because it has a sprite. Movement blocking, sight blocking, durability, interaction and persistence remain explicit world data.

## Bootstrap environment-art freeze

The **Final Environment Art Pass** is intended to be the last broad bootstrap expansion of world art before macro-world / overworld-map work.

The environment renderer now has a deliberately oversized vocabulary for:

- terrain and natural ground;
- roads, lots, curbs and civic surfaces;
- exterior building materials;
- interior floors and wall finishes;
- nature / vegetation;
- street furniture and traffic/civic signage;
- residential furniture and permanent fixtures;
- bathroom, kitchen, living-room, bedroom and laundry fixtures;
- retail, restaurant, office, warehouse and industrial clutter/fixtures.

Future work should reuse/combine this vocabulary before adding another general-purpose atlas. Small feature-specific art may still be added when a genuinely new simulation object requires it.

## Important inventory rule

**Inventory items are not represented as loose world sprites.**

Loose inventory, loot and equipment are future data/UI concerns. The tactical world depicts only:

- terrain / ground surfaces;
- walls, windows and doors;
- furniture;
- permanent or semi-permanent fixtures;
- environmental clutter;
- vegetation;
- civic / street infrastructure;
- large world objects whose physical presence matters.

A box of cereal, screwdriver, magazine, medicine bottle, ammunition stack, individual weapon pickup, etc. should not require another world sprite simply because it can exist in inventory.

## Atlases

- `tactical_atlas.svg` — original same-owner First Fire tactical subset.
- `clutter_atlas.svg` — first Tick indoor/outdoor clutter set.
- `world_art_atlas.svg` — 64 generator-support road/surface/shell tiles.
- `building_props_atlas.svg` — 32 second-pass building/exterior fixture sprites.
- `final_environment_surfaces_atlas.svg` — **64 final-pass terrain/interior/shell tiles**.
- `final_environment_props_atlas.svg` — **128 final-pass environment/fixture sprites**.
- `player_*.svg` — four independent upright player-facing sprites.

The two final-pass atlases are new files rather than extensions of the previous atlases so existing atlas indices remain stable.

## Road topology

Procedural road cells carry a four-bit link mask:

- north = 1
- east = 2
- south = 4
- west = 8

`world_art_atlas.svg` contains horizontal/vertical straights, four corners, four T junctions, four-way intersection, directional end caps and plain wide-road/intersection pavement.

`road_surface_cells` stores paved versus dirt/trail presentation. `road_class_cells` stores hierarchy (`arterial`, `secondary`, `local`, `trail`). Those remain separate concepts.

The final surface atlas adds supporting street detail including potholes, patches, lane markings, gravel shoulders, curb ramps, faded parking, stained alleys, patio pavers and brick pavers.

## Final surface vocabulary

`final_environment_surfaces_atlas.svg` contains 64 tiles.

### Nature / terrain

- lush grass
- dry grass
- weedy grass
- forest floor
- mud
- sand / beach sand
- moss
- marsh ground
- rocky ground
- dark/light dirt
- dark/light gravel
- green/dry field texture

### Street / exterior

- asphalt patch
- pothole
- horizontal/vertical white lane stripe
- horizontal/vertical yellow lane stripe
- gravel shoulder
- curb ramp
- patio pavers
- brick pavers
- clean/cracked/oil-stained concrete
- gravel driveway
- faded parking surface
- stained alley surface

### Interior floors

- light/dark laminate
- parquet
- blue/beige/green carpet
- white/checker/mosaic tile
- green/yellow linoleum
- garage floor
- basement floor
- restaurant floor
- hospital-style floor
- classroom/commercial institutional floor

### Additional shell/opening art

- wallpaper
- wood paneling
- red brick
- white brick
- stone
- tiled wall
- glass partition
- plaster
- concrete wall
- metal panel wall
- interior door
- reinforced door
- boarded window
- broken window
- sliding glass opening
- screen door

These shell tiles are presentation vocabulary; physical wall/door/glass membership remains in the shared map schema.

## Final prop vocabulary

`final_environment_props_atlas.svg` contains **128 sprites**.

### Nature — 32

Includes small/large deciduous trees, pine, dead tree, stump, fallen log, rocks, dense/thorn bushes, tall grass, weeds, wildflowers, reeds, vines, leaf litter, branch/brush piles, dirt mound, gardens, green/dry crops, hay bale, compost, cactus, palm, desert scrub, cattails, mushrooms, mossy rock, sapling and fallen branches.

### Street / civic — 32

Includes yield, speed-limit, no-parking, street-name, one-way, dead-end, road-work, pedestrian and bus-stop signs; public trash bin; guardrail; chain-link/wood/privacy fences; cone; barricade; storm drain; manhole; utility box; transformer; phone/news boxes; bike rack; crossing beacon; parking sign; call box; road barrier; sewer grate; street planter; curb mailbox; wood utility pole and transformer pole.

### Residential / domestic — 40

Kitchen:
- white/stainless refrigerators
- range
- kitchen sink
- straight/corner counters
- pantry
- dishwasher
- island
- microwave counter
- breakfast table / dining chair

Living:
- sofa
- loveseat
- recliner
- coffee/end tables
- flat/old television
- TV stand
- tall bookshelf
- floor lamp

Bedroom / study:
- single/double/bunk beds
- wide dresser
- wardrobe
- home desk / desk chair
- hamper

Bathroom / laundry:
- modern toilet
- pedestal sink
- bathroom vanity
- clawfoot tub
- shower stall
- towel rack
- medicine cabinet
- front-load washer / dryer
- tall water heater

### Commercial / office / industrial — 24

Includes retail shelf/endcap, walk-in cooler, chest freezer, produce display, restaurant table/booth, office desk/chair, tall filing cabinet, copier, cubicle corner, server rack, pallet stack, warehouse rack, heavy workbench, tool cabinet, industrial machine, portable generator, locker bank, janitor sink/cart, vending machine and break-room table.

## Legacy-name presentation aliases

To make the art pass visible immediately without changing physical object semantics, `TacticalTiles.gd` can render several existing generic prop names with newer art.

Examples include:

- `tree` → final large deciduous tree;
- `bush` → final dense bush;
- `road_sign` → final street-name sign;
- `fence` → final wood fence;
- `tv` → final flat television;
- `toilet` / `sink` → final bathroom fixtures;
- `fridge` / `kitchen` / `washer` → final appliance/fixture art;
- `couch`, `table`, `bed`, `bookshelf`, `desk`, `chair` → final residential furniture.

The **underlying prop name does not change**, so collision, perception and future persistence semantics are not silently rewritten by this visual aliasing.

Legacy generic ground names similarly receive richer presentation aliases while road topology remains handled by the directional road renderer.

## Larger-world ground representation

The shared map language supports optional `ground_cells` overrides in addition to rectangle fills. Rectangle fills remain appropriate for rooms, lots, fields and broad surfaces. Per-cell overrides are for sparse topology details such as road turns/intersections, curb details and local transitions.

Prefer:

1. broad region/parcel surface rectangles;
2. sparse per-cell topology overrides;
3. explicit physical objects;
4. no second incompatible map/tile schema.

## Known presentation limitation

Procedural specs already emit per-building `wall_themes`, `door_themes`, and `window_themes`. The current developer preview still has a legacy whole-map shell draw path, so the complete per-building shell vocabulary is not yet consumed everywhere.

Do not work around that by creating duplicate physical map systems. The next building-template renderer can consume the existing metadata and the art already present here.
