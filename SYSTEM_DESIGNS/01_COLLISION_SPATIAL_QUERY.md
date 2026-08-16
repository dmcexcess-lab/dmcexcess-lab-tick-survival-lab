# Tick Survival Lab — 01 Collision / Spatial Query

Status: **IMPLEMENTED — canonical modular source and CI contract present 2026-08-16**

Approval basis: after completing WHERE / WHAT / WHEN, the user explicitly instructed: **“Ok continue on with coding collision and spacial query.”** This authorized this bounded system only. Movement actions, pathfinding, doors, terrain traversal, AI, rendering, generation and WHEN integration remain separate future slices.

## 1. Goal

Provide the canonical read-only spatial-world query layer that answers **what occupies a location and whether entity occupancy creates a hard movement collision**.

This is the first downstream system that deliberately consumes implemented WHERE + WHAT together.

It lets future movement, AI, pathfinding, construction validation and interaction systems ask spatial questions without:

- reaching into WHAT internals;
- inferring physics from art;
- hardcoding collision rules into movement;
- treating missing/unmaterialized world data as empty space;
- storing one redundant collision boolean on every persistent world entity.

## 2. Non-goals

This system does **not**:

- move entities;
- schedule or consume ticks;
- calculate movement duration;
- decide terrain traversal capability such as swimming, climbing, mud slowdown or road speed;
- open/close doors;
- implement pathfinding;
- implement pushing, shoving or displacement;
- implement vision/opacity;
- implement attack reach;
- mutate WHAT placement;
- generate world content;
- render anything;
- own input/UI.

Movement is a later system that combines this query contract with WHEN and WHAT mutation.

## 3. Why collision is not stored directly in WHAT

WHAT intentionally stores foundation identity/type/placement, not every gameplay mechanic.

Putting `blocks_movement` on `WorldEntityRecord` would turn the foundation entity into a universal mechanic bag.

Instead this system owns physical movement collision through:

1. a **type-level collision catalog** for the normal case;
2. a **sparse per-entity override state** for dynamic exceptions.

Examples:

- `structure.wall.house` -> blocking by default;
- `object.chair` -> blocking by default;
- `object.bush.low` -> explicitly non-blocking;
- `actor.person` -> blocking by default;
- `structure.door.house` -> blocking by default, with a per-entity override to non-blocking while open.

The catalog is physics configuration, not art. Renderer atlas/sprite choices never determine collision.

## 4. Low-resource rule

Do **not** allocate a collision-state record for every static entity in a large persistent world.

Most entities use the collision profile of their semantic type.

Per-entity collision override state exists only when current physical behavior differs from the type default.

This keeps detailed persistent worlds cheap while retaining explicit physics and dynamic behavior.

## 5. Owner modules

Canonical implementation lives under `game/scripts/simulation/collision/`:

- `CollisionProfile.gd` — immutable-style type-level hard-movement collision profile.
- `CollisionCatalog.gd` — semantic entity type -> collision profile registry.
- `CollisionOverrideState.gd` — sparse durable per-entity blocking overrides with deterministic snapshot/restore.
- `SpatialQueryResult.gd` — explicit CLEAR / BLOCKED / UNKNOWN query result.
- `SpatialQueryService.gd` — read-only WHERE/WHAT/collision query facade.
- `game/scripts/ci/CollisionSpatialQuerySmoke.gd` — independent deterministic contract test.

## 6. Allowed dependencies

Collision / Spatial Query may depend on:

- WHERE public geometry/types;
- WHAT public read APIs (`entity`, `placement`, `entities_at`, `has_terrain`, `terrain_at`, entity IDs);
- stable WHAT entity-ID validation for override records.

It may not call WHAT internal mutation methods.

## 7. Forbidden dependencies

The system must not depend on:

- WHEN / `TickKernel`;
- movement actions;
- player/input/UI;
- AI/pathfinding;
- door-state implementation;
- health/combat;
- renderer/art/atlas code;
- generator;
- streaming implementation;
- reboot runtime.

## 8. Collision profile contract

`CollisionProfile` contains only:

- semantic entity type;
- `blocks_movement` boolean.

It does not contain:

- opacity/vision blocking;
- interaction rules;
- damage;
- movement cost;
- terrain effects;
- rendering facts;
- door state.

Those belong to their own systems.

## 9. Collision catalog

`CollisionCatalog` explicitly registers a profile for a semantic entity type.

Rules:

