# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract, accepted Trailer v2 baseline, Farmhouse Candidate 002 and dedicated CI present 2026-08-17**

Date: 2026-08-16; current farmhouse critique revision approved 2026-08-17.

Depends on implemented WHERE / WHAT, Art Catalog + tactical layer renderers, Door State, and System 18 Door Interaction. Future Global World Planning remains a separate higher-level owner.

## 1. Goal

Create a reusable local building generator that turns an already-chosen building slot into a believable physical building.

Development loop:

> generate an archetype candidate -> play/inspect it -> user critiques it -> convert critique into archetype rules -> preserve accepted versions -> add the next archetype

System 19 is not a screenshot generator and not the global world planner.

## 2. Architectural boundary

System 19 answers:

> Given a global-space envelope, orientation, frontage, archetype, stable instance namespace and seed, what physical building exists here?

It does **not** decide towns, roads, parcels, addresses, utilities, household occupants, loot, outbreak history, streaming regions, camera behavior or which property receives which building type.

Global planning supplies those higher-level facts first. System 19 never scans the world for a convenient place to build.

## 3. Implemented owners

### `BuildingGenerationRequest.gd`
Pure request facts: instance namespace, archetype ID, seed, global envelope, N/E/S/W orientation and caller-selected frontage.

### `GeneratedBuildingPlan.gd`
Pure semantic result: used footprint, ground, structures, props, generation-only room-purpose regions, deterministic roles, version and seed provenance.

### `LocalBuildingGenerator.gd`
Registry/coordinator only. It currently routes:

- `residential.trailer.singlewide`
- `residential.house.farm_small`

It contains no room-layout logic.

### `archetypes/TrailerBuildingGenerator.gd`
Owns the accepted single-wide trailer rules.

### `archetypes/FarmhouseBuildingGenerator.gd`
Owns only the small farmhouse rules.

### `GeneratedBuildingValidator.gd`
Shared structural validator. It verifies:

- footprint containment;
- deterministic unique roles;
- legal structure axes;
- no structure/prop contradictions;
- valid non-empty room-purpose records;
- exactly one `door.exterior.primary`;
- no blocking furniture on doors;
- one-cell circulation from the primary entrance to every declared room with doors conceptually passable.

The shared validator intentionally does **not** hard-code trailer- or farmhouse-specific room names. Each archetype's dedicated CI assertions lock its required room program and dimensions. This keeps the validator reusable for houses, stores and later building families.

### `GeneratedBuildingMaterializer.gd`
Consumes a validated plan and public initial-state contracts only. It writes initial WHAT terrain/entities/placements, explicitly enrolls generated doors CLOSED in 06A, refuses unrelated occupied cells, and restores WHAT + Door State if a later materialization write fails.

After materialization, generator ownership ends; persistent gameplay truth owns later mutations.

## 4. Determinism / identity

Same archetype version + request + seed must produce the same semantic plan/signature.

Child IDs derive from caller instance namespace + deterministic role, not insertion order or Node identity.

When critique intentionally changes same-seed geometry, bump that archetype version rather than silently changing an existing version.

## 5. Accepted Trailer baseline — Candidate 002

Archetype: `residential.trailer.singlewide`

Version: **2**.

The user explicitly accepted Candidate 002 as the saved trailer baseline on 2026-08-17. Preserve its rules unless a later explicit trailer revision supersedes it.

Canonical NORTH geometry:

- **5×12 exterior shell**;
- 3×4 living/kitchen;
- 3×2 bathroom;
- 3×2 bedroom;
- light `wall.plaster` exterior and `wall.interior` partitions;
- one exterior side door + two centered interior doors;
- four windows;
- stove/fridge/sink on one side;
- sofa/loveseat against the opposite wall facing inward;
- toilet, vanity, single bed, dresser;
- middle-column circulation spine.

`TrailerCritiqueFixture.gd` remains preserved as a regression/showcase fixture even though it is no longer the live boot target.

## 6. Farmhouse Candidate 002 — current accepted critique revision

