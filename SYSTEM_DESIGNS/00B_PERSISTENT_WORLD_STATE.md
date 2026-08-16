# Tick Survival Lab — 00B Persistent World / Entity State (WHAT)

Status: **APPROVED — implementation authorized 2026-08-16**

Parent architecture: `00_FOUNDATION_WHERE_WHAT_WHEN.md`.

Approval basis: after 00A WHERE was implemented and the next bounded target was identified as WHAT, the user explicitly instructed: **“good call. ok go for what.”** This authorizes WHAT only. WHEN, generation, rendering, streaming, gameplay mechanics and live-runtime integration remain separate future slices.

## 1. Goal

Define the authoritative persistent data model for **what currently exists in the logically continuous world**, independent of rendering, generation, streaming partitions and Godot scene Nodes.

WHAT gives every durable entity stable identity, records semantic terrain/entity facts and spatial placement using the implemented WHERE contract, maintains a derived occupancy index for efficient spatial lookup, provides validated mutation paths, emits observable change records, and supports in-memory snapshot/restore of its own canonical state.

## 2. Core rule

> **The current persistent world is authoritative.**

There is not one generated reality and another gameplay reality.

Generation may create virgin terrain/entities once. Player/NPC actions, destruction and construction later mutate the same current truth. If a generated door is destroyed, the generator does not get to recreate it merely because its original template contained a door.

A future save subsystem may optimize storage using deterministic baseline regeneration, mutation journals, changed-region snapshots or a hybrid. Those are persistence-storage strategies, not alternate gameplay worlds.

## 3. Non-goals

WHAT does not implement:

- action timing/ticks/turn order;
- collision legality, pathfinding or actor movement;
- door interaction rules or lock logic;
- health/body/injury rules;
- inventory/container mechanics;
- vehicle mechanics;
- construction recipes or legality;
- procedural world generation;
- streaming/chunk partition policy;
- rendering/art/atlas selection;
- vision/lighting/weather/sound;
- AI/outbreak decision logic;
- file-system/browser save slots.

WHAT stores only foundation-level world truth. Later mechanic systems own their typed durable state and refer to WHAT entities through stable IDs.

## 4. Dependency direction

Allowed dependency:

- **WHERE / Spatial Model only** for `Vector2i` cells, N/E/S/W facing, footprints, spatial channels and structure axis.

Forbidden dependencies:

- WHEN/tick scheduler;
- generator;
- renderer/art;
- input/UI;
- player/infected code;
- streaming;
- reboot runtime;
- health/inventory/combat/construction/weather/lighting/perception/sound.

WHAT may be used by those systems later; it may not reach upward into them.

## 5. Owner modules

Canonical implementation lives under `game/scripts/foundation/world/`.

- `WorldEntityId.gd` — opaque stable-ID validation and runtime ID construction.
- `WorldEntityRecord.gd` — immutable-style entity identity + semantic type.
- `WorldPlacement.gd` — entity placement value using WHERE: channel, anchor, facing, footprint, optional structure axis.
- `TerrainStore.gd` — semantic terrain by global cell.
- `EntityStore.gd` — entity records by persistent ID.
- `PlacementStore.gd` — placement records by persistent ID.
- `OccupancyIndex.gd` — derived cell/channel -> entity-ID index; never source of truth.
- `WorldChange.gd` — typed foundation-level change notification record.
- `WorldState.gd` — read/query facade, store composition, revision, snapshot/restore and change signals.
- `WorldMutationService.gd` — only normal validated write path for foundation WHAT facts.

No Main/root behavior belongs here.

## 6. Stable entity identity

Every durable entity has an opaque non-empty string ID.

The ID:

- survives snapshot/restore;
- is independent of Godot `Object`/Node instance IDs;
- is independent of array/dictionary ordering;
- remains the same when an entity unloads/reloads or changes simulation resolution;
- may be supplied explicitly by a deterministic generator/importer;
- may be allocated by WHAT for runtime-created entities.

Consumers may compare/store IDs but must not derive gameplay meaning from their text format.

Runtime IDs use a monotonically increasing serial owned by `WorldState`; that serial is part of WHAT snapshots. Collision with an explicitly supplied ID is skipped rather than overwriting an entity.

## 7. Entity record

A foundation `WorldEntityRecord` contains only:

- `id`;
- semantic type, e.g. `door.house`, `furniture.sofa`, `vehicle.sedan`, `actor.person`.

It does **not** contain arbitrary metadata.

No universal `metadata["anything"]` dictionary is allowed. Later domains add explicit typed state keyed by entity ID.

An entity may exist without a spatial placement. This is intentional: a future inventory item inside a container or a coarse distant actor can remain a persistent entity without pretending it occupies a tactical cell.

## 8. Terrain

