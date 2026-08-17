# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — local semantic building generator, validator/materializer, Trailer Candidate 001 and dedicated CI contract present 2026-08-17**

Date: 2026-08-16

Depends on implemented WHERE / WHAT, Art Catalog + tactical layer renderers, Door State, and System 18 Door Interaction. Future Global World Planning remains a separate higher-level owner.

## 1. Goal

Create a reusable **local building generator** that turns an already-chosen building slot into a believable physical building. The first implemented archetype is one single-wide trailer developed through a user critique loop:

> generate trailer -> play/inspect it -> user critiques it -> refine archetype rules -> then add the next house archetype

System 19 is not a disposable screenshot generator and not the global world generator. It is the lower-level materialization system a future parcel/property planner can call after deciding *where* a building belongs.

## 2. Architectural boundary

System 19 answers:

> Given a global-space envelope, orientation, frontage, archetype, stable instance namespace and seed, what physical building exists here?

It does **not** decide towns, roads, parcels, addresses, utilities, household occupants, loot, outbreak history, streaming regions, camera behavior or which property gets which building type.

Global planning must decide those higher-level facts first. System 19 never scans the world looking for a convenient place to build.

## 3. Implemented owners

### `game/scripts/generation/buildings/BuildingGenerationRequest.gd`

Pure request facts:

- stable `instance_id` namespace;
- `archetype_id`;
- seed;
- global `Rect2i` envelope;
- canonical N/E/S/W orientation;
- caller-selected frontage side.

No texture paths, atlas indices, Nodes, camera state, player state or loot data.

### `game/scripts/generation/buildings/GeneratedBuildingPlan.gd`

Pure semantic result containing:

- used footprint;
- interior ground assignments;
- walls / doors / windows with global cells, axis and facing;
- prop placements;
- generation-only room-purpose regions;
- deterministic child role labels;
- archetype version + seed provenance;
- deterministic snapshot/signature.

Room purposes remain generator/validation metadata in V1, not a new persistent Room State domain.

### `game/scripts/generation/buildings/LocalBuildingGenerator.gd`

Registry/coordinator only. It routes an archetype ID to its focused generator and contains no trailer room logic.

### `game/scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd`

Owns only `residential.trailer.singlewide`.

### `game/scripts/generation/buildings/GeneratedBuildingValidator.gd`

Pure plan validation covering:

- footprint containment;
- unique deterministic roles;
- legal structure axes;
- no duplicate structure/prop contradictions;
- required room purposes;
- exactly one primary exterior door;
- blocking furniture not occupying structure/opening cells;
- one-cell circulation from exterior entrance to every room with doors conceptually passable.

Art and Collision coverage remain independent integration tests instead of generator dependencies.

### `game/scripts/generation/buildings/GeneratedBuildingMaterializer.gd`

Consumes only a validated plan and public initial-state contracts.

It:

- writes interior terrain to WHAT;
- creates/places semantic wall, door, window and prop entities with deterministic stable IDs;
- explicitly enrolls generated doors CLOSED in 06A;
- refuses conflicting existing entity occupancy rather than deleting persistent facts;
- snapshots WHAT + Door State and restores them if a later materialization write fails.

After materialization, the generator does not own the building. WHAT / Door State and later runtime mechanics own current reality.

## 4. Replaceability / future global-planner seam

Future world generation can remain:

1. plan geography/roads globally;
2. plan parcels/properties;
3. choose property use/building archetype;
4. choose legal envelope/orientation/frontage;
5. call System 19;
6. validate/materialize the returned building;
7. afterward persistent gameplay truth owns mutations.

Changing the local generator later must not rewrite existing saved buildings.

## 5. Determinism and identity

The same archetype version + request + seed produces the same semantic plan/signature.

Randomness is local/seeded; no wall-clock/global random source is used.

Child entity IDs derive deterministically from caller instance namespace + semantic role, e.g.:

- `<instance>.wall.exterior.001`
- `<instance>.door.exterior.primary`
- `<instance>.door.interior.bathroom`
- `<instance>.prop.kitchen.stove`

Identity never depends on insertion order or Godot Node identity.

## 6. Trailer Candidate 001 — implemented geometry

Canonical archetype:

`residential.trailer.singlewide`

Archetype version: **1**.

Canonical north-oriented exterior footprint: **6 × 12 cells**. East/West orientation rotates to 12 × 6. Other orientations rotate deterministically using WHERE facing/axis rules.

The current critique-lot request uses:

- stable instance `building.demo.trailer.001`;
- envelope `Rect2i(2, 0, 6, 12)`;
- orientation NORTH;
- frontage EAST;
- deterministic seed `19001`.

### Functional rooms

The trailer has three distinct required spaces rather than the golden generator's old combined `bed_bath` zone:

1. **Living / kitchen** — 4×4 interior zone;
2. **Bathroom** — 4×2 interior zone;
3. **Bedroom** — 4×2 interior zone.

Interior partition rows physically separate those spaces, with a real interior door in each partition.

### Exterior opening

- exactly one primary exterior side door;
- canonical local cell `(5,3)` on the long East side;
- enters directly into living/kitchen;
- generated as `door.rural_wood` and explicitly begins CLOSED.

### Windows

Candidate 001 includes four exterior windows:

- two serving living/kitchen;
- two serving bedroom;
- bathroom intentionally has no window in V1.

### Floors

- living/kitchen: `ground.linoleum_green`;
- bathroom: `ground.tile_white`;
- bedroom: deterministic beige/blue carpet variant from seed.

### Structure vocabulary

