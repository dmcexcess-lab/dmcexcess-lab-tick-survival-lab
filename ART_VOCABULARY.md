# Tick Survival Lab — Art Vocabulary

This document defines the current procedural-world art vocabulary and the physical meaning boundaries that future generators must preserve.

## Core rule

**Art is not physics.** A visual tile or prop does not become solid, opaque, destructible, searchable, or interactive merely because it has a sprite. Those rules remain explicit world data.

## Atlases

- `tactical_atlas.svg` — original same-owner First Fire tactical subset: legacy ground, walls, doors, windows, props, barrels.
- `clutter_atlas.svg` — small Tick indoor/outdoor clutter.
- `world_art_atlas.svg` — generator-support surfaces, road topology, floor materials, wall materials, doors/windows, utility surface tiles.
- `building_props_atlas.svg` — expanded building/interior/exterior fixture vocabulary.
- `player_*.svg` — four independent upright player-facing sprites.

## Road topology

Procedural road cells now carry a four-bit link mask:

- north = 1
- east = 2
- south = 4
- west = 8

The current atlas contains paved variants for:

- horizontal / vertical straights
- four corners
- four T junctions
- four-way intersection
- four directional end caps
- plain wide-road/intersection asphalt

Dirt roads/trails currently have horizontal, vertical, and generic gravel/junction presentation. Future macro routing should write the same `road_links` contract instead of inventing a second road-art system.

`road_surface_cells` stores whether a road segment is paved (`road`) or dirt/trail (`dirt`). `road_class_cells` remains the gameplay/network hierarchy (`arterial`, `secondary`, `local`, `trail`). These are separate concepts.

## Exterior surfaces

Available world surfaces include:

- sidewalk + four curb-facing variants
- driveway
- parking stalls in two orientations
- horizontal/vertical crosswalks
- cracked asphalt
- stained concrete
- gravel
- field rows

These exist so the next macro generator can construct actual street frontage, lots, parking areas, driveways, farms and intersections rather than recoloring one generic ground tile.

## Interior floors

Available generator-ready floors include:

- horizontal hardwood
- vertical hardwood
- kitchen tile
- bathroom tile
- office carpet
- worn carpet
- warehouse concrete
- shop tile

Room-generation code should select floors from room/building purpose, not random per tile noise.

## Wall / opening materials

Generator-ready wall materials include:

- residential siding
- brick
- cinderblock
- drywall/interior partition
- office wall
- warehouse wall
- rural wood
- storefront framing

Generator-ready opening art includes:

- residential door open/closed
- commercial door open/closed
- metal/industrial door open/closed
- glass/storefront door open/closed
- garage door open/closed
- residential window
- storefront window
- industrial window
- office/apartment window

`wall_themes`, `door_themes`, and `window_themes` are presentation metadata only. Physical wall/door/glass membership still comes from the existing map schema.

## Expanded building props

`building_props_atlas.svg` adds:

### Residential / domestic
- stove
- kitchen counter
- dresser
- nightstand
- bathtub
- shower
- vanity
- dining table
- armchair

### Office / commercial
- filing cabinet
- cubicle
- computer
- checkout
- freezer
- produce bin

### Industrial / utility
- pallet rack
- tool chest
- workbench
- locker
- utility sink
- water heater
- exterior AC
- electric meter

### Street / exterior / rural
- utility pole
- traffic light
- stop sign
- parking meter
- bollard
- hedge
- flower bed
- shed
- propane tank

The generator may place these as visual-only or add them independently to `obstacles` when movement blocking is appropriate. Tall objects that should block sight must also be included in the perception opacity vocabulary.

## Ground representation for larger worlds

The shared map language now supports optional `ground_cells` overrides in addition to rectangle fills. Rectangle fills remain appropriate for rooms, lots, fields and large surfaces. Per-cell overrides are intended for sparse topology details such as road turns/intersections, curb details and other local surface transitions.

For the next macro-world pass, prefer:

1. broad region/parcel surface rectangles;
2. sparse per-cell topology overrides;
3. explicit physical objects;
4. no second incompatible tile schema.

## Known presentation limitation

The current developer preview consumes the expanded floor/road/prop art immediately. Procedural specs also emit per-building `wall_themes`, `door_themes`, and `window_themes`, but the preview still has a legacy whole-map wall/opening draw path. The metadata and art are ready for the upcoming building-template renderer pass; do not duplicate those themes elsewhere as a workaround.