- empty semantic types are invalid;
- registration replaces the previous profile for the same type intentionally;
- reads return copies;
- profile IDs are sorted deterministically when enumerated;
- the catalog is not a save-game state object;
- no semantic type is inferred from a texture, atlas index or naming substring.

A later composition/content layer may register the complete canonical physics vocabulary once semantic world types are finalized.

## 10. Sparse per-entity overrides

`CollisionOverrideState` stores only entity IDs whose current movement-blocking fact differs from or intentionally overrides the type default.

Rules:

- stable entity IDs only;
- override value is an explicit boolean;
- clearing an override returns the entity to catalog-default behavior;
- override state has a revision and deterministic snapshot/restore;
- restore is atomic;
- the override store itself does not require the entity to be currently loaded/placed or even present in a particular WHAT instance;
- cross-state consistency is checked by `SpatialQueryService` diagnostics rather than making the override store own WHAT.

This allows a persistent door or other dynamic object to remain collision-correct without a record for every static wall/tree/chair in the world.

## 11. Which placed entities require explicit collision classification

Placed entities in these WHERE channels require either:

- a collision catalog profile for their semantic type; or
- a per-entity override.

Required channels:

- `STRUCTURE`;
- `OBJECT`;
- `ACTOR`.

Why: silently treating an unclassified wall, chair or actor as passable would hide world/generation/content bugs.

`LOOSE_ITEM` and `EFFECT` do not require a catalog profile by default. They are non-blocking unless an explicit per-entity override says otherwise.

Terrain is not an entity collision profile in this system.

## 12. Terrain and UNKNOWN space

A query may require terrain data for every target cell.

If required terrain is absent from WHAT, that target is **UNKNOWN**, not empty/clear.

This is critical for the future persistent open world:

- an unmaterialized/uninitialized area must not become walkable void;
- streaming/generation is not triggered by collision queries;
- a caller may later request materialization and retry.

This system does not decide whether an existing terrain type is traversable by a particular actor. Future movement/traversal rules own water, mud, stairs, climbing, vehicle restrictions and similar capability questions.

## 13. Query result states

`SpatialQueryResult` has three statuses:

### CLEAR
All required terrain exists; every relevant placed entity is collision-classified; no classified entity blocks movement.

### BLOCKED
All required information is known and one or more entities explicitly block movement.

### UNKNOWN
The query cannot safely decide because one or more required terrain cells are missing or a required placed entity has no collision classification.

UNKNOWN takes precedence over BLOCKED when both are present because the result is incomplete, while still reporting known blockers.

The result contains deterministic copies of:

- queried cells;
- blocking entity IDs;
- missing-terrain cells;
- unclassified entity IDs.

## 14. Query APIs

`SpatialQueryService` exposes read-only helpers including:

- `entities_at(cell, channel)`;
- `placements_at(cell, channel)`;
- `terrain_at(cell)` / `has_terrain(cell)`;
- `query_cells(cells, ignore_entity_id, require_terrain)`;
- `query_footprint(anchor, facing, footprint, ignore_entity_id, require_terrain)`;
- `query_entity_footprint(entity_id, target_anchor, target_facing, require_terrain)`;
- `collision_coverage_report()`.

The service never mutates WHAT or collision overrides.

## 15. Self-ignore rule

When testing whether an already-placed entity can fit at a hypothetical target, its own persistent entity ID is ignored.

This prevents the actor/vehicle/object from colliding with its current footprint while evaluating a future placement.

Other entities remain normal blockers.

## 16. Multi-cell footprints

Queries operate on the full WHERE footprint after deterministic N/E/S/W rotation.

A multi-cell actor, vehicle, furniture object or future construction footprint is clear only if **every** target cell is known and free of blocking entities.

The collision system does not need special vehicle logic merely because a vehicle occupies several cells.

## 17. Deterministic behavior

- query cells are canonicalized/deduplicated/sorted;
- blocking/unclassified entity IDs are deduplicated/sorted;
- placement lookup uses WHAT's deterministic IDs;
- catalog profile keys enumerate in sorted order;
- override snapshots enumerate in sorted entity-ID order;
- no RNG exists in collision/spatial query.

## 18. Coverage diagnostics

`collision_coverage_report()` returns at least:

- `missing_required_profiles`: placed STRUCTURE/OBJECT/ACTOR entity IDs lacking both a catalog profile and entity override;
- `orphan_overrides`: collision override IDs that do not currently exist in WHAT.

