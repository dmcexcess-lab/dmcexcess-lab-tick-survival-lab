# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract with accepted Trailer v2, accepted Small Farmhouse v2, and Large Farmhouse Candidate 003**

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

It does not decide towns, roads, parcels, addresses, utilities, household occupants, loot, outbreak history, streaming regions, camera behavior or which property receives which building type.

A request envelope is a bounding area. Archetypes may be rectangular or irregular, but geometry should be no more complex than the building needs.

## 3. Implemented owners

### `BuildingGenerationRequest.gd`
Pure request facts: instance namespace, archetype ID, seed, global envelope, N/E/S/W orientation and caller-selected frontage.

### `GeneratedBuildingPlan.gd`
Pure semantic result: bounding footprint, ground, structures, props, generation-only room-purpose regions, deterministic roles, version and seed provenance.

### `LocalBuildingGenerator.gd`
Registry/coordinator only. It routes:

- `residential.trailer.singlewide`
- `residential.house.farm_small`
- `residential.house.farm_large`

It contains no room-layout logic.

### `archetypes/TrailerBuildingGenerator.gd`
Owns the accepted single-wide trailer rules.

### `archetypes/FarmhouseBuildingGenerator.gd`
Owns only the accepted small farmhouse rules. Large-house critique must not modify it unless the user explicitly reopens the small baseline.

### `archetypes/LargeFarmhouseBuildingGenerator.gd`
Owns only `residential.house.farm_large`, including room program, compact partitioning, openings and restrained furniture.

### `GeneratedBuildingValidator.gd`
Shared structural validator verifies footprint containment, unique roles, legal axes, no structure/prop contradictions, valid room records, exactly one primary exterior door, no blocking furniture on doors, and reachability from the primary entrance with doors conceptually passable.

The shared validator does not hard-code archetype-specific room names or dimensions. Dedicated CI locks each archetype program.

### `GeneratedBuildingMaterializer.gd`
Consumes a validated plan and public initial-state contracts only. It writes initial WHAT terrain/entities/placements, enrolls generated doors CLOSED, refuses unrelated occupied cells, and restores WHAT + Door State if a later write fails.

After materialization, generator ownership ends.

## 4. Determinism / identity

Same archetype version + request + seed must produce the same semantic plan/signature.

Child IDs derive from caller instance namespace + deterministic role.

When critique intentionally changes same-seed geometry, bump that archetype version.

Different farmhouse sizes remain separate archetypes:

- small: `residential.house.farm_small`
- large: `residential.house.farm_large`

## 5. Accepted Trailer baseline — v2

Preserve the accepted 5×12 trailer baseline unless explicitly reopened.

## 6. Accepted Small Farmhouse baseline — v2

Archetype: `residential.house.farm_small`

User accepted it on 2026-08-17 with:

> “Nice save that as small farm house.”

Canonical program:

- 13×9 shell;
- one 11×3 open living/kitchen;
- bedroom 1 3×3;
- bathroom 3×3;
- bedroom 2 3×3;
- private rooms directly behind one partition row;
- no oversized middle circulation band;
- two exterior + three private-room doors;
- seven windows;
- restrained wall-aware furniture.

This is a protected accepted baseline.

## 7. Large Farmhouse Candidate 003 — current

Archetype: `residential.house.farm_large`

Version: **3**.

Original requirement remains 3 bedrooms, 2 bathrooms, separate living room and kitchen, with compactness taking precedence over decorative irregularity.

### 7.1 Historical critique path

Candidate 001 used a 25×20 L-shaped footprint with large rooms and a central hall and was rejected as too large/hallway-heavy.

Candidate 002 established the accepted direction for density:

- 21×9 shell;
- 10×3 living room;
- 8×3 kitchen;
- three 3×3 bedrooms;
- two 3×3 bathrooms;
- no hall/corridor room;
- all private rooms directly behind common rooms.

Candidate 003 preserves that compact shell and room program while revising living/kitchen circulation and kitchen dressing.

### 7.2 Living/kitchen divider

The former `door.interior.living_kitchen` is removed.

Canonical NORTH divider behavior:

- local `(11,1)` remains `wall.interior`;
- local `(11,2)` — formerly the living/kitchen door — is now `wall.interior`;
- local `(11,3)` has **no structure at all**, creating a doorless lower passage between living and kitchen.

The rooms remain separate room-purpose regions and are visually/physically divided across the upper two rows, but ordinary circulation uses the open south/lower passage instead of a closable interior door.

### 7.3 Room program

Front common band:

- `living_room`: **10×3 / 30 cells**;
- `kitchen`: **8×3 / 24 cells**.

Rear private band immediately behind one horizontal partition:

- `bedroom_1`: **3×3 / 9 cells**;
- `bathroom_1`: **3×3 / 9 cells**;
- `bedroom_2`: **3×3 / 9 cells**;
- `bathroom_2`: **3×3 / 9 cells**;
- `bedroom_3`: **3×3 / 9 cells**.

All five private rooms continue to open directly into living/kitchen through the single partition row. No private room is used as circulation to another.

### 7.4 Kitchen floor / runner

Kitchen rows local y=1 and y=2 remain `ground.linoleum_yellow`.

The complete kitchen bottom row, local x=12..19 at y=3, becomes `ground.laminate_light`.

That row is a deliberate wood-floor circulation runner connecting the lower living/kitchen passage to the east side of the kitchen. **No generated prop may occupy any of those eight runner cells.**

### 7.5 Kitchen furniture

Candidate 003 reuses existing art/collision semantics only:

