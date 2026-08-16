# System 01 — Semantic Tactical Map / RaidMapSpec Data Contract

Status: **DRAFT — USER APPROVAL REQUIRED BEFORE IMPLEMENTATION**

This is intentionally the first detailed subsystem design. It is the seam that makes later generator, renderer, player/collision, prefab, perception and persistence work independently replaceable.

## 1. Goal

Define one canonical semantic representation of a loaded/generated tactical location.

A tactical map should answer **what exists and where** without knowing:

- how it was generated;
- which atlas/tile draws it;
- how the player controls movement;
- what UI is visible;
- how lighting/weather/perception render it;
- how the strategic map works.

The same `RaidMapSpec` must be usable by:

- a hand-authored tiny visual-test map;
- the future Rural Edge generator;
- saved/prefab-authored structures;
- tactical rendering;
- collision/local world initialization;
- later lighting/perception/sound queries;
- deterministic CI tests.

## 2. Non-goals

This system does **not** own:

- procedural generation rules;
- art/atlas mapping;
- rendering;
- current player state;
- movement/action rules;
- UI/input;
- mutable door gameplay after a raid begins;
- loot/container contents;
- lighting values;
- weather state;
- infected/survivor actors;
- strategic travel;
- gameplay save files.

It defines static initial tactical-world facts and semantic metadata only.

## 3. Proposed standalone owners

Data-only scripts under `game/scripts/data/`:

- `RaidMapSpec.gd` — sealed/read-only tactical map contract.
- `RaidMapDraft.gd` — controlled mutable construction surface used by authored maps/generators before validation.
- `DoorRecord.gd` — semantic opening + wall axis + initial state.
- `WindowRecord.gd` — semantic window/opening facts.
- `WorldObjectRecord.gd` — furniture/fixture/vegetation/civic/object placement and explicit physical facts.
- `BuildingRecord.gd` — building identity and contained room/entrance references.
- `RoomRecord.gd` — room purpose/cells/bounds.
- `RoadCellRecord.gd` — road class/surface/connectivity facts.
- `MapAnchorRecord.gd` — spawn/extraction/entrance/other named tactical anchors.
- `RaidMapSchemaValidator.gd` — structural/schema validation only, not biome-quality judgment.

These are small data/contract owners. None draw, generate, or process input.

## 4. Coordinates and map size

Canonical coordinates use `Vector2i`.

- `(0,0)` is top-left.
- +X is east/right.
- +Y is south/down.
- Cardinal facing continues to use `Vector2i.UP/RIGHT/DOWN/LEFT`.

`RaidMapSpec` supports arbitrary positive width/height.

The first procedural Rural Edge target may still use 64×64, but **64×64 is not baked into this data contract**. That keeps authored test maps, prefabs and future unusual locations from requiring another schema.

## 5. Semantic IDs

World meaning is represented with readable `StringName` semantic IDs.

Examples:

- `ground.grass_lush`
- `ground.dirt`
- `ground.gravel_driveway`
- `ground.road_paved`
- `wall.house_siding`
- `wall.interior_drywall`
- `door.house`
- `window.house`
- `fixture.kitchen_sink`
- `fixture.toilet`
- `furniture.bed_double`
- `furniture.sofa`
- `prop.utility_pole`
- `vegetation.deciduous_large`

Semantic IDs are **not renderer IDs** and are not allowed to contain:

- atlas number;
- texture path;
- sprite index;
- color;
- draw order;
- UI meaning.

The future `ArtCatalog` maps semantic IDs to visuals. Separate simulation/rules modules may interpret semantic IDs for gameplay, but art never decides physics.

## 6. Layer model

A tactical cell may contain several conceptual layers.

### 6.1 Ground — dense layer

Every in-bounds cell has exactly one ground semantic ID.

Ground is stored as a flat dense array indexed by:

`index = y * width + x`

Reason: ground exists everywhere and visible-cell rendering/cell queries need cheap predictable lookup.

### 6.2 Structures/openings — sparse layer

Walls, doors and windows are sparse cell-indexed records.

A cell cannot simultaneously be both an opaque wall and a door/window opening in the sealed map.

Doors/windows are records, not wall sprites painted on top of a wall.

### 6.3 World objects — sparse layer

Furniture, fixtures, vegetation, utility poles, signs and environmental clutter are `WorldObjectRecord`s.

The record contains semantic appearance meaning **plus explicit physical facts** where needed.

Examples of physical facts:

- blocks movement;
- blocks vision;
- occupies interaction space;
- initial destructible flag later if/when that system is designed.

Those facts are data, not inferred from the sprite.

A single cell may support more than one non-conflicting object only when the object records explicitly allow it. The normal physical-object case remains one primary occupying object per cell.

### 6.4 Semantic regions — rooms/buildings

Rooms/buildings are metadata records over tactical cells. They do not render themselves and do not automatically create walls.

This allows a renderer rewrite or wall-art change without destroying room-purpose data used later by loot/search/AI.

## 7. `RaidMapDraft` vs `RaidMapSpec`