This is diagnostic/validation output, not source of truth.

A future generator/content validator can use the same contract rather than duplicating collision assumptions.

## 19. Dynamic systems seam

Future systems may change collision without teaching collision what those mechanics mean.

Examples:

- Door system opens a door -> sets/clears a per-entity movement-blocking override.
- Death/body system decides a corpse no longer hard-blocks -> override.
- Construction/destruction removes or replaces physical entities in WHAT.
- Vehicle state may change collision if a special state genuinely requires it.

Collision only stores/query the resulting physical blocking fact.

## 20. Movement seam

Future Movement Actions will:

1. read the actor's WHAT placement/footprint;
2. choose a target cell/facing;
3. ask `SpatialQueryService` about that hypothetical footprint while ignoring self;
4. apply separate terrain/capability rules as needed;
5. if legal, submit a timed move through WHEN;
6. at the approved movement phase/completion, mutate WHAT placement through `WorldMutationService`.

Collision itself performs none of those action/timing/mutation steps.

## 21. Performance

A normal query is proportional to:

- the number of target footprint cells;
- the number of entities indexed in those cells.

It does not scan the whole world.

Type profiles are dictionary lookups. Dynamic overrides are sparse dictionary lookups. WHAT occupancy remains the spatial acceleration index.

No Node-per-collision-body model is introduced.

## 22. Safari/mobile

No platform-specific behavior belongs here.

The system is synchronous plain-data query logic and has no input, rendering, frame loop or browser lifecycle dependency.

## 23. Historical recovery

Golden source inspected:

- commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`;
- `game/scripts/LocalWorldState.gd` blob `f8fd11ebbf0ff2b3958fd46000404cbb12142fc5`.

Useful historical behavior:

- one canonical `can_enter` decision existed;
- walls/obstacles/glass/closed doors blocked movement;
- open doors did not.

Rejected historical architecture:

- fixed local-map width/height as reality;
- separate dictionaries for each object category;
- door state stored inside the collision/world container;
- collision tied to one local tactical spec.

The new system preserves the useful physical decision while using global WHAT placement and typed collision ownership.

## 24. Tests / acceptance criteria

Dedicated `CollisionSpatialQuerySmoke.gd` proves:

1. catalog profiles are explicit and mutation-safe on read;
2. normal static blockers require no per-entity override;
3. explicit non-blocking OBJECT profiles remain clear;
4. STRUCTURE/OBJECT/ACTOR without profile/override return UNKNOWN;
5. loose items/effects without profiles do not become false blockers;
6. explicit per-entity override supersedes catalog default and can be cleared;
7. missing terrain returns UNKNOWN rather than clear;
8. one-cell hard blockers return BLOCKED;
9. self-ignore permits hypothetical relocation without self-collision;
10. multi-cell rotated footprints query every target cell;
11. blocker/unclassified lists are deterministic and deduplicated;
12. coverage diagnostics report unclassified required entities and orphan overrides;
13. override snapshot/restore round-trips deterministically and rejects malformed state atomically;
14. no dependency on WHEN, reboot, generator, renderer or movement exists;
15. WHERE / WHAT / WHEN existing contract smokes remain green.

## 25. North-star fit

This system keeps the game physically grounded without introducing a physics-engine-style continuous simulation.

The grid remains simple and deterministic, but a meaningful world fact—whether a space is physically occupied—has one reusable owner. Movement, AI, construction and later systemic interactions can share that answer instead of each inventing slightly different collision logic.

The type-profile + sparse-override model directly serves the project's **low-resource, high-detail** goal: millions of ordinary entities can share explicit type-level physics while only dynamic exceptions consume additional persistent state.

## 26. Approved decisions

2026-08-16:

- Collision / Spatial Query is the one bounded implementation slice authorized by the user.
- Collision consumes WHERE + WHAT but does not consume WHEN.
- Type-level collision profile + sparse entity override is canonical instead of one collision state record per world entity.
- STRUCTURE / OBJECT / ACTOR placements require explicit collision classification; missing classification is UNKNOWN/fail-closed.
- Missing terrain is UNKNOWN/fail-closed.
- Terrain traversal capability is deferred to Movement/Traversal rather than conflated with hard occupancy collision.
- Collision query is read-only; movement and WHAT mutation remain separate systems.
- Implementation passed dedicated CI contract smoke while WHERE / WHAT / WHEN and the frozen reference remained green.