Terrain is a separate primary-cell fact rather than an entity per floor tile.

`TerrainStore` maps global `Vector2i` cell -> semantic terrain type.

Examples:

- `terrain.grass`
- `terrain.asphalt`
- `terrain.wood_floor`

WHAT does not infer movement cost, lighting, art or weather behavior from the semantic name.

Terrain cells may use negative global coordinates. WHAT has no implicit finite board boundary.

## 9. Placement

A placed entity has one `WorldPlacement` containing:

- persistent entity ID;
- one valid `SpatialLayer.Channel`;
- global anchor cell;
- N/E/S/W semantic facing;
- canonical-NORTH arbitrary `SpatialFootprint` geometry;
- optional structure axis.

Placement derives occupied world cells using WHERE only.

### Structure axis

`WorldPlacement.NO_STRUCTURE_AXIS = -1` means no axis is attached.

If a structure axis is supplied:

- the channel must be `STRUCTURE`;
- the axis must be a valid WHERE HORIZONTAL/VERTICAL axis.

WHAT does not require every structure to have an axis because future non-directional structures may exist. Systems that specifically place walls/doors/windows may impose the stronger requirement through their own validator.

## 10. Occupancy index

`OccupancyIndex` is a **derived acceleration structure**, not authoritative state.

It maps:

`global cell -> spatial channel -> ordered entity IDs`

Rules:

- multiple IDs may coexist in one cell/channel; WHAT does not invent collision/exclusivity rules;
- terrain is queried from `TerrainStore`, not duplicated into the entity occupancy index;
- placement set/move/rotate/remove updates the index atomically with PlacementStore changes;
- snapshot/restore serializes placements, not the index;
- restore rebuilds the index from canonical placements;
- callers receive copies of ID arrays, not the mutable internal arrays.

Future collision, rendering, LOS, construction and streaming systems can query this index without owning world truth.

## 11. Validated mutations

Normal foundation writes go through `WorldMutationService`.

Supported operations:

- create entity, optionally with requested stable ID;
- remove entity (automatically unplaces it first);
- set/replace placement;
- unplace entity without destroying it;
- set terrain semantic type;
- clear terrain.

Foundation validation rejects:

- empty semantic types;
- empty/invalid IDs;
- duplicate IDs;
- placements for nonexistent entities;
- invalid spatial channels;
- invalid facing;
- null/zero-cell footprints;
- invalid structure axis;
- structure axis attached to a non-STRUCTURE placement.

WHAT deliberately **does not** reject spatial overlap. Whether an actor can move into an occupied cell, whether furniture may overlap, or whether construction is legal belongs to later gameplay/validation systems.

## 12. Reads are mutation-safe

Public read methods return immutable-style copies of entity and placement records rather than exposing canonical mutable objects.

Public queries include:

- `has_entity(id)`;
- `entity(id)`;
- `entity_ids()`;
- `terrain_at(cell)` / `has_terrain(cell)`;
- `placement(id)` / `has_placement(id)`;
- `entities_at(cell, optional_channel)`;
- `revision()`;
- `snapshot()`.

No consumer receives direct access to the internal dictionaries/stores.

## 13. Revision and change notifications

Every successful foundation mutation increments a monotonically increasing world-state revision.

`WorldState` emits a `changed(WorldChange)` signal containing the new sequence/revision and explicit foundation-level before/after facts needed by consumers to invalidate caches or redraw.

Change kinds are intentionally small:

- entity created;
- entity removed;
- placement set/changed;
- placement removed;
- terrain set/changed;
- terrain removed.

Movement and rotation are represented as placement changes rather than teaching WHAT separate gameplay concepts.

A snapshot restore emits a separate reset signal because the whole observed state may have changed.

WHAT does not keep an unbounded permanent in-memory change journal. A future persistence adapter may subscribe to change notifications or compare snapshots; current state remains the authoritative truth.

## 14. Snapshot / restore boundary

WHAT provides a deterministic, explicit in-memory snapshot dictionary for its own state. This is **not** the final user save-file format and performs no file I/O.

Snapshot contains:

- schema version;
- next runtime-entity serial;
- current revision;
- terrain entries;
- entity records;
- placement records.

The derived occupancy index is not serialized.

Restore rules:

- validate schema and all records into temporary stores first;
- reject malformed snapshots without partially replacing current state;
- every placement must reference an existing entity;
- duplicate entity/placement IDs are rejected;
- after successful validation, replace canonical stores and rebuild occupancy;
- runtime ID serial continues from the restored value;
- emit `reset` after the complete state swap.

Snapshots use explicit primitive representations (`String`, `int`, `[x,y]`, arrays/dictionaries) so a later save codec can serialize them without depending on live Godot Nodes.

## 15. Determinism