### RaidMapDraft

Mutable construction object.

Allowed users:

- authored test-map factory;
- future generator coordinator/modules;
- prefab stamping/placement system.

It exposes controlled operations such as:

- set ground;
- add/remove planned wall;
- add door/window;
- add object;
- add room/building;
- add road cell;
- add named anchor.

It owns conflict checks that are purely schema-level (for example, do not place a wall on a recorded door cell).

### RaidMapSpec

Sealed tactical map produced only after schema validation.

Consumers receive query access but do not mutate its static layout collections directly.

This gives future generators freedom to construct however they want while keeping a stable final contract.

## 8. Door contract

`DoorRecord` contains at least:

- unique integer record ID;
- cell;
- semantic ID such as `door.house`;
- wall axis enum: `HORIZONTAL` or `VERTICAL`;
- initial state: closed/open (normally closed);
- initial blocking/opacity/interactable facts appropriate to the opening;
- owning building ID when applicable;
- optional room IDs on each side once room ownership exists.

The map schema guarantees only structural consistency.

Detailed procedural door-placement quality (clear approaches, no T-junction, etc.) belongs to the later `DoorGeometryValidator`/building generator design, but this schema must preserve the axis and references necessary to enforce those rules.

Mutable door state after raid load belongs to `LocalWorldState`/`DoorState`, not `RaidMapSpec`.

## 9. Window contract

`WindowRecord` contains at least:

- unique ID;
- cell;
- semantic ID;
- wall axis;
- initial physical facts relevant to movement/vision;
- owning building ID when applicable.

Later breakage/barricading is mutable world state, not static spec mutation.

## 10. World object contract

`WorldObjectRecord` contains at least:

- unique integer ID;
- cell;
- semantic ID;
- category (`fixture`, `furniture`, `vegetation`, `civic`, `environment`, etc.);
- explicit movement-blocking flag;
- explicit vision-blocking flag;
- optional orientation/facing when meaningful;
- owning room/building ID when applicable.

Important rule:

> A renderer may choose a completely different sprite for `fixture.kitchen_sink`, but that does not change whether the object blocks movement or how gameplay treats it.

Loose ordinary inventory items are not part of this tactical-object vocabulary by default.

## 11. Room contract

`RoomRecord` contains:

- unique ID;
- semantic room type (`room.kitchen`, `room.bathroom`, `room.storefront`, etc.);
- authoritative set/list of member cells;
- cached bounding `Rect2i` for convenience;
- owning building ID;
- door IDs connected to the room when known.

Member cells are authoritative so future non-rectangular rooms do not require a schema rewrite.

A room record does not itself place floors/walls/furniture. Those are separate facts created by generation/authored content.

## 12. Building contract

`BuildingRecord` contains:

- unique ID;
- semantic building type (`building.farmhouse`, `building.trailer`, `building.corner_store`, etc.);
- authoritative occupied/owned cell set or shell bounds as appropriate;
- room IDs;
- entrance door IDs;
- frontage/entrance anchors when known.

Building metadata exists for later search/loot/AI/validation without forcing those systems into the generator.

## 13. Road contract

Road appearance must not be baked into art indices.

Each road cell stores semantic road facts including:

- cell;
- surface (`paved`, `dirt`, `gravel`);
- class (`main`, `local`, `driveway`, `trail`, etc.);
- four-way connectivity bitmask: north/east/south/west.

The renderer/ArtCatalog later chooses straight/corner/T/cross/end art from that connectivity.

This preserves the good golden behavior while making it independent from generation.

## 14. Anchors

`MapAnchorRecord` supports named semantic positions without teaching the map data what UI/game flow will do with them.

Examples:

- `anchor.player_spawn`
- `anchor.extraction`
- `anchor.primary_entrance`
- `anchor.service_entrance`

An extraction rules system later decides what stepping on an extraction anchor means.

## 15. Public query contract

`RaidMapSpec` should expose narrow query methods similar to:

- `is_inside(cell)`
- `ground_at(cell)`
- `wall_at(cell)` / `has_wall(cell)`
- `door_at(cell)`
- `window_at(cell)`
- `objects_at(cell)`
- `road_at(cell)`
- `room_by_id(id)`
- `building_by_id(id)`
- `anchors_of_type(type)`

Visible-cell rendering and collision initialization must not need to scan the entire map for one cell query.

Ground uses dense O(1) indexing. Sparse layers use cell-indexed dictionaries/maps plus ID indexes where useful.

## 16. Immutability / runtime state separation

`RaidMapSpec` is the **initial static layout contract**.

When a raid starts, mutable systems build their runtime state from it.

Examples:

- closed door becomes open -> `DoorState`, not changing the original spec;
- furniture destroyed/moved -> future mutable world/object state;
- window broken -> future mutable opening state;
- loot removed -> inventory/container state;
- infected moves -> actor state.

This separation lets deterministic generation be reproduced and tested while gameplay mutates the loaded world independently.

## 17. Serialization / determinism

The schema must have an explicit integer `schema_version`, starting at 1.