- stove at local `(12,1)`, facing SOUTH;
- refrigerator at `(13,1)`, facing SOUTH;
- sink moved from `(19,3)` to `(14,1)`, facing SOUTH, so all three primary appliances share the north wall;
- `prop.breakfast_table` added at `(18,2)`, near the east exterior wall but one cell clear of the exterior-door approach and off the wood runner.

No renderer-specific transform or atlas knowledge enters the generator. System 07A remains responsible for presentation rotation where appropriate.

### 7.6 Doors / windows

Candidate 003 uses:

- 2 exterior doors — primary living-room front + kitchen east-side exterior;
- 5 private-room interior doors;
- **7 total doors**;
- **11 windows**.

There is no living/kitchen interior door in v3.

Generated doors begin CLOSED; System 18 owns runtime state.

### 7.7 Rotation

Canonical NORTH size 21×9 rotates to 9×21 for EAST/WEST. Structures, open passage geometry, floor runner and prop facings rotate through the same deterministic helpers as other System 19 archetypes.

## 8. Critique fixtures / live demo

### Preserved small fixture

`SmallFarmhouseCritiqueFixture.gd` preserves accepted Small Farmhouse v2 at 15×15 / 32 px per cell.

### Current live large fixture

`FarmhouseCritiqueFixture.gd` remains the large-house critique caller.

Candidate 003 configuration:

- **23×11** critique lot;
- **23 px/cell** presentation;
- envelope `Rect2i(1,1,21,9)`;
- instance `building.demo.farmhouse.large.001`;
- seed `19003`;
- NORTH orientation/frontage;
- player `(6,0)` facing SOUTH toward the primary door;
- no NPCs/infected/loot;
- collision catalog includes existing `prop.breakfast_table` for the new blocking kitchen table.

Canonical WHERE remains 1m/cell. No camera subsystem is introduced for this critique.

## 9. Tactical quality / verification contract

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` must prove:

1. accepted Trailer v2 is unchanged;
2. accepted Small Farmhouse v2 remains unchanged and rotationally valid;
3. registry exposes trailer + small farmhouse + large farmhouse;
4. Large Farmhouse v3 is deterministic;
5. large NORTH footprint remains exactly 21×9;
6. living remains 10×3 and kitchen remains 8×3;
7. all three bedrooms and both bathrooms remain exactly 3×3;
8. no hall/corridor room-purpose record exists;
9. `door.interior.living_kitchen` no longer exists;
10. former living/kitchen door cell is a real wall;
11. lower divider cell has no structure and is the open connection between common rooms;
12. all eight kitchen bottom-row cells are `ground.laminate_light` and prop-free;
13. sink sits on the same north wall as stove/fridge;
14. breakfast table uses `prop.breakfast_table` near the east wall without occupying the runner;
15. all five private doors remain on the single partition row;
16. large house has exactly 7 doors and 11 windows;
17. shared validator reaches every declared room from the primary door;
18. EAST rotation yields valid 9×21 geometry;
19. undersized large envelopes fail explicitly;
20. saved-small and live-large fixtures materialize into WHAT + CLOSED Door State;
21. all generated blockers have Collision coverage;
22. all generated ground/structure/prop semantics resolve through Art Catalog;
23. System 18 can automatically Walk through each fixture's front door;
24. both critique views render with zero planned diagnostics;
25. canonical demo startup remains green.

Candidate 003 requires exact-final-head verification before completion is claimed.

## 10. Performance / mobile

- generation is bounded to one caller-supplied envelope;
- no full-world scan or unbounded retry loop;
- no per-frame generation;
- validation scales with local plan size;
- no generator behavior depends on hover;
- live critique remains fully visible with existing touch controls.

## 11. Forbidden dependencies

Generation production code must not import renderer/art internals, texture paths/atlas indices, camera/zoom, player input, HUD geometry, Health/Needs/Skills, loot/inventory actions, AI, Reboot, world-scale parcel/road planner internals or future streaming implementation.

System 07A prop-art orientation is presentation-only. System 19 supplies semantic facing but does not know native sprite transforms.

Small and large farmhouse generators are peer archetype owners and must not import or mutate one another.

## 12. Future seams / next loop

- playtest/critiqe Large Farmhouse Candidate 003;
- turn critique into `farm_large` versioned rules without touching accepted `farm_small` v2;
- preserve Trailer v2 and Small Farmhouse v2 unless explicitly reopened;
- continue adding residential/commercial archetypes through pure-plan -> validation -> materialization;
- allow future global planning to choose small vs large farmhouse based on parcel/household facts.

## 13. Approved decisions

Approved by the user through 2026-08-17:

1. System 19 is local building generation/materialization, not global planning.
2. Caller supplies envelope/orientation/frontage/instance ID/seed.
3. Generate pure semantic plan -> validate -> materialize initial WHAT + Door State.
4. Room-purpose data is generation/validation metadata, not persistent Room State.
5. Trailer v2 is an accepted protected baseline.
6. `residential.house.farm_small` v2 is the accepted Small Farmhouse baseline.
7. Large farmhouse is a separate `residential.house.farm_large` archetype.
8. Large farmhouse requires 3 bedrooms, 2 bathrooms, and separate living/kitchen rooms.
9. Candidate 001's 25×20 L-shape + central hall is rejected as too big/hallway-heavy.
10. Candidate 002 established the compact 21×9 / no-dedicated-hall direction.
11. Candidate 003 keeps Candidate 002 dimensions while replacing the living/kitchen door with upper wall + lower open passage, converting the kitchen bottom row to a clutter-free wood runner, moving the sink to the north appliance wall, and adding a breakfast table near the east wall.