- entity ID lists are returned sorted;
- snapshot entity/placement entries are sorted by ID;
- terrain snapshot entries are sorted by global numeric cell order;
- occupancy IDs inside a cell/channel are kept sorted;
- snapshot/restore round-trips to equivalent canonical state independent of dictionary insertion order.

This supports reproducible generation, CI and later save debugging.

## 16. Performance

Foundation WHAT is event/query driven:

- no `_process`;
- no full-world per-frame scan;
- no permanent Node per entity;
- occupancy queries are indexed by cell/channel;
- placement index updates are proportional to footprint size;
- entity/placement lookup is keyed by stable ID.

The first implementation may use in-memory Dictionaries behind these contracts. Future region-backed storage may replace store internals without changing global world coordinates or public WHAT semantics.

Streaming partition size/policy is explicitly not decided here.

## 17. Initial generation vs current truth

WHAT stores **one current canonical world state**.

Generation, prefab materialization, player construction, NPC construction and save restoration all create ordinary entities/terrain through the same foundation contract.

A future persistence layer may remember which data came from deterministic virgin generation for storage efficiency, but gameplay systems never choose between an “original” and “modified” world.

## 18. Bases and open-world fit

WHAT has no `BaseMap` and no privileged base region.

A player-built base later consists of ordinary persistent entities/terrain plus typed mechanics from construction, storage, power, water, survivors, farming, etc. Multiple or zero bases require no special world-state architecture.

## 19. Future extension seams

The stable ID + placement + query contract is intentionally ready for later:

- typed DoorState keyed by entity ID;
- actor/health/infection state;
- inventory/container relationships;
- vehicle state and multi-cell placement;
- construction/destruction;
- world generation/materialization;
- rendering and change-driven redraw;
- collision/pathfinding/LOS;
- lighting/sound anchoring;
- population/outbreak simulation;
- streaming/materialization resolution;
- save persistence/region snapshots.

Those systems must not be implemented inside WHAT merely because they need durable state.

## 20. Historical recovery

Golden `LocalWorldState.gd` (`f8fd11ebbf0ff2b3958fd46000404cbb12142fc5`) proved useful ideas—plain data for walls/obstacles/glass/doors and mutable door state—but mixed finite-board bounds and collision policy (`can_enter`) into world state.

WHAT keeps the valuable plain-data principle but rejects:

- fixed local width/height as reality;
- generator-owned board constants;
- collision legality inside world state;
- cell dictionaries as the only identity of durable objects.

Golden baseline commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 21. Tests / acceptance criteria

Dedicated headless `WorldStateSmoke.gd` must prove:

1. unique runtime IDs and caller-supplied stable IDs;
2. duplicate/invalid ID rejection;
3. entity reads cannot mutate canonical entity records;
4. terrain set/read/replace/clear at positive and negative coordinates;
5. single-cell and rotated multi-cell placement using real WHERE footprints;
6. explicit structure-axis persistence/validation;
7. invalid layer/facing/axis placement rejection;
8. occupancy index updates after place/move/rotate/unplace/remove;
9. overlapping entities can coexist because WHAT owns indexing, not collision policy;
10. removing a placed entity also removes occupancy;
11. successful mutations increment revision and emit typed changes;
12. deterministic snapshot -> restore round trip;
13. occupancy is rebuilt from restored placement rather than serialized as truth;
14. malformed snapshot rejection is atomic;
15. restored runtime ID allocation does not collide;
16. no dependency on reboot, renderer, generator or WHEN classes.

Existing `SpatialModelSmoke.gd` and frozen-reference smokes must continue to pass.

## 22. North-star fit

This design makes the persistent open world a data reality rather than a scene-tree illusion. Houses, vehicles, family members, corpses, player construction and future outbreak consequences can remain the same entities whether nearby, distant, rendered or unloaded.

It preserves **reduced complexity, not reduced consequence or mood** by keeping the foundation small and explicit while giving later systems durable causal state instead of fake regenerated outcomes.

## 23. Approved decisions

2026-08-16:

- WHAT is the second bounded implementation slice after WHERE;
- one authoritative current world, not parallel original/current gameplay worlds;
- stable opaque string entity IDs;
- semantic entity type separate from art;
- entities may exist unplaced;
- terrain stored as a primary cell fact;
- placement uses the implemented WHERE contract;
- optional explicit structure axis lives with placement geometry;
- derived occupancy index is never source of truth;
- validated write service + mutation-safe reads;
- revision/change notifications are foundation-level and mechanic-agnostic;
- no generic metadata bag;
- snapshot/restore is an in-memory canonical-state boundary, not the final disk-save implementation;
- no gameplay collision, mechanics, generation, rendering, streaming or WHEN behavior inside WHAT.
