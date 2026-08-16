# Tick Survival Lab — 00A Spatial Model (WHERE)

Status: **IMPLEMENTED — canonical modular foundation slice**

Parent architecture: `00_FOUNDATION_WHERE_WHAT_WHEN.md`.

User approval basis: after reviewing the WHERE / WHAT / WHEN foundation summary and its highlighted spatial recommendations, the user explicitly instructed: **“using all that go ahead and write the code.”** Per the one-system scope gate, this approval applied to WHERE first; WHAT and WHEN remain separate future implementation slices.

## 1. Goal

Define one durable, renderer-agnostic spatial language for the entire persistent world.

This system answers only geometric questions: where a cell is, what direction/facing means, which cells a footprint occupies, how a footprint rotates, which cells are adjacent, and how structure-cell axes define doorway/window approach and continuity geometry.

## 2. Non-goals

WHERE does not own:

- terrain/entity existence or persistence;
- door open/closed state;
- collision policy for a specific semantic object;
- actor movement rules or action costs;
- pathfinding/AI;
- rendering/art/atlas selection;
- map/world generation;
- streaming/chunk storage;
- health, inventory, lighting, perception, weather, sound, construction rules, vehicles or outbreak behavior.

## 3. Owners

Implementation lives under `game/scripts/foundation/spatial/`.

- `SpatialFacing.gd` — canonical N/E/S/W direction values and direction math.
- `SpatialFootprint.gd` — immutable-style relative occupied-cell masks and deterministic rotation.
- `SpatialStructureGeometry.gd` — structure-cell axis geometry and approach/continuity cell helpers.
- `SpatialLayer.gd` — canonical occupancy-channel vocabulary only; no occupants/state.
- `SpatialModel.gd` — small public spatial facade: global-cell adjacency, footprint placement, overlap/bounds and shared cell scale.

No root/Main code belongs here.

## 4. Public contract

### Global cells

Authoritative simulation coordinates are integer `Vector2i` global cells. Streaming partitions may later index ranges of global cells but never redefine coordinate identity.

### Cell scale

`SpatialModel.CELL_METERS = 1.0` is the canonical planning scale for one tactical cell. Pixel size is presentation-only and must not be stored here.

The scale is centralized so a future deliberate scale revision does not require scattered magic numbers.

### Facing

Canonical semantic facings are NORTH, EAST, SOUTH, WEST.

`SpatialFacing` supplies:

- validation;
- facing -> `Vector2i` vector;
- vector -> facing for exact cardinals;
- left/right/opposite;
- deterministic quarter-turn rotation of relative offsets;
- stable display/debug label.

Art-frame selection is forbidden here.

### Footprints

A footprint is a non-empty set of unique relative `Vector2i` offsets from a stable anchor cell.

- single-cell and rectangle helpers are provided;
- arbitrary masks are allowed;
- rotation is around the anchor, in 90-degree steps based on semantic facing;
- negative relative offsets are valid;
- sprite pivots do not affect footprints;
- world cells are derived from `anchor + rotated_offset`.

### Structure geometry

WHERE uses **structure cells**, not edge walls.

Every directional wall/opening structure can carry an explicit axis:

- HORIZONTAL — wall continuity E/W; perpendicular approaches N/S;
- VERTICAL — wall continuity N/S; perpendicular approaches E/W.

`SpatialStructureGeometry` only returns those geometric relations. It does not inspect whether structure entities actually exist; later WHAT/generator/construction validators consume these helpers.

### Spatial layers

The shared occupancy vocabulary is:

- TERRAIN
- STRUCTURE
- OBJECT
- ACTOR
- LOOSE_ITEM
- EFFECT

This is a classification contract, not a world-state container. WHAT later decides what occupies each channel.

### Spatial facade

`SpatialModel` supplies pure geometry helpers including:

- adjacent/forward/behind/left/right cells;
- four cardinal neighbors;
- Manhattan distance / cardinal adjacency;
- world cells for a footprint placement;
- footprint overlap;
- integer bounding rectangle for a cell set.

## 5. Data ownership

WHERE owns no mutable world state.

Footprints own only their relative geometry value. All public geometry operations are deterministic and side-effect-free.

## 6. Allowed dependencies

Only Godot core value types and other WHERE modules.

## 7. Forbidden dependencies

WHERE must never depend on:

- WHAT/persistent world stores;
- WHEN/tick scheduler;
- generator;
- renderer/art;
- player or infected code;
- input/UI;
- streaming;
- save serialization;
- health/inventory/AI/combat/construction/weather/lighting/sound.

## 8. Detailed rules