Archetype: `residential.house.farm_small`

Version: **2**.

On 2026-08-17 the user found Candidate 001's main room too large and explicitly changed the requirement to:

> livingroom/kitchen 3x11 instead

Candidate 002 converts that critique into a reusable compact farmhouse rule rather than merely relabeling the old oversized open area.

### Canonical shell / layout

- **13×9 exterior shell**;
- light `wall.plaster` exterior;
- one open-plan living/kitchen room occupies the entire front interior strip: **11×3 cells** (`living_kitchen`, 33 cells);
- the kitchen work zone is the rightmost 3×3 portion of that same open-plan room and keeps `ground.linoleum_yellow` while the living side keeps `ground.laminate_light`;
- immediately behind the main room is one horizontal partition row containing the three private-room doors;
- the rear private band contains bedroom 1, bathroom and bedroom 2 as three separate **3×3** rooms;
- two vertical interior partition columns separate those private rooms;
- there is no extra four-row open circulation/dining void between the main room and private rooms.

The reduced shell height is intentional: keeping the old 13×13 shell would have preserved the same visually oversized dead open area the critique was meant to remove.

### Doors

Exactly five V2 doors:

1. primary front `door.house` entering the living side of the open-plan room;
2. secondary east-side `door.house` entering the kitchen end of the same room;
3. bedroom 1 door;
4. bathroom door;
5. bedroom 2 door.

System 18 owns runtime opening/closing; generated doors begin CLOSED.

### Windows

Seven V2 `window.house` openings remain:

- three front/side living-area windows;
- one front kitchen window;
- one rear window for each bedroom;
- one rear bathroom window.

### Floors

- open-plan living side: `ground.laminate_light`;
- 3×3 kitchen end: `ground.linoleum_yellow`;
- bathroom: `ground.tile_white`;
- bedroom 1: `ground.carpet_beige`;
- bedroom 2: deterministic beige/blue carpet variation.

### Furnishing

The first-pass set remains restrained and wall-aware:

- living: sofa, armchair, coffee table;
- kitchen: stove, refrigerator, sink;
- bedroom 1: double bed + dresser;
- bedroom 2: double bed + dresser;
- bathroom: toilet, vanity, clawfoot tub.

System 07A presentation consumes the N/E/S/W prop facing already produced by System 19, so wall-facing sinks, appliances and furniture visually align without generator-specific sprite logic.

Furniture placement preserves a one-cell path from the front entrance through the open-plan room to all three private-room doors and to the kitchen side door.

### Superseded Farmhouse Candidate 001

Candidate 001 / archetype version 1 used a 13×13 shell, separate 5×5 living and 3×3 kitchen room-purpose regions, and a large unpartitioned middle band. In play that visually read as an approximately 11×7 main open area and was rejected as too large. It remains historical only; do not restore its geometry without newer explicit direction.

## 7. Live critique integration

`FarmhouseCritiqueFixture.gd` is the current live critique caller.

- fixed **15×15** one-screen lot;
- presentation uses **32 px/cell** so no camera is required;
- authoritative spatial scale remains the canonical 1m tactical cell;
- farmhouse envelope: `Rect2i(1, 1, 13, 9)`;
- instance: `building.demo.farmhouse.001`;
- seed: `19002`;
- orientation NORTH / frontage NORTH;
- player starts at `(4,0)` facing SOUTH toward the CLOSED primary front door;
- no NPCs/infected/loot.

The 15×15 critique lot is a presentation/test caller only, not a new streaming/world-size rule. The stable demo instance namespace remains unchanged even though the farmhouse archetype version advanced to 2.

`CanonicalDemoFixture.gd` and `TrailerCritiqueFixture.gd` remain preserved for their regression roles.

## 8. Tactical quality rules

A valid generated building must be playable, not merely recognizable in a static image.

Shared validation ensures:

- each declared room has ground cells;
- every declared room is reachable from the primary exterior door with doors treated open;
- no required route relies on a blocking prop cell;
- no wall/door/window duplicate structure cell;
- no blocking prop occupies a structure/door cell;
- rotation stays deterministic/legal;
- materialization does not delete unrelated persistent facts.

Archetype CI additionally locks each building's required room program, dimensions and content counts.

## 9. Verification contract

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` must prove:

1. Trailer v2 remains deterministic, 5×12, correctly room-sized, light-walled and keeps the accepted opposite-wall sofa placement;
2. the registry exposes both trailer and farmhouse archetypes;
3. Farmhouse v2 is deterministic and reports archetype version 2;
4. farmhouse uses the exact compact **13×9** NORTH shell;
5. farmhouse has exactly one **11×3 / 33-cell `living_kitchen`** room and no separate v1 `living_room`/`kitchen` room-purpose records;
6. bedroom 1, bathroom and bedroom 2 remain exactly 3×3 / 9 cells each;
7. farmhouse has exactly five doors and seven windows;
8. light shell, primary front door, side kitchen door and the compact private-room partition line are locked by contract;
9. EAST rotation produces a deterministic **9×13** footprint and correct rotated doorway geometry;
10. too-small farmhouse requests fail explicitly;
11. farmhouse materializes into canonical WHAT with five CLOSED Door State entries;
12. all generated blocking semantics have Collision coverage;
13. all generated ground/wall/door/window/prop semantics resolve through current Art Catalog;
14. System 18 can automatically Walk through the generated farmhouse front door;
15. fixed 15×15 / 32px critique rendering produces no diagnostics;
16. foundation/art/door regressions and actual canonical demo startup remain green.

Historical first-green Candidate 001:

- SHA `65a951bc1d38c055c17cbcfcd496a59cb30727c9`
- Local Building Generation run `32007785922`: **SUCCESS**

Candidate 002 requires exact-final-head validation before completion is claimed in chat.

## 10. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- no full-world scan;
- no per-frame generation;
- no unbounded random retry loop;
- validation scales with local plan size;
- no generator behavior depends on desktop-only hover;
- live critique remains playable through existing mobile controls + System 18 touch door interaction.

## 11. Forbidden dependencies

Generation production code must not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale parcel/road planner internals or future streaming implementation.

System 07A prop-art orientation is presentation-only. System 19 supplies semantic facing but does not know native sprite direction, transforms or atlas layout.

## 12. Future seams / next loop

After Farmhouse Candidate 002 critique:

- refine the farmhouse only if critique identifies another reusable farmhouse rule;
- keep accepted Trailer v2 unchanged;
- add further residential/commercial archetypes under the same contract;
- camera/larger local play space remains deferred until multiple simultaneous properties create an actual need beyond the one-screen critique lot.

Potential later archetypes include ranch variants, duplexes, apartments, gas stations, convenience stores, retail, offices, warehouses, cabins, sheds and outbuildings.

## 13. Approved decisions

Approved by the user through 2026-08-17:

1. System 19 is local building generation/materialization, not global planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed.
3. Generate pure semantic plan -> validate -> materialize initial WHAT + Door State.
4. Room-purpose data is generation/validation metadata, not a persistent Room State domain.
5. Trailer v2 Candidate 002 is the accepted saved trailer baseline and remains unchanged by farmhouse work.
6. Farmhouse archetype is `residential.house.farm_small`.
7. Farmhouse Candidate 001 / version 1 is superseded after playtest critique that its open main area was too large.
8. Farmhouse Candidate 002 / version 2 uses a **13×9 shell** with one **11×3 open-plan living/kitchen room**.
9. The kitchen is the rightmost 3×3 end of that same room, not a separately partitioned room.
10. The three rear private rooms remain bedroom 1 / bathroom / bedroom 2 at 3×3 each, directly behind one partition row.
11. Farmhouse keeps light walls, two exterior doors, three private-room doors and seven windows.
12. Farmhouse critique stays one-screen via a 15×15 view at 32 px/cell; camera remains deferred.
