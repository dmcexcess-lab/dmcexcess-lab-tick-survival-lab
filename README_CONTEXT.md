# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

Systems 14–19 are the live canonical demo/player path. `game/main.tscn` still launches the modular diner critique demo. `game/scripts/reboot/` remains frozen/deprecated reference only.

**System 19 is finalized.** The user explicitly accepted the building grammar and directed development to move on. New building profiles are now normal content work by default and should not reopen System 19 architecture unless a frozen contract proves insufficient.

**System 20 Candidate 001 is the active implementation:** pure deterministic `rural.crossroads + temperate.rural` local-area planning over 256×256 global cells, using only the existing System 19 building library.

Large-area visualization/camera and WHAT materialization are intentionally not part of this pure-plan slice.

## 3. Foundation truth

### WHERE
Global integer cells, 1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic types/terrain, WHERE placements, derived occupancy and typed mechanic state keyed by stable IDs.

### WHEN
One deterministic integer world tick, variable-duration actions/events, same-tick draining, COMMITTED/RESUMABLE/CANCELABLE policies, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical gameplay/presentation

Implemented + dedicated validation includes:

- WHERE / WHAT / WHEN foundation;
- Collision / Movement / Locomotion;
- recovered Art + Ground/Structure/Prop/Living Actor/Hand renderers;
- System 07A facing-aware Prop Art Orientation;
- Door State + System 18 automatic/manual door interaction;
- Hands / Inventory / Item Transfer;
- Health / Needs / Skills / Item Weight / Carry / Moodlets;
- Canonical Demo / HUD / Player Shell;
- Run / damage-interruptible Walk;
- movement exertion/encumbrance/run impact;
- System 19 Local Building Generation / finalized building grammar;
- System 19 DEV seed-cycle critique controls;
- System 20 Candidate 001 pure local-area/parcel planning.

Art remains presentation truth; generation stores semantic type/facing only. Art is not physics.

## 5. System 19 final truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

Stable pipeline:

`request -> pure semantic building plan -> shared structural validation -> materialize initial WHAT + CLOSED Door State -> relinquish ownership`

Frozen placement seam for higher-level planners:

`LocalBuildingGenerator.placement_descriptor(archetype_id)`

Protected/finalized library:

- `residential.trailer.singlewide` v2;
- `residential.house.farm_small` v2;
- `residential.house.farm_large` v4;
- `residential.house.compact_laundry` v1;
- `commercial.gas_station.small` v1;
- `commercial.diner.rural_small` v2.

Final hard rules emphasize compact purposeful space, logical adjacency, minimal wasted circulation, clear door/service paths, local functional clustering, contiguous work runs where appropriate, intentional open space, deterministic seeded variation and profile-specific requirements outside generic structural validation.

The earlier second-arbitrary-building finalization gate is superseded by the user's explicit 2026-08-20 instruction to finalize System 19.

## 6. System 20 active truth

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`

Current pipeline:

`AreaGenerationRequest -> inherited roads/intersection -> road-facing parcels -> land use -> access -> System 19 placement -> driveways -> outdoor/environment dressing -> GeneratedAreaValidator -> pure GeneratedAreaPlan`

Current owners under `game/scripts/generation/areas/`:

- `AreaSeed.gd`;
- `AreaGenerationRequest.gd`;
- `GeneratedAreaPlan.gd`;
- `AreaProfileCatalog.gd`;
- `EnvironmentProfileCatalog.gd`;
- `LocalRoadPlanner.gd`;
- `ParcelPlanner.gd`;
- `ParcelAccessPlanner.gd`;
- `BuildingPlacementPlanner.gd`;
- `OutdoorPropertyDressingPlanner.gd`;
- `GeneratedAreaValidator.gd`;
- `LocalAreaGenerator.gd`.

System 20 depends on System 19 only through its read-only placement descriptor and normal public generation/validation contracts. It does not inspect building internals.

## 7. Candidate 001 — Rural Crossroads

Fixture: `RuralCrossroadsPlanFixture.gd`

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- `rural.crossroads` v1;
- `temperate.rural` v1;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- central crossing at `(1128,2128)`;
- exactly one signalized intersection;
- zero locally generated road spurs.

Land-use target:

- 3 `commercial_small` opportunities nearest center;
- 6 residential parcels;
- 4 farther farmstead parcels;
- remaining generated frontage parcels agricultural/vacant/wilderness;
- >=60% non-road land unbuilt by buildings.

Existing library only:

- gas station once;
- diner once;
- third commercial opportunity intentionally vacant;
- ten residential/farmstead buildings drawn from the existing trailer/small farmhouse/large farmhouse/compact-laundry library.

Outdoor semantics include base grass, roads, gravel driveways, fields, one traffic signal, mailboxes, sparse residential trees and sparse farm fencing. No fake barns/stores, people, vehicles, loot or outbreak scenes.

## 8. System 20 verification

`LocalAreaGenerationSmoke.gd` verifies:

- deterministic same-seed replay and different-seed variation;
- inherited road/boundary integrity;
- one signalized crossroads;
- parcel non-overlap and road exclusion;
- 3 commercial / 6 residential / 4 farmstead targets;
- gas station + diner + one honest vacant commercial parcel;
- all four saved residential archetypes exercised;
- density falling outward;
- longer farmstead driveways;
- >=60% unbuilt non-road area;
- traffic signal/mailboxes/fields;
- every selected building accepted by System 19;
- recovered-art semantic coverage;
- twelve consecutive area seeds without reroll loops.

Dedicated workflow: `.github/workflows/local-area-generation.yml`.

Exact-head status context: `verify/system20-local-area`.

## 9. Current live demo

The live Web demo remains the **Rural Diner v2** critique fixture with `NEW BUILDING` seed cycling.

This is intentional. System 20 Candidate 001 is a 256×256 pure plan and does not own a camera/viewer. Do not distort the planner merely to fit the current one-screen demo.

## 10. Immediate next path

1. Get System 20 Candidate 001 pure planner green on exact `main` SHA.
2. Implement a separately owned large-area DEV critique viewer/camera to inspect the full rural plan visually.
3. Use that visual test to critique road/parcel/density/driveway behavior.
4. After the area test, add new System 19 building profiles freely as content needs emerge.
5. Only after the plan/viewer are sound, design System 20 initial WHAT materialization/transaction behavior.

## 11. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholders/fake completion.
4. Generation produces initial truth; persistent WHAT owns later changes after materialization.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Reboot is reference only.
9. Cross-region infrastructure is globally coordinated.
10. System 20 areas are planning domains, not streaming chunks.
11. System 20 chooses parcels/building requests; System 19 owns building internals.
12. New building profiles are content additions by default; accepted baselines stay protected.
13. Same-seed intentional rule changes require version bumps.
14. Settlement morphology and environment ecology remain separate.
15. Open space is legitimate output indoors and outdoors.
16. Large-area presentation is separate from System 20 planning.

## 12. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context;
8. IMPLEMENTED/APPROVED system designs;
9. DRAFT designs;
10. compatible master design;
11. golden/same-owner history.
