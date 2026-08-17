# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **IMPLEMENTED — shared local-building contract with accepted Trailer v2, accepted Small Farmhouse v2, and Large Farmhouse Candidate 002**

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

## 7. Large Farmhouse Candidate 002 — current

Archetype: `residential.house.farm_large`

Version: **2**.

Original request required 3 bedrooms, 2 bathrooms, separate living room and kitchen, with non-square shape as a bonus.

### 7.1 Rejected Candidate 001

Candidate 001 used a 25×20 L-shaped footprint with large rooms and a dedicated central hall. On 2026-08-17 the user rejected it:

> “Too big. Too many hallways. Try again. Look how compact mine are”

That critique supersedes Candidate 001 geometry. Its L-shape demonstrated irregular support but is not an accepted large-house rule.

### 7.2 Candidate 002 compactness rule

Candidate 002 deliberately mirrors the accepted small farmhouse's density:

- **21×9 shell**, exactly the same depth as the accepted small farmhouse;
- size increase comes primarily from width and room count, not inflated room dimensions;
- **zero dedicated hall/corridor room cells**;
- the primary front door enters the living room directly;
- common rooms perform normal household circulation rather than spending cells on hallway-only space.

The earlier irregular-shape bonus is deprioritized here because compactness is the stronger explicit critique. The 21×9 footprint remains non-square without adding gratuitous geometry.

### 7.3 Room program

Front common band:

- `living_room`: **10×3 / 30 cells**;
- `kitchen`: **8×3 / 24 cells**;
- a real vertical partition separates them, with `door.interior.living_kitchen` connecting them.

Rear private band immediately behind one horizontal partition:

- `bedroom_1`: **3×3 / 9 cells**;
- `bathroom_1`: **3×3 / 9 cells**;
- `bedroom_2`: **3×3 / 9 cells**;
- `bathroom_2`: **3×3 / 9 cells**;
- `bedroom_3`: **3×3 / 9 cells**.

All five private rooms open directly into living/kitchen through the single partition row. No private room must be traversed to reach another.

### 7.4 Doors / windows

Candidate 002 uses:

- 2 exterior doors — primary living-room front door + kitchen side door;
- 1 living/kitchen interior door;
- 5 direct private-room doors;
- **8 total doors**;
- **11 windows**.

Generated doors begin CLOSED; System 18 owns runtime state.

### 7.5 Floors / furniture

Floors:

- living/common structural gaps: `ground.laminate_light`;
- kitchen: `ground.linoleum_yellow`;
- bathrooms: `ground.tile_white`;
- bedrooms: beige/blue carpet with deterministic seed variation.

Furniture reuses existing supported semantic vocabulary:

- living: sofa, armchair, coffee table;
- kitchen: stove, refrigerator, sink;
- each bedroom: double bed + dresser;
- each bathroom: toilet, vanity, clawfoot tub.

Furniture preserves a one-cell route from the exterior entry through the living/kitchen and into all five private-room doors.

### 7.6 Rotation

Canonical NORTH size 21×9 rotates to 9×21 for EAST/WEST. Structures, axes and prop facings use the same deterministic helpers as other System 19 archetypes.

## 8. Critique fixtures / live demo

### Preserved small fixture

`SmallFarmhouseCritiqueFixture.gd` preserves accepted Small Farmhouse v2 at 15×15 / 32 px per cell.

### Current live large fixture

`FarmhouseCritiqueFixture.gd` remains the large-house critique caller.

Candidate 002 configuration:

- **23×11** critique lot;
- **23 px/cell** presentation;
- envelope `Rect2i(1,1,21,9)`;
- instance `building.demo.farmhouse.large.001`;
- seed `19003`;
- NORTH orientation/frontage;
- player `(6,0)` facing SOUTH toward the primary door;
- no NPCs/infected/loot.

Canonical WHERE remains 1m/cell. No camera subsystem is introduced for this critique.

## 9. Tactical quality / verification contract

`LocalBuildingGenerationSmoke.gd` + `.github/workflows/local-building-generation.yml` must prove:

1. accepted Trailer v2 is unchanged;
2. accepted Small Farmhouse v2 remains unchanged and rotationally valid;
3. registry exposes trailer + small farmhouse + large farmhouse;
4. Large Farmhouse v2 is deterministic;
5. large NORTH footprint is exactly 21×9;
6. living is exactly 10×3 and kitchen exactly 8×3;
7. all three bedrooms and both bathrooms are exactly 3×3;
8. no hall/corridor room-purpose record exists;
9. living and kitchen remain physically separate through real partition geometry + door;
10. all five private doors occupy the single partition row and open directly from living/kitchen;
11. large house has exactly 8 doors and 11 windows;
12. shared validator reaches every declared room from the primary door;
13. EAST rotation yields valid 9×21 geometry;
14. undersized large envelopes fail explicitly;
15. saved-small and live-large fixtures materialize into WHAT + CLOSED Door State;
16. all generated blockers have Collision coverage;
17. all generated ground/structure/prop semantics resolve through Art Catalog;
18. System 18 can automatically Walk through each fixture's front door;
19. both critique views render with zero planned diagnostics;
20. canonical demo startup remains green.

Candidate 002 requires exact-final-head verification before completion is claimed.

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

- playtest/critiqe Large Farmhouse Candidate 002;
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
8. Large farmhouse requires 3 bedrooms, 2 bathrooms, and truly separate living and kitchen rooms.
9. Candidate 001's 25×20 L-shape + central hall is rejected as too big/hallway-heavy.
10. Candidate 002 follows the compact small-house pattern: 21×9, five 3×3 private rooms directly behind living/kitchen, no dedicated hall.
11. Compactness takes precedence over irregular-shape complexity for this critique iteration.