Records should be serializable to plain deterministic dictionaries/arrays for:

- CI snapshots;
- prefab import/export later;
- debugging;
- possible future raid persistence/migration.

Do not store live `Node`, texture, renderer or controller references inside map data.

Stable serialized output should use deterministic ordering where order matters for tests.

## 18. No generic metadata dumping ground

Avoid a broad anonymous `metadata` dictionary as the normal way to add features.

If a future system needs durable data, add a typed/defined field or a new record and advance the schema when necessary.

Reason: generic metadata becomes invisible coupling and defeats the purpose of the contract.

## 19. Allowed dependencies

The data subsystem may depend only on:

- Godot core value/container types;
- other records inside `scripts/data/`;
- schema validator inside the same subsystem.

## 20. Forbidden dependencies

The data subsystem must never import or call:

- generation scripts;
- ArtCatalog/renderers;
- player modules;
- input/UI;
- strategic map;
- raid/extraction controllers;
- weather/lighting/perception;
- save manager/game flow.

Consumers depend on the data contract, not the reverse.

## 21. Structural schema validation

`RaidMapSchemaValidator` checks only contract correctness, such as:

- positive width/height;
- exact ground-array size;
- every referenced cell in bounds;
- unique record IDs;
- valid room/building references;
- no wall occupying a door/window opening cell;
- door/window axis is valid;
- object occupancy rules are internally consistent;
- road connectivity references only valid road cells/in-bounds directions;
- required anchor records are valid when present.

It does **not** judge whether a rural map is good, whether a kitchen looks believable, or whether there are enough trees. Those are later independent quality validators.

## 22. Performance requirements

- O(1)-style cell queries for normal ground/structure/object lookups.
- No full-map scan per player movement or per visible cell.
- No Nodes/resources instantiated per empty cell.
- Dense storage only for facts that truly exist everywhere (initially ground).
- Sparse dictionaries/indexes for structures, openings and objects.
- 64×64 should be trivial on desktop and Safari, but the contract must not assume only 64×64 forever.

## 23. Safari/mobile requirements

This system has no UI, but it must remain lightweight enough that mobile rendering/input systems can query visible cells cheaply.

No platform-specific code belongs here.

## 24. Recovery sources

Inspect/mining sources before implementation:

Golden commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`:

- `TacticalMapGenerator.gd` — useful historical map schema/ground query concepts;
- `ProceduralRegionGenerator.gd` — useful road/building/prop data patterns;
- `LocalWorldState.gd` — useful static-spec -> mutable-world separation;
- `TacticalTiles.gd` — reveals what semantic data rendering needs;
- `MapPreviewPresentation.gd` — reveals visible-cell consumer needs.

Frozen recent reboot:

- `RebootSiteGenerator.gd` — mine recent door-axis/sparse lookup lessons only.

Do not copy either architecture blindly.

## 25. Acceptance criteria

System 01 is complete only when all of these are true:

1. A tiny hand-authored map can be created **without importing any generator**.
2. The map contains semantic ground, walls, doors, windows, objects, rooms/buildings, roads and anchors without any atlas indices.
3. A later renderer can query only visible cells without scanning the full map.
4. A later collision module can initialize blocking facts without importing the renderer.
5. Deleting the entire future `generation/` folder would not invalidate the authored map/data tests.
6. Static spec and mutable runtime state are clearly separate.
7. Door/window axes survive the contract.
8. Roads preserve semantic connectivity independent of road art.
9. Schema validation rejects invalid references/overlaps.
10. Deterministic serialize -> deserialize -> serialize produces equivalent canonical data.
11. The data subsystem imports no gameplay/presentation subsystem.
12. CI has a focused map-data contract test independent of the current frozen reboot.

## 26. Future extension seams

Known future systems should attach without redesigning the core contract:

- ArtCatalog/rendering reads semantic IDs.
- LocalWorldState builds mutable door/object/opening state.
- CollisionQuery consumes physical facts.
- Lighting/perception consumes opening/opacity/object facts.
- Sound uses geometry/material semantics through its own rules.
- Loot/search uses room/building/object identities.
- Generator/prefabs produce the same draft/spec.
- Persistence serializes spec plus separate mutable deltas.
- Multi-story maps, if ever approved, would require an explicit coordinate/schema revision rather than secretly abusing metadata.

## 27. Decisions requiring user approval

This DRAFT currently proposes these important choices:

1. `RaidMapSpec` is static/sealed initial layout; mutable gameplay state lives elsewhere.
2. Use semantic `StringName` IDs instead of enums tied to art.
3. Ground is dense; structures/openings/objects are sparse.
4. Roads store connectivity semantics, not chosen road sprite indices.
5. Rooms/buildings are semantic metadata separate from wall/floor/object placement.
6. Use `RaidMapDraft` as the mutable construction surface and seal it into `RaidMapSpec` after schema validation.
7. Avoid generic catch-all metadata dictionaries as the normal extension mechanism.
8. Map dimensions are not hardcoded to 64×64 in the contract.

No implementation should begin until these are approved or revised.
