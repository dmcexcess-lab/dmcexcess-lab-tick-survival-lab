# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract with accepted Trailer v2, accepted Small Farmhouse v2, and Large Farmhouse Candidate 001**

Date: 2026-08-16; farmhouse archetype work current through 2026-08-17.

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

A request envelope is a bounding area, not a requirement that every enclosed cell be building interior. Archetypes may therefore generate irregular/L-shaped occupied geometry inside a deterministic rectangular bounding footprint.

## 3. Implemented owners

### `BuildingGenerationRequest.gd`
Pure request facts: instance namespace, archetype ID, seed, global envelope, N/E/S/W orientation and caller-selected frontage.

### `GeneratedBuildingPlan.gd`
Pure semantic result: used bounding footprint, ground, structures, props, generation-only room-purpose regions, deterministic roles, version and seed provenance.

### `LocalBuildingGenerator.gd`
Registry/coordinator only. It currently routes:

- `residential.trailer.singlewide`
- `residential.house.farm_small`
- `residential.house.farm_large`

It contains no room-layout logic.

### `archetypes/TrailerBuildingGenerator.gd`
Owns the accepted single-wide trailer rules.

### `archetypes/FarmhouseBuildingGenerator.gd`
Owns only the **accepted small farmhouse** rules. Large-farmhouse work must not modify this owner unless the user explicitly reopens the small baseline.

### `archetypes/LargeFarmhouseBuildingGenerator.gd`
Owns only `residential.house.farm_large`, including its irregular occupied shape, room program, partitions, openings and restrained furniture.

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

The shared validator intentionally does **not** hard-code trailer/small-house/large-house room names or require a fully rectangular interior. Each archetype's dedicated CI assertions lock its room program, dimensions and shape facts.

### `GeneratedBuildingMaterializer.gd`
Consumes a validated plan and public initial-state contracts only. It writes initial WHAT terrain/entities/placements, explicitly enrolls generated doors CLOSED in 06A, refuses unrelated occupied cells, and restores WHAT + Door State if a later materialization write fails.

After materialization, generator ownership ends; persistent gameplay truth owns later mutations.

## 4. Determinism / identity

Same archetype version + request + seed must produce the same semantic plan/signature.

Child IDs derive from caller instance namespace + deterministic role, not insertion order or Node identity.

When critique intentionally changes same-seed geometry, bump that archetype version rather than silently changing an existing version.

Different farmhouse sizes are different archetypes, not versions of one another:

- small: `residential.house.farm_small`
- large: `residential.house.farm_large`

## 5. Accepted Trailer baseline — Candidate 002

Archetype: `residential.trailer.singlewide`

Version: **2**.

The user explicitly accepted Candidate 002 as the saved trailer baseline on 2026-08-17. Preserve its rules unless a later explicit trailer revision supersedes it.

Canonical NORTH geometry:

- 5×12 exterior shell;
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

`TrailerCritiqueFixture.gd` remains preserved as a regression/showcase fixture.

## 6. Accepted Small Farmhouse baseline — Candidate 002 / v2

Archetype: `residential.house.farm_small`

Version: **2**.

Candidate 001 used a 13×13 shell with separate 5×5 living and 3×3 kitchen regions plus a large unpartitioned middle band. In play that read as an oversized approximately 11×7 main open area and was rejected.

Candidate 002 compacted the house to:

- **13×9 exterior shell**;
- one open-plan **11×3 `living_kitchen`** room;
- rightmost 3×3 kitchen work zone with linoleum flooring;
- bedroom 1 3×3;
- bathroom 3×3;
- bedroom 2 3×3;
- one horizontal partition immediately behind the main room;
- two exterior doors + three private-room doors;
- seven windows;
- light plaster exterior;
- restrained wall-aware furniture;
- one-cell circulation to all rooms.

On 2026-08-17 the user explicitly accepted/saved it with:

> “Nice save that as small farm house.”

This makes `farm_small` v2 a protected accepted baseline. `SmallFarmhouseCritiqueFixture.gd` preserves its critique setup after the live demo moves on to the large farmhouse.