- exterior: `wall.rural_wood`;
- interior partitions: `wall.interior`;
- exterior door: `door.rural_wood`;
- interior doors: `door.house`;
- windows: `window.rural_wood`.

Generator stores semantics only. Art Catalog owns appearance.

### Fixtures / furniture

Current restrained set:

- stove range;
- refrigerator;
- kitchen sink;
- sofa/loveseat deterministic variant;
- toilet;
- bathroom vanity;
- single bed;
- dresser.

A clear circulation spine is intentionally preserved instead of filling every available cell.

## 7. Tactical quality rules

A valid home must be playable, not merely recognizable in a static screenshot.

System 19 validates:

- one-cell route from exterior door to all three room zones;
- no required route through blocking furniture;
- no blocking prop on a door/opening;
- no sealed bath/bedroom;
- no wall/door/window overlap;
- deterministic legal orientation/axis rotation;
- no corrective deletion of pre-existing occupied cells.

Connectivity validation treats doors as conceptually open/passable. Runtime state remains 06A + System 18.

## 8. Critique-lot integration

`game/scripts/demo/TrailerCritiqueFixture.gd` is the current live composition fixture.

It remains a fixed **13×13 one-screen** environment so camera/streaming are still deferred. The lot contains:

- simple grass/road context;
- one generated Trailer Candidate 001;
- player spawn immediately outside the side entrance at `(8,3)`, facing WEST toward the CLOSED exterior door;
- no NPCs/infected/loot.

The old authored `CanonicalDemoFixture.gd` remains unchanged and continues to serve its existing regression contract.

System 18 makes the generated trailer physically enterable:

- Walk opens the exterior/interior door only at movement commit;
- Run forces it open loudly;
- manual tap close requires adjacency and facing.

Camera is intentionally not required until multiple properties exceed one screen.

## 9. User-guided archetype iteration

Trailer Candidate 001 is a **candidate**, not a declaration that trailer design is finished.

Development loop:

1. play Candidate 001;
2. critique proportions, rooms, entrance, windows, furniture and tactical circulation;
3. turn critique into reusable trailer-generation rules;
4. regenerate and retest;
5. once the trailer archetype feels right, version/freeze those rules for new generation;
6. add `residential.house.small_ranch` under the same contract;
7. repeat.

Do not patch one showcase instance by hand when critique should become an archetype rule.

## 10. Next archetype

The intended next building family remains a small ordinary ranch/house, targeting:

- distinct living room;
- kitchen;
- bathroom;
- primary bedroom;
- optional second bedroom where footprint supports it;
- sensible exterior frontage/windows/domestic fixtures.

House generation is not part of System 19 V1 yet.

## 11. Verified acceptance

`game/scripts/ci/LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` prove:

1. same request+seed produces identical semantic plan signature;
2. rotated orientation changes footprint correctly and still validates;
3. too-small request fails explicitly;
4. Candidate 001 materializes into canonical WHAT;
5. all three generated doors are explicitly enrolled CLOSED;
6. all generated blocking semantics have Collision coverage;
7. generated ground/wall/door/window/prop semantics resolve through current Art Catalog;
8. System 18 can Walk through the generated exterior door and opens it at commit;
9. fixed one-screen renderer stack configures the generated lot without diagnostics;
10. foundation/art/door regressions and actual canonical demo startup remain green.

Implementation candidate `c035fe7b3f5d0badab6c5b598996010e92d852b2` passed dedicated Local Building Generation run `32005363051` before documentation promotion.

## 12. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- no full-world scan;
- no per-frame generation;
- no unbounded random retries;
- validation scales with local plan size;
- no generator behavior depends on desktop UI/hover;
- the live critique result remains playable with existing phone controls + System 18 touch interaction.

## 13. Forbidden dependencies

Generation production code does not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale road/parcel planner internals, or future streaming implementation.

The materializer uses only approved public initial-state mutation contracts: WHAT + Door State.

## 14. Future seams

The same request/plan/validator/materializer contract can later host:

- small/large houses;
- duplexes;
- apartments;
- gas stations/convenience stores;
- retail/office/warehouse;
- farms/cabins;
- sheds/garages/outbuildings.

Future higher layers may supply parcel identity, address, utility connection points, household/business identity, socioeconomic/style/age parameters, pre-collapse furnishing variation and outbreak damage state without letting System 19 own global geography.

## 15. North-star fit

Believable enterable houses are core to “Ultima-style turn-based mini Zomboid.” System 19 preserves the meaningful depth—room purpose, navigation, doors/windows/furniture and persistent physical state—without becoming architectural CAD or a world-planning monolith.

The critique loop is especially important at the coarse 1 m grid scale: learn good density/proportion from actual play before multiplying bad assumptions across a large generated world.

## 16. Approved decisions

Approved by the user on 2026-08-16/17:

1. System 19 is local building generation/materialization, not global world planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed; generator never hunts the world for placement.
3. Pure semantic plan is generated and validated before WHAT mutation.
4. Initial materialization writes physical WHAT facts and explicitly enrolls doors CLOSED in 06A.
5. Room-purpose data remains generation/validation metadata in V1.
6. First archetype is `residential.trailer.singlewide`.
7. Candidate 001 uses a concrete 6×12 single-wide footprint before rotation.
8. Trailer has distinct living/kitchen, bathroom and bedroom rather than the old combined bed/bath zone.
9. First trailer has one main exterior side entrance, two interior doors, windows and restrained functional furniture.
10. Connectivity/circulation is validated as gameplay geometry.
11. First live critique uses one generated building on the fixed one-screen lot; camera remains deferred.
12. User critiques become generator/archetype rules; next archetype after trailer refinement is a small ordinary ranch house.
