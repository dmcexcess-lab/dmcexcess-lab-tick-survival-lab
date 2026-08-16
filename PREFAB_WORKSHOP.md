# Tick Survival Lab — Prefab Workshop

Status: active reboot subsystem.

## Purpose

The Prefab Workshop lets a developer author small tactical structures directly inside the running game and save them as reusable data. Saved prefabs can then be inserted automatically into later procedural Rural Road generations when the generator finds a safe footprint.

This is deliberately **data-driven**. Creating a new cabin, shed, room cluster, roadside structure, decorative site, etc. does not require adding another hardcoded floor plan to `RebootSiteGenerator.gd`.

## Access

- Strategic map: `PREFABS n`
- Tactical screen: `PREFABS`
- Desktop convenience: `F2`

The workshop is an overlay/dev screen. It does not advance simulation time; the current clean reboot has no tick/calendar system active anyway.

## Authoring canvas

Maximum authoring footprint: **16 × 14 cells**.

That matches one far-zoom tactical window in the current reboot. A prefab does not have to use the entire canvas: on SAVE, empty outer rows/columns are trimmed and only the used bounding box is stored.

For example, an 8×9 cabin painted inside the 16×14 workshop is stored and later stamped as an 8×9 prefab.

## Current tools

### Floors

- wood
- carpet
- tile
- linoleum
- concrete
- grass
- dirt

### Structure

- house wall
- light/interior wall
- store wall
- industrial wall
- window
- `DOOR H`
- `DOOR V`

`DOOR H` means a doorway cut into a horizontal wall. Its north/south approach cells must be clear.

`DOOR V` means a doorway cut into a vertical wall. Its east/west approach cells must be clear.

The editor protects doorway approach cells while painting, and SAVE runs the same hard structural validation used by generated maps. A doorway must have structural wall/window neighbors on both sides along its wall axis. Doors at crosses/T-junctions or with blocked approaches are rejected.

Exterior doors are supported. Door clearance may extend beyond the saved prefab footprint and is still checked against the destination map before stamping.

### Props / furniture

Current pages include common living, kitchen, retail, bathroom, office and utility objects such as sofas, tables, beds, refrigerators, stoves, counters, shelving, toilets, sinks, tubs/showers, desks, chairs, cabinets, bookshelves, TVs, washers, crates, pallets, firewood and propane tanks.

The first workshop version treats these authored props as blocking objects. More detailed per-prop behavior can be added later without changing the prefab storage format.

## Persistence

Saved prefabs live at:

`user://reboot_prefabs.json`

In the Web build this means the prefab library is persistent **for that browser/device profile**. It is not automatically committed to GitHub and is not automatically synchronized to another phone/computer/browser.

This persistence is a developer authoring library, not the future survivor/world save system. Normal game save serialization is still deferred in the reboot.

The storage format is intentionally portable JSON so later work can add:

- prefab export/import;
- promotion of selected authored prefabs into a repository-shipped built-in library;
- sharing prefab packs;
- role/category metadata;
- semantic room tagging.

## Procedural insertion

`RebootPrefabLibrary.gd` owns safe prefab insertion. `RebootSiteGenerator.gd` remains the canonical Rural Road generator and does not need to know how an authored floor plan was created.

Current generation sequence in `RebootMain.gd`:

1. Generate the normal deterministic Rural Road sample.
2. Load the local authored prefab library.
3. Deterministically choose/attempt an authored prefab for the current seed.
4. Search the 64×64 map for a safe footprint.
5. Stamp at most one saved prefab when a safe location exists.
6. Run the normal `RebootSiteGenerator.validate()` over the complete result.

The first version inserts the authored prefab as an **additional structure**. It does not replace one of the four canonical residences or the roadside business yet because workshop prefabs do not currently carry semantic room/property roles.

This preserves the current Rural Road contract while allowing authored structures to start appearing immediately.

## Safe-footprint rules

An authored prefab will not be stamped when its footprint would conflict with:

- the player spawn;
- the main road;
- dirt/gravel access roads;
- an existing generated building or its buffer;
- existing walls, windows, or doors;
- non-vegetation props;
- incompatible road/asphalt/field ground;
- an existing doorway clearance;
- the authored prefab's own exterior-door clearance.

A small amount of ordinary vegetation may be cleared to make room. The completed map is still required to pass the canonical Rural Road validator.

If no safe footprint exists for the selected prefab/seed, generation simply uses the normal procedural map without that prefab.

## Determinism

Given the same:

- Rural Road seed; and
- ordered prefab library contents,

the selected prefab and insertion origin are deterministic.

The local library can of course change when the developer adds/deletes/edits a prefab, so the authored content set becomes another explicit input to generation.

## Permanent validation

`game/scripts/ci/RebootPrefabSmoke.gd` validates:

- a real authored cabin prefab;
- 16×14 canvas trimming;
- storage encode/decode round trip;
- rejection of broken doorway geometry;
- deterministic placement;
- door-axis preservation after stamping;
- authored-use metadata;
- full `RebootSiteGenerator.validate()` success after the insert.

Pages CI runs this smoke before startup/Web export.

## Future expansion

The next useful authoring upgrades, when needed, are:

1. prefab role/category (`house`, `shed`, `store`, `barn`, `decoration`, etc.);
2. semantic room painting/tagging so authored houses can replace procedural residence slots;
3. entrance/driveway anchor markers;
4. optional rotation/mirroring where a prefab supports it;
5. export/import and repository promotion;
6. multi-prefab compositions/sets.

The current implementation intentionally starts with a small reliable contract: **paint it, validate it, save it, and let the random generator safely insert it.**