## 7. Large Farmhouse Candidate 001 — current

Archetype: `residential.house.farm_large`

Version: **1**.

User requirement on 2026-08-17:

> “Lets make a large farm house.3 bed 2 bath, seperate rooms for livingroom and kitchen. Bonus for making it non square.”

### 7.1 Shape

Candidate 001 uses a genuine **L-shaped occupied building**, not a full rectangle with cosmetic indentation.

Canonical NORTH bounding footprint:

- **25×20** bounding rectangle;
- **19×20 main body** on the left;
- **6×8 front-right kitchen wing**;
- cells in the southeast portion of the 25×20 bound remain outdoor terrain and receive no building ground;
- exterior walls follow the L perimeter, including the wing underside and inner notch wall.

This proves System 19 can represent irregular local buildings while retaining simple deterministic bounding-envelope rotation.

### 7.2 Room program

Declared rooms are deliberately separate physical spaces:

- `living_room`: **6×5 / 30 cells**;
- `kitchen`: **5×5 / 25 cells**;
- `bedroom_1`: **6×4 / 24 cells**;
- `bedroom_2`: **6×4 / 24 cells**;
- `bedroom_3`: **6×3 / 18 cells**;
- `bathroom_1`: **3×3 / 9 cells**;
- `bathroom_2`: **3×3 / 9 cells**.

The primary front door enters a central circulation hall. No declared room is used as a hallway to reach another declared room.

### 7.3 Separate living room and kitchen

The living room and kitchen are not merely floor-color regions:

- living room is enclosed from the hall by real `wall.interior` structure and `door.interior.living`;
- kitchen is in the right-front wing and is enclosed from the hall by real `wall.interior` structure and `door.interior.kitchen`;
- kitchen also has a secondary exterior side door.

### 7.4 Doors / windows

Candidate 001 uses:

- **2 exterior doors** — primary front + kitchen side;
- **7 interior doors** — living, kitchen, three bedrooms, two bathrooms;
- **9 total doors**;
- **12 windows** distributed across living, hall, kitchen, bedrooms and bathrooms.

Generated doors begin CLOSED; System 18 owns runtime opening/closing.

### 7.5 Floors / furniture

Floors:

- living/hall: `ground.laminate_light`;
- kitchen: `ground.linoleum_yellow`;
- bathrooms: `ground.tile_white`;
- bedrooms: beige/blue carpet with deterministic seed variation.

Furniture deliberately reuses already-supported semantic art/collision vocabulary:

- living: sofa, armchair, coffee table;
- kitchen: stove, refrigerator, sink;
- each bedroom: double bed + dresser;
- each bathroom: toilet, vanity, clawfoot tub.

System 07A consumes semantic N/E/S/W facing so installed-looking furniture aligns to walls without renderer knowledge inside generation.

### 7.6 Rotation

Canonical NORTH bounding size 25×20 rotates to 20×25 for EAST/WEST. All occupied cells, notch geometry, structures, axes and prop facings rotate through the same canonical helpers used by other System 19 archetypes.

## 8. Critique fixtures / live demo

### Preserved small fixture

`SmallFarmhouseCritiqueFixture.gd` preserves the accepted small farmhouse:

- 15×15 critique lot;
- 32 px/cell;
- envelope `Rect2i(1,1,13,9)`;
- seed 19002;
- player `(4,0)` facing SOUTH.

### Current live large fixture

`FarmhouseCritiqueFixture.gd` is now the large-house critique caller so `CanonicalDemoMain.gd` remains composition-only and needs no building-specific edit.

- **27×22** critique lot;
- **19 px/cell** presentation;
- envelope `Rect2i(1,1,25,20)`;
- instance `building.demo.farmhouse.large.001`;
- seed `19003`;
- NORTH orientation/frontage;
- player `(10,0)` facing SOUTH toward the CLOSED primary door;
- no NPCs/infected/loot.

The reduced critique cell-pixel size is presentation-only. Canonical WHERE remains 1 meter per cell; no camera subsystem was introduced solely for this candidate.

## 9. Tactical quality / verification contract