1. Global coordinates may be negative. No implicit finite board bounds exist in WHERE.
2. Facing uses Godot screen/grid convention: north is `(0,-1)`, east `(1,0)`, south `(0,1)`, west `(-1,0)`.
3. Footprint rotation is clockwise for NORTH -> EAST -> SOUTH -> WEST.
4. Footprint constructor removes duplicate offsets deterministically while preserving first occurrence order.
5. An empty supplied footprint falls back to one occupied anchor cell; physical placement never has a zero-cell footprint.
6. Structure cells are the canonical baseline because they reduce generation, collision, LOS, construction and recovered-art complexity.
7. Door/window axis is explicit semantic geometry, never inferred from sprite appearance.
8. WHERE does not answer `can_enter`. That later query depends on WHAT + mechanic-specific collision/door state.
9. WHERE does not expose streaming/chunk coordinates. A future streaming system may derive them from global cells without changing this contract.
10. WHERE never uses floating-point coordinates as authoritative location truth.

## 9. Failure / edge cases

- Invalid facing/axis values are rejectable through explicit validation helpers and are not silently treated as valid values.
- Duplicate footprint offsets do not create duplicate occupied world cells.
- Negative world coordinates and rotated negative relative offsets are valid.
- Bounds of an empty arbitrary query set return an empty `Rect2i`; footprints themselves are never empty.
- Overlap checks compare cell identity only and do not invent blocking/collision semantics.

## 10. Performance

All operations are pure local integer math.

Footprint operations are O(number of footprint cells). This is acceptable because ordinary props/actors have tiny footprints; large-area world queries belong to later indexes, not this value layer.

No `_process`, Nodes, signals, frame callbacks or rendering occur in WHERE.

## 11. Safari/mobile

No direct device-specific behavior. The grid contract supports touch input later because one semantic movement intent can resolve to one adjacent global cell without presentation-specific coordinates.

## 12. Tests / acceptance criteria

Dedicated headless `SpatialModelSmoke.gd` proves:

- exact cardinal vectors and left/right/opposite operations;
- clockwise relative-offset rotation;
- one-cell and rectangular/arbitrary footprint behavior;
- duplicate-offset removal;
- world-cell derivation at positive and negative global coordinates;
- overlap and bounds;
- horizontal/vertical structure approach and continuity cells;
- occupancy-channel validity;
- canonical 1.0m cell scale;
- no dependency on live reboot/runtime classes.

The owning smoke is permanently wired into Pages CI before the frozen-reference smokes.

## 13. Recovery sources

Historical `LocalWorldState.gd` and `PlayerActor.gd` demonstrate the useful old cell/facing approach, but their finite-board and player-specific responsibilities were not copied into WHERE.

Golden baseline commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 14. Future extension seams

The stable WHERE contract is intended for:

- WHAT placement/occupancy indexes;
- movement/collision/pathfinding;
- global generation and local materialization;
- construction/destruction;
- vision/LOS/facing vulnerability;
- lighting/sound anchoring;
- vehicles and larger footprints;
- rendering/art orientation;
- streaming/storage partition calculations;
- world validation.

Those systems consume WHERE; they do not get implemented inside it.

## 15. North-star fit

The invisible integer tactical grid keeps the Ultima-like world readable and deterministic while whole-cell footprints and four-way facing keep graphics/simulation manageable. Structure cells deliberately choose the simpler causal model because edge-wall complexity does not currently buy enough gameplay consequence or mood.

## 16. Approved decisions

2026-08-16:

- WHERE is the first implementation slice of the WHERE / WHAT / WHEN foundation.
- authoritative invisible global tactical grid;
- `Vector2i` global coordinates;
- four-way N/E/S/W facing;
- whole-cell arbitrary-mask footprints;
- structure cells with explicit horizontal/vertical axis;
- canonical planning scale of 1.0 meter per cell;
- no sub-cell/free movement baseline;
- pure geometry only; no persistent world/tick/render/generator ownership.

## 17. Implementation evidence

Implemented 2026-08-16 as five standalone modules plus one owning smoke test:

- `game/scripts/foundation/spatial/SpatialFacing.gd`
- `game/scripts/foundation/spatial/SpatialFootprint.gd`
- `game/scripts/foundation/spatial/SpatialStructureGeometry.gd`
- `game/scripts/foundation/spatial/SpatialLayer.gd`
- `game/scripts/foundation/spatial/SpatialModel.gd`
- `game/scripts/ci/SpatialModelSmoke.gd`

No live reboot/gameplay source imports this foundation yet. That isolation is intentional until WHAT and WHEN have their own approved contracts and integration slice.
