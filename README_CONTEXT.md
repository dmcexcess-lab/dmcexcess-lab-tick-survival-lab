# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

Systems 14–21 are the current canonical demo/player/planning path. `game/main.tscn` still launches the modular Rural Diner critique world while the System 20 rural crossroads remains a pure 256×256 plan. `game/scripts/reboot/` remains frozen/deprecated reference only.

**System 19 is finalized.** New building profiles are normal content work by default and should not reopen the building-grammar architecture unless its frozen public contract proves insufficient.

**System 20 Candidate 001 is implemented as a pure deterministic planner:** `rural.crossroads + temperate.rural`, 256×256 global cells, existing System 19 building library only.

**System 21 Tactical Camera / View Control is implemented:** player-follow by default, five discrete zoom levels, detached inspection/pan, recenter, cell/actor focus and future-cutscene scripted transition/restore seams. It is presentation only and does not move actors or advance simulation.

The immediate active development target is now a separately owned **System 20 large-area DEV critique viewer** that uses System 21 for camera behavior while keeping System 20 generation pure.

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
- System 20 Candidate 001 pure local-area/parcel planning;
- System 21 Tactical Camera / View Control.

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

System 20 depends on System 19 only through its read-only placement descriptor and normal public generation/validation contracts. It does not inspect building internals and it does not own camera/viewer behavior.

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
- ten residential/farmstead buildings drawn from trailer/small farmhouse/large farmhouse/compact-laundry.

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

## 9. System 21 camera truth

Design: `SYSTEM_DESIGNS/21_TACTICAL_CAMERA_VIEW_CONTROL.md`

Owners:

- `camera/TacticalCameraState.gd`;
- `camera/ZoomController.gd`;
- `camera/TacticalCameraController.gd`;
- `input/CameraInputAdapter.gd`;
- `ui/CameraControls.gd`.

Camera modes:

- `FOLLOW_PLAYER` — default;
- `DETACHED` — manual inspect/pan;
- `FOCUS_CELL`;
- `FOCUS_ACTOR`;
- `SCRIPTED` — wall-clock presentation transition, then settles into focus.

Five zoom presets:

1. Very Close — 1.75×;
2. Close — 1.35×;
3. Normal — 1.00× default;
4. Far — 0.75×;
5. Area — 0.50×.

Desktop: wheel zoom, middle-drag pan, Home recenter, bracket-key zoom convenience. Right-click remains reserved for future interaction UI.

Mobile: two-finger centroid pan + pinch-to-discrete-zoom, plus explicit `ZOOM - / CENTER / ZOOM +` buttons. One-finger gameplay touch is not consumed by the camera gesture adapter.

`DoorPointerInputAdapter` is camera-aware: it inverts the active canvas transform before mapping screen position to world cells. Touch selection resolves on short release and cancels on drag/multitouch so a pinch cannot accidentally become a door action.

Dedicated workflow: `.github/workflows/camera-view-control.yml`.
Exact-head status context: `verify/system21-camera-view`.

## 10. Current live demo

The live Web demo remains the **Rural Diner v2** critique fixture with `NEW BUILDING` seed cycling, but it now runs through System 21:

- camera starts centered on the survivor;
- Normal zoom is the default;
- `ZOOM - / CENTER / ZOOM +` controls are available;
- desktop/touch camera gestures are available;
- player movement moves the camera only while in follow mode;
- inspect/focus camera behavior changes presentation only.

The 256×256 System 20 area itself is still not the live world. Its dedicated critique viewer/materialization is the next bounded slice.

## 11. Immediate next path

1. Build a separately owned System 20 **large-area DEV critique viewer**.
2. Have that viewer expose/render the generated 256×256 area while System 21 owns camera follow/pan/zoom/recenter.
3. Visually critique road/parcel/density/driveway/farm/commercial-center behavior.
4. Add new System 19 building profiles freely after the prefab-only area test establishes System 20 quality.
5. Only after planner + visual inspection are sound, design System 20 initial WHAT materialization/transaction behavior.

## 12. Invariants

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
16. System 21 owns camera presentation only; camera never mutates world/simulation truth.
17. Large-area critique/viewer composition remains separate from System 20 planning and System 21 camera control.

## 13. Documentation source order

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