A valid generated building must be playable, not merely recognizable in a static image.

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` must prove:

1. accepted Trailer v2 is unchanged;
2. accepted Small Farmhouse v2 remains deterministic, 13×9, 11×3 living/kitchen, 2 bed/1 bath, five-door/seven-window and rotationally valid;
3. registry exposes trailer + small farmhouse + large farmhouse;
4. Large Farmhouse v1 is deterministic;
5. large NORTH bounding footprint is exactly 25×20;
6. large room counts are exactly 30 / 25 / 24 / 24 / 18 / 9 / 9 for living, kitchen, three bedrooms and two bathrooms;
7. living and kitchen have distinct real interior doors;
8. large house has exactly 9 doors and 12 windows;
9. southeast notch is genuinely outdoors while the front-right kitchen wing is genuinely occupied;
10. shared validator reaches every declared large-house room from the primary door;
11. EAST rotation yields a valid 20×25 bounding footprint;
12. undersized large envelopes fail explicitly;
13. both saved-small and live-large fixtures materialize into WHAT + CLOSED Door State;
14. all generated blockers have Collision coverage;
15. all generated ground/structure/prop semantics resolve through current Art Catalog;
16. System 18 can automatically Walk through each fixture's generated front door;
17. both critique views render with zero planned diagnostics;
18. actual canonical demo startup remains green.

First green Large Farmhouse Candidate 001 code:

- SHA `a533f4f27de6f37b92b5e8472bb4b81220b2e06e`;
- Local Building Generation run `32011785845`: **SUCCESS**.

That run passed source boundaries, Godot 4.7.1 import/parse, foundation/presentation regressions, Systems 18/19 integration smokes and canonical startup with no production repair.

## 10. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- irregular shape does not require a full-world scan or corrective retry loop;
- no per-frame generation;
- validation scales with local plan size;
- no generator behavior depends on desktop-only hover;
- live large critique remains fully visible through a 27×22 / 19px visible window and uses the existing touch controls;
- no camera subsystem was added merely to satisfy this archetype critique.

## 11. Forbidden dependencies

Generation production code must not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale parcel/road planner internals or future streaming implementation.

System 07A prop-art orientation is presentation-only. System 19 supplies semantic facing but does not know native sprite direction, transforms or atlas layout.

Small and large farmhouse generators must not import or mutate one another; they are peer archetype owners behind the registry.

## 12. Future seams / next loop

- playtest/critiqe Large Farmhouse Candidate 001;
- turn critique into `farm_large` versioned rules without touching accepted `farm_small` v2;
- preserve Trailer v2 and Small Farmhouse v2 unless explicitly reopened;
- continue adding residential/commercial archetypes through the same pure-plan -> validation -> materialization contract;
- allow future global planning to choose small vs large farmhouse based on parcel/household facts without changing either local generator;
- camera/larger world-view work remains a separate presentation system.

Potential later archetypes include ranch variants, duplexes, apartments, gas stations, convenience stores, retail, offices, warehouses, cabins, sheds and outbuildings.

## 13. Approved decisions

Approved by the user through 2026-08-17:

1. System 19 is local building generation/materialization, not global planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed.
3. Generate pure semantic plan -> validate -> materialize initial WHAT + Door State.
4. Room-purpose data is generation/validation metadata, not a persistent Room State domain.
5. Trailer v2 Candidate 002 is an accepted protected baseline.
6. `residential.house.farm_small` v2 is the accepted **Small Farmhouse** baseline: 13×9, compact 11×3 open living/kitchen, two bedrooms and one bath.
7. Large farmhouse is a **separate archetype**, `residential.house.farm_large`, not a mutation/version of `farm_small`.
8. Large farmhouse requires 3 bedrooms, 2 bathrooms, and truly separate living and kitchen rooms.
9. Large Farmhouse Candidate 001 receives the requested non-square bonus as a genuine L-shaped occupied structure inside a 25×20 bounding footprint.
10. Large-house circulation uses a central hall rather than routing traffic through declared rooms.
11. Large critique may reduce presentation cell pixels to keep the whole candidate visible; this does not alter the 1m canonical spatial scale or justify adding a camera system prematurely.
